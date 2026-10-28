import SwiftUI

struct X01MatchRouteView: View {
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void

    var body: some View {
        MatchRouteScreen(
            matchId: matchId,
            dependencies: dependencies,
            onShowSummary: onShowSummary
        ) {
            X01MatchViewModel(
                matchId: matchId,
                store: dependencies.activeMatchStore,
                logger: dependencies.logger,
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository,
                feedbackPreferences: dependencies.userPreferencesStore.feedback
            )
        } content: { viewModel, lifecycle in
            X01MatchScreen(
                viewModel: viewModel,
                onShowSummary: onShowSummary,
                audio: dependencies.audioFeedbackService,
                haptics: dependencies.hapticsService,
                turnTotalCaller: dependencies.turnTotalCallerService,
                feedbackPreferences: dependencies.userPreferencesStore.feedback,
                lifecycleDependencies: lifecycle,
                visionScoringEnabled: dependencies.featureFlags.isEnabled(.enableVisionAutoScoring),
                visualDartboardInputEnabled: dependencies.featureFlags.isEnabled(.enableVisualDartboardInput),
                visionLogger: dependencies.logger,
                defaultDartEntryPresentation: dependencies.userPreferencesStore.defaultDartEntryPresentation
                    .resolved(allowsVisualBoard: dependencies.featureFlags.isEnabled(.enableVisualDartboardInput))
            )
        }
    }
}
