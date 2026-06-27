import Foundation

extension DartBotEngine {
    /// Generates a Halve-It visit aiming at `targetSegment`.
    ///
    /// Halve-It scores any multiplier on the round target (sum of dart points).
    /// Reuses inning-style targeting from Baseball bots — tier-based S/D/T mix,
    /// partial hits on the target bed, and clock-adjacent misses.
    public static func generateHalveItTurn(
        targetSegment: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        generateBaseballTurn(
            targetSegment: targetSegment,
            phase: .innings,
            stretchGateOpen: true,
            seventhInningStretch: false,
            profile: profile,
            rng: &rng
        )
    }
}
