import Foundation

class DataRepo<Model>: DataRepoProtocol where Model: DataRepoModel {
    
    var onDataChanged: String {
        return "\(String(describing: self)).onDataChanged"
    }
    
    func restore(completion: @escaping ([Model]) -> Void, failure: @escaping ErrorCompletion) {
        fatalError()
    }
    
    func remove(identifiers: [Int], completion: @escaping () -> Void, failure: @escaping ErrorCompletion) {
        fatalError()
    }
    
    func store(object: Model, completion: @escaping (Model)->Void, failure: @escaping ErrorCompletion) {
        fatalError()
    }
    
    func store(objects: [Model], completion: @escaping ([Model])->Void, failure: @escaping ErrorCompletion) {
        fatalError()
    }
    
    func removeAll(completion: @escaping () -> Void, failure: @escaping ErrorCompletion) {
        fatalError()
    }
}
