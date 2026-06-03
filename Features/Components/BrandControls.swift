import SwiftUI

/// Capsule segmented control matching the reference app's pill toggles.
struct BrandSegmented<T: Hashable>: View {
    let options: [(value: T, title: String)]
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
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
                        .background(selection == option.value ? Brand.cardElevated : Color.clear, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.title)
                .accessibilityAddTraits(selection == option.value ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Brand.card, in: Capsule())
    }
}

/// A "FINISHED" style status pill.
///
/// Renders as a tinted capsule rather than bare colored text: a saturated accent used directly
/// as small-text foreground fails WCAG AA on at least one appearance (e.g. green on the white
/// light-mode card is ~2.9:1). The tint carries the color cue while `textPrimary` keeps the
/// label at AA contrast in both light and dark mode.
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
                in: Capsule()
            )
    }
}
