import SwiftUI

struct PlayMatchRouteView: View {
    let route: PlayRoute
    let dependencies: AppDependencies
    let onShowSummary: () -> Void

    var body: some View {
        switch route {
        case let .americanCricketMatch(matchId):
            AmericanCricketMatchRouteView(matchId: matchId, dependencies: dependencies, onShowSummary: onShowSummary)
        case let .mickeyMouseMatch(matchId):
            MickeyMouseMatchRouteView(matchId: matchId, dependencies: dependencies, onShowSummary: onShowSummary)
        case let .mulliganMatch(matchId):
            MulliganMatchRouteView(matchId: matchId, dependencies: dependencies, onShowSummary: onShowSummary)
        case let .englishCricketMatch(matchId):
            EnglishCricketMatchRouteView(matchId: matchId, dependencies: dependencies, onShowSummary: onShowSummary)
        case let .knockoutMatch(matchId):
            KnockoutMatchRouteView(matchId: matchId, dependencies: dependencies, onShowSummary: onShowSummary)
        case let .suddenDeathMatch(matchId):
            SuddenDeathMatchRouteView(matchId: matchId, dependencies: dependencies, onShowSummary: onShowSummary)
        case let .fiftyOneByFivesMatch(matchId):
            FiftyOneByFivesMatchRouteView(matchId: matchId, dependencies: dependencies, onShowSummary: onShowSummary)
        case let .golfMatch(matchId):
            GolfMatchRouteView(matchId: matchId, dependencies: dependencies, onShowSummary: onShowSummary)
        case let .footballMatch(matchId):
            FootballMatchRouteView(matchId: matchId, dependencies: dependencies, onShowSummary: onShowSummary)
        case let .grandNationalMatch(matchId):
            GrandNationalMatchRouteView(matchId: matchId, dependencies: dependencies, onShowSummary: onShowSummary)
        case let .hareAndHoundsMatch(matchId):
            HareAndHoundsMatchRouteView(matchId: matchId, dependencies: dependencies, onShowSummary: onShowSummary)
        case let .aroundTheClockMatch(matchId):
            AroundTheClockMatchRouteView(matchId: matchId, dependencies: dependencies, onShowSummary: onShowSummary)
        case let .aroundTheClock180Match(matchId):
            AroundTheClock180MatchRouteView(matchId: matchId, dependencies: dependencies, onShowSummary: onShowSummary)
        case let .chaseTheDragonMatch(matchId):
            ChaseTheDragonMatchRouteView(matchId: matchId, dependencies: dependencies, onShowSummary: onShowSummary)
        case let .nineLivesMatch(matchId):
            NineLivesMatchRouteView(matchId: matchId, dependencies: dependencies, onShowSummary: onShowSummary)
        case let .fleetMatch(matchId):
            FleetMatchRouteView(matchId: matchId, dependencies: dependencies, onShowSummary: onShowSummary)
        case let .raidMatch(matchId):
            RaidMatchRouteView(matchId: matchId, dependencies: dependencies, onShowSummary: onShowSummary)
        default:
            EmptyView()
        }
    }
}

private struct AmericanCricketMatchRouteView: View {
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void
    @StateObject private var viewModel: AmericanCricketMatchViewModel

    init(matchId: UUID, dependencies: AppDependencies, onShowSummary: @escaping () -> Void) {
        self.matchId = matchId
        self.dependencies = dependencies
        self.onShowSummary = onShowSummary
        _viewModel = StateObject(wrappedValue: Self.makeViewModel(matchId: matchId, dependencies: dependencies))
    }

    var body: some View {
        AmericanCricketMatchScreen(
            viewModel: viewModel,
            onShowSummary: onShowSummary,
            audio: dependencies.audioFeedbackService,
            haptics: dependencies.hapticsService,
            feedbackPreferences: dependencies.userPreferencesStore.feedback
        )
    }

    private static func makeViewModel(matchId: UUID, dependencies: AppDependencies) -> AmericanCricketMatchViewModel {
        AmericanCricketMatchViewModel(
            matchId: matchId,
            store: dependencies.activeMatchStore,
            logger: dependencies.logger,
            matchRepository: dependencies.matchRepository,
            statsRepository: dependencies.statsRepository,
            feedbackPreferences: dependencies.userPreferencesStore.feedback
        )
    }
}

private struct MickeyMouseMatchRouteView: View {
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void
    @StateObject private var viewModel: MickeyMouseMatchViewModel

    init(matchId: UUID, dependencies: AppDependencies, onShowSummary: @escaping () -> Void) {
        self.matchId = matchId
        self.dependencies = dependencies
        self.onShowSummary = onShowSummary
        _viewModel = StateObject(
            wrappedValue: MickeyMouseMatchViewModel(
                matchId: matchId,
                store: dependencies.activeMatchStore,
                logger: dependencies.logger,
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository,
                feedbackPreferences: dependencies.userPreferencesStore.feedback
            )
        )
    }

