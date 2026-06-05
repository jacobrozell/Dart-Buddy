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

    /// X01/Cricket scoring uses alternate layout at accessibility text sizes (AX1–AX5).
    static func usesAccessibilityMatchScoringLayout(dynamicTypeSize: DynamicTypeSize) -> Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    /// Number-pad columns: fewer columns at AX sizes so labels stay legible.
    static func scoringPadColumnCount(dynamicTypeSize: DynamicTypeSize) -> Int {
        usesAccessibilityMatchScoringLayout(dynamicTypeSize: dynamicTypeSize) ? 4 : 7
    }

    /// Play setup home uses alternate layout at accessibility text sizes (AX1–AX5).
    static func usesAccessibilitySetupHomeLayout(dynamicTypeSize: DynamicTypeSize) -> Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    /// iPhone landscape (compact vertical height): board and pad side-by-side.
    static func usesLandscapeMatchScoringLayout(verticalSizeClass: UserInterfaceSizeClass?) -> Bool {
        verticalSizeClass == .compact
    }

    /// Fixed scoring pad width in landscape (compact pad targets ~250pt).
    static let landscapeScoringPadWidth: CGFloat = 252
}
