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
    @Published var session: MatchLifecycleSession?
    @Published private(set) var isBotPlaying = false
    /// Recorded hole result shown while `holeCompleteFeedback` is active.
    @Published private(set) var holeCompleteFeedback: (hole: Int, strokes: Int)?

    let matchId: UUID
    private let sessionController: MatchSessionController

    init(
        matchId: UUID,
        store: ActiveMatchStore,
        logger: any AppLogger,
        matchRepository: any MatchRepository,
        statsRepository: any StatsRepository,
        feedbackPreferences: FeedbackPreferences = FeedbackPreferences()
    ) {
        self.matchId = matchId
        self.sessionController = MatchSessionController(
            matchId: matchId,
            matchType: .golf,
            eventTypeRaw: "golfTurn",
            store: store,
            logger: logger,
            matchRepository: matchRepository,
            statsRepository: statsRepository,
            feedbackPreferences: feedbackPreferences,
            errorKeys: MatchSessionErrorKeys(
                sessionMissing: "golf.error.sessionMissing",
                undoFailed: "golf.error.undoFailed",
                invalidTurn: "golf.error.invalidTurn"
            ),
            screenAppearedMessage: "Golf match screen presented."
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
        let holeLine = L10n.format("play.golf.header.holeFormat", state.currentHole, state.config.courseLength.rawValue)
        let targetLine = L10n.format("play.golf.header.targetFormat", state.currentHole)
        return "\(holeLine) · \(targetLine)"
    }

    var lastDartHint: String {
        L10n.string("play.golf.lastDartCountsHint")
    }

    var headerAccessibilityLabel: String {
        let parts = [L10n.string("play.golf.navTitle"), headerText, lastDartHint]
        return parts.joined(separator: ", ")
    }

    /// Preview stroke count for the in-progress visit (last entered dart on the current hole).
    var currentStrokePreview: Int? {
        guard let last = enteredDarts.last, let hole = lockedSegment else { return nil }
        return GolfEngine.strokesForLastDart(last, holeSegment: hole)
    }

    var holeCompleteFeedbackText: String? {
        guard let feedback = holeCompleteFeedback else { return nil }
        return L10n.format(
            "play.golf.announce.holeCompleteDetail",
            feedback.hole,
            GolfStrokePresentation.label(for: feedback.strokes),
            feedback.strokes
        )
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
        await sessionController.undoLastTurn(
            getSession: { session },
            setSession: { session = $0 },
            setReadyTurn: { state = .readyTurn },
            setError: { state = .error($0) },
            clearEnteredDarts: { enteredDarts.removeAll() },
            onSuccess: { await playBotTurnIfNeeded() }
        )
    }

    func undoLastDart() async {
        await sessionController.undoLastDart(
            getSession: { session },
            getEnteredDarts: { enteredDarts },
            setSession: { session = $0 },
            setEnteredDarts: { enteredDarts = $0 },
            setSelectedMultiplier: { selectedMultiplier = $0 },
            setReadyTurn: { state = .readyTurn },
            setError: { state = .error($0) },
            onRestoredEmptyVisit: { await playBotTurnIfNeeded() }
        )
    }

    func onAppear() async {
        await sessionController.handleAppear(
            getSession: { session },
            setSession: { session = $0 },
            onLoadError: { state = .error($0) },
            reconcileAfterSummaryUndo: { await reconcileAfterSummaryUndo() },
            reconcileInterruptedBotPlayback: { reconcileInterruptedBotPlayback() },
            scheduleBotPlayback: { scheduleBotPlaybackIfNeeded() }
        )
    }

    func onDisappear() {
        sessionController.handleDisappear(reconcileInterruptedBotPlayback: { reconcileInterruptedBotPlayback() })
    }

    func recoverBotPlaybackIfNeeded() {
        sessionController.recoverBotPlaybackIfNeeded(
            isBotTurn: isCurrentPlayerBot,
            isBotPlaying: isBotPlaying,
            reconcileInterruptedBotPlayback: { reconcileInterruptedBotPlayback() },
            scheduleBotPlayback: { scheduleBotPlaybackIfNeeded() }
        )
    }

    func playBotTurnIfNeeded() async {
        while await playSingleBotTurnIfNeeded() {}
    }

    func announceHoleCompleteIfNeeded(strokes: Int, hole: Int) {
        let announcement = L10n.format(
            "play.golf.announce.holeCompleteDetail",
            hole,
            GolfStrokePresentation.label(for: strokes),
            strokes
        )
        postAccessibilityAnnouncement(announcement)
    }

    func loadSessionIfNeeded() async {
        await sessionController.loadSessionIfNeeded(
            session: session,
            setSession: { session = $0 },
            onError: { state = .error($0) }
        )
    }

    private func scheduleBotPlaybackIfNeeded() {
        sessionController.scheduleBotPlayback { await self.playBotTurnIfNeeded() }
    }

    private func isPlayerLeading(playerIndex: Int, state: GolfState) -> Bool {
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
        await sessionController.reconcileAfterSummaryUndo(
            isMatchCompleted: state == .matchCompleted,
            setSession: { session = $0 },
            setEnteredDarts: { enteredDarts = $0 },
            setBotPlaying: { isBotPlaying = $0 },
            setReadyTurn: { state = .readyTurn },
            isCurrentPlayerBot: { currentBotSkillProfile != nil },
            scheduleBotPlayback: { scheduleBotPlaybackIfNeeded() }
        )
    }

    private func reconcileInterruptedBotPlayback() {
        sessionController.reconcileInterruptedBotPlayback(
            session: session,
            setBotPlaying: { isBotPlaying = $0 },
            clearEnteredDarts: { enteredDarts.removeAll() },
            shouldResetState: {
                switch state {
                case .submittingTurn, .entryInvalid, .error, .matchCompleted, .holeCompleteFeedback:
                    return true
                default:
                    return false
                }
            },
            resetState: { state = .readyTurn },
            beforeReset: { holeCompleteFeedback = nil }
        )
    }

    @discardableResult
    private func playSingleBotTurnIfNeeded() async -> Bool {
        guard let profile = currentBotSkillProfile,
              let golfState = session?.runtime.golfState else { return false }

        var rng = SystemRandomNumberGenerator()
        let planned = DartBotEngine.generateGolfTurn(
            holeSegment: golfState.currentHole,
            profile: profile,
            rng: &rng
        )

        let submitted = await sessionController.playBotVisitAndSubmit(
            isReadyTurn: state == .readyTurn,
            isBotPlaying: isBotPlaying,
            setBotPlaying: { isBotPlaying = $0 },
            getEnteredDarts: { enteredDarts },
            setEnteredDarts: { enteredDarts = $0 },
            plannedDarts: planned.darts
        ) {
            await submitTurnAsync(endedEarly: planned.endedEarly, fromBotPlayback: true)
        }
        guard submitted else { return false }
        return sessionController.shouldContinueBotChain(
            session: session,
            isReadyTurn: state == .readyTurn,
            isCurrentPlayerBot: { currentBotSkillProfile != nil }
        )
    }

    private func submitTurnAsync(endedEarly: Bool, fromBotPlayback: Bool = false) async {
        await loadSessionIfNeeded()
        guard let current = session else {
            state = .error(sessionController.errorKeys.sessionMissing)
            return
        }
        state = .submittingTurn
        let darts = enteredDarts
        let input = GolfTurnInput(darts: darts, endedEarly: endedEarly)

        let outcome = await sessionController.turnSubmitter.submitTurn(
            from: current,
            invalidTurnFallbackKey: sessionController.errorKeys.invalidTurn
        ) {
            try MatchLifecycleService.submitGolfTurn(session: current, input: input)
        }

        await sessionController.applySubmitOutcome(
            outcome,
            fromBotPlayback: fromBotPlayback,
            setSession: { session = $0 },
            clearEnteredDarts: { enteredDarts.removeAll() },
            setReadyTurn: { state = .readyTurn },
            setEntryInvalid: { state = .entryInvalid($0) },
            setError: { state = .error($0) },
            handleSuccess: { updated, fromBotPlayback in
                if let event = lastGolfTurn(in: updated) {
                    holeCompleteFeedback = (hole: event.hole, strokes: event.strokesRecorded)
                    announceHoleCompleteIfNeeded(strokes: event.strokesRecorded, hole: event.hole)
                    state = .holeCompleteFeedback
                    try? await Task.sleep(nanoseconds: BotTurnPacing.golfHoleCompleteDelayNanoseconds(feedbackPreferences: sessionController.feedbackPreferences))
                    holeCompleteFeedback = nil
                }
                if updated.runtime.status == .completed {
                    state = .matchCompleted
                } else {
                    state = .readyTurn
                    if !fromBotPlayback {
                        await playBotTurnIfNeeded()
                    }
                }
            }
        )
    }

    private func lastGolfTurn(in session: MatchLifecycleSession) -> GolfTurnEvent? {
        guard let envelope = session.events.last,
              case let .golfTurn(event) = envelope.payload else { return nil }
        return event
    }
}

extension GolfMatchViewModel: MatchPlaySessionHost {
    var isBotTurnBlocking: Bool { isBotPlaying || state == .submittingTurn }
    var hostMatchRepository: any MatchRepository { sessionController.matchRepository }
    var hostMatchStore: ActiveMatchStore { sessionController.store }
    var hostMatchLogger: any AppLogger { sessionController.logger }
    var hostMatchType: MatchType { .golf }
}
