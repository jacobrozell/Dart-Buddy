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
        self.feedbackPreferences = feedbackPreferences
        self.turnSubmitter = MatchTurnSubmitter(
            matchId: matchId,
            matchType: .cricket,
            eventTypeRaw: "cricketTurn",
            store: store,
            logger: logger,
            matchRepository: matchRepository
        )
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
            let participant = participant(for: player.playerId)
            return CricketBoardView.Column(
                id: player.playerId,
                name: participant?.displayNameAtMatchStart ?? MatchConfigText.playerName(forIndex: index),
                score: player.score,
                marks: player.marks,
                isActive: index == state.currentPlayerIndex && isInProgress,
                colorToken: participant?.colorToken ?? PlayerColorToken.defaultForPlayer(id: player.playerId),
                isClosureHighlight: highlightClosure && index == state.currentPlayerIndex
            )
        }
    }

    private func participant(for playerId: UUID) -> MatchParticipant? {
        session?.runtime.participants.first { ($0.playerId ?? $0.id) == playerId }
    }

    func submitTurn() async {
        await submitTurnAsync()
    }

    func undoLastTurn() async {
        await undoLastTurnAsync()
    }

    func undoLastDart() async {
        await undoLastDartAsync()
    }

    func onAppear() async {
        logger.matchDebug(
            matchId: matchId,
            matchType: .cricket,
            category: .ui,
            eventName: "match_screen_appeared",
            message: "Cricket match screen presented."
        )
        if await reconcileAfterSummaryUndo() { return }
        await loadSessionIfNeeded()
        reconcileInterruptedBotPlayback()
        await playBotTurnIfNeeded()
    }

    /// Restores play after the user undoes the finishing throw from the match summary.
    private func reconcileAfterSummaryUndo() async -> Bool {
        guard state == .matchCompleted,
              let stored = store.session(for: matchId),
              stored.runtime.status == .inProgress else { return false }
        session = stored
        state = .readyTurn
        enteredDarts = store.consumeResumeHint(matchId: matchId) ?? []
        isBotPlaying = false
        if enteredDarts.isEmpty {
            await playBotTurnIfNeeded()
        }
        return true
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
            try await matchRepository.updateMatch(MatchTurnSupport.matchSummary(from: abandoned.runtime))
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
                metadata: MatchTurnSupport.appErrorMetadata(for: error)
            )
        }
    }

    private func submitTurnAsync() async {
        await loadSessionIfNeeded()
        guard let current = session else {
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
        let darts = enteredDarts

        let outcome = await turnSubmitter.submitTurn(
            from: current,
            invalidTurnFallbackKey: "cricket.error.invalidTurn"
        ) {
            try MatchLifecycleService.submitCricketTurn(session: current, darts: darts)
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
            if wasHumanTurn {
                turnTotalCallerToken += 1
                turnTotalCallerSignal = TurnTotalCallerSignal(token: turnTotalCallerToken, total: submittedVisitTotal)
            }
            if updated.runtime.status == .completed {
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
                    metadata: MatchTurnSupport.matchProgressMetadata(for: updated)
                )
                state = .matchCompleted
            } else {
                let didCloseTarget = Self.didCloseAnyCricketTarget(
                    before: marksBeforeTurn,
                    after: throwingPlayerIndex.flatMap { index in
                        updated.runtime.cricketState?.players[index].marks
                    }
                )
                if didCloseTarget {
                    state = .closureTransition
                    try? await Task.sleep(nanoseconds: BotTurnPacing.cricketClosureTransitionNanoseconds)
                }
                state = .readyTurn
                if updated.runtime.status != .completed {
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
            let undone = try await MatchTurnSupport.undoLastTurn(
                session: current,
                matchId: matchId,
                store: store,
                matchRepository: matchRepository
            )
            session = undone
            state = .readyTurn
            enteredDarts.removeAll()
            logger.matchDebug(
                matchId: matchId,
                matchType: .cricket,
                eventName: "turn_undone",
                message: "Last turn undone.",
                metadata: MatchTurnSupport.matchProgressMetadata(for: undone)
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
                metadata: MatchTurnSupport.appErrorMetadata(for: error)
            )
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "cricket.error.undoFailed"))
        }
    }

    private func undoLastDartAsync() async {
        await loadSessionIfNeeded()
        guard let current = session else { return }
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
            logger.matchDebug(
                matchId: matchId,
                matchType: .cricket,
                eventName: "dart_undone",
                message: "Last throw undone.",
                metadata: MatchTurnSupport.matchProgressMetadata(for: result.session)
            )
            if result.restoredDarts.isEmpty {
                await playBotTurnIfNeeded()
            }
        } catch is CancellationError {
            state = .readyTurn
        } catch {
            logger.matchError(
                matchId: matchId,
                matchType: .cricket,
                eventName: "turn_undo_failed",
                message: "Undo failed.",
                metadata: MatchTurnSupport.appErrorMetadata(for: error)
            )
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "cricket.error.undoFailed"))
        }
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
                metadata: MatchTurnSupport.matchProgressMetadata(for: existing)
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
                metadata: MatchTurnSupport.appErrorMetadata(for: error)
            )
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "cricket.error.sessionMissing"))
        }
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
