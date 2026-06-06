import Foundation
import Testing
@testable import DartBuddy

/// Long-run Shanghai bot simulations for preset difficulty tiers.
///
/// Shanghai bots reuse Baseball turn generation (`generateShanghaiTurn`): they aim at
/// the active round segment and resolve hits with Cricket tables from `BotSkillProfile`.
/// Very Easy and Easy tiers only throw singles on the target bed, so totals stay low
/// over short round counts (e.g. 7 rounds). Medium+ tiers attempt doubles/triples, so
/// a single 7-round game where Medium finishes near ~100 while Easy/Very Easy sit in
/// the teens is within the expected band — ordering across many seeded games is the
/// contract we guard here.
///
/// Run `botShanghaiBenchmarkSnapshot` in Xcode to print a fresh tuning report.

private struct BotShanghaiPerformanceProfile: Sendable {
    var games = 0
    var wins = 0
    var totalPoints = 0
    var visits = 0
    var zeroPointVisits = 0
    var tripleDarts = 0
    var doubleDarts = 0
    var totalDarts = 0

    var averagePointsPerGame: Double {
        guard games > 0 else { return 0 }
        return Double(totalPoints) / Double(games)
    }

    var averagePointsPerVisit: Double {
        guard visits > 0 else { return 0 }
        return Double(totalPoints) / Double(visits)
    }

    var zeroVisitRate: Double {
        guard visits > 0 else { return 0 }
        return Double(zeroPointVisits) / Double(visits)
    }

    var winRate: Double {
        guard games > 0 else { return 0 }
        return Double(wins) / Double(games)
    }

    var tripleRate: Double {
        guard totalDarts > 0 else { return 0 }
        return Double(tripleDarts) / Double(totalDarts)
    }

    var doubleRate: Double {
        guard totalDarts > 0 else { return 0 }
        return Double(doubleDarts) / Double(totalDarts)
    }

    mutating func record(visitPoints: Int, darts: [DartInput]) {
        visits += 1
        totalPoints += visitPoints
        if visitPoints == 0 { zeroPointVisits += 1 }
        totalDarts += darts.count
        tripleDarts += darts.filter { $0.multiplier == .triple && !$0.isMiss }.count
        doubleDarts += darts.filter { $0.multiplier == .double && !$0.isMiss }.count
    }
}

private struct BotShanghaiMatchResult: Sendable {
    let winnerTurnOrder: Int
    let roundsPlayed: Int
    let playerProfiles: [Int: BotShanghaiPerformanceProfile]
}

private enum BotShanghaiSimulator {
    static let shortRoundConfig = MatchConfigShanghai(roundCount: 7)
    static let standardConfig = MatchConfigShanghai(roundCount: 20)
    static let passiveMissTurn = Array(
        repeating: DartInput(multiplier: .single, segment: .miss, isMiss: true),
        count: 3
    )

    static func botParticipant(_ difficulty: BotDifficulty, turnOrder: Int) -> MatchParticipant {
        let id = UUID()
        return MatchParticipant(
            playerId: id,
            displayNameAtMatchStart: difficulty.rosterName,
            turnOrder: turnOrder,
            botDifficultyRaw: difficulty.rawValue
        )
    }

