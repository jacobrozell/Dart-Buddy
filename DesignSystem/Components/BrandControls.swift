import SwiftUI

/// Segmented control for scoreboard screens (mode, stats period, etc.).
struct BrandSegmented<T: Hashable>: View {
    let options: [(value: T, title: String)]
    @Binding var selection: T
    var accessibilityIdentifiers: [T: String] = [:]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                let isSelected = selection == option.value
                Button {
                    selection = option.value
                } label: {
                    Text(option.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Spacing.s2)
                        .background(
                            isSelected ? Brand.cardElevated : Color.clear,
                            in: RoundedRectangle(cornerRadius: DS.Radius.sm)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .modifier(OptionalAccessibilityIdentifier(identifier: accessibilityIdentifiers[option.value]))
            }
        }
        .padding(4)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
    }
}

/// A "FINISHED" style status badge.
struct StatusBadge: View {
    let text: String
    let color: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(Brand.textPrimary)
            .padding(.horizontal, DS.Spacing.s2)
            .padding(.vertical, 2)
            .background(
                color.opacity(colorScheme == .dark ? 0.30 : 0.20),
                in: RoundedRectangle(cornerRadius: DS.Radius.sm)
            )
    }
}
