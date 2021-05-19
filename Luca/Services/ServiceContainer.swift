import Foundation

public class ServiceContainer {

    public static let shared = ServiceContainer()

    var dailyKeyRepository: DailyPubKeyHistoryRepository!
    var ePubKeyHistoryRepository: EphemeralPublicKeyHistoryRepository!
    var ePrivKeyHistoryRepository: EphemeralPrivateKeyHistoryRepository!
    var locationPrivateKeyHistoryRepository: LocationPrivateKeyHistoryRepository!

    var backendAddressV3: BackendAddressV3!

    var backendUserV3: BackendUserV3!
    var backendTraceIdV3: BackendTraceIdV3!
    var backendMiscV3: BackendMiscV3!
    var backendSMSV3: BackendSMSVerificationV3!
    var backendLocationV3: BackendLocationV3!
    var backendDailyKeyV3: DefaultBackendDailyKeyV3!

    var dailyKeyRepoHandler: DailyKeyRepoHandler!

    var userService: UserService!

    var locationUpdater: LocationUpdater!

    var regionMonitor: RegionMonitor!

    var userKeysBundle: UserKeysBundle!

    var userDataPackageBuilderV3: UserDataPackageBuilderV3!
    var checkOutPayloadBuilderV3: CheckOutPayloadBuilderV3!
    var checkInPayloadBuilderV3: CheckInPayloadBuilderV3!
    var qrCodePayloadBuilderV3: QRCodePayloadBuilderV3!
    var userTransferBuilderV3: UserTransferBuilderV3!
    var traceIdAdditionalBuilderV3: TraceIdAdditionalDataBuilderV3!
    var privateMeetingQRCodeBuilderV3: PrivateMeetingQRCodeBuilderV3!

    var traceIdService: TraceIdService!

    var history: HistoryService!
    var historyListener: HistoryEventListener!

    var selfCheckin: SelfCheckinService!
    var privateMeetingService: PrivateMeetingService!

    var userSecrectsConsistencyChecker: UserSecretsConsistencyChecker!

    var accessedTracesChecker: AccessedTraceIdChecker!

    var traceInfoRepo: TraceInfoRepo!
    var accessedTraceIdRepo: AccessedTraceIdRepo!
    var traceIdCoreRepo: TraceIdCoreRepo!
    var locationRepo: LocationRepo!
    var keyValueRepo: KeyValueRepoProtocol!
    var healthDepartmentRepo: HealthDepartmentRepo!

    var coronaTestRepo: CoronaTestRepo!
    var coronaTestFactory: CoronaTestFactory!
    var coronaTestRepoService: CoronaTestRepoService!
    var coronaTestProcessingService: CoronaTestProcessingService!
    var coronaTestUniquenessChecker: CoronaTestUniquenessChecker!

    private(set) var isSetup = false

