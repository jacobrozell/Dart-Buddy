import SwiftUI

@MainActor
final class ChaseTheDragonMatchViewModel: ObservableObject {
    enum State: Equatable {
        case readyTurn
        case entryInvalid(String)
        case submittingTurn
        case matchCompleted
        case error(String)
    }

    @Published private(set) var state: State = .readyTurn
    @Published var selectedMultiplier: DartMultiplier = .triple
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
            matchType: .chaseTheDragon,
            eventTypeRaw: "chaseTheDragonTurn",
            store: store,
            logger: logger,
            matchRepository: matchRepository
        )
        self.session = store.session(for: matchId)
    }

    var chaseTheDragonState: ChaseTheDragonState? { session?.runtime.chaseTheDragonState }

    var canSubmit: Bool { enteredDarts.count == 3 && canHumanInput }

    var canHumanInput: Bool {
        isCurrentPlayerBot == false && isBotPlaying == false && state == .readyTurn
    }

    var isCurrentPlayerBot: Bool {
        currentBotSkillProfile != nil
    }

    var currentBotSkillProfile: BotSkillProfile? {
        guard let session, let gameState = session.runtime.chaseTheDragonState else { return nil }
        guard session.runtime.status == .inProgress else { return nil }
        let player = gameState.players[gameState.currentPlayerIndex]
        return DartBotEngine.botSkillProfile(
            playerId: player.playerId,
            in: session.runtime.participants
        )
    }

    /// The current dragon step as a display label for the header.
    var currentStepLabel: String {
        guard let gameState = chaseTheDragonState else { return "" }
        let stepIndex = gameState.players[gameState.currentPlayerIndex].stepIndex
        guard stepIndex < ChaseTheDragonEngine.stepsPerLap else { return "" }
        return ChaseTheDragonEngine.dragonSequence[stepIndex].displayLabel
    }

    /// Full sequence progress for the current player (e.g. "Step 3 of 13").
    var sequenceProgressText: String {
        guard let gameState = chaseTheDragonState else { return "" }
        let player = gameState.players[gameState.currentPlayerIndex]
        let totalSteps = ChaseTheDragonEngine.stepsPerLap * gameState.config.laps.rawValue
        let completedSteps = player.lapsCompleted * ChaseTheDragonEngine.stepsPerLap + player.stepIndex
        return L10n.format("play.chaseTheDragon.sequenceProgressFormat", completedSteps + 1, totalSteps)
    }

    /// Current lap label shown when laps > 1.
    var lapLabel: String? {
        guard let gameState = chaseTheDragonState, gameState.config.laps.rawValue > 1 else { return nil }
        let player = gameState.players[gameState.currentPlayerIndex]
        return L10n.format("play.chaseTheDragon.lapFormat", player.lapsCompleted + 1, gameState.config.laps.rawValue)
    }

    var headerAccessibilityLabel: String {
        var parts = [L10n.string("play.chaseTheDragon.navTitle"), currentStepLabel, sequenceProgressText]
        if let lapLabel { parts.append(lapLabel) }
        return parts.joined(separator: ", ")
    }

    /// Rows describing each player's sequence position for the scoreboard strip.
    var sequenceRows: [ChaseTheDragonSequenceStripView.Row] {
        guard let session, let gameState = session.runtime.chaseTheDragonState else { return [] }
        let isInProgress = session.runtime.status == .inProgress
        let totalSteps = ChaseTheDragonEngine.stepsPerLap * gameState.config.laps.rawValue
        return gameState.players.enumerated().map { index, player in
            let participant = participant(for: player.playerId)
            let completedSteps = player.lapsCompleted * ChaseTheDragonEngine.stepsPerLap + player.stepIndex
            return ChaseTheDragonSequenceStripView.Row(
                id: player.playerId,
                name: participant?.displayNameAtMatchStart ?? MatchConfigText.playerName(forIndex: index),
                completedSteps: completedSteps,
                totalSteps: totalSteps,
                currentStepLabel: stepLabel(for: player, gameState: gameState),
                isActive: index == gameState.currentPlayerIndex && isInProgress,
                isLeading: isPlayerLeading(playerIndex: index, gameState: gameState),
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
            matchType: .chaseTheDragon,
            category: .ui,
            eventName: "match_screen_appeared",
            message: "Chase the Dragon match screen presented."
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

    func playBotTurnIfNeeded() async {
        while await playSingleBotTurnIfNeeded() {}
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
                matchType: .chaseTheDragon,
                category: .appLifecycle,
                eventName: "chaseTheDragon_abandon_failed",
                message: "Abandon failed.",
                metadata: MatchTurnSupport.appErrorMetadata(for: error)
            )
        }
    }

    // MARK: - Private helpers

    private func isPlayerLeading(playerIndex: Int, gameState: ChaseTheDragonState) -> Bool {
        let maxSteps = gameState.players.map { p in
            p.lapsCompleted * ChaseTheDragonEngine.stepsPerLap + p.stepIndex
        }.max() ?? 0
        guard maxSteps > 0 else { return false }
        let leaderCount = gameState.players.filter {
            $0.lapsCompleted * ChaseTheDragonEngine.stepsPerLap + $0.stepIndex == maxSteps
        }.count
        let playerSteps = gameState.players[playerIndex].lapsCompleted * ChaseTheDragonEngine.stepsPerLap
            + gameState.players[playerIndex].stepIndex
        return leaderCount == 1 && playerSteps == maxSteps
    }

    private func stepLabel(
        for player: ChaseTheDragonPlayerState,
        gameState: ChaseTheDragonState
    ) -> String {
        guard player.stepIndex < ChaseTheDragonEngine.stepsPerLap else {
            return L10n.string("play.chaseTheDragon.dragonComplete")
        }
        return ChaseTheDragonEngine.dragonSequence[player.stepIndex].displayLabel
    }

    private func participant(for playerId: UUID) -> MatchParticipant? {
        session?.runtime.participants.first { ($0.playerId ?? $0.id) == playerId }
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
              let gameState = session?.runtime.chaseTheDragonState else { return false }

        isBotPlaying = true
        defer { isBotPlaying = false }

        enteredDarts.removeAll()
        let stepIndex = gameState.players[gameState.currentPlayerIndex].stepIndex
        var rng = SystemRandomNumberGenerator()
        let plannedDarts = DartBotEngine.generateChaseTheDragonTurn(
            stepIndex: stepIndex,
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
            state = .error("chaseTheDragon.error.sessionMissing")
            return
        }
        state = .submittingTurn
        let darts = enteredDarts

        let outcome = await turnSubmitter.submitTurn(
            from: current,
            invalidTurnFallbackKey: "chaseTheDragon.error.invalidTurn"
        ) {
            try MatchLifecycleService.submitChaseTheDragonTurn(session: current, darts: darts)
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
            await playBotTurnIfNeeded()
        } catch is CancellationError {
            state = .readyTurn
        } catch {
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "chaseTheDragon.error.undoFailed"))
        }
    }

    private func undoLastDartAsync() async {
        await loadSessionIfNeeded()
        guard let current = session else { return }
        if !enteredDarts.isEmpty {
            enteredDarts.removeLast()
            selectedMultiplier = .triple
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
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "chaseTheDragon.error.undoFailed"))
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
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "chaseTheDragon.error.sessionMissing"))
        }
    }
}

private func postAccessibilityAnnouncement(_ text: String) {
    UIAccessibility.post(notification: .announcement, argument: text)
}
