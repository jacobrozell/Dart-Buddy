import SwiftUI

@MainActor
final class HareAndHoundsMatchViewModel: ObservableObject {
    enum State: Equatable {
        case readyTurn
        case entryInvalid(String)
        case submittingTurn
        case positionAdvancedFeedback
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
            matchType: .hareAndHounds,
            eventTypeRaw: "hareAndHoundsTurn",
            store: store,
            logger: logger,
            matchRepository: matchRepository
        )
        self.session = store.session(for: matchId)
    }

    var hareAndHoundsState: HareAndHoundsState? { session?.runtime.hareAndHoundsState }

    var canSubmit: Bool { enteredDarts.count == 3 && canHumanInput }

    var canHumanInput: Bool {
        isCurrentPlayerBot == false && isBotPlaying == false && state == .readyTurn
    }

    var isCurrentPlayerBot: Bool {
        currentBotSkillProfile != nil
    }

    var currentBotSkillProfile: BotSkillProfile? {
        guard let session, let gameState = session.runtime.hareAndHoundsState else { return nil }
        guard session.runtime.status == .inProgress else { return nil }
        let player = gameState.players[gameState.currentPlayerIndex]
        return DartBotEngine.botSkillProfile(
            playerId: player.playerId,
            in: session.runtime.participants
        )
    }

    /// The locked segment for the number pad (effective course segment during entry).
    var lockedSegment: Int? {
        guard !scoringSegmentsDisabled else { return nil }
        return projectedPositionIndex().map { MatchConfigHareAndHounds.clockwiseCourse[$0] }
    }

    var scoringSegmentsDisabled: Bool {
        projectedVisitOutcome()?.wouldCompleteMatch == true
    }

    var headerText: String {
        guard let gameState = hareAndHoundsState else { return "" }
        let player = gameState.players[gameState.currentPlayerIndex]
        let roleKey = player.role == .hare ? "role.hare" : "role.hound"
        let segment = lockedSegment ?? player.currentSegment
        return L10n.format(
            "play.hareAndHounds.trackPositionFormat",
            L10n.string(roleKey),
            segment
        )
    }

    var headerAccessibilityLabel: String {
        [L10n.string("play.hareAndHounds.navTitle"), headerText]
            .joined(separator: ", ")
    }

    /// Track display rows for the dual-track progress view.
    var trackRows: [HareAndHoundsDualTrackView.Row] {
        guard let session, let gameState = session.runtime.hareAndHoundsState else { return [] }
        let isInProgress = session.runtime.status == .inProgress
        return gameState.players.enumerated().map { index, player in
            let participant = participant(for: player.playerId)
            let isActive = index == gameState.currentPlayerIndex && isInProgress
            return HareAndHoundsDualTrackView.Row(
                id: player.playerId,
                name: participant?.displayNameAtMatchStart ?? MatchConfigText.playerName(forIndex: index),
                role: player.role,
                positionIndex: player.positionIndex,
                isActive: isActive,
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
            matchType: .hareAndHounds,
            category: .ui,
            eventName: "match_screen_appeared",
            message: "Hare and Hounds match screen presented."
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


    func announcePositionChangeIfNeeded(positionBefore: Int, positionAfter: Int, role: HareAndHoundsRole) {
        guard positionAfter != positionBefore else { return }
        let segment = MatchConfigHareAndHounds.clockwiseCourse[positionAfter % HareAndHoundsState.courseLength]
        let announcement = L10n.format("play.hareAndHounds.segmentAdvance", segment)
        postAccessibilityAnnouncement(announcement)
    }

    private func participant(for playerId: UUID) -> MatchParticipant? {
        session?.runtime.participants.first { ($0.playerId ?? $0.id) == playerId }
    }

    private struct ProjectedVisitOutcome {
        var positionIndex: Int
        var wouldCompleteMatch: Bool
    }

    private func projectedVisitOutcome() -> ProjectedVisitOutcome? {
        guard let gameState = hareAndHoundsState else { return nil }
        let playerIndex = gameState.currentPlayerIndex
        var positionIndex = gameState.players[playerIndex].positionIndex
        let role = gameState.players[playerIndex].role
        let courseLength = HareAndHoundsState.courseLength

        for dart in enteredDarts {
            let segment = MatchConfigHareAndHounds.clockwiseCourse[positionIndex]
            guard HareAndHoundsEngine.dartHitsSegment(dart, segment: segment) else { continue }

            let newIndex = positionIndex + 1
            if newIndex >= courseLength {
                if role == .hare {
                    return ProjectedVisitOutcome(positionIndex: 0, wouldCompleteMatch: true)
                }
                positionIndex = 0
            } else {
                positionIndex = newIndex
                if role == .hound, let hareIndex = gameState.harePlayer?.positionIndex {
                    let chaseDistance = (hareIndex - positionIndex + courseLength) % courseLength
                    if chaseDistance == 0 {
                        return ProjectedVisitOutcome(positionIndex: positionIndex, wouldCompleteMatch: true)
                    }
                }
            }
        }
        return ProjectedVisitOutcome(positionIndex: positionIndex, wouldCompleteMatch: false)
    }

    private func projectedPositionIndex() -> Int? {
        projectedVisitOutcome()?.positionIndex
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
        case .submittingTurn, .entryInvalid, .error, .matchCompleted, .positionAdvancedFeedback:
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
              let gameState = session?.runtime.hareAndHoundsState else { return false }

        isBotPlaying = true
        defer { isBotPlaying = false }

        enteredDarts.removeAll()
        var rng = SystemRandomNumberGenerator()
        let player = gameState.players[gameState.currentPlayerIndex]
        let plannedDarts = DartBotEngine.generateHareAndHoundsTurn(
            positionIndex: player.positionIndex,
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
            state = .error("hareAndHounds.error.sessionMissing")
            return
        }
        state = .submittingTurn
        let darts = enteredDarts

        let outcome = await turnSubmitter.submitTurn(
            from: current,
            invalidTurnFallbackKey: "hareAndHounds.error.invalidTurn"
        ) {
            try MatchLifecycleService.submitHareAndHoundsTurn(session: current, darts: darts)
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
            if let event = lastHareAndHoundsTurn(in: updated) {
                announcePositionChangeIfNeeded(
                    positionBefore: event.positionBefore,
                    positionAfter: event.positionAfter,
                    role: event.role
                )
                if event.positionAfter != event.positionBefore {
                    state = .positionAdvancedFeedback
                    try? await Task.sleep(nanoseconds: BotTurnPacing.briefModeFeedbackDelayNanoseconds(feedbackPreferences: feedbackPreferences))
                }
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
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "hareAndHounds.error.undoFailed"))
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
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "hareAndHounds.error.undoFailed"))
        }
    }

    func loadSessionIfNeeded() async {
        if session != nil { return }
        switch await MatchSessionLoader.load(
            matchId: matchId,
            matchType: .hareAndHounds,
            store: store,
            logger: logger,
            matchRepository: matchRepository,
            statsRepository: statsRepository,
            sessionMissingFallbackKey: "hareAndHounds.error.sessionMissing"
        ) {
        case let .loaded(loaded):
            session = loaded
        case .missing:
            break
        case let .failed(messageKey):
            state = .error(messageKey)
        }
    }

    private func lastHareAndHoundsTurn(in session: MatchLifecycleSession) -> HareAndHoundsTurnEvent? {
        guard let envelope = session.events.last,
              case let .hareAndHoundsTurn(event) = envelope.payload else { return nil }
        return event
    }
}
extension HareAndHoundsMatchViewModel: MatchPlaySessionHost {
    var isBotTurnBlocking: Bool { isBotPlaying || state == .submittingTurn }
    var hostMatchRepository: any MatchRepository { matchRepository }
    var hostMatchStore: ActiveMatchStore { store }
    var hostMatchLogger: any AppLogger { logger }
    var hostMatchType: MatchType { .hareAndHounds }
}
