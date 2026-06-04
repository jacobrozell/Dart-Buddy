import Foundation

public struct TrainingBotEligibility: Equatable, Sendable {
    public let isEligible: Bool
    public let gamesPlayed: Int
    public let requiredGames: Int
    public let mode: MatchType

    public init(isEligible: Bool, gamesPlayed: Int, requiredGames: Int = 5, mode: MatchType) {
        self.isEligible = isEligible
        self.gamesPlayed = gamesPlayed
        self.requiredGames = requiredGames
        self.mode = mode
    }
}

public enum TrainingBotEligibilityService {
    public static let requiredGames = 5

    public static func eligibility(breakdown: PlayerStatBreakdown, mode: MatchType) -> TrainingBotEligibility {
        TrainingBotEligibility(
            isEligible: breakdown.games >= requiredGames,
            gamesPlayed: breakdown.games,
            requiredGames: requiredGames,
            mode: mode
        )
    }
}