    var body: some View {
        MickeyMouseMatchScreen(
            viewModel: viewModel,
            onShowSummary: onShowSummary,
            audio: dependencies.audioFeedbackService,
            haptics: dependencies.hapticsService,
            feedbackPreferences: dependencies.userPreferencesStore.feedback
        )
    }
}

private struct MulliganMatchRouteView: View {
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void
    @StateObject private var viewModel: MulliganMatchViewModel

    init(matchId: UUID, dependencies: AppDependencies, onShowSummary: @escaping () -> Void) {
        self.matchId = matchId
        self.dependencies = dependencies
        self.onShowSummary = onShowSummary
        _viewModel = StateObject(
            wrappedValue: MulliganMatchViewModel(
                matchId: matchId,
                store: dependencies.activeMatchStore,
                logger: dependencies.logger,
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository,
                feedbackPreferences: dependencies.userPreferencesStore.feedback
            )
        )
    }

    var body: some View {
        MulliganMatchScreen(
            viewModel: viewModel,
            onShowSummary: onShowSummary,
            audio: dependencies.audioFeedbackService,
            haptics: dependencies.hapticsService,
            feedbackPreferences: dependencies.userPreferencesStore.feedback
        )
    }
}

private struct EnglishCricketMatchRouteView: View {
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void
    @StateObject private var viewModel: EnglishCricketMatchViewModel

    init(matchId: UUID, dependencies: AppDependencies, onShowSummary: @escaping () -> Void) {
        self.matchId = matchId
        self.dependencies = dependencies
        self.onShowSummary = onShowSummary
        _viewModel = StateObject(
            wrappedValue: EnglishCricketMatchViewModel(
                matchId: matchId,
                store: dependencies.activeMatchStore,
                logger: dependencies.logger,
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository,
                feedbackPreferences: dependencies.userPreferencesStore.feedback
            )
        )
    }

    var body: some View {
        EnglishCricketMatchScreen(
            viewModel: viewModel,
            onShowSummary: onShowSummary,
            audio: dependencies.audioFeedbackService,
            haptics: dependencies.hapticsService,
            feedbackPreferences: dependencies.userPreferencesStore.feedback
        )
    }
}

private struct KnockoutMatchRouteView: View {
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void
    @StateObject private var viewModel: KnockoutMatchViewModel

    init(matchId: UUID, dependencies: AppDependencies, onShowSummary: @escaping () -> Void) {
        self.matchId = matchId
        self.dependencies = dependencies
        self.onShowSummary = onShowSummary
        _viewModel = StateObject(
            wrappedValue: KnockoutMatchViewModel(
                matchId: matchId,
                store: dependencies.activeMatchStore,
                logger: dependencies.logger,
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository,
                feedbackPreferences: dependencies.userPreferencesStore.feedback
            )
        )
    }

    var body: some View {
        KnockoutMatchScreen(
            viewModel: viewModel,
            onShowSummary: onShowSummary,
            audio: dependencies.audioFeedbackService,
            haptics: dependencies.hapticsService,
            feedbackPreferences: dependencies.userPreferencesStore.feedback
        )
    }
}

private struct SuddenDeathMatchRouteView: View {
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void
    @StateObject private var viewModel: SuddenDeathMatchViewModel

    init(matchId: UUID, dependencies: AppDependencies, onShowSummary: @escaping () -> Void) {
        self.matchId = matchId
        self.dependencies = dependencies
        self.onShowSummary = onShowSummary
        _viewModel = StateObject(
            wrappedValue: SuddenDeathMatchViewModel(
                matchId: matchId,
                store: dependencies.activeMatchStore,
                logger: dependencies.logger,
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository,
                feedbackPreferences: dependencies.userPreferencesStore.feedback
            )
        )
    }

    var body: some View {
        SuddenDeathMatchScreen(
            viewModel: viewModel,
            onShowSummary: onShowSummary,
            audio: dependencies.audioFeedbackService,
            haptics: dependencies.hapticsService,
            feedbackPreferences: dependencies.userPreferencesStore.feedback
        )
    }
}

private struct FiftyOneByFivesMatchRouteView: View {
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void
    @StateObject private var viewModel: FiftyOneByFivesMatchViewModel

    init(matchId: UUID, dependencies: AppDependencies, onShowSummary: @escaping () -> Void) {
        self.matchId = matchId
        self.dependencies = dependencies
        self.onShowSummary = onShowSummary
        _viewModel = StateObject(
            wrappedValue: FiftyOneByFivesMatchViewModel(
                matchId: matchId,
                store: dependencies.activeMatchStore,
                logger: dependencies.logger,
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository,
                feedbackPreferences: dependencies.userPreferencesStore.feedback
            )
        )
    }

