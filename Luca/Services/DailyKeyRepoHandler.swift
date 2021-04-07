import Foundation
import RxSwift

enum DailyKeyRepoHandlerError: LocalizedTitledError {
    case keyNotSaved(error: Error)
    case backendError(error: BackendError<RetrieveDailyKeyError>)
    case validationFailed
}

extension DailyKeyRepoHandlerError {
    var errorDescription: String? {
        switch self {
        case .keyNotSaved(let error):
            return L10n.DailyKey.Fetch.FailedToSave.message(error.localizedDescription)
        case .backendError:
            return L10n.DailyKey.Fetch.FailedToDownload.message
        case .validationFailed:
            return L10n.DailyKey.Fetch.FailedToSave.message("Signature is not valid")
        }
    }
    
    var localizedTitle: String {
        return L10n.Navigation.Basic.error
    }
}

class DailyKeyRepoHandler {
    let dailyKeyRepo: DailyPubKeyHistoryRepository
    let backend: DefaultBackendDailyKeyV3
    
    init(dailyKeyRepo: DailyPubKeyHistoryRepository, backend: DefaultBackendDailyKeyV3) {
        self.dailyKeyRepo = dailyKeyRepo
        self.backend = backend
    }
    
    func fetch(completion: @escaping () -> Void, failure: @escaping (DailyKeyRepoHandlerError) -> Void) {
        log("Fetching new daily key")
        backend.retrieveDailyPubKey()
            .execute { [weak self] (result) in
                guard let safeSelf = self else { return }
                safeSelf.fetchIssuerKeys(for: result.issuerId, completion: { (issuerResult) in
                    guard safeSelf.verify(thatSignature: result.signature,
                                          matchesIssuerWithPublicHDSKP: issuerResult.publicHDSKP,
                                          withKeyId: result.keyId,
                                          createdAt: result.createdAt,
                                          publicKey: result.publicKey) else {
                        safeSelf.log("The key signature could not be verified", entryType: .error)
                        DispatchQueue.main.async { failure(DailyKeyRepoHandlerError.validationFailed) }
                        return
                    }
                    
                    guard safeSelf.keyAgeIsValid(for: result.createdAt) else {
                        safeSelf.log("The key is not valid anymore", entryType: .error)
                        DispatchQueue.main.async { failure(DailyKeyRepoHandlerError.validationFailed) }
                        return
                    }
                    
                    do {
                        try safeSelf.updateDailyKeyRepo(with: result)
                    } catch let error {
                        safeSelf.log("The key couldn't be saved: \(error)", entryType: .error)
                        DispatchQueue.main.async { failure(DailyKeyRepoHandlerError.keyNotSaved(error: error)) }
                        return
                    }
                    print("[DailyKeyRepoHandler] Key has been successfully fetched: \(result.keyId) \(result.publicKey)")
                    safeSelf.log("Key has been successfully fetched")
                    DispatchQueue.main.async { completion() }
                }, failure: failure)
            } failure: { (error) in
                self.log("The key couldn't be retrieved: \(error)", entryType: .error)
                DispatchQueue.main.async { failure(.backendError(error: error)) }
            }
    }
    
    func removeAll() {
        dailyKeyRepo.removeAll()
        self.log("Keys have been removed")
    }
    
    private func updateDailyKeyRepo(with result: PublicKeyFetchResultV3) throws {
        guard let key = result.parsedKey else {
            throw NSError(domain: "Invalid daily public key", code: 0, userInfo: nil)
        }
        
        try ServiceContainer.shared.dailyKeyRepository.store(key: key, index: DailyKeyIndex(keyId: result.keyId, createdAt: Date(timeIntervalSince1970: TimeInterval(result.createdAt))))
        
        //Get only N newest keys and dispose rest
        let allIndices = Array(ServiceContainer.shared.dailyKeyRepository.indices)
        let sortedIndices = allIndices.sorted(by: { $0.createdAt.timeIntervalSince1970 > $1.createdAt.timeIntervalSince1970 })
        let indicesToKeep = sortedIndices.prefix(20)
        let indicesToRemove = allIndices.difference(from: Array(indicesToKeep))
        for index in indicesToRemove {
            dailyKeyRepo.remove(index: index)
        }
    }
    
    private func fetchIssuerKeys(for issuerId: String, completion: @escaping (IssuerKeysFetchResultV3) -> Void, failure: @escaping (DailyKeyRepoHandlerError) -> Void) {
        backend.retrieveIssuerKeys(issuerId: issuerId).execute (completion: { issuerResult in
            DispatchQueue.main.async {
                completion(issuerResult)
            }
        }, failure: { (issuerError) in
            self.log("The issuerKeys couldn't be retrieved: \(issuerError)", entryType: .error)
            DispatchQueue.main.async {
                failure(.backendError(error: issuerError))
            }
        })
    }
    
    private func verify(thatSignature actualSignature: String, matchesIssuerWithPublicHDSKP publicHDSKP: String, withKeyId keyId: Int, createdAt: Int, publicKey: String) -> Bool {
        guard let publicHDSKPData = Data(base64Encoded: publicHDSKP),
              let publicHDSKPKey = KeyFactory.create(from: publicHDSKPData, type: .ecsecPrimeRandom, keyClass: .public),
              let publicKey = publicKey.base64ToHex(),
              let signature = Data(base64Encoded: actualSignature) else {
            return false
        }
        
        let keyIdData = Int32(keyId).data
        let timestampData = Int32(createdAt).data
        
        var signatureData = keyIdData
        signatureData.append(timestampData)
        signatureData.append(Data(hex: publicKey))
        
        let signatureVerifier = ECDSA(privateKeySource: nil, publicKeySource: ValueKeySource(key: publicHDSKPKey))
        
        do {
            let isValidSignature = try signatureVerifier.verify(data: signatureData, signature: signature)
            return isValidSignature
        } catch let error {
            print("Error in checking signature: \(error)")
            return false
        }
    }
    
    private func keyAgeIsValid(for createdAt: Int) -> Bool {
        let keyAge = Date().timeIntervalSince1970 - TimeInterval(createdAt)
        return keyAge <= TimeUnit.day(amount: 7).timeInterval
    }
}

extension DailyKeyRepoHandler {
    func fetch() -> Completable {
        Completable.create { (observer) -> Disposable in
            self.fetch {
                observer(.completed)
            } failure: { (error) in
                observer(.error(error))
            }

            return Disposables.create()
        }
    }
}

extension DailyKeyRepoHandler: LogUtil, UnsafeAddress {}
