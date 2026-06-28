import SwiftUI

@MainActor
final class LoopMatchViewModel: ObservableObject {
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
    @Published private(set) var submittedDarts: [LoopSubmittedDart] = []
    @Published var showWireTargetPicker = false
    @Published private(set) var pendingWireTargetDart: DartInput?
    @Published private(set) var pendingWireTargetOptions: [LoopWireTargetArea] = []
    @Published private(set) var session: MatchLifecycleSession?
    @Published private(set) var isBotPlaying = false

    private let matchId: UUID
    private let store: ActiveMatchStore
    private let logger: any AppLogger
    private let matchRepository: any MatchRepository
    private let statsRepository: any StatsRepository
    private let feedbackPreferences: FeedbackPreferences
    private let visitSubmitter: MatchTurnSubmitter
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
        self.visitSubmitter = MatchTurnSubmitter(
            matchId: matchId,
            matchType: .loop,
            eventTypeRaw: "loopVisit",
            store: store,
            logger: logger,
            matchRepository: matchRepository
        )
        self.session = store.session(for: matchId)
    }

    var loopState: LoopState? { session?.runtime.loopState }

    var maxDartsPerSubmission: Int {
        guard let state = loopState else { return 3 }
        return state.needsOpeningTarget ? 1 : 3
    }

    var canSubmit: Bool {
        !submittedDarts.isEmpty
            && submittedDarts.count == enteredDarts.count
            && submittedDarts.count <= maxDartsPerSubmission
            && canHumanInput
            && !canPass
    }

    var canPass: Bool {
        guard let state = loopState, canHumanInput else { return false }
        return state.awaitingPassDecision && state.currentPlayerId == state.targetSetterId
    }

    var canHumanInput: Bool {
        isCurrentPlayerBot == false && isBotPlaying == false && state == .readyTurn && !showWireTargetPicker
    }

    var isCurrentPlayerBot: Bool {
        currentBotSkillProfile != nil
    }

    var currentBotSkillProfile: BotSkillProfile? {
        guard let session, let gameState = session.runtime.loopState else { return nil }
        guard session.runtime.status == .inProgress else { return nil }
        let player = gameState.players[gameState.currentPlayerIndex]
        guard !player.isEliminated else { return nil }
        return DartBotEngine.botSkillProfile(
            playerId: player.playerId,
            in: session.runtime.participants
        )
    }

    var headerText: String {
        guard let gameState = loopState,
              let playerId = gameState.currentPlayerId else { return "" }
        let name = participantName(for: playerId)
        if gameState.needsOpeningTarget {
            return L10n.format("play.loop.openingThrowFormat", name)
        }
        if gameState.awaitingPassDecision {
            return L10n.format("play.loop.passTurnFormat", name)
        }
        return L10n.format("play.loop.throwFormat", name)
    }

    var scoreboardRows: [LoopScoreboardView.Row] {
        guard let session, let gameState = session.runtime.loopState else { return [] }
        let isInProgress = session.runtime.status == .inProgress
        return gameState.players.enumerated().map { index, player in
            let participant = participant(for: player.playerId)
            let isActive = index == gameState.currentPlayerIndex && isInProgress && !player.isEliminated
            return LoopScoreboardView.Row(
                id: player.playerId,
                name: participant?.displayNameAtMatchStart ?? MatchConfigText.playerName(forIndex: index),
                lives: player.lives,
                startingLives: gameState.config.startingLives,
                isEliminated: player.isEliminated,
                isActive: isActive,
                colorToken: participant?.colorToken ?? PlayerColorToken.defaultForPlayer(id: player.playerId)
            )
        }
    }

    func processDartEntry(previousCount: Int) {
        guard enteredDarts.count > previousCount,
              let dart = enteredDarts.last,
              canHumanInput || isBotPlaying else { return }
        resolveWireTarget(for: dart, autoSubmit: true)
    }

    func confirmWireTarget(_ target: LoopWireTargetArea) {
        guard let dart = pendingWireTargetDart else { return }
        submittedDarts.append(LoopSubmittedDart(dart: dart, wireTarget: target))
        clearPendingWireTarget()
        autoSubmitIfReady()
    }

    func cancelWireTargetPicker() {
        if pendingWireTargetDart != nil {
            enteredDarts.removeLast()
        }
        clearPendingWireTarget()
    }

    func submitTurn() async {
        await submitVisitAsync()
    }

    func passTurn() async {
        await passTurnAsync()
    }

    func undoLastTurn() async {
        await undoLastTurnAsync()
    }

    func undoLastDart() async {
        guard canHumanInput, !enteredDarts.isEmpty else { return }
        enteredDarts.removeLast()
        if !submittedDarts.isEmpty {
            submittedDarts.removeLast()
        }
        clearPendingWireTarget()
    }

    func onAppear() async {
        logger.matchInfo(
            matchId: matchId,
            matchType: .loop,
            category: .ui,
            eventName: "match_screen_appeared",
            message: "Loop match screen presented."
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
        } catch {
            logger.matchError(
                matchId: matchId,
                matchType: .loop,
                category: .appLifecycle,
                eventName: "loop_abandon_failed",
                message: "Abandon failed.",
                metadata: MatchTurnSupport.appErrorMetadata(for: error)
            )
        }
    }

    private func scheduleBotPlaybackIfNeeded() {
        botPlayback.schedule { await self.playBotTurnIfNeeded() }
    }

    func playBotTurnIfNeeded() async {
        while await playSingleBotTurnIfNeeded() {}
    }

    private func reconcileAfterSummaryUndo() async -> Bool {
        guard state == .matchCompleted,
              let stored = store.session(for: matchId),
              stored.runtime.status == .inProgress else { return false }
        session = stored
        state = .readyTurn
        enteredDarts = store.consumeResumeHint(matchId: matchId) ?? []
        submittedDarts = []
        isBotPlaying = false
        if currentBotSkillProfile != nil {
            enteredDarts.removeAll()
        }
        if enteredDarts.isEmpty {
            scheduleBotPlaybackIfNeeded()
        }
        return true
    }

    private func reconcileInterruptedBotPlayback() {
        isBotPlaying = false
        enteredDarts.removeAll()
        submittedDarts.removeAll()
        clearPendingWireTarget()
        guard session?.runtime.status == .inProgress else { return }
        switch state {
        case .submittingTurn, .entryInvalid, .error, .matchCompleted:
            state = .readyTurn
        default:
            break
        }
    }

    @discardableResult
    private func playSingleBotTurnIfNeeded() async -> Bool {
        guard let profile = currentBotSkillProfile,
              state == .readyTurn,
              isBotPlaying == false,
              let gameState = session?.runtime.loopState else { return false }

        isBotPlaying = true
        defer { isBotPlaying = false }

        if gameState.awaitingPassDecision, gameState.currentPlayerId == gameState.targetSetterId {
            await passTurnAsync(fromBotPlayback: true)
            guard session?.runtime.status != .completed else { return false }
            return currentBotSkillProfile != nil && state == .readyTurn
        }

        enteredDarts.removeAll()
        submittedDarts.removeAll()
        var rng = SystemRandomNumberGenerator()
        let plannedDarts = DartBotEngine.generateLoopVisit(
            state: gameState,
            profile: profile,
            rng: &rng
        )

        let dartDelay = BotTurnPacing.dartDelayNanoseconds(feedbackPreferences: feedbackPreferences)
        for submitted in plannedDarts {
            do {
                try await Task.sleep(nanoseconds: dartDelay)
            } catch {
                return false
            }
            enteredDarts.append(submitted.dart)
            submittedDarts.append(submitted)
        }

        do {
            try await Task.sleep(nanoseconds: BotTurnPacing.submitDelayNanoseconds(feedbackPreferences: feedbackPreferences))
        } catch {
            return false
        }
        await submitVisitAsync(fromBotPlayback: true)
        guard session?.runtime.status != .completed else { return false }
        return currentBotSkillProfile != nil && state == .readyTurn
    }

    private func resolveWireTarget(for dart: DartInput, autoSubmit: Bool) {
        if dart.isMiss {
            submittedDarts.append(LoopEngine.missSubmittedDart(dart))
            if autoSubmit { autoSubmitIfReady() }
            return
        }
        let candidates = LoopWireTargetArea.candidates(for: dart)
        if candidates.count == 1, let only = candidates.first {
            submittedDarts.append(LoopSubmittedDart(dart: dart, wireTarget: only))
            if autoSubmit { autoSubmitIfReady() }
        } else {
            pendingWireTargetDart = dart
            pendingWireTargetOptions = candidates
            showWireTargetPicker = true
        }
    }

    private func clearPendingWireTarget() {
        pendingWireTargetDart = nil
        pendingWireTargetOptions = []
        showWireTargetPicker = false
    }

    private func autoSubmitIfReady() {
        guard submittedDarts.count == maxDartsPerSubmission else { return }
        Task { await submitVisitAsync() }
    }

    private func submitVisitAsync(fromBotPlayback: Bool = false) async {
        await loadSessionIfNeeded()
        guard let current = session else {
            state = .error("loop.error.sessionMissing")
            return
        }
        state = .submittingTurn
        let darts = submittedDarts

        let outcome = await visitSubmitter.submitTurn(
            from: current,
            invalidTurnFallbackKey: "loop.error.invalidVisit"
        ) {
            try MatchLifecycleService.submitLoopVisit(session: current, darts: darts)
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
            if let event = lastVisit(in: updated) {
                announceVisitIfNeeded(event: event)
            }
            if updated.runtime.status == .completed {
                state = .matchCompleted
            } else {
                state = .readyTurn
                if !fromBotPlayback {
                    await playBotTurnIfNeeded()
                }
            }
            enteredDarts.removeAll()
            submittedDarts.removeAll()
        }
    }

    private func passTurnAsync(fromBotPlayback: Bool = false) async {
        await loadSessionIfNeeded()
        guard let current = session else {
            state = .error("loop.error.sessionMissing")
            return
        }
        state = .submittingTurn

        let outcome = await visitSubmitter.submitTurn(
            from: current,
            invalidTurnFallbackKey: "loop.error.invalidVisit"
        ) {
            try MatchLifecycleService.submitLoopPass(session: current)
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
            if updated.runtime.status == .completed {
                state = .matchCompleted
            } else {
                state = .readyTurn
                if !fromBotPlayback {
                    await playBotTurnIfNeeded()
                }
            }
            enteredDarts.removeAll()
            submittedDarts.removeAll()
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
            submittedDarts.removeAll()
            scheduleBotPlaybackIfNeeded()
        } catch is CancellationError {
            state = .readyTurn
        } catch {
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "loop.error.invalidVisit"))
        }
    }

    private func loadSessionIfNeeded() async {
        if session == nil {
            session = store.session(for: matchId)
        }
    }

    private func participant(for playerId: UUID) -> MatchParticipant? {
        session?.runtime.participant(for: playerId)
    }

    private func participantName(for playerId: UUID) -> String {
        participant(for: playerId)?.displayNameAtMatchStart
            ?? L10n.string("play.match.unknownPlayer")
    }

    private func lastVisit(in session: MatchLifecycleSession) -> LoopVisitEvent? {
        guard case let .loopVisit(event) = session.events.last?.payload else { return nil }
        return event
    }

    private func announceVisitIfNeeded(event: LoopVisitEvent) {
        if event.matched, !event.setOpeningTarget {
            postAccessibilityAnnouncement(L10n.string("play.loop.announce.targetMatched"))
        } else if event.lifeLost {
            postAccessibilityAnnouncement(L10n.string("play.loop.lifeLost"))
        }
    }

    private func postAccessibilityAnnouncement(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}
