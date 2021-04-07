import Foundation
import RxSwift

class UserKeysBundle {
    
    let onDataPurge = "UserKeysBundle.onDataPurge"
    let onDataPopulation = "UserKeysBundle.onDataPopulation"
    
    private let publicKeyTag = "userKeysBundle.public"
    private let privateKeyTag = "userKeysBundle.private"
    private let dataSecretTag = "userKeysBundle.data"
    private let oldTraceSecretTag = "userKeysBundle.traceSecret"
    private let traceSecretTag = "userKeysBundle.traceSecrets"
    
    private let _publicKey: KeyRepository<SecKey>
    private let _privateKey: KeyRepository<SecKey>
    private let _dataSecret: KeyRepository<Data>
    private let _oldTraceSecret: KeyRepository<Data>
    private let _traceSecrets: DailyDataKeyRepository
    
    var publicKey: KeySource { _publicKey }
    var privateKey: KeySource { _privateKey }
    var dataSecret: RawKeySource { _dataSecret }
    var traceSecrets: DailyDataKeyRepository { _traceSecrets }
    
    init() {
        _publicKey = SecKeyRepository(tag: publicKeyTag)
        _privateKey = SecKeyRepository(tag: privateKeyTag)
        _dataSecret = DataKeyRepository(tag: dataSecretTag)
        _oldTraceSecret = DataKeyRepository(tag: oldTraceSecretTag)
        _traceSecrets = DailyDataKeyRepository(header: traceSecretTag)
        _traceSecrets.factory = self.createUserTraceSecret
    }
    
    /// Removes all keys. Use with care as all data, that has been encrypted with those keys, won't be decryptable anymore
    func removeKeys() {
        _publicKey.purge()
        _privateKey.purge()
        _dataSecret.purge()
        _traceSecrets.removeAll()
        NotificationCenter.default.post(Notification(name: Notification.Name(onDataPurge), object: self, userInfo: nil))
    }
    
    /// It will generate missing keys. It won't remove already filled keys.
    /// Generates new trace secret for current day if there is no key
    func generateKeys(forceRefresh: Bool = false) throws {
        if forceRefresh {
            removeKeys()
        }
        var dataHasBeenCreated = false
        if _privateKey.restore() == nil || _publicKey.restore() == nil {
            
            //Invalidate public key
            _publicKey.purge()
            _privateKey.purge()
            
            guard let privateKey = KeyFactory.createPrivate(tag: privateKeyTag, type: .ecsecPrimeRandom, sizeInBits: 256) else {
                throw NSError(domain: "Private key couldn't be created!", code: 0, userInfo: nil)
            }
            
            guard _privateKey.store(key: privateKey) else {
                throw NSError(domain: "Private key couldn't be stored!", code: 0, userInfo: nil)
            }
            
            guard let publicKey = KeyFactory.derivePublic(from: privateKey) else {
                throw NSError(domain: "Public key couldn't be created!", code: 0, userInfo: nil)
            }
            
            guard _publicKey.store(key: publicKey) else {
                throw NSError(domain: "Public key couldn't be stored!", code: 0, userInfo: nil)
            }
            dataHasBeenCreated = true
        }
        
        let dataSecret = _dataSecret.restore()
        if dataSecret == nil || dataSecret?.bytes.count != 16 {
            guard let randomData = KeyFactory.randomBytes(size: 16) else {
                throw NSError(domain: "Couldn't create random data!", code: 0, userInfo: nil)
            }
            _dataSecret.purge()
            guard _dataSecret.store(key: randomData) else {
                throw NSError(domain: "Data key couldn't be stored!", code: 0, userInfo: nil)
            }
            dataHasBeenCreated = true
        }
        
        let traceSecret = try? _traceSecrets.restore(index: Date(), enableFactoryIfAvailable: false)
        if let oldTraceSecret = _oldTraceSecret.restore(),
           (traceSecret == nil || traceSecret?.bytes.count != 16) {
            
            // Migrate old traceSecret and assign as todays secret
            log("Migrating the old trace secret.")
            // Save the keys for the last two weeks to be compatible with all possible trace IDs saved in the app.
            // Those keys will be removed in the sanity check
            let now = Date()
            for i in 0...14 {
                if let date = Calendar.current.date(byAdding: .day, value: -i, to: now) {
                    try _traceSecrets.store(key: oldTraceSecret, index: date)
                }
            }
            _oldTraceSecret.purge()
        }
        
        if dataHasBeenCreated {
            NotificationCenter.default.post(Notification(name: Notification.Name(onDataPopulation), object: self, userInfo: nil))
        }
    }
    
    private func createUserTraceSecret(for date: Date) throws -> Data {
        log("Generating new trace secret for \(date)")
        guard let randomData = KeyFactory.randomBytes(size: 16) else {
            throw NSError(domain: "Couldn't create user trace secret", code: 0, userInfo: nil)
        }
        return randomData
    }
    
    /// Removes keys that are out of date
    func removeUnusedKeys() {
        if let thresholdDate = Calendar.current.date(byAdding: .day, value: -15, to: Date()) {
            let tooOldDates = _traceSecrets.indices.filter { $0 < thresholdDate }
            for tooOldDate in tooOldDates {
                _traceSecrets.remove(index: tooOldDate)
            }
        }
    }
}

extension UserKeysBundle {
    var isComplete: Bool {
        
        publicKey.retrieveKey() != nil &&
        privateKey.retrieveKey() != nil &&
        dataSecret.retrieveKey() != nil
    }
}

extension UserKeysBundle {
    var onDataPurgeRx: Observable<Void> {
        NotificationCenter.default.rx.notification(NSNotification.Name(self.onDataPurge), object: self).map { _ in Void() }
    }
    var onDataPopulationRx: Observable<Void> {
        NotificationCenter.default.rx.notification(NSNotification.Name(self.onDataPopulation), object: self).map { _ in Void() }
    }
}

extension UserKeysBundle: LogUtil, UnsafeAddress {}
