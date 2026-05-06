import SwiftUI

struct SettingsRootView: View {
    let dependencies: AppDependencies
    @State private var path: [SettingsRoute] = []
    @StateObject private var viewModel: SettingsViewModel

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = StateObject(
            wrappedValue: SettingsViewModel(
                repository: dependencies.settingsRepository,
                logger: dependencies.logger,
                activeMatchStore: dependencies.activeMatchStore
            )
        )
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let settings = viewModel.settings {
                    Form {
                        Section(L10n.appearanceSection) {
                            Picker("settings.theme.label", selection: Binding(
                                get: { settings.appearanceModeRaw },
                                set: { Task { await viewModel.updateAppearance($0) } }
                            )) {
                                Text("settings.theme.system").tag("system")
                                Text("settings.theme.light").tag("light")
                                Text("settings.theme.dark").tag("dark")
                            }
                        }
                        Section(L10n.gameplayDefaultsSection) {
                            Picker("settings.mode.label", selection: Binding(
                                get: { settings.defaultMatchTypeRaw },
                                set: { Task { await viewModel.updateDefaults(matchType: $0, startScore: settings.defaultX01StartScore, checkout: settings.defaultCheckoutModeRaw, legs: settings.defaultLegsToWin, setsEnabled: settings.defaultSetsEnabled) } }
                            )) {
                                Text("settings.mode.x01").tag("x01")
                                Text("settings.mode.cricket").tag("cricket")
                            }
                        }
                        Section(L10n.feedbackSection) {
                            Toggle("settings.feedback.haptics", isOn: Binding(
                                get: { settings.hapticsEnabled },
                                set: { Task { await viewModel.updateFeedback(haptics: $0) } }
                            ))
                            Toggle("settings.feedback.sound", isOn: Binding(
                                get: { settings.soundEnabled },
                                set: { Task { await viewModel.updateFeedback(sound: $0) } }
                            ))
                        }
                        Section(L10n.dataSection) {
                            Button(L10n.resetAllData, role: .destructive) {
                                viewModel.requestReset()
                            }
                        }
                        Section(L10n.aboutSection) {
                            Text("settings.about.value")
                                .foregroundStyle(DS.ColorRole.textSecondary)
                        }
                    }
                } else {
                    ProgressView(L10n.settingsLoading)
                }
            }
            .navigationTitle(L10n.settingsTitle)
            .task { await viewModel.onAppear() }
            .confirmationDialog(
                L10n.resetConfirmTitle,
                isPresented: Binding(
                    get: { viewModel.state == .showResetConfirmation },
                    set: { if !$0 { viewModel.dismissResetPrompt() } }
                ),
                titleVisibility: .visible
            ) {
                Button(L10n.resetConfirmAction, role: .destructive) {
                    Task { await viewModel.confirmReset() }
                }
                Button(L10n.cancel, role: .cancel) {
                    viewModel.dismissResetPrompt()
                }
            } message: {
                Text(L10n.resetConfirmMessage)
            }
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .root:
                    EmptyView()
                }
            }
        }
    }
}
