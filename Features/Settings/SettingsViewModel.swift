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
    private var mutationTask: Task<Void, Never>?
    private var resetTask: Task<Void, Never>?

    init(repository: any SettingsRepository, logger: any AppLogger, activeMatchStore: ActiveMatchStore) {
        self.repository = repository
        self.logger = logger
        self.activeMatchStore = activeMatchStore
    }

    deinit {
        mutationTask?.cancel()
        resetTask?.cancel()
    }

    func onAppear() async {
        state = .loading
        do {
            settings = try await repository.fetchSettings()
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
            defaultMatchTypeRaw: current.defaultMatchTypeRaw,
            defaultX01StartScore: current.defaultX01StartScore,
            defaultCheckoutModeRaw: current.defaultCheckoutModeRaw,
            defaultLegsToWin: current.defaultLegsToWin,
            defaultSetsEnabled: current.defaultSetsEnabled,
            updatedAt: Date()
        )
        await persist(current)
    }

    func queueAppearanceUpdate(_ value: String) {
        queueMutation { await self.updateAppearance(value) }
    }

    func updateFeedback(haptics: Bool? = nil, sound: Bool? = nil) async {
        guard var current = settings else { return }
        current = SettingsSummary(
            id: current.id,
            appearanceModeRaw: current.appearanceModeRaw,
            hapticsEnabled: haptics ?? current.hapticsEnabled,
            soundEnabled: sound ?? current.soundEnabled,
            defaultMatchTypeRaw: current.defaultMatchTypeRaw,
            defaultX01StartScore: current.defaultX01StartScore,
            defaultCheckoutModeRaw: current.defaultCheckoutModeRaw,
            defaultLegsToWin: current.defaultLegsToWin,
            defaultSetsEnabled: current.defaultSetsEnabled,
            updatedAt: Date()
        )
        await persist(current)
    }

    func queueFeedbackUpdate(haptics: Bool? = nil, sound: Bool? = nil) {
        queueMutation { await self.updateFeedback(haptics: haptics, sound: sound) }
    }

    func updateDefaults(matchType: String, startScore: Int, checkout: String, legs: Int, setsEnabled: Bool) async {
        guard var current = settings else { return }
        current = SettingsSummary(
            id: current.id,
            appearanceModeRaw: current.appearanceModeRaw,
            hapticsEnabled: current.hapticsEnabled,
            soundEnabled: current.soundEnabled,
            defaultMatchTypeRaw: matchType,
            defaultX01StartScore: startScore,
            defaultCheckoutModeRaw: checkout,
            defaultLegsToWin: max(1, legs),
            defaultSetsEnabled: setsEnabled,
            updatedAt: Date()
        )
        await persist(current)
    }

    func queueDefaultsUpdate(matchType: String, startScore: Int, checkout: String, legs: Int, setsEnabled: Bool) {
        queueMutation { await self.updateDefaults(matchType: matchType, startScore: startScore, checkout: checkout, legs: legs, setsEnabled: setsEnabled) }
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
            settings = try await repository.updateSettings(next)
            state = .ready
        } catch is CancellationError {
            state = .ready
        } catch {
            state = .error(messageKey(for: error, fallback: "settings.error.save"))
        }
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
