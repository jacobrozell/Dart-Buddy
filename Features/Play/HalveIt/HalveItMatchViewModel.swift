import SwiftUI

@MainActor
final class HalveItMatchViewModel: ObservableObject {
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
            matchType: .halveIt,
            eventTypeRaw: "halveItRound",
            store: store,
            logger: logger,
            matchRepository: matchRepository
        )
        self.session = store.session(for: matchId)
    }

    var halveItState: HalveItState? { session?.runtime.halveItState }

    var canSubmit: Bool { enteredDarts.count == 3 && canHumanInput }

    var canHumanInput: Bool {
        isCurrentPlayerBot == false && isBotPlaying == false && state == .readyTurn
    }

    var isCurrentPlayerBot: Bool { currentBotSkillProfile != nil }

    var currentBotSkillProfile: BotSkillProfile? {
        guard let session, let gameState = session.runtime.halveItState else { return nil }
        guard session.runtime.status == .inProgress else { return nil }
        let player = gameState.players[gameState.currentPlayerIndex]
        return DartBotEngine.botSkillProfile(
            playerId: player.playerId,
            in: session.runtime.participants
        )
    }

    var lockedSegment: Int? { halveItState?.currentTarget }

    var headerText: String {
        guard let state = halveItState, let target = state.currentTarget else { return "" }
        let roundNumber = min(state.roundIndex + 1, state.config.targets.count)
        return L10n.format(
            "play.halveIt.headerFormat",
            target,
            roundNumber,
            state.config.targets.count
        )
    }

    var headerAccessibilityLabel: String {
        [L10n.string("play.halveIt.navTitle"), headerText].joined(separator: ", ")
    }

    var scoreboardRows: [HalveItScoreboardView.Row] {
        guard let session, let gameState = session.runtime.halveItState else { return [] }
        let isInProgress = session.runtime.status == .inProgress
        let maxTotal = gameState.players.map(\.total).max() ?? 0
        return gameState.players.enumerated().map { index, player in
            let participant = session.runtime.participant(for: player.playerId)
            let isActive = index == gameState.currentPlayerIndex && isInProgress
            let isLeading = maxTotal > 0 && player.total == maxTotal
                && gameState.players.filter { $0.total == maxTotal }.count == 1
            return HalveItScoreboardView.Row(
                id: player.playerId,
                name: participant?.displayNameAtMatchStart ?? MatchConfigText.playerName(forIndex: index),
                total: player.total,
                isActive: isActive,
                isLeading: isLeading,
                colorToken: participant?.colorToken ?? PlayerColorToken.defaultForPlayer(id: player.playerId)
            )
        }
    }

    func submitTurn() async { await submitTurnAsync() }
    func undoLastTurn() async { await undoLastTurnAsync() }
    func undoLastDart() async { await undoLastDartAsync() }

    func onAppear() async {
        logger.matchInfo(
            matchId: matchId,
            matchType: .halveIt,
            category: .ui,
            eventName: "match_screen_appeared",
            message: "Halve-It match screen presented."
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
                matchType: .halveIt,
                category: .appLifecycle,
                eventName: "halve_it_abandon_failed",
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
        if currentBotSkillProfile != nil { enteredDarts.removeAll() }
        if enteredDarts.isEmpty { scheduleBotPlaybackIfNeeded() }
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
              let gameState = session?.runtime.halveItState,
              let target = gameState.currentTarget else { return false }

        isBotPlaying = true
        defer { isBotPlaying = false }

        enteredDarts.removeAll()
        var rng = SystemRandomNumberGenerator()
        let plannedDarts = DartBotEngine.generateHalveItTurn(
            targetSegment: target,
            profile: profile,
            rng: &rng
        )

        let dartDelay = BotTurnPacing.dartDelayNanoseconds(staggerEnabled: feedbackPreferences.botStaggerEnabled)
        for dart in plannedDarts {
            do { try await Task.sleep(nanoseconds: dartDelay) } catch { return false }
            enteredDarts.append(dart)
        }

        do {
            try await Task.sleep(
                nanoseconds: BotTurnPacing.submitDelayNanoseconds(
                    staggerEnabled: feedbackPreferences.botStaggerEnabled
                )
            )
        } catch { return false }

        await submitTurnAsync(fromBotPlayback: true)
        guard session?.runtime.status != .completed else { return false }
        return currentBotSkillProfile != nil && state == .readyTurn
    }

    private func submitTurnAsync(fromBotPlayback: Bool = false) async {
        await loadSessionIfNeeded()
        guard let current = session else {
            state = .error("halveIt.error.sessionMissing")
            return
        }
        state = .submittingTurn
        let darts = enteredDarts

        let outcome = await turnSubmitter.submitTurn(
            from: current,
            invalidTurnFallbackKey: "halveIt.error.invalidTurn"
        ) {
            try MatchLifecycleService.submitHalveItTurn(session: current, darts: darts)
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
                if !fromBotPlayback { await playBotTurnIfNeeded() }
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
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "error.repository.storage"))
        }
    }

    private func undoLastDartAsync() async {
        await loadSessionIfNeeded()
        guard let current = session else { return }
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
        } catch is CancellationError {
            state = .readyTurn
        } catch {
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "error.repository.storage"))
        }
    }

    private func loadSessionIfNeeded() async {
        if session == nil {
            session = store.session(for: matchId)
        }
    }
}
