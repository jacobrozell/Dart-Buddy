import Foundation

/// Controls which product areas are reachable in this build.
///
/// **Debug / `dev`:** defaults to the full catalog (all tabs, party modes, locales).
/// **Release / App Store:** defaults to lean 1.0 (X01 + Cricket picker, 4 tabs, English bundle).
/// Launch args override either default — see `docs/release/branch-strategy.md`.
enum ProductSurface {
    struct Configuration: Sendable, Equatable {
        var showsModesTab: Bool
        var showsPartyModes: Bool
        var showsCoopModes: Bool
        var showsTrainingBots: Bool
        var showsCustomBots: Bool
        var showsPlayerExport: Bool
        var showsAccessibilityMarketing: Bool
        var bundledLocaleCodes: [String]

        static let full = Configuration(
            showsModesTab: true,
            showsPartyModes: true,
            showsCoopModes: true,
            showsTrainingBots: true,
            showsCustomBots: true,
            showsPlayerExport: true,
            showsAccessibilityMarketing: true,
            bundledLocaleCodes: ["en", "de", "es", "nl", "fr", "zh-Hans", "it"]
        )

        static let lean1_0 = Configuration(
            showsModesTab: false,
            showsPartyModes: false,
            showsCoopModes: false,
            showsTrainingBots: false,
            showsCustomBots: true,
            showsPlayerExport: false,
            showsAccessibilityMarketing: true,
            bundledLocaleCodes: ["en"]
        )
    }

    static let fullProductSurfaceLaunchArgument = "-enable_full_product_surface"
    static let leanProductSurfaceLaunchArgument = "-enable_lean_product_surface"

    static var showsModesTab: Bool { active.showsModesTab }
    static var showsPartyModes: Bool { active.showsPartyModes }
    static var showsCoopModes: Bool { active.showsCoopModes }
    static var showsTrainingBots: Bool { active.showsTrainingBots }
    static var showsCustomBots: Bool { active.showsCustomBots }
    static var showsPlayerExport: Bool { active.showsPlayerExport }
    static var showsAccessibilityMarketing: Bool { active.showsAccessibilityMarketing }
    static var bundledLocaleCodes: [String] { active.bundledLocaleCodes }

    static var isFullProductSurfaceEnabled: Bool {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains(leanProductSurfaceLaunchArgument) {
            return false
        }
        if arguments.contains(fullProductSurfaceLaunchArgument) {
            return true
        }
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    private static var active: Configuration {
        isFullProductSurfaceEnabled ? .full : .lean1_0
    }

    /// Whether gameplay for this match type is reachable in the current product surface.
    static func isMatchTypeReachable(_ matchType: MatchType) -> Bool {
        switch matchType {
        case .x01, .cricket:
            return true
        default:
            guard let entry = GameModeCatalog.entry(for: matchType), entry.isAvailable else {
                return false
            }
            switch entry.section {
            case .party:
                return showsPartyModes
            case .coop:
                return showsCoopModes
            case .standard, .practice:
                return showsModesTab
            }
        }
    }
}
