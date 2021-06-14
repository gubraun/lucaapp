import Foundation

protocol RealmDatabaseUtils {

    /// It reads whole database with old key and saves it with the new key. If one of the keys is nil, it means that the source or target file is unencrypted.
    /// - Parameters:
    ///   - oldKey: 64 Byte
    ///   - newKey: 64 Byte
    func changeEncryptionSettings(oldKey: Data?, newKey: Data?, completion: @escaping () -> Void, failure: @escaping ((Error) -> Void))

    /// Removes database file.
    func removeFile(completion: @escaping() -> Void, failure: @escaping ((Error) -> Void))
}
