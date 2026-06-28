import SwiftUI

struct StatChip: View {
    let value: String
    let label: String
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(compact ? .subheadline.weight(.bold).monospacedDigit() : .title3.weight(.bold).monospacedDigit())
                .foregroundStyle(Brand.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(compact ? 0.85 : 1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Brand.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(compact ? 0.7 : 0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }
}