    static func playMatch(
        difficulties: [BotDifficulty],
        config: MatchConfigShanghai = standardConfig,
        seed: UInt64
    ) throws -> BotShanghaiMatchResult {
        guard difficulties.count >= 2 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.players.minimum"
            )
        }

        let participants = difficulties.enumerated().map { index, difficulty in
            botParticipant(difficulty, turnOrder: index)
        }
        let playerIds = participants.map { $0.playerId! }
        var difficultyByPlayerId: [UUID: BotDifficulty] = [:]
        for (index, playerId) in playerIds.enumerated() {
            difficultyByPlayerId[playerId] = difficulties[index]
        }

        var session = try MatchLifecycleService.createMatch(
            type: .shanghai,
            config: .shanghai(config),
            participants: participants
        )

        var profiles = Dictionary(uniqueKeysWithValues: difficulties.indices.map { ($0, BotShanghaiPerformanceProfile()) })
        var rng = BotShanghaiSimulationRNG(seed: seed)
        var turnCounter: UInt64 = 0

        while session.runtime.status == .inProgress {
            guard let shanghaiState = session.runtime.shanghaiState else { break }
            let playerIndex = shanghaiState.currentPlayerIndex
            let playerId = shanghaiState.players[playerIndex].playerId
            guard difficultyByPlayerId[playerId] != nil else { break }

            let profile = difficultyByPlayerId[playerId]!.skillProfile
            let darts = DartBotEngine.generateShanghaiTurn(
                targetSegment: shanghaiState.currentRound,
                profile: profile,
                rng: &rng
            )

            session = try MatchLifecycleService.submitShanghaiTurn(session: session, darts: darts)

            if case let .shanghaiTurn(event) = session.events.last?.payload {
                profiles[playerIndex, default: BotShanghaiPerformanceProfile()].record(
                    visitPoints: event.pointsThisVisit,
                    darts: darts
                )
            }

            turnCounter &+= 1
            if turnCounter > 4_000 {
                Issue.record("Shanghai bot simulation exceeded turn safety limit")
                break
            }
        }

        guard let winnerId = session.runtime.winnerPlayerId,
              let winnerTurnOrder = playerIds.firstIndex(of: winnerId) else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .error,
                isRecoverable: false,
                userMessageKey: "error.match.completed"
            )
        }

        for index in profiles.keys {
            profiles[index]?.games += 1
        }
        profiles[winnerTurnOrder]?.wins += 1

        let roundsPlayed = session.runtime.shanghaiState?.currentRound ?? config.roundCount
        return BotShanghaiMatchResult(
            winnerTurnOrder: winnerTurnOrder,
            roundsPlayed: roundsPlayed,
            playerProfiles: profiles
        )
    }

    static func playHeadToHead(
        first: BotDifficulty,
        second: BotDifficulty,
        config: MatchConfigShanghai = standardConfig,
        seed: UInt64
    ) throws -> (winner: BotDifficulty, profiles: [BotDifficulty: BotShanghaiPerformanceProfile]) {
        let result = try playMatch(difficulties: [first, second], config: config, seed: seed)
        let winner = result.winnerTurnOrder == 0 ? first : second
        return (
            winner,
            [
                first: result.playerProfiles[0] ?? BotShanghaiPerformanceProfile(),
                second: result.playerProfiles[1] ?? BotShanghaiPerformanceProfile()
            ]
        )
    }

    /// Measures one bot's scoring over a full Shanghai match against a zero-point opponent.
    static func playSoloBotGame(
        difficulty: BotDifficulty,
        config: MatchConfigShanghai = standardConfig,
        seed: UInt64
    ) throws -> BotShanghaiPerformanceProfile {
        let bot = botParticipant(difficulty, turnOrder: 0)
        let passive = MatchParticipant(
            playerId: UUID(),
            displayNameAtMatchStart: "Bench",
            turnOrder: 1
        )

        var session = try MatchLifecycleService.createMatch(
            type: .shanghai,
            config: .shanghai(config),
            participants: [bot, passive]
        )

        var profile = BotShanghaiPerformanceProfile()
        var rng = BotShanghaiSimulationRNG(seed: seed)
        var turnCounter: UInt64 = 0

        while session.runtime.status == .inProgress {
            guard let shanghaiState = session.runtime.shanghaiState else { break }
            let playerIndex = shanghaiState.currentPlayerIndex

            let darts: [DartInput]
            if playerIndex == 0 {
                darts = DartBotEngine.generateShanghaiTurn(
                    targetSegment: shanghaiState.currentRound,
                    profile: difficulty.skillProfile,
                    rng: &rng
                )
            } else {
                darts = passiveMissTurn
            }

            session = try MatchLifecycleService.submitShanghaiTurn(session: session, darts: darts)

            if playerIndex == 0,
               case let .shanghaiTurn(event) = session.events.last?.payload {
                profile.record(visitPoints: event.pointsThisVisit, darts: darts)
            }

            turnCounter &+= 1
            if turnCounter > 600 {
                Issue.record("Solo Shanghai bot simulation exceeded turn safety limit")
                break
            }
        }

        guard session.runtime.status == .completed,
              session.runtime.winnerPlayerId == bot.playerId else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .error,
                isRecoverable: false,
                userMessageKey: "error.match.completed"
            )
        }

        profile.games = 1
        profile.wins = 1
        return profile
    }

    static func merge(_ profiles: [BotShanghaiPerformanceProfile]) -> BotShanghaiPerformanceProfile {
        profiles.reduce(into: BotShanghaiPerformanceProfile()) { merged, profile in
            merged.games += profile.games
            merged.wins += profile.wins
            merged.totalPoints += profile.totalPoints
            merged.visits += profile.visits
            merged.zeroPointVisits += profile.zeroPointVisits
            merged.tripleDarts += profile.tripleDarts
            merged.doubleDarts += profile.doubleDarts
            merged.totalDarts += profile.totalDarts
        }
    }
}

// MARK: - Tier ordering

