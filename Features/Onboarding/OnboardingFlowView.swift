import SwiftUI

struct OnboardingFlowView: View {
    let mode: OnboardingPresentationMode
    let dependencies: AppDependencies
    var store: OnboardingStore = OnboardingStore()
    var logger: (any AppLogger)?
    var preferredColorScheme: ColorScheme?
    let onFinished: () -> Void

    @State private var step: OnboardingStep = .welcome
    @State private var experience: OnboardingExperience?
    @State private var skippedFromWelcome = false

    var body: some View {
        NavigationStack {
            stepContent
        }
        .navigationBarTitleDisplayMode(.inline)
        .legacyHiddenNavigationBarBackground()
        .preferredColorScheme(preferredColorScheme)
        .interactiveDismissDisabled(mode == .firstLaunch)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .welcome:
            OnboardingWelcomeStepView(
                onNext: { step = .experienceQuestion },
                onSkip: {
                    skippedFromWelcome = true
                    step = .ready
                }
            )
        case .experienceQuestion:
            OnboardingExperienceStepView(
                progressIndex: step.progressIndex,
                showsBack: true,
                onBack: { goBack() },
                onExperienced: {
                    experience = .experienced
                    step = .preferences
                },
                onBeginner: {
                    experience = .beginner
                    step = .learnToPlay
                }
            )
        case .preferences:
            OnboardingPreferencesStepView(
                dependencies: dependencies,
                progressIndex: step.progressIndex,
                showsBack: true,
                onBack: { goBack() }
            ) {
                step = .appTour
            }
        case .learnToPlay:
            OnboardingLearnStepView(
                progressIndex: step.progressIndex,
                showsBack: true,
                onBack: { goBack() }
            ) {
                step = .appTour
            }
        case .appTour:
            OnboardingAppTourStepView(
                progressIndex: step.progressIndex,
                showsBack: true,
                onBack: { goBack() }
            ) {
                step = .support
            }
        case .support:
            OnboardingSupportStepView(
                progressIndex: step.progressIndex,
                showsBack: true,
                onBack: { goBack() }
            ) {
                step = .ready
            }
        case .ready:
            OnboardingReadyStepView(
                progressIndex: step.progressIndex,
                showsBack: step.backStep(experience: experience) != nil,
                onBack: { goBack() }
            ) {
                finish(skipped: skippedFromWelcome)
            }
        }
    }

    private func goBack() {
        guard let previous = step.backStep(experience: experience) else { return }
        step = previous
    }

    private func finish(skipped: Bool) {
        if mode == .firstLaunch {
            store.markCompleted()
            if let experience, !skipped {
                store.saveExperience(experience)
                if experience == .beginner {
                    applyBeginnerGameplayDefaults()
                }
            }
            var metadata: [String: String] = ["skipped": skipped ? "true" : "false"]
            if let experience, !skipped {
                metadata["experience"] = experience.rawValue
            }
            logger?.debug(
                .ui,
                eventName: "onboarding_completed",
                message: "First-launch onboarding finished.",
                metadata: metadata
            )
        }
        onFinished()
    }

    private func applyBeginnerGameplayDefaults() {
        Task {
            do {
                let current = try await dependencies.settingsRepository.fetchSettings()
                guard current.defaultMatchTypeRaw != MatchType.x01.rawValue else { return }
                let updated = SettingsSummary(
                    id: current.id,
                    appearanceModeRaw: current.appearanceModeRaw,
                    hapticsEnabled: current.hapticsEnabled,
                    soundEnabled: current.soundEnabled,
                    turnTotalCallerEnabled: current.turnTotalCallerEnabled,
                    defaultMatchTypeRaw: MatchType.x01.rawValue,
                    defaultX01StartScore: current.defaultX01StartScore,
                    defaultCheckoutModeRaw: current.defaultCheckoutModeRaw,
                    defaultCheckInModeRaw: current.defaultCheckInModeRaw,
                    defaultLegFormatRaw: current.defaultLegFormatRaw,
                    defaultLegsToWin: current.defaultLegsToWin,
                    defaultSetsEnabled: current.defaultSetsEnabled,
                    botStaggerEnabled: current.botStaggerEnabled,
                    botDartHapticsEnabled: current.botDartHapticsEnabled,
                    updatedAt: current.updatedAt
                )
                _ = try await dependencies.settingsRepository.updateSettings(updated)
            } catch {
                logger?.debug(
                    .ui,
                    eventName: "onboarding_beginner_defaults_failed",
                    message: "Could not apply beginner gameplay defaults.",
                    metadata: ["error": String(describing: error)]
                )
            }
        }
    }
}
