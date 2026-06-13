import Foundation
import Testing
@testable import DartBuddy

@Suite("Repository protocol defaults", .tags(.unit, .regression))
struct RepositoryProtocolDefaultsTests {
    @Test
    func playerRepositoryDefaultCustomBotMethodsThrow() async {
        let repository = MinimalPlayerRepository()
        await expectUnsupported(method: "createCustomBot") {
            _ = try await repository.createCustomBot(
                name: "Ace",
                metrics: CustomBotMetrics(
                    x01Average: CustomBotMetrics.defaultX01Average,
                    cricketMPR: CustomBotMetrics.defaultCricketMPR
                )
            )
        }
        await expectUnsupported(method: "updateCustomBotMetrics") {
            _ = try await repository.updateCustomBotMetrics(
                playerId: UUID(),
                metrics: CustomBotMetrics(
                    x01Average: CustomBotMetrics.defaultX01Average,
                    cricketMPR: CustomBotMetrics.defaultCricketMPR
                )
            )
        }
        await expectUnsupported(method: "createTrainingBot") {
            _ = try await repository.createTrainingBot(for: UUID())
        }
        await expectUnsupported(method: "resolveTrainingBotSkill") {
            _ = try await repository.resolveTrainingBotSkill(for: UUID(), mode: .x01)
        }
    }

    @Test
    func playerRepositoryDefaultFetchTrainingBotReturnsNil() async throws {
        let repository = MinimalPlayerRepository()
        #expect(try await repository.fetchTrainingBot(linkedTo: UUID()) == nil)
    }

    @Test
    func matchRepositoryDefaultFetchConfigPayloadReturnsNil() async throws {
        let repository = MinimalMatchRepository()
        #expect(try await repository.fetchConfigPayload(matchId: UUID()) == nil)
    }

    @Test
    func matchHistoryRecordStoresSummaryAndParticipants() {
        let matchId = UUID()
        let summary = MatchSummary(
            id: matchId,
            type: .cricket,
            status: .completed,
            startedAt: Date(),
            endedAt: Date(),
            winnerPlayerId: UUID(),
            currentTurnPlayerId: nil,
            currentLegIndex: 0,
            currentSetIndex: 0,
            eventCount: 3,
            createdAt: Date(),
            updatedAt: Date()
        )
        let participants = [
            MatchParticipantSummary(
                id: UUID(),
                matchId: matchId,
                playerId: UUID(),
                turnOrder: 0,
                displayNameAtMatchStart: "Alice",
                avatarStyleAtMatchStart: nil
            )
        ]
        let record = MatchHistoryRecord(summary: summary, participants: participants)
        #expect(record.summary.id == matchId)
        #expect(record.participants.count == 1)
        #expect(record.participants.first?.displayNameAtMatchStart == "Alice")
    }

    private func expectUnsupported(method: String, _ operation: () async throws -> Void) async {
        do {
            try await operation()
            Issue.record("Expected unsupported operation for \(method)")
        } catch let error as AppError {
            #expect(error.userMessageKey == "error.repository.notImplemented")
            #expect(error.debugContext["method"] == method)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}

private actor MinimalPlayerRepository: PlayerRepository {
    func fetchPlayers(includeArchived _: Bool) async throws -> [PlayerSummary] { [] }
    func createPlayer(name _: String) async throws -> PlayerSummary { throw unsupported() }
    func createBot(difficulty _: BotDifficulty) async throws -> PlayerSummary { throw unsupported() }
    func updatePlayerName(playerId _: UUID, name _: String) async throws -> PlayerSummary { throw unsupported() }
    func updatePlayerProfile(
        playerId _: UUID,
        name _: String,
        avatarStyle _: PlayerAvatarStyle,
        colorToken _: PlayerColorToken,
        notes _: String
    ) async throws -> PlayerSummary { throw unsupported() }
    func archivePlayer(playerId _: UUID) async throws {}
    func unarchivePlayer(playerId _: UUID) async throws {}
    func deletePlayer(playerId _: UUID) async throws {}

    private func unsupported() -> AppError {
        AppError(
            code: .unsupportedOperation,
            layer: .data,
            severity: .warning,
            isRecoverable: true,
            userMessageKey: "error.repository.notImplemented",
            debugContext: [:]
        )
    }
}

private actor MinimalMatchRepository: MatchRepository {
    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary { throw unsupported() }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary { throw unsupported() }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary { throw unsupported() }
    func saveSnapshot(matchId _: UUID, snapshotVersion _: Int, snapshotPayload _: Data) async throws -> MatchSnapshotSummary { throw unsupported() }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}

    private func unsupported() -> AppError {
        AppError(
            code: .unsupportedOperation,
            layer: .data,
            severity: .warning,
            isRecoverable: true,
            userMessageKey: "error.repository.notImplemented",
            debugContext: [:]
        )
    }
}
