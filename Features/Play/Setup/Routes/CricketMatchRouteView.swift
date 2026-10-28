import SwiftUI

struct CricketMatchRouteView: View {
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void

    var body: some View {
        MatchRouteScreen(
            matchId: matchId,
            dependencies: dependencies,
            onShowSummary: onShowSummary
        ) {
            CricketMatchViewModel(
                matchId: matchId,
                store: dependencies.activeMatchStore,
                logger: dependencies.logger,
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository,
                feedbackPreferences: dependencies.userPreferencesStore.feedback
            )
        } content: { viewModel, lifecycle in
            CricketMatchScreen(
                viewModel: viewModel,
                onShowSummary: onShowSummary,
                audio: dependencies.audioFeedbackService,
                haptics: dependencies.hapticsService,
                turnTotalCaller: dependencies.turnTotalCallerService,
                feedbackPreferences: dependencies.userPreferencesStore.feedback,
                lifecycleDependencies: lifecycle,
                visualDartboardInputEnabled: dependencies.featureFlags.isEnabled(.enableVisualDartboardInput),
                defaultDartEntryPresentation: dependencies.userPreferencesStore.defaultDartEntryPresentation
                    .resolved(allowsVisualBoard: dependencies.featureFlags.isEnabled(.enableVisualDartboardInput))
            )
        }
    }
}
