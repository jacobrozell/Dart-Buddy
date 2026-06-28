import Foundation

/// Controls which product areas are reachable in this build.
///
/// **Debug and Release** default to the shipping slice (`smart1_2` on 1.2 — seven modes,
/// Training Partner, player export, **English + German** bundled).
/// Pass `-enable_full_product_surface` to dogfood the full catalog (Modes tab, all shipped modes, locales).
/// See `docs/release/branch-strategy.md`.
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

        /// 1.1 — lean shell plus party modes, Raid co-op, and Around the Clock practice.
        static let party1_1 = Configuration(
            showsModesTab: false,
            showsPartyModes: true,
            showsCoopModes: false,
            showsTrainingBots: false,
            showsCustomBots: true,
            showsPlayerExport: false,
            showsAccessibilityMarketing: true,
            bundledLocaleCodes: ["en"]
        )

        /// 1.2 — 1.1 gameplay plus Training Partner, player export, and German UI in the store bundle.
        static let smart1_2 = Configuration(
            showsModesTab: false,
            showsPartyModes: true,
            showsCoopModes: false,
            showsTrainingBots: true,
            showsCustomBots: true,
            showsPlayerExport: true,
            showsAccessibilityMarketing: true,
            bundledLocaleCodes: ["en", "de"]
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

    /// Coarse build slice label for analytics (`full` vs `lean`).
    static var analyticsLabel: String {
        isFullProductSurfaceEnabled ? "full" : "lean"
    }

    static var isFullProductSurfaceEnabled: Bool {
        isFullProductSurfaceEnabled(arguments: ProcessInfo.processInfo.arguments)
    }

    static func isFullProductSurfaceEnabled(arguments: [String]) -> Bool {
        if arguments.contains(leanProductSurfaceLaunchArgument) {
            return false
        }
        if arguments.contains(fullProductSurfaceLaunchArgument) {
            return true
        }
        return false
    }

    private static var active: Configuration {
        configuration(for: ProcessInfo.processInfo.arguments)
    }

    static func configuration(for arguments: [String]) -> Configuration {
        isFullProductSurfaceEnabled(arguments: arguments) ? .full : .smart1_2
    }

    /// Catalog IDs shipped in the default Release 1.1+ gameplay surface (unchanged in 1.2).
    static let partyPack1_1CatalogIDs: Set<String> = [
        "standard.x01",
        "standard.cricket",
        "party.baseball",
        "party.killer",
        "party.shanghai",
        "coop.raid",
        "practice.aroundTheClock"
    ]

    /// Whether gameplay for this match type is reachable in the current product surface.
    static func isMatchTypeReachable(_ matchType: MatchType) -> Bool {
        isMatchTypeReachable(matchType, arguments: ProcessInfo.processInfo.arguments)
    }

    static func isMatchTypeReachable(_ matchType: MatchType, arguments: [String]) -> Bool {
        guard let entry = GameModeCatalog.entry(for: matchType), entry.isAvailable else {
            return false
        }
        return isCatalogEntryReachable(entry, arguments: arguments)
    }

    /// Whether a shipped catalog entry is reachable in the current product surface.
    static func isCatalogEntryReachable(_ entry: GameModeCatalogEntry) -> Bool {
        isCatalogEntryReachable(entry, arguments: ProcessInfo.processInfo.arguments)
    }

    static func isCatalogEntryReachable(_ entry: GameModeCatalogEntry, arguments: [String]) -> Bool {
        guard entry.isAvailable, entry.matchType != nil else { return false }

        let config = configuration(for: arguments)
        if isFullProductSurfaceEnabled(arguments: arguments) {
            switch entry.matchType {
            case .x01, .cricket:
                return true
            default:
                break
            }
            switch entry.section {
            case .party:
                return config.showsPartyModes
            case .coop:
                return config.showsCoopModes
            case .standard, .practice:
                return config.showsModesTab
            }
        }

        return partyPack1_1CatalogIDs.contains(entry.id)
    }
}
