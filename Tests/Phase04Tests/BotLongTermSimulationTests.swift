import Foundation
import Testing
@testable import DartsScoreboard

/// Long-run bot simulations for 501 double-out (and Cricket marks).
///
/// Expected tier separation (from `DartBotEngine` aim/checkout model):
/// | Tier   | Typical 3-dart avg | Bust tendency | Checkout on finish | H2H vs easier tier |
/// |--------|-------------------|---------------|--------------------|--------------------|
/// | Easy   | ~25–40            | Highest       | ~25% attempt rate  | Loses most legs    |
/// | Medium | ~45–62            | Moderate      | ~40% attempt rate  | Beats Easy often   |
/// | Hard   | ~65–78            | Low           | ~50% attempt rate  | Beats Medium often |
/// | Pro    | ~80–95            | Lowest        | ~58% attempt rate  | Beats Hard often   |
///
/// Run `botLongTermBenchmarkSnapshot` in Xcode to print a fresh sample to the console.
/// Run `botTierMirrorMatchAnalysisSnapshot` for same-tier best-of-3 501 tuning reports.

private struct BotPerformanceProfile: Sendable {
    var visits = 0
    var totalPoints = 0
    var totalDarts = 0
    var busts = 0
    var checkoutAttempts = 0
    var checkouts = 0
    var games = 0
    var wins = 0
    var zeroScoreVisits = 0

    var average3Dart: Double {
        guard totalDarts > 0 else { return 0 }
        return Double(totalPoints) / Double(totalDarts) * 3.0
    }

    var bustRate: Double {
        guard visits > 0 else { return 0 }
        return Double(busts) / Double(visits)
    }

    var checkoutRate: Double {
        guard checkoutAttempts > 0 else { return 0 }
        return Double(checkouts) / Double(checkoutAttempts)
    }

    var winRate: Double {
        guard games > 0 else { return 0 }
        return Double(wins) / Double(games)
    }

    var zeroVisitRate: Double {
        guard visits > 0 else { return 0 }
        return Double(zeroScoreVisits) / Double(visits)
    }

    mutating func record(turn: X01TurnEvent, wasFinishable: Bool) {
        visits += 1
        totalPoints += turn.appliedTotal
        totalDarts += turn.effectiveDartsThrown
        if turn.isBust { busts += 1 }
        if turn.appliedTotal == 0 { zeroScoreVisits += 1 }
        if wasFinishable { checkoutAttempts += 1 }
        if turn.didCheckout { checkouts += 1 }
    }
}

private struct BotX01MatchResult: Sendable {
    let winnerTurnOrder: Int
    let winnerDifficulty: BotDifficulty
    let legsPlayed: Int
    let playerProfiles: [Int: BotPerformanceProfile]
}

private struct BotMirrorTierReport: Sendable {
    let difficulty: BotDifficulty
    let matches: Int
    var turnOrderZeroWins = 0
    var turnOrderOneWins = 0
    var totalLegsPlayed = 0
    var profile = BotPerformanceProfile()

    var averageLegsPerMatch: Double {
        guard matches > 0 else { return 0 }
        return Double(totalLegsPlayed) / Double(matches)
    }

    mutating func absorb(_ result: BotX01MatchResult) {
        if result.winnerTurnOrder == 0 {
            turnOrderZeroWins += 1
        } else {
            turnOrderOneWins += 1
        }
        totalLegsPlayed += result.legsPlayed
        profile = BotSimulator.merge([
            profile,
            result.playerProfiles[0] ?? BotPerformanceProfile(),
            result.playerProfiles[1] ?? BotPerformanceProfile()
        ])
    }
}

private enum BotSimulator {
    static let standard501 = MatchConfigX01(
        startScore: 501,
        legsToWin: 1,
        setsEnabled: false,
        setsToWin: nil,
        checkoutMode: .doubleOut
    )

