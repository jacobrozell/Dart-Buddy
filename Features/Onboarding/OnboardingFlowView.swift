import SwiftUI

struct OnboardingFlowView: View {
    let mode: OnboardingPresentationMode
    let dependencies: AppDependencies
    var store: OnboardingStore = OnboardingStore()
    var logger: (any AppLogger)?
    var preferredColorScheme: ColorScheme?
    let onFinished: () -> Void

    @State private var step: OnboardingStep = .welcome
    @State private var rosterDraft: OnboardingRosterDraft?
    @State private var skippedFromWelcome = false
    @State private var skipsRosterSetup = false
    @State private var finishTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            stepContent
        }
        .navigationBarTitleDisplayMode(.inline)
        .legacyHiddenNavigationBarBackground()
        .preferredColorScheme(preferredColorScheme)
        .interactiveDismissDisabled(mode == .firstLaunch)
        .onDisappear { finishTask?.cancel() }
        .task { await resolveRosterSetupSkip() }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .welcome:
            OnboardingWelcomeStepView(
                onNext: { advanceFromWelcome() },
                onSkip: {
                    skippedFromWelcome = true
                    step = .ready
                }
            )
        case .rosterSetup:
            OnboardingRosterSetupStepView(
                progressIndex: step.progressIndex,
                showsBack: true,
                onBack: { goBack() }
            ) { draft in
                rosterDraft = draft
                step = draft.botDifficulty.showsOnboardingRulesIntro ? .learnToPlay : .preferences
            }
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
                rosterSummary: readyRosterSummary,
                showsBack: step.backStep(
                    showsRulesIntro: rosterDraft?.botDifficulty.showsOnboardingRulesIntro,
                    skipsRosterSetup: skipsRosterSetup
                ) != nil,
                onBack: { goBack() }
            ) {
                finishTask?.cancel()
                finishTask = Task { await completeOnboarding() }
            }
        }
    }

    private var readyRosterSummary: OnboardingRosterDraft? {
        guard mode == .firstLaunch, !skippedFromWelcome else { return nil }
        return rosterDraft
    }

    private func goBack() {
        guard let previous = step.backStep(
            showsRulesIntro: rosterDraft?.botDifficulty.showsOnboardingRulesIntro,
            skipsRosterSetup: skipsRosterSetup
        ) else { return }
        step = previous
    }

    @MainActor
    private func resolveRosterSetupSkip() async {
        guard let primary = try? await dependencies.playerRepository.fetchPrimaryPlayer() else { return }
        skipsRosterSetup = true
        seedRosterDraft(from: primary)
    }

    private func advanceFromWelcome() {
        if skipsRosterSetup, rosterDraft != nil {
            step = nextStepAfterRoster()
        } else {
            step = .rosterSetup
        }
    }

    private func nextStepAfterRoster() -> OnboardingStep {
        guard let draft = rosterDraft else { return .preferences }
        return draft.botDifficulty.showsOnboardingRulesIntro ? .learnToPlay : .preferences
    }

    private func seedRosterDraft(from primary: PlayerSummary) {
        let tier = store.savedExperienceTier ?? .medium
        rosterDraft = OnboardingRosterDraft(
            name: primary.name,
            avatarStyle: primary.avatarStyle,
            colorToken: primary.colorToken,
            botDifficulty: tier
        )
    }

    @MainActor
    private func completeOnboarding() async {
        if mode == .firstLaunch {
            if !skippedFromWelcome, let draft = rosterDraft {
                await persistRoster(draft)
                store.saveExperienceTier(draft.botDifficulty)
            }
            store.markCompleted()

            var metadata: [String: String] = ["skipped": skippedFromWelcome ? "true" : "false"]
            if let draft = rosterDraft, !skippedFromWelcome {
                metadata["bot_tier"] = draft.botDifficulty.rawValue
                metadata["created_player"] = "true"
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

    @MainActor
    private func persistRoster(_ draft: OnboardingRosterDraft) async {
        let editable = EditablePlayer(
            id: UUID(),
            name: draft.name,
            isArchived: false,
            notes: "",
            isBot: false,
            isTrainingBot: false,
            isCustomBot: false,
            customX01Average: CustomBotMetrics.defaultX01Average,
            customCricketMPR: CustomBotMetrics.defaultCricketMPR,
            customBotConfiguration: nil,
            linkedPlayerId: nil,
            botDifficulty: nil,
            avatarStyle: draft.avatarStyle,
            colorToken: draft.colorToken,
            playerRole: .primary
        )
        do {
            let human = try await dependencies.playerRepository.createHumanPlayer(from: editable)
            let bot = try await dependencies.playerRepository.createBot(difficulty: draft.botDifficulty)
            dependencies.pendingMatchPlayerSelections.enqueueForNextMatchSetup(human.id)
            dependencies.pendingMatchPlayerSelections.enqueueForNextMatchSetup(bot.id)
            if draft.botDifficulty.showsOnboardingRulesIntro {
                await applyBeginnerGameplayDefaults()
            }
        } catch let appError as AppError {
            logger?.warning(
                .ui,
                eventName: "onboarding_roster_persist_failed",
                message: "Failed to persist onboarding roster.",
                metadata: ["error": appError.userMessageKey]
            )
        } catch {
            logger?.warning(
                .ui,
                eventName: "onboarding_roster_persist_failed",
                message: "Failed to persist onboarding roster.",
                metadata: ["error": String(describing: error)]
            )
        }
    }

    private func applyBeginnerGameplayDefaults() async {
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
