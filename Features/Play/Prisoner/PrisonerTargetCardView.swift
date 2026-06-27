import SwiftUI

struct PrisonerTargetCardView: View {
    let target: Int?
    let dartsAvailable: Int
    let stuckOnBoard: Int

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Text(L10n.string("play.prisoner.currentTargetTitle"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.textSecondary)
            if let target {
                Text(L10n.format("play.prisoner.progressSegmentFormat", target))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(Brand.textPrimary)
                    .accessibilityLabel(L10n.format("play.prisoner.progressSegmentFormat", target))
            } else {
                Text(L10n.string("play.prisoner.completed"))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Brand.green)
            }
            HStack(spacing: DS.Spacing.s3) {
                Label(
                    L10n.format("play.prisoner.dartPoolFormat", dartsAvailable),
                    systemImage: "circle.grid.3x3.fill"
                )
                if stuckOnBoard > 0 {
                    Label(
                        L10n.format("play.prisoner.stuckDartsFormat", stuckOnBoard),
                        systemImage: "pin.fill"
                    )
                    .foregroundStyle(Brand.amber)
                }
            }
            .font(.caption)
            .foregroundStyle(Brand.textSecondary)
            Text(L10n.string("play.prisoner.playableRingHint"))
                .font(.caption2)
                .foregroundStyle(Brand.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.s3)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }
}
