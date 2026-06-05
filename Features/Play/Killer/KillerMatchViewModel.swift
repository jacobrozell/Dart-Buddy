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
    @Published private(set) var session: MatchLifecycleSession?

    private let matchId: UUID
    private let store: ActiveMatchStore
    private let logger: any AppLogger
    private let matchRepository: any MatchRepository
    private let statsRepository: any StatsRepository
    private let pickSubmitter: MatchTurnSubmitter
    private let turnSubmitter: MatchTurnSubmitter

    init(
        matchId: UUID,
        store: ActiveMatchStore,
        logger: any AppLogger,
        matchRepository: any MatchRepository,
        statsRepository: any StatsRepository
    ) {
        self.matchId = matchId
        self.store = store
        self.logger = logger
        self.matchRepository = matchRepository
        self.statsRepository = statsRepository
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

    var canSubmit: Bool {
        guard killerState != nil else { return false }
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
            let participant = participant(for: player.playerId)
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
        logger.matchDebug(
            matchId: matchId,
            matchType: .killer,
            category: .ui,
            eventName: "match_screen_appeared",
            message: "Killer match screen presented."
        )
        if await reconcileAfterSummaryUndo() { return }
        await loadSessionIfNeeded()
        syncInteractionState()
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
                matchType: .killer,
                category: .appLifecycle,
                eventName: "killer_abandon_failed",
                message: "Abandon failed.",
                metadata: MatchTurnSupport.appErrorMetadata(for: error)
            )
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

    private func participant(for playerId: UUID) -> MatchParticipant? {
        session?.runtime.participants.first { ($0.playerId ?? $0.id) == playerId }
    }

    private func participantName(for playerId: UUID) -> String {
        participant(for: playerId)?.displayNameAtMatchStart ?? L10n.string("play.killer.unknownPlayer")
    }

    private func reconcileAfterSummaryUndo() async -> Bool {
        guard state == .matchCompleted,
              let stored = store.session(for: matchId),
              stored.runtime.status == .inProgress else { return false }
        session = stored
        enteredDarts = store.consumeResumeHint(matchId: matchId) ?? []
        syncInteractionState()
        return true
    }

    private func submitTurnAsync() async {
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
                try? await Task.sleep(nanoseconds: 700_000_000)
            }
            if updated.runtime.status == .completed {
                state = .matchCompleted
            } else {
                syncInteractionState()
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
            enteredDarts.removeAll()
            syncInteractionState()
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
        } catch is CancellationError {
            syncInteractionState()
        } catch {
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "killer.error.undoFailed"))
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
            state = .error(MatchTurnSupport.errorMessageKey(for: error, fallback: "killer.error.sessionMissing"))
        }
    }

    private func lastKillerTurn(in session: MatchLifecycleSession) -> KillerTurnEvent? {
        guard let envelope = session.events.last,
              case let .killerTurn(event) = envelope.payload else { return nil }
        return event
    }
}