@Test(.tags(.integration, .match, .regression))
func botShanghaiPointsScaleWithDifficulty() throws {
    let games = 50
    let config = BotShanghaiSimulator.shortRoundConfig
    let veryEasy = try aggregateShanghaiProfile(difficulty: .veryEasy, games: games, config: config, seedBase: 81_001)
    let easy = try aggregateShanghaiProfile(difficulty: .easy, games: games, config: config, seedBase: 81_101)
    let medium = try aggregateShanghaiProfile(difficulty: .medium, games: games, config: config, seedBase: 81_201)
    let hard = try aggregateShanghaiProfile(difficulty: .hard, games: games, config: config, seedBase: 81_301)
    let pro = try aggregateShanghaiProfile(difficulty: .pro, games: games, config: config, seedBase: 81_401)

    // Lower tiers only throw singles on the round bed, so 7-round totals stay modest.
    #expect(veryEasy.averagePointsPerGame >= 8)
    #expect(veryEasy.averagePointsPerGame <= 35)
    #expect(easy.averagePointsPerGame >= 12)
    #expect(easy.averagePointsPerGame <= 45)

    #expect(pro.averagePointsPerGame > hard.averagePointsPerGame)
    #expect(hard.averagePointsPerGame > medium.averagePointsPerGame)
    #expect(medium.averagePointsPerGame > easy.averagePointsPerGame)
    #expect(easy.averagePointsPerGame > veryEasy.averagePointsPerGame)
}

@Test(.tags(.integration, .match, .regression))
func botShanghaiEasyBeatsVeryEasyInHeadToHead() throws {
    let games = 60
    let config = BotShanghaiSimulator.shortRoundConfig
    var easyWins = 0
    for index in 0 ..< games {
        let result = try BotShanghaiSimulator.playHeadToHead(
            first: .easy,
            second: .veryEasy,
            config: config,
            seed: 82_000 + UInt64(index)
        )
        if result.winner == .easy { easyWins += 1 }
    }
    #expect(easyWins > games / 2)
    #expect(Double(easyWins) / Double(games) >= 0.55)
}

@Test(.tags(.integration, .match, .regression))
func botShanghaiMediumBeatsEasyInHeadToHead() throws {
    let games = 60
    let config = BotShanghaiSimulator.shortRoundConfig
    var mediumWins = 0
    for index in 0 ..< games {
        let result = try BotShanghaiSimulator.playHeadToHead(
            first: .medium,
            second: .easy,
            config: config,
            seed: 82_100 + UInt64(index)
        )
        if result.winner == .medium { mediumWins += 1 }
    }
    #expect(mediumWins > games / 2)
    #expect(Double(mediumWins) / Double(games) >= 0.70)
}

@Test(.tags(.integration, .match, .regression))
func botShanghaiVeryEasyAndEasyStayInLowScoringBand() throws {
    let games = 80
    let config = BotShanghaiSimulator.shortRoundConfig
    let veryEasy = try aggregateShanghaiProfile(difficulty: .veryEasy, games: games, config: config, seedBase: 83_001)
    let easy = try aggregateShanghaiProfile(difficulty: .easy, games: games, config: config, seedBase: 83_101)

    // Mirrors observed 7-round play: Very Easy often lands around 10–20; Easy around 15–30.
    #expect(veryEasy.averagePointsPerGame >= 8)
    #expect(veryEasy.averagePointsPerGame <= 28)
    #expect(easy.averagePointsPerGame >= 12)
    #expect(easy.averagePointsPerGame <= 38)
    #expect(easy.averagePointsPerGame >= veryEasy.averagePointsPerGame + 2)
}

@Test(.tags(.integration, .match, .regression))
func botShanghaiMediumUsesMultipliersWhileEasyTiersDoNot() throws {
    let games = 40
    let config = BotShanghaiSimulator.shortRoundConfig
    let veryEasy = try aggregateShanghaiProfile(difficulty: .veryEasy, games: games, config: config, seedBase: 84_001)
    let easy = try aggregateShanghaiProfile(difficulty: .easy, games: games, config: config, seedBase: 84_101)
    let medium = try aggregateShanghaiProfile(difficulty: .medium, games: games, config: config, seedBase: 84_201)

    // Very Easy / Easy only aim singles on the round bed.
    #expect(veryEasy.tripleRate == 0)
    #expect(veryEasy.doubleRate == 0)
    #expect(easy.tripleRate == 0)
    #expect(easy.doubleRate == 0)

    // Medium attempts doubles/triples; observed single-game triple rates around 25% are normal variance.
    #expect(medium.tripleRate >= 0.06)
    #expect(medium.tripleRate <= 0.35)
    #expect(medium.tripleRate > easy.tripleRate)
}

