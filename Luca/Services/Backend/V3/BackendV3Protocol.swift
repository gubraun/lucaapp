import Foundation

protocol BackendUserV3Protocol {

    func create(userData: UserRegistrationData) -> AsyncDataOperation<BackendError<CreateUserError>, UUID>
    func userExists(userId: UUID) -> AsyncOperation<BackendError<UserExistsError>>
    func update(userId: UUID, userData: UserRegistrationData) -> AsyncOperation<BackendError<UpdateUserError>>
    func userTransfer(userId: UUID, numberOfDays: Int) -> AsyncDataOperation<BackendError<UserTransferError>, String>
    func delete(userId: UUID) -> AsyncOperation<BackendError<DeleteUserError>>
}

protocol BackendDailyKeyV3 {
    associatedtype ErrorType: Error

    func retrieveDailyPubKey() -> AsyncDataOperation<ErrorType, PublicKeyFetchResultV3>

    func retrieveIssuerKeys(issuerId: String) -> AsyncDataOperation<ErrorType, IssuerKeysFetchResultV3>
}

protocol BackendTraceIdV3Protocol {

    func checkIn(qrCode: QRCodePayloadV3, venuePubKey: KeySource, scannerId: String) -> AsyncOperation<BackendError<CheckInError>>
    func fetchInfo(traceId: TraceId) -> AsyncDataOperation<BackendError<FetchTraceInfoError>, TraceInfo>
    func fetchInfo(traceIds: [TraceId]) -> AsyncDataOperation<BackendError<FetchTraceInfoError>, [TraceInfo]>
    func checkOut(traceId: TraceId, timestamp: Date) -> AsyncOperation<BackendError<CheckOutError>>
    func updateAdditionalData<T>(traceId: TraceId, scannerId: String, venuePubKey: KeySource, additionalData: T) -> AsyncOperation<BackendError<UploadAdditionalDataError>> where T: Encodable
}
