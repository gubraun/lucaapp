import Foundation
import RxSwift
import RxBlocking

public class ServiceContainer {

    public static let shared = ServiceContainer()

    var dailyKeyRepository: DailyPubKeyHistoryRepository!
    var ePubKeyHistoryRepository: EphemeralPublicKeyHistoryRepository!
    var ePrivKeyHistoryRepository: EphemeralPrivateKeyHistoryRepository!
    var locationPrivateKeyHistoryRepository: LocationPrivateKeyHistoryRepository!
    var localDBKeyRepository: DataKeyRepository!

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

    var autoCheckoutService: AutoCheckoutService!

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
    var keyValueRepo: RealmKeyValueRepo!
    var healthDepartmentRepo: HealthDepartmentRepo!
    var historyRepo: HistoryRepo!
    var documentRepo: DocumentRepo!
    var testProviderKeyRepo: TestProviderKeyRepo!

    /// Aggregated realm databases when some global changes on all DBs are needed.
    var realmDatabaseUtils: [RealmDatabaseUtils] = []

    var documentKeyProvider: DocumentKeyProvider!
    var documentFactory: DocumentFactory!
    var documentRepoService: DocumentRepoService!
    var documentProcessingService: DocumentProcessingService!
    var documentUniquenessChecker: DocumentUniquenessChecker!

    var baerCodeKeyService: BaerCodeKeyService!
    var notificationService: NotificationService!

    private(set) var isSetup = false

    // swiftlint:disable:next function_body_length
    func setup(forceReinitialize: Bool = false) throws {
        if isSetup {
            if forceReinitialize {
                disableAllServices()
            } else {
                return
            }
        }
        backendAddressV3 = BackendAddressV3()

        dailyKeyRepository = DailyPubKeyHistoryRepository()
        ePubKeyHistoryRepository = EphemeralPublicKeyHistoryRepository()
        ePrivKeyHistoryRepository = EphemeralPrivateKeyHistoryRepository()
        locationPrivateKeyHistoryRepository = LocationPrivateKeyHistoryRepository()
        localDBKeyRepository = DataKeyRepository(tag: "LocalDBKey")

        locationUpdater = LocationUpdater()

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

        try setupRepos()

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
                                        locationRepo: locationRepo,
                                        traceIdCoreRepo: traceIdCoreRepo)

        autoCheckoutService = AutoCheckoutService(
            keyValueRepo: keyValueRepo,
            traceIdService: traceIdService,
            locationUpdater: locationUpdater,
            oldLucaPreferences: LucaPreferences.shared
        )
        autoCheckoutService.enable()

        history = HistoryService(
            preferences: UserDataPreferences(suiteName: "history"),
            historyRepo: historyRepo
        )

        historyListener = HistoryEventListener(
            historyService: history,
            traceIdService: traceIdService,
            userService: userService,
            privateMeetingService: privateMeetingService,
            locationRepo: locationRepo,
            historyRepo: historyRepo,
            traceInfoRepo: traceInfoRepo)

        historyListener.enable()

        selfCheckin = SelfCheckinService()

        userSecrectsConsistencyChecker = UserSecretsConsistencyChecker(userKeysBundle: userKeysBundle,
                                                                       traceIdService: traceIdService,
                                                                       userService: userService,
                                                                       lucaPreferences: LucaPreferences.shared,
                                                                       dailyKeyHandler: dailyKeyRepoHandler)

        accessedTracesChecker = AccessedTraceIdChecker(
            backend: backendMiscV3,
            traceInfoRepo: traceInfoRepo,
            healthDepartmentRepo: healthDepartmentRepo, accessedTraceIdRepo: accessedTraceIdRepo)

        baerCodeKeyService = BaerCodeKeyService(preferences: LucaPreferences.shared)
        notificationService = NotificationService(traceIdService: traceIdService, autoCheckoutService: autoCheckoutService)
        notificationService.enable()

        setupDocuments()

