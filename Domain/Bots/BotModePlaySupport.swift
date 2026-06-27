import Foundation

/// Setup and roster policy for computer opponents by `MatchType`.
enum BotModePlaySupport: Equatable, Sendable {
    /// No bots (co-op PvE hero roster).
    case none
    /// Preset, training partner, and custom bots.
    case full

    var allowsBots: Bool { self != .none }

    var allowsTrainingAndCustomBots: Bool { self == .full }

    static func support(for matchType: MatchType) -> BotModePlaySupport {
        matchType == .raid ? .none : .full
    }

    func validationErrors(
        matchType: MatchType,
        hasBot: Bool,
        hasTrainingOrCustomBot: Bool
    ) -> [String] {
        _ = hasTrainingOrCustomBot
        guard hasBot else { return [] }
        if !allowsBots {
            if matchType == .raid {
                return ["setup.validation.coopHumansOnly"]
            }
            return ["setup.validation.botUnsupportedForMode"]
        }
        return []
    }
}
