import SwiftUI

struct SettingsRootView: View {
    let dependencies: AppDependencies
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ObservedObject private var preferences: UserPreferencesStore
    @State private var path: [SettingsRoute] = []
    @StateObject private var viewModel: SettingsViewModel
    @State private var retryTask: Task<Void, Never>?
    @State private var showsOnboarding = false

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _preferences = ObservedObject(wrappedValue: dependencies.userPreferencesStore)
        _viewModel = StateObject(
            wrappedValue: SettingsViewModel(
                repository: dependencies.settingsRepository,
                logger: dependencies.logger,
                activeMatchStore: dependencies.activeMatchStore,
                pendingMatchPlayerSelections: dependencies.pendingMatchPlayerSelections,
                userPreferencesStore: dependencies.userPreferencesStore
            )
        )
    }

    var body: some View {
        phoneSettingsShell
        .alert(L10n.resetConfirmTitle, isPresented: resetConfirmationBinding) {
            Button(L10n.cancel, role: .cancel) {
                viewModel.dismissResetPrompt()
            }
            Button(L10n.resetConfirmAction, role: .destructive) {
                viewModel.queueConfirmReset()
            }
        } message: {
            Text(L10n.resetConfirmMessage)
        }
        .fullScreenCover(isPresented: $showsOnboarding) {
            OnboardingFlowView(
                mode: .replay,
                dependencies: dependencies,
                preferredColorScheme: preferences.preferredColorScheme,
                onFinished: { showsOnboarding = false }
            )
        }
    }

    private var phoneSettingsShell: some View {
        NavigationStack(path: $path) {
            Group {
                if let settings = viewModel.settings {
                    settingsForm(settings)
                } else {
                    settingsPlaceholderBody
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background {
                settingsRootBackground
                    .ignoresSafeArea()
            }
            .navigationBarHidden(true)
            .task { await viewModel.onAppear() }
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
        .safeAreaInset(edge: .top, spacing: DS.Spacing.s2) {
            settingsScreenTitle
                .padding(.horizontal, DS.Spacing.s4)
                .readableRootContentWidth(horizontalSizeClass)
                .frame(maxWidth: .infinity)
                .background(settingsRootBackground)
        }
        .brandSettingsScreenChrome(appearanceModeRaw: preferences.appearanceModeRaw)
    }

    private var settingsRootBackground: Color {
        AppAppearancePolicy.settingsUsesBrandPalette(appearanceModeRaw: preferences.appearanceModeRaw)
            ? Brand.background
            : Color(uiColor: .systemGroupedBackground)
    }

    private var resetConfirmationBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state == .showResetConfirmation },
            set: { isPresented in
                if !isPresented {
                    viewModel.dismissResetPrompt()
                }
            }
        )
    }

    private var usesBrandSettingsPalette: Bool {
        AppAppearancePolicy.settingsUsesBrandPalette(appearanceModeRaw: preferences.appearanceModeRaw)
    }

    @ViewBuilder
    private func settingsSectionFooter(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.footnote)
            .foregroundStyle(usesBrandSettingsPalette ? Brand.textSecondary : Color.secondary)
    }

    @ViewBuilder
    private var settingsPlaceholderBody: some View {
        switch viewModel.state {
        case let .error(messageKey):
            ContentUnavailableView(
                L10n.errorTitle,
                systemImage: "exclamationmark.triangle",
                description: Text(LocalizedStringKey(messageKey))
                    .foregroundStyle(
                        usesBrandSettingsPalette ? Brand.textSecondary : DS.ColorRole.textSecondary
                    )
            )
            .brandScoreboardEmptyState(when: usesBrandSettingsPalette)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                Button(L10n.retry) {
                    retryTask?.cancel()
                    retryTask = Task { await viewModel.onAppear() }
                }
                .buttonStyle(.borderedProminent)
                .tint(Brand.green)
                .accessibilityIdentifier("settings_retryButton")
                .tabRootScrollChrome()
            }
        default:
            ProgressView(L10n.settingsLoading)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("settings_loading")
                .accessibilityLabel(L10n.settingsLoading)
        }
    }

    @ViewBuilder
    private func settingsForm(_ settings: SettingsSummary) -> some View {
        List {
            appearanceSection(settings, usesBrand: usesBrandSettingsPalette)
            startingModeSection(settings, usesBrand: usesBrandSettingsPalette)
            matchDefaultsSection(settings, usesBrand: usesBrandSettingsPalette)
            x01DefaultsSection(settings, usesBrand: usesBrandSettingsPalette)
            duringPlaySection(usesBrand: usesBrandSettingsPalette)
            botOpponentsSection(usesBrand: usesBrandSettingsPalette)
            dataSection(usesBrand: usesBrandSettingsPalette)
            helpAndFeedbackSection(usesBrand: usesBrandSettingsPalette)
            aboutSection(usesBrand: usesBrandSettingsPalette)
        }
        .listStyle(.insetGrouped)
        .tint(Brand.green)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .readableRootContentWidth(horizontalSizeClass)
        .tabRootScrollChrome()
        .brandSettingsFormChrome(appearanceModeRaw: preferences.appearanceModeRaw)
        .accessibilityIdentifier("settings_form")
    }

    @ViewBuilder
    private var settingsScreenTitle: some View {
        if usesBrandSettingsPalette {
            BrandRootScreenTitle(title: L10n.settingsTitle)
        } else {
            Text(L10n.settingsTitle)
                .font(
                    dynamicTypeSize.isAccessibilitySize
                        ? .title.weight(.bold)
                        : .largeTitle.weight(.heavy)
                )
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private func appearanceSection(_ settings: SettingsSummary, usesBrand: Bool) -> some View {
        Section {
            Picker("settings.theme.label", selection: Binding(
                get: { settings.appearanceModeRaw },
                set: { viewModel.queueAppearanceUpdate($0) }
            )) {
                Text("settings.theme.system").tag("system")
                Text("settings.theme.light").tag("light")
                Text("settings.theme.dark").tag("dark")
            }
            .accessibilityIdentifier("settings_themePicker")
        } header: {
            Text(L10n.appearanceSection)
        } footer: {
            if settings.appearanceModeRaw != "dark" {
                settingsSectionFooter("settings.theme.footer")
            }
        }
        .brandFormRowBackground(when: usesBrand)
    }

    private func startingModeSection(_ settings: SettingsSummary, usesBrand: Bool) -> some View {
        Section {
            Picker("settings.mode.label", selection: Binding(
                get: { settings.defaultMatchTypeRaw },
                set: { queueGameplayDefaults(from: settings, matchType: $0) }
            )) {
                Text("settings.mode.x01").tag("x01")
                Text("settings.mode.cricket").tag("cricket")
            }
            .accessibilityIdentifier("settings_defaultModePicker")
        } header: {
            Text(L10n.settingsStartingModeSection)
        } footer: {
            settingsSectionFooter(L10n.settingsStartingModeFooter)
        }
        .brandFormRowBackground(when: usesBrand)
    }

    private func matchDefaultsSection(_ settings: SettingsSummary, usesBrand: Bool) -> some View {
        Section {
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
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("settings_defaultSetsToggle")
        } header: {
            Text(L10n.settingsMatchDefaultsSection)
        } footer: {
            settingsSectionFooter(L10n.settingsMatchDefaultsFooter)
        }
        .brandFormRowBackground(when: usesBrand)
    }

    private func x01DefaultsSection(_ settings: SettingsSummary, usesBrand: Bool) -> some View {
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
        } header: {
            Text(L10n.x01DefaultsSection)
        } footer: {
            settingsSectionFooter(L10n.x01DefaultsFooter)
        }
        .brandFormRowBackground(when: usesBrand)
    }

    private func duringPlaySection(usesBrand: Bool) -> some View {
        Section {
            if dependencies.featureFlags.isEnabled(.enableVisualDartboardInput) {
                Picker("settings.dartEntryPresentation.label", selection: Binding(
                    get: {
                        DartEntryPresentation(
                            rawValueOrDefault: viewModel.settings?.defaultDartEntryPresentationRaw
                        ).rawValue
                    },
                    set: { viewModel.queueDartEntryPresentationUpdate($0) }
                )) {
                    Text("settings.dartEntryPresentation.numberPad")
                        .tag(DartEntryPresentation.numberPad.rawValue)
                    Text("settings.dartEntryPresentation.visualBoard")
                        .tag(DartEntryPresentation.visualBoard.rawValue)
                }
                .accessibilityIdentifier("settings_dartEntryPresentationPicker")
                .accessibilityHint(L10n.string("settings.dartEntryPresentation.hint"))
            }
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
            .accessibilityHint(L10n.string("settings.feedback.turnTotalCaller.hint"))
            Toggle("settings.feedback.instantBotTurns", isOn: Binding(
                get: { viewModel.settings?.instantBotTurnsEnabled ?? false },
                set: { viewModel.queueFeedbackUpdate(instantBotTurns: $0) }
            ))
            .accessibilityIdentifier("settings_instantBotTurnsToggle")
            .accessibilityHint(L10n.string("settings.feedback.instantBotTurns.accessibilityHint"))
        } header: {
            Text(L10n.settingsDuringPlaySection)
        } footer: {
            settingsSectionFooter(L10n.settingsDuringPlayFooter)
        }
        .brandFormRowBackground(when: usesBrand)
    }

    private func botOpponentsSection(usesBrand: Bool) -> some View {
        let instantBotTurnsOn = viewModel.settings?.instantBotTurnsEnabled ?? false
        return Section {
            Toggle("settings.feedback.botStagger", isOn: Binding(
                get: { viewModel.settings?.botStaggerEnabled ?? true },
                set: { viewModel.queueBotPacingUpdate(stagger: $0) }
            ))
            .accessibilityIdentifier("settings_botStaggerToggle")
            .disabled(instantBotTurnsOn)
            Toggle("settings.feedback.botDartHaptics", isOn: Binding(
                get: { viewModel.settings?.botDartHapticsEnabled ?? true },
                set: { viewModel.queueBotPacingUpdate(dartHaptics: $0) }
            ))
            .accessibilityIdentifier("settings_botDartHapticsToggle")
            .accessibilityHint(L10n.string("settings.feedback.botDartHaptics.hint"))
            .disabled(instantBotTurnsOn)
        } header: {
            Text(L10n.settingsBotOpponentsSection)
        } footer: {
            settingsSectionFooter(
                instantBotTurnsOn
                    ? L10n.settingsBotOpponentsInstantOverridesFooter
                    : L10n.settingsBotOpponentsFooter
            )
        }
        .brandFormRowBackground(when: usesBrand)
    }

    private func dataSection(usesBrand: Bool) -> some View {
        Section(L10n.dataSection) {
            Button(L10n.resetAllData, role: .destructive) {
                viewModel.requestReset()
            }
            .accessibilityLabel(L10n.string("settings.reset.accessibility"))
            .accessibilityIdentifier("settings_resetAllDataButton")
        }
        .brandFormRowBackground(when: usesBrand)
    }

    private func helpAndFeedbackSection(usesBrand: Bool) -> some View {
        Section {
            Link(destination: AppLinks.support) {
                Label(L10n.settingsSupportFAQ, systemImage: "questionmark.circle")
            }
            .accessibilityLabel(L10n.settingsSupportFAQAccessibility)
            .accessibilityIdentifier("settings_supportFAQLink")

            NavigationLink {
                FeedbackFormView()
            } label: {
                Label(L10n.settingsSupportFeedback, systemImage: "lightbulb")
            }
            .accessibilityLabel(L10n.settingsSupportFeedbackAccessibility)
            .accessibilityHint(L10n.settingsSupportFeedbackHint)
            .accessibilityIdentifier("settings_feedbackForm")

            Link(destination: AppLinks.appStoreReview) {
                Label(L10n.settingsSupportRate, systemImage: "star")
            }
            .accessibilityLabel(L10n.settingsSupportRateAccessibility)
            .accessibilityIdentifier("settings_rateAppLink")

            if ProductSurface.showsAccessibilityMarketing {
                Link(destination: AppLinks.accessibility) {
                    Label(L10n.settingsSupportAccessibility, systemImage: "accessibility")
                }
                .accessibilityLabel(L10n.settingsSupportAccessibilityLabel)
                .accessibilityIdentifier("settings_accessibilityLink")
            }

            Link(destination: AppLinks.privacy) {
                Label(L10n.settingsSupportPrivacy, systemImage: "hand.raised")
            }
            .accessibilityLabel(L10n.settingsSupportPrivacyAccessibility)
            .accessibilityIdentifier("settings_privacyPolicyLink")
        } header: {
            Text(L10n.settingsHelpAndFeedbackSection)
        }
        .brandFormRowBackground(when: usesBrand)
    }

    private func aboutSection(usesBrand: Bool) -> some View {
        Section {
            Button {
                showsOnboarding = true
            } label: {
                Label(L10n.settingsViewOnboarding, systemImage: "book.pages")
            }
            .accessibilityLabel(L10n.settingsViewOnboardingAccessibility)
            .accessibilityIdentifier("settings_viewOnboardingButton")

            Text(AppSupport.versionLabel)
                .foregroundStyle(usesBrand ? Brand.textSecondary : DS.ColorRole.textSecondary)
                .accessibilityLabel(AppSupport.versionLabel)
                .accessibilityIdentifier("settings_aboutVersion")
        } header: {
            Text(L10n.aboutSection)
        }
        .brandFormRowBackground(when: usesBrand)
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
