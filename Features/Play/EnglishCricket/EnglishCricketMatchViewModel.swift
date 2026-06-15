import SwiftUI

@MainActor
final class EnglishCricketMatchViewModel: ObservableObject {
    enum State: Equatable {
        case readyTurn
        case entryInvalid(String)
        case submittingTurn
        case inningsCompletedFeedback
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
            matchType: .englishCricket,
            eventTypeRaw: "englishCricketTurn",
            store: store,
            logger: logger,
            matchRepository: matchRepository
        )
        self.session = store.session(for: matchId)
    }

    var englishCricketState: EnglishCricketState? { session?.runtime.englishCricketState }

    var canSubmit: Bool { enteredDarts.count == 3 && canHumanInput }

    var canHumanInput: Bool {
        isCurrentPlayerBot == false && isBotPlaying == false && state == .readyTurn
    }

    var isCurrentPlayerBot: Bool {
        currentBotSkillProfile != nil
    }

    var currentBotSkillProfile: BotSkillProfile? {
        guard let session, let ecState = session.runtime.englishCricketState else { return nil }
        guard session.runtime.status == .inProgress else { return nil }
        let currentId = ecState.currentTurnPlayerId
        return DartBotEngine.botSkillProfile(
            playerId: currentId,
            in: session.runtime.participants
        )
    }

    /// `true` when the current phase is batting (full-board pad).
    var isBatterPhase: Bool {
        englishCricketState?.phase == .batting
    }

    /// `true` when the current phase is bowling (bull-only pad).
    var isBowlerPhase: Bool {
        englishCricketState?.phase == .bowling
    }

    var navTitle: String {
        L10n.string("play.englishCricket.navTitle")
    }

    var headerInningsText: String {
        guard let ecState = englishCricketState else { return "" }
        return L10n.format("play.englishCricket.header.inningsFormat", ecState.inningsIndex + 1)
    }

    var currentRoleName: String {
        guard let ecState = englishCricketState else { return "" }
        switch ecState.phase {
        case .batting: return L10n.string("play.englishCricket.role.batter")
        case .bowling: return L10n.string("play.englishCricket.role.bowler")
        }
    }

    var padHint: String {
        isBatterPhase
            ? L10n.string("play.englishCricket.pad.fullBoardHint")
            : L10n.string("play.englishCricket.pad.bullOnlyHint")
    }

    var headerAccessibilityLabel: String {
        var parts = [navTitle, headerInningsText, currentRoleName]
        parts.append(padHint)
        return parts.joined(separator: ", ")
    }

    var scoreboardRows: [EnglishCricketScoreboardView.Row] {
        guard let session, let ecState = session.runtime.englishCricketState else { return [] }
        let isInProgress = session.runtime.status == .inProgress
        return ecState.players.enumerated().map { index, player in
            let participant = participant(for: player.playerId)
            let isBatter = index == ecState.batterIndex
            let isBowler = index == ecState.bowlerIndex
            let isActiveThisTurn: Bool = {
                switch ecState.phase {
                case .batting: return isBatter
                case .bowling: return isBowler
                }
            }()
            let wicketDisplay = isBowler
                ? max(0, ecState.config.wicketsPerInnings - ecState.wicketsFallen)
                : nil
            return EnglishCricketScoreboardView.Row(
                id: player.playerId,
                name: participant?.displayNameAtMatchStart ?? MatchConfigText.playerName(forIndex: index),
                totalRuns: player.totalRuns,
                runsThisInnings: player.runsThisInnings,
                wicketsRemaining: wicketDisplay,
                isBatter: isBatter,
                isBowler: isBowler,
                isActiveTurn: isActiveThisTurn && isInProgress,
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
            matchType: .englishCricket,
            category: .ui,
            eventName: "match_screen_appeared",
            message: "English Cricket match screen presented."
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
        case .submittingTurn, .entryInvalid, .error, .matchCompleted, .inningsCompletedFeedback:
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
              let ecState = session?.runtime.englishCricketState else { return false }

        isBotPlaying = true
        defer { isBotPlaying = false }

        enteredDarts.removeAll()
        var rng = SystemRandomNumberGenerator()

        let role: EnglishCricketRole = ecState.phase == .batting ? .batter : .bowler
        let plannedDarts = DartBotEngine.generateEnglishCricketTurn(
            role: role,
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
            state = .error("englishCricket.error.sessionMissing")
            return
        }
        state = .submittingTurn
        let darts = enteredDarts

        let outcome = await turnSubmitter.submitTurn(
            from: current,
            invalidTurnFallbackKey: "englishCricket.error.invalidTurn"
        ) {
            try MatchLifecycleService.submitEnglishCricketTurn(session: current, darts: darts)
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
            let inningsJustCompleted = lastEnglishCricketTurnInningsCompleted(in: updated)
            if updated.runtime.status == .completed {
                state = .matchCompleted
            } else if inningsJustCompleted {
                state = .inningsCompletedFeedback
                postAccessibilityAnnouncement(L10n.string("play.englishCricket.announce.inningsComplete"))
                try? await Task.sleep(nanoseconds: BotTurnPacing.shanghaiAchievementDelayNanoseconds(feedbackPreferences: feedbackPreferences))
                state = .readyTurn
                if !fromBotPlayback {
                    await playBotTurnIfNeeded()
                }
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
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "englishCricket.error.undoFailed"))
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
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "englishCricket.error.undoFailed"))
        }
    }

    func loadSessionIfNeeded() async {
        if session != nil { return }
        switch await MatchSessionLoader.load(
            matchId: matchId,
            matchType: .englishCricket,
            store: store,
            logger: logger,
            matchRepository: matchRepository,
            statsRepository: statsRepository,
            sessionMissingFallbackKey: "englishCricket.error.sessionMissing"
        ) {
        case let .loaded(loaded):
            session = loaded
        case .missing:
            break
        case let .failed(messageKey):
            state = .error(messageKey)
        }
    }

    /// Returns `true` if the most recent turn event caused an innings to complete.
    ///
    /// We infer this by comparing the innings index recorded in the event against the
    /// innings index in the updated state: if the state's innings index advanced (or
    /// the match completed), an innings boundary was crossed.
    private func lastEnglishCricketTurnInningsCompleted(in updated: MatchLifecycleSession) -> Bool {
        guard let envelope = updated.events.last,
              case let .englishCricketTurn(event) = envelope.payload,
              let ecState = updated.runtime.englishCricketState else { return false }
        // If the event's innings index differs from the current state's innings, an innings ended.
        // Also `true` when the match completed, so callers needn't special-case it.
        return event.inningsIndex != ecState.inningsIndex || ecState.isComplete
    }

    private func participant(for playerId: UUID) -> MatchParticipant? {
        session?.runtime.participants.first { ($0.playerId ?? $0.id) == playerId }
    }
}
extension EnglishCricketMatchViewModel: MatchPlaySessionHost {
    var isBotTurnBlocking: Bool { isBotPlaying || state == .submittingTurn }
    var hostMatchRepository: any MatchRepository { matchRepository }
    var hostMatchStore: ActiveMatchStore { store }
    var hostMatchLogger: any AppLogger { logger }
    var hostMatchType: MatchType { .englishCricket }
}