        isSetup = true
    }

    private func disableAllServices() {
        if !isSetup {
            return
        }

        locationUpdater.stop()
        autoCheckoutService.disable()
        historyListener.disable()
        notificationService.disable()

        accessedTracesChecker.disposeNotificationOnMatch()
        notificationService.removePendingNotifications()
    }

    func setupRepos() throws {
        var currentKey: Data! = localDBKeyRepository.retrieveKey()
        let keyWasAvailable = currentKey != nil
        if !keyWasAvailable {
            self.log("No DB Key found, generating one...")
            guard let bytes = KeyFactory.randomBytes(size: 64) else {
                throw NSError(domain: "Couldn't generate random bytes for local DB key", code: 0, userInfo: nil)
            }
            if !localDBKeyRepository.store(key: bytes, removeIfExists: true) {
                throw NSError(domain: "Couldn't store local DB key", code: 0, userInfo: nil)
            }
            currentKey = bytes
            self.log("DB Key generated and stored succesfully.")
        }

        traceInfoRepo = TraceInfoRepo(key: currentKey)
        accessedTraceIdRepo = AccessedTraceIdRepo(key: currentKey)
        traceIdCoreRepo = TraceIdCoreRepo(key: currentKey)
        locationRepo = LocationRepo(key: currentKey)
        historyRepo = HistoryRepo(key: currentKey)
        keyValueRepo = RealmKeyValueRepo(key: currentKey)
        healthDepartmentRepo = HealthDepartmentRepo(key: currentKey)
        documentRepo = DocumentRepo(key: currentKey)
        testProviderKeyRepo = TestProviderKeyRepo(key: currentKey)

        realmDatabaseUtils = [
            traceInfoRepo,
            accessedTraceIdRepo,
            traceIdCoreRepo,
            locationRepo,
            historyRepo,
            keyValueRepo,
            healthDepartmentRepo,
            documentRepo,
            testProviderKeyRepo
        ]

        if !keyWasAvailable {
            self.log("Applying new key to the repos")

            let changeEncryptionCompletables = self.realmDatabaseUtils
                .map { $0.changeEncryptionSettings(oldKey: nil, newKey: currentKey)
                    .logError(self, "\(String(describing: $0.self)): Changing encryption")
                }

            let array = try Completable.zip(changeEncryptionCompletables)
            .debug("KT TOTAL")
            .do(onError: { error in
                fatalError("failed to change encryption settings. Error: \(error)")
            })
            .toBlocking() // This blocking is crucial here. I want to block the app until the settings are done.
            .toArray()

            self.log("New keys applied successfully")

            print(array)
        }
    }

    private func setupDocuments() {

        documentKeyProvider = DocumentKeyProvider(backend: backendMiscV3, testProviderKeyRepo: testProviderKeyRepo)

        documentFactory = DocumentFactory()

//        documentFactory.register(parser: UbirchParser())
        documentFactory.register(parser: DGCParser())
        documentFactory.register(parser: AppointmentParser())
        documentFactory.register(parser: BaerCodeParser())
        documentFactory.register(parser: DefaultJWTParser(keyProvider: documentKeyProvider))
        documentFactory.register(parser: JWTParserWithOptionalDoctor(keyProvider: documentKeyProvider))

        documentRepoService = DocumentRepoService(documentRepo: documentRepo, documentFactory: documentFactory)
        documentUniquenessChecker = DocumentUniquenessChecker(backend: backendMiscV3, keyValueRepo: keyValueRepo)
        documentProcessingService = DocumentProcessingService(
            documentRepoService: documentRepoService,
            documentFactory: documentFactory,
            uniquenessChecker: documentUniquenessChecker)

        documentProcessingService.register(validator: CoronaTestIsNegativeValidator())
        documentProcessingService.register(validator: DGCIssuerValidator())

        #if !DEVELOPMENT
        documentProcessingService.register(validator: CoronaTestOwnershipValidator(preferences: LucaPreferences.shared))
        documentProcessingService.register(validator: VaccinationOwnershipValidator(preferences: LucaPreferences.shared))
        documentProcessingService.register(validator: RecoveryOwnershipValidator(preferences: LucaPreferences.shared))
        #endif

        #if PREPROD || PRODUCTION
        documentProcessingService.register(validator: CoronaTestValidityValidator())
        documentProcessingService.register(validator: RecoveryValidityValidator())
        documentProcessingService.register(validator: AppointmentValidityValidator())
        #endif
    }
}

extension ServiceContainer: UnsafeAddress, LogUtil {}
