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
    @Published var session: MatchLifecycleSession?
    @Published private(set) var isBotPlaying = false
    /// Increments on every leg checkout so the UI can play finish audio even when
    /// the match continues (e.g. best-of-3 legs).
    @Published private(set) var legFinishSoundToken = 0
    /// Fires after a visit is accepted so the UI can announce the visit total.
    @Published private(set) var turnTotalCallerSignal: TurnTotalCallerSignal?

    private var turnTotalCallerToken = 0

    let matchId: UUID
    private let store: ActiveMatchStore
    private let logger: any AppLogger
    private let matchRepository: any MatchRepository
    private let statsRepository: any StatsRepository
    private let feedbackPreferences: FeedbackPreferences
    private let turnSubmitter: MatchTurnSubmitter
    private let botPlayback = MatchBotPlaybackLifecycle()

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
        guard MatchVisitPreview.includesActiveVisit(
            isActive: isActive,
            canHumanInput: canHumanInput,
            isBotPlaying: isBotPlaying,
            isCurrentPlayerBot: isCurrentPlayerBot
        ) else { return player.remainingScore }
        let visitTotal: Int
        switch inputMode {
        case .dartEntry:
            visitTotal = enteredDarts.reduce(0) { $0 + $1.points }
        case .totalEntry:
            visitTotal = Int(totalEntryText) ?? 0
        }
        return player.remainingScore - visitTotal
    }

    /// Checkout route for the active player, shown while a turn is armed and the
    /// match is still in progress. `bustFeedback` is included because a busted visit
    /// advances play to the next player — that player is already up and may be on a
    /// checkout, so their suggestion must show before they throw (the bust banner
    /// clears itself when they start scoring).
    var checkoutRoute: [String]? {
        checkoutRoutes.first
    }

    /// Every fewest-dart checkout route for the active player (preferred route first).
    var checkoutRoutes: [[String]] {
        guard let context = activeCheckoutContext else { return [] }
        return CheckoutSuggester.allSuggestions(
            remaining: context.remaining,
            mode: context.mode,
            dartsAvailable: context.dartsLeft
        )
    }

    private var activeCheckoutContext: (remaining: Int, mode: X01CheckoutMode, dartsLeft: Int)? {
        guard state == .readyTurn || state == .bustFeedback,
              isBotPlaying == false,
              isCurrentPlayerBot == false,
              let x01State = session?.runtime.x01State,
              x01State.winnerPlayerId == nil else { return nil }
        let player = x01State.players[x01State.currentPlayerIndex]
        let dartsLeft = max(1, 3 - enteredDarts.count)
        let previewRemaining = previewRemainingScore(for: player, isActive: true)
        return (previewRemaining, x01State.config.checkoutMode, dartsLeft)
    }

    var configSummary: String? {
        guard let config = session?.runtime.x01State?.config else { return nil }
        return MatchConfigText.x01InlineConfig(from: config)
    }

    var isCurrentPlayerBot: Bool {
        currentBotSkillProfile != nil
    }

    var canHumanInput: Bool {
        guard isCurrentPlayerBot == false, isBotPlaying == false else { return false }
        // Opponent bust feedback must not freeze the pad; the screen dismisses the
        // banner when the active human starts their visit.
        return state == .readyTurn || state == .bustFeedback
    }

    var currentBotSkillProfile: BotSkillProfile? {
        guard let session, let x01State = session.runtime.x01State else { return nil }
        guard session.runtime.status == .inProgress else { return nil }
        let player = x01State.players[x01State.currentPlayerIndex]
        return DartBotEngine.botSkillProfile(
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
        guard MatchVisitPreview.includesActiveVisit(
            isActive: isActive,
            canHumanInput: canHumanInput,
            isBotPlaying: isBotPlaying,
            isCurrentPlayerBot: isCurrentPlayerBot
        ) else { return (0, 0) }
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
        return StatsService.x01LiveScorecardAverage(
            committedPoints: committedPoints,
            committedDarts: committedDarts,
            previewPoints: visit.points,
            previewDarts: visit.darts
        )
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
        MatchGameplaySessionSync.refreshStoredSession(matchId: matchId, store: store, into: &session)
        if await reconcileAfterSummaryUndo() { return }
        await loadSessionIfNeeded()
        reconcileInterruptedBotPlayback()
        scheduleBotPlaybackIfNeeded()
    }

    func onDisappear() {
        botPlayback.cancel { reconcileInterruptedBotPlayback() }
    }

    func recoverBotPlaybackIfNeeded() {
        MatchBotPlaybackRecovery.recoverIfNeeded(
            isBotTurn: isCurrentPlayerBot,
            isBotPlaying: isBotPlaying,
            reconcile: reconcileInterruptedBotPlayback,
            schedule: scheduleBotPlaybackIfNeeded
        )
    }

    private func scheduleBotPlaybackIfNeeded() {
        botPlayback.schedule { await self.playBotTurnIfNeeded() }
    }

    /// Restores play after the user undoes the finishing throw from the match summary.
    private func reconcileAfterSummaryUndo() async -> Bool {
        guard state == .matchCompleted,
              let stored = store.session(for: matchId),
              stored.runtime.status == .inProgress else { return false }
        session = stored
        state = .readyTurn
        enteredDarts = store.consumeResumeHint(matchId: matchId) ?? []
        totalEntryText = ""
        isBotPlaying = false
        if currentBotSkillProfile != nil {
            enteredDarts.removeAll()
        }
        if enteredDarts.isEmpty {
            scheduleBotPlaybackIfNeeded()
        }
        return true
    }

    /// Clears transient bot UI when the screen reappears after a cancelled bot task
    /// (e.g. tab switch or save-and-exit while the bot was throwing).
    private func reconcileInterruptedBotPlayback() {
        isBotPlaying = false
        enteredDarts.removeAll()
        totalEntryText = ""
        selectedMultiplier = .single
        guard session?.runtime.status == .inProgress else { return }
        switch state {
        case .submittingTurn, .entryInvalid, .error, .matchCompleted:
            state = .readyTurn
        default:
            break
        }
    }

    /// Generates and submits bot visits for every consecutive bot in the rotation.
    func playBotTurnIfNeeded() async {
        while await playSingleBotTurnIfNeeded() {}
    }

    /// Plays one bot visit. Returns whether another bot may still be up in the same chain.
    @discardableResult
    private func playSingleBotTurnIfNeeded() async -> Bool {
        guard let profile = currentBotSkillProfile,
              state == .readyTurn || state == .bustFeedback,
              isBotPlaying == false,
              let x01State = session?.runtime.x01State else { return false }

        if state == .bustFeedback { acknowledgeBustFeedback() }
        isBotPlaying = true
        defer { isBotPlaying = false }
        logger.matchDebug(
            matchId: matchId,
            matchType: .x01,
            eventName: "bot_turn_started",
            message: "Bot visit generation started."
        )

        let partialVisitCount = enteredDarts.count
        if partialVisitCount == 0 {
            enteredDarts.removeAll()
            totalEntryText = ""
        }

        let player = x01State.players[x01State.currentPlayerIndex]
        var rng = SystemRandomNumberGenerator()
        let plannedDarts = DartBotEngine.generateX01Turn(
            remaining: player.remainingScore,
            profile: profile,
            checkoutMode: x01State.config.checkoutMode,
            checkInMode: x01State.config.checkInMode,
            isCheckedIn: player.isCheckedIn,
            rng: &rng
        )
        let dartsToReveal = BotVisitPlayback.remainingPlannedDarts(
            fullPlan: plannedDarts,
            existingCount: partialVisitCount
        )

        guard await BotVisitPlayback.revealVisit(
            dartsToReveal,
            feedbackPreferences: feedbackPreferences,
            append: { enteredDarts.append($0) }
        ) else { return false }
        await submitTurnAsync(fromBotPlayback: true)
        guard session?.runtime.status != .completed else { return false }
        return currentBotSkillProfile != nil && (state == .readyTurn || state == .bustFeedback)
    }

    /// Marks the match abandoned when the player leaves mid-match so it stops
    /// appearing as resumable. Completed matches are left untouched.
    // Shared implementation: `MatchPlaySessionHost.abandonMatch()`.

    /// Clears the transient bust banner so the next visit can be scored.
    /// `bustFeedback` is shown after a busted turn; without acknowledging it the
    /// auto-submit guard would otherwise stay blocked and stall the match.
    func acknowledgeBustFeedback() {
        if state == .bustFeedback { state = .readyTurn }
    }

    private func submitTurnAsync(fromBotPlayback: Bool = false) async {
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
            if case let .x01Turn(event) = updated.events.last?.payload {
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
            if updated.runtime.status != .completed, !fromBotPlayback {
                scheduleBotPlaybackIfNeeded()
            }
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
            totalEntryText = ""
            logger.matchDebug(
                matchId: matchId,
                matchType: .x01,
                eventName: "turn_undone",
                message: "Last turn undone.",
                metadata: MatchTurnSupport.matchProgressMetadata(for: undone)
            )
            scheduleBotPlaybackIfNeeded()
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
        if !enteredDarts.isEmpty {
            enteredDarts.removeLast()
            selectedMultiplier = .single
            logger.matchDebug(
                matchId: matchId,
                matchType: .x01,
                eventName: "dart_undone",
                message: "In-progress throw undone.",
                metadata: MatchTurnSupport.matchProgressMetadata(for: current)
            )
            resumeBotPlaybackAfterUndoIfNeeded()
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
            totalEntryText = ""
            logger.matchDebug(
                matchId: matchId,
                matchType: .x01,
                eventName: "dart_undone",
                message: "Last throw undone.",
                metadata: MatchTurnSupport.matchProgressMetadata(for: result.session)
            )
            resumeBotPlaybackAfterUndoIfNeeded()
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

    private func resumeBotPlaybackAfterUndoIfNeeded() {
        MatchBotUndoSupport.resumeAfterDartUndo(
            isBotTurn: isCurrentPlayerBot,
            partialVisitCount: enteredDarts.count,
            isBotPlaying: &isBotPlaying,
            reconcileSubmittingTurn: {
                if case .submittingTurn = state { state = .readyTurn }
            },
            botPlayback: botPlayback,
            schedule: scheduleBotPlaybackIfNeeded
        )
    }

    func loadSessionIfNeeded() async {
        if session != nil { return }
        switch await MatchSessionLoader.load(
            matchId: matchId,
            matchType: .x01,
            store: store,
            logger: logger,
            matchRepository: matchRepository,
            statsRepository: statsRepository,
            sessionMissingFallbackKey: "x01.error.sessionMissing"
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

extension X01MatchViewModel: MatchPlaySessionHost {
    var isBotTurnBlocking: Bool { isBotPlaying || state == .submittingTurn }
    var hostMatchRepository: any MatchRepository { matchRepository }
    var hostMatchStore: ActiveMatchStore { store }
    var hostMatchLogger: any AppLogger { logger }
    var hostMatchType: MatchType { .x01 }
}
