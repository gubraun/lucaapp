import Foundation
import RxSwift

struct Person: Codable, DataRepoModel {
    var identifier: Int? = Int.random(in: Int.min...Int.max)
    var firstName: String
    var lastName: String

    var fullName: String {
        return "\(firstName) \(lastName)"
    }

    /// List of all TraceInfo identifiers this person was checked in
    var traceInfoIDs: [Int] = []
}

extension Person {
    func isAssociated(with traceInfo: TraceInfo) -> Bool {
        traceInfoIDs.contains(traceInfo.identifier ?? -1)
    }
}

class PersonService {

    private let personRepo: PersonRepo
    private let documentProcessing: DocumentProcessingService

    init(personRepo: PersonRepo, documentProcessing: DocumentProcessingService) {
        self.personRepo = personRepo
        self.documentProcessing = documentProcessing
    }

    /// Creates a new person with given names
    /// - Parameters:
    ///   - firstName: first name
    ///   - lastName: last name
    func create(firstName: String, lastName: String) -> Single<Person> {
        let person = Person(firstName: firstName, lastName: lastName)
        return personRepo.store(object: person)
    }

    /// Updates the person.
    ///
    /// The `identifier` has to stay unchanged to guarantee the object to update
    /// - Parameter person: person to update
    func update(person: Person) -> Completable {
        personRepo.store(object: person)
            .asCompletable()
            .andThen(documentProcessing.revalidateSavedTests())
    }

    /// Removes a specific person
    /// - Parameter person: person to remove
    func remove(person: Person) -> Completable {
        Maybe<Int>.from { person.identifier }
            .asObservable()
            .flatMap { self.personRepo.remove(identifiers: [$0]) }
            .asCompletable()
            .andThen(documentProcessing.revalidateSavedTests())
    }

    /// Retrieves all persons with or without a specific predicate
    /// - Parameter predicate: if not given, all persons would be retrieved
    func retrieve(_ predicate: ((Person) -> Bool)? = nil) -> Single<[Person]> {
        personRepo
            .restore()
            .map { array in array.filter { predicate?($0) ?? true } }
    }

    /// Retrieves all persons that are associated with given TraceInfo
    /// - Parameter traceInfo: TraceInfo to search for
    func retrieveAssociated(with traceInfo: TraceInfo) -> Single<[Person]> {
        retrieve { $0.identifier == traceInfo.identifier }
    }

    /// Adds and saves an association of specific persons
    /// - Parameters:
    ///   - persons: persons to associate the traceInfo with
    ///   - traceInfo: traceInfo to associate
    func associate(persons: [Person], with traceInfo: TraceInfo) -> Completable {
        Single.from { persons.map { $0.identifier } }
            .asObservable()
            .flatMap { inputIDs in self.retrieve { inputIDs.contains($0.identifier) } }
            .flatMap { Observable.from($0) }
            .map { immutablePerson in
                var temp = immutablePerson
                temp.traceInfoIDs.append(traceInfo.identifier ?? -1)
                return temp
            }
            .toArray()
            .flatMap(personRepo.store)
            .asCompletable()
    }

    /// Removes the association of selected persons with a given traceInfo
    func removeAssociation(persons: [Person], from traceInfo: TraceInfo) -> Completable {
        Single.from { persons.map { $0.identifier } }
            .asObservable()
            .flatMap { inputIDs in self.retrieve { inputIDs.contains($0.identifier) } }
            .flatMap { Observable.from($0) }
            .map { immutablePerson in
                var temp = immutablePerson
                temp.traceInfoIDs = immutablePerson.traceInfoIDs.filter { $0 == traceInfo.identifier ?? -1 }
                return temp
            }
            .toArray()
            .flatMap(personRepo.store)
            .asCompletable()
    }
}
