import SwiftUI

/// Dart Buddy wordmark at the top of the Play tab.
struct BrandAppTitle: View {
    var body: some View {
        BrandRootScreenTitle(title: L10n.brandTitle)
            .accessibilityIdentifier("brand_app_title")
    }
}

/// Launch splash wordmark — rounded heavy type distinct from in-app titles.
struct LaunchSplashWordmark: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var wordmarkFont: Font {
        if dynamicTypeSize.isAccessibilitySize {
            return .system(.title, design: .rounded).weight(.bold)
        }
        return .system(size: 34, weight: .heavy, design: .rounded)
    }

    var body: some View {
        Text(L10n.brandTitle)
            .font(wordmarkFont)
            .foregroundStyle(Brand.textPrimary)
            .tracking(0.6)
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

/// In-match gameplay headers (X01, Cricket, party/solo modes).
struct BrandMatchScreenTitle: View {
    /// Resolved copy so keys in `GameplayModes.strings` localize correctly.
    private let title: String

    init(title key: String) {
        self.title = L10n.string(key)
    }

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var titleFont: Font {
        verticalSizeClass == .compact
            ? .headline.weight(.bold)
            : .title2.weight(.bold)
    }

    var body: some View {
        Text(title)
            .font(titleFont)
            .foregroundStyle(Brand.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
    }
}
