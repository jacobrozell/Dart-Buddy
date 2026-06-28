import SwiftUI

/// Team cricket marks on shield segments 20→16 during Raid's Shield phase.
struct RaidShieldProgressView: View {
    let teamMarks: [Int: Int]
    let closedSegments: Set<Int>

    private static let displayOrder = [20, 19, 18, 17, 16]
    private static let teamColor: PlayerColorToken = .amber

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Text(L10n.string("play.raid.shieldProgress.title"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.textSecondary)

            HStack(spacing: DS.Spacing.s2) {
                ForEach(Self.displayOrder, id: \.self) { segment in
                    segmentCell(segment)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("raid_shield_progress")
    }

    @ViewBuilder
    private func segmentCell(_ segment: Int) -> some View {
        let marks = teamMarks[segment, default: 0]
        let isClosed = closedSegments.contains(segment)

        VStack(spacing: 4) {
            Text("\(segment)")
                .font(.caption2.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(isClosed ? Brand.green : Brand.textPrimary)

            if isClosed {
                Image(systemName: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundStyle(Brand.green)
                    .frame(width: 26, height: 26)
                    .accessibilityLabel(L10n.format("play.raid.shieldProgress.closedFormat", segment))
            } else {
                CricketMarkCell(
                    targetLabel: "\(segment)",
                    marks: marks,
                    colorToken: Self.teamColor
                )
                .frame(width: 26, height: 26)
            }

            if isClosed {
                Text(L10n.string("play.raid.shieldProgress.damageBadge"))
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(Brand.green)
            } else {
                Color.clear.frame(height: 11)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.s1)
        .padding(.horizontal, 2)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.xs))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(segmentAccessibilityLabel(segment: segment, marks: marks, isClosed: isClosed))
    }

    private func segmentAccessibilityLabel(segment: Int, marks: Int, isClosed: Bool) -> String {
        if isClosed {
            return L10n.format("play.raid.shieldProgress.closedFormat", segment)
        }
        let markState: String
        switch marks {
        case 0: markState = L10n.string("cricket.mark.open")
        case 1: markState = L10n.string("cricket.mark.one")
        case 2: markState = L10n.string("cricket.mark.two")
        default: markState = L10n.string("cricket.mark.closed")
        }
        return L10n.format("cricket.mark.accessibilityFormat", "\(segment)", markState)
    }
}
