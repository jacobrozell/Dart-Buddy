import SwiftUI

/// Dart Buddy wordmark at the top of the Play tab.
struct BrandAppTitle: View {
    var body: some View {
        BrandRootScreenTitle(title: L10n.brandTitle)
            .accessibilityIdentifier("brand_app_title")
    }
}

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
