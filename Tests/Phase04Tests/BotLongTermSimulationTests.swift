import Foundation
import Testing
@testable import DartsScoreboard

/// Long-run bot simulations for 501 double-out (and Cricket marks).
///
/// Expected tier separation (from `DartBotEngine` aim/checkout model):
/// | Tier      | Typical 3-dart avg | Bust tendency | Checkout on finish | H2H vs easier tier |
/// |-----------|-------------------|---------------|--------------------|--------------------|
/// | Very Easy | ~15–25            | Highest       | ~12% attempt rate  | Loses most legs    |
/// | Easy      | ~25–40            | High          | ~25% attempt rate  | Beats Very Easy    |
/// | Medium    | ~45–62            | Moderate      | ~40% attempt rate  | Beats Easy often   |
/// | Hard      | ~65–78            | Low           | ~50% attempt rate  | Beats Medium often |
/// | Pro       | ~80–95            | Lowest        | ~58% attempt rate  | Beats Hard often   |
///
/// Mirror snapshot (Jun 2026 tuning): Very Easy ~20 avg / ~35% bust, Easy ~29 / ~27%,
/// Medium ~61 / ~19%, Hard ~75 / ~8%, Pro ~88 / ~6%.
///
/// Run `botLongTermBenchmarkSnapshot` in Xcode to print a fresh sample to the console.
/// Run `botTierMirrorMatchAnalysisSnapshot` for same-tier best-of-3 501 tuning reports.
/// Run `botTierFourWayMatchAnalysisSnapshot` for four same-tier bots per match.

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

private struct BotX01MultiMatchResult: Sendable {
    let winnerTurnOrder: Int
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

private struct BotFourWayTierReport: Sendable {
    let difficulty: BotDifficulty
    let matches: Int
    let playerCount: Int
    var winsBySeat: [Int: Int] = [:]
    var totalLegsPlayed = 0
    var profileBySeat: [Int: BotPerformanceProfile] = [:]

    var aggregateProfile: BotPerformanceProfile {
        BotSimulator.merge(Array(profileBySeat.values))
    }

    var averageLegsPerMatch: Double {
        guard matches > 0 else { return 0 }
        return Double(totalLegsPlayed) / Double(matches)
    }

    var seatAverageSpread: Double {
        let averages = profileBySeat.values.map(\.average3Dart).filter { $0 > 0 }
        guard let minAvg = averages.min(), let maxAvg = averages.max() else { return 0 }
        return maxAvg - minAvg
    }

    mutating func absorb(_ result: BotX01MultiMatchResult) {
        winsBySeat[result.winnerTurnOrder, default: 0] += 1
        totalLegsPlayed += result.legsPlayed
        for seat in 0 ..< playerCount {
            profileBySeat[seat] = BotSimulator.merge([
                profileBySeat[seat] ?? BotPerformanceProfile(),
                result.playerProfiles[seat] ?? BotPerformanceProfile()
            ])
        }
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

    /// Plays a full X01 match with one or more bots and returns per-seat stats.
    static func playX01MultiBotMatch(
        difficulties: [BotDifficulty],
        config: MatchConfigX01 = standard501,
        seed: UInt64
    ) throws -> BotX01MultiMatchResult {
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
            type: .x01,
            config: .x01(config),
            participants: participants
        )

        var profiles = Dictionary(uniqueKeysWithValues: difficulties.indices.map { ($0, BotPerformanceProfile()) })
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

        return BotX01MultiMatchResult(
            winnerTurnOrder: winnerTurnOrder,
            legsPlayed: legsPlayed,
            playerProfiles: profiles
        )
    }