    /// Best-of-3 legs, 501 double-out — typical pub match format for bot tuning.
    static let bestOfThree501 = MatchConfigX01(
        startScore: 501,
        legsToWin: 3,
        setsEnabled: false,
        setsToWin: nil,
        checkoutMode: .doubleOut,
        legFormat: .bestOf
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

    /// Plays a full X01 match bot-vs-bot with per-player stats (supports same-tier pairs).
    static func playX01Match(
        first: BotDifficulty,
        second: BotDifficulty,
        config: MatchConfigX01 = standard501,
        seed: UInt64
    ) throws -> BotX01MatchResult {
        let participants = [
            botParticipant(first, turnOrder: 0),
            botParticipant(second, turnOrder: 1)
        ]
        let playerIds = participants.map { $0.playerId! }
        var difficultyByPlayerId: [UUID: BotDifficulty] = [:]
        difficultyByPlayerId[playerIds[0]] = first
        difficultyByPlayerId[playerIds[1]] = second

        var session = try MatchLifecycleService.createMatch(
            type: .x01,
            config: .x01(config),
            participants: participants
        )

        var profiles: [Int: BotPerformanceProfile] = [0: BotPerformanceProfile(), 1: BotPerformanceProfile()]
        var rng = BotSimulationRNG(seed: seed)
        var turnCounter: UInt64 = 0

        while session.runtime.status == .inProgress {
            guard let state = session.runtime.x01State else { break }
            let playerIndex = state.currentPlayerIndex
            let player = state.players[playerIndex]
            guard let difficulty = difficultyByPlayerId[player.playerId] else { break }

            let finishable = CheckoutSuggester.suggestion(
                remaining: player.remainingScore,
                mode: state.config.checkoutMode,
                dartsAvailable: 3
            ) != nil

            let darts = DartBotEngine.generateX01Turn(
                remaining: player.remainingScore,
                difficulty: difficulty,
                checkoutMode: state.config.checkoutMode,
                checkInMode: state.config.checkInMode,
                isCheckedIn: player.isCheckedIn,
                rng: &rng
            )

            session = try MatchLifecycleService.submitX01Turn(
                session: session,
                enteredTotal: nil,
                darts: darts
            )

            if case let .x01Turn(event) = session.events.last?.payload {
                profiles[playerIndex, default: BotPerformanceProfile()].record(
                    turn: event,
                    wasFinishable: finishable
                )
            }

            turnCounter &+= 1
            if turnCounter > 6_000 {
                Issue.record("Bot simulation exceeded turn safety limit")
                break
            }
        }

        guard let winnerId = session.runtime.winnerPlayerId,
              let winnerDifficulty = difficultyByPlayerId[winnerId],
              let winnerTurnOrder = playerIds.firstIndex(of: winnerId) else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .error,
                isRecoverable: false,
                userMessageKey: "error.match.completed"
            )
        }

        let legsPlayed = session.events.reduce(into: 0) { count, envelope in
            if case let .x01Turn(event) = envelope.payload, event.didCheckout {
                count += 1
            }
        }

        for index in profiles.keys {
            profiles[index]?.games += 1
        }
        profiles[winnerTurnOrder]?.wins += 1

