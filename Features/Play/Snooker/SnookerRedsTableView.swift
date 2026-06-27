import SwiftUI

struct SnookerRedsTableView: View {
    let availableReds: Set<Int>

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s1) {
            Text(L10n.format("play.snooker.redsRemainingFormat", availableReds.count))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.textSecondary)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(1 ... 15, id: \.self) { segment in
                    Text("\(segment)")
                        .font(.caption2.weight(.semibold).monospacedDigit())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.xs)
                                .fill(availableReds.contains(segment) ? Brand.red.opacity(0.85) : Brand.card.opacity(0.35))
                        )
                        .foregroundStyle(availableReds.contains(segment) ? Color.white : Brand.textSecondary.opacity(0.4))
                        .accessibilityLabel(
                            availableReds.contains(segment)
                                ? L10n.format("play.snooker.redAvailableAccessibilityFormat", segment)
                                : L10n.format("play.snooker.redPocketedAccessibilityFormat", segment)
                        )
                }
            }
        }
        .accessibilityIdentifier("snooker_reds_table")
    }
}
