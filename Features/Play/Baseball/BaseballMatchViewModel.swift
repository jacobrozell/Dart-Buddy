import SwiftUI

@MainActor
final class BaseballMatchViewModel: ObservableObject {
    enum State: Equatable {
        case readyTurn
        case entryInvalid(String)
        case submittingTurn
        case stretchGateHint
        case perfectInningFeedback
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
            matchType: .baseball,
            eventTypeRaw: "baseballTurn",
            store: store,
            logger: logger,
            matchRepository: matchRepository
        )
        self.session = store.session(for: matchId)
    }

    var baseballState: BaseballState? { session?.runtime.baseballState }

    var canSubmit: Bool { enteredDarts.count == 3 && canHumanInput }

    var canHumanInput: Bool {
        isCurrentPlayerBot == false && isBotPlaying == false && state == .readyTurn
    }

    var isCurrentPlayerBot: Bool {
        currentBotSkillProfile != nil
    }

    var currentBotSkillProfile: BotSkillProfile? {
        guard let session, let state = session.runtime.baseballState else { return nil }
        guard session.runtime.status == .inProgress else { return nil }
        let player = state.players[state.currentPlayerIndex]
        return DartBotEngine.botSkillProfile(
            playerId: player.playerId,
            in: session.runtime.participants
        )
    }

    var lockedSegment: Int? {
        guard let state = baseballState else { return nil }
        switch state.phase {
        case .innings:
            return state.currentInning
        case .bullPlayoff:
            return 25
        case .completed:
            return nil
        }
    }

    var showsBullOnPad: Bool {
        guard let state = baseballState else { return false }
        switch state.phase {
        case .bullPlayoff:
            return true
        case .innings:
            return state.config.seventhInningStretch && state.currentInning == 7
        case .completed:
            return false
        }
    }

    var headerText: String {
        guard let state = baseballState else { return "" }
        switch state.phase {
        case .bullPlayoff:
            return L10n.string("play.baseball.header.bullPlayoff")
        case .innings, .completed:
            return L10n.format("play.baseball.headerFormat", state.currentInning, state.currentInning)
        }
    }

    var showsExtraInningBadge: Bool {
        baseballState?.isExtraInning == true && baseballState?.phase == .innings
    }

    var headerAccessibilityLabel: String {
        var parts = [L10n.string("play.baseball.title"), headerText]
        if showsExtraInningBadge {
            parts.append(L10n.string("play.baseball.extraInning"))
        }
        return parts.joined(separator: ", ")
    }

    var showsInningProgressStrip: Bool {
        baseballState?.phase == .innings
    }

    var stretchGateHint: String? {
        guard let state = baseballState,
              state.phase == .innings,
              state.config.seventhInningStretch,
              state.currentInning == 7,
              state.players[state.currentPlayerIndex].stretchGateOpen == false,
              canHumanInput || isBotPlaying else { return nil }
        return L10n.string("play.baseball.stretchGateHint")
    }

    var scoreboardRows: [BaseballScoreboardView.Row] {
        guard let session, let state = session.runtime.baseballState else { return [] }
        let isInProgress = session.runtime.status == .inProgress
        let showsVisitColumn = state.players.count < 6 && state.phase != .completed
        return state.players.enumerated().map { index, player in
            let participant = participant(for: player.playerId)
            let isActive = index == state.currentPlayerIndex && isInProgress
            let visitPreview = showsVisitColumn
                ? previewVisitRuns(for: player, playerIndex: index, isActive: isActive, state: state)
                : nil
            return BaseballScoreboardView.Row(
                id: player.playerId,
                name: participant?.displayNameAtMatchStart ?? MatchConfigText.playerName(forIndex: index),
                cumulativeRuns: player.cumulativeRuns,
                visitRuns: visitPreview?.runs,
                visitRunsKind: visitPreview?.kind,
                isActive: isActive,
                isLeading: isPlayerLeading(playerIndex: index, state: state),
                colorToken: participant?.colorToken ?? PlayerColorToken.defaultForPlayer(id: player.playerId)
            )
        }
    }

    var showsVisitRunsColumn: Bool {
        guard let state = baseballState else { return false }
        return state.players.count < 6 && state.phase != .completed
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
            matchType: .baseball,
            category: .ui,
            eventName: "match_screen_appeared",
            message: "Baseball match screen presented."
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
                matchType: .baseball,
                category: .appLifecycle,
                eventName: "baseball_abandon_failed",
                message: "Abandon failed.",
                metadata: MatchTurnSupport.appErrorMetadata(for: error)
            )
        }
    }

    func announceTurnIfNeeded(visitRuns: Int, cumulativeRuns: Int) {
        let announcement = L10n.format(
            "play.baseball.announce.turnFormat",
            visitRuns,
            cumulativeRuns
        )
        postAccessibilityAnnouncement(announcement)
    }

    private struct VisitRunsPreview {
        let runs: Int
        let kind: BaseballScoreboardView.VisitRunsKind
    }

    private func isPlayerLeading(playerIndex: Int, state: BaseballState) -> Bool {
        switch state.phase {
        case .bullPlayoff:
            let indices = state.playoffPlayerIndices
            guard indices.contains(playerIndex) else { return false }
            let scores = indices.map { playoffRuns(forLeading: $0, state: state) }
            guard let maxScore = scores.max(), maxScore > 0 else { return false }
            let leaders = indices.filter { playoffRuns(forLeading: $0, state: state) == maxScore }
            return leaders.count == 1 && leaders[0] == playerIndex
        case .innings:
            let maxRuns = state.players.map(\.cumulativeRuns).max() ?? 0
            guard maxRuns > 0 else { return false }
            let leaderCount = state.players.filter { $0.cumulativeRuns == maxRuns }.count
            return leaderCount == 1 && state.players[playerIndex].cumulativeRuns == maxRuns
        case .completed:
            return state.winnerPlayerId == state.players[playerIndex].playerId
        }
    }

    private func playoffRuns(forLeading playerIndex: Int, state: BaseballState) -> Int {
        var runs = state.players[playerIndex].playoffRunsThisRound
        if playerIndex == state.currentPlayerIndex, canHumanInput || isBotPlaying {
            for dart in enteredDarts {
                runs += previewRuns(for: dart, state: state, playerIndex: playerIndex)
            }
        }
        return runs
    }

    private func previewVisitRuns(
        for player: BaseballPlayerState,
        playerIndex: Int,
        isActive: Bool,
        state: BaseballState
    ) -> VisitRunsPreview? {
        switch state.phase {
        case .bullPlayoff:
            guard state.playoffPlayerIndices.contains(playerIndex) else { return nil }
            var preview = player.playoffRunsThisRound
            if isActive, canHumanInput || isBotPlaying {
                for dart in enteredDarts {
                    preview += previewRuns(for: dart, state: state, playerIndex: playerIndex)
                }
            }
            return VisitRunsPreview(runs: preview, kind: .playoffRound)
        case .innings:
            let runs = previewRunsThisInning(for: player, isActive: isActive)
            return VisitRunsPreview(runs: runs, kind: .inning)
        case .completed:
            return nil
        }
    }

    private func previewRunsThisInning(for player: BaseballPlayerState, isActive: Bool) -> Int {
        guard isActive, canHumanInput || isBotPlaying else { return player.runsThisInning }
        guard let state = baseballState, isActive else { return player.runsThisInning }
        var preview = player.runsThisInning
        for dart in enteredDarts {
            preview += previewRuns(for: dart, state: state, playerIndex: state.currentPlayerIndex)
        }
        return preview
    }

    private func previewRuns(for dart: DartInput, state: BaseballState, playerIndex: Int) -> Int {
        if dart.isMiss { return 0 }
        switch state.phase {
        case .bullPlayoff:
            switch dart.segment {
            case .outerBull: return 1
            case .innerBull: return 2
            default: return 0
            }
        case .innings:
            let target = state.currentInning
            if state.config.seventhInningStretch, target == 7, !state.players[playerIndex].stretchGateOpen {
                if dart.segment == .outerBull || dart.segment == .innerBull { return 0 }
                if case let .oneToTwenty(value) = dart.segment, value == target { return 0 }
                return 0
            }
            if case let .oneToTwenty(value) = dart.segment, value == target {
                switch dart.multiplier {
                case .single: return 1
                case .double: return 2
                case .triple: return 3
                }
            }
            return 0
        case .completed:
            return 0
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
        case .submittingTurn, .entryInvalid, .error, .matchCompleted, .stretchGateHint, .perfectInningFeedback:
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
              let baseballState = session?.runtime.baseballState else { return false }

        isBotPlaying = true
        defer { isBotPlaying = false }

        enteredDarts.removeAll()
        var rng = SystemRandomNumberGenerator()
        let plannedDarts = DartBotEngine.generateBaseballTurn(
            targetSegment: baseballState.phase == .bullPlayoff ? 25 : baseballState.currentInning,
            phase: baseballState.phase,
            stretchGateOpen: baseballState.players[baseballState.currentPlayerIndex].stretchGateOpen,
            seventhInningStretch: baseballState.config.seventhInningStretch,
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
            state = .error("baseball.error.sessionMissing")
            return
        }
        state = .submittingTurn
        let darts = enteredDarts
        let playerIndex = current.runtime.baseballState?.currentPlayerIndex

        let outcome = await turnSubmitter.submitTurn(
            from: current,
            invalidTurnFallbackKey: "baseball.error.invalidTurn"
        ) {
            try MatchLifecycleService.submitBaseballTurn(session: current, darts: darts)
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
            if let event = lastBaseballTurn(in: updated) {
                announceTurnIfNeeded(visitRuns: event.runsThisVisit, cumulativeRuns: event.cumulativeRunsAfterTurn)
                if event.runsThisVisit == 9 {
                    state = .perfectInningFeedback
                    try? await Task.sleep(nanoseconds: 800_000_000)
                }
            }
            if updated.runtime.status == .completed {
                state = .matchCompleted
            } else {
                if updated.runtime.baseballState?.config.seventhInningStretch == true,
                   updated.runtime.baseballState?.currentInning == 7,
                   playerIndex.flatMap({ updated.runtime.baseballState?.players[$0].stretchGateOpen }) == false,
                   darts.contains(where: { $0.segment == .outerBull || $0.segment == .innerBull }) {
                    state = .stretchGateHint
                    try? await Task.sleep(nanoseconds: 600_000_000)
                }
                state = .readyTurn
                if updated.runtime.status != .completed, !fromBotPlayback {
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
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "baseball.error.undoFailed"))
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
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "baseball.error.undoFailed"))
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
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "baseball.error.sessionMissing"))
        }
    }

    private func lastBaseballTurn(in session: MatchLifecycleSession) -> BaseballTurnEvent? {
        guard let envelope = session.events.last,
              case let .baseballTurn(event) = envelope.payload else { return nil }
        return event
    }
}

private func postAccessibilityAnnouncement(_ text: String) {
    UIAccessibility.post(notification: .announcement, argument: text)
}