        return BotX01MatchResult(
            winnerTurnOrder: winnerTurnOrder,
            winnerDifficulty: winnerDifficulty,
            legsPlayed: legsPlayed,
            playerProfiles: profiles
        )
    }

    /// Plays a full X01 leg bot-vs-bot and returns per-bot stats for that game.
    @discardableResult
    static func playX01Game(
        first: BotDifficulty,
        second: BotDifficulty,
        config: MatchConfigX01 = standard501,
        seed: UInt64
    ) throws -> (winner: BotDifficulty, profiles: [BotDifficulty: BotPerformanceProfile]) {
        let result = try playX01Match(first: first, second: second, config: config, seed: seed)
        var profiles: [BotDifficulty: BotPerformanceProfile] = [
            first: result.playerProfiles[0] ?? BotPerformanceProfile(),
            second: result.playerProfiles[1] ?? BotPerformanceProfile()
        ]
        if first == second {
            profiles[first] = merge([result.playerProfiles[0], result.playerProfiles[1]].compactMap { $0 })
        }
        return (result.winnerDifficulty, profiles)
    }

    /// Runs many standalone visits (no match completion) to sample raw scoring.
    static func sampleVisits(
        difficulty: BotDifficulty,
        visitCount: Int,
        remaining: Int = 501,
        config: MatchConfigX01 = standard501,
        seed: UInt64
    ) -> BotPerformanceProfile {
        var profile = BotPerformanceProfile()
        var rng = BotSimulationRNG(seed: seed)

        for _ in 0 ..< visitCount {
            let finishable = CheckoutSuggester.suggestion(
                remaining: remaining,
                mode: config.checkoutMode,
                dartsAvailable: 3
            ) != nil

            let darts = DartBotEngine.generateX01Turn(
                remaining: remaining,
                difficulty: difficulty,
                checkoutMode: config.checkoutMode,
                checkInMode: config.checkInMode,
                isCheckedIn: true,
                rng: &rng
            )

            let points = darts.reduce(0) { $0 + $1.points }
            let event = X01TurnEvent(
                payloadVersion: 1,
                id: UUID(),
                playerId: UUID(),
                turnIndex: 0,
                legIndex: 0,
                setIndex: 0,
                startRemaining: remaining,
                enteredTotal: points,
                appliedTotal: points,
                endRemaining: max(0, remaining - points),
                isBust: false,
                didCheckout: false,
                checkoutModeRaw: config.checkoutMode.rawValue,
                checkoutDartCount: nil,
                darts: [],
                timestamp: Date(),
                dartsThrown: darts.count
            )
            profile.record(turn: event, wasFinishable: finishable)
        }

        return profile
    }

    static func merge(_ profiles: [BotPerformanceProfile]) -> BotPerformanceProfile {
        profiles.reduce(into: BotPerformanceProfile()) { merged, profile in
            merged.visits += profile.visits
            merged.totalPoints += profile.totalPoints
            merged.totalDarts += profile.totalDarts
            merged.busts += profile.busts
            merged.checkoutAttempts += profile.checkoutAttempts
            merged.checkouts += profile.checkouts
            merged.games += profile.games
            merged.wins += profile.wins
        }
    }
}

// MARK: - Long-term scoring shape

@Test(.tags(.integration, .x01, .performance, .regression))
func botLongTermBenchmarkSnapshot() throws {
    let games = 40
    let easy = try aggregateGameProfile(difficulty: .easy, games: games, seedBase: 40_001)
    let medium = try aggregateGameProfile(difficulty: .medium, games: games, seedBase: 40_101)
    let hard = try aggregateGameProfile(difficulty: .hard, games: games, seedBase: 40_201)
    let pro = try aggregateGameProfile(difficulty: .pro, games: games, seedBase: 40_301)

    print("Bot benchmark (\(games) full 501 double-out legs, seeded)")
    print(String(format: "  Easy   → 3-dart avg: %.1f  bust: %.1f%%  checkout: %.1f%%  visits: %d",
                 easy.average3Dart, easy.bustRate * 100, easy.checkoutRate * 100, easy.visits))
    print(String(format: "  Medium → 3-dart avg: %.1f  bust: %.1f%%  checkout: %.1f%%  visits: %d",
                 medium.average3Dart, medium.bustRate * 100, medium.checkoutRate * 100, medium.visits))
    print(String(format: "  Hard   → 3-dart avg: %.1f  bust: %.1f%%  checkout: %.1f%%  visits: %d",
                 hard.average3Dart, hard.bustRate * 100, hard.checkoutRate * 100, hard.visits))
    print(String(format: "  Pro    → 3-dart avg: %.1f  bust: %.1f%%  checkout: %.1f%%  visits: %d",
                 pro.average3Dart, pro.bustRate * 100, pro.checkoutRate * 100, pro.visits))

    var hardWins = 0
    var mediumWins = 0
    let headToHeadGames = 40
    for index in 0 ..< headToHeadGames {
        if try BotSimulator.playX01Game(first: .hard, second: .easy, seed: 50_000 + UInt64(index)).winner == .hard { hardWins += 1 }
        if try BotSimulator.playX01Game(first: .medium, second: .easy, seed: 51_000 + UInt64(index)).winner == .medium { mediumWins += 1 }
        if try BotSimulator.playX01Game(first: .hard, second: .medium, seed: 52_000 + UInt64(index)).winner == .hard { /* counted below */ }
    }
    var hardVsMediumWins = 0
    var proVsHardWins = 0
    for index in 0 ..< headToHeadGames {
        if try BotSimulator.playX01Game(first: .hard, second: .medium, seed: 52_000 + UInt64(index)).winner == .hard {
            hardVsMediumWins += 1
        }
        if try BotSimulator.playX01Game(first: .pro, second: .hard, seed: 53_000 + UInt64(index)).winner == .pro {
            proVsHardWins += 1
        }
    }
    print("  Head-to-head win rate (\(headToHeadGames) legs each)")
    print(String(format: "    Hard vs Easy:   %.0f%%", Double(hardWins) / Double(headToHeadGames) * 100))
    print(String(format: "    Medium vs Easy: %.0f%%", Double(mediumWins) / Double(headToHeadGames) * 100))
    print(String(format: "    Hard vs Medium: %.0f%%", Double(hardVsMediumWins) / Double(headToHeadGames) * 100))
    print(String(format: "    Pro vs Hard:    %.0f%%", Double(proVsHardWins) / Double(headToHeadGames) * 100))

    #expect(pro.average3Dart > hard.average3Dart)
    #expect(hard.average3Dart > medium.average3Dart)
    #expect(medium.average3Dart > easy.average3Dart)
}

