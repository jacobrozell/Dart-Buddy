import SwiftUI

/// Bottom padding for tab-root scroll content so the last rows clear the tab bar at accessibility sizes.
struct TabRootScrollChrome: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        content.padding(.bottom, GameplayLayout.tabScrollBottomPadding(dynamicTypeSize: dynamicTypeSize))
    }
}

extension View {
    func tabRootScrollChrome() -> some View {
        modifier(TabRootScrollChrome())
    }

    /// Full-width scoreboard background for tab-root navigation content.
    /// Apply to the root stack inside `NavigationStack`, not to width-constrained children.
    func tabRootScreenBackground() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Brand.background.ignoresSafeArea())
    }
}
