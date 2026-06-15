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
    @Published var session: MatchLifecycleSession?
    @Published private(set) var isBotPlaying = false

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
        guard let projection = projectedStepState(),
              projection.stepIndex < ChaseTheDragonEngine.stepsPerLap else { return "" }
        return ChaseTheDragonEngine.dragonSequence[projection.stepIndex].displayLabel
    }

    /// Full sequence progress for the current player (e.g. "Step 3 of 13").
    var sequenceProgressText: String {
        guard let gameState = chaseTheDragonState,
              let projection = projectedStepState() else { return "" }
        let totalSteps = ChaseTheDragonEngine.stepsPerLap * gameState.config.laps.rawValue
        let completedSteps = projection.lapsCompleted * ChaseTheDragonEngine.stepsPerLap + projection.stepIndex
        return L10n.format("play.chaseTheDragon.sequenceProgressFormat", completedSteps + 1, totalSteps)
    }

    var scoringSegmentsDisabled: Bool {
        projectedStepState()?.wouldCompleteMatch == true
    }

    /// Current lap label shown when laps > 1.
    var lapLabel: String? {
        guard let gameState = chaseTheDragonState,
              gameState.config.laps.rawValue > 1,
              let projection = projectedStepState() else { return nil }
        return L10n.format(
            "play.chaseTheDragon.lapFormat",
            projection.lapsCompleted + 1,
            gameState.config.laps.rawValue
        )
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
        logger.matchInfo(
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

    private struct ProjectedStepState {
        var stepIndex: Int
        var lapsCompleted: Int
        var wouldCompleteMatch: Bool
    }

    private func projectedStepState() -> ProjectedStepState? {
        guard let gameState = chaseTheDragonState else { return nil }
        let player = gameState.players[gameState.currentPlayerIndex]
        var stepIndex = player.stepIndex
        var lapsCompleted = player.lapsCompleted
        let lapsNeeded = gameState.config.laps.rawValue

        for dart in enteredDarts {
            guard stepIndex < ChaseTheDragonEngine.stepsPerLap else { break }
            let step = ChaseTheDragonEngine.dragonSequence[stepIndex]
            guard step.isQualifyingHit(dart) else { continue }
            stepIndex += 1
            if stepIndex == ChaseTheDragonEngine.stepsPerLap {
                lapsCompleted += 1
                if lapsCompleted >= lapsNeeded {
                    return ProjectedStepState(
                        stepIndex: stepIndex,
                        lapsCompleted: lapsCompleted,
                        wouldCompleteMatch: true
                    )
                }
                stepIndex = 0
            }
        }
        return ProjectedStepState(
            stepIndex: stepIndex,
            lapsCompleted: lapsCompleted,
            wouldCompleteMatch: false
        )
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
        let player = gameState.players[gameState.currentPlayerIndex]
        var rng = SystemRandomNumberGenerator()
        let plannedDarts = DartBotEngine.generateChaseTheDragonTurn(
            stepIndex: player.stepIndex,
            lapsCompleted: player.lapsCompleted,
            lapsNeeded: gameState.config.laps.rawValue,
            profile: profile,
            rng: &rng
        )

        let dartDelay = BotTurnPacing.dartDelayNanoseconds(feedbackPreferences: feedbackPreferences)
        for dart in plannedDarts {
            do {
                try await Task.sleep(nanoseconds: dartDelay)
            } catch {
                return false
            }
            enteredDarts.append(dart)
        }

        do {
            try await Task.sleep(nanoseconds: BotTurnPacing.submitDelayNanoseconds(feedbackPreferences: feedbackPreferences))
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

    func loadSessionIfNeeded() async {
        if session != nil { return }
        switch await MatchSessionLoader.load(
            matchId: matchId,
            matchType: .chaseTheDragon,
            store: store,
            logger: logger,
            matchRepository: matchRepository,
            statsRepository: statsRepository,
            sessionMissingFallbackKey: "chaseTheDragon.error.sessionMissing"
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
extension ChaseTheDragonMatchViewModel: MatchPlaySessionHost {
    var isBotTurnBlocking: Bool { isBotPlaying || state == .submittingTurn }
    var hostMatchRepository: any MatchRepository { matchRepository }
    var hostMatchStore: ActiveMatchStore { store }
    var hostMatchLogger: any AppLogger { logger }
    var hostMatchType: MatchType { .chaseTheDragon }
}
