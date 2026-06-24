import SwiftUI

enum SetupOptionChipHelpers {
    static func chip<Content: View>(
        titleKey: String,
        color: Color,
        dynamicTypeSize: DynamicTypeSize,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 6) {
            Text(L10n.string(titleKey))
                .font(.caption)
                .foregroundStyle(Brand.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            content()
        }
        .frame(maxWidth: .infinity)
    }

    static func chipBox(
        _ text: String,
        color: Color,
        dynamicTypeSize: DynamicTypeSize,
        showsMenuIndicator: Bool = false
    ) -> some View {
        Text(text)
            .font(.headline.weight(.bold))
            .foregroundStyle(Brand.textPrimary)
            .lineLimit(2)
            .minimumScaleFactor(0.6)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: dynamicTypeSize.isAccessibilitySize ? 56 : 52)
            .padding(.horizontal, 4)
            .background(color, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
            .overlay(alignment: .topTrailing) {
                if showsMenuIndicator {
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Brand.textSecondary)
                        .padding(5)
                        .accessibilityHidden(true)
                }
            }
    }

    static func chipAccessibilityLabel(_ titleKey: String, _ value: String) -> String {
        L10n.format("play.setup.chip.accessibilityFormat", L10n.string(titleKey), value)
    }
}
