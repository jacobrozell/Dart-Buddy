import SwiftUI

/// Root tab screens (Play, Statistics, Settings).
struct BrandRootScreenTitle: View {
    let title: LocalizedStringKey

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var titleFont: Font {
        dynamicTypeSize.isAccessibilitySize
            ? .title.weight(.bold)
            : .largeTitle.weight(.heavy)
    }

    var body: some View {
        Text(title)
            .font(titleFont)
            .foregroundStyle(Brand.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }
}

/// In-match gameplay headers (X01, Cricket).
struct BrandMatchScreenTitle: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(.title2.weight(.bold))
            .foregroundStyle(Brand.textPrimary)
    }
}
