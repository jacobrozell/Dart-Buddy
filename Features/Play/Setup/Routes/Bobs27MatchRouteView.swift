import SwiftUI

struct Bobs27MatchRouteView: View {
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void

    var body: some View {
        MatchRouteScreen(
            matchId: matchId,
            dependencies: dependencies,
            onShowSummary: onShowSummary
        ) {
            Bobs27MatchViewModel(
                matchId: matchId,
                store: dependencies.activeMatchStore,
                logger: dependencies.logger,
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository,
                feedbackPreferences: dependencies.userPreferencesStore.feedback
            )
        } content: { viewModel, _ in
            Bobs27MatchScreen(
                viewModel: viewModel,
                onShowSummary: onShowSummary,
                audio: dependencies.audioFeedbackService,
                haptics: dependencies.hapticsService
            )
        }
    }
}
