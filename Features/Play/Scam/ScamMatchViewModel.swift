import SwiftUI

@MainActor
final class ScamMatchViewModel: ObservableObject {
    enum State: Equatable {
        case readyTurn
        case entryInvalid(String)
        case submittingTurn
        case halfCompletedFeedback
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
            matchType: .scam,
            eventTypeRaw: "scamVisit",
            store: store,
            logger: logger,
            matchRepository: matchRepository
        )
        self.session = store.session(for: matchId)
    }

    var scamState: ScamState? { session?.runtime.scamState }

    var canSubmit: Bool { enteredDarts.count == 3 && canHumanInput }

    var canHumanInput: Bool {
        isCurrentPlayerBot == false && isBotPlaying == false && state == .readyTurn
    }

    var isCurrentPlayerBot: Bool { currentBotSkillProfile != nil }

    var currentBotSkillProfile: BotSkillProfile? {
        guard let session, let gameState = session.runtime.scamState else { return nil }
        guard session.runtime.status == .inProgress else { return nil }
        return DartBotEngine.botSkillProfile(
            playerId: gameState.currentPlayerId,
            in: session.runtime.participants
        )
    }

    var isStopperPhase: Bool { scamState?.currentRole == .stopper }

    var isScorerPhase: Bool { scamState?.currentRole == .scorer }

    var lockedSegment: Int? {
        guard isScorerPhase else { return nil }
        return scamState?.currentHalf.highestOpenSegment
    }

    var headerHalfText: String {
        guard let gameState = scamState else { return "" }
        return L10n.format("play.scam.halfFormat", gameState.halfIndex + 1)
    }

    var currentRoleName: String {
        guard let role = scamState?.currentRole else { return "" }
        switch role {
        case .stopper: return L10n.string("play.scam.role.stopper")
        case .scorer: return L10n.string("play.scam.role.scorer")
        }
    }

    var padHint: String {
        if isStopperPhase {
            return L10n.string("play.scam.pad.stopperHint")
        }
        if let segment = lockedSegment {
            return L10n.format("play.scam.pad.scorerHint", segment)
        }
        return ""
    }

    var headerAccessibilityLabel: String {
        [L10n.string("play.scam.navTitle"), headerHalfText, currentRoleName, padHint]
            .joined(separator: ", ")
    }

    var scoreboardRows: [ScamScoreboardView.Row] {
        guard let session, let gameState = session.runtime.scamState else { return [] }
        let isInProgress = session.runtime.status == .inProgress
        let maxScore = gameState.players.map(\.totalScore).max() ?? 0
        return gameState.players.enumerated().map { index, player in
            let participant = session.runtime.participant(for: player.playerId)
            let isActive = player.playerId == gameState.currentPlayerId && isInProgress
            let isLeading = maxScore > 0 && player.totalScore == maxScore
                && gameState.players.filter { $0.totalScore == maxScore }.count == 1
            let roleLabel: String? = {
                guard isActive else { return nil }
                return currentRoleName
            }()
            return ScamScoreboardView.Row(
                id: player.playerId,
                name: participant?.displayNameAtMatchStart ?? MatchConfigText.playerName(forIndex: index),
                totalScore: player.totalScore,
                isActive: isActive,
                isLeading: isLeading,
                roleLabel: roleLabel,
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
            matchType: .scam,
            category: .ui,
            eventName: "match_screen_appeared",
            message: "Scam match screen presented."
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
                matchType: .scam,
                category: .appLifecycle,
                eventName: "scam_abandon_failed",
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
        case .submittingTurn, .entryInvalid, .error, .matchCompleted, .halfCompletedFeedback:
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
              let gameState = session?.runtime.scamState else { return false }

        isBotPlaying = true
        defer { isBotPlaying = false }

        enteredDarts.removeAll()
        var rng = SystemRandomNumberGenerator()
        let plannedDarts: [DartInput]
        if gameState.currentRole == .scorer, let target = gameState.currentHalf.highestOpenSegment {
            plannedDarts = DartBotEngine.generateScamScorerTurn(
                targetSegment: target,
                profile: profile,
                rng: &rng
            )
        } else {
            plannedDarts = DartBotEngine.generateScamStopperTurn(
                closedSegments: gameState.currentHalf.closedSegments,
                profile: profile,
                rng: &rng
            )
        }

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
            state = .error("scam.error.sessionMissing")
            return
        }
        state = .submittingTurn
        let darts = enteredDarts

        let outcome = await turnSubmitter.submitTurn(
            from: current,
            invalidTurnFallbackKey: "scam.error.invalidTurn"
        ) {
            try MatchLifecycleService.submitScamVisit(session: current, darts: darts)
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
            if let event = lastScamVisit(in: updated) {
                announceVisitIfNeeded(event: event)
            }
            if updated.runtime.status == .completed {
                state = .matchCompleted
            } else if lastScamVisit(in: updated)?.halfCompleted == true {
                state = .halfCompletedFeedback
                postAccessibilityAnnouncement(L10n.string("play.scam.halfComplete"))
                try? await Task.sleep(nanoseconds: BotTurnPacing.shanghaiAchievementTransitionNanoseconds)
                state = .readyTurn
                if !fromBotPlayback { await playBotTurnIfNeeded() }
            } else {
                state = .readyTurn
                if !fromBotPlayback { await playBotTurnIfNeeded() }
            }
            enteredDarts.removeAll()
        }
    }

    private func announceVisitIfNeeded(event: ScamVisitEvent) {
        let announcement: String
        if event.role == .scorer, event.pointsAdded > 0 {
            announcement = L10n.format("play.scam.pointsThisVisitFormat", event.pointsAdded)
        } else if !event.segmentsClosedThisVisit.isEmpty {
            announcement = L10n.format(
                "play.scam.segmentClosedFormat",
                event.segmentsClosedThisVisit.count
            )
        } else {
            return
        }
        postAccessibilityAnnouncement(announcement)
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

    private func lastScamVisit(in session: MatchLifecycleSession) -> ScamVisitEvent? {
        guard let envelope = session.events.last,
              case let .scamVisit(event) = envelope.payload else { return nil }
        return event
    }
}
