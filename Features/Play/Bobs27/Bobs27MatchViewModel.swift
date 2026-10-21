import SwiftUI

@MainActor
final class Bobs27MatchViewModel: ObservableObject {
    enum State: Equatable {
        case readyTurn
        case entryInvalid(String)
        case submittingTurn
        case matchCompleted
        case error(String)
    }

    @Published private(set) var state: State = .readyTurn
    @Published var selectedMultiplier: DartMultiplier = .double
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
            matchType: .bobs27,
            eventTypeRaw: "bobs27Round",
            store: store,
            logger: logger,
            matchRepository: matchRepository
        )
        self.session = store.session(for: matchId)
    }

    var bobs27State: Bobs27State? { session?.runtime.bobs27State }

    var canHumanInput: Bool { state == .readyTurn }

    var canSubmit: Bool { enteredDarts.count == 3 && canHumanInput }

    var roundLabel: String {
        guard let state = bobs27State else { return "" }
        switch state.currentTarget {
        case .bull:
            return L10n.string("play.bobs27.round.bull")
        case let .double(n):
            return L10n.format("play.bobs27.round.doubleFormat", n)
        }
    }

    var scoreText: String {
        guard let state = bobs27State else { return "" }
        return L10n.format("play.bobs27.scoreFormat", state.score)
    }

    var progressText: String {
        guard let state = bobs27State else { return "" }
        let roundDisplay = min(state.roundIndex + 1, Bobs27State.totalRounds)
        return L10n.format("play.bobs27.roundProgressFormat", roundDisplay, Bobs27State.totalRounds)
    }

    var headerAccessibilityLabel: String {
        [L10n.string("play.bobs27.navTitle"), roundLabel, scoreText, progressText]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    /// Double N for pad lock; nil on bull round (pad shows bull).
    var lockedSegment: Int? {
        guard let state = bobs27State else { return nil }
        if case let .double(n) = state.currentTarget { return n }
        return nil
    }

    var showsBull: Bool {
        guard let state = bobs27State else { return false }
        if case .bull = state.currentTarget { return true }
        return false
    }

    func submitTurn() async {
        await loadSessionIfNeeded()
        guard let current = session else {
            state = .error("error.match.mode.bobs27Unavailable")
            return
        }
        state = .submittingTurn
        let darts = enteredDarts
        let outcome = await turnSubmitter.submitTurn(
            from: current,
            invalidTurnFallbackKey: "error.turn.maxDarts"
        ) {
            try MatchLifecycleService.submitBobs27Round(session: current, darts: darts)
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
            selectedMultiplier = .double
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
            matchType: .bobs27,
            category: .ui,
            eventName: "match_screen_appeared",
            message: "Bob's 27 match screen presented."
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
            matchType: .bobs27,
            store: store,
            logger: logger,
            matchRepository: matchRepository,
            statsRepository: statsRepository,
            sessionMissingFallbackKey: "error.match.mode.bobs27Unavailable"
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

extension Bobs27MatchViewModel: MatchPlaySessionHost {
    var isBotTurnBlocking: Bool { state == .submittingTurn }
    var hostMatchRepository: any MatchRepository { matchRepository }
    var hostMatchStore: ActiveMatchStore { store }
    var hostMatchLogger: any AppLogger { logger }
    var hostMatchType: MatchType { .bobs27 }
}
