import SwiftUI

struct AmericanCricketMatchRouteView: View {
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void

    var body: some View {
        MatchRouteScreen(
            matchId: matchId,
            dependencies: dependencies,
            onShowSummary: onShowSummary
        ) {
            AmericanCricketMatchViewModel(
                matchId: matchId,
                store: dependencies.activeMatchStore,
                logger: dependencies.logger,
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository,
                feedbackPreferences: dependencies.userPreferencesStore.feedback
            )
        } content: { viewModel, lifecycle in
            AmericanCricketMatchScreen(
                viewModel: viewModel,
                onShowSummary: onShowSummary,
                audio: dependencies.audioFeedbackService,
                haptics: dependencies.hapticsService,
                feedbackPreferences: dependencies.userPreferencesStore.feedback,
                lifecycleDependencies: lifecycle
            )
        }
    }
}
