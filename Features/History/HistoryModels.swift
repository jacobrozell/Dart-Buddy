import Foundation

struct HistoryStanding: Identifiable, Equatable {
    let id: UUID
    let name: String
    let isWinner: Bool
    let sets: Int
    let legs: Int
    let score: Int
}

struct HistoryListRow: Identifiable, Equatable {
    let summary: MatchSummary
    let dateText: String
    let configText: String
    let standings: [HistoryStanding]
    let isFinished: Bool
    let isForfeited: Bool

    var id: UUID { summary.id }

    var accessibilitySummary: String {
        let players = standings.map { standing in
            MatchConfigText.standingAccessibility(
                name: standing.name,
                isWinner: standing.isWinner,
                score: standing.score
            )
        }.joined(separator: ". ")
        var summary = L10n.format("history.row.accessibilityFormat", dateText, configText, players)
        if isForfeited {
            summary += " " + L10n.string("history.row.forfeitAccessibilitySuffix")
        }
        return summary
    }
}

struct HistoryDetailHeader: Equatable {
    let modeText: String
    let winnerText: String
    let dateText: String
    let durationText: String
    let participantsText: String
    let modeSpecificSummaryText: String
}

struct ThrowStatRow: Identifiable, Equatable {
    let id: UUID
    let name: String
    let throwCount: Int
    let doublePercent: Double
    let triplePercent: Double
}