    var body: some View {
        FiftyOneByFivesMatchScreen(
            viewModel: viewModel,
            onShowSummary: onShowSummary,
            audio: dependencies.audioFeedbackService,
            haptics: dependencies.hapticsService,
            feedbackPreferences: dependencies.userPreferencesStore.feedback
        )
    }
}

private struct GolfMatchRouteView: View {
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void
    @StateObject private var viewModel: GolfMatchViewModel

    init(matchId: UUID, dependencies: AppDependencies, onShowSummary: @escaping () -> Void) {
        self.matchId = matchId
        self.dependencies = dependencies
        self.onShowSummary = onShowSummary
        _viewModel = StateObject(
            wrappedValue: GolfMatchViewModel(
                matchId: matchId,
                store: dependencies.activeMatchStore,
                logger: dependencies.logger,
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository,
                feedbackPreferences: dependencies.userPreferencesStore.feedback
            )
        )
    }

    var body: some View {
        GolfMatchScreen(
            viewModel: viewModel,
            onShowSummary: onShowSummary,
            audio: dependencies.audioFeedbackService,
            haptics: dependencies.hapticsService,
            feedbackPreferences: dependencies.userPreferencesStore.feedback
        )
    }
}

private struct FootballMatchRouteView: View {
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void
    @StateObject private var viewModel: FootballMatchViewModel

    init(matchId: UUID, dependencies: AppDependencies, onShowSummary: @escaping () -> Void) {
        self.matchId = matchId
        self.dependencies = dependencies
        self.onShowSummary = onShowSummary
        _viewModel = StateObject(
            wrappedValue: FootballMatchViewModel(
                matchId: matchId,
                store: dependencies.activeMatchStore,
                logger: dependencies.logger,
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository,
                feedbackPreferences: dependencies.userPreferencesStore.feedback
            )
        )
    }

    var body: some View {
        FootballMatchScreen(
            viewModel: viewModel,
            onShowSummary: onShowSummary,
            audio: dependencies.audioFeedbackService,
            haptics: dependencies.hapticsService,
            feedbackPreferences: dependencies.userPreferencesStore.feedback
        )
    }
}

private struct GrandNationalMatchRouteView: View {
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void
    @StateObject private var viewModel: GrandNationalMatchViewModel

    init(matchId: UUID, dependencies: AppDependencies, onShowSummary: @escaping () -> Void) {
        self.matchId = matchId
        self.dependencies = dependencies
        self.onShowSummary = onShowSummary
        _viewModel = StateObject(
            wrappedValue: GrandNationalMatchViewModel(
                matchId: matchId,
                store: dependencies.activeMatchStore,
                logger: dependencies.logger,
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository,
                feedbackPreferences: dependencies.userPreferencesStore.feedback
            )
        )
    }

    var body: some View {
        GrandNationalMatchScreen(
            viewModel: viewModel,
            onShowSummary: onShowSummary,
            audio: dependencies.audioFeedbackService,
            haptics: dependencies.hapticsService,
            feedbackPreferences: dependencies.userPreferencesStore.feedback
        )
    }
}

private struct HareAndHoundsMatchRouteView: View {
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void
    @StateObject private var viewModel: HareAndHoundsMatchViewModel

    init(matchId: UUID, dependencies: AppDependencies, onShowSummary: @escaping () -> Void) {
        self.matchId = matchId
        self.dependencies = dependencies
        self.onShowSummary = onShowSummary
        _viewModel = StateObject(
            wrappedValue: HareAndHoundsMatchViewModel(
                matchId: matchId,
                store: dependencies.activeMatchStore,
                logger: dependencies.logger,
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository,
                feedbackPreferences: dependencies.userPreferencesStore.feedback
            )
        )
    }

    var body: some View {
        HareAndHoundsMatchScreen(
            viewModel: viewModel,
            onShowSummary: onShowSummary,
            audio: dependencies.audioFeedbackService,
            haptics: dependencies.hapticsService,
            feedbackPreferences: dependencies.userPreferencesStore.feedback
        )
    }
}

private struct AroundTheClockMatchRouteView: View {
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void
    @StateObject private var viewModel: AroundTheClockMatchViewModel

    init(matchId: UUID, dependencies: AppDependencies, onShowSummary: @escaping () -> Void) {
        self.matchId = matchId
        self.dependencies = dependencies
        self.onShowSummary = onShowSummary
        _viewModel = StateObject(
            wrappedValue: AroundTheClockMatchViewModel(
                matchId: matchId,
                store: dependencies.activeMatchStore,
                logger: dependencies.logger,
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository,
                feedbackPreferences: dependencies.userPreferencesStore.feedback
            )
        )
    }

