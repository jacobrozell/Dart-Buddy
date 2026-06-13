import SwiftUI

struct OnboardingPreferencesStepView: View {
    let dependencies: AppDependencies
    let progressIndex: Int
    let showsBack: Bool
    let onBack: () -> Void
    let onContinue: () -> Void

    @ObservedObject private var preferences: UserPreferencesStore
    @StateObject private var viewModel: SettingsViewModel
    @State private var retryTask: Task<Void, Never>?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var contentMaxWidth: CGFloat {
        horizontalSizeClass == .regular ? 560 : .infinity
    }

    init(
        dependencies: AppDependencies,
        progressIndex: Int,
        showsBack: Bool,
        onBack: @escaping () -> Void,
        onContinue: @escaping () -> Void
    ) {
        self.dependencies = dependencies
        self.progressIndex = progressIndex
        self.showsBack = showsBack
        self.onBack = onBack
        self.onContinue = onContinue
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
        ZStack {
            Brand.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Group {
                    if let settings = viewModel.settings {
                        preferencesForm(settings)
                    } else {
                        switch viewModel.state {
                        case let .error(messageKey):
                            ContentUnavailableView(
                                L10n.errorTitle,
                                systemImage: "exclamationmark.triangle",
                                description: Text(LocalizedStringKey(messageKey))
                                    .foregroundStyle(Brand.textSecondary)
                            )
                            .overlay(alignment: .bottom) {
                                Button(L10n.retry) {
                                    retryTask?.cancel()
                                    retryTask = Task { await viewModel.onAppear() }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Brand.green)
                                .padding(.bottom, DS.Spacing.s6)
                            }
                        default:
                            ProgressView(L10n.settingsLoading)
                        }
                    }
                }
                .frame(maxWidth: contentMaxWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                OnboardingPrimaryButton(
                    title: L10n.onboardingContinue,
                    accessibilityIdentifier: "onboarding_preferences_continue",
                    isEnabled: viewModel.settings != nil
                ) {
                    onContinue()
                }
                .frame(maxWidth: contentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, DS.Spacing.s4)
                .padding(.top, DS.Spacing.s4)
                .padding(.bottom, DS.Spacing.s6)
            }
        }
        .navigationTitle(L10n.onboardingPreferencesTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(L10n.format("onboarding.stepProgress", progressIndex, OnboardingStep.progressTotal))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.textSecondary)
                        .accessibilityLabel(
                            L10n.format("onboarding.stepProgress", progressIndex, OnboardingStep.progressTotal)
                        )
                        .accessibilityIdentifier("onboarding_step_progress")
                }