@Test(.tags(.integration, .match, .regression))
func botShanghaiVeryEasyHasMoreScorelessVisitsThanEasy() throws {
    let games = 40
    let config = BotShanghaiSimulator.shortRoundConfig
    let veryEasy = try aggregateShanghaiProfile(difficulty: .veryEasy, games: games, config: config, seedBase: 85_001)
    let easy = try aggregateShanghaiProfile(difficulty: .easy, games: games, config: config, seedBase: 85_101)
    let pro = try aggregateShanghaiProfile(difficulty: .pro, games: games, config: config, seedBase: 85_401)

    #expect(veryEasy.zeroVisitRate > easy.zeroVisitRate)
    #expect(veryEasy.zeroVisitRate >= 0.35)
    // Medium aims at doubles/triples and can blank more often than Easy; Pro finishes more visits overall.
    #expect(pro.zeroVisitRate < easy.zeroVisitRate)
}

@Test(.tags(.integration, .match, .regression))
func botShanghaiMediumSevenRoundScoreWithinExpectedBand() throws {
    let games = 80
    let config = BotShanghaiSimulator.shortRoundConfig
    let medium = try aggregateShanghaiProfile(difficulty: .medium, games: games, config: config, seedBase: 86_001)

    // A single ~102 finish is plausible; over many games Medium should average well above Easy
    // but not run away into triple-digit outliers every time.
    #expect(medium.averagePointsPerGame >= 45)
    #expect(medium.averagePointsPerGame <= 130)
}

// MARK: - Snapshot

@Test(.tags(.integration, .match, .regression))
func botShanghaiBenchmarkSnapshot() throws {
    let games = 40
    let shortConfig = BotShanghaiSimulator.shortRoundConfig
    let veryEasy = try aggregateShanghaiProfile(difficulty: .veryEasy, games: games, config: shortConfig, seedBase: 87_001)
    let easy = try aggregateShanghaiProfile(difficulty: .easy, games: games, config: shortConfig, seedBase: 87_101)
    let medium = try aggregateShanghaiProfile(difficulty: .medium, games: games, config: shortConfig, seedBase: 87_201)
    let hard = try aggregateShanghaiProfile(difficulty: .hard, games: games, config: shortConfig, seedBase: 87_301)
    let pro = try aggregateShanghaiProfile(difficulty: .pro, games: games, config: shortConfig, seedBase: 87_401)

    print("Shanghai bot benchmark (7 rounds, bot vs passive opponent, \(games) games per tier, seeded)")
    for (label, profile) in [
        ("Very Easy", veryEasy),
        ("Easy", easy),
        ("Medium", medium),
        ("Hard", hard),
        ("Pro", pro)
    ] {
        print(
            "\(label.padding(toLength: 9, withPad: " ", startingAt: 0)) " +
            "pts/game: \(String(format: "%5.1f", profile.averagePointsPerGame))  " +
            "pts/visit: \(String(format: "%.2f", profile.averagePointsPerVisit))  " +
            "zero visits: \(String(format: "%4.1f", profile.zeroVisitRate * 100))%  " +
            "triple: \(String(format: "%4.1f", profile.tripleRate * 100))%  " +
            "double: \(String(format: "%4.1f", profile.doubleRate * 100))%"
        )
    }

    var mediumWins = 0
    let headToHeadGames = 40
    for index in 0 ..< headToHeadGames {
        if try BotShanghaiSimulator.playHeadToHead(
            first: .medium,
            second: .easy,
            config: shortConfig,
            seed: 88_000 + UInt64(index)
        ).winner == .medium {
            mediumWins += 1
        }
    }
    print(String(format: "  Medium vs Easy win rate: %.0f%% (%d/%d)", Double(mediumWins) / Double(headToHeadGames) * 100, mediumWins, headToHeadGames))

    #expect(medium.averagePointsPerGame > easy.averagePointsPerGame)
    #expect(easy.averagePointsPerGame > veryEasy.averagePointsPerGame)
}

// MARK: - Helpers

private func aggregateShanghaiProfile(
    difficulty: BotDifficulty,
    games: Int,
    config: MatchConfigShanghai,
    seedBase: UInt64
) throws -> BotShanghaiPerformanceProfile {
    var profile = BotShanghaiPerformanceProfile()

    for index in 0 ..< games {
        let gameProfile = try BotShanghaiSimulator.playSoloBotGame(
            difficulty: difficulty,
            config: config,
            seed: seedBase + UInt64(index)
        )
        profile = BotShanghaiSimulator.merge([profile, gameProfile])
    }
    return profile
}

private struct BotShanghaiSimulationRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0xDEADBEEF : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
