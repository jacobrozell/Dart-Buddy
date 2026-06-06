import Foundation

/// Controls which product areas are reachable in this build.
///
/// Lean 1.0 defaults hide Modes, party modes, advanced bots, and export.
/// UI tests and dogfood builds pass `-enable_full_product_surface` to restore the full app.
/// See `docs/release/lean-1.0-implementation-plan.md`.
enum ProductSurface {
    struct Configuration: Sendable, Equatable {
        var showsModesTab: Bool
        var showsPartyModes: Bool
        var showsTrainingBots: Bool
        var showsCustomBots: Bool
        var showsPlayerExport: Bool
        var bundledLocaleCodes: [String]

        static let full = Configuration(
            showsModesTab: true,
            showsPartyModes: true,
            showsTrainingBots: true,
            showsCustomBots: true,
            showsPlayerExport: true,
            bundledLocaleCodes: ["en", "de", "es", "nl"]
        )

        static let lean1_0 = Configuration(
            showsModesTab: false,
            showsPartyModes: false,
            showsTrainingBots: false,
            showsCustomBots: false,
            showsPlayerExport: false,
            bundledLocaleCodes: ["en"]
        )
    }

    static let fullProductSurfaceLaunchArgument = "-enable_full_product_surface"

    static var showsModesTab: Bool { active.showsModesTab }
    static var showsPartyModes: Bool { active.showsPartyModes }
    static var showsTrainingBots: Bool { active.showsTrainingBots }
    static var showsCustomBots: Bool { active.showsCustomBots }
    static var showsPlayerExport: Bool { active.showsPlayerExport }
    static var bundledLocaleCodes: [String] { active.bundledLocaleCodes }

    static var isFullProductSurfaceEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(fullProductSurfaceLaunchArgument)
    }

    private static var active: Configuration {
        isFullProductSurfaceEnabled ? .full : .lean1_0
    }
}
