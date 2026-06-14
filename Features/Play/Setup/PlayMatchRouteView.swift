import SwiftUI

struct PlayMatchRouteView: View {
    let route: PlayRoute
    let dependencies: AppDependencies
    let onShowSummary: () -> Void

    var body: some View {
        switch route {
        case let .americanCricketMatch(matchId):
            MatchRouteHost {
                AmericanCricketMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel in
                AmericanCricketMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            }

        case let .mickeyMouseMatch(matchId):
            MatchRouteHost {
                MickeyMouseMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel in
                MickeyMouseMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            }

        case let .mulliganMatch(matchId):
            MatchRouteHost {
                MulliganMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel in
                MulliganMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            }

        case let .englishCricketMatch(matchId):
            MatchRouteHost {
                EnglishCricketMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel in
                EnglishCricketMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            }

        case let .knockoutMatch(matchId):
            MatchRouteHost {
                KnockoutMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel in
                KnockoutMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            }

        case let .suddenDeathMatch(matchId):
            MatchRouteHost {
                SuddenDeathMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel in
                SuddenDeathMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            }

        case let .fiftyOneByFivesMatch(matchId):
            MatchRouteHost {
                FiftyOneByFivesMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel in
                FiftyOneByFivesMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            }

        case let .golfMatch(matchId):
            MatchRouteHost {
                GolfMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel in
                GolfMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            }

        case let .footballMatch(matchId):
            MatchRouteHost {
                FootballMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel in
                FootballMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            }

        case let .grandNationalMatch(matchId):
            MatchRouteHost {
                GrandNationalMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel in
                GrandNationalMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            }

        case let .hareAndHoundsMatch(matchId):
            MatchRouteHost {
                HareAndHoundsMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel in
                HareAndHoundsMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            }

        case let .aroundTheClockMatch(matchId):
            MatchRouteHost {
                AroundTheClockMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel in
                AroundTheClockMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            }

        case let .aroundTheClock180Match(matchId):
            MatchRouteHost {
                AroundTheClock180MatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel in
                AroundTheClock180MatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            }

        case let .chaseTheDragonMatch(matchId):
            MatchRouteHost {
                ChaseTheDragonMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel in
                ChaseTheDragonMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            }

        case let .nineLivesMatch(matchId):
            MatchRouteHost {
                NineLivesMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel in
                NineLivesMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            }

        case let .fleetMatch(matchId):
            MatchRouteHost {
                FleetMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel in
                FleetMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            }

        case let .raidMatch(matchId):
            MatchRouteHost {
                RaidMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository
                )
            } content: { viewModel in
                RaidMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            }

        default:
            EmptyView()
        }
    }
}

/// Generic host that owns a match view-model as `@StateObject` and renders a screen for it.
/// Replaces 17 near-identical private wrapper structs with one reusable container.
private struct MatchRouteHost<ViewModel: ObservableObject, Content: View>: View {
    @StateObject private var viewModel: ViewModel
    private let content: (ViewModel) -> Content

    init(
        _ makeViewModel: @escaping () -> ViewModel,
        @ViewBuilder content: @escaping (ViewModel) -> Content
    ) {
        _viewModel = StateObject(wrappedValue: makeViewModel())
        self.content = content
    }

    var body: some View {
        content(viewModel)
    }
}
