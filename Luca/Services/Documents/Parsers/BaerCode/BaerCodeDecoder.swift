import RxSwift
import SwiftCBOR

enum BaerCodeType: Int, Codable {

    case fast = 1
    case pcr = 2
    case cormirnaty = 3
    case janssen = 4
    case moderna = 5
    case vaxzevria = 6

    var category: String {
        switch self {
        case .fast: return L10n.Test.Result.fast
        case .pcr: return L10n.Test.Result.pcr
        case .cormirnaty: return L10n.Vaccine.Result.cormirnaty
        case .janssen: return L10n.Vaccine.Result.janssen
        case .moderna: return L10n.Vaccine.Result.moderna
        case .vaxzevria: return L10n.Vaccine.Result.vaxzevria
        }
    }
}

struct BaerCoronaProcedure: Codable {
    var type: BaerCodeType
    var date: Int
}

struct BaerCodePayload {
    var version: Int
    var firstName: String
    var lastName: String
    var dateOfBirthInt: Int
    var diseaseType: Int
    var procedures: [BaerCoronaProcedure]
    var procedureOperator: String
    var result: Bool

    func isVaccine() -> Bool {
        return procedures[0].type.rawValue >= BaerCodeType.cormirnaty.rawValue
    }
}

class BaerCodeDecoder {

    func decodeCode(_ code: String) -> Single<BaerCodePayload> {
        ServiceContainer.shared.baerCodeKeyService.getKeys()
            .flatMap { keys in
                self.parseCode(code, with: keys)
            }
    }

    func parseCode(_ code: String, with keys: [BaerCodeKey]) -> Single<BaerCodePayload> {
        Single.create { [self] observer -> Disposable in

            let originalRawData = Data(base64Encoded: code, options: .ignoreUnknownCharacters)
            if var rawData = originalRawData {

                let version = cutVersion(from: &rawData)
                do {

                    if let decodedCOSESign = try CBORDecoder(input: rawData.bytes).decodeItem() {

                        let coseSignPayload = parseCOSESign(with: decodedCOSESign)

                        guard let payload = coseSignPayload
                        else {
                            throw CoronaTestProcessingError.parsingFailed
                        }
                        let (parsedProtectedHeader, parsedUnprotectedHeader, coseEncrypt0Ciphertext) = parseCOSEEncrypt0(with: payload)

                        guard let unprotectedHeader = parsedUnprotectedHeader,
                              let ciphertext = coseEncrypt0Ciphertext
                        else {
                            throw CoronaTestProcessingError.parsingFailed
                        }
                        let (parsedKid, parsedIV) = parseCOSEEncrypt0UnprotectedHeader(with: unprotectedHeader)

                        guard let kid = parsedKid,
                              let iv = parsedIV,
                              let protectedHeader = parsedProtectedHeader,
                              let key = keys.filter({ $0.kid == kid }).first,
                              let decodedCredentials = try decryptCretentials(aesKey: key.aesKey, kid: kid, protectedHeader: protectedHeader, iv: iv, ciphertext: ciphertext)
                        else {
                            throw CoronaTestProcessingError.parsingFailed
                        }

                        if try BaerCodeSignatureValidator().verify(decodedCOSESign, key: key),
                           let baerCodePayload = parseCredentials(decodedCredentials: decodedCredentials, version: version) {
                            observer(.success(baerCodePayload))
                        }
                    }
                } catch {
                    observer(.failure(CoronaTestProcessingError.parsingFailed))
                }
            }

            observer(.failure(CoronaTestProcessingError.parsingFailed))
            return Disposables.create()
        }
        .subscribe(on: LucaScheduling.backgroundScheduler)
    }

    /// First two bytes ob BaerCode hold the version number. Remaining part is CBOR encoded.
    /// We pop first two bytes and pass remaining code to parser
    /// - Parameter data: baercode
    /// - Returns: Baercode version
    private func cutVersion(from data: inout Data) -> Int {
        let versionFirstByte = data.popFirst()
        let versionSecondByte = data.popFirst()
        let versionBytes = [versionFirstByte, versionSecondByte]
        let versionPointer = UnsafeMutablePointer<UInt16>.allocate(capacity: versionBytes.count)
        let version = versionPointer.withMemoryRebound(to: UInt16.self, capacity: 1) {
            $0.pointee
        }

        return Int(version)
    }

