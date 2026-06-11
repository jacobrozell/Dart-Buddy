import SwiftUI

/// Sequence-progress scoreboard for 180 Around the Clock.
/// Displays per-player running totals with active/leading highlights,
/// plus a strip showing progress through numbers 1–20.
struct AroundTheClock180ScoreboardView: View {
    struct Row: Identifiable {
        let id: UUID
        let name: String
        let cumulativePoints: Int
        let isActive: Bool
        let isLeading: Bool
        let colorToken: PlayerColorToken
    }

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let rows: [Row]

    private var usesLandscapeLayout: Bool {
        GameplayLayout.usesLandscapeMatchScoringLayout(verticalSizeClass: verticalSizeClass)
    }

    var body: some View {
        VStack(spacing: usesLandscapeLayout ? DS.Spacing.s3 : DS.Spacing.s2) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                HStack(spacing: DS.Spacing.s3) {
                    Circle()
                        .fill(PlayerVisualViews.color(for: row.colorToken))
                        .frame(
                            width: usesLandscapeLayout ? 12 : 10,
                            height: usesLandscapeLayout ? 12 : 10
                        )
                    Text(row.name)
                        .font(
                            usesLandscapeLayout
                                ? .body.weight(row.isActive || row.isLeading ? .bold : .regular)
                                : .subheadline.weight(row.isActive || row.isLeading ? .bold : .regular)
                        )
                        .foregroundStyle(Brand.textPrimary)
                        .lineLimit(1)
                    if row.isLeading {
                        Text(L10n.string("play.aroundTheClock180.leading"))
                            .font(
                                usesLandscapeLayout
                                    ? .caption.weight(.semibold)
                                    : .caption2.weight(.semibold)
                            )
                            .foregroundStyle(Brand.green)
                    }
                    Spacer()
                    Text("\(row.cumulativePoints)")
                        .font(
                            usesLandscapeLayout
                                ? .title2.weight(.bold)
                                : .title3.weight(.bold)
                        )
                        .foregroundStyle(row.isActive ? Brand.green : Brand.textPrimary)
                        .accessibilityLabel(
                            L10n.format("play.aroundTheClock180.runningTotalAccessibilityFormat", row.cumulativePoints)
                        )
                }
                .padding(.horizontal, usesLandscapeLayout ? DS.Spacing.s4 : DS.Spacing.s3)
                .padding(.vertical, usesLandscapeLayout ? DS.Spacing.s3 : DS.Spacing.s2)
                .background(
                    row.isActive ? Brand.cardElevated : Brand.card,
                    in: RoundedRectangle(cornerRadius: DS.Radius.sm)
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(rowAccessibilityLabel(row))
                .accessibilityIdentifier("atc180_scoreboard_row_\(index)")
            }
        }
    }

    private func rowAccessibilityLabel(_ row: Row) -> String {
        var parts = [
            row.name,
            L10n.format("play.aroundTheClock180.runningTotalAccessibilityFormat", row.cumulativePoints),
        ]
        if row.isActive { parts.append(L10n.string("common.active")) }
        if row.isLeading { parts.append(L10n.string("play.aroundTheClock180.leading")) }
        return parts.joined(separator: ", ")
    }
}

/// Dot strip showing progress through numbers 1–20.
struct ATC180NumberStrip: View {
    let currentNumber: Int
    let totalNumbers: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1 ... totalNumbers, id: \.self) { number in
                Circle()
                    .fill(fillColor(for: number))
                    .frame(width: 10, height: 10)
                    .overlay {
                        if number == currentNumber {
                            Circle().stroke(Brand.green, lineWidth: 2)
                        }
                    }
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            L10n.format(
                "play.aroundTheClock180.numberStrip.accessibilityFormat",
                currentNumber,
                totalNumbers
            )
        )
    }

    private func fillColor(for number: Int) -> Color {
        if number < currentNumber { return Brand.green }
        if number == currentNumber { return Brand.amber }
        return Brand.textSecondary.opacity(0.35)
    }
}
