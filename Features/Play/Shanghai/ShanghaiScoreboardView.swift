import SwiftUI

struct ShanghaiScoreboardView: View {
    struct Row: Identifiable {
        let id: UUID
        let name: String
        let cumulativePoints: Int
        let roundPoints: Int?
        let isActive: Bool
        let isLeading: Bool
        let colorToken: PlayerColorToken
    }

    let rows: [Row]
    let showsRoundPointsColumn: Bool

    var body: some View {
        MatchScoreboardListView(
            entries: rows.map { row in
                MatchScoreboardListView.Entry(
                    id: row.id,
                    name: row.name,
                    totalText: "\(row.cumulativePoints)",
                    secondaryText: showsRoundPointsColumn
                        ? row.roundPoints.map { L10n.format("play.shanghai.thisRoundFormat", $0) }
                        : nil,
                    leadingText: row.isLeading ? L10n.string("play.shanghai.leading") : nil,
                    isActive: row.isActive,
                    colorToken: row.colorToken,
                    accessibilityLabel: rowAccessibilityLabel(row)
                )
            },
            accessibilityIdentifierPrefix: "shanghai"
        )
    }

    private func rowAccessibilityLabel(_ row: Row) -> String {
        var parts = [row.name, L10n.format("play.shanghai.totalPointsAccessibilityFormat", row.cumulativePoints)]
        if let roundPoints = row.roundPoints {
            parts.append(L10n.format("play.shanghai.thisRoundAccessibilityFormat", roundPoints))
        }
        if row.isActive {
            parts.append(L10n.string("common.active"))
        }
        if row.isLeading {
            parts.append(L10n.string("play.shanghai.leading"))
        }
        return parts.joined(separator: ", ")
    }
}

struct RoundProgressStrip: View {
    let roundCount: Int
    let currentRound: Int
    let isExtraRound: Bool

    var body: some View {
        MatchProgressDotStrip(
            count: roundCount,
            current: currentRound,
            accessibilityLabel: roundStripAccessibilityLabel(totalDots: max(roundCount, currentRound))
        )
    }

    private func roundStripAccessibilityLabel(totalDots: Int) -> String {
        var label = L10n.format(
            "play.shanghai.roundStrip.accessibilityFormat",
            currentRound,
            totalDots,
            currentRound
        )
        if isExtraRound {
            label += ", \(L10n.string("play.shanghai.extraRound"))"
        }
        return label
    }
}