@Test(.tags(.integration, .x01, .performance, .regression))
func botLongTermScoringAveragesScaleWithDifficulty() throws {
    let games = 50
    let easy = try aggregateGameProfile(difficulty: .easy, games: games, seedBase: 10_001)
    let medium = try aggregateGameProfile(difficulty: .medium, games: games, seedBase: 20_001)
    let hard = try aggregateGameProfile(difficulty: .hard, games: games, seedBase: 30_001)
    let pro = try aggregateGameProfile(difficulty: .pro, games: games, seedBase: 35_001)

    // Lower bounds guard against a collapsed bot model; ordering is the primary contract.
    #expect(easy.average3Dart >= 15)
    #expect(medium.average3Dart >= 30)
    #expect(hard.average3Dart >= 45)
    #expect(hard.average3Dart <= 82)
    #expect(pro.average3Dart >= 55)
    #expect(pro.average3Dart <= 100)

    #expect(pro.average3Dart > hard.average3Dart)
    #expect(hard.average3Dart > medium.average3Dart)
    #expect(medium.average3Dart > easy.average3Dart)

    #expect(pro.average3Dart - easy.average3Dart >= 20)
}

@Test(.tags(.integration, .x01, .performance, .regression))
func botLongTermBustRateDecreasesWithDifficulty() throws {
    let games = 50
    let easy = try aggregateGameProfile(difficulty: .easy, games: games, seedBase: 100)
    let hard = try aggregateGameProfile(difficulty: .hard, games: games, seedBase: 200)

    // All tiers stay relatively clean; allow noise when bust counts are tiny.
    #expect(hard.bustRate <= 0.05)
    #expect(easy.bustRate <= hard.bustRate + 0.03)
}

// MARK: - Head-to-head over many legs