    /// Plays a full X01 match bot-vs-bot with per-player stats (supports same-tier pairs).
    static func playX01Match(
        first: BotDifficulty,
        second: BotDifficulty,
        config: MatchConfigX01 = standard501,
        seed: UInt64
    ) throws -> BotX01MatchResult {
        let result = try playX01MultiBotMatch(
            difficulties: [first, second],
            config: config,
            seed: seed
        )
        let winnerDifficulty = result.winnerTurnOrder == 0 ? first : second
        return BotX01MatchResult(
            winnerTurnOrder: result.winnerTurnOrder,
            winnerDifficulty: winnerDifficulty,
            legsPlayed: result.legsPlayed,
            playerProfiles: result.playerProfiles
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
    let veryEasy = try aggregateGameProfile(difficulty: .veryEasy, games: games, seedBase: 39_901)
    let easy = try aggregateGameProfile(difficulty: .easy, games: games, seedBase: 40_001)
    let medium = try aggregateGameProfile(difficulty: .medium, games: games, seedBase: 40_101)
    let hard = try aggregateGameProfile(difficulty: .hard, games: games, seedBase: 40_201)
    let pro = try aggregateGameProfile(difficulty: .pro, games: games, seedBase: 40_301)

    print("Bot benchmark (\(games) full 501 double-out legs, seeded)")
    print(String(format: "  Very Easy → 3-dart avg: %.1f  bust: %.1f%%  checkout: %.1f%%  visits: %d",
                 veryEasy.average3Dart, veryEasy.bustRate * 100, veryEasy.checkoutRate * 100, veryEasy.visits))
    print(String(format: "  Easy      → 3-dart avg: %.1f  bust: %.1f%%  checkout: %.1f%%  visits: %d",
                 easy.average3Dart, easy.bustRate * 100, easy.checkoutRate * 100, easy.visits))
    print(String(format: "  Medium → 3-dart avg: %.1f  bust: %.1f%%  checkout: %.1f%%  visits: %d",
                 medium.average3Dart, medium.bustRate * 100, medium.checkoutRate * 100, medium.visits))
    print(String(format: "  Hard   → 3-dart avg: %.1f  bust: %.1f%%  checkout: %.1f%%  visits: %d",
                 hard.average3Dart, hard.bustRate * 100, hard.checkoutRate * 100, hard.visits))
    print(String(format: "  Pro    → 3-dart avg: %.1f  bust: %.1f%%  checkout: %.1f%%  visits: %d",
                 pro.average3Dart, pro.bustRate * 100, pro.checkoutRate * 100, pro.visits))

    var easyWins = 0
    var hardWins = 0
    var mediumWins = 0
    let headToHeadGames = 40
    for index in 0 ..< headToHeadGames {
        if try BotSimulator.playX01Game(first: .easy, second: .veryEasy, seed: 49_000 + UInt64(index)).winner == .easy { easyWins += 1 }
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
    print(String(format: "    Easy vs Very Easy: %.0f%%", Double(easyWins) / Double(headToHeadGames) * 100))
    print(String(format: "    Hard vs Easy:      %.0f%%", Double(hardWins) / Double(headToHeadGames) * 100))
    print(String(format: "    Medium vs Easy: %.0f%%", Double(mediumWins) / Double(headToHeadGames) * 100))
    print(String(format: "    Hard vs Medium: %.0f%%", Double(hardVsMediumWins) / Double(headToHeadGames) * 100))
    print(String(format: "    Pro vs Hard:    %.0f%%", Double(proVsHardWins) / Double(headToHeadGames) * 100))

    #expect(pro.average3Dart > hard.average3Dart)
    #expect(hard.average3Dart > medium.average3Dart)
    #expect(medium.average3Dart > easy.average3Dart)
    #expect(easy.average3Dart > veryEasy.average3Dart)
}

@Test(.tags(.integration, .x01, .performance, .regression))
func botLongTermVeryEasyProfileMatchesExpectations() throws {
    let games = 50
    let veryEasy = try aggregateGameProfile(difficulty: .veryEasy, games: games, seedBase: 39_801)
    let easy = try aggregateGameProfile(difficulty: .easy, games: games, seedBase: 39_901)

    #expect(veryEasy.average3Dart >= 12)
    #expect(veryEasy.average3Dart <= 30)
    #expect(veryEasy.bustRate > easy.bustRate)
    #expect(veryEasy.bustRate >= 0.25)
}

@Test(.tags(.integration, .x01, .performance, .regression))
func botLongTermScoringAveragesScaleWithDifficulty() throws {
    let games = 50
    let veryEasy = try aggregateGameProfile(difficulty: .veryEasy, games: games, seedBase: 9_001)
    let easy = try aggregateGameProfile(difficulty: .easy, games: games, seedBase: 10_001)
    let medium = try aggregateGameProfile(difficulty: .medium, games: games, seedBase: 20_001)
    let hard = try aggregateGameProfile(difficulty: .hard, games: games, seedBase: 30_001)
    let pro = try aggregateGameProfile(difficulty: .pro, games: games, seedBase: 35_001)

    // Lower bounds guard against a collapsed bot model; ordering is the primary contract.
    #expect(veryEasy.average3Dart >= 10)
    #expect(easy.average3Dart >= 15)
    #expect(medium.average3Dart >= 30)
    #expect(hard.average3Dart >= 45)
    #expect(hard.average3Dart <= 82)
    #expect(pro.average3Dart >= 55)
    #expect(pro.average3Dart <= 100)

    #expect(pro.average3Dart > hard.average3Dart)
    #expect(hard.average3Dart > medium.average3Dart)
    #expect(medium.average3Dart > easy.average3Dart)
    #expect(easy.average3Dart > veryEasy.average3Dart)

    #expect(pro.average3Dart - veryEasy.average3Dart >= 20)
}

@Test(.tags(.integration, .x01, .performance, .regression))
func botLongTermBustRateDecreasesWithDifficulty() throws {
    let matches = 40
    let veryEasy = try runMirrorTierAnalysis(difficulty: .veryEasy, matches: matches, seedBase: 70_001)
    let easy = try runMirrorTierAnalysis(difficulty: .easy, matches: matches, seedBase: 70_051)
    let medium = try runMirrorTierAnalysis(difficulty: .medium, matches: matches, seedBase: 70_101)
    let hard = try runMirrorTierAnalysis(difficulty: .hard, matches: matches, seedBase: 70_201)
    let pro = try runMirrorTierAnalysis(difficulty: .pro, matches: matches, seedBase: 70_301)

    #expect(veryEasy.profile.bustRate >= 0.20)
    #expect(veryEasy.profile.bustRate > easy.profile.bustRate)
    #expect(easy.profile.bustRate >= 0.15)
    #expect(easy.profile.bustRate > medium.profile.bustRate)
    #expect(medium.profile.bustRate > hard.profile.bustRate)
    #expect(hard.profile.bustRate > pro.profile.bustRate)
}

// MARK: - Head-to-head over many legs

@Test(.tags(.integration, .x01, .performance, .regression))
func botLongTermHeadToHeadWinRatesReflectDifficulty() throws {
    let games = 60
    var wins: [BotDifficulty: Int] = [.veryEasy: 0, .easy: 0, .medium: 0, .hard: 0, .pro: 0]

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

    let easyVsVeryEasy = try play(.easy, .veryEasy, seedBase: 500)
    let hardVsEasy = try play(.hard, .easy, seedBase: 1_000)
    let mediumVsEasy = try play(.medium, .easy, seedBase: 2_000)
    let hardVsMedium = try play(.hard, .medium, seedBase: 3_000)
    let proVsHard = try play(.pro, .hard, seedBase: 4_000)

    #expect(easyVsVeryEasy == .easy)
    #expect(hardVsEasy == .hard)
    #expect(mediumVsEasy == .medium)
    #expect(hardVsMedium == .hard)
    #expect(proVsHard == .pro)

    // Win-rate floors — tuned to current bot model, not pro-dart expectations.
    #expect(Double(wins[.pro, default: 0]) / Double(games) >= 0.55)
    #expect(Double(wins[.hard, default: 0]) / Double(games * 2) >= 0.50)
    #expect(Double(wins[.veryEasy, default: 0]) / Double(games) <= 0.20)
}

@Test(.tags(.integration, .x01, .performance, .regression))
func botLongTermFullGameProfilesStayOrdered() throws {
    let games = 30
    let veryEasyProfile = try aggregateGameProfile(difficulty: .veryEasy, games: games, seedBase: 4_500)
    let easyProfile = try aggregateGameProfile(difficulty: .easy, games: games, seedBase: 5_000)
    let mediumProfile = try aggregateGameProfile(difficulty: .medium, games: games, seedBase: 6_000)
    let hardProfile = try aggregateGameProfile(difficulty: .hard, games: games, seedBase: 7_000)
    let proProfile = try aggregateGameProfile(difficulty: .pro, games: games, seedBase: 7_500)

    #expect(proProfile.average3Dart > hardProfile.average3Dart)
    #expect(hardProfile.average3Dart > mediumProfile.average3Dart)
    #expect(mediumProfile.average3Dart > easyProfile.average3Dart)
    #expect(easyProfile.average3Dart > veryEasyProfile.average3Dart)

    #expect(proProfile.bustRate <= hardProfile.bustRate + 0.03)
    #expect(hardProfile.bustRate <= mediumProfile.bustRate + 0.03)
    #expect(veryEasyProfile.bustRate > easyProfile.bustRate)
}

@Test(.tags(.integration, .x01, .performance, .regression))
func botLongTermCheckoutSuccessScalesWithDifficulty() {
    // Force finishable scores so checkout behaviour is exercised every visit.
    let attempts = 400
    var veryEasy = BotPerformanceProfile()
    var easy = BotPerformanceProfile()
    var medium = BotPerformanceProfile()
    var hard = BotPerformanceProfile()
    var pro = BotPerformanceProfile()

    let finishScores = [40, 32, 36, 24, 16, 50, 44, 28, 20, 18]

    for (index, remaining) in finishScores.enumerated() {
        let seed = UInt64(8_000 + index)
        veryEasy = BotSimulator.merge([
            veryEasy,
            sampleCheckoutVisits(difficulty: .veryEasy, remaining: remaining, count: attempts / finishScores.count, seed: seed)
        ])
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
    #expect(easy.checkoutRate > veryEasy.checkoutRate)
    #expect(veryEasy.checkoutRate >= 0.02)
    #expect(easy.checkoutRate >= 0.05)
    #expect(hard.checkoutRate <= 0.95)
}

// MARK: - Cricket long-run

@Test(.tags(.integration, .cricket, .performance, .regression))
func botLongTermCricketMarksScaleWithDifficulty() throws {
    let rounds = 60
    var veryEasyMarks = 0
    var easyMarks = 0
    var mediumMarks = 0
    var hardMarks = 0
    var proMarks = 0

    for index in 0 ..< rounds {
        veryEasyMarks += try cricketMarksScored(difficulty: .veryEasy, seed: UInt64(8_500 + index))
        easyMarks += try cricketMarksScored(difficulty: .easy, seed: UInt64(9_000 + index))
        mediumMarks += try cricketMarksScored(difficulty: .medium, seed: UInt64(9_500 + index))
        hardMarks += try cricketMarksScored(difficulty: .hard, seed: UInt64(10_000 + index))
        proMarks += try cricketMarksScored(difficulty: .pro, seed: UInt64(10_500 + index))
    }

    #expect(proMarks > hardMarks)

    #expect(hardMarks > mediumMarks)
    #expect(mediumMarks > easyMarks)
    #expect(easyMarks >= veryEasyMarks)
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
    let veryEasy = try runMirrorTierAnalysis(difficulty: .veryEasy, matches: matches, seedBase: 59_901)
    let easy = try runMirrorTierAnalysis(difficulty: .easy, matches: matches, seedBase: 60_001)
    let medium = try runMirrorTierAnalysis(difficulty: .medium, matches: matches, seedBase: 60_101)
    let hard = try runMirrorTierAnalysis(difficulty: .hard, matches: matches, seedBase: 60_201)
    let pro = try runMirrorTierAnalysis(difficulty: .pro, matches: matches, seedBase: 60_301)

    print("Bot tier mirror analysis (best-of-3 501 double-out, \(matches) matches per tier, seeded)")
    printMirrorTierReport(veryEasy)
    printMirrorTierReport(easy)
    printMirrorTierReport(medium)
    printMirrorTierReport(hard)
    printMirrorTierReport(pro)

    #expect(pro.profile.average3Dart > hard.profile.average3Dart)
    #expect(hard.profile.average3Dart > medium.profile.average3Dart)
    #expect(medium.profile.average3Dart > easy.profile.average3Dart)
    #expect(easy.profile.average3Dart > veryEasy.profile.average3Dart)
}

@Test(.tags(.integration, .x01, .performance, .regression))
func botTierMirrorMatchupsStayOrderedByDifficulty() throws {
    let matches = 35
    let seedBases: [BotDifficulty: UInt64] = [
        .veryEasy: 60_901,
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
        #expect(p0Rate >= 0.30)
        #expect(p0Rate <= 0.70)
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

// MARK: - Four-way same-tier matchups (best-of-3 501)

private let fourWayPlayerCount = 4

/// Runs many best-of-3 501 matches with four bots sharing a difficulty tier.
private func runFourWayTierAnalysis(
    difficulty: BotDifficulty,
    matches: Int,
    seedBase: UInt64,
    config: MatchConfigX01 = BotSimulator.bestOfThree501
) throws -> BotFourWayTierReport {
    var report = BotFourWayTierReport(
        difficulty: difficulty,
        matches: matches,
        playerCount: fourWayPlayerCount
    )
    let lineup = Array(repeating: difficulty, count: fourWayPlayerCount)
    for index in 0 ..< matches {
        let result = try BotSimulator.playX01MultiBotMatch(
            difficulties: lineup,
            config: config,
            seed: seedBase + UInt64(index)
        )
        report.absorb(result)
    }
    return report
}

private func printFourWayTierReport(_ report: BotFourWayTierReport) {
    let aggregate = report.aggregateProfile
    print(String(
        format: "  %@  matches: %3d  agg 3-dart avg: %5.1f  zero visits: %4.1f%%  bust: %4.1f%%  checkout: %4.1f%%  legs/match: %.2f  seat avg spread: %.1f",
        report.difficulty.displayName,
        report.matches,
        aggregate.average3Dart,
        aggregate.zeroVisitRate * 100,
        aggregate.bustRate * 100,
        aggregate.checkoutRate * 100,
        report.averageLegsPerMatch,
        report.seatAverageSpread
    ))

    let seatSummaries = (0 ..< report.playerCount).map { seat -> String in
        let wins = Double(report.winsBySeat[seat, default: 0]) / Double(report.matches) * 100
        let avg = report.profileBySeat[seat]?.average3Dart ?? 0
        return String(format: "P%d %.0f%%/%.1f", seat, wins, avg)
    }
    print("    seats: \(seatSummaries.joined(separator: "  |  "))")
}

/// Run `botTierFourWayMatchAnalysisSnapshot` in Xcode to print a four-bot tuning report.
@Test(.tags(.integration, .x01, .performance, .regression))
func botTierFourWayMatchAnalysisSnapshot() throws {
    let matches = 30
    let veryEasy = try runFourWayTierAnalysis(difficulty: .veryEasy, matches: matches, seedBase: 63_901)
    let easy = try runFourWayTierAnalysis(difficulty: .easy, matches: matches, seedBase: 64_001)
    let medium = try runFourWayTierAnalysis(difficulty: .medium, matches: matches, seedBase: 64_101)
    let hard = try runFourWayTierAnalysis(difficulty: .hard, matches: matches, seedBase: 64_201)
    let pro = try runFourWayTierAnalysis(difficulty: .pro, matches: matches, seedBase: 64_301)

    print("Bot four-way tier analysis (best-of-3 501 double-out, \(fourWayPlayerCount) bots, \(matches) matches per tier, seeded)")
    printFourWayTierReport(veryEasy)
    printFourWayTierReport(easy)
    printFourWayTierReport(medium)
    printFourWayTierReport(hard)
    printFourWayTierReport(pro)

    #expect(pro.aggregateProfile.average3Dart > hard.aggregateProfile.average3Dart)
    #expect(hard.aggregateProfile.average3Dart > medium.aggregateProfile.average3Dart)
    #expect(medium.aggregateProfile.average3Dart > easy.aggregateProfile.average3Dart)
    #expect(easy.aggregateProfile.average3Dart > veryEasy.aggregateProfile.average3Dart)
}

@Test(.tags(.integration, .x01, .performance, .regression))
func botTierFourWayMatchupsStayOrderedByDifficulty() throws {
    let matches = 25
    let seedBases: [BotDifficulty: UInt64] = [
        .veryEasy: 64_901,
        .easy: 65_001,
        .medium: 65_101,
        .hard: 65_201,
        .pro: 65_301
    ]
    let reports = try BotDifficulty.allCases.map { difficulty in
        try runFourWayTierAnalysis(
            difficulty: difficulty,
            matches: matches,
            seedBase: seedBases[difficulty]!
        )
    }

    for index in 1 ..< reports.count {
        #expect(reports[index].aggregateProfile.average3Dart > reports[index - 1].aggregateProfile.average3Dart)
    }
}

@Test(.tags(.integration, .x01, .performance, .regression))
func botTierFourWayMatchupsHaveBalancedWinDistribution() throws {
    let matches = 80
    for (offset, difficulty) in BotDifficulty.allCases.enumerated() {
        let report = try runFourWayTierAnalysis(
            difficulty: difficulty,
            matches: matches,
            seedBase: 66_000 + UInt64(offset * 1_000)
        )
        for seat in 0 ..< report.playerCount {
            let winRate = Double(report.winsBySeat[seat, default: 0]) / Double(matches)
            // Equal bots should spread wins across seats; allow statistical noise.
            #expect(winRate >= 0.12)
            #expect(winRate <= 0.38)
        }
    }
}

@Test(.tags(.integration, .x01, .performance, .regression))
func botTierFourWayPerSeatAveragesClusterTightly() throws {
    let matches = 40
    for (offset, difficulty) in BotDifficulty.allCases.enumerated() {
        let report = try runFourWayTierAnalysis(
            difficulty: difficulty,
            matches: matches,
            seedBase: 67_000 + UInt64(offset * 1_000)
        )
        // Same-tier bots should land near the same average regardless of seat.
        #expect(report.seatAverageSpread <= 10.0)
    }
}

@Test(.tags(.integration, .x01, .performance, .regression))
func botTierFourWayMatchesCompleteInReasonableLegCount() throws {
    let matches = 30
    for (offset, difficulty) in BotDifficulty.allCases.enumerated() {
        let report = try runFourWayTierAnalysis(
            difficulty: difficulty,
            matches: matches,
            seedBase: 68_000 + UInt64(offset * 1_000)
        )
        // Four-player rotation spreads leg wins across seats before someone reaches two.
        #expect(report.averageLegsPerMatch >= 2.0)
        #expect(report.averageLegsPerMatch <= 6.0)
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
    case .veryEasy: .easy
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
