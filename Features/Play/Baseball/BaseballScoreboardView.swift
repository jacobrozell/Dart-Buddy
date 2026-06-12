import SwiftUI

struct BaseballScoreboardView: View {
    enum VisitRunsKind: Equatable {
        case inning
        case playoffRound
    }

    struct Row: Identifiable {
        let id: UUID
        let name: String
        let cumulativeRuns: Int
        let visitRuns: Int?
        let visitRunsKind: VisitRunsKind?
        let isActive: Bool
        let isLeading: Bool
        let colorToken: PlayerColorToken
    }

    let rows: [Row]
    let showsVisitRunsColumn: Bool

    var body: some View {
        MatchScoreboardListView(
            entries: rows.map { row in
                MatchScoreboardListView.Entry(
                    id: row.id,
                    name: row.name,
                    totalText: "\(row.cumulativeRuns)",
                    secondaryText: secondaryText(for: row),
                    leadingText: row.isLeading ? L10n.string("play.baseball.leading") : nil,
                    isActive: row.isActive,
                    colorToken: row.colorToken,
                    accessibilityLabel: rowAccessibilityLabel(row)
                )
            },
            accessibilityIdentifierPrefix: "baseball"
        )
    }

    private func secondaryText(for row: Row) -> String? {
        guard showsVisitRunsColumn, let visitRuns = row.visitRuns, let kind = row.visitRunsKind else { return nil }
        switch kind {
        case .inning:
            return L10n.format("play.baseball.thisInningFormat", visitRuns)
        case .playoffRound:
            return L10n.format("play.baseball.playoffRoundFormat", visitRuns)
        }
    }

    private func rowAccessibilityLabel(_ row: Row) -> String {
        var parts = [row.name, L10n.format("play.baseball.totalRunsAccessibilityFormat", row.cumulativeRuns)]
        if let visitRuns = row.visitRuns, let kind = row.visitRunsKind {
            switch kind {
            case .inning:
                parts.append(L10n.format("play.baseball.thisInningAccessibilityFormat", visitRuns))
            case .playoffRound:
                parts.append(L10n.format("play.baseball.playoffRoundAccessibilityFormat", visitRuns))
            }
        }
        if row.isLeading {
            parts.append(L10n.string("play.baseball.leading"))
        }
        return parts.joined(separator: ", ")
    }
}

struct InningProgressStrip: View {
    let inningCount: Int
    let currentInning: Int
    let isExtraInning: Bool

    var body: some View {
        MatchProgressDotStrip(
            count: inningCount,
            current: currentInning,
            accessibilityLabel: L10n.format(
                "play.baseball.inningStrip.accessibilityFormat",
                currentInning,
                max(inningCount, currentInning),
                currentInning
            )
        )
    }
}
