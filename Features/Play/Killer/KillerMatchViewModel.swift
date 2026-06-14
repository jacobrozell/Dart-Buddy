import SwiftUI

@MainActor
final class KillerMatchViewModel: ObservableObject {
    enum State: Equatable {
        case readyTurn
        case readyPick
        case entryInvalid(String)
        case submittingTurn
        case becameKillerFeedback
        case matchCompleted
        case error(String)
    }

    @Published private(set) var state: State = .readyPick
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
    private let pickSubmitter: MatchTurnSubmitter
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
        self.pickSubmitter = MatchTurnSubmitter(
            matchId: matchId,
            matchType: .killer,
            eventTypeRaw: "killerPick",
            store: store,
            logger: logger,
            matchRepository: matchRepository
        )
        self.turnSubmitter = MatchTurnSubmitter(
            matchId: matchId,
            matchType: .killer,
            eventTypeRaw: "killerTurn",
            store: store,
            logger: logger,
            matchRepository: matchRepository
        )
        self.session = store.session(for: matchId)
        syncInteractionState()
    }

    var killerState: KillerState? { session?.runtime.killerState }

    var isPickPhase: Bool { killerState?.phase == .numberPick }

    var canHumanInput: Bool {
        isCurrentActorBot == false && isBotPlaying == false && isReadyForHumanInput
    }

    var isCurrentActorBot: Bool {
        currentBotSkillProfile != nil
    }

    var currentBotSkillProfile: BotSkillProfile? {
        guard let session, let state = session.runtime.killerState else { return nil }
        guard session.runtime.status == .inProgress else { return nil }
        if state.phase == .numberPick {
            guard let pickerId = state.pickQueue.first else { return nil }
            return DartBotEngine.botSkillProfile(
                playerId: pickerId,
                in: session.runtime.participants
            )
        }
        let player = state.players[state.currentPlayerIndex]
        guard !player.isEliminated else { return nil }
        return DartBotEngine.botSkillProfile(
            playerId: player.playerId,
            in: session.runtime.participants
        )
    }

    var canSubmit: Bool {
        guard killerState != nil, canHumanInput else { return false }
        if isPickPhase {
            return enteredDarts.count == 1 && state == .readyPick
        }
        return !enteredDarts.isEmpty && state == .readyTurn
    }

    var maxDartsPerSubmission: Int { isPickPhase ? 1 : 3 }

    var headerText: String {
        guard let state = killerState else { return "" }
        if state.phase == .numberPick, let pickerId = state.pickQueue.first {
            let name = participantName(for: pickerId)
            return L10n.format("play.killer.header.pickFormat", name)
        }
        let thrower = state.players[state.currentPlayerIndex]
        let name = participantName(for: thrower.playerId)
        if thrower.isKiller {
            return L10n.format("play.killer.header.killerThrowFormat", name)
        }
        return L10n.format("play.killer.header.throwFormat", name)
    }

    var targetHint: String? {
        guard let state = killerState else { return nil }
        if state.phase == .numberPick {
            return L10n.string("play.killer.pickHint")
        }
        guard let throwerNumber = state.players[state.currentPlayerIndex].assignedNumber else { return nil }
        if state.players[state.currentPlayerIndex].isKiller {
            return L10n.string("play.killer.aimDoubles")
        }
        return L10n.format("play.killer.yourNumberFormat", throwerNumber)
    }

    var scoreboardRows: [KillerScoreboardView.Row] {
        guard let session, let state = session.runtime.killerState else { return [] }
        let isInProgress = session.runtime.status == .inProgress
        return state.players.enumerated().map { index, player in
            let participant = session.runtime.participant(for: player.playerId)
            let isActive: Bool
            if state.phase == .numberPick {
                isActive = state.pickQueue.first == player.playerId && isInProgress
            } else {
                isActive = index == state.currentPlayerIndex && isInProgress && !player.isEliminated
            }
            return KillerScoreboardView.Row(
                id: player.playerId,
                name: participant?.displayNameAtMatchStart ?? MatchConfigText.playerName(forIndex: index),
                assignedNumber: player.assignedNumber,
                lives: player.lives,
                isKiller: player.isKiller,
                isEliminated: player.isEliminated,
                isActive: isActive,
                colorToken: participant?.colorToken ?? PlayerColorToken.defaultForPlayer(id: player.playerId)
            )
        }
    }

    var numberGridAssignments: [KillerNumberGridView.Assignment] {
        guard let state = killerState else { return [] }
        return state.players.compactMap { player in
            guard let number = player.assignedNumber else { return nil }
            let name = participantName(for: player.playerId)
            let initial = String(name.prefix(1)).uppercased()
            return KillerNumberGridView.Assignment(number: number, playerInitial: initial)
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
            matchType: .killer,
            category: .ui,
            eventName: "match_screen_appeared",
            message: "Killer match screen presented."
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
            isBotTurn: isCurrentActorBot,
            isBotPlaying: isBotPlaying,
            reconcile: reconcileInterruptedBotPlayback,
            schedule: scheduleBotPlaybackIfNeeded
        )
    }

    private func scheduleBotPlaybackIfNeeded() {
        botPlayback.schedule { await self.playBotTurnIfNeeded() }
    }

    func playBotTurnIfNeeded() async {
        while await playSingleBotActionIfNeeded() {}
    }

    private var isReadyForHumanInput: Bool {
        switch state {
        case .readyPick, .readyTurn:
            return true
        default:
            return false
        }
    }

    private func syncInteractionState() {
        if killerState?.phase == .numberPick {
            if case .matchCompleted = state { return }
            state = .readyPick
        } else if killerState?.isComplete == true {
            state = .matchCompleted
        } else if case .entryInvalid = state {
            return
        } else if case .error = state {
            return
        } else {
            state = .readyTurn
        }
    }

    private func participantName(for playerId: UUID) -> String {
        session?.runtime.participant(for: playerId)?.displayNameAtMatchStart ?? L10n.string("play.killer.unknownPlayer")
    }

    private func reconcileAfterSummaryUndo() async -> Bool {
        guard state == .matchCompleted,
              let stored = store.session(for: matchId),
              stored.runtime.status == .inProgress else { return false }
        session = stored
        enteredDarts = store.consumeResumeHint(matchId: matchId) ?? []
        isBotPlaying = false
        syncInteractionState()
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
        case .submittingTurn, .entryInvalid, .error, .matchCompleted, .becameKillerFeedback:
            syncInteractionState()
        default:
            break
        }
    }

    @discardableResult
    private func playSingleBotActionIfNeeded() async -> Bool {
        guard let profile = currentBotSkillProfile,
              isBotPlaying == false,
              let killerState = session?.runtime.killerState,
              session?.runtime.status == .inProgress else { return false }

        let isPick = killerState.phase == .numberPick
        guard (isPick && state == .readyPick) || (!isPick && state == .readyTurn) else { return false }

        isBotPlaying = true
        defer { isBotPlaying = false }

        enteredDarts.removeAll()
        var rng = SystemRandomNumberGenerator()

        let dartsToReveal: [DartInput]
        if isPick {
            let takenNumbers = Set(killerState.players.compactMap(\.assignedNumber))
            dartsToReveal = [
                DartBotEngine.generateKillerPick(
                    takenNumbers: takenNumbers,
                    profile: profile,
                    rng: &rng
                )
            ]
        } else {
            let partialVisitCount = enteredDarts.count
            let plannedDarts = DartBotEngine.generateKillerTurn(
                state: killerState,
                throwerIndex: killerState.currentPlayerIndex,
                profile: profile,
                rng: &rng
            )
            dartsToReveal = BotVisitPlayback.remainingPlannedDarts(
                fullPlan: plannedDarts,
                existingCount: partialVisitCount
            )
        }

        guard await BotVisitPlayback.revealVisit(
            dartsToReveal,
            feedbackPreferences: feedbackPreferences,
            append: { enteredDarts.append($0) }
        ) else { return false }
        await submitTurnAsync(fromBotPlayback: true)
        guard session?.runtime.status != .completed else { return false }

        if session?.runtime.killerState?.phase == .numberPick {
            return currentBotSkillProfile != nil && state == .readyPick
        }
        return currentBotSkillProfile != nil && state == .readyTurn
    }

    private func submitTurnAsync(fromBotPlayback: Bool = false) async {
        await loadSessionIfNeeded()
        guard let current = session else {
            state = .error("killer.error.sessionMissing")
            return
        }
        state = .submittingTurn
        let darts = enteredDarts
        let isPick = current.runtime.killerState?.phase == .numberPick

        let outcome: MatchTurnSubmitter.Outcome
        if isPick {
            guard let dart = darts.first else {
                state = .entryInvalid("killer.error.invalidPick")
                return
            }
            outcome = await pickSubmitter.submitTurn(
                from: current,
                invalidTurnFallbackKey: "killer.error.invalidPick"
            ) {
                try MatchLifecycleService.submitKillerPick(session: current, dart: dart)
            }
        } else {
            outcome = await turnSubmitter.submitTurn(
                from: current,
                invalidTurnFallbackKey: "killer.error.invalidTurn"
            ) {
                try MatchLifecycleService.submitKillerTurn(session: current, darts: darts)
            }
        }

        switch outcome {
        case .cancelled:
            syncInteractionState()
        case let .rejected(messageKey):
            state = .entryInvalid(messageKey)
        case let .persistFailed(messageKey):
            state = .error(messageKey)
        case let .succeeded(updated):
            session = updated
            if !isPick, lastKillerTurn(in: updated)?.darts.contains(where: \.becameKiller) == true {
                state = .becameKillerFeedback
                try? await Task.sleep(nanoseconds: BotTurnPacing.killerBecameKillerTransitionNanoseconds)
            }
            if updated.runtime.status == .completed {
                state = .matchCompleted
            } else {
                syncInteractionState()
            }
            enteredDarts.removeAll()
            if updated.runtime.status != .completed, !fromBotPlayback {
                scheduleBotPlaybackIfNeeded()
            }
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
            enteredDarts.removeAll()
            syncInteractionState()
            scheduleBotPlaybackIfNeeded()
        } catch is CancellationError {
            syncInteractionState()
        } catch {
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "killer.error.undoFailed"))
        }
    }

    private func undoLastDartAsync() async {
        await loadSessionIfNeeded()
        guard let current = session else { return }
        if !enteredDarts.isEmpty {
            enteredDarts.removeLast()
            selectedMultiplier = .single
            resumeBotPlaybackAfterUndoIfNeeded()
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
            enteredDarts = result.restoredDarts
            syncInteractionState()
            resumeBotPlaybackAfterUndoIfNeeded()
        } catch is CancellationError {
            syncInteractionState()
        } catch {
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "killer.error.undoFailed"))
        }
    }

    private func resumeBotPlaybackAfterUndoIfNeeded() {
        MatchBotUndoSupport.resumeAfterDartUndo(
            isBotTurn: isCurrentActorBot,
            partialVisitCount: enteredDarts.count,
            isBotPlaying: &isBotPlaying,
            reconcileSubmittingTurn: {
                if case .submittingTurn = state { state = .readyTurn }
            },
            botPlayback: botPlayback,
            schedule: scheduleBotPlaybackIfNeeded
        )
    }

    func loadSessionIfNeeded() async {
        if session != nil { return }
        switch await MatchSessionLoader.load(
            matchId: matchId,
            matchType: .killer,
            store: store,
            logger: logger,
            matchRepository: matchRepository,
            statsRepository: statsRepository,
            sessionMissingFallbackKey: "killer.error.sessionMissing"
        ) {
        case let .loaded(loaded):
            session = loaded
        case .missing:
            break
        case let .failed(messageKey):
            state = .error(messageKey)
        }
    }

    private func lastKillerTurn(in session: MatchLifecycleSession) -> KillerTurnEvent? {
        guard let envelope = session.events.last,
              case let .killerTurn(event) = envelope.payload else { return nil }
        return event
    }
}

extension KillerMatchViewModel: MatchPlaySessionHost {
    var isBotTurnBlocking: Bool { isBotPlaying || state == .submittingTurn }
    var hostMatchRepository: any MatchRepository { matchRepository }
    var hostMatchStore: ActiveMatchStore { store }
    var hostMatchLogger: any AppLogger { logger }
    var hostMatchType: MatchType { .killer }
}
