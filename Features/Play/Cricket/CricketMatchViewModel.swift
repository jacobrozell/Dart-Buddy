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
    @Published var session: MatchLifecycleSession?
    @Published private(set) var isBotPlaying = false
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
        currentBotSkillProfile != nil
    }

    var canHumanInput: Bool {
        isCurrentPlayerBot == false && isBotPlaying == false && state == .readyTurn
    }

    var currentBotSkillProfile: BotSkillProfile? {
        guard let session, let cricketState = session.runtime.cricketState else { return nil }
        guard session.runtime.status == .inProgress else { return nil }
        let player = cricketState.players[cricketState.currentPlayerIndex]
        return DartBotEngine.botSkillProfile(
            playerId: player.playerId,
            in: session.runtime.participants
        )
    }

    // MARK: - Presentation

    var cricketState: CricketState? { session?.runtime.cricketState }

    var matchSubtitle: String? {
        guard let config = session?.runtime.cricketState?.config else { return nil }
        return MatchConfigText.cricketMatchSubtitle(from: config)
    }

    var activeBoardColumnID: UUID? {
        boardColumns.first(where: \.isActive)?.id
    }

    var boardColumns: [CricketBoardView.Column] {
        guard let session, let state = session.runtime.cricketState else { return [] }
        let isInProgress = session.runtime.status == .inProgress
        let highlightClosure = self.state == .closureTransition
        let config = state.config
        return state.players.enumerated().map { index, player in
            let participant = session.runtime.participant(for: player.playerId)
            let isActive = index == state.currentPlayerIndex && isInProgress
            return CricketBoardView.Column(
                id: player.playerId,
                name: participant?.displayNameAtMatchStart ?? MatchConfigText.playerName(forIndex: index),
                score: player.score,
                marks: player.marks,
                isActive: isActive,
                colorToken: participant?.colorToken ?? PlayerColorToken.defaultForPlayer(id: player.playerId),
                dartsThrown: previewDartsThrown(for: player.playerId, isActive: isActive),
                marksPerRound: previewMarksPerRound(for: player.playerId, isActive: isActive),
                setsWon: player.setsWon,
                setsEnabled: config.setsEnabled,
                isClosureHighlight: highlightClosure && index == state.currentPlayerIndex
            )
        }
    }

    private func cricketTurnEvents(for playerId: UUID) -> [CricketTurnEvent] {
        guard let session else { return [] }
        return session.events.compactMap { envelope in
            if case let .cricketTurn(event) = envelope.payload, event.playerId == playerId {
                return event
            }
            return nil
        }
    }

    private func dartsThrown(for playerId: UUID) -> Int {
        StatsService.cricketDartsThrown(from: cricketTurnEvents(for: playerId))
    }

    private func previewVisitDarts(isActive: Bool) -> Int {
        guard MatchVisitPreview.includesActiveVisit(
            isActive: isActive,
            canHumanInput: canHumanInput,
            isBotPlaying: isBotPlaying,
            isCurrentPlayerBot: isCurrentPlayerBot
        ) else { return 0 }
        return enteredDarts.count
    }

    private func previewDartsThrown(for playerId: UUID, isActive: Bool) -> Int {
        dartsThrown(for: playerId) + previewVisitDarts(isActive: isActive)
    }

    private func committedMarks(for playerId: UUID) -> Int {
        cricketTurnEvents(for: playerId).reduce(0) { sum, event in
            sum + event.targetsTouched.reduce(0) { $0 + $1.marksAdded }
        }
    }

    private func previewVisitMarks(isActive: Bool) -> Int {
        guard MatchVisitPreview.includesActiveVisit(
            isActive: isActive,
            canHumanInput: canHumanInput,
            isBotPlaying: isBotPlaying,
            isCurrentPlayerBot: isCurrentPlayerBot
        ) else { return 0 }
        guard let state = cricketState else { return 0 }
        let playerIndex = state.currentPlayerIndex
        let before = state.players[playerIndex].marks
        var preview = state
        preview.players[playerIndex].marks = before
        for dart in enteredDarts {
            guard let raw = dart.segment.cricketTargetRaw,
                  let target = CricketTarget(rawValue: raw) else { continue }
            let incoming = dart.isMiss ? 0 : (dart.segment == .innerBull ? 2 : (dart.segment == .outerBull ? 1 : dart.multiplier.markValue))
            let prior = preview.players[playerIndex].marks[target.rawValue] ?? 0
            preview.players[playerIndex].marks[target.rawValue] = min(3, prior + incoming)
        }
        return CricketTarget.allCases.reduce(0) { sum, target in
            let prior = before[target.rawValue] ?? 0
            let next = preview.players[playerIndex].marks[target.rawValue] ?? 0
            return sum + max(0, min(3, next) - prior)
        }
    }

    private func previewMarksPerRound(for playerId: UUID, isActive: Bool) -> Double {
        let events = cricketTurnEvents(for: playerId)
        let marks = committedMarks(for: playerId) + previewVisitMarks(isActive: isActive)
        let includesPreviewRound = MatchVisitPreview.includesActiveVisit(
            isActive: isActive,
            canHumanInput: canHumanInput,
            isBotPlaying: isBotPlaying,
            isCurrentPlayerBot: isCurrentPlayerBot
        ) && !enteredDarts.isEmpty
        let rounds = events.count + (includesPreviewRound ? 1 : 0)
        guard rounds > 0 else { return 0 }
        return Double(marks) / Double(rounds)
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
        logger.matchInfo(
            matchId: matchId,
            matchType: .cricket,
            category: .ui,
            eventName: "match_screen_appeared",
            message: "Cricket match screen presented."
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
        isBotPlaying = false
        if currentBotSkillProfile != nil {
            enteredDarts.removeAll()
        }
        if enteredDarts.isEmpty {
            scheduleBotPlaybackIfNeeded()
        }
        return true
    }

    /// Clears transient bot UI when the screen reappears after a cancelled bot task.
    private func reconcileInterruptedBotPlayback() {
        isBotPlaying = false
        enteredDarts.removeAll()
        guard session?.runtime.status == .inProgress else { return }
        switch state {
        case .submittingTurn, .entryInvalid, .error, .matchCompleted, .closureTransition:
            state = .readyTurn
        default:
            break
        }
    }

    func playBotTurnIfNeeded() async {
        while await playSingleBotTurnIfNeeded() {}
    }

    @discardableResult
    private func playSingleBotTurnIfNeeded() async -> Bool {
        guard let profile = currentBotSkillProfile,
              state == .readyTurn,
              isBotPlaying == false,
              let cricketState = session?.runtime.cricketState else { return false }

        isBotPlaying = true
        defer { isBotPlaying = false }
        logger.matchDebug(
            matchId: matchId,
            matchType: .cricket,
            eventName: "bot_turn_started",
            message: "Bot visit generation started."
        )

        let partialVisitCount = enteredDarts.count
        if partialVisitCount == 0 {
            enteredDarts.removeAll()
        }

        var rng = SystemRandomNumberGenerator()
        let plannedDarts = DartBotEngine.generateCricketTurn(
            state: cricketState,
            playerIndex: cricketState.currentPlayerIndex,
            profile: profile,
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
        return currentBotSkillProfile != nil && state == .readyTurn
    }

    /// Marks the match abandoned when the player leaves mid-match so it stops
    /// appearing as resumable. Completed matches are left untouched.
    private func submitTurnAsync(fromBotPlayback: Bool = false) async {
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
            if let visitTotal = lastCricketTurnTotal(in: updated) {
                turnTotalCallerToken += 1
                turnTotalCallerSignal = TurnTotalCallerSignal(token: turnTotalCallerToken, total: visitTotal)
            }
            if updated.runtime.status == .completed {
                PerformanceMonitor.measure(
                    .completeMatch,
                    logger: logger,
                    metadata: ["matchType": MatchType.cricket.rawValue]
                ) {}
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
                    try? await Task.sleep(nanoseconds: BotTurnPacing.cricketClosureDelayNanoseconds())
                }
                state = .readyTurn
                if updated.runtime.status != .completed, !fromBotPlayback {
                    scheduleBotPlaybackIfNeeded()
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
            logger.matchInfo(
                matchId: matchId,
                matchType: .cricket,
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
        if !enteredDarts.isEmpty {
            enteredDarts.removeLast()
            selectedMultiplier = .single
            logger.matchInfo(
                matchId: matchId,
                matchType: .cricket,
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
            logger.matchInfo(
                matchId: matchId,
                matchType: .cricket,
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
                matchType: .cricket,
                eventName: "turn_undo_failed",
                message: "Undo failed.",
                metadata: MatchTurnSupport.appErrorMetadata(for: error)
            )
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "cricket.error.undoFailed"))
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
            matchType: .cricket,
            store: store,
            logger: logger,
            matchRepository: matchRepository,
            statsRepository: statsRepository,
            sessionMissingFallbackKey: "cricket.error.sessionMissing"
        ) {
        case let .loaded(loaded):
            session = loaded
        case .missing:
            break
        case let .failed(messageKey):
            state = .error(messageKey)
        }
    }

    private func lastCricketTurnTotal(in session: MatchLifecycleSession) -> Int? {
        guard let envelope = session.events.last,
              case let .cricketTurn(event) = envelope.payload else { return nil }
        return event.totalPointsAdded
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

extension CricketMatchViewModel: MatchPlaySessionHost {
    var isBotTurnBlocking: Bool { isBotPlaying || state == .submittingTurn }
    var hostMatchRepository: any MatchRepository { matchRepository }
    var hostMatchStore: ActiveMatchStore { store }
    var hostMatchLogger: any AppLogger { logger }
    var hostMatchType: MatchType { .cricket }
}
