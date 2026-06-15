import Foundation
import Testing
@testable import DartBuddy

@MainActor
@Test(.tags(.unit, .settings, .regression))
func settingsOnAppearLoadsAndAppliesPreferences() async {
    let settings = makeSettings(appearanceModeRaw: "dark", hapticsEnabled: false, soundEnabled: false)
    let repository = FakeSettingsRepository(settings: settings)
    let preferences = UserPreferencesStore()
    let vm = SettingsViewModel(
        repository: repository,
        logger: testLogger(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections(),
        userPreferencesStore: preferences
    )

    await vm.onAppear()

    #expect(vm.state == .ready)
    #expect(vm.settings?.appearanceModeRaw == "dark")
    #expect(preferences.preferredColorScheme == .dark)
    #expect(preferences.feedback.hapticsEnabled == false)
    #expect(preferences.feedback.soundEnabled == false)
    #expect(preferences.feedback.turnTotalCallerEnabled == false)
    #expect(preferences.feedback.botStaggerEnabled == true)
    #expect(preferences.feedback.botDartHapticsEnabled == true)
}

@MainActor
@Test(.tags(.unit, .settings, .regression))
func settingsUpdateAppearancePersistsAndSyncsPreferences() async {
    let repository = FakeSettingsRepository(settings: makeSettings(appearanceModeRaw: "system"))
    let preferences = UserPreferencesStore()
    let vm = SettingsViewModel(
        repository: repository,
        logger: testLogger(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections(),
        userPreferencesStore: preferences
    )
    await vm.onAppear()

    await vm.updateAppearance("light")

    #expect(vm.state == .ready)
    #expect(vm.settings?.appearanceModeRaw == "light")
    #expect(preferences.preferredColorScheme == .light)
    #expect(await repository.updateCallCount == 1)
}

@MainActor
@Test(.tags(.unit, .settings, .regression))
func settingsUpdateFeedbackTogglesHapticsAndSound() async {
    let repository = FakeSettingsRepository(settings: makeSettings())
    let preferences = UserPreferencesStore()
    let vm = SettingsViewModel(
        repository: repository,
        logger: testLogger(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections(),
        userPreferencesStore: preferences
    )
    await vm.onAppear()

    await vm.updateFeedback(haptics: false, sound: false)

    #expect(vm.settings?.hapticsEnabled == false)
    #expect(vm.settings?.soundEnabled == false)
    #expect(preferences.feedback.hapticsEnabled == false)
    #expect(preferences.feedback.soundEnabled == false)
}

@MainActor
@Test(.tags(.unit, .settings, .regression))
func settingsUpdateFeedbackTogglesTurnTotalCaller() async {
    let repository = FakeSettingsRepository(settings: makeSettings())
    let preferences = UserPreferencesStore()
    let vm = SettingsViewModel(
        repository: repository,
        logger: testLogger(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections(),
        userPreferencesStore: preferences
    )
    await vm.onAppear()

    await vm.updateFeedback(turnTotalCaller: true)

    #expect(vm.settings?.turnTotalCallerEnabled == true)
    #expect(preferences.feedback.turnTotalCallerEnabled == true)
}

@MainActor
@Test(.tags(.unit, .settings, .regression))
func settingsUpdateBotPacingPersistsAndSyncsPreferences() async {
    let repository = FakeSettingsRepository(settings: makeSettings())
    let preferences = UserPreferencesStore()
    let vm = SettingsViewModel(
        repository: repository,
        logger: testLogger(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections(),
        userPreferencesStore: preferences
    )
    await vm.onAppear()

    await vm.updateBotPacing(stagger: false, dartHaptics: false)

    #expect(vm.settings?.botStaggerEnabled == false)
    #expect(vm.settings?.botDartHapticsEnabled == false)
    #expect(preferences.feedback.botStaggerEnabled == false)
    #expect(preferences.feedback.botDartHapticsEnabled == false)
    #expect(await repository.updateCallCount == 1)
}

@MainActor
@Test(.tags(.unit, .settings, .regression))
func settingsUpdateBotPacingCanToggleIndependently() async {
    let repository = FakeSettingsRepository(settings: makeSettings())
    let vm = SettingsViewModel(
        repository: repository,
        logger: testLogger(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections(),
        userPreferencesStore: UserPreferencesStore()
    )
    await vm.onAppear()

    await vm.updateBotPacing(stagger: false)
    #expect(vm.settings?.botStaggerEnabled == false)
    #expect(vm.settings?.botDartHapticsEnabled == true)

    await vm.updateBotPacing(dartHaptics: false)
    #expect(vm.settings?.botStaggerEnabled == false)
    #expect(vm.settings?.botDartHapticsEnabled == false)
}

@MainActor
@Test(.tags(.unit, .settings, .scoringInput, .regression))
func settingsUpdateDartEntryPresentationPersistsAndSyncsPreferences() async {
    let repository = FakeSettingsRepository(settings: makeSettings())
    let preferences = UserPreferencesStore()
    let vm = SettingsViewModel(
        repository: repository,
        logger: testLogger(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections(),
        userPreferencesStore: preferences
    )
    await vm.onAppear()

    await vm.updateDartEntryPresentation(DartEntryPresentation.visualBoard.rawValue)

    #expect(vm.settings?.defaultDartEntryPresentationRaw == DartEntryPresentation.visualBoard.rawValue)
    #expect(preferences.defaultDartEntryPresentation == .visualBoard)
    #expect(await repository.updateCallCount == 1)

    // Unknown raw values fall back to the number pad instead of persisting garbage.
    await vm.updateDartEntryPresentation("garbage")
    #expect(vm.settings?.defaultDartEntryPresentationRaw == DartEntryPresentation.numberPad.rawValue)
}

@MainActor
@Test(.tags(.unit, .settings, .regression))
func settingsUpdateDefaultsChangesMatchType() async {
    let repository = FakeSettingsRepository(settings: makeSettings(defaultMatchTypeRaw: "x01"))
    let vm = SettingsViewModel(
        repository: repository,
        logger: testLogger(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections(),
        userPreferencesStore: UserPreferencesStore()
    )
    await vm.onAppear()

    await vm.updateDefaults(
        matchType: "cricket",
        startScore: 301,
        checkout: "singleOut",
        checkIn: "doubleIn",
        legFormat: "bestOf",
        legs: 5,
        setsEnabled: true
    )

    #expect(vm.settings?.defaultMatchTypeRaw == "cricket")
    #expect(vm.settings?.defaultX01StartScore == 301)
    #expect(vm.settings?.defaultCheckoutModeRaw == "singleOut")
    #expect(vm.settings?.defaultCheckInModeRaw == "doubleIn")
    #expect(vm.settings?.defaultLegFormatRaw == "bestOf")
    #expect(vm.settings?.defaultLegsToWin == 5)
    #expect(vm.settings?.defaultSetsEnabled == true)
}

@MainActor
@Test(.tags(.unit, .settings, .regression))
func settingsUpdateDefaultsChangesSetsEnabled() async {
    let repository = FakeSettingsRepository(settings: makeSettings())
    let vm = SettingsViewModel(
        repository: repository,
        logger: testLogger(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections(),
        userPreferencesStore: UserPreferencesStore()
    )
    await vm.onAppear()

    await vm.updateDefaults(
        matchType: "x01",
        startScore: 501,
        checkout: "doubleOut",
        checkIn: "straightIn",
        legFormat: "firstTo",
        legs: 3,
        setsEnabled: true
    )

    #expect(vm.settings?.defaultSetsEnabled == true)
}

@MainActor
@Test(.tags(.unit, .settings, .regression))
func settingsLoadFailureSurfacesErrorKey() async {
    let repository = FakeSettingsRepository(
        settings: makeSettings(),
        fetchError: AppError(
            code: .storageUnavailable,
            layer: .data,
            severity: .error,
            isRecoverable: true,
            userMessageKey: "settings.error.load"
        )
    )
    let vm = SettingsViewModel(
        repository: repository,
        logger: testLogger(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections(),
        userPreferencesStore: UserPreferencesStore()
    )

    await vm.onAppear()

    if case let .error(key) = vm.state {
        #expect(key == "settings.error.load")
    } else {
        Issue.record("Expected error state")
    }
}

@MainActor
@Test(.tags(.unit, .settings, .regression))
func settingsSaveFailureSurfacesErrorKey() async {
    let repository = FakeSettingsRepository(
        settings: makeSettings(),
        updateError: AppError(
            code: .storageUnavailable,
            layer: .data,
            severity: .error,
            isRecoverable: true,
            userMessageKey: "settings.error.save"
        )
    )
    let vm = SettingsViewModel(
        repository: repository,
        logger: testLogger(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections(),
        userPreferencesStore: UserPreferencesStore()
    )
    await vm.onAppear()

    await vm.updateAppearance("dark")

    if case let .error(key) = vm.state {
        #expect(key == "settings.error.save")
    } else {
        Issue.record("Expected error state")
    }
}

@MainActor
@Test(.tags(.unit, .settings, .regression))
func settingsResetPromptFlow() async {
    let vm = SettingsViewModel(
        repository: FakeSettingsRepository(settings: makeSettings()),
        logger: testLogger(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections(),
        userPreferencesStore: UserPreferencesStore()
    )
    await vm.onAppear()

    vm.requestReset()
    #expect(vm.state == .showResetConfirmation)

    vm.dismissResetPrompt()
    #expect(vm.state == .ready)
}

@MainActor
@Test(.tags(.unit, .settings, .regression))
func settingsConfirmResetClearsActiveMatchStore() async throws {
    let repository = FakeSettingsRepository(settings: makeSettings(appearanceModeRaw: "dark"))
    let activeStore = ActiveMatchStore()
    let session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 501, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .doubleOut)),
        participants: [
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    activeStore.save(session)
    #expect(activeStore.activeMatchSummary() != nil)

    let preferences = UserPreferencesStore()
    let vm = SettingsViewModel(
        repository: repository,
        logger: testLogger(),
        activeMatchStore: activeStore,
        pendingMatchPlayerSelections: PendingMatchPlayerSelections(),
        userPreferencesStore: preferences
    )
    await vm.onAppear()
    preferences.apply(makeSettings(appearanceModeRaw: "dark"))

    await vm.confirmReset()

    #expect(vm.state == .ready)
    #expect(activeStore.activeMatchSummary() == nil)
    #expect(vm.settings?.appearanceModeRaw == "system")
    #expect(preferences.preferredColorScheme == nil)
    #expect(await repository.resetCallCount == 1)
}

@MainActor
@Test(.tags(.unit, .settings, .regression))
func settingsConfirmResetFailureSurfacesError() async throws {
    let resetError = AppError(
        code: .storageUnavailable,
        layer: .data,
        severity: .error,
        isRecoverable: true,
        userMessageKey: "settings.error.reset"
    )
    let repository = FakeSettingsRepository(settings: makeSettings(), resetError: resetError)
    let sink = RecordingSettingsLogSink()
    let vm = SettingsViewModel(
        repository: repository,
        logger: DefaultAppLogger(minimumLevel: .debug, sink: sink),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections(),
        userPreferencesStore: UserPreferencesStore()
    )
    await vm.onAppear()

    await vm.confirmReset()

    if case .error(let key) = vm.state {
        #expect(key == "settings.error.reset")
    } else {
        Issue.record("Expected error state after failed reset")
    }
    #expect(sink.entries.contains(where: { $0.eventName == "settings_reset_failed" && $0.level >= .error }))
}

private func makeSettings(
    id: UUID = UUID(),
    appearanceModeRaw: String = "system",
    hapticsEnabled: Bool = true,
    soundEnabled: Bool = true,
    defaultMatchTypeRaw: String = "x01"
) -> SettingsSummary {
    SettingsSummary(
        id: id,
        appearanceModeRaw: appearanceModeRaw,
        hapticsEnabled: hapticsEnabled,
        soundEnabled: soundEnabled,
        turnTotalCallerEnabled: false,
        defaultMatchTypeRaw: defaultMatchTypeRaw,
        defaultX01StartScore: 501,
        defaultCheckoutModeRaw: "doubleOut",
        defaultCheckInModeRaw: "straightIn",
        defaultLegFormatRaw: "firstTo",
        defaultLegsToWin: 3,
        defaultSetsEnabled: false,
        botStaggerEnabled: true,
        botDartHapticsEnabled: true,
        defaultDartEntryPresentationRaw: "numberPad",
        updatedAt: Date()
    )
}

private func testLogger() -> DefaultAppLogger {
    DefaultAppLogger(minimumLevel: .fault, sink: RecordingSettingsLogSink())
}

private final class RecordingSettingsLogSink: LogSink, @unchecked Sendable {
    private(set) var entries: [LogEntry] = []

    func write(_ entry: LogEntry) {
        entries.append(entry)
    }
}
