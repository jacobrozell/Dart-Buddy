import Foundation
@testable import DartBuddy

/// Minimal `MatchSummary` for stub repositories and view-model tests.
func makeSummary(type: MatchType, status: MatchStatus) -> MatchSummary {
    MatchSummary(
        id: UUID(),
        type: type,
        status: status,
        startedAt: Date(),
        endedAt: status == .completed ? Date() : nil,
        winnerPlayerId: nil,
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: 0,
        createdAt: Date(),
        updatedAt: Date()
    )
}
