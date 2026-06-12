import SwiftUI

@MainActor
final class GolfMatchViewModel: ObservableObject {
    enum State: Equatable {
        case readyTurn
        case entryInvalid(String)
        case submittingTurn
        case holeCompleteFeedback
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
            matchType: .golf,
            eventTypeRaw: "golfTurn",
            store: store,
            logger: logger,
            matchRepository: matchRepository
        )
        self.session = store.session(for: matchId)
    }

    var golfState: GolfState? { session?.runtime.golfState }

    /// The player may submit after 1 dart (with endedEarly=true) or all 3, but only if human.
    var canSubmitEarly: Bool {
        enteredDarts.count >= 1 && enteredDarts.count < 3 && canHumanInput
    }

    var canSubmitFull: Bool {
        enteredDarts.count == 3 && canHumanInput
    }

    var canHumanInput: Bool {
        isCurrentPlayerBot == false && isBotPlaying == false && state == .readyTurn
    }

    var isCurrentPlayerBot: Bool {
        currentBotSkillProfile != nil
    }

    var currentBotSkillProfile: BotSkillProfile? {
        guard let session, let golfState = session.runtime.golfState else { return nil }
        guard session.runtime.status == .inProgress else { return nil }
        let player = golfState.players[golfState.currentPlayerIndex]
        return DartBotEngine.botSkillProfile(
            playerId: player.playerId,
            in: session.runtime.participants
        )
    }

    var lockedSegment: Int? { golfState?.currentHole }

    var currentHole: Int { golfState?.currentHole ?? 1 }

    var courseLength: Int { golfState?.config.courseLength.rawValue ?? 9 }

    var headerText: String {
        guard let state = golfState else { return "" }
        return L10n.format("play.golf.header.holeFormat", state.currentHole, state.config.courseLength.rawValue)
    }

    var lastDartHint: String {
        L10n.string("play.golf.lastDartCountsHint")
    }

    var headerAccessibilityLabel: String {
        var parts = [L10n.string("play.golf.navTitle"), headerText, lastDartHint]
        return parts.joined(separator: ", ")
    }

    /// Preview stroke count for the current dart entry (last entered dart).
    var currentStrokePreview: Int? {
        guard let last = enteredDarts.last, let hole = golfState?.currentHole else { return nil }
        return GolfEngine.strokesForLastDart(last, holeSegment: hole)
    }

    var scorecardRows: [GolfScorecardView.PlayerRow] {
        guard let session, let state = session.runtime.golfState else { return [] }
        let isInProgress = session.runtime.status == .inProgress
        return state.players.enumerated().map { index, player in
            let participant = participant(for: player.playerId)
            let isActive = index == state.currentPlayerIndex && isInProgress
            let holeStrokes: [Int?] = (1 ... state.config.courseLength.rawValue).map { hole in
                player.strokesByHole[hole]
            }
            return GolfScorecardView.PlayerRow(
                id: player.playerId,
                name: participant?.displayNameAtMatchStart ?? MatchConfigText.playerName(forIndex: index),
                holeStrokes: holeStrokes,
                runningTotal: player.runningTotal,
                isActive: isActive,
                isLeading: isPlayerLeading(playerIndex: index, state: state),
                colorToken: participant?.colorToken ?? PlayerColorToken.defaultForPlayer(id: player.playerId)
            )
        }
    }

    func submitTurn(endedEarly: Bool = false) async {
        await submitTurnAsync(endedEarly: endedEarly, fromBotPlayback: false)
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
            matchType: .golf,
            category: .ui,
            eventName: "match_screen_appeared",
            message: "Golf match screen presented."
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
                matchType: .golf,
                category: .appLifecycle,
                eventName: "golf_abandon_failed",
                message: "Abandon failed.",
                metadata: MatchTurnSupport.appErrorMetadata(for: error)
            )
        }
    }

    func announceHoleCompleteIfNeeded(strokes: Int) {
        let announcement = L10n.format("play.golf.announce.holeComplete", strokes)
        postAccessibilityAnnouncement(announcement)
    }

    private func isPlayerLeading(playerIndex: Int, state: GolfState) -> Bool {
        // In Golf, lowest strokes leads. Only show leader badge mid-game once hole 1 is done.
        let completedHoles = state.players[playerIndex].strokesByHole.count
        guard completedHoles > 0 else { return false }
        let minTotal = state.players.map(\.runningTotal).min() ?? 0
        let leaderCount = state.players.filter { $0.runningTotal == minTotal }.count
        return leaderCount == 1 && state.players[playerIndex].runningTotal == minTotal
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
        case .submittingTurn, .entryInvalid, .error, .matchCompleted, .holeCompleteFeedback:
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
              let golfState = session?.runtime.golfState else { return false }

        isBotPlaying = true
        defer { isBotPlaying = false }

        enteredDarts.removeAll()
        var rng = SystemRandomNumberGenerator()
        let planned = DartBotEngine.generateGolfTurn(
            holeSegment: golfState.currentHole,
            profile: profile,
            rng: &rng
        )

        let dartDelay = BotTurnPacing.dartDelayNanoseconds(staggerEnabled: feedbackPreferences.botStaggerEnabled)
        for dart in planned.darts {
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
        await submitTurnAsync(endedEarly: planned.endedEarly, fromBotPlayback: true)
        guard session?.runtime.status != .completed else { return false }
        return currentBotSkillProfile != nil && state == .readyTurn
    }

    private func submitTurnAsync(endedEarly: Bool, fromBotPlayback: Bool = false) async {
        await loadSessionIfNeeded()
        guard let current = session else {
            state = .error("golf.error.sessionMissing")
            return
        }
        state = .submittingTurn
        let darts = enteredDarts
        let input = GolfTurnInput(darts: darts, endedEarly: endedEarly)

        let outcome = await turnSubmitter.submitTurn(
            from: current,
            invalidTurnFallbackKey: "golf.error.invalidTurn"
        ) {
            try MatchLifecycleService.submitGolfTurn(session: current, input: input)
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
            if let event = lastGolfTurn(in: updated) {
                announceHoleCompleteIfNeeded(strokes: event.strokesRecorded)
                state = .holeCompleteFeedback
                try? await Task.sleep(nanoseconds: 600_000_000)
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
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "golf.error.undoFailed"))
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
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "golf.error.undoFailed"))
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
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "golf.error.sessionMissing"))
        }
    }

    private func lastGolfTurn(in session: MatchLifecycleSession) -> GolfTurnEvent? {
        guard let envelope = session.events.last,
              case let .golfTurn(event) = envelope.payload else { return nil }
        return event
    }
}