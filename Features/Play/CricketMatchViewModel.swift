import SwiftUI

@MainActor
final class CricketMatchViewModel: ObservableObject {
    enum State: Equatable {
        case readyTurn
        case entryInvalid(String)
        case submittingTurn
        case closureTransition
        case matchCompleted
        case error(String)
    }

    @Published private(set) var state: State = .readyTurn
    @Published var selectedMultiplier: DartMultiplier = .single
    @Published var enteredDarts: [DartInput] = []
    @Published private(set) var session: MatchLifecycleSession?
    @Published private(set) var isBotPlaying = false
    /// Fires after a human visit is accepted so the UI can announce the visit total.
    @Published private(set) var turnTotalCallerSignal: TurnTotalCallerSignal?

    private var turnTotalCallerToken = 0

    private let matchId: UUID
    private let store: ActiveMatchStore
    private let logger: any AppLogger
    private let matchRepository: any MatchRepository
    private let statsRepository: any StatsRepository
    private let feedbackPreferences: FeedbackPreferences

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
        self.feedbackPreferences = feedbackPreferences
        self.session = store.session(for: matchId)
    }

    var canSubmit: Bool { !enteredDarts.isEmpty && canHumanInput }

    var isCurrentPlayerBot: Bool {
        currentBotDifficulty != nil
    }

    var canHumanInput: Bool {
        isCurrentPlayerBot == false && isBotPlaying == false && state == .readyTurn
    }

    var currentBotDifficulty: BotDifficulty? {
        guard let session, let cricketState = session.runtime.cricketState else { return nil }
        guard session.runtime.status == .inProgress else { return nil }
        let player = cricketState.players[cricketState.currentPlayerIndex]
        return DartBotEngine.botDifficulty(
            playerId: player.playerId,
            in: session.runtime.participants
        )
    }

    // MARK: - Presentation

    var cricketState: CricketState? { session?.runtime.cricketState }

    var boardColumns: [CricketBoardView.Column] {
        guard let session, let state = session.runtime.cricketState else { return [] }
        let isInProgress = session.runtime.status == .inProgress
        let highlightClosure = self.state == .closureTransition
        return state.players.enumerated().map { index, player in
            CricketBoardView.Column(
                id: player.playerId,
                name: name(for: player.playerId, fallbackIndex: index),
                score: player.score,
                marks: player.marks,
                isActive: index == state.currentPlayerIndex && isInProgress,
                isClosureHighlight: highlightClosure && index == state.currentPlayerIndex
            )
        }
    }

    private func name(for playerId: UUID, fallbackIndex: Int) -> String {
        let participant = session?.runtime.participants.first { ($0.playerId ?? $0.id) == playerId }
        return participant?.displayNameAtMatchStart ?? MatchConfigText.playerName(forIndex: fallbackIndex)
    }

    func submitTurn() async {
        await submitTurnAsync()
    }

    func undoLastTurn() async {
        await undoLastTurnAsync()
    }

    func onAppear() async {
        logger.matchDebug(
            matchId: matchId,
            matchType: .cricket,
            category: .ui,
            eventName: "match_screen_appeared",
            message: "Cricket match screen presented."
        )
        await loadSessionIfNeeded()
        reconcileInterruptedBotPlayback()
        await playBotTurnIfNeeded()
    }

    /// Clears transient bot UI when the screen reappears after a cancelled bot task.
    private func reconcileInterruptedBotPlayback() {
        isBotPlaying = false
        enteredDarts.removeAll()
        if state == .submittingTurn {
            state = .readyTurn
        }
    }

    func playBotTurnIfNeeded() async {
        guard let difficulty = currentBotDifficulty,
              state == .readyTurn,
              isBotPlaying == false,
              let cricketState = session?.runtime.cricketState else { return }

        isBotPlaying = true
        defer { isBotPlaying = false }
        logger.matchDebug(
            matchId: matchId,
            matchType: .cricket,
            eventName: "bot_turn_started",
            message: "Bot visit generation started."
        )

        enteredDarts.removeAll()
        var rng = SystemRandomNumberGenerator()
        let plannedDarts = DartBotEngine.generateCricketTurn(
            state: cricketState,
            playerIndex: cricketState.currentPlayerIndex,
            difficulty: difficulty,
            rng: &rng
        )

        let dartDelay = BotTurnPacing.dartDelayNanoseconds(staggerEnabled: feedbackPreferences.botStaggerEnabled)
        for dart in plannedDarts {
            do {
                try await Task.sleep(nanoseconds: dartDelay)
            } catch {
                return
            }
            enteredDarts.append(dart)
        }

        do {
            try await Task.sleep(nanoseconds: BotTurnPacing.submitDelayNanoseconds(staggerEnabled: feedbackPreferences.botStaggerEnabled))
        } catch {
            return
        }
        await submitTurnAsync()
    }

    /// Marks the match abandoned when the player leaves mid-match so it stops
    /// appearing as resumable. Completed matches are left untouched.
    func abandonMatch() async {
        await loadSessionIfNeeded()
        guard let current = session, current.runtime.status == .inProgress else { return }
        do {
            let abandoned = try MatchLifecycleService.abandon(session: current)
            try await matchRepository.updateMatch(matchSummary(from: abandoned.runtime))
            _ = try await matchRepository.saveSnapshot(
                matchId: matchId,
                snapshotVersion: abandoned.latestSnapshot.payloadVersion,
                snapshotPayload: abandoned.latestSnapshot.payload
            )
            store.remove(matchId: matchId)
            session = abandoned
            logger.matchInfo(
                matchId: matchId,
                matchType: .cricket,
                category: .appLifecycle,
                eventName: "match_abandoned",
                message: "Cricket match abandoned by user.",
                metadata: ["eventCount": String(abandoned.runtime.eventCount)]
            )
        } catch {
            logger.matchError(
                matchId: matchId,
                matchType: .cricket,
                category: .appLifecycle,
                eventName: "cricket_abandon_failed",
                message: "Abandon failed.",
                metadata: appErrorMetadata(for: error)
            )
        }
    }

    private func submitTurnAsync() async {
        await loadSessionIfNeeded()
        guard var current = session else {
            logger.matchError(
                matchId: matchId,
                matchType: .cricket,
                eventName: "match_session_missing",
                message: "Submit attempted without a loaded session."
            )
            state = .error("cricket.error.sessionMissing")
            return
        }
        state = .submittingTurn
        let wasHumanTurn = currentBotDifficulty == nil
        let submittedVisitTotal = enteredDarts.reduce(0) { $0 + $1.points }
        let throwingPlayerIndex = current.runtime.cricketState?.currentPlayerIndex
        let marksBeforeTurn = current.runtime.cricketState.flatMap { state in
            guard let index = throwingPlayerIndex else { return nil as [String: Int]? }
            return state.players[index].marks
        }
        do {
            do {
                current = try PerformanceMonitor.measure(
                    .submitTurn,
                    logger: logger,
                    metadata: ["matchType": MatchType.cricket.rawValue]
                ) {
                    try MatchLifecycleService.submitCricketTurn(session: current, darts: enteredDarts)
                }
            } catch is CancellationError {
                state = .readyTurn
                return
            } catch {
                logger.matchDebug(
                    matchId: matchId,
                    matchType: .cricket,
                    eventName: "turn_submit_rejected",
                    message: "Turn rejected by scoring engine.",
                    metadata: appErrorMetadata(for: error)
                )
                state = .entryInvalid(errorMessageKey(for: error, fallback: "cricket.error.invalidTurn"))
                return
            }
            do {
                try await persistProgress(current)
            } catch is CancellationError {
                state = .readyTurn
                return
            } catch {
                logger.matchError(
                    matchId: matchId,
                    matchType: .cricket,
                    category: .persistence,
                    eventName: "turn_persist_failed",
                    message: "Failed to persist submitted turn.",
                    metadata: appErrorMetadata(for: error)
                )
                state = .error(errorMessageKey(for: error, fallback: "error.repository.storage"))
                return
            }
            store.save(current)
            session = current
            logger.matchDebug(
                matchId: matchId,
                matchType: .cricket,
                eventName: "turn_submitted",
                message: "Turn accepted and persisted.",
                metadata: matchProgressMetadata(for: current)
            )
            if wasHumanTurn {
                turnTotalCallerToken += 1
                turnTotalCallerSignal = TurnTotalCallerSignal(token: turnTotalCallerToken, total: submittedVisitTotal)
            }
            if current.runtime.status == .completed {
                PerformanceMonitor.measure(
                    .completeMatch,
                    logger: logger,
                    metadata: ["matchType": MatchType.cricket.rawValue]
                ) {}
                logger.matchInfo(
                    matchId: matchId,
                    matchType: .cricket,
                    category: .appLifecycle,
                    eventName: "match_completed",
                    message: "Cricket match completed.",
                    metadata: matchProgressMetadata(for: current)
                )
                state = .matchCompleted
            } else {
                let didCloseTarget = Self.didCloseAnyCricketTarget(
                    before: marksBeforeTurn,
                    after: throwingPlayerIndex.flatMap { index in
                        current.runtime.cricketState?.players[index].marks
                    }
                )
                if didCloseTarget {
                    state = .closureTransition
                    try? await Task.sleep(nanoseconds: BotTurnPacing.cricketClosureTransitionNanoseconds)
                }
                state = .readyTurn
                if current.runtime.status != .completed {
                    await playBotTurnIfNeeded()
                }
            }
            enteredDarts.removeAll()
        }
    }

    private func undoLastTurnAsync() async {
        await loadSessionIfNeeded()
        guard let current = session else { return }
        do {
            let undone = try MatchLifecycleService.undoLastTurn(session: current)
            try await matchRepository.updateMatch(matchSummary(from: undone.runtime))
            _ = try await matchRepository.saveSnapshot(
                matchId: matchId,
                snapshotVersion: undone.latestSnapshot.payloadVersion,
                snapshotPayload: undone.latestSnapshot.payload
            )
            store.save(undone)
            session = undone
            state = .readyTurn
            enteredDarts.removeAll()
            logger.matchDebug(
                matchId: matchId,
                matchType: .cricket,
                eventName: "turn_undone",
                message: "Last turn undone.",
                metadata: matchProgressMetadata(for: undone)
            )
            await playBotTurnIfNeeded()
        } catch is CancellationError {
            state = .readyTurn
        } catch {
            logger.matchError(
                matchId: matchId,
                matchType: .cricket,
                eventName: "turn_undo_failed",
                message: "Undo failed.",
                metadata: appErrorMetadata(for: error)
            )
            state = .error(errorMessageKey(for: error, fallback: "cricket.error.undoFailed"))
        }
    }

    private func persistProgress(_ current: MatchLifecycleSession) async throws {
        if let event = current.events.last, event.eventIndex >= 0 {
            let payload = try CodablePayloadCoder.encode(event)
            _ = try await matchRepository.appendEvent(
                matchId: matchId,
                eventTypeRaw: "cricketTurn",
                eventPayload: payload
            )
        }
        _ = try await matchRepository.saveSnapshot(
            matchId: matchId,
            snapshotVersion: current.latestSnapshot.payloadVersion,
            snapshotPayload: current.latestSnapshot.payload
        )
        if current.runtime.status == .completed {
            _ = try await matchRepository.completeMatch(
                matchId: matchId,
                endedAt: current.runtime.endedAt ?? Date(),
                winnerPlayerId: current.runtime.winnerPlayerId
            )
        } else {
            try await matchRepository.updateMatch(matchSummary(from: current.runtime))
        }
    }

    private func matchSummary(from runtime: MatchRuntimeState) -> MatchSummary {
        MatchSummary(
            id: runtime.matchId,
            type: runtime.type,
            status: MatchStatus(rawValue: runtime.status.rawValue) ?? .inProgress,
            startedAt: runtime.startedAt,
            endedAt: runtime.endedAt,
            winnerPlayerId: runtime.winnerPlayerId,
            currentTurnPlayerId: runtime.currentTurnPlayerId,
            currentLegIndex: runtime.currentLegIndex,
            currentSetIndex: runtime.currentSetIndex,
            eventCount: runtime.eventCount,
            createdAt: runtime.startedAt,
            updatedAt: Date()
        )
    }

    private func loadSessionIfNeeded() async {
        if session != nil { return }
        if let existing = store.session(for: matchId) {
            session = existing
            logger.matchDebug(
                matchId: matchId,
                matchType: .cricket,
                eventName: "match_session_resumed_from_memory",
                message: "Loaded active match session from memory.",
                metadata: matchProgressMetadata(for: existing)
            )
            return
        }
        do {
            guard let snapshotSummary = try await matchRepository.fetchLatestSnapshot(matchId: matchId) else {
                return
            }
            let runtime = try CodablePayloadCoder.decode(MatchRuntimeState.self, from: snapshotSummary.snapshotPayload)
            let events = try await statsRepository.fetchEvents(matchId: matchId)
            let envelopes = try events
                .map { try CodablePayloadCoder.decode(MatchEventEnvelope.self, from: $0.eventPayload) }
                .sorted { $0.eventIndex < $1.eventIndex }
            let tailEvents = envelopes.filter { $0.eventIndex >= runtime.eventCount }
            let snapshot = MatchSnapshot(
                payloadVersion: snapshotSummary.snapshotVersion,
                eventCount: runtime.eventCount,
                createdAt: snapshotSummary.updatedAt,
                payload: snapshotSummary.snapshotPayload
            )
            let rehydrated = try MatchLifecycleService.rehydrate(snapshot: snapshot, tailEvents: tailEvents)
            store.save(rehydrated)
            session = rehydrated
            logger.matchInfo(
                matchId: matchId,
                matchType: .cricket,
                eventName: "match_session_rehydrated",
                message: "Rehydrated match session from snapshot.",
                metadata: [
                    "source": "snapshot",
                    "eventCount": String(rehydrated.runtime.eventCount)
                ]
            )
        } catch {
            logger.matchError(
                matchId: matchId,
                matchType: .cricket,
                eventName: "match_session_load_failed",
                message: "Failed to load match session.",
                metadata: appErrorMetadata(for: error)
            )
            state = .error(errorMessageKey(for: error, fallback: "cricket.error.sessionMissing"))
        }
    }

    private func matchProgressMetadata(for session: MatchLifecycleSession) -> [String: String] {
        [
            "eventCount": String(session.runtime.eventCount),
            "legIndex": String(session.runtime.currentLegIndex),
            "setIndex": String(session.runtime.currentSetIndex),
            "status": session.runtime.status.rawValue
        ]
    }

    private func appErrorMetadata(for error: Error) -> [String: String] {
        if let appError = error as? AppError {
            return [
                "errorCode": appError.code.rawValue,
                "layer": appError.layer.rawValue
            ]
        }
        return ["errorCode": "unknown"]
    }

    private func errorMessageKey(for error: Error, fallback: String) -> String {
        if let appError = error as? AppError {
            return appError.userMessageKey
        }
        return fallback
    }

    private static func didCloseAnyCricketTarget(before: [String: Int]?, after: [String: Int]?) -> Bool {
        guard let before, let after else { return false }
        return CricketTarget.allCases.contains { target in
            let key = target.rawValue
            let prior = before[key] ?? 0
            let next = after[key] ?? 0
            return prior < 3 && next >= 3
        }
    }
}
