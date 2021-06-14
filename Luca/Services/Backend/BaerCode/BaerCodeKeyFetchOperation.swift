import Foundation
import Alamofire
import RxSwift

class BaerCodeKeyFetchOperation {

    static let url = URL(string: "https://s3-de-central.profitbricks.com/")!

    static func fetch(completion: @escaping(Data) -> Void, failure: @escaping(Error) -> Void) {
        let fullUrl = url.appendingPathComponent("baercode").appendingPathComponent("bundle.cose")

        AF.request(fullUrl, method: .get, encoding: URLEncoding.httpBody, headers: [:]).responseData(completionHandler: { response in
            switch response.result {
            case .success:
                if let data = response.data {
                    completion(data)
                }
            case .failure(let error):
                failure(error)
            }
        })
    }

    static func fetchRx() -> Single<Data> {
        Single<Data>.create { (observer) -> Disposable in
            fetch(completion: { data in
                observer(.success(data))
            }, failure: { error in
                observer(.failure(error))
            })
            return Disposables.create()
        }
    }

}
