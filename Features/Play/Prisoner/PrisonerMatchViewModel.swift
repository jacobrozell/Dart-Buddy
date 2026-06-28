import SwiftUI

@MainActor
final class PrisonerMatchViewModel: ObservableObject {
    enum State: Equatable {
        case readyTurn
        case entryInvalid(String)
        case submittingTurn
        case matchCompleted
        case error(String)
    }

    @Published private(set) var state: State = .readyTurn
    @Published var selectedMultiplier: DartMultiplier = .single
    @Published var enteredDarts: [DartInput] = []
    @Published private(set) var submittedHits: [PrisonerDartHit] = []
    @Published var showRingPicker = false
    @Published private(set) var pendingRingPickerDart: DartInput?
    @Published private(set) var pendingRingSegment: Int?
    @Published private(set) var session: MatchLifecycleSession?
    @Published private(set) var isBotPlaying = false

    private let matchId: UUID
    private let store: ActiveMatchStore
    private let logger: any AppLogger
    private let matchRepository: any MatchRepository
    private let statsRepository: any StatsRepository
    private let feedbackPreferences: FeedbackPreferences
    private let visitSubmitter: MatchTurnSubmitter
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
        self.visitSubmitter = MatchTurnSubmitter(
            matchId: matchId,
            matchType: .prisoner,
            eventTypeRaw: "prisonerVisit",
            store: store,
            logger: logger,
            matchRepository: matchRepository
        )
        self.session = store.session(for: matchId)
    }

    var prisonerState: PrisonerState? { session?.runtime.prisonerState }

    var maxDartsPerSubmission: Int {
        prisonerState?.dartsAvailableThisVisit ?? 3
    }

    var canSubmit: Bool {
        !submittedHits.isEmpty
            && submittedHits.count == enteredDarts.count
            && submittedHits.count <= maxDartsPerSubmission
            && canHumanInput
    }

    var canHumanInput: Bool {
        isCurrentPlayerBot == false && isBotPlaying == false && state == .readyTurn && !showRingPicker
    }

    var isCurrentPlayerBot: Bool {
        currentBotSkillProfile != nil
    }

    var currentBotSkillProfile: BotSkillProfile? {
        guard let session, let gameState = session.runtime.prisonerState else { return nil }
        guard session.runtime.status == .inProgress else { return nil }
        let player = gameState.players[gameState.currentPlayerIndex]
        guard !player.hasFinished else { return nil }
        return DartBotEngine.botSkillProfile(
            playerId: player.playerId,
            in: session.runtime.participants
        )
    }

    var headerText: String {
        guard let gameState = prisonerState else { return "" }
        let playerId = gameState.currentPlayer.playerId
        let name = participantName(for: playerId)
        return L10n.format("play.prisoner.throwFormat", name)
    }

    var scoreboardRows: [PrisonerScoreboardView.Row] {
        guard let session, let gameState = session.runtime.prisonerState else { return [] }
        let isInProgress = session.runtime.status == .inProgress
        let sequenceLength = MatchConfigPrisoner.clockwiseSequence.count
        return gameState.players.enumerated().map { index, player in
            let participant = participant(for: player.playerId)
            let isActive = index == gameState.currentPlayerIndex && isInProgress && !player.hasFinished
            return PrisonerScoreboardView.Row(
                id: player.playerId,
                name: participant?.displayNameAtMatchStart ?? MatchConfigText.playerName(forIndex: index),
                progressIndex: player.progressIndex,
                sequenceLength: sequenceLength,
                pool: player.pool,
                isActive: isActive,
                colorToken: participant?.colorToken ?? PlayerColorToken.defaultForPlayer(id: player.playerId),
                hasFinished: player.hasFinished
            )
        }
    }

    var prisonerRows: [PrisonerPrisonersListView.Row] {
        guard let session, let gameState = session.runtime.prisonerState else { return [] }
        return gameState.prisoners.map { prisoner in
            let label = prisoner.segment == MatchConfigPrisoner.bullSegment
                ? L10n.string("play.prisoner.bullSegmentLabel")
                : String(prisoner.segment)
            let owner = participant(for: prisoner.ownerPlayerId)?.displayNameAtMatchStart
                ?? L10n.string("play.match.unknownPlayer")
            return PrisonerPrisonersListView.Row(
                id: prisoner.segment,
                segmentLabel: label,
                ownerName: owner
            )
        }
    }

    func processDartEntry(previousCount: Int) {
        guard enteredDarts.count > previousCount,
              let dart = enteredDarts.last,
              canHumanInput || isBotPlaying else { return }
        resolveHit(for: dart, autoSubmit: true)
    }

    func confirmRingHit(_ hit: PrisonerDartHit) {
        submittedHits.append(hit)
        clearPendingRingPicker()
        autoSubmitIfReady()
    }

    func cancelRingPicker() {
        if pendingRingPickerDart != nil {
            enteredDarts.removeLast()
        }
        clearPendingRingPicker()
    }

    func submitTurn() async {
        await submitVisitAsync()
    }

    func undoLastTurn() async {
        await undoLastTurnAsync()
    }

    func undoLastDart() async {
        guard canHumanInput, !enteredDarts.isEmpty else { return }
        enteredDarts.removeLast()
        if !submittedHits.isEmpty {
            submittedHits.removeLast()
        }
        clearPendingRingPicker()
    }

    func onAppear() async {
        logger.matchInfo(
            matchId: matchId,
            matchType: .prisoner,
            category: .ui,
            eventName: "match_screen_appeared",
            message: "Prisoner match screen presented."
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
                matchType: .prisoner,
                category: .appLifecycle,
                eventName: "prisoner_abandon_failed",
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
        submittedHits = []
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
        submittedHits.removeAll()
        clearPendingRingPicker()
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
              let gameState = session?.runtime.prisonerState else { return false }

        isBotPlaying = true
        defer { isBotPlaying = false }

        enteredDarts.removeAll()
        submittedHits.removeAll()
        var rng = SystemRandomNumberGenerator()
        let plannedHits = DartBotEngine.generatePrisonerVisit(
            state: gameState,
            profile: profile,
            rng: &rng
        )

        let dartDelay = BotTurnPacing.dartDelayNanoseconds(feedbackPreferences: feedbackPreferences)
        for hit in plannedHits {
            do {
                try await Task.sleep(nanoseconds: dartDelay)
            } catch {
                return false
            }
            enteredDarts.append(dartInput(for: hit))
            submittedHits.append(hit)
        }

        do {
            try await Task.sleep(nanoseconds: BotTurnPacing.submitDelayNanoseconds(feedbackPreferences: feedbackPreferences))
        } catch {
            return false
        }
        await submitVisitAsync(fromBotPlayback: true)
        guard session?.runtime.status != .completed else { return false }
        return currentBotSkillProfile != nil && state == .readyTurn
    }

    private func resolveHit(for dart: DartInput, autoSubmit: Bool) {
        if dart.isMiss {
            submittedHits.append(.outsideDouble)
            if autoSubmit { autoSubmitIfReady() }
            return
        }
        switch dart.segment {
        case .innerBull, .outerBull:
            submittedHits.append(.bull)
            if autoSubmit { autoSubmitIfReady() }
        case .miss:
            submittedHits.append(.outsideDouble)
            if autoSubmit { autoSubmitIfReady() }
        case let .oneToTwenty(segment):
            switch dart.multiplier {
            case .double, .triple:
                submittedHits.append(.playable(segment: segment))
                if autoSubmit { autoSubmitIfReady() }
            case .single:
                pendingRingPickerDart = dart
                pendingRingSegment = segment
                showRingPicker = true
            }
        }
    }

    private func clearPendingRingPicker() {
        pendingRingPickerDart = nil
        pendingRingSegment = nil
        showRingPicker = false
    }

    private func autoSubmitIfReady() {
        guard submittedHits.count == maxDartsPerSubmission else { return }
        Task { await submitVisitAsync() }
    }

    private func submitVisitAsync(fromBotPlayback: Bool = false) async {
        await loadSessionIfNeeded()
        guard let current = session else {
            state = .error("prisoner.error.sessionMissing")
            return
        }
        state = .submittingTurn
        let hits = submittedHits

        let outcome = await visitSubmitter.submitTurn(
            from: current,
            invalidTurnFallbackKey: "prisoner.error.invalidVisit"
        ) {
            try MatchLifecycleService.submitPrisonerVisit(session: current, hits: hits)
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
            if let event = lastVisit(in: updated) {
                announceVisitIfNeeded(event: event)
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
            submittedHits.removeAll()
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
            submittedHits.removeAll()
            scheduleBotPlaybackIfNeeded()
        } catch is CancellationError {
            state = .readyTurn
        } catch {
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "prisoner.error.invalidVisit"))
        }
    }

    private func loadSessionIfNeeded() async {
        if session == nil {
            session = store.session(for: matchId)
        }
    }

    private func participant(for playerId: UUID) -> MatchParticipant? {
        session?.runtime.participant(for: playerId)
    }

    private func participantName(for playerId: UUID) -> String {
        participant(for: playerId)?.displayNameAtMatchStart
            ?? L10n.string("play.match.unknownPlayer")
    }

    private func lastVisit(in session: MatchLifecycleSession) -> PrisonerVisitEvent? {
        guard case let .prisonerVisit(event) = session.events.last?.payload else { return nil }
        return event
    }

    private func announceVisitIfNeeded(event: PrisonerVisitEvent) {
        if !event.prisonersCaptured.isEmpty {
            postAccessibilityAnnouncement(L10n.string("play.prisoner.prisonerCaptured"))
        }
        if !event.prisonersCreated.isEmpty {
            postAccessibilityAnnouncement(L10n.string("play.prisoner.prisonerOnBoard"))
        }
        if event.dartsLost > 0 {
            postAccessibilityAnnouncement(L10n.string("play.prisoner.dartLostOneTurn"))
        }
    }

    private func postAccessibilityAnnouncement(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    private func dartInput(for hit: PrisonerDartHit) -> DartInput {
        switch hit {
        case let .playable(segment):
            return DartInput(multiplier: .single, segment: .oneToTwenty(segment))
        case let .innerSingle(segment):
            return DartInput(multiplier: .single, segment: .oneToTwenty(segment))
        case .bull:
            return DartInput(multiplier: .single, segment: .outerBull)
        case .outsideDouble:
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
    }
}
