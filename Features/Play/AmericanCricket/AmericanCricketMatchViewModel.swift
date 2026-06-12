import SwiftUI

@MainActor
final class AmericanCricketMatchViewModel: ObservableObject {
    enum State: Equatable {
        case readyTurn
        case entryInvalid(String)
        case submittingTurn
        case targetAdvanced
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
            matchType: .americanCricket,
            eventTypeRaw: "americanCricketTurn",
            store: store,
            logger: logger,
            matchRepository: matchRepository
        )
        self.session = store.session(for: matchId)
    }

    // MARK: - Accessors

    var americanCricketState: AmericanCricketState? { session?.runtime.americanCricketState }

    var canSubmit: Bool { !enteredDarts.isEmpty && canHumanInput }

    var canHumanInput: Bool {
        isCurrentPlayerBot == false && isBotPlaying == false && state == .readyTurn
    }

    var isCurrentPlayerBot: Bool { currentBotSkillProfile != nil }

    var currentBotSkillProfile: BotSkillProfile? {
        guard let session, let acState = session.runtime.americanCricketState else { return nil }
        guard session.runtime.status == .inProgress else { return nil }
        let player = acState.players[acState.currentPlayerIndex]
        return DartBotEngine.botSkillProfile(
            playerId: player.playerId,
            in: session.runtime.participants
        )
    }

    // MARK: - Presentation

    var activeTargetLabel: String {
        guard let acState = americanCricketState else { return "" }
        let target = acState.activeTarget
        let segment = acState.activeTargetIndex + 1
        let labelValue = target == .bull
            ? L10n.string("cricket.target.bull")
            : target.rawValue
        return L10n.format(
            "play.americanCricket.header.activeTargetFormat",
            labelValue,
            segment,
            americanCricketTargets.count
        )
    }

    var boardColumns: [AmericanCricketBoardView.Column] {
        guard let session, let acState = session.runtime.americanCricketState else { return [] }
        let isInProgress = session.runtime.status == .inProgress
        return acState.players.enumerated().map { index, player in
            let participant = participant(for: player.playerId)
            let isActive = index == acState.currentPlayerIndex && isInProgress
            return AmericanCricketBoardView.Column(
                id: player.playerId,
                name: participant?.displayNameAtMatchStart ?? MatchConfigText.playerName(forIndex: index),
                marks: player.marks,
                score: player.cumulativePoints,
                isActive: isActive,
                colorToken: participant?.colorToken ?? PlayerColorToken.defaultForPlayer(id: player.playerId),
                activeTargetIndex: acState.activeTargetIndex
            )
        }
    }

    var activeBoardColumnID: UUID? {
        boardColumns.first(where: \.isActive)?.id
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
            matchType: .americanCricket,
            category: .ui,
            eventName: "match_screen_appeared",
            message: "American Cricket match screen presented."
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
            logger.matchInfo(
                matchId: matchId,
                matchType: .americanCricket,
                category: .appLifecycle,
                eventName: "match_abandoned",
                message: "American Cricket match abandoned by user.",
                metadata: ["eventCount": String(abandoned.runtime.eventCount)]
            )
        } catch {
            logger.matchError(
                matchId: matchId,
                matchType: .americanCricket,
                category: .appLifecycle,
                eventName: "americanCricket_abandon_failed",
                message: "Abandon failed.",
                metadata: MatchTurnSupport.appErrorMetadata(for: error)
            )
        }
    }

    // MARK: - Private

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
              let acState = session?.runtime.americanCricketState else { return false }

        isBotPlaying = true
        defer { isBotPlaying = false }
        logger.matchDebug(
            matchId: matchId,
            matchType: .americanCricket,
            eventName: "bot_turn_started",
            message: "Bot visit generation started."
        )

        enteredDarts.removeAll()
        var rng = SystemRandomNumberGenerator()
        let plannedDarts = DartBotEngine.generateAmericanCricketTurn(
            state: acState,
            playerIndex: acState.currentPlayerIndex,
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
            logger.matchError(
                matchId: matchId,
                matchType: .americanCricket,
                eventName: "match_session_missing",
                message: "Submit attempted without a loaded session."
            )
            state = .error("americanCricket.error.sessionMissing")
            return
        }
        state = .submittingTurn
        let darts = enteredDarts
        let activeTargetBefore = current.runtime.americanCricketState?.activeTargetIndex

        let outcome = await turnSubmitter.submitTurn(
            from: current,
            invalidTurnFallbackKey: "americanCricket.error.invalidTurn"
        ) {
            try MatchLifecycleService.submitAmericanCricketTurn(session: current, darts: darts)
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
            let activeTargetAfter = updated.runtime.americanCricketState?.activeTargetIndex
            if updated.runtime.status == .completed {
                logger.matchInfo(
                    matchId: matchId,
                    matchType: .americanCricket,
                    category: .appLifecycle,
                    eventName: "match_completed",
                    message: "American Cricket match completed.",
                    metadata: MatchTurnSupport.matchProgressMetadata(for: updated)
                )
                state = .matchCompleted
            } else {
                let didAdvance = activeTargetBefore != activeTargetAfter
                if didAdvance {
                    state = .targetAdvanced
                    try? await Task.sleep(nanoseconds: BotTurnPacing.cricketClosureDelayNanoseconds())
                }
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
            logger.matchDebug(
                matchId: matchId,
                matchType: .americanCricket,
                eventName: "turn_undone",
                message: "Last turn undone.",
                metadata: MatchTurnSupport.matchProgressMetadata(for: undone)
            )
            await playBotTurnIfNeeded()
        } catch is CancellationError {
            state = .readyTurn
        } catch {
            logger.matchError(
                matchId: matchId,
                matchType: .americanCricket,
                eventName: "turn_undo_failed",
                message: "Undo failed.",
                metadata: MatchTurnSupport.appErrorMetadata(for: error)
            )
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "americanCricket.error.undoFailed"))
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
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "americanCricket.error.undoFailed"))
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
        case .submittingTurn, .entryInvalid, .error, .matchCompleted, .targetAdvanced:
            state = .readyTurn
        default:
            break
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
            logger.matchInfo(
                matchId: matchId,
                matchType: .americanCricket,
                eventName: "match_session_rehydrated",
                message: "Rehydrated session from snapshot.",
                metadata: ["eventCount": String(rehydrated.runtime.eventCount)]
            )
        } catch {
            logger.matchError(
                matchId: matchId,
                matchType: .americanCricket,
                eventName: "match_session_load_failed",
                message: "Failed to load match session.",
                metadata: MatchTurnSupport.appErrorMetadata(for: error)
            )
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "americanCricket.error.sessionMissing"))
        }
    }

    private func participant(for playerId: UUID) -> MatchParticipant? {
        session?.runtime.participants.first { ($0.playerId ?? $0.id) == playerId }
    }
}