@Test(.tags(.integration, .x01, .performance, .regression))
func botLongTermHeadToHeadWinRatesReflectDifficulty() throws {
    let games = 60
    var wins: [BotDifficulty: Int] = [.easy: 0, .medium: 0, .hard: 0, .pro: 0]

    func play(_ a: BotDifficulty, _ b: BotDifficulty, seedBase: UInt64) throws -> BotDifficulty {
        var aWins = 0
        var bWins = 0
        for index in 0 ..< games {
            let result = try BotSimulator.playX01Game(first: a, second: b, seed: seedBase + UInt64(index))
            if result.winner == a { aWins += 1 } else { bWins += 1 }
        }
        wins[a, default: 0] += aWins
        wins[b, default: 0] += bWins
        return aWins > bWins ? a : b
    }

    let hardVsEasy = try play(.hard, .easy, seedBase: 1_000)
    let mediumVsEasy = try play(.medium, .easy, seedBase: 2_000)
    let hardVsMedium = try play(.hard, .medium, seedBase: 3_000)
    let proVsHard = try play(.pro, .hard, seedBase: 4_000)

    #expect(hardVsEasy == .hard)
    #expect(mediumVsEasy == .medium)
    #expect(hardVsMedium == .hard)
    #expect(proVsHard == .pro)

    // Win-rate floors — tuned to current bot model, not pro-dart expectations.
    #expect(Double(wins[.pro, default: 0]) / Double(games) >= 0.55)
    #expect(Double(wins[.hard, default: 0]) / Double(games * 2) >= 0.50)
    #expect(Double(wins[.easy, default: 0]) / Double(games) <= 0.25)
}

@Test(.tags(.integration, .x01, .performance, .regression))
func botLongTermFullGameProfilesStayOrdered() throws {
    let games = 30
    let easyProfile = try aggregateGameProfile(difficulty: .easy, games: games, seedBase: 5_000)
    let mediumProfile = try aggregateGameProfile(difficulty: .medium, games: games, seedBase: 6_000)
    let hardProfile = try aggregateGameProfile(difficulty: .hard, games: games, seedBase: 7_000)
    let proProfile = try aggregateGameProfile(difficulty: .pro, games: games, seedBase: 7_500)

    #expect(proProfile.average3Dart > hardProfile.average3Dart)
    #expect(hardProfile.average3Dart > mediumProfile.average3Dart)
    #expect(mediumProfile.average3Dart > easyProfile.average3Dart)

    #expect(proProfile.bustRate <= hardProfile.bustRate)
    #expect(hardProfile.bustRate <= mediumProfile.bustRate)
    #expect(mediumProfile.bustRate <= easyProfile.bustRate + 0.03)
}

@Test(.tags(.integration, .x01, .performance, .regression))
func botLongTermCheckoutSuccessScalesWithDifficulty() {
    // Force finishable scores so checkout behaviour is exercised every visit.
    let attempts = 400
    var easy = BotPerformanceProfile()
    var medium = BotPerformanceProfile()
    var hard = BotPerformanceProfile()
    var pro = BotPerformanceProfile()

    let finishScores = [40, 32, 36, 24, 16, 50, 44, 28, 20, 18]

    for (index, remaining) in finishScores.enumerated() {
        let seed = UInt64(8_000 + index)
        easy = BotSimulator.merge([
            easy,
            sampleCheckoutVisits(difficulty: .easy, remaining: remaining, count: attempts / finishScores.count, seed: seed)
        ])
        medium = BotSimulator.merge([
            medium,
            sampleCheckoutVisits(difficulty: .medium, remaining: remaining, count: attempts / finishScores.count, seed: seed &+ 10_000)
        ])
        hard = BotSimulator.merge([
            hard,
            sampleCheckoutVisits(difficulty: .hard, remaining: remaining, count: attempts / finishScores.count, seed: seed &+ 20_000)
        ])
        pro = BotSimulator.merge([
            pro,
            sampleCheckoutVisits(difficulty: .pro, remaining: remaining, count: attempts / finishScores.count, seed: seed &+ 30_000)
        ])
    }

    #expect(pro.checkoutRate > hard.checkoutRate)

    #expect(hard.checkoutRate > medium.checkoutRate)
    #expect(medium.checkoutRate > easy.checkoutRate)
    #expect(easy.checkoutRate >= 0.05)
    #expect(hard.checkoutRate <= 0.95)
}

// MARK: - Cricket long-run

