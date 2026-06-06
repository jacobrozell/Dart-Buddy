import SwiftUI

/// Segmented control for scoreboard screens (mode, stats period, etc.).
struct BrandSegmented<T: Hashable>: View {
    let options: [(value: T, title: String)]
    @Binding var selection: T
    var accessibilityIdentifiers: [T: String] = [:]
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var usesScrollingSegments: Bool {
        dynamicTypeSize.isAccessibilitySize
            || (horizontalSizeClass == .regular && options.count > 4)
    }

    var body: some View {
        Group {
            if usesScrollingSegments {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(options.indices, id: \.self) { index in
                            segmentButton(at: index, expands: false)
                        }
                    }
                    .padding(4)
                }
            } else {
                HStack(spacing: 0) {
                    ForEach(options.indices, id: \.self) { index in
                        segmentButton(at: index, expands: true)
                    }
                }
                .padding(4)
            }
        }
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
    }

    private func segmentButton(at index: Int, expands: Bool) -> some View {
        let option = options[index]
        let isSelected = selection == option.value
        let allowsMultilineLabel = dynamicTypeSize.isAccessibilitySize
        return Button {
            selection = option.value
        } label: {
            Text(option.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.textPrimary)
                .lineLimit(allowsMultilineLabel ? 2 : 1)
                .minimumScaleFactor(expands && !allowsMultilineLabel ? 0.8 : 1)
                .padding(.horizontal, expands ? 0 : DS.Spacing.s3)
                .frame(maxWidth: expands ? .infinity : nil, minHeight: 44)
                .contentShape(Rectangle())
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