    var body: some View {
        AroundTheClockMatchScreen(
            viewModel: viewModel,
            onShowSummary: onShowSummary,
            audio: dependencies.audioFeedbackService,
            haptics: dependencies.hapticsService,
            feedbackPreferences: dependencies.userPreferencesStore.feedback
        )
    }
}

private struct AroundTheClock180MatchRouteView: View {
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void
    @StateObject private var viewModel: AroundTheClock180MatchViewModel

    init(matchId: UUID, dependencies: AppDependencies, onShowSummary: @escaping () -> Void) {
        self.matchId = matchId
        self.dependencies = dependencies
        self.onShowSummary = onShowSummary
        _viewModel = StateObject(
            wrappedValue: AroundTheClock180MatchViewModel(
                matchId: matchId,
                store: dependencies.activeMatchStore,
                logger: dependencies.logger,
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository,
                feedbackPreferences: dependencies.userPreferencesStore.feedback
            )
        )
    }

    var body: some View {
        AroundTheClock180MatchScreen(
            viewModel: viewModel,
            onShowSummary: onShowSummary,
            audio: dependencies.audioFeedbackService,
            haptics: dependencies.hapticsService,
            feedbackPreferences: dependencies.userPreferencesStore.feedback
        )
    }
}

private struct ChaseTheDragonMatchRouteView: View {
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void
    @StateObject private var viewModel: ChaseTheDragonMatchViewModel

    init(matchId: UUID, dependencies: AppDependencies, onShowSummary: @escaping () -> Void) {
        self.matchId = matchId
        self.dependencies = dependencies
        self.onShowSummary = onShowSummary
        _viewModel = StateObject(
            wrappedValue: ChaseTheDragonMatchViewModel(
                matchId: matchId,
                store: dependencies.activeMatchStore,
                logger: dependencies.logger,
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository,
                feedbackPreferences: dependencies.userPreferencesStore.feedback
            )
        )
    }

    var body: some View {
        ChaseTheDragonMatchScreen(
            viewModel: viewModel,
            onShowSummary: onShowSummary,
            audio: dependencies.audioFeedbackService,
            haptics: dependencies.hapticsService,
            feedbackPreferences: dependencies.userPreferencesStore.feedback
        )
    }
}

private struct NineLivesMatchRouteView: View {
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void
    @StateObject private var viewModel: NineLivesMatchViewModel

    init(matchId: UUID, dependencies: AppDependencies, onShowSummary: @escaping () -> Void) {
        self.matchId = matchId
        self.dependencies = dependencies
        self.onShowSummary = onShowSummary
        _viewModel = StateObject(
            wrappedValue: NineLivesMatchViewModel(
                matchId: matchId,
                store: dependencies.activeMatchStore,
                logger: dependencies.logger,
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository,
                feedbackPreferences: dependencies.userPreferencesStore.feedback
            )
        )
    }

    var body: some View {
        NineLivesMatchScreen(
            viewModel: viewModel,
            onShowSummary: onShowSummary,
            audio: dependencies.audioFeedbackService,
            haptics: dependencies.hapticsService,
            feedbackPreferences: dependencies.userPreferencesStore.feedback
        )
    }
}

private struct FleetMatchRouteView: View {
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void
    @StateObject private var viewModel: FleetMatchViewModel

    init(matchId: UUID, dependencies: AppDependencies, onShowSummary: @escaping () -> Void) {
        self.matchId = matchId
        self.dependencies = dependencies
        self.onShowSummary = onShowSummary
        _viewModel = StateObject(
            wrappedValue: FleetMatchViewModel(
                matchId: matchId,
                store: dependencies.activeMatchStore,
                logger: dependencies.logger,
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository,
                feedbackPreferences: dependencies.userPreferencesStore.feedback
            )
        )
    }

    var body: some View {
        FleetMatchScreen(
            viewModel: viewModel,
            onShowSummary: onShowSummary,
            audio: dependencies.audioFeedbackService,
            haptics: dependencies.hapticsService,
            feedbackPreferences: dependencies.userPreferencesStore.feedback
        )
    }
}

private struct RaidMatchRouteView: View {
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void
    @StateObject private var viewModel: RaidMatchViewModel

    init(matchId: UUID, dependencies: AppDependencies, onShowSummary: @escaping () -> Void) {
        self.matchId = matchId
        self.dependencies = dependencies
        self.onShowSummary = onShowSummary
        _viewModel = StateObject(
            wrappedValue: RaidMatchViewModel(
                matchId: matchId,
                store: dependencies.activeMatchStore,
                logger: dependencies.logger,
                matchRepository: dependencies.matchRepository
            )
        )
    }

    var body: some View {
        RaidMatchScreen(
            viewModel: viewModel,
            onShowSummary: onShowSummary,
            audio: dependencies.audioFeedbackService,
            haptics: dependencies.hapticsService,
            feedbackPreferences: dependencies.userPreferencesStore.feedback
        )
    }
}
