import SwiftUI

struct RaidMatchRouteView: View {
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void

    var body: some View {
        MatchRouteScreen(
            matchId: matchId,
            dependencies: dependencies,
            onShowSummary: onShowSummary
        ) {
            RaidMatchViewModel(
                matchId: matchId,
                store: dependencies.activeMatchStore,
                logger: dependencies.logger,
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository
            )
        } content: { viewModel, lifecycle in
            RaidMatchScreen(
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
