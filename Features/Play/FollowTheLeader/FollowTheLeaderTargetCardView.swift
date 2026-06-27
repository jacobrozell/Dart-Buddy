import SwiftUI

struct FollowTheLeaderTargetCardView: View {
    let target: FollowTheLeaderTargetArea?
    let isOpening: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Text(isOpening ? L10n.string("play.followTheLeader.openingTargetTitle") : L10n.string("play.followTheLeader.currentTargetTitle"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.textSecondary)
            if let target {
                Text(target.displayLabel)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Brand.textPrimary)
            } else if isOpening {
                Text(L10n.string("play.followTheLeader.nonDominantPickReminder"))
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
            } else {
                Text("—")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Brand.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.s3)
        .background(Brand.cardElevated, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
    }
}