            if showsBack {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Brand.textPrimary)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel(L10n.string("common.back"))
                    .accessibilityIdentifier("onboarding_back")
                }
            }
        }
        .task { await viewModel.onAppear() }
        .onDisappear {
            retryTask?.cancel()
            viewModel.cancelPendingWork()
        }
    }

    @ViewBuilder
    private func preferencesForm(_ settings: SettingsSummary) -> some View {
        Form {
            Section {
                Picker("settings.theme.label", selection: Binding(
                    get: { settings.appearanceModeRaw },
                    set: { viewModel.queueAppearanceUpdate($0) }
                )) {
                    Text("settings.theme.system").tag("system")
                    Text("settings.theme.light").tag("light")
                    Text("settings.theme.dark").tag("dark")
                }
            } header: {
                Text(L10n.appearanceSection)
            } footer: {
                if settings.appearanceModeRaw != "dark" {
                    Text("settings.theme.footer")
                }
            }
            .brandFormRowBackground(when: true)

            Section(L10n.gameplayDefaultsSection) {
                Picker("settings.mode.label", selection: Binding(
                    get: { settings.defaultMatchTypeRaw },
                    set: { queueGameplayDefaults(from: settings, matchType: $0) }
                )) {
                    Text("settings.mode.x01").tag("x01")
                    Text("settings.mode.cricket").tag("cricket")
                }
            }
            .brandFormRowBackground(when: true)

            Section {
                Picker(L10n.setupChipPoints, selection: Binding(
                    get: { settings.defaultX01StartScore },
                    set: { queueGameplayDefaults(from: settings, startScore: $0) }
                )) {
                    ForEach(X01StartScores.all, id: \.self) { score in
                        Text("\(score)").tag(score)
                    }
                }

                Picker(L10n.setupChipCheckOut, selection: Binding(
                    get: { settings.defaultCheckoutModeRaw },
                    set: { queueGameplayDefaults(from: settings, checkout: $0) }
                )) {
                    ForEach(X01CheckoutMode.allCases, id: \.rawValue) { mode in
                        Text(mode.displayName).tag(mode.rawValue)
                    }
                }

                Picker(L10n.setupChipCheckIn, selection: Binding(
                    get: { settings.defaultCheckInModeRaw },
                    set: { queueGameplayDefaults(from: settings, checkIn: $0) }
                )) {
                    ForEach(X01CheckInMode.allCases, id: \.rawValue) { mode in
                        Text(mode.displayName).tag(mode.rawValue)
                    }
                }

                Picker(L10n.setupChipSetLeg, selection: Binding(
                    get: { settings.defaultLegFormatRaw },
                    set: { queueGameplayDefaults(from: settings, legFormat: $0) }
                )) {
                    ForEach(X01LegFormat.allCases, id: \.rawValue) { format in
                        Text(format.displayName).tag(format.rawValue)
                    }
                }

                Picker(L10n.setupChipLegs, selection: Binding(
                    get: { settings.defaultLegsToWin },
                    set: { queueGameplayDefaults(from: settings, legs: $0) }
                )) {
                    ForEach(1 ... 9, id: \.self) { count in
                        Text("\(count)").tag(count)
                    }
                }
            } header: {
                Text(L10n.x01DefaultsSection)
            } footer: {
                Text(L10n.x01DefaultsFooter)
            }
            .brandFormRowBackground(when: true)

            Section {
                Toggle("settings.feedback.haptics", isOn: Binding(
                    get: { viewModel.settings?.hapticsEnabled ?? true },
                    set: { viewModel.queueFeedbackUpdate(haptics: $0) }
                ))
                Toggle("settings.feedback.sound", isOn: Binding(
                    get: { viewModel.settings?.soundEnabled ?? true },
                    set: { viewModel.queueFeedbackUpdate(sound: $0) }
                ))
                Toggle("settings.feedback.turnTotalCaller", isOn: Binding(
                    get: { viewModel.settings?.turnTotalCallerEnabled ?? false },
                    set: { viewModel.queueFeedbackUpdate(turnTotalCaller: $0) }
                ))
            } header: {
                Text(L10n.feedbackSection)
            } footer: {
                Text(L10n.onboardingPreferencesFooter)
            }
            .brandFormRowBackground(when: true)
        }
        .accessibilityIdentifier("onboarding_preferences_form")
        .tint(Brand.green)
        .brandSettingsFormChrome(appearanceModeRaw: preferences.appearanceModeRaw)
    }

    private func queueGameplayDefaults(
        from settings: SettingsSummary,
        matchType: String? = nil,
        startScore: Int? = nil,
        checkout: String? = nil,
        checkIn: String? = nil,
        legFormat: String? = nil,
        legs: Int? = nil
    ) {
        viewModel.queueDefaultsUpdate(
            matchType: matchType ?? settings.defaultMatchTypeRaw,
            startScore: startScore ?? settings.defaultX01StartScore,
            checkout: checkout ?? settings.defaultCheckoutModeRaw,
            checkIn: checkIn ?? settings.defaultCheckInModeRaw,
            legFormat: legFormat ?? settings.defaultLegFormatRaw,
            legs: legs ?? settings.defaultLegsToWin,
            setsEnabled: settings.defaultSetsEnabled
        )
    }
}
