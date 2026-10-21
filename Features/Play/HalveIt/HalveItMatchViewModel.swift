import SwiftUI

@MainActor
final class HalveItMatchViewModel: ObservableObject {
    enum State: Equatable {
        case readyTurn
        case entryInvalid(String)
        case submittingTurn
        case matchCompleted
        case error(String)
    }

    @Published private(set) var state: State = .readyTurn
    @Published var selectedMultiplier: DartMultiplier = .single
    @Published var enteredDarts: [DartInput] = []
    @Published var session: MatchLifecycleSession?

    let matchId: UUID
    private let store: ActiveMatchStore
    private let logger: any AppLogger
    private let matchRepository: any MatchRepository
    private let statsRepository: any StatsRepository
    private let turnSubmitter: MatchTurnSubmitter

    init(
        matchId: UUID,
        store: ActiveMatchStore,
        logger: any AppLogger,
        matchRepository: any MatchRepository,
        statsRepository: any StatsRepository,
        feedbackPreferences: FeedbackPreferences = FeedbackPreferences()
    ) {
        self.matchId = matchId
        self.store = store
        self.logger = logger
        self.matchRepository = matchRepository
        self.statsRepository = statsRepository
        _ = feedbackPreferences
        self.turnSubmitter = MatchTurnSubmitter(
            matchId: matchId,
            matchType: .halveIt,
            eventTypeRaw: "halveItRound",
            store: store,
            logger: logger,
            matchRepository: matchRepository
        )
        self.session = store.session(for: matchId)
    }

    var halveItState: HalveItState? { session?.runtime.halveItState }

    var canHumanInput: Bool { state == .readyTurn }

    var canSubmit: Bool { enteredDarts.count == 3 && canHumanInput }

    var currentPlayerTotal: Int {
        guard let game = halveItState,
              game.players.indices.contains(game.currentPlayerIndex) else { return 0 }
        return game.players[game.currentPlayerIndex].total
    }

    var scoreText: String {
        L10n.format("play.halveIt.runningTotalFormat", currentPlayerTotal)
    }

    var roundTargetText: String {
        guard let target = halveItState?.currentTarget else { return "" }
        return L10n.format("play.halveIt.roundTargetFormat", target)
    }

    var progressText: String {
        guard let game = halveItState else { return "" }
        let roundDisplay = min(game.roundIndex + 1, game.config.targets.count)
        return L10n.format(
            "play.halveIt.roundProgressFormat",
            roundDisplay,
            game.config.targets.count
        )
    }

    var headerAccessibilityLabel: String {
        [L10n.string("play.halveIt.navTitle"), roundTargetText, scoreText, progressText]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    var lockedSegment: Int? { halveItState?.currentTarget }

    func submitTurn() async {
        await loadSessionIfNeeded()
        guard let current = session else {
            state = .error("error.match.mode.halveItUnavailable")
            return
        }
        state = .submittingTurn
        let darts = enteredDarts
        let outcome = await turnSubmitter.submitTurn(
            from: current,
            invalidTurnFallbackKey: "error.turn.maxDarts"
        ) {
            try MatchLifecycleService.submitHalveItRound(session: current, darts: darts)
        }
        switch outcome {
        case .cancelled:
            state = .readyTurn
        case let .rejected(messageKey):
            state = .entryInvalid(messageKey)
        case let .persistFailed(messageKey):
            state = .error(messageKey)
        case let .succeeded(updated):
            session = updated
            enteredDarts.removeAll()
            state = updated.runtime.status == .completed ? .matchCompleted : .readyTurn
        }
    }

    func undoLastDart() async {
        await loadSessionIfNeeded()
        guard let current = session else { return }
        if !enteredDarts.isEmpty {
            enteredDarts.removeLast()
            selectedMultiplier = .single
            return
        }
        do {
            let result = try await MatchTurnSupport.undoLastDart(
                session: current,
                matchId: matchId,
                store: store,
                matchRepository: matchRepository
            )
            session = result.session
            state = .readyTurn
            enteredDarts = result.restoredDarts
        } catch is CancellationError {
            state = .readyTurn
        } catch {
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "error.match.undoFailed"))
        }
    }

    func onAppear() async {
        logger.matchInfo(
            matchId: matchId,
            matchType: .halveIt,
            category: .ui,
            eventName: "match_screen_appeared",
            message: "Halve-It match screen presented."
        )
        MatchGameplaySessionSync.refreshStoredSession(matchId: matchId, store: store, into: &session)
        if await reconcileAfterSummaryUndo() { return }
        await loadSessionIfNeeded()
    }

    func onDisappear() {}

    func recoverBotPlaybackIfNeeded() {}

    private func reconcileAfterSummaryUndo() async -> Bool {
        guard state == .matchCompleted,
              let stored = store.session(for: matchId),
              stored.runtime.status == .inProgress else { return false }
        session = stored
        state = .readyTurn
        enteredDarts = store.consumeResumeHint(matchId: matchId) ?? []
        return true
    }

    func loadSessionIfNeeded() async {
        if session != nil { return }
        switch await MatchSessionLoader.load(
            matchId: matchId,
            matchType: .halveIt,
            store: store,
            logger: logger,
            matchRepository: matchRepository,
            statsRepository: statsRepository,
            sessionMissingFallbackKey: "error.match.mode.halveItUnavailable"
        ) {
        case let .loaded(loaded):
            session = loaded
        case .missing:
            break
        case let .failed(messageKey):
            state = .error(messageKey)
        }
    }
}

extension HalveItMatchViewModel: MatchPlaySessionHost {
    var isBotTurnBlocking: Bool { state == .submittingTurn }
    var hostMatchRepository: any MatchRepository { matchRepository }
    var hostMatchStore: ActiveMatchStore { store }
    var hostMatchLogger: any AppLogger { logger }
    var hostMatchType: MatchType { .halveIt }
}
