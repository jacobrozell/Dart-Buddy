import SwiftUI

enum GameplayLayout {
    /// Readable column for setup, summary, and list-style screens on iPad.
    static func contentMaxWidth(horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .regular ? 760 : .infinity
    }

    /// Active X01/Cricket scoreboards use full width; horizontal padding defines the margins.
    static func matchContentMaxWidth(horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        .infinity
    }

    /// X01 uses a scrollable score region with a pinned pad at accessibility text sizes (AX1–AX5).
    static func usesAccessibilityMatchScoringLayout(dynamicTypeSize: DynamicTypeSize) -> Bool {
        dynamicTypeSize.isAccessibilitySize
    }
}
