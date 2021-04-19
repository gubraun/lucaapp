import CryptoSwift

class HMACSHA256: Encryption {
    private let key: Data

    init(key: Data) {
        self.key = key
    }

    func encrypt(data: Data) throws -> Data {
        let hmac = HMAC(key: key.bytes, variant: .sha256)
        let bytes = try hmac.authenticate(data.bytes)
        return Data(bytes)
    }

}