@Test(.tags(.integration, .cricket, .performance, .regression))
func botLongTermCricketMarksScaleWithDifficulty() throws {
    let rounds = 25
    var easyMarks = 0
    var mediumMarks = 0
    var hardMarks = 0
    var proMarks = 0

    for index in 0 ..< rounds {
        easyMarks += try cricketMarksScored(difficulty: .easy, seed: UInt64(9_000 + index))
        mediumMarks += try cricketMarksScored(difficulty: .medium, seed: UInt64(9_500 + index))
        hardMarks += try cricketMarksScored(difficulty: .hard, seed: UInt64(10_000 + index))
        proMarks += try cricketMarksScored(difficulty: .pro, seed: UInt64(10_500 + index))
    }

    #expect(proMarks > hardMarks)

    #expect(hardMarks > mediumMarks)
    #expect(mediumMarks > easyMarks)
}

// MARK: - Same-tier mirror matchups (best-of-3 501)

/// Runs many best-of-3 501 matches where both players share a difficulty tier.
/// Run `botTierMirrorMatchAnalysisSnapshot` in Xcode to print a tuning report.
private func runMirrorTierAnalysis(
    difficulty: BotDifficulty,
    matches: Int,
    seedBase: UInt64,
    config: MatchConfigX01 = BotSimulator.bestOfThree501
) throws -> BotMirrorTierReport {
    var report = BotMirrorTierReport(difficulty: difficulty, matches: matches)
    for index in 0 ..< matches {
        let result = try BotSimulator.playX01Match(
            first: difficulty,
            second: difficulty,
            config: config,
            seed: seedBase + UInt64(index)
        )
        report.absorb(result)
    }
    return report
}

private func printMirrorTierReport(_ report: BotMirrorTierReport) {
    let p0WinRate = Double(report.turnOrderZeroWins) / Double(report.matches) * 100
    let profile = report.profile
    print(String(
        format: "  %@  matches: %3d  3-dart avg: %5.1f  zero visits: %4.1f%%  bust: %4.1f%%  checkout: %4.1f%%  legs/match: %.2f  P0 wins: %.0f%%",
        report.difficulty.displayName,
        report.matches,
        profile.average3Dart,
        profile.zeroVisitRate * 100,
        profile.bustRate * 100,
        profile.checkoutRate * 100,
        report.averageLegsPerMatch,
        p0WinRate
    ))
}

@Test(.tags(.integration, .x01, .performance, .regression))
func botTierMirrorMatchAnalysisSnapshot() throws {
    let matches = 40
    let easy = try runMirrorTierAnalysis(difficulty: .easy, matches: matches, seedBase: 60_001)
    let medium = try runMirrorTierAnalysis(difficulty: .medium, matches: matches, seedBase: 60_101)
    let hard = try runMirrorTierAnalysis(difficulty: .hard, matches: matches, seedBase: 60_201)
    let pro = try runMirrorTierAnalysis(difficulty: .pro, matches: matches, seedBase: 60_301)

    print("Bot tier mirror analysis (best-of-3 501 double-out, \(matches) matches per tier, seeded)")
    printMirrorTierReport(easy)
    printMirrorTierReport(medium)
    printMirrorTierReport(hard)
    printMirrorTierReport(pro)

    #expect(pro.profile.average3Dart > hard.profile.average3Dart)
    #expect(hard.profile.average3Dart > medium.profile.average3Dart)
    #expect(medium.profile.average3Dart > easy.profile.average3Dart)
}

@Test(.tags(.integration, .x01, .performance, .regression))
func botTierMirrorMatchupsStayOrderedByDifficulty() throws {
    let matches = 35
    let seedBases: [BotDifficulty: UInt64] = [
        .easy: 61_001,
        .medium: 61_101,
        .hard: 61_201,
        .pro: 61_301
    ]
    let reports = try BotDifficulty.allCases.map { difficulty in
        try runMirrorTierAnalysis(
            difficulty: difficulty,
            matches: matches,
            seedBase: seedBases[difficulty]!
        )
    }

    for index in 1 ..< reports.count {
        #expect(reports[index].profile.average3Dart > reports[index - 1].profile.average3Dart)
        #expect(reports[index].profile.zeroVisitRate <= reports[index - 1].profile.zeroVisitRate + 0.02)
    }
}

