import Foundation
import Testing
@testable import DartBuddy

@Suite("Match forfeit support", .tags(.unit, .match, .regression))
struct MatchForfeitSupportTests {
    @Test
    @MainActor
    func persistForfeitMarksMatchForfeitedAndClearsStore() async throws {
        let forfeiter = UUID()
        let winner = UUID()
        var session = try MatchLifecycleService.createMatch(
            type: .x01,
            config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
            participants: [
                MatchParticipant(playerId: forfeiter, displayNameAtMatchStart: "Alice", turnOrder: 0),
                MatchParticipant(playerId: winner, displayNameAtMatchStart: "Bob", turnOrder: 1)
            ]
        )
        session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)

        let matchId = session.runtime.matchId
        let store = ActiveMatchStore()
        store.save(session)
        let repository = ForfeitSupportTrackingMatchRepository()

        let result = try await MatchForfeitSupport.persistForfeit(
            session: session,
            forfeitingPlayerId: forfeiter,
            winnerPlayerId: winner,
            matchId: matchId,
            store: store,
            matchRepository: repository,
            logger: DefaultAppLogger(minimumLevel: .fault, sink: ForfeitSupportSilentLogSink()),
            matchType: .x01,
            resolution: "automatic"
        )

        #expect(result.runtime.status == .forfeited)
        #expect(result.runtime.forfeitedByPlayerId == forfeiter)
        #expect(result.runtime.winnerPlayerId == winner)
        #expect(store.session(for: matchId) == nil)
        #expect(await repository.updateCount == 1)
        #expect(await repository.snapshotSaveCount == 1)
        #expect(await repository.forfeitCallCount == 1)
        let forfeitArgs = try #require(await repository.lastForfeitArgs)
        #expect(forfeitArgs.winner == winner)
        #expect(forfeitArgs.forfeitedBy == forfeiter)
    }

    @Test
    @MainActor
    func persistForfeitWorksForBaseballMatch() async throws {
        let forfeiter = UUID()
        let winner = UUID()
        var session = try MatchLifecycleService.createMatch(
            type: .baseball,
            config: MatchConfigDefaults.config(for: .baseball),
            participants: [
                MatchParticipant(playerId: forfeiter, displayNameAtMatchStart: "Alice", turnOrder: 0),
                MatchParticipant(playerId: winner, displayNameAtMatchStart: "Bob", turnOrder: 1)
            ]
        )
        session = try MatchLifecycleService.submitBaseballTurn(
            session: session,
            darts: [DartInput(multiplier: .single, segment: .miss, isMiss: true)]
        )

        let matchId = session.runtime.matchId
        let store = ActiveMatchStore()
        store.save(session)
        let repository = ForfeitSupportTrackingMatchRepository()

        let result = try await MatchForfeitSupport.persistForfeit(
            session: session,
            forfeitingPlayerId: forfeiter,
            winnerPlayerId: winner,
            matchId: matchId,
            store: store,
            matchRepository: repository,
            logger: DefaultAppLogger(minimumLevel: .fault, sink: ForfeitSupportSilentLogSink()),
            matchType: .baseball,
            resolution: "automatic"
        )

        #expect(result.runtime.status == .forfeited)
        #expect(result.runtime.type == .baseball)
        #expect(store.session(for: matchId) == nil)
        #expect(await repository.forfeitCallCount == 1)
    }
}

private struct ForfeitSupportSilentLogSink: LogSink {
    func write(_: LogEntry) {}
}

private struct ForfeitRecord {
    let winner: UUID?
    let forfeitedBy: UUID
}

private actor ForfeitSupportTrackingMatchRepository: MatchRepository {
    private(set) var updateCount = 0
    private(set) var snapshotSaveCount = 0
    private(set) var forfeitCallCount = 0
    private(set) var lastForfeitArgs: ForfeitRecord?

    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented")
    }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws { updateCount += 1 }
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented")
    }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented")
    }
    func saveSnapshot(matchId _: UUID, snapshotVersion _: Int, snapshotPayload _: Data) async throws -> MatchSnapshotSummary {
        snapshotSaveCount += 1
        return MatchSnapshotSummary(id: UUID(), matchId: UUID(), snapshotVersion: 1, snapshotPayload: Data(), updatedAt: Date())
    }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}
    func forfeitMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId: UUID?, forfeitedByPlayerId: UUID) async throws -> MatchSummary {
        forfeitCallCount += 1
        lastForfeitArgs = ForfeitRecord(winner: winnerPlayerId, forfeitedBy: forfeitedByPlayerId)
        return MatchSummary(
            id: UUID(),
            type: .x01,
            status: .forfeited,
            startedAt: Date(),
            endedAt: Date(),
            winnerPlayerId: winnerPlayerId,
            forfeitedByPlayerId: forfeitedByPlayerId,
            currentTurnPlayerId: nil,
            currentLegIndex: 0,
            currentSetIndex: 0,
            eventCount: 1,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
