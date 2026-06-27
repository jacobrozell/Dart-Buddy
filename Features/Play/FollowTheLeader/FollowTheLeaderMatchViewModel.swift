import SwiftUI

@MainActor
final class FollowTheLeaderMatchViewModel: ObservableObject {
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
            matchType: .followTheLeader,
            eventTypeRaw: "followTheLeaderVisit",
            store: store,
            logger: logger,
            matchRepository: matchRepository
        )
        self.session = store.session(for: matchId)
    }

    var followTheLeaderState: FollowTheLeaderState? { session?.runtime.followTheLeaderState }

    var maxDartsPerSubmission: Int {
        guard let state = followTheLeaderState else { return 3 }
        return state.needsOpeningTarget ? 1 : 3
    }

    var canSubmit: Bool {
        !enteredDarts.isEmpty && enteredDarts.count <= maxDartsPerSubmission && canHumanInput && !canPass
    }

    var canPass: Bool {
        guard let state = followTheLeaderState, canHumanInput else { return false }
        return state.awaitingPassDecision && state.currentPlayerId == state.targetSetterId
    }

    var canHumanInput: Bool {
        isCurrentPlayerBot == false && isBotPlaying == false && state == .readyTurn
    }

    var isCurrentPlayerBot: Bool {
        currentBotSkillProfile != nil
    }

    var currentBotSkillProfile: BotSkillProfile? {
        guard let session, let gameState = session.runtime.followTheLeaderState else { return nil }
        guard session.runtime.status == .inProgress else { return nil }
        let player = gameState.players[gameState.currentPlayerIndex]
        guard !player.isEliminated else { return nil }
        return DartBotEngine.botSkillProfile(
            playerId: player.playerId,
            in: session.runtime.participants
        )
    }

    var headerText: String {
        guard let gameState = followTheLeaderState,
              let playerId = gameState.currentPlayerId else { return "" }
        let name = participantName(for: playerId)
        if gameState.needsOpeningTarget {
            return L10n.format("play.followTheLeader.openingThrowFormat", name)
        }
        if gameState.awaitingPassDecision {
            return L10n.format("play.followTheLeader.passTurnFormat", name)
        }
        return L10n.format("play.followTheLeader.throwFormat", name)
    }

    var scoreboardRows: [FollowTheLeaderScoreboardView.Row] {
        guard let session, let gameState = session.runtime.followTheLeaderState else { return [] }
        let isInProgress = session.runtime.status == .inProgress
        return gameState.players.enumerated().map { index, player in
            let participant = participant(for: player.playerId)
            let isActive = index == gameState.currentPlayerIndex && isInProgress && !player.isEliminated
            return FollowTheLeaderScoreboardView.Row(
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
        await undoLastDartAsync()
    }

    func onAppear() async {
        logger.matchInfo(
            matchId: matchId,
            matchType: .followTheLeader,
            category: .ui,
            eventName: "match_screen_appeared",
            message: "Follow the Leader match screen presented."
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
                matchType: .followTheLeader,
                category: .appLifecycle,
                eventName: "followTheLeader_abandon_failed",
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
              let gameState = session?.runtime.followTheLeaderState else { return false }

        isBotPlaying = true
        defer { isBotPlaying = false }

        if gameState.awaitingPassDecision, gameState.currentPlayerId == gameState.targetSetterId {
            await passTurnAsync(fromBotPlayback: true)
            guard session?.runtime.status != .completed else { return false }
            return currentBotSkillProfile != nil && state == .readyTurn
        }

        enteredDarts.removeAll()
        var rng = SystemRandomNumberGenerator()
        let plannedDarts = DartBotEngine.generateFollowTheLeaderVisit(
            state: gameState,
            profile: profile,
            rng: &rng
        )

        let dartDelay = BotTurnPacing.dartDelayNanoseconds(staggerEnabled: feedbackPreferences.botStaggerEnabled)
        for dart in plannedDarts {
            do {
                try await Task.sleep(nanoseconds: dartDelay)
            } catch {
                return false
            }
            enteredDarts.append(dart)
        }

        do {
            try await Task.sleep(nanoseconds: BotTurnPacing.submitDelayNanoseconds(staggerEnabled: feedbackPreferences.botStaggerEnabled))
        } catch {
            return false
        }
        await submitVisitAsync(fromBotPlayback: true)
        guard session?.runtime.status != .completed else { return false }
        return currentBotSkillProfile != nil && state == .readyTurn
    }

    private func submitVisitAsync(fromBotPlayback: Bool = false) async {
        await loadSessionIfNeeded()
        guard let current = session else {
            state = .error("followTheLeader.error.sessionMissing")
            return
        }
        state = .submittingTurn
        let darts = enteredDarts

        let outcome = await visitSubmitter.submitTurn(
            from: current,
            invalidTurnFallbackKey: "followTheLeader.error.invalidVisit"
        ) {
            try MatchLifecycleService.submitFollowTheLeaderVisit(session: current, darts: darts)
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
        }
    }

    private func passTurnAsync(fromBotPlayback: Bool = false) async {
        await loadSessionIfNeeded()
        guard let current = session else {
            state = .error("followTheLeader.error.sessionMissing")
            return
        }
        state = .submittingTurn

        let outcome = await visitSubmitter.submitTurn(
            from: current,
            invalidTurnFallbackKey: "followTheLeader.error.invalidVisit"
        ) {
            try MatchLifecycleService.submitFollowTheLeaderPass(session: current)
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
            scheduleBotPlaybackIfNeeded()
        } catch is CancellationError {
            state = .readyTurn
        } catch {
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "followTheLeader.error.invalidVisit"))
        }
    }

    private func undoLastDartAsync() async {
        guard canHumanInput, !enteredDarts.isEmpty else { return }
        enteredDarts.removeLast()
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

    private func lastVisit(in session: MatchLifecycleSession) -> FollowTheLeaderVisitEvent? {
        guard case let .followTheLeaderVisit(event) = session.events.last?.payload else { return nil }
        return event
    }

    private func announceVisitIfNeeded(event: FollowTheLeaderVisitEvent) {
        if event.matched, !event.setOpeningTarget {
            postAccessibilityAnnouncement(L10n.string("play.followTheLeader.announce.targetMatched"))
        } else if event.lifeLost {
            postAccessibilityAnnouncement(L10n.string("play.followTheLeader.lifeLost"))
        }
    }

    private func postAccessibilityAnnouncement(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}
