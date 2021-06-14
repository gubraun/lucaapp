import Foundation
import RxSwift

class HistoryEventListener {
    private let historyService: HistoryService
    private let traceIdService: TraceIdService
    private let userService: UserService
    private let privateMeetingService: PrivateMeetingService
    private let locationRepo: LocationRepo

    private var disposeBag: DisposeBag?

    init(historyService: HistoryService,
         traceIdService: TraceIdService,
         userService: UserService,
         privateMeetingService: PrivateMeetingService,
         locationRepo: LocationRepo) {
        self.historyService = historyService
        self.traceIdService = traceIdService
        self.userService = userService
        self.privateMeetingService = privateMeetingService
        self.locationRepo = locationRepo
    }

    /// Enables listening
    func enable() {

        let newDisposeBag = DisposeBag()

        let onUserUpdated = userService.onUserUpdatedRx.flatMap { _ in self.add(.userDataUpdate) }.ignoreElementsAsCompletable()
        let onUserDataTransfered = userService.onUserDataTransferedRx.flatMap { self.add(.userDataTransfer, numberOfDaysShared: $0) }.ignoreElementsAsCompletable()

        let onCheckIn = traceIdService.onCheckInRx()
            .flatMap { _ in self.fetchCurrentLocation() }
            .flatMap { self.add(.checkIn, location: $0) }
            .ignoreElementsAsCompletable()

        let onCheckOut = traceIdService.onCheckOutRx()
            .unwrapOptional()
            .flatMap { traceInfo in
                self.locationRepo
                    .restore()
                    .map { locations in locations.first(where: {$0.locationId == traceInfo.locationId}) }
                    .unwrapOptional()
            }
            .flatMap { self.add(.checkOut, location: $0) }
            .ignoreElementsAsCompletable()

        let onMeetingCreated = privateMeetingService
            .onMeetingCreatedRx
            .flatMap { meeting -> Completable in
                let guestList = self.guestLists(from: meeting)
                let namesList = guestList.map { "\($0.fn) \($0.ln)" }
                return self.add(.checkIn, guestlist: namesList)
            }
            .ignoreElementsAsCompletable()

        let onMeetingClosed = privateMeetingService
            .onMeetingClosedRx
            .flatMap { meeting -> Completable in
                let guestList = self.guestLists(from: meeting)
                let namesList = guestList.map { "\($0.fn) \($0.ln)" }
                return self.add(.checkOut, guestlist: namesList)
            }
            .ignoreElementsAsCompletable()

        Completable.zip(onUserUpdated,
                        onUserDataTransfered,
                        onCheckIn,
                        onCheckOut,
                        onMeetingCreated,
                        onMeetingClosed)
            .logError(self)
            .retry(delay: .milliseconds(100), scheduler: LucaScheduling.backgroundScheduler)
            .subscribe()
            .disposed(by: newDisposeBag)

        disposeBag = newDisposeBag
    }

    /// Disables listening
    func disable() {
        disposeBag = nil
    }

    private func guestLists(from meeting: PrivateMeetingData) -> [PrivateMeetingQRCodeV3AdditionalData] {
        var guestList: [PrivateMeetingQRCodeV3AdditionalData] = []
        let guestsData = meeting.guests
            .filter { $0.data != nil }

        for guest in guestsData {
            if let data = try? self.privateMeetingService.decrypt(guestData: guest, meetingKeyIndex: meeting.keyIndex) {
                guestList.append(data)
            }
        }
        return guestList
    }

//    private func retrieveCurrentLocation() -> Single<Location> {
//        self.traceIdService.fetchCurrentLocationInfo()
//    }

    private func fetchCurrentLocation() -> Single<Location> {
        self.traceIdService.fetchCurrentLocationInfo()
    }

    private func add(_ type: HistoryEntryType, numberOfDaysShared: Int) -> Completable {
        self.historyService.add(entry: HistoryEntry(date: Date(), type: type, numberOfDaysShared: numberOfDaysShared))
    }

    private func add(_ type: HistoryEntryType, location: Location? = nil) -> Completable {
        self.historyService.add(entry: HistoryEntry(date: Date(), type: type, location: location))
    }

    private func add(_ type: HistoryEntryType, location: Location? = nil, guestlist: [String]?) -> Completable {
        self.historyService.add(entry: HistoryEntry(date: Date(), type: type, location: location, guestlist: guestlist))
    }

}

extension HistoryEventListener: LogUtil, UnsafeAddress {}
