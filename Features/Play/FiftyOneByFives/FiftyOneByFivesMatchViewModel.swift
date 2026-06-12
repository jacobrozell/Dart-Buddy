import SwiftUI

@MainActor
final class FiftyOneByFivesMatchViewModel: ObservableObject {
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
            matchType: .fiftyOneByFives,
            eventTypeRaw: "fiftyOneByFivesTurn",
            store: store,
            logger: logger,
            matchRepository: matchRepository
        )
        self.session = store.session(for: matchId)
    }

    var fiftyOneByFivesState: FiftyOneByFivesState? { session?.runtime.fiftyOneByFivesState }

    var canSubmit: Bool { enteredDarts.count == 3 && canHumanInput }

    var canHumanInput: Bool {
        isCurrentPlayerBot == false && isBotPlaying == false && state == .readyTurn
    }

    var isCurrentPlayerBot: Bool {
        currentBotSkillProfile != nil
    }

    var currentBotSkillProfile: BotSkillProfile? {
        guard let session, let gameState = session.runtime.fiftyOneByFivesState else { return nil }
        guard session.runtime.status == .inProgress else { return nil }
        let player = gameState.players[gameState.currentPlayerIndex]
        return DartBotEngine.botSkillProfile(
            playerId: player.playerId,
            in: session.runtime.participants
        )
    }

    var navTitle: String {
        L10n.string("play.fiftyOneByFives.navTitle")
    }

    var divisibilityHint: String {
        L10n.string("play.fiftyOneByFives.noPointsDivisibleHint")
    }

    var targetDescription: String {
        guard let gameState = fiftyOneByFivesState else { return "" }
        return L10n.format("play.fiftyOneByFives.runningScoreFormat", gameState.config.targetPoints)
    }

    var mustFinishExactBadge: String? {
        guard fiftyOneByFivesState?.config.mustFinishExact == true else { return nil }
        return L10n.string("play.fiftyOneByFives.setup.mustFinishExact")
    }

    var headerAccessibilityLabel: String {
        var parts = [L10n.string("play.fiftyOneByFives.navTitle")]
        if let gameState = fiftyOneByFivesState {
            parts.append(L10n.format("play.fiftyOneByFives.runningScoreFormat", gameState.config.targetPoints))
        }
        parts.append(divisibilityHint)
        return parts.joined(separator: ", ")
    }

    var scoreboardRows: [FiftyOneByFivesScoreboardView.Row] {
        guard let session, let gameState = session.runtime.fiftyOneByFivesState else { return [] }
        let isInProgress = session.runtime.status == .inProgress
        return gameState.players.enumerated().map { index, player in
            let participant = participant(for: player.playerId)
            let isActive = index == gameState.currentPlayerIndex && isInProgress
            return FiftyOneByFivesScoreboardView.Row(
                id: player.playerId,
                name: participant?.displayNameAtMatchStart ?? MatchConfigText.playerName(forIndex: index),
                cumulativePoints: player.cumulativePoints,
                targetPoints: gameState.config.targetPoints,
                isActive: isActive,
                isLeading: isPlayerLeading(playerIndex: index, state: gameState),
                colorToken: participant?.colorToken ?? PlayerColorToken.defaultForPlayer(id: player.playerId)
            )
        }
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
            matchType: .fiftyOneByFives,
            category: .ui,
            eventName: "match_screen_appeared",
            message: "51 By 5's match screen presented."
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
                matchType: .fiftyOneByFives,
                category: .appLifecycle,
                eventName: "fiftyOneByFives_abandon_failed",
                message: "Abandon failed.",
                metadata: MatchTurnSupport.appErrorMetadata(for: error)
            )
        }
    }

    func announceTurnIfNeeded(pointsAwarded: Int, cumulativePoints: Int) {
        let announcement = L10n.format(
            "play.fiftyOneByFives.pointsAwardedFormat",
            pointsAwarded,
            cumulativePoints
        )
        postFiftyOneAccessibilityAnnouncement(announcement)
    }

    private func scheduleBotPlaybackIfNeeded() {
        botPlayback.schedule { await self.playBotTurnIfNeeded() }
    }

    func playBotTurnIfNeeded() async {
        while await playSingleBotTurnIfNeeded() {}
    }

    @discardableResult
    private func playSingleBotTurnIfNeeded() async -> Bool {
        guard let profile = currentBotSkillProfile,
              state == .readyTurn,
              isBotPlaying == false,
              let gameState = session?.runtime.fiftyOneByFivesState else { return false }

        isBotPlaying = true
        defer { isBotPlaying = false }

        enteredDarts.removeAll()
        var rng = SystemRandomNumberGenerator()
        let plannedDarts = DartBotEngine.generateFiftyOneByFivesTurn(
            state: gameState,
            playerIndex: gameState.currentPlayerIndex,
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
        await submitTurnAsync(fromBotPlayback: true)
        guard session?.runtime.status != .completed else { return false }
        return currentBotSkillProfile != nil && state == .readyTurn
    }

    private func submitTurnAsync(fromBotPlayback: Bool = false) async {
        await loadSessionIfNeeded()
        guard let current = session else {
            state = .error("fiftyOneByFives.error.sessionMissing")
            return
        }
        state = .submittingTurn
        let darts = enteredDarts

        let outcome = await turnSubmitter.submitTurn(
            from: current,
            invalidTurnFallbackKey: "fiftyOneByFives.error.invalidTurn"
        ) {
            try MatchLifecycleService.submitFiftyOneByFivesTurn(session: current, darts: darts)
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
            if let event = lastFiftyOneByFivesTurn(in: updated) {
                announceTurnIfNeeded(
                    pointsAwarded: event.pointsAwarded,
                    cumulativePoints: event.cumulativeAfter
                )
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
            await playBotTurnIfNeeded()
        } catch is CancellationError {
            state = .readyTurn
        } catch {
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "fiftyOneByFives.error.undoFailed"))
        }
    }

    private func undoLastDartAsync() async {
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
            if result.restoredDarts.isEmpty {
                await playBotTurnIfNeeded()
            }
        } catch is CancellationError {
            state = .readyTurn
        } catch {
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "fiftyOneByFives.error.undoFailed"))
        }
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
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "fiftyOneByFives.error.sessionMissing"))
        }
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

    private func isPlayerLeading(playerIndex: Int, state: FiftyOneByFivesState) -> Bool {
        let maxPoints = state.players.map(\.cumulativePoints).max() ?? 0
        guard maxPoints > 0 else { return false }
        let leaderCount = state.players.filter { $0.cumulativePoints == maxPoints }.count
        return leaderCount == 1 && state.players[playerIndex].cumulativePoints == maxPoints
    }

    private func participant(for playerId: UUID) -> MatchParticipant? {
        session?.runtime.participants.first { ($0.playerId ?? $0.id) == playerId }
    }

    private func lastFiftyOneByFivesTurn(in session: MatchLifecycleSession) -> FiftyOneByFivesTurnEvent? {
        guard let envelope = session.events.last,
              case let .fiftyOneByFivesTurn(event) = envelope.payload else { return nil }
        return event
    }
}

private func postFiftyOneAccessibilityAnnouncement(_ text: String) {
    UIAccessibility.post(notification: .announcement, argument: text)
}
