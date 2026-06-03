import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case ready
        case saving
        case showResetConfirmation
        case resetInProgress
        case error(String)
    }

    @Published private(set) var state: State = .loading
    @Published var settings: SettingsSummary?

    private let repository: any SettingsRepository
    private let logger: any AppLogger
    private let activeMatchStore: ActiveMatchStore
    private let userPreferencesStore: UserPreferencesStore
    private var mutationTask: Task<Void, Never>?
    private var resetTask: Task<Void, Never>?

    init(
        repository: any SettingsRepository,
        logger: any AppLogger,
        activeMatchStore: ActiveMatchStore,
        userPreferencesStore: UserPreferencesStore
    ) {
        self.repository = repository
        self.logger = logger
        self.activeMatchStore = activeMatchStore
        self.userPreferencesStore = userPreferencesStore
    }

    deinit {
        mutationTask?.cancel()
        resetTask?.cancel()
    }

    func onAppear() async {
        state = .loading
        do {
            settings = try await repository.fetchSettings()
            if let settings { userPreferencesStore.apply(settings) }
            state = .ready
        } catch is CancellationError {
            return
        } catch {
            state = .error(messageKey(for: error, fallback: "settings.error.load"))
        }
    }

    func updateAppearance(_ value: String) async {
        guard var current = settings else { return }
        current = SettingsSummary(
            id: current.id,
            appearanceModeRaw: value,
            hapticsEnabled: current.hapticsEnabled,
            soundEnabled: current.soundEnabled,
            turnTotalCallerEnabled: current.turnTotalCallerEnabled,
            defaultMatchTypeRaw: current.defaultMatchTypeRaw,
            defaultX01StartScore: current.defaultX01StartScore,
            defaultCheckoutModeRaw: current.defaultCheckoutModeRaw,
            defaultCheckInModeRaw: current.defaultCheckInModeRaw,
            defaultLegFormatRaw: current.defaultLegFormatRaw,
            defaultLegsToWin: current.defaultLegsToWin,
            defaultSetsEnabled: current.defaultSetsEnabled,
            botStaggerEnabled: current.botStaggerEnabled,
            botDartHapticsEnabled: current.botDartHapticsEnabled,
            updatedAt: Date()
        )
        await persist(current)
    }

    func queueAppearanceUpdate(_ value: String) {
        queueMutation { await self.updateAppearance(value) }
    }

    func updateFeedback(haptics: Bool? = nil, sound: Bool? = nil, turnTotalCaller: Bool? = nil) async {
        guard let current = applyFeedbackDraft(haptics: haptics, sound: sound, turnTotalCaller: turnTotalCaller) else { return }
        await persist(current)
    }

    func updateBotPacing(stagger: Bool? = nil, dartHaptics: Bool? = nil) async {
        guard let current = applyBotPacingDraft(stagger: stagger, dartHaptics: dartHaptics) else { return }
        await persist(current)
    }

    func queueFeedbackUpdate(haptics: Bool? = nil, sound: Bool? = nil, turnTotalCaller: Bool? = nil) {
        guard let current = applyFeedbackDraft(haptics: haptics, sound: sound, turnTotalCaller: turnTotalCaller) else { return }
        queueMutation { await self.persist(current) }
    }

    func queueBotPacingUpdate(stagger: Bool? = nil, dartHaptics: Bool? = nil) {
        guard let current = applyBotPacingDraft(stagger: stagger, dartHaptics: dartHaptics) else { return }
        queueMutation { await self.persist(current) }
    }

    func updateDefaults(
        matchType: String,
        startScore: Int,
        checkout: String,
        checkIn: String,
        legFormat: String,
        legs: Int,
        setsEnabled: Bool
    ) async {
        guard var current = settings else { return }
        current = SettingsSummary(
            id: current.id,
            appearanceModeRaw: current.appearanceModeRaw,
            hapticsEnabled: current.hapticsEnabled,
            soundEnabled: current.soundEnabled,
            turnTotalCallerEnabled: current.turnTotalCallerEnabled,
            defaultMatchTypeRaw: matchType,
            defaultX01StartScore: startScore,
            defaultCheckoutModeRaw: checkout,
            defaultCheckInModeRaw: checkIn,
            defaultLegFormatRaw: legFormat,
            defaultLegsToWin: max(1, legs),
            defaultSetsEnabled: setsEnabled,
            botStaggerEnabled: current.botStaggerEnabled,
            botDartHapticsEnabled: current.botDartHapticsEnabled,
            updatedAt: Date()
        )
        await persist(current)
    }

    func queueDefaultsUpdate(
        matchType: String,
        startScore: Int,
        checkout: String,
        checkIn: String,
        legFormat: String,
        legs: Int,
        setsEnabled: Bool
    ) {
        queueMutation {
            await self.updateDefaults(
                matchType: matchType,
                startScore: startScore,
                checkout: checkout,
                checkIn: checkIn,
                legFormat: legFormat,
                legs: legs,
                setsEnabled: setsEnabled
            )
        }
    }

    func requestReset() {
        state = .showResetConfirmation
    }

    func confirmReset() async {
        state = .resetInProgress
        do {
            try await repository.resetAllLocalData()
            activeMatchStore.clearAll()
            settings = try await repository.fetchSettings()
            if let settings { userPreferencesStore.apply(settings) }
            state = .ready
            logger.warning(.settings, eventName: "settings_reset_all_data", message: "Reset local data path executed.")
        } catch is CancellationError {
            state = .ready
        } catch {
            state = .error(messageKey(for: error, fallback: "settings.error.reset"))
        }
    }

    func queueConfirmReset() {
        resetTask?.cancel()
        resetTask = Task { await self.confirmReset() }
    }

    func dismissResetPrompt() {
        state = .ready
    }

    func cancelPendingWork() {
        mutationTask?.cancel()
        resetTask?.cancel()
    }

    private func persist(_ next: SettingsSummary) async {
        state = .saving
        do {
            let updated = try await repository.updateSettings(next)
            settings = updated
            userPreferencesStore.apply(updated)
            state = .ready
        } catch is CancellationError {
            state = .ready
        } catch {
            state = .error(messageKey(for: error, fallback: "settings.error.save"))
        }
    }

    private func applyFeedbackDraft(
        haptics: Bool?,
        sound: Bool?,
        turnTotalCaller: Bool?
    ) -> SettingsSummary? {
        guard var current = settings else { return nil }
        current = SettingsSummary(
            id: current.id,
            appearanceModeRaw: current.appearanceModeRaw,
            hapticsEnabled: haptics ?? current.hapticsEnabled,
            soundEnabled: sound ?? current.soundEnabled,
            turnTotalCallerEnabled: turnTotalCaller ?? current.turnTotalCallerEnabled,
            defaultMatchTypeRaw: current.defaultMatchTypeRaw,
            defaultX01StartScore: current.defaultX01StartScore,
            defaultCheckoutModeRaw: current.defaultCheckoutModeRaw,
            defaultCheckInModeRaw: current.defaultCheckInModeRaw,
            defaultLegFormatRaw: current.defaultLegFormatRaw,
            defaultLegsToWin: current.defaultLegsToWin,
            defaultSetsEnabled: current.defaultSetsEnabled,
            botStaggerEnabled: current.botStaggerEnabled,
            botDartHapticsEnabled: current.botDartHapticsEnabled,
            updatedAt: Date()
        )
        settings = current
        userPreferencesStore.apply(current)
        return current
    }

    private func applyBotPacingDraft(stagger: Bool?, dartHaptics: Bool?) -> SettingsSummary? {
        guard var current = settings else { return nil }
        current = SettingsSummary(
            id: current.id,
            appearanceModeRaw: current.appearanceModeRaw,
            hapticsEnabled: current.hapticsEnabled,
            soundEnabled: current.soundEnabled,
            turnTotalCallerEnabled: current.turnTotalCallerEnabled,
            defaultMatchTypeRaw: current.defaultMatchTypeRaw,
            defaultX01StartScore: current.defaultX01StartScore,
            defaultCheckoutModeRaw: current.defaultCheckoutModeRaw,
            defaultCheckInModeRaw: current.defaultCheckInModeRaw,
            defaultLegFormatRaw: current.defaultLegFormatRaw,
            defaultLegsToWin: current.defaultLegsToWin,
            defaultSetsEnabled: current.defaultSetsEnabled,
            botStaggerEnabled: stagger ?? current.botStaggerEnabled,
            botDartHapticsEnabled: dartHaptics ?? current.botDartHapticsEnabled,
            updatedAt: Date()
        )
        settings = current
        userPreferencesStore.apply(current)
        return current
    }

    private func queueMutation(_ operation: @escaping @MainActor () async -> Void) {
        mutationTask?.cancel()
        mutationTask = Task { await operation() }
    }

    private func messageKey(for error: Error, fallback: String) -> String {
        if let appError = error as? AppError {
            return appError.userMessageKey
        }
        return fallback
    }
}
