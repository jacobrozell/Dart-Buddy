import SwiftUI

@MainActor
final class SnookerMatchViewModel: ObservableObject {
    enum State: Equatable {
        case readyDart
        case submittingDart
        case breakEndedFeedback
        case matchCompleted
        case error(String)
    }

    @Published private(set) var state: State = .readyDart
    @Published var selectedMultiplier: DartMultiplier = .single
    @Published var enteredDarts: [DartInput] = []
    @Published var pendingNominatedColour: SnookerColour?
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
            matchType: .snooker,
            eventTypeRaw: "snookerDart",
            store: store,
            logger: logger,
            matchRepository: matchRepository
        )
        self.session = store.session(for: matchId)
    }

    var snookerState: SnookerState? { session?.runtime.snookerState }

    var canEnterDart: Bool {
        guard canHumanInput else { return false }
        if isAwaitingNomination { return pendingNominatedColour != nil }
        return true
    }

    var canHumanInput: Bool {
        isCurrentPlayerBot == false && isBotPlaying == false && state == .readyDart
    }

    var isCurrentPlayerBot: Bool { currentBotSkillProfile != nil }

    var isAwaitingNomination: Bool {
        guard let phase = snookerState?.phase else { return false }
        if case .awaitingNomination = phase { return true }
        return false
    }

    var lockedSegment: Int? {
        guard let phase = snookerState?.phase else { return nil }
        switch phase {
        case .awaitingColour(let colour):
            return colour.targetSegment
        case .awaitingRed, .awaitingNomination:
            return nil
        }
    }

    var showsBull: Bool {
        guard let phase = snookerState?.phase else { return false }
        if case .awaitingColour(let colour) = phase { return colour == .black }
        return false
    }

    var currentBotSkillProfile: BotSkillProfile? {
        guard let session, let gameState = session.runtime.snookerState else { return nil }
        guard session.runtime.status == .inProgress else { return nil }
        return DartBotEngine.botSkillProfile(
            playerId: gameState.currentBreakerId,
            in: session.runtime.participants
        )
    }

    var phaseBannerText: String {
        guard let phase = snookerState?.phase else { return "" }
        switch phase {
        case .awaitingRed:
            return L10n.string("play.snooker.phase.awaitingRed")
        case .awaitingNomination:
            return L10n.string("play.snooker.phase.awaitingNomination")
        case .awaitingColour(let colour):
            return L10n.format("play.snooker.phase.awaitingColourFormat", L10n.string(colour.localizationKey))
        }
    }

    var headerAccessibilityLabel: String {
        [L10n.string("play.snooker.navTitle"), phaseBannerText].joined(separator: ", ")
    }

    var scoreboardRows: [SnookerScoreboardView.Row] {
        guard let session, let gameState = session.runtime.snookerState else { return [] }
        let isInProgress = session.runtime.status == .inProgress
        let maxScore = gameState.players.map(\.frameScore).max() ?? 0
        return gameState.players.enumerated().map { index, player in
            let participant = session.runtime.participant(for: player.playerId)
            let isActive = player.playerId == gameState.currentBreakerId && isInProgress
            let isLeading = maxScore > 0 && player.frameScore == maxScore
                && gameState.players.filter { $0.frameScore == maxScore }.count == 1
            return SnookerScoreboardView.Row(
                id: player.playerId,
                name: participant?.displayNameAtMatchStart ?? MatchConfigText.playerName(forIndex: index),
                frameScore: player.frameScore,
                highestBreak: player.highestBreak,
                isActive: isActive,
                isLeading: isLeading,
                colorToken: participant?.colorToken ?? PlayerColorToken.defaultForPlayer(id: player.playerId)
            )
        }
    }

    func selectNominatedColour(_ colour: SnookerColour) {
        pendingNominatedColour = colour
    }

    func submitDart() async { await submitDartAsync() }
    func undoLastDart() async { await undoLastDartAsync() }

    func onAppear() async {
        logger.matchInfo(
            matchId: matchId,
            matchType: .snooker,
            category: .ui,
            eventName: "match_screen_appeared",
            message: "Snooker match screen presented."
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
                matchType: .snooker,
                category: .appLifecycle,
                eventName: "snooker_abandon_failed",
                message: "Abandon failed.",
                metadata: MatchTurnSupport.appErrorMetadata(for: error)
            )
        }
    }

    private func scheduleBotPlaybackIfNeeded() {
        botPlayback.schedule { await self.playBotBreakIfNeeded() }
    }

    func playBotBreakIfNeeded() async {
        while await playSingleBotDartIfNeeded() {}
    }

    private func reconcileAfterSummaryUndo() async -> Bool {
        guard state == .matchCompleted,
              let stored = store.session(for: matchId),
              stored.runtime.status == .inProgress else { return false }
        session = stored
        state = .readyDart
        pendingNominatedColour = nil
        enteredDarts = []
        isBotPlaying = false
        scheduleBotPlaybackIfNeeded()
        return true
    }

    private func reconcileInterruptedBotPlayback() {
        isBotPlaying = false
        enteredDarts.removeAll()
        pendingNominatedColour = nil
        guard session?.runtime.status == .inProgress else { return }
        switch state {
        case .submittingDart, .error, .matchCompleted, .breakEndedFeedback:
            state = .readyDart
        default:
            break
        }
    }

    @discardableResult
    private func playSingleBotDartIfNeeded() async -> Bool {
        guard let profile = currentBotSkillProfile,
              state == .readyDart,
              isBotPlaying == false,
              let gameState = session?.runtime.snookerState else { return false }

        isBotPlaying = true
        defer { isBotPlaying = false }

        var nominatedColour: SnookerColour?
        var rng = SystemRandomNumberGenerator()
        if case .awaitingNomination = gameState.phase {
            nominatedColour = DartBotEngine.generateSnookerNomination(
                state: gameState,
                profile: profile,
                rng: &rng
            )
            pendingNominatedColour = nominatedColour
        }

        let dart = DartBotEngine.generateSnookerDart(
            state: gameState,
            profile: profile,
            nominatedColour: nominatedColour,
            rng: &rng
        )
        do { try await Task.sleep(nanoseconds: BotTurnPacing.dartDelayNanoseconds(staggerEnabled: feedbackPreferences.botStaggerEnabled)) } catch { return false }

        await submitDartAsync(dart: dart, nominatedColour: nominatedColour, fromBotPlayback: true)
        guard session?.runtime.status != .completed else { return false }
        return currentBotSkillProfile != nil && state == .readyDart
    }

    private func submitDartAsync(
        dart: DartInput? = nil,
        nominatedColour: SnookerColour? = nil,
        fromBotPlayback: Bool = false
    ) async {
        await loadSessionIfNeeded()
        guard let current = session else {
            state = .error("snooker.error.sessionMissing")
            return
        }
        let dartToSubmit = dart ?? enteredDarts.last
        guard let dartToSubmit else { return }

        state = .submittingDart
        let nomination = nominatedColour ?? pendingNominatedColour

        let outcome = await turnSubmitter.submitTurn(
            from: current,
            invalidTurnFallbackKey: "snooker.error.invalidDart"
        ) {
            try MatchLifecycleService.submitSnookerDart(
                session: current,
                dart: dartToSubmit,
                nominatedColour: nomination
            )
        }

        switch outcome {
        case .cancelled:
            state = .readyDart
        case let .rejected(messageKey):
            enteredDarts.removeAll()
            state = .error(messageKey)
        case let .persistFailed(messageKey):
            enteredDarts.removeAll()
            state = .error(messageKey)
        case let .succeeded(updated):
            session = updated
            enteredDarts.removeAll()
            pendingNominatedColour = nil

            if let event = lastSnookerDart(in: updated) {
                handleDartFeedback(event: event, fromBotPlayback: fromBotPlayback)
            }

            if updated.runtime.status == .completed {
                state = .matchCompleted
            } else if lastSnookerDart(in: updated)?.breakEnded == true {
                state = .breakEndedFeedback
                try? await Task.sleep(nanoseconds: 900_000_000)
                state = .readyDart
                if !fromBotPlayback { scheduleBotPlaybackIfNeeded() }
            } else {
                state = .readyDart
                if !fromBotPlayback { scheduleBotPlaybackIfNeeded() }
            }
        }
    }

    private func lastSnookerDart(in session: MatchLifecycleSession) -> SnookerDartEvent? {
        guard case let .snookerDart(event) = session.events.last?.payload else { return nil }
        return event
    }

    private func handleDartFeedback(event: SnookerDartEvent, fromBotPlayback: Bool) {
        if event.points > 0 {
            if !fromBotPlayback || feedbackPreferences.botDartHapticsEnabled {
                // audio/haptics handled by screen
            }
        }
        if event.breakEnded {
            postAccessibilityAnnouncement(L10n.string("play.snooker.breakEnded"))
        } else if event.ballType == .red, event.segmentPocketed != nil {
            postAccessibilityAnnouncement(L10n.string("play.snooker.redPocketed"))
        }
    }

    private func undoLastDartAsync() async {
        await loadSessionIfNeeded()
        guard let current = session else { return }
        if !enteredDarts.isEmpty {
            enteredDarts.removeAll()
            pendingNominatedColour = nil
            selectedMultiplier = .single
            return
        }
        do {
            let undone = try await MatchTurnSupport.undoLastTurn(
                session: current,
                matchId: matchId,
                store: store,
                matchRepository: matchRepository
            )
            session = undone
            pendingNominatedColour = nil
            state = .readyDart
            scheduleBotPlaybackIfNeeded()
        } catch {
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "error.turn.undoFailed"))
        }
    }

    private func loadSessionIfNeeded() async {
        if session == nil {
            session = store.session(for: matchId)
        }
    }

    private func postAccessibilityAnnouncement(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}
