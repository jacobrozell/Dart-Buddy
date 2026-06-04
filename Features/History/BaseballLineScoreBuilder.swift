import Foundation

struct BaseballLineScore: Equatable {
    struct PlayerRow: Equatable, Identifiable {
        let id: UUID
        let name: String
        let runsByInning: [Int: Int]
        let total: Int
    }

    let inningColumns: [Int]
    let rows: [PlayerRow]
    let playoffTurnCount: Int
}

enum BaseballLineScoreBuilder {
    static func build(
        turns: [BaseballTurnEvent],
        participants: [(playerId: UUID, name: String, turnOrder: Int)],
        scheduledInningCount: Int
    ) -> BaseballLineScore {
        var runsByPlayerInning: [UUID: [Int: Int]] = [:]
        var maxInning = max(1, scheduledInningCount)
        var playoffTurnCount = 0

        for turn in turns {
            if turn.phase != .innings {
                if turn.phase == .bullPlayoff {
                    playoffTurnCount += 1
                }
                continue
            }
            maxInning = max(maxInning, turn.inning)
            var playerRuns = runsByPlayerInning[turn.playerId, default: [:]]
            playerRuns[turn.inning, default: 0] += turn.runsThisVisit
            runsByPlayerInning[turn.playerId] = playerRuns
        }

        let inningColumns = Array(1 ... maxInning)
        let orderedParticipants = participants.sorted { $0.turnOrder < $1.turnOrder }
        let rows = orderedParticipants.map { participant in
            let inningRuns = runsByPlayerInning[participant.playerId] ?? [:]
            let total = inningRuns.values.reduce(0, +)
            return BaseballLineScore.PlayerRow(
                id: participant.playerId,
                name: participant.name,
                runsByInning: inningRuns,
                total: total
            )
        }

        return BaseballLineScore(
            inningColumns: inningColumns,
            rows: rows,
            playoffTurnCount: playoffTurnCount
        )
    }
}
