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
                        .foregroundStyle(.white)
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
struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(color)
    }
}