    private func parseCOSESign(with decodedCOSESign: CBOR) -> CBOR? {

        guard case let CBOR.tagged(tag, cborElement) = decodedCOSESign,
              tag.rawValue == 98,
              case let CBOR.array(array) = cborElement,
              case let CBOR.byteString(payload) = array[2]
        else {
            return nil
        }

        let decodedPayload = try? CBOR.decode(payload)

        return decodedPayload
    }

    // swiftlint:disable:next large_tuple
    private func parseCOSEEncrypt0(with decodedPayload: CBOR) -> ([UInt8]?, [CBOR: CBOR]?, [UInt8]?) {

        guard case let CBOR.tagged(tag, cborElement) = decodedPayload,
              tag.rawValue == 16,
              case let CBOR.array(array) = cborElement,
              case let CBOR.byteString(protectedHeader) = array[0],
              case let CBOR.map(unprotectedHeader) = array[1],
              case let CBOR.byteString(ciphertext) = array[2]
        else {
            return (nil, nil, nil)
        }

        return (protectedHeader, unprotectedHeader, ciphertext)
    }

    private func parseCOSEEncrypt0UnprotectedHeader(with header: [CBOR: CBOR]) -> ([UInt8]?, [UInt8]?) {

        guard let kidByteString = header[4],
              let ivByteString = header[5],
              case let CBOR.byteString(kid) = kidByteString,
              case let CBOR.byteString(iv) = ivByteString
        else {
            return (nil, nil)
        }

        return (kid, iv)
    }

    private func decryptCretentials(aesKey: [UInt8], kid: [UInt8], protectedHeader: [UInt8], iv: [UInt8], ciphertext: [UInt8]) throws -> CBOR? {
        let additionalAuthenticatedData: [UInt8] = CBOR.encode(
            [
                "Encrypt0",
                CBOR.byteString(protectedHeader),
                CBOR.byteString([])
            ]
        )

        let keySource = ValueRawKeySource(key: Data(aesKey))
        let aes = AESGCMCrypto(keySource: keySource, iv: iv, additionalAuthenticatedData: additionalAuthenticatedData)
        let decryptedCredentials = try aes.decrypt(data: Data(ciphertext))

        return try CBORDecoder(input: decryptedCredentials.bytes).decodeItem()

    }

    private func parseCredentials(decodedCredentials: CBOR, version: Int) -> BaerCodePayload? {

        guard case let CBOR.array(credentialsArray) = decodedCredentials,
              case let CBOR.utf8String(firstName) = credentialsArray[0],
              case let CBOR.utf8String(lastName) = credentialsArray[1],
              case let CBOR.unsignedInt(diseaseType) = credentialsArray[3],
              case let CBOR.array(proceduresArray) = credentialsArray[4],
              case let CBOR.utf8String(procedureOperator) = credentialsArray[5],
              case let CBOR.boolean(result) = credentialsArray[6]
        else {
            return nil
        }

        // date of birth is a negativeInt if born before 01/01/1970 and unsignedInt if born after
        var dateOfBirthResult = 0
        if case let CBOR.unsignedInt(dateOfBirth) = credentialsArray[2] {
            dateOfBirthResult = Int(dateOfBirth)
        } else if case let CBOR.negativeInt(dateOfBirth) = credentialsArray[2] {
            dateOfBirthResult = -Int(dateOfBirth)
        }

        var procedures = [BaerCoronaProcedure]()
        for procedure in proceduresArray {

            guard case let CBOR.array(procedureArray) = procedure,
                  case let CBOR.unsignedInt(type) = procedureArray[0],
                  case let CBOR.unsignedInt(date) = procedureArray[1],
                  let baerCodeType = BaerCodeType.init(rawValue: Int(type))
            else {
                continue
            }

            procedures.append(BaerCoronaProcedure(type: baerCodeType, date: Int(date)))
        }

        return BaerCodePayload(version: version,
                               firstName: firstName,
                               lastName: lastName,
                               dateOfBirthInt: dateOfBirthResult,
                               diseaseType: Int(diseaseType),
                               procedures: procedures,
                               procedureOperator: procedureOperator,
                               result: result)
    }
}
