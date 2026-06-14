import SwiftUI

@MainActor
enum SetupHomeModeContext {
    static func selectedCatalogEntry(for setupViewModel: MatchSetupViewModel) -> GameModeCatalogEntry? {
        if let matchType = setupViewModel.selectedCatalogMatchType {
            return GameModeCatalog.entry(for: matchType)
        }
        if setupViewModel.setupCategory == .party {
            switch setupViewModel.partyGame {
            case .baseball: return GameModeCatalog.entry(for: .baseball)
            case .killer: return GameModeCatalog.entry(for: .killer)
            case .shanghai: return GameModeCatalog.entry(for: .shanghai)
            }
        }
        return setupViewModel.mode == .cricket
            ? GameModeCatalog.entry(for: .cricket)
            : GameModeCatalog.entry(for: .x01)
    }

    static func learnToPlayMatchType(for setupViewModel: MatchSetupViewModel) -> MatchType? {
        let candidate: MatchType = {
            if let selected = setupViewModel.selectedCatalogMatchType {
                return selected
            }
            if setupViewModel.setupCategory == .party {
                switch setupViewModel.partyGame {
                case .baseball: return .baseball
                case .killer: return .killer
                case .shanghai: return .shanghai
                }
            }
            return setupViewModel.mode.matchType
        }()
        return GameRulesCatalog.hasGuide(for: candidate) ? candidate : nil
    }

    static func activeMatchTypeForSetupOptions(for setupViewModel: MatchSetupViewModel) -> MatchType? {
        if let selected = setupViewModel.selectedCatalogMatchType {
            return selected
        }
        if setupViewModel.setupCategory == .party {
            switch setupViewModel.partyGame {
            case .baseball: return .baseball
            case .killer: return .killer
            case .shanghai: return .shanghai
            }
        }
        return setupViewModel.mode.matchType
    }

    static func hasModeOptionChips(for setupViewModel: MatchSetupViewModel) -> Bool {
        guard let matchType = activeMatchTypeForSetupOptions(for: setupViewModel) else { return false }
        switch matchType {
        case .mickeyMouse, .mulligan,
             .blindKiller, .followTheLeader, .loop, .prisoner, .scam, .snooker, .ticTacToe, .bobs27, .halveIt:
            return false
        default:
            return true
        }
    }
}
