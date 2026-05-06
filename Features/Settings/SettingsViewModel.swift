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

    init(repository: any SettingsRepository, logger: any AppLogger, activeMatchStore: ActiveMatchStore) {
        self.repository = repository
        self.logger = logger
        self.activeMatchStore = activeMatchStore
    }

    func onAppear() async {
        state = .loading
        do {
            settings = try await repository.fetchSettings()
            state = .ready
        } catch {
            state = .error("settings.error.load")
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

    func requestReset() {
        state = .showResetConfirmation
    }

    func confirmReset() async {
        state = .resetInProgress
        do {
            try await repository.resetSettings()
            activeMatchStore.clearAll()
            settings = try await repository.fetchSettings()
            state = .ready
            logger.warning(.settings, eventName: "settings_reset_all_data", message: "Reset local data path executed.")
        } catch {
            state = .error("settings.error.reset")
        }
    }

    func dismissResetPrompt() {
        state = .ready
    }

    private func persist(_ next: SettingsSummary) async {
        state = .saving
        do {
            settings = try await repository.updateSettings(next)
            state = .ready
        } catch {
            state = .error("settings.error.save")
        }
    }
}
