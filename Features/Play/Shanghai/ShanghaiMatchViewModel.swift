import SwiftUI

@MainActor
final class ShanghaiMatchViewModel: ObservableObject {
    enum State: Equatable {
        case readyTurn
        case entryInvalid(String)
        case submittingTurn
        case shanghaiFeedback
        case matchCompleted
        case error(String)
    }

    @Published private(set) var state: State = .readyTurn
    @Published var selectedMultiplier: DartMultiplier = .single
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
            matchType: .shanghai,
            eventTypeRaw: "shanghaiTurn",
            store: store,
            logger: logger,
            matchRepository: matchRepository
        )
        self.session = store.session(for: matchId)
    }

    var shanghaiState: ShanghaiState? { session?.runtime.shanghaiState }

    var canSubmit: Bool { enteredDarts.count == 3 && canHumanInput }

    var canHumanInput: Bool {
        isCurrentPlayerBot == false && isBotPlaying == false && state == .readyTurn
    }

    var isCurrentPlayerBot: Bool {
        currentBotSkillProfile != nil
    }

    var currentBotSkillProfile: BotSkillProfile? {
        guard let session, let state = session.runtime.shanghaiState else { return nil }
        guard session.runtime.status == .inProgress else { return nil }
        let player = state.players[state.currentPlayerIndex]
        return DartBotEngine.botSkillProfile(
            playerId: player.playerId,
            in: session.runtime.participants
        )
    }

    var lockedSegment: Int? {
        shanghaiState?.currentRound
    }

    var headerText: String {
        guard let state = shanghaiState else { return "" }
        return L10n.format("play.shanghai.headerFormat", state.currentRound, state.currentRound)
    }

    var showsExtraRoundBadge: Bool {
        shanghaiState?.isExtraRound == true
    }

    var headerAccessibilityLabel: String {
        var parts = [L10n.string("play.shanghai.title"), headerText]
        if showsExtraRoundBadge {
            parts.append(L10n.string("play.shanghai.extraRound"))
        }
        if let scoringHint {
            parts.append(scoringHint)
        }
        return parts.joined(separator: ", ")
    }

    var scoringHint: String? {
        guard let target = shanghaiState?.currentRound else { return nil }
        return L10n.format(
            "play.shanghai.scoringHintFormat",
            target,
            target,
            target * 2,
            target * 3
        )
    }

    var goalReminder: String {
        L10n.string("play.shanghai.goalReminder")
    }

    var scoreboardRows: [ShanghaiScoreboardView.Row] {
        guard let session, let state = session.runtime.shanghaiState else { return [] }
        let isInProgress = session.runtime.status == .inProgress
        let showsRoundColumn = state.players.count < 6 && !state.isComplete
        return state.players.enumerated().map { index, player in
            let participant = participant(for: player.playerId)
            let isActive = index == state.currentPlayerIndex && isInProgress
            let roundPreview = showsRoundColumn
                ? previewRoundPoints(for: player, playerIndex: index, isActive: isActive, state: state)
                : nil
            return ShanghaiScoreboardView.Row(
                id: player.playerId,
                name: participant?.displayNameAtMatchStart ?? MatchConfigText.playerName(forIndex: index),
                cumulativePoints: player.cumulativePoints,
                roundPoints: roundPreview,
                isActive: isActive,
                isLeading: isPlayerLeading(playerIndex: index, state: state),
                colorToken: participant?.colorToken ?? PlayerColorToken.defaultForPlayer(id: player.playerId)
            )
        }
    }

    var showsRoundPointsColumn: Bool {
        guard let state = shanghaiState else { return false }
        return state.players.count < 6 && !state.isComplete
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
            matchType: .shanghai,
            category: .ui,
            eventName: "match_screen_appeared",
            message: "Shanghai match screen presented."
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

    func announceTurnIfNeeded(visitPoints: Int, cumulativePoints: Int) {
        let announcement = L10n.format(
            "play.shanghai.announce.turnFormat",
            visitPoints,
            cumulativePoints
        )
        postAccessibilityAnnouncement(announcement)
    }

    private func isPlayerLeading(playerIndex: Int, state: ShanghaiState) -> Bool {
        let maxPoints = state.players.map(\.cumulativePoints).max() ?? 0
        guard maxPoints > 0 else { return false }
        let leaderCount = state.players.filter { $0.cumulativePoints == maxPoints }.count
        return leaderCount == 1 && state.players[playerIndex].cumulativePoints == maxPoints
    }

    private func previewRoundPoints(
        for player: ShanghaiPlayerState,
        playerIndex: Int,
        isActive: Bool,
        state: ShanghaiState
    ) -> Int {
        guard MatchVisitPreview.includesActiveVisit(
            isActive: isActive,
            canHumanInput: canHumanInput,
            isBotPlaying: isBotPlaying,
            isCurrentPlayerBot: isCurrentPlayerBot
        ) else { return player.pointsThisRound }
        var preview = player.pointsThisRound
        for dart in enteredDarts {
            preview += previewPoints(for: dart, target: state.currentRound)
        }
        return preview
    }

    private func previewPoints(for dart: DartInput, target: Int) -> Int {
        if dart.isMiss { return 0 }
        guard case let .oneToTwenty(value) = dart.segment, value == target else { return 0 }
        switch dart.multiplier {
        case .single: return target
        case .double: return target * 2
        case .triple: return target * 3
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
        case .submittingTurn, .entryInvalid, .error, .matchCompleted, .shanghaiFeedback:
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
              let shanghaiState = session?.runtime.shanghaiState else { return false }

        isBotPlaying = true
        defer { isBotPlaying = false }

        let partialVisitCount = enteredDarts.count
        if partialVisitCount == 0 {
            enteredDarts.removeAll()
        }

        var rng = SystemRandomNumberGenerator()
        let plannedDarts = DartBotEngine.generateShanghaiTurn(
            targetSegment: shanghaiState.currentRound,
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

    private func submitTurnAsync(fromBotPlayback: Bool = false) async {
        await loadSessionIfNeeded()
        guard let current = session else {
            state = .error("shanghai.error.sessionMissing")
            return
        }
        state = .submittingTurn
        let darts = enteredDarts

        let outcome = await turnSubmitter.submitTurn(
            from: current,
            invalidTurnFallbackKey: "shanghai.error.invalidTurn"
        ) {
            try MatchLifecycleService.submitShanghaiTurn(session: current, darts: darts)
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
            if let event = lastShanghaiTurn(in: updated) {
                announceTurnIfNeeded(visitPoints: event.pointsThisVisit, cumulativePoints: event.cumulativePointsAfterTurn)
                if event.achievedShanghai {
                    postAccessibilityAnnouncement(L10n.string("play.shanghai.achieved"))
                    state = .shanghaiFeedback
                    try? await Task.sleep(nanoseconds: BotTurnPacing.shanghaiAchievementTransitionNanoseconds)
                }
            }
            if updated.runtime.status == .completed {
                state = .matchCompleted
            } else {
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
            scheduleBotPlaybackIfNeeded()
        } catch is CancellationError {
            state = .readyTurn
        } catch {
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "shanghai.error.undoFailed"))
        }
    }

    private func undoLastDartAsync() async {
        await loadSessionIfNeeded()
        guard let current = session else { return }
        if !enteredDarts.isEmpty {
            enteredDarts.removeLast()
            selectedMultiplier = .single
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
            resumeBotPlaybackAfterUndoIfNeeded()
        } catch is CancellationError {
            state = .readyTurn
        } catch {
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "shanghai.error.undoFailed"))
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
            matchType: .shanghai,
            store: store,
            logger: logger,
            matchRepository: matchRepository,
            statsRepository: statsRepository,
            sessionMissingFallbackKey: "shanghai.error.sessionMissing"
        ) {
        case let .loaded(loaded):
            session = loaded
        case .missing:
            break
        case let .failed(messageKey):
            state = .error(messageKey)
        }
    }

    private func lastShanghaiTurn(in session: MatchLifecycleSession) -> ShanghaiTurnEvent? {
        guard let envelope = session.events.last,
              case let .shanghaiTurn(event) = envelope.payload else { return nil }
        return event
    }
}

extension ShanghaiMatchViewModel: MatchPlaySessionHost {
    var isBotTurnBlocking: Bool { isBotPlaying || state == .submittingTurn }
    var hostMatchRepository: any MatchRepository { matchRepository }
    var hostMatchStore: ActiveMatchStore { store }
    var hostMatchLogger: any AppLogger { logger }
    var hostMatchType: MatchType { .shanghai }
}
