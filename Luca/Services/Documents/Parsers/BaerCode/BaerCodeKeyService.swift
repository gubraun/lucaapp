import Foundation
import RxSwift
import SwiftCBOR

enum BaerCodeKeyServiceError: LocalizedError {

    case keysStillValid
    case couldNotParse

}

struct BaerCodeKey: Codable {
    var kid: [UInt8]
    var credType: UInt64
    var aesKey: [UInt8]
    var xCoordECDSAKey: [UInt8]
    var yCoordECDSAKey: [UInt8]
}

class BaerCodeKeyService {

    private var preferences: LucaPreferences
    private var disposeBag = DisposeBag()

    init(preferences: LucaPreferences) {
        self.preferences = preferences
    }

    func setup() {
        getKeys().subscribe().disposed(by: disposeBag)
    }

    func getKeys() -> Single<[BaerCodeKey]> {
        readyToFetch()
            .andThen(BaerCodeKeyFetchOperation.fetchRx())
            .flatMap { self.decodeKeys(keyBundle: $0) }
            .flatMap { self.parseCOSESign(with: $0) }
            .flatMap { self.parseKeys($0) }
            .do(onSuccess: { keys in
                if !keys.isEmpty {
                    self.preferences.keyCache = keys
                    self.preferences.lastFetched = Date()
                }
            })
            .catchAndReturn(self.preferences.keyCache)
    }

    private func readyToFetch() -> Completable {
        return Completable.create { observer -> Disposable in
            guard let fetched = self.preferences.lastFetched else {
                observer(.completed)
                return Disposables.create()
            }
            let interval = TimeUnit.hour(amount: 12).timeInterval
            fetched + interval < Date() ? observer(.completed) : observer(.error(BaerCodeKeyServiceError.keysStillValid))
            return Disposables.create()
        }
    }

    private func decodeKeys(keyBundle: Data) -> Single<CBOR> {
        return Single.create { observer -> Disposable in
            do {
                if let decodedCOSESign = try CBORDecoder(input: keyBundle.bytes).decodeItem() {
                    observer(.success(decodedCOSESign))
                }
            } catch let error {
                observer(.failure(error))
            }
            return Disposables.create()
        }
    }

    private func parseCOSESign(with decodedCOSESign: CBOR) -> Single<(CBOR)> {
        return Single.create { observer -> Disposable in
            guard case let CBOR.tagged(tag, cborElement) = decodedCOSESign,
                  tag.rawValue == 98,
                  case let CBOR.array(array) = cborElement,
                  case let CBOR.byteString(payload) = array[2]
            else {
                observer(.failure(BaerCodeKeyServiceError.couldNotParse))
                return Disposables.create()
            }

            let decodedPayload = try? CBOR.decode(payload)

            if let payload = decodedPayload,
               case .map(let itemMap) = payload {
                if let keys = itemMap["Keys"] {
                    observer(.success(keys))
                } else {
                    observer(.failure(BaerCodeKeyServiceError.couldNotParse))
                }
            } else {
                observer(.failure(BaerCodeKeyServiceError.couldNotParse))
            }

            return Disposables.create()
        }
    }

    private func parseKeys(_ keys: CBOR) -> Single<[BaerCodeKey]> {
        return Single.create { observer -> Disposable in
            var baerCodeKeys = [BaerCodeKey]()
            if case let CBOR.array(allKeysArray) = keys {
                for keysArray in allKeysArray {
                    guard case let CBOR.array(keysCBOR) = keysArray,
                          case let CBOR.unsignedInt(credType) = keysCBOR[0],
                          case let CBOR.byteString(aesKey) = keysCBOR[1],
                          case let CBOR.byteString(xCoord) = keysCBOR[2],
                          case let CBOR.byteString(yCoord) = keysCBOR[3] else {
                        observer(.failure(BaerCodeKeyServiceError.couldNotParse))
                        return Disposables.create()
                    }

                    // kid is hidden in the last 16 bytes of xCoords for QR code size purposes
                    let suffix = xCoord.suffix(16) as [UInt8]
                    if suffix.count == 16 {
                        baerCodeKeys.append(BaerCodeKey(kid: suffix, credType: credType, aesKey: aesKey, xCoordECDSAKey: xCoord, yCoordECDSAKey: yCoord))
                    }
                }
            } else {
                observer(.failure(BaerCodeKeyServiceError.couldNotParse))
            }

            observer(.success(baerCodeKeys))
            return Disposables.create()
        }
    }

}
