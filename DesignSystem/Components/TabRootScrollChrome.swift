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
}
