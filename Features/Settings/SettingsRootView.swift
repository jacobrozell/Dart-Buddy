import SwiftUI

struct SettingsRootView: View {
    let dependencies: AppDependencies
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var path: [SettingsRoute] = []
    @StateObject private var viewModel: SettingsViewModel
    @State private var retryTask: Task<Void, Never>?

    private var contentMaxWidth: CGFloat {
        horizontalSizeClass == .regular ? 760 : .infinity
    }

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = StateObject(
            wrappedValue: SettingsViewModel(
                repository: dependencies.settingsRepository,
                logger: dependencies.logger,
                activeMatchStore: dependencies.activeMatchStore,
                userPreferencesStore: dependencies.userPreferencesStore
            )
        )
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let settings = viewModel.settings {
                    settingsForm(settings)
                } else {
                    switch viewModel.state {
                    case let .error(messageKey):
                        ContentUnavailableView(
                            L10n.errorTitle,
                            systemImage: "exclamationmark.triangle",
                            description: Text(LocalizedStringKey(messageKey))
                        )
                        .overlay(alignment: .bottom) {
                            Button(L10n.retry) {
                                retryTask?.cancel()
                                retryTask = Task { await viewModel.onAppear() }
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.bottom, DS.Spacing.s6)
                        }
                    default:
                        ProgressView(L10n.settingsLoading)
                    }
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
                    viewModel.queueConfirmReset()
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
            .onDisappear {
                retryTask?.cancel()
                viewModel.cancelPendingWork()
            }
        }
    }

    @ViewBuilder
    private func settingsForm(_ settings: SettingsSummary) -> some View {
        let usesBrand = AppAppearancePolicy.settingsUsesBrandPalette(appearanceModeRaw: settings.appearanceModeRaw)

        Form {
            Section(L10n.appearanceSection) {
                Picker("settings.theme.label", selection: Binding(
                    get: { settings.appearanceModeRaw },
                    set: { viewModel.queueAppearanceUpdate($0) }
                )) {
                    Text("settings.theme.system").tag("system")
                    Text("settings.theme.light").tag("light")
                    Text("settings.theme.dark").tag("dark")
                }
            }
            .brandFormRowBackground(when: usesBrand)

            Section(L10n.gameplayDefaultsSection) {
                Picker("settings.mode.label", selection: Binding(
                    get: { settings.defaultMatchTypeRaw },
                    set: { viewModel.queueDefaultsUpdate(matchType: $0, startScore: settings.defaultX01StartScore, checkout: settings.defaultCheckoutModeRaw, legs: settings.defaultLegsToWin, setsEnabled: settings.defaultSetsEnabled) }
                )) {
                    Text("settings.mode.x01").tag("x01")
                    Text("settings.mode.cricket").tag("cricket")
                }
            }
            .brandFormRowBackground(when: usesBrand)

            Section {
                Toggle("settings.feedback.haptics", isOn: Binding(
                    get: { settings.hapticsEnabled },
                    set: { viewModel.queueFeedbackUpdate(haptics: $0) }
                ))
                .accessibilityIdentifier("settings_hapticsToggle")
                Toggle("settings.feedback.sound", isOn: Binding(
                    get: { settings.soundEnabled },
                    set: { viewModel.queueFeedbackUpdate(sound: $0) }
                ))
                .accessibilityIdentifier("settings_soundToggle")
                Toggle("settings.feedback.turnTotalCaller", isOn: Binding(
                    get: { settings.turnTotalCallerEnabled },
                    set: { viewModel.queueFeedbackUpdate(turnTotalCaller: $0) }
                ))
                .accessibilityIdentifier("settings_turnTotalCallerToggle")
            } header: {
                Text(L10n.feedbackSection)
            } footer: {
                Text("settings.feedback.turnTotalCaller.footer")
            }
            .brandFormRowBackground(when: usesBrand)

            Section(L10n.dataSection) {
                Button(L10n.resetAllData, role: .destructive) {
                    viewModel.requestReset()
                }
                .accessibilityLabel(L10n.string("settings.reset.accessibility"))
                .accessibilityIdentifier("settings_resetAllDataButton")
            }
            .brandFormRowBackground(when: usesBrand)

            Section(L10n.aboutSection) {
                Text("settings.about.value")
                    .foregroundStyle(usesBrand ? Brand.textSecondary : DS.ColorRole.textSecondary)
            }
            .brandFormRowBackground(when: usesBrand)
        }
        .tint(Brand.green)
        .frame(maxWidth: contentMaxWidth)
        .frame(maxWidth: .infinity, alignment: .center)
        .safeAreaPadding(.bottom, DS.Spacing.s6)
        .brandSettingsChrome(appearanceModeRaw: settings.appearanceModeRaw)
    }
}
