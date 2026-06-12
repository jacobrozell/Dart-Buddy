import SwiftUI

/// Scoreboard showing each player's name, strike indicators, and elimination status.
/// The large `currentHigh` banner is rendered in `KnockoutMatchScreen` above this view.
struct KnockoutScoreboardView: View {
    struct Row: Identifiable {
        let id: UUID
        let name: String
        /// Strikes accrued so far.
        let strikes: Int
        /// Total strikes required for elimination (from config).
        let maxStrikes: Int
        let isActive: Bool
        let isEliminated: Bool
        let colorToken: PlayerColorToken
    }

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let rows: [Row]
    let currentHigh: Int

    private var usesLandscapeLayout: Bool {
        GameplayLayout.usesLandscapeMatchScoringLayout(verticalSizeClass: verticalSizeClass)
    }

    var body: some View {
        VStack(spacing: usesLandscapeLayout ? DS.Spacing.s3 : DS.Spacing.s2) {
            currentHighBanner
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                playerRow(row, index: index)
            }
        }
    }

    // MARK: - Current-high banner

    private var currentHighBanner: some View {
        VStack(spacing: DS.Spacing.s1) {
            Text(L10n.string("play.knockout.currentHighLabel"))
                .font(usesLandscapeLayout ? .caption : .caption2)
                .foregroundStyle(Brand.textSecondary)
            Text("\(currentHigh)")
                .font(usesLandscapeLayout ? .system(size: 52, weight: .black) : .system(size: 44, weight: .black))
                .foregroundStyle(currentHigh > 0 ? Brand.amber : Brand.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, usesLandscapeLayout ? DS.Spacing.s3 : DS.Spacing.s2)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.format("play.knockout.currentHighFormat", currentHigh))
        .accessibilityIdentifier("knockout_current_high")
    }

    // MARK: - Player row

    private func playerRow(_ row: Row, index: Int) -> some View {
        HStack(spacing: DS.Spacing.s3) {
            Circle()
                .fill(PlayerVisualViews.color(for: row.colorToken))
                .frame(width: usesLandscapeLayout ? 12 : 10, height: usesLandscapeLayout ? 12 : 10)

            Text(row.name)
                .font(
                    usesLandscapeLayout
                        ? .body.weight(row.isActive ? .bold : .regular)
                        : .subheadline.weight(row.isActive ? .bold : .regular)
                )
                .foregroundStyle(row.isEliminated ? Brand.textSecondary.opacity(0.5) : Brand.textPrimary)
                .lineLimit(1)
                .strikethrough(row.isEliminated)

            Spacer()

            strikeIndicators(for: row)
        }
        .padding(.horizontal, usesLandscapeLayout ? DS.Spacing.s4 : DS.Spacing.s3)
        .padding(.vertical, usesLandscapeLayout ? DS.Spacing.s3 : DS.Spacing.s2)
        .background(
            row.isEliminated
                ? Brand.card.opacity(0.5)
                : (row.isActive ? Brand.cardElevated : Brand.card),
            in: RoundedRectangle(cornerRadius: DS.Radius.sm)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rowAccessibilityLabel(row))
        .accessibilityIdentifier("knockout_scoreboard_row_\(index)")
    }

    // MARK: - Strike indicators

    private func strikeIndicators(for row: Row) -> some View {
        HStack(spacing: DS.Spacing.s1) {
            ForEach(0 ..< row.maxStrikes, id: \.self) { slot in
                Image(systemName: slot < row.strikes ? "xmark.circle.fill" : "circle")
                    .font(usesLandscapeLayout ? .callout : .caption)
                    .foregroundStyle(strikeColor(slot: slot, row: row))
            }
        }
        .accessibilityHidden(true)
    }

    private func strikeColor(slot: Int, row: Row) -> Color {
        guard slot < row.strikes else { return Brand.textSecondary.opacity(0.35) }
        if row.isEliminated { return Brand.red }
        return row.strikes == row.maxStrikes - 1 ? Brand.amber : Brand.red
    }

    // MARK: - Accessibility

    private func rowAccessibilityLabel(_ row: Row) -> String {
        var parts = [row.name]
        if row.isEliminated {
            parts.append(L10n.string("play.knockout.eliminated"))
        } else {
            parts.append(L10n.format("play.knockout.strikesRemainingFormat", row.maxStrikes - row.strikes))
            parts.append(L10n.format("play.knockout.strikesCountFormat", row.strikes, row.maxStrikes))
        }
        if row.isActive {
            parts.append(L10n.string("common.active"))
        }
        return parts.joined(separator: ", ")
    }
}
