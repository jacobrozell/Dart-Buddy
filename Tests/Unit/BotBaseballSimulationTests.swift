import Foundation
import Testing
@testable import DartBuddy

/// Long-run Baseball bot simulations for preset difficulty tiers.
///
/// Baseball bots aim at the active inning segment and resolve hits using the
/// Cricket hit tables from `BotSkillProfile`. Very Easy and Easy tiers only
/// throw singles on the target bed, so full 9-inning totals stay low (often
/// single digits). A single game where Very Easy finishes with ~3 runs and
/// Easy with ~9 runs is within the expected band — ordering across many
/// seeded games is the contract we guard here.
///
/// Run `botBaseballBenchmarkSnapshot` in Xcode to print a fresh tuning report.

private struct BotBaseballPerformanceProfile: Sendable {
    var games = 0
    var wins = 0
    var totalRuns = 0
    var visits = 0
    var zeroRunVisits = 0

    var averageRunsPerGame: Double {
        guard games > 0 else { return 0 }
        return Double(totalRuns) / Double(games)
    }

    var averageRunsPerVisit: Double {
        guard visits > 0 else { return 0 }
        return Double(totalRuns) / Double(visits)
    }

    var zeroVisitRate: Double {
        guard visits > 0 else { return 0 }
        return Double(zeroRunVisits) / Double(visits)
    }

    var winRate: Double {
        guard games > 0 else { return 0 }
        return Double(wins) / Double(games)
    }

    mutating func record(visitRuns: Int) {
        visits += 1
        totalRuns += visitRuns
        if visitRuns == 0 { zeroRunVisits += 1 }
    }
}

private struct BotBaseballMatchResult: Sendable {
    let winnerTurnOrder: Int
    let legsPlayed: Int
    let playerProfiles: [Int: BotBaseballPerformanceProfile]
}

