import Foundation
import Testing

@MainActor
@Test(.tags(.unit, .player, .regression))
func playerEditValidationRejectsDuplicateName() {
    let vm = PlayerEditViewModel(existingNames: ["Alice"], editing: nil)
    vm.name = "alice"
    vm.validate()
    #expect(!vm.canSave)
    #expect(vm.validationMessage == "player.validation.duplicateName")
}

@MainActor
@Test(.tags(.integration, .history, .match, .regression))
func historyFiltersByModeDeterministically() async {
    let now = Date()
    let vm = HistoryListViewModel(
        matchRepository: FakeHistoryMatchRepository(
            rows: [
                MatchSummary(
                    id: UUID(),
                    type: .x01,
                    status: .completed,
                    startedAt: now,
                    endedAt: now,
                    winnerPlayerId: nil,
                    currentTurnPlayerId: nil,
                    currentLegIndex: 0,
                    currentSetIndex: 0,
                    eventCount: 10,
                    createdAt: now,
                    updatedAt: now
                ),
                MatchSummary(
                    id: UUID(),
                    type: .cricket,
                    status: .completed,
                    startedAt: now,
                    endedAt: now,
                    winnerPlayerId: nil,
                    currentTurnPlayerId: nil,
                    currentLegIndex: 0,
                    currentSetIndex: 0,
                    eventCount: 12,
                    createdAt: now,
                    updatedAt: now
                )
            ]
        )
    )
    vm.modeFilter = .x01
    await vm.applyFilters()

    #expect(vm.rows.count == 1)
    #expect(vm.rows.first?.summary.type == .x01)
}

private actor FakeHistoryMatchRepository: MatchRepository {
    let rows: [MatchSummary]
    init(rows: [MatchSummary]) {
        self.rows = rows
    }

    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary { rows.first! }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { rows }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int) async throws -> [MatchHistoryRecord] {
        rows.map { MatchHistoryRecord(summary: $0, participants: []) }
    }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary { rows.first! }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func saveSnapshot(matchId _: UUID, snapshotVersion _: Int, snapshotPayload _: Data) async throws -> MatchSnapshotSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
}