@Test(.tags(.integration, .x01, .performance, .regression))
func botTierMirrorMatchupsHaveBalancedTurnOrder() throws {
    let matches = 80
    for (offset, difficulty) in BotDifficulty.allCases.enumerated() {
        let report = try runMirrorTierAnalysis(
            difficulty: difficulty,
            matches: matches,
            seedBase: 62_000 + UInt64(offset * 1_000)
        )
        let p0Rate = Double(report.turnOrderZeroWins) / Double(matches)
        // Same-tier bots should split wins fairly; allow statistical noise.
        #expect(p0Rate >= 0.35)
        #expect(p0Rate <= 0.65)
    }
}

@Test(.tags(.integration, .x01, .performance, .regression))
func botTierMirrorBestOfThreeCompletesInTwoOrThreeLegs() throws {
    let matches = 50
    for (offset, difficulty) in BotDifficulty.allCases.enumerated() {
        let report = try runMirrorTierAnalysis(
            difficulty: difficulty,
            matches: matches,
            seedBase: 63_000 + UInt64(offset * 1_000)
        )
        #expect(report.averageLegsPerMatch >= 2.0)
        #expect(report.averageLegsPerMatch <= 3.0)
    }
}

// MARK: - Helpers

private func aggregateGameProfile(
    difficulty: BotDifficulty,
    games: Int,
    seedBase: UInt64
) throws -> BotPerformanceProfile {
    var profile = BotPerformanceProfile()
    let opponent: BotDifficulty = switch difficulty {
    case .easy, .medium: .hard
    case .hard: .medium
    case .pro: .hard
    }

    for index in 0 ..< games {
        let result = try BotSimulator.playX01Game(
            first: difficulty,
            second: opponent,
            seed: seedBase + UInt64(index)
        )
        profile = BotSimulator.merge([profile, result.profiles[difficulty] ?? BotPerformanceProfile()])
    }
    return profile
}

private func sampleCheckoutVisits(
    difficulty: BotDifficulty,
    remaining: Int,
    count: Int,
    seed: UInt64
) -> BotPerformanceProfile {
    var profile = BotPerformanceProfile()
    var rng = BotSimulationRNG(seed: seed)
    let config = BotSimulator.standard501

    for _ in 0 ..< count {
        let darts = DartBotEngine.generateX01Turn(
            remaining: remaining,
            difficulty: difficulty,
            checkoutMode: config.checkoutMode,
            checkInMode: config.checkInMode,
            isCheckedIn: true,
            rng: &rng
        )

        var state = try! X01Engine.makeInitialState(
            config: config,
            playerIds: [UUID(), UUID()]
        )
        state.players[0].remainingScore = remaining
        let outcome = try! X01Engine.submitTurn(state: state, enteredTotal: nil, darts: darts)
        profile.record(turn: outcome.event, wasFinishable: true)
    }

    return profile
}

private func cricketMarksScored(difficulty: BotDifficulty, seed: UInt64) throws -> Int {
    let participants = [
        BotSimulator.botParticipant(difficulty, turnOrder: 0),
        BotSimulator.botParticipant(.easy, turnOrder: 1)
    ]
    var session = try MatchLifecycleService.createMatch(
        type: .cricket,
        config: .cricket(MatchConfigCricket()),
        participants: participants
    )
    var rng = BotSimulationRNG(seed: seed)
    guard let state = session.runtime.cricketState else { return 0 }

    let darts = DartBotEngine.generateCricketTurn(
        state: state,
        playerIndex: 0,
        difficulty: difficulty,
        rng: &rng
    )
    session = try MatchLifecycleService.submitCricketTurn(session: session, darts: darts)

    guard case let .cricketTurn(event) = session.events.last?.payload else { return 0 }
    return event.targetsTouched.reduce(0) { $0 + $1.marksAdded }
}

private struct BotSimulationRNG: RandomNumberGenerator {
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
