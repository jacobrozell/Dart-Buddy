import Foundation

enum ScoringInputMode {
    case totalEntry
    case dartEntry
}

@MainActor
final class X01MatchViewModel: ObservableObject {
    enum State: Equatable {
        case readyTurn
        case entryInvalid(String)
        case submittingTurn
        case bustFeedback
        case matchCompleted
        case error(String)
    }

    @Published private(set) var state: State = .readyTurn
    @Published var inputMode: ScoringInputMode = .totalEntry
    @Published var selectedMultiplier: DartMultiplier = .single
    @Published var enteredDarts: [DartInput] = []
    @Published var totalEntryText = ""
    @Published private(set) var session: MatchLifecycleSession?
    @Published private(set) var isBotPlaying = false
    /// Increments on every leg checkout so the UI can play finish audio even when
    /// the match continues (e.g. best-of-3 legs).
    @Published private(set) var legFinishSoundToken = 0
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
            matchType: .x01,
            eventTypeRaw: "x01Turn",
            store: store,
            logger: logger,
            matchRepository: matchRepository
        )
        self.session = store.session(for: matchId)
    }

    var canSubmit: Bool {
        switch inputMode {
        case .totalEntry:
            guard let value = Int(totalEntryText) else { return false }
            return (0 ... 180).contains(value)
        case .dartEntry:
            return !enteredDarts.isEmpty
        }
    }

    // MARK: - Presentation

    struct PlayerCard: Identifiable {
        let id: UUID
        let name: String
        let score: Int
        let setsWon: Int
        let legsWon: Int
        let isActive: Bool
        let colorToken: PlayerColorToken
        let visitDarts: [DartInput]
        let dartsThrown: Int
        let average: Double
    }

    var x01State: X01State? { session?.runtime.x01State }

    var playerCards: [PlayerCard] {
        guard let session, let state = session.runtime.x01State else { return [] }
        let isInProgress = session.runtime.status == .inProgress
        let completedRoundVisits = currentRoundVisitDarts(session: session, state: state)
        return state.players.enumerated().map { index, player in
            let isActive = index == state.currentPlayerIndex && isInProgress
            let visitDarts = isActive
                ? enteredDarts
                : (completedRoundVisits[player.playerId] ?? [])
            let participant = participant(for: player.playerId)
            return PlayerCard(
                id: player.playerId,
                name: participant?.displayNameAtMatchStart ?? MatchConfigText.playerName(forIndex: index),
                score: previewRemainingScore(for: player, isActive: isActive),
                setsWon: player.setsWon,
                legsWon: player.legsWon,
                isActive: isActive,
                colorToken: participant?.colorToken ?? PlayerColorToken.defaultForPlayer(id: player.playerId),
                visitDarts: visitDarts,
                dartsThrown: previewDartsThrown(for: player.playerId, isActive: isActive),
                average: previewAverage(for: player.playerId, isActive: isActive)
            )
        }
    }

    /// Live remaining score while the active player is entering their visit.
    private func previewRemainingScore(for player: X01PlayerState, isActive: Bool) -> Int {
        guard isActive, canHumanInput || isBotPlaying else { return player.remainingScore }
        let visitTotal: Int
        switch inputMode {
        case .dartEntry:
            visitTotal = enteredDarts.reduce(0) { $0 + $1.points }
        case .totalEntry:
            visitTotal = Int(totalEntryText) ?? 0
        }
        return player.remainingScore - visitTotal
    }

    /// Checkout route for the active player, shown only when a turn is armed and
    /// the match is still in progress.
    var checkoutRoute: [String]? {
        guard state == .readyTurn,
              isBotPlaying == false,
              let x01State = session?.runtime.x01State,
              x01State.winnerPlayerId == nil else { return nil }
        let player = x01State.players[x01State.currentPlayerIndex]
        let dartsLeft = max(1, 3 - enteredDarts.count)
        let previewRemaining = previewRemainingScore(for: player, isActive: true)
        return CheckoutSuggester.suggestion(
            remaining: previewRemaining,
            mode: x01State.config.checkoutMode,
            dartsAvailable: dartsLeft
        )
    }

    var configSummary: String? {
        guard let config = session?.runtime.x01State?.config else { return nil }
        return MatchConfigText.x01InlineConfig(from: config)
    }

    var isCurrentPlayerBot: Bool {
        currentBotDifficulty != nil
    }

    var canHumanInput: Bool {
        guard isCurrentPlayerBot == false, isBotPlaying == false else { return false }
        // Opponent bust feedback must not freeze the pad; the screen dismisses the
        // banner when the active human starts their visit.
        return state == .readyTurn || state == .bustFeedback
    }

    var currentBotDifficulty: BotDifficulty? {
        guard let session, let x01State = session.runtime.x01State else { return nil }
        guard session.runtime.status == .inProgress else { return nil }
        let player = x01State.players[x01State.currentPlayerIndex]
        return DartBotEngine.botDifficulty(
            playerId: player.playerId,
            in: session.runtime.participants
        )
    }

    private func participant(for playerId: UUID) -> MatchParticipant? {
        session?.runtime.participants.first { ($0.playerId ?? $0.id) == playerId }
    }

    /// Completed visits in the current scoring round (one full rotation through
    /// `state.players`), derived from turn events for the active leg/set.
    private func currentRoundVisitDarts(
        session: MatchLifecycleSession,
        state: X01State
    ) -> [UUID: [DartInput]] {
        guard state.currentPlayerIndex > 0 else { return [:] }

        let legEvents: [X01TurnEvent] = session.events.compactMap { envelope in
            guard case let .x01Turn(event) = envelope.payload,
                  event.legIndex == state.legIndex,
                  event.setIndex == state.setIndex else { return nil }
            return event
        }

        guard legEvents.count >= state.currentPlayerIndex else { return [:] }

        let recentEvents = Array(legEvents.suffix(state.currentPlayerIndex))
        var visits: [UUID: [DartInput]] = [:]
        for (index, event) in recentEvents.enumerated() {
            guard state.players[index].playerId == event.playerId else { return [:] }
            visits[event.playerId] = event.reconstructedDarts
        }
        return visits
    }

    private func turnEvents(for playerId: UUID) -> [X01TurnEvent] {
        guard let session else { return [] }
        return session.events.compactMap { envelope in
            if case let .x01Turn(event) = envelope.payload, event.playerId == playerId {
                return event
            }
            return nil
        }
    }

    private func dartsThrown(for playerId: UUID) -> Int {
        turnEvents(for: playerId).reduce(0) { $0 + max($1.effectiveDartsThrown, 0) }
    }

    /// In-progress visit dart count and points for the active player.
    private func previewVisitStats(isActive: Bool) -> (darts: Int, points: Int) {
        guard isActive, canHumanInput || isBotPlaying else { return (0, 0) }
        switch inputMode {
        case .dartEntry:
            return (enteredDarts.count, enteredDarts.reduce(0) { $0 + $1.points })
        case .totalEntry:
            guard let value = Int(totalEntryText), (0 ... 180).contains(value) else { return (0, 0) }
            return (3, value)
        }
    }

    private func previewDartsThrown(for playerId: UUID, isActive: Bool) -> Int {
        dartsThrown(for: playerId) + previewVisitStats(isActive: isActive).darts
    }

    private func previewAverage(for playerId: UUID, isActive: Bool) -> Double {
        let events = turnEvents(for: playerId)
        let committedDarts = events.reduce(0) { $0 + max($1.effectiveDartsThrown, 0) }
        let committedPoints = events.reduce(0) { $0 + $1.appliedTotal }
        let visit = previewVisitStats(isActive: isActive)
        let darts = committedDarts + visit.darts
        guard darts > 0 else { return 0 }
        return Double(committedPoints + visit.points) / Double(darts) * 3.0
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
            matchType: .x01,
            category: .ui,
            eventName: "match_screen_appeared",
            message: "X01 match screen presented."
        )
        await loadSessionIfNeeded()
        reconcileInterruptedBotPlayback()
        await playBotTurnIfNeeded()
    }

    /// Clears transient bot UI when the screen reappears after a cancelled bot task
    /// (e.g. tab switch or save-and-exit while the bot was throwing).
    private func reconcileInterruptedBotPlayback() {
        isBotPlaying = false
        enteredDarts.removeAll()
        totalEntryText = ""
        if state == .submittingTurn {
            state = .readyTurn
        }
    }

    /// Generates and submits a bot visit when it is the bot's turn.
    func playBotTurnIfNeeded() async {
        guard let difficulty = currentBotDifficulty,
              state == .readyTurn || state == .bustFeedback,
              isBotPlaying == false,
              let x01State = session?.runtime.x01State else { return }

        if state == .bustFeedback { acknowledgeBustFeedback() }
        isBotPlaying = true
        defer { isBotPlaying = false }
        logger.matchDebug(
            matchId: matchId,
            matchType: .x01,
            eventName: "bot_turn_started",
            message: "Bot visit generation started."
        )

        enteredDarts.removeAll()
        totalEntryText = ""

        let player = x01State.players[x01State.currentPlayerIndex]
        var rng = SystemRandomNumberGenerator()
        let plannedDarts = DartBotEngine.generateX01Turn(
            remaining: player.remainingScore,
            difficulty: difficulty,
            checkoutMode: x01State.config.checkoutMode,
            checkInMode: x01State.config.checkInMode,
            isCheckedIn: player.isCheckedIn,
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
                matchType: .x01,
                category: .appLifecycle,
                eventName: "match_abandoned",
                message: "X01 match abandoned by user.",
                metadata: ["eventCount": String(abandoned.runtime.eventCount)]
            )
        } catch {
            logger.matchError(
                matchId: matchId,
                matchType: .x01,
                category: .appLifecycle,
                eventName: "x01_abandon_failed",
                message: "Abandon failed.",
                metadata: MatchTurnSupport.appErrorMetadata(for: error)
            )
        }
    }

    /// Clears the transient bust banner so the next visit can be scored.
    /// `bustFeedback` is shown after a busted turn; without acknowledging it the
    /// auto-submit guard would otherwise stay blocked and stall the match.
    func acknowledgeBustFeedback() {
        if state == .bustFeedback { state = .readyTurn }
    }

    private func submitTurnAsync() async {
        await loadSessionIfNeeded()
        guard let current = session else {
            logger.matchError(
                matchId: matchId,
                matchType: .x01,
                eventName: "match_session_missing",
                message: "Submit attempted without a loaded session."
            )
            state = .error("x01.error.sessionMissing")
            return
        }
        state = .submittingTurn
        let wasHumanTurn = currentBotDifficulty == nil
        let total = inputMode == .totalEntry ? Int(totalEntryText) : nil
        let darts = inputMode == .dartEntry ? enteredDarts : nil

        let outcome = await turnSubmitter.submitTurn(
            from: current,
            invalidTurnFallbackKey: "x01.error.invalidTurn"
        ) {
            try MatchLifecycleService.submitX01Turn(
                session: current,
                enteredTotal: total,
                darts: darts
            )
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
            if wasHumanTurn, case let .x01Turn(event) = updated.events.last?.payload {
                turnTotalCallerToken += 1
                turnTotalCallerSignal = TurnTotalCallerSignal(token: turnTotalCallerToken, total: event.appliedTotal)
            }
            if case let .x01Turn(event) = updated.events.last?.payload,
               event.didCheckout,
               updated.runtime.status != .completed {
                legFinishSoundToken += 1
            }
            if updated.runtime.status == .completed {
                PerformanceMonitor.measure(
                    .completeMatch,
                    logger: logger,
                    metadata: ["matchType": MatchType.x01.rawValue]
                ) {}
                logger.matchInfo(
                    matchId: matchId,
                    matchType: .x01,
                    category: .appLifecycle,
                    eventName: "match_completed",
                    message: "X01 match completed.",
                    metadata: MatchTurnSupport.matchProgressMetadata(for: updated)
                )
                state = .matchCompleted
            } else if case let .x01Turn(event) = updated.events.last?.payload, event.isBust {
                logger.matchDebug(
                    matchId: matchId,
                    matchType: .x01,
                    eventName: "turn_bust",
                    message: "Visit busted.",
                    metadata: MatchTurnSupport.matchProgressMetadata(for: updated)
                )
                state = .bustFeedback
            } else {
                state = .readyTurn
            }
            enteredDarts.removeAll()
            totalEntryText = ""
            if updated.runtime.status != .completed {
                await playBotTurnIfNeeded()
            }
        }
    }

    private func undoLastTurnAsync() async {
        await loadSessionIfNeeded()
        guard let current = session else { return }
        do {
            let undone = try MatchLifecycleService.undoLastTurn(session: current)
            try await matchRepository.updateMatch(MatchTurnSupport.matchSummary(from: undone.runtime))
            _ = try await matchRepository.saveSnapshot(
                matchId: matchId,
                snapshotVersion: undone.latestSnapshot.payloadVersion,
                snapshotPayload: undone.latestSnapshot.payload
            )
            store.save(undone)
            session = undone
            state = .readyTurn
            enteredDarts.removeAll()
            totalEntryText = ""
            logger.matchDebug(
                matchId: matchId,
                matchType: .x01,
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
                matchType: .x01,
                eventName: "turn_undo_failed",
                message: "Undo failed.",
                metadata: MatchTurnSupport.appErrorMetadata(for: error)
            )
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "x01.error.undoFailed"))
        }
    }

    private func undoLastDartAsync() async {
        await loadSessionIfNeeded()
        guard let current = session else { return }
        do {
            let result = try MatchLifecycleService.undoLastDart(session: current)
            try await matchRepository.updateMatch(MatchTurnSupport.matchSummary(from: result.session.runtime))
            _ = try await matchRepository.saveSnapshot(
                matchId: matchId,
                snapshotVersion: result.session.latestSnapshot.payloadVersion,
                snapshotPayload: result.session.latestSnapshot.payload
            )
            store.save(result.session)
            session = result.session
            state = .readyTurn
            enteredDarts = result.restoredDarts
            totalEntryText = ""
            logger.matchDebug(
                matchId: matchId,
                matchType: .x01,
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
                matchType: .x01,
                eventName: "turn_undo_failed",
                message: "Undo failed.",
                metadata: MatchTurnSupport.appErrorMetadata(for: error)
            )
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "x01.error.undoFailed"))
        }
    }

    private func loadSessionIfNeeded() async {
        if session != nil { return }
        if let existing = store.session(for: matchId) {
            session = existing
            logger.matchDebug(
                matchId: matchId,
                matchType: .x01,
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
                matchType: .x01,
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
                matchType: .x01,
                eventName: "match_session_load_failed",
                message: "Failed to load match session.",
                metadata: MatchTurnSupport.appErrorMetadata(for: error)
            )
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "x01.error.sessionMissing"))
        }
    }

}
