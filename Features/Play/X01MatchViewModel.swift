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

    init(
        matchId: UUID,
        store: ActiveMatchStore,
        logger: any AppLogger,
        matchRepository: any MatchRepository,
        statsRepository: any StatsRepository
    ) {
        self.matchId = matchId
        self.store = store
        self.logger = logger
        self.matchRepository = matchRepository
        self.statsRepository = statsRepository
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
        let visitDarts: [DartInput]
        let dartsThrown: Int
        let average: Double
    }

    var x01State: X01State? { session?.runtime.x01State }

    var playerCards: [PlayerCard] {
        guard let session, let state = session.runtime.x01State else { return [] }
        let isInProgress = session.runtime.status == .inProgress
        return state.players.enumerated().map { index, player in
            let isActive = index == state.currentPlayerIndex && isInProgress
            return PlayerCard(
                id: player.playerId,
                name: name(for: player.playerId, fallbackIndex: index),
                score: previewRemainingScore(for: player, isActive: isActive),
                setsWon: player.setsWon,
                legsWon: player.legsWon,
                isActive: isActive,
                visitDarts: index == state.currentPlayerIndex ? enteredDarts : [],
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
        isCurrentPlayerBot == false && isBotPlaying == false && state == .readyTurn
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

    private func name(for playerId: UUID, fallbackIndex: Int) -> String {
        let participant = session?.runtime.participants.first { ($0.playerId ?? $0.id) == playerId }
        return participant?.displayNameAtMatchStart ?? MatchConfigText.playerName(forIndex: fallbackIndex)
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

    func onAppear() async {
        await loadSessionIfNeeded()
        await playBotTurnIfNeeded()
    }

    /// Generates and submits a bot visit when it is the bot's turn.
    func playBotTurnIfNeeded() async {
        guard let difficulty = currentBotDifficulty,
              state == .readyTurn || state == .bustFeedback,
              isBotPlaying == false,
              let x01State = session?.runtime.x01State else { return }

        if state == .bustFeedback { acknowledgeBustFeedback() }
        isBotPlaying = true

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

        for dart in plannedDarts {
            try? await Task.sleep(nanoseconds: 650_000_000)
            enteredDarts.append(dart)
        }

        try? await Task.sleep(nanoseconds: 350_000_000)
        isBotPlaying = false
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
        } catch {
            logger.error(.appLifecycle, eventName: "x01_abandon_failed", message: "Abandon failed: \(error)")
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
        guard var current = session else {
            state = .error("x01.error.sessionMissing")
            return
        }
        state = .submittingTurn
        let wasHumanTurn = currentBotDifficulty == nil
        do {
            let total = inputMode == .totalEntry ? Int(totalEntryText) : nil
            let darts = inputMode == .dartEntry ? enteredDarts : nil
            do {
                current = try PerformanceMonitor.measure(
                    .submitTurn,
                    logger: logger,
                    metadata: ["matchType": MatchType.x01.rawValue]
                ) {
                    try MatchLifecycleService.submitX01Turn(
                        session: current,
                        enteredTotal: total,
                        darts: darts
                    )
                }
            } catch is CancellationError {
                state = .readyTurn
                return
            } catch {
                state = .entryInvalid(errorMessageKey(for: error, fallback: "x01.error.invalidTurn"))
                return
            }
            do {
                try await persistProgress(current)
            } catch is CancellationError {
                state = .readyTurn
                return
            } catch {
                state = .error(errorMessageKey(for: error, fallback: "error.repository.storage"))
                return
            }
            store.save(current)
            session = current
            if wasHumanTurn, case let .x01Turn(event) = current.events.last?.payload {
                turnTotalCallerToken += 1
                turnTotalCallerSignal = TurnTotalCallerSignal(token: turnTotalCallerToken, total: event.appliedTotal)
            }
            if case let .x01Turn(event) = current.events.last?.payload,
               event.didCheckout,
               current.runtime.status != .completed {
                legFinishSoundToken += 1
            }
            if current.runtime.status == .completed {
                PerformanceMonitor.measure(
                    .completeMatch,
                    logger: logger,
                    metadata: ["matchType": MatchType.x01.rawValue]
                ) {}
                state = .matchCompleted
            } else if case let .x01Turn(event) = current.events.last?.payload, event.isBust {
                state = .bustFeedback
            } else {
                state = .readyTurn
            }
            enteredDarts.removeAll()
            totalEntryText = ""
            if current.runtime.status != .completed {
                await playBotTurnIfNeeded()
            }
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
            totalEntryText = ""
        } catch is CancellationError {
            state = .readyTurn
        } catch {
            state = .error(errorMessageKey(for: error, fallback: "x01.error.undoFailed"))
        }
    }

    private func persistProgress(_ current: MatchLifecycleSession) async throws {
        if let event = current.events.last, event.eventIndex >= 0 {
            let payload = try CodablePayloadCoder.encode(event)
            _ = try await matchRepository.appendEvent(
                matchId: matchId,
                eventTypeRaw: "x01Turn",
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
        } catch {
            state = .error(errorMessageKey(for: error, fallback: "x01.error.sessionMissing"))
        }
    }

    private func errorMessageKey(for error: Error, fallback: String) -> String {
        if let appError = error as? AppError {
            return appError.userMessageKey
        }
        return fallback
    }
}
