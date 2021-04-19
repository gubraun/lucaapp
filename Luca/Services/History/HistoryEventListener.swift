import Foundation
import RxSwift

class HistoryEventListener {
    private let historyService: HistoryService
    private let traceIdService: TraceIdService
    private let userService: UserService
    private let privateMeetingService: PrivateMeetingService

    private var disposeBag: DisposeBag?

    init(historyService: HistoryService, traceIdService: TraceIdService, userService: UserService, privateMeetingService: PrivateMeetingService) {
        self.historyService = historyService
        self.traceIdService = traceIdService
        self.userService = userService
        self.privateMeetingService = privateMeetingService
    }

    /// Enables listening
    func enable() {

        let newDisposeBag = DisposeBag()

        let onUserUpdated = userService.onUserUpdatedRx.do(onNext: { _ in self.add(.userDataUpdate) }).ignoreElements()
        let onUserDataTransfered = userService.onUserDataTransferedRx.do(onNext: { _ in self.add(.userDataTransfer) }).ignoreElements()

        let onCheckIn = traceIdService.onCheckInRx()
            .flatMap { _ in self.fetchCurrentLocation() }
            .do(onNext: { self.add(.checkIn, location: $0) })
            .ignoreElements()

        let onCheckOut = traceIdService.onCheckOutRx()
            .flatMap { _ in self.retrieveCurrentLocation() }
            .do(onNext: { self.add(.checkOut, location: $0) })
            .ignoreElements()

        let onMeetingCreated = privateMeetingService
            .onMeetingCreatedRx
            .do(onNext: { meeting in
                let guestList = self.guestLists(from: meeting)
                let namesList = guestList.map { "\($0.fn) \($0.ln)" }
                self.add(.checkIn, guestlist: namesList)
            })
            .ignoreElements()

        let onMeetingClosed = privateMeetingService
            .onMeetingClosedRx
            .do(onNext: { meeting in
                let guestList = self.guestLists(from: meeting)
                let namesList = guestList.map { "\($0.fn) \($0.ln)" }
                self.add(.checkOut, guestlist: namesList)
            })
            .ignoreElements()

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

    private func retrieveCurrentLocation() -> Single<Location?> {
        Single.from { self.traceIdService.currentLocationInfo }
    }

    private func fetchCurrentLocation() -> Single<Location> {
        self.traceIdService.fetchCurrentLocationInfo()
    }

    private func add(_ type: HistoryEntryType, location: Location? = nil) {
        self.historyService.add(entry: HistoryEntry(date: Date(), type: type, location: location))
    }

    private func add(_ type: HistoryEntryType, location: Location? = nil, guestlist: [String]?) {
        self.historyService.add(entry: HistoryEntry(date: Date(), type: type, location: location, guestlist: guestlist))
    }

}

extension HistoryEventListener: LogUtil, UnsafeAddress {}
