import Foundation

extension DartBotEngine {
    /// Generates up to three darts for a Football bot turn.
    ///
    /// During kickoff the bot aims for the bull (inner bull preferred for `twoOuterBulls` mode,
    /// outer bull for `singleBull`).  During scoring the bot aims for double 20.
    public static func generateFootballTurn(
        playerState: FootballPlayerState,
        config: MatchConfigFootball,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        var darts: [DartInput] = []
        var simulatedState = playerState

        while darts.count < 3 {
            let dart: DartInput
            if !simulatedState.kickoffComplete {
                dart = resolveFootballKickoffDart(
                    progress: simulatedState.kickoffProgress,
                    kickoffMode: config.kickoffMode,
                    profile: profile,
                    rng: &rng
                )
                // Simulate kickoff progress so subsequent darts in the same visit
                // reflect the updated state.
                if FootballEngine.isBull(dart) {
                    switch config.kickoffMode {
                    case .singleBull:
                        simulatedState.kickoffComplete = true
                    case .twoOuterBulls:
                        if dart.segment == .innerBull {
                            simulatedState.kickoffComplete = true
                        } else {
                            simulatedState.kickoffProgress += 1
                            if simulatedState.kickoffProgress >= 2 {
                                simulatedState.kickoffComplete = true
                            }
                        }
                    }
                }
            } else {
                dart = resolveFootballScoringDart(profile: profile, rng: &rng)
            }
            darts.append(dart)
        }
        return darts
    }

    // MARK: - Private helpers

    private static func resolveFootballKickoffDart(
        progress: Int,
        kickoffMode: FootballKickoffMode,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        resolveBullDartForFootball(profile: profile, rng: &rng)
    }

    /// Aims for double 20 as the primary scoring dart.
    private static func resolveFootballScoringDart(
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        let hitChance = profile.cricket.hitChances.double
        let roll = Double.random(in: 0 ... 1, using: &rng)
        if roll < hitChance {
            return DartInput(multiplier: .double, segment: .oneToTwenty(20))
        }
        let offBoard = profile.cricket.offBoardMissChance
        if roll < hitChance + offBoard {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
        // Downgrade: land on single 20 or adjacent single.
        let adjacent = Bool.random(using: &rng) ? 5 : 1  // neighbours of 20 on the board
        if Double.random(in: 0 ... 1, using: &rng) < 0.65 {
            return DartInput(multiplier: .single, segment: .oneToTwenty(20))
        }
        return DartInput(multiplier: .single, segment: .oneToTwenty(adjacent))
    }

    /// Aims for the bull; inner bull preferred (higher precision) then outer bull.
    private static func resolveBullDartForFootball(
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        let roll = Double.random(in: 0 ... 1, using: &rng)
        let innerChance = profile.cricket.hitChances.triple
        let outerChance = innerChance + profile.cricket.hitChances.single
        if roll < innerChance {
            return DartInput(multiplier: .single, segment: .innerBull)
        } else if roll < outerChance {
            return DartInput(multiplier: .single, segment: .outerBull)
        } else {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
    }
}
