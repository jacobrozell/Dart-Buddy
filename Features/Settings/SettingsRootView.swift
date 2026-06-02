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
                    set: { queueGameplayDefaults(from: settings, matchType: $0) }
                )) {
                    Text("settings.mode.x01").tag("x01")
                    Text("settings.mode.cricket").tag("cricket")
                }
            }
            .brandFormRowBackground(when: usesBrand)

            Section {
                Picker(L10n.setupChipPoints, selection: Binding(
                    get: { settings.defaultX01StartScore },
                    set: { queueGameplayDefaults(from: settings, startScore: $0) }
                )) {
                    ForEach(X01StartScores.all, id: \.self) { score in
                        Text("\(score)").tag(score)
                    }
                }
                .accessibilityIdentifier("settings_defaultStartScorePicker")

                Picker(L10n.setupChipCheckOut, selection: Binding(
                    get: { settings.defaultCheckoutModeRaw },
                    set: { queueGameplayDefaults(from: settings, checkout: $0) }
                )) {
                    ForEach(X01CheckoutMode.allCases, id: \.rawValue) { mode in
                        Text(mode.displayName).tag(mode.rawValue)
                    }
                }
                .accessibilityIdentifier("settings_defaultCheckoutPicker")

                Picker(L10n.setupChipCheckIn, selection: Binding(
                    get: { settings.defaultCheckInModeRaw },
                    set: { queueGameplayDefaults(from: settings, checkIn: $0) }
                )) {
                    ForEach(X01CheckInMode.allCases, id: \.rawValue) { mode in
                        Text(mode.displayName).tag(mode.rawValue)
                    }
                }
                .accessibilityIdentifier("settings_defaultCheckInPicker")

                Picker(L10n.setupChipSetLeg, selection: Binding(
                    get: { settings.defaultLegFormatRaw },
                    set: { queueGameplayDefaults(from: settings, legFormat: $0) }
                )) {
                    ForEach(X01LegFormat.allCases, id: \.rawValue) { format in
                        Text(format.displayName).tag(format.rawValue)
                    }
                }
                .accessibilityIdentifier("settings_defaultLegFormatPicker")

                Picker(L10n.setupChipLegs, selection: Binding(
                    get: { settings.defaultLegsToWin },
                    set: { queueGameplayDefaults(from: settings, legs: $0) }
                )) {
                    ForEach(1 ... 9, id: \.self) { count in
                        Text("\(count)").tag(count)
                    }
                }
                .accessibilityIdentifier("settings_defaultLegsPicker")

                Toggle(L10n.setupChipSets, isOn: Binding(
                    get: { settings.defaultSetsEnabled },
                    set: { queueGameplayDefaults(from: settings, setsEnabled: $0) }
                ))
                .accessibilityIdentifier("settings_defaultSetsToggle")
            } header: {
                Text(L10n.x01DefaultsSection)
            } footer: {
                Text(L10n.x01DefaultsFooter)
            }
            .brandFormRowBackground(when: usesBrand)

            Section {
                Toggle("settings.feedback.haptics", isOn: Binding(
                    get: { viewModel.settings?.hapticsEnabled ?? true },
                    set: { viewModel.queueFeedbackUpdate(haptics: $0) }
                ))
                .accessibilityIdentifier("settings_hapticsToggle")
                Toggle("settings.feedback.sound", isOn: Binding(
                    get: { viewModel.settings?.soundEnabled ?? true },
                    set: { viewModel.queueFeedbackUpdate(sound: $0) }
                ))
                .accessibilityIdentifier("settings_soundToggle")
                Toggle("settings.feedback.turnTotalCaller", isOn: Binding(
                    get: { viewModel.settings?.turnTotalCallerEnabled ?? false },
                    set: { viewModel.queueFeedbackUpdate(turnTotalCaller: $0) }
                ))
                .accessibilityIdentifier("settings_turnTotalCallerToggle")
                Toggle("settings.feedback.botStagger", isOn: Binding(
                    get: { viewModel.settings?.botStaggerEnabled ?? true },
                    set: { viewModel.queueBotPacingUpdate(stagger: $0) }
                ))
                .accessibilityIdentifier("settings_botStaggerToggle")
                Toggle("settings.feedback.botDartHaptics", isOn: Binding(
                    get: { viewModel.settings?.botDartHapticsEnabled ?? true },
                    set: { viewModel.queueBotPacingUpdate(dartHaptics: $0) }
                ))
                .accessibilityIdentifier("settings_botDartHapticsToggle")
            } header: {
                Text(L10n.feedbackSection)
            } footer: {
                Text("settings.feedback.footer")
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

            Section {
                Text("settings.about.value")
                    .foregroundStyle(usesBrand ? Brand.textSecondary : DS.ColorRole.textSecondary)

                if let buyDeveloperCoffeeURL = AppLinks.buyDeveloperCoffee {
                    Link(destination: buyDeveloperCoffeeURL) {
                        Label(L10n.settingsBuyDeveloperCoffee, systemImage: "cup.and.saucer.fill")
                    }
                    .accessibilityLabel(L10n.settingsBuyDeveloperCoffeeAccessibility)
                    .accessibilityIdentifier("settings_buyDeveloperCoffeeLink")
                }
            } header: {
                Text(L10n.aboutSection)
            } footer: {
                if AppLinks.buyDeveloperCoffee != nil {
                    Text(L10n.settingsBuyDeveloperCoffeeFooter)
                }
            }
            .brandFormRowBackground(when: usesBrand)
        }
        .tint(Brand.green)
        .frame(maxWidth: contentMaxWidth)
        .frame(maxWidth: .infinity, alignment: .center)
        .safeAreaPadding(.bottom, DS.Spacing.s6)
        .brandSettingsChrome(appearanceModeRaw: settings.appearanceModeRaw)
    }

    private func queueGameplayDefaults(
        from settings: SettingsSummary,
        matchType: String? = nil,
        startScore: Int? = nil,
        checkout: String? = nil,
        checkIn: String? = nil,
        legFormat: String? = nil,
        legs: Int? = nil,
        setsEnabled: Bool? = nil
    ) {
        viewModel.queueDefaultsUpdate(
            matchType: matchType ?? settings.defaultMatchTypeRaw,
            startScore: startScore ?? settings.defaultX01StartScore,
            checkout: checkout ?? settings.defaultCheckoutModeRaw,
            checkIn: checkIn ?? settings.defaultCheckInModeRaw,
            legFormat: legFormat ?? settings.defaultLegFormatRaw,
            legs: legs ?? settings.defaultLegsToWin,
            setsEnabled: setsEnabled ?? settings.defaultSetsEnabled
        )
    }
}
