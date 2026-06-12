import SwiftUI

@MainActor
final class SuddenDeathMatchViewModel: ObservableObject {
    enum State: Equatable {
        case readyTurn
        case entryInvalid(String)
        case submittingTurn
        case eliminationFeedback
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
            matchType: .suddenDeath,
            eventTypeRaw: "suddenDeathTurn",
            store: store,
            logger: logger,
            matchRepository: matchRepository
        )
        self.session = store.session(for: matchId)
    }

    var suddenDeathState: SuddenDeathState? { session?.runtime.suddenDeathState }

    var canSubmit: Bool { enteredDarts.count == 3 && canHumanInput }

    var canHumanInput: Bool {
        isCurrentPlayerBot == false && isBotPlaying == false && state == .readyTurn
    }

    var isCurrentPlayerBot: Bool {
        currentBotSkillProfile != nil
    }

    var currentBotSkillProfile: BotSkillProfile? {
        guard let session, let gameState = session.runtime.suddenDeathState else { return nil }
        guard session.runtime.status == .inProgress else { return nil }
        let player = gameState.players[gameState.currentPlayerIndex]
        return DartBotEngine.botSkillProfile(
            playerId: player.playerId,
            in: session.runtime.participants
        )
    }

    var headerText: String {
        guard let gameState = suddenDeathState else { return "" }
        return L10n.format("play.suddenDeath.roundFormat", gameState.currentRound)
    }

    var playersRemainingText: String {
        guard let gameState = suddenDeathState else { return "" }
        return L10n.format(
            "play.suddenDeath.playersRemainingFormat",
            gameState.activePlayerIds.count
        )
    }

    var headerAccessibilityLabel: String {
        var parts = [L10n.string("play.suddenDeath.navTitle"), headerText, playersRemainingText]
        return parts.joined(separator: ", ")
    }

    var scoreboardRows: [SuddenDeathScoreboardView.Row] {
        guard let session, let gameState = session.runtime.suddenDeathState else { return [] }
        let isInProgress = session.runtime.status == .inProgress
        return gameState.players.enumerated().map { index, player in
            let participant = participant(for: player.playerId)
            let isActive = index == gameState.currentPlayerIndex && isInProgress && !player.isEliminated
            let isAtRisk = isInProgress && isAtLowestThisRound(playerIndex: index, state: gameState)
            let roundPreview = currentRoundPreview(
                for: player,
                playerIndex: index,
                isActive: isActive,
                state: gameState
            )
            return SuddenDeathScoreboardView.Row(
                id: player.playerId,
                name: participant?.displayNameAtMatchStart ?? MatchConfigText.playerName(forIndex: index),
                roundTotal: roundPreview,
                cumulativeTotal: player.cumulativeTotal,
                isActive: isActive,
                isEliminated: player.isEliminated,
                isAtRisk: isAtRisk,
                colorToken: participant?.colorToken ?? PlayerColorToken.defaultForPlayer(id: player.playerId)
            )
        }
    }

    var lastRoundEliminationText: String? {
        guard let gameState = suddenDeathState,
              !gameState.lastRoundEliminatedIds.isEmpty else { return nil }
        if gameState.lastRoundEliminatedIds.count == 1,
           let id = gameState.lastRoundEliminatedIds.first,
           let participant = participant(for: id) {
            return L10n.format(
                "play.suddenDeath.lowestScoreEliminatedFormat",
                participant.displayNameAtMatchStart
            )
        }
        return L10n.string("play.suddenDeath.eliminatedThisRound")
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
            matchType: .suddenDeath,
            category: .ui,
            eventName: "match_screen_appeared",
            message: "Sudden Death match screen presented."
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
                matchType: .suddenDeath,
                category: .appLifecycle,
                eventName: "suddenDeath_abandon_failed",
                message: "Abandon failed.",
                metadata: MatchTurnSupport.appErrorMetadata(for: error)
            )
        }
    }

    func announceRoundResultsIfNeeded(eliminatedNames: [String]) {
        guard !eliminatedNames.isEmpty else { return }
        let names = eliminatedNames.joined(separator: ", ")
        let announcement = L10n.format("play.suddenDeath.announce.roundResults", names)
        postAccessibilityAnnouncement(announcement)
    }

    // MARK: - Private helpers

    private func isAtLowestThisRound(playerIndex: Int, state: SuddenDeathState) -> Bool {
        guard !state.players[playerIndex].isEliminated else { return false }
        let activePlayers = state.players.filter { !$0.isEliminated }
        guard activePlayers.count > 1 else { return false }
        guard let minTotal = activePlayers.map(\.roundTotal).min() else { return false }
        guard minTotal > 0 || activePlayers.allSatisfy({ $0.roundTotal == 0 }) == false else {
            return false
        }
        return state.players[playerIndex].roundTotal == minTotal
    }

    private func currentRoundPreview(
        for player: SuddenDeathPlayerState,
        playerIndex: Int,
        isActive: Bool,
        state: SuddenDeathState
    ) -> Int {
        guard MatchVisitPreview.includesActiveVisit(
            isActive: isActive,
            canHumanInput: canHumanInput,
            isBotPlaying: isBotPlaying,
            isCurrentPlayerBot: isCurrentPlayerBot
        ) else { return player.roundTotal }
        var preview = player.roundTotal
        for dart in enteredDarts {
            preview += pointValue(for: dart)
        }
        return preview
    }

    private func pointValue(for dart: DartInput) -> Int {
        guard !dart.isMiss else { return 0 }
        switch dart.segment {
        case let .oneToTwenty(value):
            switch dart.multiplier {
            case .single: return value
            case .double: return value * 2
            case .triple: return value * 3
            }
        case .outerBull: return 25
        case .innerBull: return 50
        case .miss: return 0
        }
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
        case .submittingTurn, .entryInvalid, .error, .matchCompleted, .eliminationFeedback:
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
              session?.runtime.suddenDeathState != nil else { return false }

        isBotPlaying = true
        defer { isBotPlaying = false }

        enteredDarts.removeAll()
        var rng = SystemRandomNumberGenerator()
        let plannedDarts = DartBotEngine.generateSuddenDeathTurn(
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
            state = .error("suddenDeath.error.sessionMissing")
            return
        }
        state = .submittingTurn
        let darts = enteredDarts

        let outcome = await turnSubmitter.submitTurn(
            from: current,
            invalidTurnFallbackKey: "suddenDeath.error.invalidTurn"
        ) {
            try MatchLifecycleService.submitSuddenDeathTurn(session: current, darts: darts)
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
            if let event = lastSuddenDeathTurn(in: updated), event.roundCompleted,
               !event.eliminatedPlayerIds.isEmpty {
                let names = event.eliminatedPlayerIds.compactMap { id in
                    participant(for: id)?.displayNameAtMatchStart
                }
                announceRoundResultsIfNeeded(eliminatedNames: names)
                state = .eliminationFeedback
                try? await Task.sleep(nanoseconds: 800_000_000)
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
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "suddenDeath.error.undoFailed"))
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
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "suddenDeath.error.undoFailed"))
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
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "suddenDeath.error.sessionMissing"))
        }
    }

    private func lastSuddenDeathTurn(in session: MatchLifecycleSession) -> SuddenDeathTurnEvent? {
        guard let envelope = session.events.last,
              case let .suddenDeathTurn(event) = envelope.payload else { return nil }
        return event
    }
}

private func postAccessibilityAnnouncement(_ text: String) {
    UIAccessibility.post(notification: .announcement, argument: text)
}
