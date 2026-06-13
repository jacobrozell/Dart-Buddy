import SwiftUI

@MainActor
final class AroundTheClockMatchViewModel: ObservableObject {
    enum State: Equatable {
        case readyTurn
        case entryInvalid(String)
        case submittingTurn
        case targetAdvancedFeedback
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
            matchType: .aroundTheClock,
            eventTypeRaw: "aroundTheClockTurn",
            store: store,
            logger: logger,
            matchRepository: matchRepository
        )
        self.session = store.session(for: matchId)
    }

    var aroundTheClockState: AroundTheClockState? { session?.runtime.aroundTheClockState }

    var canSubmit: Bool { enteredDarts.count == 3 && canHumanInput }

    var canHumanInput: Bool {
        isCurrentPlayerBot == false && isBotPlaying == false && state == .readyTurn
    }

    var isCurrentPlayerBot: Bool {
        currentBotSkillProfile != nil
    }

    var currentBotSkillProfile: BotSkillProfile? {
        guard let session, let atcState = session.runtime.aroundTheClockState else { return nil }
        guard session.runtime.status == .inProgress else { return nil }
        let player = atcState.players[atcState.currentPlayerIndex]
        return DartBotEngine.botSkillProfile(
            playerId: player.playerId,
            in: session.runtime.participants
        )
    }

    /// The current player's target segment value (1–20 or 25 for bull), including in-visit hits.
    var currentTarget: Int? {
        projectedPlayerState()?.currentTarget
    }

    /// Locked segment for the number pad (nil for bull target since the pad shows numbers 1–20).
    var lockedSegment: Int? {
        guard let target = currentTarget, target != 25 else { return nil }
        return target
    }

    /// Whether scoring segments should be disabled (sequence finished mid-visit).
    var scoringSegmentsDisabled: Bool {
        guard let atcState = aroundTheClockState else { return false }
        return (projectedPlayerState()?.targetIndex ?? 0) >= atcState.sequenceLength
    }

    /// Whether the current target is the bull finish.
    var isOnBullTarget: Bool {
        currentTarget == 25
    }

    var headerText: String {
        guard let target = currentTarget else { return "" }
        if target == 25 {
            return L10n.string("play.aroundTheClock.bullFinishEnabled")
        }
        return L10n.format("play.aroundTheClock.currentTargetFormat", target)
    }

    var headerAccessibilityLabel: String {
        var parts = [L10n.string("play.aroundTheClock.navTitle"), headerText]
        return parts.joined(separator: ", ")
    }

    var progressRows: [AroundTheClockSequenceStripView.Row] {
        guard let session, let atcState = session.runtime.aroundTheClockState else { return [] }
        let isInProgress = session.runtime.status == .inProgress
        return atcState.players.enumerated().map { index, player in
            let participant = participant(for: player.playerId)
            let isActive = index == atcState.currentPlayerIndex && isInProgress
            return AroundTheClockSequenceStripView.Row(
                id: player.playerId,
                name: participant?.displayNameAtMatchStart ?? MatchConfigText.playerName(forIndex: index),
                targetIndex: player.targetIndex,
                sequenceLength: atcState.sequenceLength,
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
        logger.matchDebug(
            matchId: matchId,
            matchType: .aroundTheClock,
            category: .ui,
            eventName: "match_screen_appeared",
            message: "Around the Clock match screen presented."
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
                matchType: .aroundTheClock,
                category: .appLifecycle,
                eventName: "aroundTheClock_abandon_failed",
                message: "Abandon failed.",
                metadata: MatchTurnSupport.appErrorMetadata(for: error)
            )
        }
    }

    func announceTargetAdvanceIfNeeded(targetBefore: Int, targetAfter: Int) {
        guard targetAfter > targetBefore else { return }
        let newTarget = targetAfter < 20 ? targetAfter + 1 : 25
        let announcement = L10n.format("play.aroundTheClock.targetAdvanced", newTarget)
        postAccessibilityAnnouncement(announcement)
    }

    private func participant(for playerId: UUID) -> MatchParticipant? {
        session?.runtime.participants.first { ($0.playerId ?? $0.id) == playerId }
    }

    /// Player state after applying in-progress darts for pad targeting.
    private func projectedPlayerState() -> AroundTheClockPlayerState? {
        guard let atcState = aroundTheClockState else { return nil }
        var player = atcState.players[atcState.currentPlayerIndex]
        for dart in enteredDarts {
            guard player.targetIndex < atcState.sequenceLength else { break }
            if AroundTheClockEngine.dartHitsTarget(dart, player: player, config: atcState.config) {
                player.targetIndex += 1
            }
        }
        guard player.targetIndex < atcState.sequenceLength else { return nil }
        return player
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
        case .submittingTurn, .entryInvalid, .error, .matchCompleted, .targetAdvancedFeedback:
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
              let atcState = session?.runtime.aroundTheClockState else { return false }

        isBotPlaying = true
        defer { isBotPlaying = false }

        enteredDarts.removeAll()
        var rng = SystemRandomNumberGenerator()
        let currentIndex = atcState.players[atcState.currentPlayerIndex].targetIndex
        let plannedDarts = DartBotEngine.generateAroundTheClockTurn(
            targetIndex: currentIndex,
            includeBullFinish: atcState.config.includeBullFinish,
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
            state = .error("aroundTheClock.error.sessionMissing")
            return
        }
        state = .submittingTurn
        let darts = enteredDarts

        let outcome = await turnSubmitter.submitTurn(
            from: current,
            invalidTurnFallbackKey: "aroundTheClock.error.invalidTurn"
        ) {
            try MatchLifecycleService.submitAroundTheClockTurn(session: current, darts: darts)
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
            if let event = lastAroundTheClockTurn(in: updated) {
                announceTargetAdvanceIfNeeded(
                    targetBefore: event.targetBefore,
                    targetAfter: event.targetAfter
                )
                if event.resetApplied {
                    postAccessibilityAnnouncement(L10n.string("play.aroundTheClock.progressReset"))
                }
                if event.targetAfter > event.targetBefore {
                    state = .targetAdvancedFeedback
                    try? await Task.sleep(nanoseconds: BotTurnPacing.briefModeFeedbackTransitionNanoseconds)
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
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "aroundTheClock.error.undoFailed"))
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
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "aroundTheClock.error.undoFailed"))
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
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "aroundTheClock.error.sessionMissing"))
        }
    }

    private func lastAroundTheClockTurn(in session: MatchLifecycleSession) -> AroundTheClockTurnEvent? {
        guard let envelope = session.events.last,
              case let .aroundTheClockTurn(event) = envelope.payload else { return nil }
        return event
    }
}