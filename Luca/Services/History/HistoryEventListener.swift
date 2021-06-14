import Foundation
import RxSwift

class HistoryEventListener {
    private let historyService: HistoryService
    private let traceIdService: TraceIdService
    private let userService: UserService
    private let privateMeetingService: PrivateMeetingService
    private let locationRepo: LocationRepo
    private let historyRepo: HistoryRepo
    private let traceInfoRepo: TraceInfoRepo

    private var disposeBag: DisposeBag?

    init(historyService: HistoryService,
         traceIdService: TraceIdService,
         userService: UserService,
         privateMeetingService: PrivateMeetingService,
         locationRepo: LocationRepo,
         historyRepo: HistoryRepo,
         traceInfoRepo: TraceInfoRepo) {
        self.historyService = historyService
        self.traceIdService = traceIdService
        self.userService = userService
        self.privateMeetingService = privateMeetingService
        self.locationRepo = locationRepo
        self.historyRepo = historyRepo
        self.traceInfoRepo = traceInfoRepo
    }

    /// Enables listening
    func enable() {

        let newDisposeBag = DisposeBag()

        let onUserUpdated = userService.onUserUpdatedRx.flatMap { _ in self.add(.userDataUpdate) }.ignoreElementsAsCompletable()
        let onUserDataTransfered = userService.onUserDataTransferedRx.flatMap { self.add(.userDataTransfer, numberOfDaysShared: $0) }.ignoreElementsAsCompletable()

        let onCheckIn = traceIdService.onCheckInRx()
            .flatMap {
                self.fetchCurrentLocation()
                    .asObservable()
                    .ignoreElementsAsCompletable()
                    .andThen(Single.just($0))
            }
            .flatMap { self.add(.checkIn, traceInfo: $0) }
            .ignoreElementsAsCompletable()

        let onCheckOut = traceIdService.onCheckOutRx()
            .flatMap { self.add(.checkOut, traceInfo: $0) }
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

        let recreateHistory = isHistoryCorrupted()
            .flatMapCompletable { isCorrupted in
                if isCorrupted {
                    return self.saveLocationsFromMeetings().andThen(self.recreateHistory())
                }
                return Completable.empty()
            }

        Completable.zip(onUserUpdated,
                        onUserDataTransfered,
                        onCheckIn,
                        onCheckOut,
                        onMeetingCreated,
                        onMeetingClosed,
                        recreateHistory)
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

    private func isHistoryCorrupted() -> Single<Bool> {

        let checkInsWithoutTraceInfo = historyRepo.restore()
            .map { events in events.filter { $0.guestlist == nil } }                            // Ignore private meeting events
            .map { events in events.filter { $0.type == .checkIn || $0.type == .checkOut } }    // Take checkIn and checkOut events
            .map { events in events.filter { $0.traceInfo == nil } }                            // Take events without traceInfo
            .map { !$0.isEmpty }                                                                // It should be empty

        let areCheckInsBalanced = historyRepo.restore()
            .map { events in events.filter { $0.type == .checkIn || $0.type == .checkOut } }
            .map { events -> Bool in
                let checkIns = events.filter { $0.type == .checkIn }.count
                let checkOuts = events.filter { $0.type == .checkOut }.count

                // There can be only one checkOut left over (when user is checked in)
                return checkIns == checkOuts || checkIns == checkOuts + 1
            }

        return Single.zip(checkInsWithoutTraceInfo, areCheckInsBalanced)
            .map { (checkInsWithoutTraceInfo, areCheckInsBalanced) in

                // If there are any checkIns without traceInfos or the checkIns and checkOuts are unbalanced
                return checkInsWithoutTraceInfo || !areCheckInsBalanced
            }
            .debug("is history corrupted")
    }

    /// It's needed when recreating history. Old locations (prior to 1.6.3) haven't been saved with a name to the repo for private meetings
    private func saveLocationsFromMeetings() -> Completable {
        historyRepo.restore()
            .map { events in events.map { $0.location }.filter { $0 != nil }.map { $0! } }                              // Filter all non-nil locations
            .map { locations in locations.filter { $0.name != nil || $0.groupName != nil || $0.locationName != nil } }  // Take only locations that have some name
            .flatMap(locationRepo.store)
            .asCompletable()
    }

    private func recreateHistory() -> Completable {
        historyRepo.restore()
            .map { events in events.filter { $0.guestlist == nil } }                            // Ignore meetings as host
            .map { events in events.filter { $0.type == .checkIn || $0.type == .checkOut } }    // Take only checkIns and checkOuts
            .map { events in events.map { $0.identifier ?? 0 } }
            .flatMapCompletable(historyRepo.remove)
            .andThen(traceInfoRepo.restore())
            .asObservable()
            .flatMap { Observable.from($0) }
            .flatMap { traceInfo -> Completable in
                if traceInfo.checkOutDate == nil {
                    return self.add(.checkIn, traceInfo: traceInfo)
                }
                return self.add(.checkIn, traceInfo: traceInfo).andThen(self.add(.checkOut, traceInfo: traceInfo))
            }
            .ignoreElementsAsCompletable()
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

    private func fetchCurrentLocation() -> Single<Location> {
        self.traceIdService.fetchCurrentLocationInfo()
    }

    private func add(_ type: HistoryEntryType, numberOfDaysShared: Int) -> Completable {
        self.historyService.add(entry: HistoryEntry(date: Date(), type: type, numberOfDaysShared: numberOfDaysShared))
    }

    private func add(_ type: HistoryEntryType) -> Completable {
        self.historyService.add(entry: HistoryEntry(date: Date(), type: type, location: nil, traceInfo: nil))
    }

    private func add(_ type: HistoryEntryType, traceInfo: TraceInfo) -> Completable {
        Single<Date?>.from {
            if type == .checkIn {
                return traceInfo.checkInDate
            }
            return traceInfo.checkOutDate
        }
        .asObservable()
        .unwrapOptional()
        .flatMap { date in
            self.locationRepo.restore()
                .asObservable()
                .map { locations -> Location? in
                    let location = locations.first(where: { $0.locationId == traceInfo.locationId })

                    return location
                }
                .unwrapOptional()
                .flatMap { self.historyService.add(entry: HistoryEntry(date: date, type: type, location: $0, traceInfo: traceInfo)) }
        }
        .ignoreElementsAsCompletable()
    }

    private func add(_ type: HistoryEntryType, location: Location? = nil, guestlist: [String]?) -> Completable {
        self.historyService.add(entry: HistoryEntry(date: Date(), type: type, location: location, guestlist: guestlist))
    }

}

extension HistoryEventListener: LogUtil, UnsafeAddress {}