    // swiftlint:disable:next function_body_length
    func setup() throws {
        if isSetup {
            return
        }
        backendAddressV3 = BackendAddressV3()

        dailyKeyRepository = DailyPubKeyHistoryRepository()
        ePubKeyHistoryRepository = EphemeralPublicKeyHistoryRepository()
        ePrivKeyHistoryRepository = EphemeralPrivateKeyHistoryRepository()
        locationPrivateKeyHistoryRepository = LocationPrivateKeyHistoryRepository()

        locationUpdater = LocationUpdater()

        regionMonitor = RegionMonitor()

        userKeysBundle = UserKeysBundle()
        try userKeysBundle.generateKeys()
        userKeysBundle.removeUnusedKeys()

        userDataPackageBuilderV3 = UserDataPackageBuilderV3(
            userKeysBundle: userKeysBundle)

        qrCodePayloadBuilderV3 = QRCodePayloadBuilderV3(
            keysBundle: userKeysBundle,
            dailyKeyRepo: dailyKeyRepository,
            ePubKeyRepo: ePubKeyHistoryRepository,
            ePrivKeyRepo: ePrivKeyHistoryRepository)

        checkOutPayloadBuilderV3 = CheckOutPayloadBuilderV3()
        checkInPayloadBuilderV3 = CheckInPayloadBuilderV3()
        traceIdAdditionalBuilderV3 = TraceIdAdditionalDataBuilderV3()
        privateMeetingQRCodeBuilderV3 = PrivateMeetingQRCodeBuilderV3(backendAddress: backendAddressV3, preferences: LucaPreferences.shared)

        userTransferBuilderV3 = UserTransferBuilderV3(userKeysBundle: userKeysBundle, dailyKeyRepo: dailyKeyRepository)

        backendSMSV3 = BackendSMSVerificationV3(backendAddress: backendAddressV3)
        backendLocationV3 = BackendLocationV3(backendAddress: backendAddressV3)

        backendUserV3 = BackendUserV3(
            backendAddress: backendAddressV3,
            userDataBuilder: userDataPackageBuilderV3,
            userTransferBuilder: userTransferBuilderV3)

        backendTraceIdV3 = BackendTraceIdV3(
            backendAddress: backendAddressV3,
            checkInBuilder: checkInPayloadBuilderV3,
            checkOutBuilder: checkOutPayloadBuilderV3,
            additionalDataBuilder: traceIdAdditionalBuilderV3)

        backendMiscV3 = BackendMiscV3(backendAddress: backendAddressV3)

        backendDailyKeyV3 = DefaultBackendDailyKeyV3(backendAddress: backendAddressV3)

        dailyKeyRepoHandler = DailyKeyRepoHandler(dailyKeyRepo: dailyKeyRepository, backend: backendDailyKeyV3)

        userService = UserService(preferences: LucaPreferences.shared, backend: backendUserV3, userKeysBundle: userKeysBundle, dailyKeyRepoHandler: dailyKeyRepoHandler)

        privateMeetingService = PrivateMeetingService(
            privateKeys: locationPrivateKeyHistoryRepository,
            preferences: UserDataPreferences(suiteName: "locations"),
            backend: backendLocationV3,
            traceIdAdditionalDataBuilder: traceIdAdditionalBuilderV3)

        traceInfoRepo = TraceInfoRepo()
        accessedTraceIdRepo = AccessedTraceIdRepo()
        traceIdCoreRepo = TraceIdCoreRepo()
        locationRepo = LocationRepo()

        traceIdService = TraceIdService(qrCodeGenerator: qrCodePayloadBuilderV3,
                                        lucaPreferences: LucaPreferences.shared,
                                        dailyKeyRepo: dailyKeyRepository,
                                        ePubKeyRepo: ePubKeyHistoryRepository,
                                        ePrivKeyRepo: ePrivKeyHistoryRepository,
                                        preferences: UserDataPreferences(suiteName: "traceIdService"),
                                        backendTrace: backendTraceIdV3,
                                        backendMisc: backendMiscV3,
                                        backendLocation: backendLocationV3,
                                        privateMeetingService: privateMeetingService,
                                        traceInfoRepo: traceInfoRepo,
                                        locationRepo: locationRepo)

        history = HistoryService(preferences: UserDataPreferences(suiteName: "history"))

        historyListener = HistoryEventListener(historyService: history, traceIdService: traceIdService, userService: userService, privateMeetingService: privateMeetingService)
        historyListener.enable()

        selfCheckin = SelfCheckinService()

        userSecrectsConsistencyChecker = UserSecretsConsistencyChecker(userKeysBundle: userKeysBundle,
                                                                       traceIdService: traceIdService,
                                                                       userService: userService,
                                                                       lucaPreferences: LucaPreferences.shared,
                                                                       dailyKeyHandler: dailyKeyRepoHandler)
        keyValueRepo = RealmKeyValueRepo()
        healthDepartmentRepo = HealthDepartmentRepo()
        accessedTracesChecker = AccessedTraceIdChecker(
            backend: backendMiscV3,
            traceInfoRepo: traceInfoRepo,
            healthDepartmentRepo: healthDepartmentRepo, accessedTraceIdRepo: accessedTraceIdRepo)

        coronaTestRepo = CoronaTestRepo()
        coronaTestFactory = CoronaTestFactory()
        coronaTestRepoService = CoronaTestRepoService(coronaTestRepo: coronaTestRepo,
                                                      coronaTestFactory: coronaTestFactory)
        coronaTestUniquenessChecker = CoronaTestUniquenessChecker(backend: backendMiscV3, keyValueRepo: keyValueRepo)
        coronaTestProcessingService = CoronaTestProcessingService(coronaTestRepoService: coronaTestRepoService,
                                                                  coronaTestFactory: coronaTestFactory,
                                                                  preferences: LucaPreferences.shared,
                                                                  uniquenessChecker: coronaTestUniquenessChecker)

        isSetup = true
    }

}
