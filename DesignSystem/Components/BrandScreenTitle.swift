import SwiftUI

/// Root tab screens (Play, Statistics, Settings).
struct BrandRootScreenTitle: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(.largeTitle.weight(.heavy))
            .foregroundStyle(Brand.textPrimary)
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
