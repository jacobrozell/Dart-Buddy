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
                onSkip: { finish(skipped: true) }
            )
        case .experienceQuestion:
            OnboardingExperienceStepView(
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
            OnboardingPreferencesStepView(dependencies: dependencies) {
                step = .ready
            }
        case .learnToPlay:
            OnboardingLearnStepView {
                step = .ready
            }
        case .ready:
            OnboardingReadyStepView {
                finish(skipped: false)
            }
        }
    }

    private func finish(skipped: Bool) {
        if mode == .firstLaunch {
            store.markCompleted()
            if let experience, !skipped {
                store.saveExperience(experience)
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
}
