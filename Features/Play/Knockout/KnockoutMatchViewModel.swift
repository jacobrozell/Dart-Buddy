import SwiftUI

@MainActor
final class KnockoutMatchViewModel: ObservableObject {
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
    @Published var session: MatchLifecycleSession?
    @Published private(set) var isBotPlaying = false

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
            matchType: .knockout,
            eventTypeRaw: "knockoutTurn",
            store: store,
            logger: logger,
            matchRepository: matchRepository,
            statsRepository: statsRepository,
            feedbackPreferences: feedbackPreferences,
            errorKeys: MatchSessionErrorKeys(
                sessionMissing: "knockout.error.sessionMissing",
                undoFailed: "knockout.error.undoFailed",
                invalidTurn: "knockout.error.invalidTurn"
            ),
            screenAppearedMessage: "Knockout match screen presented."
        )
        self.session = store.session(for: matchId)
    }

    var knockoutState: KnockoutState? { session?.runtime.knockoutState }

    var canSubmit: Bool { enteredDarts.count == 3 && canHumanInput }

    var canHumanInput: Bool {
        isCurrentPlayerBot == false && isBotPlaying == false && state == .readyTurn
    }

    var isCurrentPlayerBot: Bool {
        currentBotSkillProfile != nil
    }

    var currentBotSkillProfile: BotSkillProfile? {
        guard let session, let knockoutState = session.runtime.knockoutState else { return nil }
        guard session.runtime.status == .inProgress else { return nil }
        let player = knockoutState.players[knockoutState.currentPlayerIndex]
        return DartBotEngine.botSkillProfile(
            playerId: player.playerId,
            in: session.runtime.participants
        )
    }

    var navTitle: String { L10n.string("play.knockout.navTitle") }

    var currentHighText: String {
        guard let gs = knockoutState else { return "" }
        return L10n.format("play.knockout.currentHighFormat", gs.currentHigh)
    }

    var headerAccessibilityLabel: String {
        var parts = [L10n.string("play.knockout.navTitle"), currentHighText]
        if let gs = knockoutState {
            parts.append(L10n.format("play.knockout.roundFormat", gs.currentRound))
        }
        return parts.joined(separator: ", ")
    }

    var scoreboardRows: [KnockoutScoreboardView.Row] {
        guard let session, let gs = session.runtime.knockoutState else { return [] }
        let isInProgress = session.runtime.status == .inProgress
        return gs.players.enumerated().map { index, player in
            let participant = participant(for: player.playerId)
            let isActive = index == gs.currentPlayerIndex && isInProgress && !player.isEliminated
            return KnockoutScoreboardView.Row(
                id: player.playerId,
                name: participant?.displayNameAtMatchStart ?? MatchConfigText.playerName(forIndex: index),
                strikes: player.strikes,
                maxStrikes: gs.config.strikesToEliminate,
                isActive: isActive,
                isEliminated: player.isEliminated,
                colorToken: participant?.colorToken ?? PlayerColorToken.defaultForPlayer(id: player.playerId)
            )
        }
    }

    func submitTurn() async {
        await submitTurnAsync()
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

    @discardableResult
    private func playSingleBotTurnIfNeeded() async -> Bool {
        guard let profile = currentBotSkillProfile,
              let gs = session?.runtime.knockoutState else { return false }

        var rng = SystemRandomNumberGenerator()
        let plannedDarts = DartBotEngine.generateKnockoutTurn(
            currentHigh: gs.currentHigh,
            profile: profile,
            rng: &rng
        )

        let submitted = await sessionController.playBotVisitAndSubmit(
            isReadyTurn: state == .readyTurn,
            isBotPlaying: isBotPlaying,
            setBotPlaying: { isBotPlaying = $0 },
            getEnteredDarts: { enteredDarts },
            setEnteredDarts: { enteredDarts = $0 },
            plannedDarts: plannedDarts
        ) {
            await submitTurnAsync(fromBotPlayback: true)
        }
        guard submitted else { return false }
        return sessionController.shouldContinueBotChain(
            session: session,
            isReadyTurn: state == .readyTurn,
            isCurrentPlayerBot: { currentBotSkillProfile != nil }
        )
    }

    private func submitTurnAsync(fromBotPlayback: Bool = false) async {
        await loadSessionIfNeeded()
        guard let current = session else {
            state = .error(sessionController.errorKeys.sessionMissing)
            return
        }
        state = .submittingTurn
        let darts = enteredDarts

        let outcome = await sessionController.turnSubmitter.submitTurn(
            from: current,
            invalidTurnFallbackKey: sessionController.errorKeys.invalidTurn
        ) {
            try MatchLifecycleService.submitKnockoutTurn(session: current, darts: darts)
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
                if let event = lastKnockoutTurn(in: updated) {
                    announceOutcome(event: event)
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
                case .submittingTurn, .entryInvalid, .error, .matchCompleted:
                    return true
                default:
                    return false
                }
            },
            resetState: { state = .readyTurn }
        )
    }

    private func announceOutcome(event: KnockoutTurnEvent) {
        let key = event.beatHigh ? "play.knockout.announce.beatHigh" : "play.knockout.announce.missedHigh"
        let text = L10n.format(key, event.visitTotal)
        postKnockoutAccessibilityAnnouncement(text)
        if event.strikeAwarded {
            let strikeText = L10n.string("play.knockout.strikeAwarded")
            postKnockoutAccessibilityAnnouncement(strikeText)
        }
        if event.wasEliminated {
            postKnockoutAccessibilityAnnouncement(L10n.string("play.knockout.playerEliminated"))
        }
    }

    private func participant(for playerId: UUID) -> MatchParticipant? {
        session?.runtime.participants.first { ($0.playerId ?? $0.id) == playerId }
    }

    private func lastKnockoutTurn(in session: MatchLifecycleSession) -> KnockoutTurnEvent? {
        guard let envelope = session.events.last,
              case let .knockoutTurn(event) = envelope.payload else { return nil }
        return event
    }
}

private func postKnockoutAccessibilityAnnouncement(_ text: String) {
    UIAccessibility.post(notification: .announcement, argument: text)
}

extension KnockoutMatchViewModel: MatchPlaySessionHost {
    var isBotTurnBlocking: Bool { isBotPlaying || state == .submittingTurn }
    var hostMatchRepository: any MatchRepository { sessionController.matchRepository }
    var hostMatchStore: ActiveMatchStore { sessionController.store }
    var hostMatchLogger: any AppLogger { sessionController.logger }
    var hostMatchType: MatchType { .knockout }
}
