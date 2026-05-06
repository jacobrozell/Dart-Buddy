import Foundation

@MainActor
final class X01MatchViewModel: ObservableObject {
    enum State: Equatable {
        case readyTurn
        case entryInvalid(String)
        case submittingTurn
        case bustFeedback
        case matchCompleted
        case error(String)
    }

    @Published private(set) var state: State = .readyTurn
    @Published var inputMode: ScoringInputMode = .totalEntry
    @Published var selectedMultiplier: DartMultiplier = .single
    @Published var enteredDarts: [DartInput] = []
    @Published var totalEntryText = ""
    @Published private(set) var session: MatchLifecycleSession?

    private let matchId: UUID
    private let store: ActiveMatchStore
    private let logger: any AppLogger
    private let matchRepository: any MatchRepository
    private let statsRepository: any StatsRepository

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
        self.session = store.session(for: matchId)
    }

    var canSubmit: Bool {
        switch inputMode {
        case .totalEntry:
            guard let value = Int(totalEntryText) else { return false }
            return (0 ... 180).contains(value)
        case .dartEntry:
            return !enteredDarts.isEmpty
        }
    }

    func submitTurn() async {
        await submitTurnAsync()
    }

    func undoLastTurn() async {
        await undoLastTurnAsync()
    }

    func onAppear() async {
        await loadSessionIfNeeded()
    }

    private func submitTurnAsync() async {
        await loadSessionIfNeeded()
        guard var current = session else {
            state = .error("x01.error.sessionMissing")
            return
        }
        state = .submittingTurn
        do {
            let total = inputMode == .totalEntry ? Int(totalEntryText) : nil
            let darts = inputMode == .dartEntry ? enteredDarts : nil
            do {
                current = try PerformanceMonitor.measure(
                    .submitTurn,
                    logger: logger,
                    metadata: ["matchType": MatchType.x01.rawValue]
                ) {
                    try MatchLifecycleService.submitX01Turn(
                        session: current,
                        enteredTotal: total,
                        darts: darts
                    )
                }
            } catch is CancellationError {
                state = .readyTurn
                return
            } catch {
                state = .entryInvalid(errorMessageKey(for: error, fallback: "x01.error.invalidTurn"))
                return
            }
            do {
                try await persistProgress(current)
            } catch is CancellationError {
                state = .readyTurn
                return
            } catch {
                state = .error(errorMessageKey(for: error, fallback: "error.repository.storage"))
                return
            }
            store.save(current)
            session = current
            if current.runtime.status == .completed {
                PerformanceMonitor.measure(
                    .completeMatch,
                    logger: logger,
                    metadata: ["matchType": MatchType.x01.rawValue]
                ) {}
                state = .matchCompleted
            } else if case let .x01Turn(event) = current.events.last?.payload, event.isBust {
                state = .bustFeedback
            } else {
                state = .readyTurn
            }
            enteredDarts.removeAll()
            totalEntryText = ""
        }
    }

    private func undoLastTurnAsync() async {
        await loadSessionIfNeeded()
        guard let current = session else { return }
        do {
            let undone = try MatchLifecycleService.undoLastTurn(session: current)
            try await matchRepository.updateMatch(matchSummary(from: undone.runtime))
            _ = try await matchRepository.saveSnapshot(
                matchId: matchId,
                snapshotVersion: undone.latestSnapshot.payloadVersion,
                snapshotPayload: undone.latestSnapshot.payload
            )
            store.save(undone)
            session = undone
            state = .readyTurn
            enteredDarts.removeAll()
            totalEntryText = ""
        } catch is CancellationError {
            state = .readyTurn
        } catch {
            state = .error(errorMessageKey(for: error, fallback: "x01.error.undoFailed"))
        }
    }

    private func persistProgress(_ current: MatchLifecycleSession) async throws {
        if let event = current.events.last, event.eventIndex >= 0 {
            let payload = try CodablePayloadCoder.encode(event)
            _ = try await matchRepository.appendEvent(
                matchId: matchId,
                eventTypeRaw: "x01Turn",
                eventPayload: payload
            )
        }
        _ = try await matchRepository.saveSnapshot(
            matchId: matchId,
            snapshotVersion: current.latestSnapshot.payloadVersion,
            snapshotPayload: current.latestSnapshot.payload
        )
        if current.runtime.status == .completed {
            _ = try await matchRepository.completeMatch(
                matchId: matchId,
                endedAt: current.runtime.endedAt ?? Date(),
                winnerPlayerId: current.runtime.winnerPlayerId
            )
        } else {
            try await matchRepository.updateMatch(matchSummary(from: current.runtime))
        }
    }

    private func matchSummary(from runtime: MatchRuntimeState) -> MatchSummary {
        MatchSummary(
            id: runtime.matchId,
            type: runtime.type,
            status: MatchStatus(rawValue: runtime.status.rawValue) ?? .inProgress,
            startedAt: runtime.startedAt,
            endedAt: runtime.endedAt,
            winnerPlayerId: runtime.winnerPlayerId,
            currentTurnPlayerId: runtime.currentTurnPlayerId,
            currentLegIndex: runtime.currentLegIndex,
            currentSetIndex: runtime.currentSetIndex,
            eventCount: runtime.eventCount,
            createdAt: runtime.startedAt,
            updatedAt: Date()
        )
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
            state = .error(errorMessageKey(for: error, fallback: "x01.error.sessionMissing"))
        }
    }

    private func errorMessageKey(for error: Error, fallback: String) -> String {
        if let appError = error as? AppError {
            return appError.userMessageKey
        }
        return fallback
    }
}
