import Foundation
import RealmSwift
import RxSwift

extension RealmDatabaseUtils {

    /// Removes database file
    func removeFile() -> Completable {
        Completable.create { (observer) -> Disposable in

            self.removeFile {
                observer(.completed)
            } failure: { (error) in
                observer(.error(error))
            }

            return Disposables.create()
        }
    }

    /// It reads the database with the old key and saves it with the new key. If one of the keys is nil, it means that the source or target file is unencrypted.
    /// - Parameters:
    ///   - oldKey: 64 Bytes length
    ///   - newKey: 64 Bytes length
    func changeEncryptionSettings(oldKey: Data?, newKey: Data?) -> Completable {
        Completable.create { (observer) -> Disposable in
            self.changeEncryptionSettings(oldKey: oldKey, newKey: newKey) {
                observer(.completed)
            } failure: { (error) in
                observer(.error(error))
            }

            return Disposables.create()
        }
    }
}
