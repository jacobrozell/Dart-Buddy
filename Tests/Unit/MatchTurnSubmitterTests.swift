import Foundation
import Testing
@testable import DartBuddy

@Suite("Match turn submitter", .tags(.unit, .match, .x01, .regression))
struct MatchTurnSubmitterTests {
    @MainActor
    @Test
    func submitTurnReturnsSucceededWhenEngineAndPersistenceSucceed() async throws {
        let fixture = try makeSubmitterFixture(afterTotals: [60])
        let repo = TurnSubmitterFakeMatchRepository()
        let store = ActiveMatchStore()
        store.save(fixture.session)
        let submitter = makeSubmitter(matchId: fixture.matchId, repository: repo, store: store)

        let outcome = await submitter.submitTurn(
            from: fixture.session,
            invalidTurnFallbackKey: "error.match.invalidTurn"
        ) {
            try MatchLifecycleService.submitX01Turn(
                session: fixture.session,
                enteredTotal: 40,
                darts: nil
            )
        }

        guard case let .succeeded(updated) = outcome else {
            Issue.record("Expected succeeded outcome, got \(outcome)")
            return
        }
        #expect(updated.runtime.eventCount == fixture.session.runtime.eventCount + 1)
        #expect(await repo.appendCount == 1)
        #expect(await repo.updateCount == 1)
        #expect(store.session(for: fixture.matchId)?.runtime.eventCount == updated.runtime.eventCount)
    }

    @MainActor
    @Test
    func submitTurnReturnsRejectedWhenEngineThrows() async throws {
        let fixture = try makeSubmitterFixture(afterTotals: [])
        let submitter = makeSubmitter(matchId: fixture.matchId, repository: TurnSubmitterFakeMatchRepository(), store: ActiveMatchStore())
        let appError = AppError(
            code: .validationFailed,
            layer: .domain,
            severity: .warning,
            isRecoverable: true,
            userMessageKey: "error.match.invalidTurn"
        )

        let outcome = await submitter.submitTurn(
            from: fixture.session,
            invalidTurnFallbackKey: "error.match.invalidTurn"
        ) {
            throw appError
        }

        guard case let .rejected(messageKey) = outcome else {
            Issue.record("Expected rejected outcome, got \(outcome)")
            return
        }
        #expect(messageKey == "error.match.invalidTurn")
    }

    @MainActor
    @Test
    func submitTurnReturnsPersistFailedWhenRepositoryAppendFails() async throws {
        let fixture = try makeSubmitterFixture(afterTotals: [])
        let repo = TurnSubmitterFakeMatchRepository(failAppend: true)
        let submitter = makeSubmitter(matchId: fixture.matchId, repository: repo, store: ActiveMatchStore())

        let outcome = await submitter.submitTurn(
            from: fixture.session,
            invalidTurnFallbackKey: "error.match.invalidTurn"
        ) {
            try MatchLifecycleService.submitX01Turn(
                session: fixture.session,
                enteredTotal: 60,
                darts: nil
            )
        }

        guard case let .persistFailed(messageKey) = outcome else {
            Issue.record("Expected persistFailed outcome, got \(outcome)")
            return
        }
        #expect(messageKey == "error.repository.storage")
    }

    @MainActor
    @Test
    func persistProgressUpdatesMatchWhileStillInProgress() async throws {
        let fixture = try makeSubmitterFixture(afterTotals: [])
        let repo = TurnSubmitterFakeMatchRepository()
        let submitter = makeSubmitter(matchId: fixture.matchId, repository: repo, store: ActiveMatchStore())
        let updated = try MatchLifecycleService.submitX01Turn(
            session: fixture.session,
            enteredTotal: 60,
            darts: nil
        )

        try await submitter.persistProgress(updated)

        #expect(await repo.completeCount == 0)
        #expect(await repo.updateCount == 1)
        #expect(await repo.appendCount == 1)
        #expect(await repo.saveSnapshotCount == 1)
    }

    @MainActor
    @Test
    func persistProgressCompletesMatchWhenRuntimeIsCompleted() async throws {
        let fixture = try makeSubmitterFixture(afterTotals: [180, 0, 81, 0])
        let repo = TurnSubmitterFakeMatchRepository()
        let submitter = makeSubmitter(matchId: fixture.matchId, repository: repo, store: ActiveMatchStore())
        let completed = try MatchLifecycleService.submitX01Turn(
            session: fixture.session,
            enteredTotal: 40,
            darts: nil
        )

        try await submitter.persistProgress(completed)

        #expect(await repo.completeCount == 1)
        #expect(await repo.appendCount == 1)
        #expect(await repo.updateCount == 0)
    }