private enum BotBaseballSimulator {
    static let standardConfig = MatchConfigBaseball(inningCount: 9, tieBreaker: .extraInnings)
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
        config: MatchConfigBaseball = standardConfig,
        seed: UInt64
    ) throws -> BotBaseballMatchResult {
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
            type: .baseball,
            config: .baseball(config),
            participants: participants
        )

        var profiles = Dictionary(uniqueKeysWithValues: difficulties.indices.map { ($0, BotBaseballPerformanceProfile()) })
        var rng = BotBaseballSimulationRNG(seed: seed)
        var turnCounter: UInt64 = 0

        while session.runtime.status == .inProgress {
            guard let baseballState = session.runtime.baseballState else { break }
            let playerIndex = baseballState.currentPlayerIndex
            let playerId = baseballState.players[playerIndex].playerId
            guard let difficulty = difficultyByPlayerId[playerId] else { break }

            let darts = DartBotEngine.generateBaseballTurn(
                targetSegment: baseballState.phase == .bullPlayoff ? 25 : baseballState.currentInning,
                phase: baseballState.phase,
                stretchGateOpen: baseballState.players[playerIndex].stretchGateOpen,
                seventhInningStretch: baseballState.config.seventhInningStretch,
                profile: difficulty.skillProfile,
                rng: &rng
            )

            session = try MatchLifecycleService.submitBaseballTurn(session: session, darts: darts)

            if case let .baseballTurn(event) = session.events.last?.payload {
                profiles[playerIndex, default: BotBaseballPerformanceProfile()].record(visitRuns: event.runsThisVisit)
            }

            turnCounter &+= 1
            if turnCounter > 2_000 {
                Issue.record("Baseball bot simulation exceeded turn safety limit")
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

        let inningsPlayed = session.runtime.baseballState?.currentInning ?? config.inningCount
        return BotBaseballMatchResult(
            winnerTurnOrder: winnerTurnOrder,
            legsPlayed: inningsPlayed,
            playerProfiles: profiles
        )
    }

    static func playHeadToHead(
        first: BotDifficulty,
        second: BotDifficulty,
        config: MatchConfigBaseball = standardConfig,
        seed: UInt64
    ) throws -> (winner: BotDifficulty, profiles: [BotDifficulty: BotBaseballPerformanceProfile]) {
        let result = try playMatch(difficulties: [first, second], config: config, seed: seed)
        let winner = result.winnerTurnOrder == 0 ? first : second
        return (
            winner,
            [
                first: result.playerProfiles[0] ?? BotBaseballPerformanceProfile(),
                second: result.playerProfiles[1] ?? BotBaseballPerformanceProfile()
            ]
        )
    }

    /// Measures one bot's scoring over a full 9-inning game against a zero-run opponent.
    /// Avoids extra-inning loops that occur when two similar bots tie after regulation.
    static func playSoloBotGame(
        difficulty: BotDifficulty,
        config: MatchConfigBaseball = standardConfig,
        seed: UInt64
    ) throws -> BotBaseballPerformanceProfile {
        let bot = botParticipant(difficulty, turnOrder: 0)
        let passive = MatchParticipant(
            playerId: UUID(),
            displayNameAtMatchStart: "Bench",
            turnOrder: 1
        )

        var session = try MatchLifecycleService.createMatch(
            type: .baseball,
            config: .baseball(config),
            participants: [bot, passive]
        )

        var profile = BotBaseballPerformanceProfile()
        var rng = BotBaseballSimulationRNG(seed: seed)
        var turnCounter: UInt64 = 0

        while session.runtime.status == .inProgress {
            guard let baseballState = session.runtime.baseballState else { break }
            let playerIndex = baseballState.currentPlayerIndex

            let darts: [DartInput]
            if playerIndex == 0 {
                darts = DartBotEngine.generateBaseballTurn(
                    targetSegment: baseballState.phase == .bullPlayoff ? 25 : baseballState.currentInning,
                    phase: baseballState.phase,
                    stretchGateOpen: baseballState.players[playerIndex].stretchGateOpen,
                    seventhInningStretch: baseballState.config.seventhInningStretch,
                    profile: difficulty.skillProfile,
                    rng: &rng
                )
            } else {
                darts = passiveMissTurn
            }

            session = try MatchLifecycleService.submitBaseballTurn(session: session, darts: darts)

            if playerIndex == 0,
               case let .baseballTurn(event) = session.events.last?.payload {
                profile.record(visitRuns: event.runsThisVisit)
            }

            turnCounter &+= 1
            if turnCounter > 200 {
                Issue.record("Solo baseball bot simulation exceeded turn safety limit")
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

    static func merge(_ profiles: [BotBaseballPerformanceProfile]) -> BotBaseballPerformanceProfile {
        profiles.reduce(into: BotBaseballPerformanceProfile()) { merged, profile in
            merged.games += profile.games
            merged.wins += profile.wins
            merged.totalRuns += profile.totalRuns
            merged.visits += profile.visits
            merged.zeroRunVisits += profile.zeroRunVisits
        }
    }
}

// MARK: - Tier ordering

@Test(.tags(.integration, .baseball, .regression))
func botBaseballRunsScaleWithDifficulty() throws {
    let games = 50
    let veryEasy = try aggregateBaseballProfile(difficulty: .veryEasy, games: games, seedBase: 71_001)
    let easy = try aggregateBaseballProfile(difficulty: .easy, games: games, seedBase: 71_101)
    let medium = try aggregateBaseballProfile(difficulty: .medium, games: games, seedBase: 71_201)
    let hard = try aggregateBaseballProfile(difficulty: .hard, games: games, seedBase: 71_301)
    let pro = try aggregateBaseballProfile(difficulty: .pro, games: games, seedBase: 71_401)

    // Lower tiers only throw singles on the inning bed, so totals stay in single digits.
    #expect(veryEasy.averageRunsPerGame >= 1)
    #expect(veryEasy.averageRunsPerGame <= 12)
    #expect(easy.averageRunsPerGame >= 3)
    #expect(easy.averageRunsPerGame <= 18)

    #expect(pro.averageRunsPerGame > hard.averageRunsPerGame)
    #expect(hard.averageRunsPerGame > medium.averageRunsPerGame)
    #expect(medium.averageRunsPerGame > easy.averageRunsPerGame)
    #expect(easy.averageRunsPerGame > veryEasy.averageRunsPerGame)
}

@Test(.tags(.integration, .baseball, .regression))
func botBaseballEasyBeatsVeryEasyInHeadToHead() throws {
    let games = 60
    var easyWins = 0
    for index in 0 ..< games {
        let result = try BotBaseballSimulator.playHeadToHead(
            first: .easy,
            second: .veryEasy,
            seed: 72_000 + UInt64(index)
        )
        if result.winner == .easy { easyWins += 1 }
    }
    #expect(easyWins > games / 2)
    #expect(Double(easyWins) / Double(games) >= 0.55)
}

@Test(.tags(.integration, .baseball, .regression))
func botBaseballVeryEasyAndEasyStayInLowScoringBand() throws {
    let games = 80
    let veryEasy = try aggregateBaseballProfile(difficulty: .veryEasy, games: games, seedBase: 73_001)
    let easy = try aggregateBaseballProfile(difficulty: .easy, games: games, seedBase: 73_101)

    // Mirrors observed play: Very Easy often lands around 2–8 runs; Easy around 6–12.
    #expect(veryEasy.averageRunsPerGame >= 2)
    #expect(veryEasy.averageRunsPerGame <= 10)
    #expect(easy.averageRunsPerGame >= 5)
    #expect(easy.averageRunsPerGame <= 14)
    #expect(easy.averageRunsPerGame >= veryEasy.averageRunsPerGame + 1.5)
}

@Test(.tags(.integration, .baseball, .regression))
func botBaseballVeryEasyHasMoreScorelessVisitsThanEasy() throws {
    let games = 40
    let veryEasy = try aggregateBaseballProfile(difficulty: .veryEasy, games: games, seedBase: 74_001)
    let easy = try aggregateBaseballProfile(difficulty: .easy, games: games, seedBase: 74_101)
    let pro = try aggregateBaseballProfile(difficulty: .pro, games: games, seedBase: 74_301)

    // Very Easy / Easy only throw singles on the inning bed, so blank visits are common.
    #expect(veryEasy.zeroVisitRate > easy.zeroVisitRate)
    #expect(veryEasy.zeroVisitRate >= 0.40)
    // Higher tiers attempt doubles/triples and finish with fewer scoreless visits overall.
    #expect(pro.zeroVisitRate < easy.zeroVisitRate)
}

// MARK: - Snapshot

@Test(.tags(.integration, .baseball, .regression))
func botBaseballBenchmarkSnapshot() throws {
    let games = 40
    let veryEasy = try aggregateBaseballProfile(difficulty: .veryEasy, games: games, seedBase: 75_001)
    let easy = try aggregateBaseballProfile(difficulty: .easy, games: games, seedBase: 75_101)
    let medium = try aggregateBaseballProfile(difficulty: .medium, games: games, seedBase: 75_201)
    let hard = try aggregateBaseballProfile(difficulty: .hard, games: games, seedBase: 75_301)
    let pro = try aggregateBaseballProfile(difficulty: .pro, games: games, seedBase: 75_401)

    print("Baseball bot benchmark (9 innings, bot vs passive opponent, \(games) games per tier, seeded)")
    for (label, profile) in [
        ("Very Easy", veryEasy),
        ("Easy", easy),
        ("Medium", medium),
        ("Hard", hard),
        ("Pro", pro)
    ] {
        print("\(label.padding(toLength: 9, withPad: " ", startingAt: 0)) runs/game: \(String(format: "%4.1f", profile.averageRunsPerGame))  runs/visit: \(String(format: "%.2f", profile.averageRunsPerVisit))  zero visits: \(String(format: "%4.1f", profile.zeroVisitRate * 100))%  visits: \(profile.visits)")
    }

    var easyWins = 0
    let headToHeadGames = 40
    for index in 0 ..< headToHeadGames {
        if try BotBaseballSimulator.playHeadToHead(first: .easy, second: .veryEasy, seed: 76_000 + UInt64(index)).winner == .easy {
            easyWins += 1
        }
    }
    print(String(format: "  Easy vs Very Easy win rate: %.0f%% (%d/%d)", Double(easyWins) / Double(headToHeadGames) * 100, easyWins, headToHeadGames))

    #expect(easy.averageRunsPerGame > veryEasy.averageRunsPerGame)
    #expect(medium.averageRunsPerGame > easy.averageRunsPerGame)
}

// MARK: - Helpers

private func aggregateBaseballProfile(
    difficulty: BotDifficulty,
    games: Int,
    seedBase: UInt64
) throws -> BotBaseballPerformanceProfile {
    var profile = BotBaseballPerformanceProfile()

    for index in 0 ..< games {
        let gameProfile = try BotBaseballSimulator.playSoloBotGame(
            difficulty: difficulty,
            seed: seedBase + UInt64(index)
        )
        profile = BotBaseballSimulator.merge([profile, gameProfile])
    }
    return profile
}

private struct BotBaseballSimulationRNG: RandomNumberGenerator {
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
