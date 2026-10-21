import Foundation

/// Setup and roster policy for computer opponents by `MatchType`.
///
/// Authoritative table: `specs/BotOpponentSpec.md` §5.1.
enum BotModePlaySupport: Equatable, Sendable {
    /// No bots (co-op PvE hero roster).
    case none
    /// Preset difficulty bots only (no training partner / custom).
    case presetOnly
    /// Preset, training partner, and custom bots.
    case full

    var allowsBots: Bool { self != .none }

    var allowsTrainingAndCustomBots: Bool { self == .full }

    static func support(for matchType: MatchType) -> BotModePlaySupport {
        switch matchType {
        case .raid:
            return .none
        case .baseball, .shanghai, .killer:
            return .presetOnly
        default:
            return .full
        }
    }

    func validationErrors(
        matchType: MatchType,
        hasBot: Bool,
        hasTrainingOrCustomBot: Bool
    ) -> [String] {
        guard hasBot else { return [] }
        if !allowsBots {
            if matchType == .raid {
                return ["setup.validation.coopHumansOnly"]
            }
            return ["setup.validation.botUnsupportedForMode"]
        }
        if hasTrainingOrCustomBot, self == .presetOnly {
            return [presetOnlyValidationKey(for: matchType)].compactMap { $0 }
        }
        return []
    }

    private func presetOnlyValidationKey(for matchType: MatchType) -> String? {
        switch matchType {
        case .baseball: return "setup.validation.baseballBotsPresetOnly"
        case .shanghai: return "setup.validation.shanghaiBotsPresetOnly"
        case .killer: return "setup.validation.killerBotsPresetOnly"
        default: return "setup.validation.botUnsupportedForMode"
        }
    }
}