    @MainActor
    @Test
    func matchTurnSupportUndoLastTurnUpdatesRepositoryAndStore() async throws {
        var session = try MatchLifecycleService.createMatch(
            type: .x01,
            config: .x01(MatchConfigX01(
                startScore: 301,
                legsToWin: 1,
                setsEnabled: false,
                setsToWin: nil,
                checkoutMode: .singleOut
            )),
            participants: [
                MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "A", turnOrder: 0),
                MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "B", turnOrder: 1)
            ]
        )
        session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
        let matchId = session.runtime.matchId
        let repo = TurnSubmitterFakeMatchRepository()
        let store = ActiveMatchStore()
        store.save(session)

        let undone = try await MatchTurnSupport.undoLastTurn(
            session: session,
            matchId: matchId,
            store: store,
            matchRepository: repo
        )

        #expect(undone.runtime.eventCount == 0)
        #expect(await repo.updateCount == 1)
        #expect(await repo.saveSnapshotCount == 1)
        #expect(store.session(for: matchId)?.runtime.eventCount == 0)
    }

    @MainActor
    @Test
    func matchTurnSupportMatchProgressMetadataReflectsSession() throws {
        var session = try MatchLifecycleService.createMatch(
            type: .x01,
            config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
            participants: [
                MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "A", turnOrder: 0),
                MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "B", turnOrder: 1)
            ]
        )
        session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
        let metadata = MatchTurnSupport.matchProgressMetadata(for: session)
        #expect(metadata["eventCount"] == "1")
        #expect(metadata["status"] == MatchLifecycleStatus.inProgress.rawValue)
    }

    @MainActor
    @Test
    func matchTurnSupportMapsRuntimeToSummary() throws {
        let session = try MatchLifecycleService.createMatch(
            type: .x01,
            config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
            participants: [
                MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "A", turnOrder: 0),
                MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "B", turnOrder: 1)
            ]
        )
        let summary = MatchTurnSupport.matchSummary(from: session.runtime)
        #expect(summary.id == session.runtime.matchId)
        #expect(summary.status == .inProgress)
        #expect(summary.type == .x01)
    }

    @MainActor
    @Test
    func matchTurnSupportErrorHelpersMapAppError() {
        let error = AppError(code: .validationFailed, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.match.invalidTurn")
        #expect(MatchTurnSupport.errorMessageKey(for: error, fallback: "fallback") == "error.match.invalidTurn")
        #expect(MatchTurnSupport.appErrorMetadata(for: error)["errorCode"] == ErrorCode.validationFailed.rawValue)
        #expect(MatchTurnSupport.errorMessageKey(for: NSError(domain: "test", code: 1), fallback: "fallback") == "fallback")
    }

    @MainActor
    @Test
    func matchTurnSupportUndoLastDartRestoresPartialVisit() async throws {
        func dart(_ multiplier: DartMultiplier, _ value: Int) -> DartInput {
            DartInput(multiplier: multiplier, segment: .oneToTwenty(value))
        }
        var session = try MatchLifecycleService.createMatch(
            type: .x01,
            config: .x01(MatchConfigX01(
                startScore: 301,
                legsToWin: 1,
                setsEnabled: false,
                setsToWin: nil,
                checkoutMode: .singleOut
            )),
            participants: [
                MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "A", turnOrder: 0),
                MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "B", turnOrder: 1)
            ]
        )
        session = try MatchLifecycleService.submitX01Turn(
            session: session,
            enteredTotal: nil,
            darts: [dart(.triple, 20), dart(.triple, 20), dart(.single, 20)]
        )
        let matchId = session.runtime.matchId
        let repo = TurnSubmitterFakeMatchRepository()
        let store = ActiveMatchStore()
        store.save(session)

        let result = try await MatchTurnSupport.undoLastDart(
            session: session,
            matchId: matchId,
            store: store,
            matchRepository: repo
        )

        #expect(result.restoredDarts.count == 2)
        #expect(result.session.runtime.eventCount == 0)
        #expect(store.session(for: matchId)?.runtime.eventCount == 0)
    }
}

@MainActor
private func makeSubmitter(
    matchId: UUID,
    repository: TurnSubmitterFakeMatchRepository,
    store: ActiveMatchStore
) -> MatchTurnSubmitter {
    MatchTurnSubmitter(
        matchId: matchId,
        matchType: .x01,
        eventTypeRaw: "x01Turn",
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TurnSubmitterSilentLogSink()),
        matchRepository: repository
    )
}

private struct SubmitterFixture {
    let matchId: UUID
    let session: MatchLifecycleSession
}

private func makeSubmitterFixture(afterTotals: [Int]) throws -> SubmitterFixture {
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(
            startScore: 301,
            legsToWin: 1,
            setsEnabled: false,
            setsToWin: nil,
            checkoutMode: .singleOut
        )),
        participants: [
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    for total in afterTotals {
        session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: total, darts: nil)
    }
    return SubmitterFixture(matchId: session.runtime.matchId, session: session)
}

private actor TurnSubmitterFakeMatchRepository: MatchRepository {
    private(set) var appendCount = 0
    private(set) var updateCount = 0
    private(set) var completeCount = 0
    private(set) var saveSnapshotCount = 0
    let failAppend: Bool

    init(failAppend: Bool = false) {
        self.failAppend = failAppend
    }

    func createMatch(type: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        makeSummary(type: type, status: .inProgress)
    }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws { updateCount += 1 }
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary {
        completeCount += 1
        return makeSummary(type: .x01, status: .completed)
    }
    func appendEvent(matchId: UUID, eventTypeRaw: String, eventPayload: Data) async throws -> MatchEventSummary {
        if failAppend {
            throw AppError(
                code: .storageUnavailable,
                layer: .data,
                severity: .error,
                isRecoverable: true,
                userMessageKey: "error.repository.storage"
            )
        }
        appendCount += 1
        return MatchEventSummary(
            id: UUID(),
            matchId: matchId,
            eventIndex: appendCount - 1,
            eventTypeRaw: eventTypeRaw,
            eventPayload: eventPayload,
            createdAt: Date()
        )
    }
    func saveSnapshot(matchId: UUID, snapshotVersion: Int, snapshotPayload: Data) async throws -> MatchSnapshotSummary {
        saveSnapshotCount += 1
        return MatchSnapshotSummary(
            id: UUID(),
            matchId: matchId,
            snapshotVersion: snapshotVersion,
            snapshotPayload: snapshotPayload,
            updatedAt: Date()
        )
    }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}

}

private final class TurnSubmitterSilentLogSink: LogSink, @unchecked Sendable {
    func write(_: LogEntry) {}
}
