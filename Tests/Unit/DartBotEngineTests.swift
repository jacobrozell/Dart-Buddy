import Foundation
import Testing
@testable import DartBuddy

@Test func dartBotEngine_generatesThreeX01Darts() {
    var rng = SeededRandomNumberGenerator(seed: 42)
    let darts = DartBotEngine.generateX01Turn(
        remaining: 501,
        difficulty: .medium,
        checkoutMode: .doubleOut,
        checkInMode: .straightIn,
        isCheckedIn: true,
        rng: &rng
    )
    #expect(darts.count == 3)
    #expect(darts.allSatisfy { $0.isMiss == false || $0.points == 0 })
}

@Test func dartBotEngine_parsesCheckoutLabels() {
    #expect(DartBotEngine.dart(fromCheckoutLabel: "T20")?.multiplier == .triple)
    #expect(DartBotEngine.dart(fromCheckoutLabel: "D16")?.multiplier == .double)
    #expect(DartBotEngine.dart(fromCheckoutLabel: "Bull")?.segment == .innerBull)
}

@Test func dartBotEngine_proBotAveragesHigherThanHard() {
    var hardTotal = 0
    var proTotal = 0
    for seed in 0 ..< 80 {
        var hardRNG = SeededRandomNumberGenerator(seed: UInt64(seed))
        var proRNG = SeededRandomNumberGenerator(seed: UInt64(seed))
        hardTotal += DartBotEngine.generateX01Turn(
            remaining: 501,
            difficulty: .hard,
            checkoutMode: .doubleOut,
            checkInMode: .straightIn,
            isCheckedIn: true,
            rng: &hardRNG
        ).reduce(0) { $0 + $1.points }
        proTotal += DartBotEngine.generateX01Turn(
            remaining: 501,
            difficulty: .pro,
            checkoutMode: .doubleOut,
            checkInMode: .straightIn,
            isCheckedIn: true,
            rng: &proRNG
        ).reduce(0) { $0 + $1.points }
    }
    #expect(proTotal > hardTotal)
}

@Test func dartBotEngine_easyBotAveragesHigherThanVeryEasy() {
    var veryEasyTotal = 0
    var easyTotal = 0
    for seed in 0 ..< 80 {
        var veryEasyRNG = SeededRandomNumberGenerator(seed: UInt64(seed))
        var easyRNG = SeededRandomNumberGenerator(seed: UInt64(seed))
        veryEasyTotal += DartBotEngine.generateX01Turn(
            remaining: 501,
            difficulty: .veryEasy,
            checkoutMode: .doubleOut,
            checkInMode: .straightIn,
            isCheckedIn: true,
            rng: &veryEasyRNG
        ).reduce(0) { $0 + $1.points }
        easyTotal += DartBotEngine.generateX01Turn(
            remaining: 501,
            difficulty: .easy,
            checkoutMode: .doubleOut,
            checkInMode: .straightIn,
            isCheckedIn: true,
            rng: &easyRNG
        ).reduce(0) { $0 + $1.points }
    }
    #expect(easyTotal > veryEasyTotal)
}

@Test func dartBotEngine_hardBotAveragesHigherThanEasy() {
    var easyTotal = 0
    var hardTotal = 0
    for seed in 0 ..< 80 {
        var easyRNG = SeededRandomNumberGenerator(seed: UInt64(seed))
        var hardRNG = SeededRandomNumberGenerator(seed: UInt64(seed))
        easyTotal += DartBotEngine.generateX01Turn(
            remaining: 501,
            difficulty: .easy,
            checkoutMode: .doubleOut,
            checkInMode: .straightIn,
            isCheckedIn: true,
            rng: &easyRNG
        ).reduce(0) { $0 + $1.points }
        hardTotal += DartBotEngine.generateX01Turn(
            remaining: 501,
            difficulty: .hard,
            checkoutMode: .doubleOut,
            checkInMode: .straightIn,
            isCheckedIn: true,
            rng: &hardRNG
        ).reduce(0) { $0 + $1.points }
    }
    #expect(hardTotal > easyTotal)
}

@Test func dartBotEngine_generatesBaseballTurn() {
    var rng = SeededRandomNumberGenerator(seed: 11)
    let darts = DartBotEngine.generateBaseballTurn(
        targetSegment: 4,
        phase: .innings,
        stretchGateOpen: true,
        seventhInningStretch: false,
        profile: BotDifficulty.medium.skillProfile,
        rng: &rng
    )
    #expect(darts.count == 3)
}

@Test func dartBotEngine_generatesShanghaiTurn() {
    var rng = SeededRandomNumberGenerator(seed: 13)
    let darts = DartBotEngine.generateShanghaiTurn(
        targetSegment: 7,
        profile: BotDifficulty.medium.skillProfile,
        rng: &rng
    )
    #expect(darts.count == 3)
}

@Test func dartBotEngine_shanghaiEasyBotScoresMorePointsThanVeryEasy() throws {
    var veryEasyPoints = 0
    var easyPoints = 0
    let samples = 120

    for seed in 0 ..< samples {
        for round in 1 ... 7 {
            var veryEasyRNG = SeededRandomNumberGenerator(seed: UInt64(seed * 10 + round))
            var easyRNG = SeededRandomNumberGenerator(seed: UInt64(seed * 10 + round))

            let veryEasyDarts = DartBotEngine.generateShanghaiTurn(
                targetSegment: round,
                profile: BotDifficulty.veryEasy.skillProfile,
                rng: &veryEasyRNG
            )
            let easyDarts = DartBotEngine.generateShanghaiTurn(
                targetSegment: round,
                profile: BotDifficulty.easy.skillProfile,
                rng: &easyRNG
            )

            veryEasyPoints += try scoreShanghaiVisit(darts: veryEasyDarts, round: round)
            easyPoints += try scoreShanghaiVisit(darts: easyDarts, round: round)
        }
    }

    #expect(easyPoints > veryEasyPoints)
}

@Test func dartBotEngine_shanghaiMediumBotScoresMorePointsThanEasy() throws {
    var easyPoints = 0
    var mediumPoints = 0
    let samples = 120

    for seed in 0 ..< samples {
        for round in 1 ... 7 {
            var easyRNG = SeededRandomNumberGenerator(seed: UInt64(seed * 10 + round + 500))
            var mediumRNG = SeededRandomNumberGenerator(seed: UInt64(seed * 10 + round + 500))

            let easyDarts = DartBotEngine.generateShanghaiTurn(
                targetSegment: round,
                profile: BotDifficulty.easy.skillProfile,
                rng: &easyRNG
            )
            let mediumDarts = DartBotEngine.generateShanghaiTurn(
                targetSegment: round,
                profile: BotDifficulty.medium.skillProfile,
                rng: &mediumRNG
            )

            easyPoints += try scoreShanghaiVisit(darts: easyDarts, round: round)
            mediumPoints += try scoreShanghaiVisit(darts: mediumDarts, round: round)
        }
    }

    #expect(mediumPoints > easyPoints)
}

@Test func dartBotEngine_shanghaiVeryEasyAndEasyNeverThrowDoublesOrTriples() {
    let samples = 200
    for difficulty in [BotDifficulty.veryEasy, .easy] {
        for seed in 0 ..< samples {
            for round in 1 ... 7 {
                var rng = SeededRandomNumberGenerator(seed: UInt64(seed * 20 + round))
                let darts = DartBotEngine.generateShanghaiTurn(
                    targetSegment: round,
                    profile: difficulty.skillProfile,
                    rng: &rng
                )
                for dart in darts where dart.isMiss == false {
                    #expect(dart.multiplier == .single)
                }
            }
        }
    }
}

@Test func dartBotEngine_baseballEasyBotScoresMoreRunsThanVeryEasy() throws {
    var veryEasyRuns = 0
    var easyRuns = 0
    let samples = 120

    for seed in 0 ..< samples {
        for inning in 1 ... 9 {
            var veryEasyRNG = SeededRandomNumberGenerator(seed: UInt64(seed * 10 + inning))
            var easyRNG = SeededRandomNumberGenerator(seed: UInt64(seed * 10 + inning))
            let inningSegment = inning

            let veryEasyDarts = DartBotEngine.generateBaseballTurn(
                targetSegment: inningSegment,
                phase: .innings,
                stretchGateOpen: true,
                seventhInningStretch: false,
                profile: BotDifficulty.veryEasy.skillProfile,
                rng: &veryEasyRNG
            )
            let easyDarts = DartBotEngine.generateBaseballTurn(
                targetSegment: inningSegment,
                phase: .innings,
                stretchGateOpen: true,
                seventhInningStretch: false,
                profile: BotDifficulty.easy.skillProfile,
                rng: &easyRNG
            )

            veryEasyRuns += try scoreBaseballVisit(darts: veryEasyDarts, inning: inningSegment)
            easyRuns += try scoreBaseballVisit(darts: easyDarts, inning: inningSegment)
        }
    }

    #expect(easyRuns > veryEasyRuns)
}

@Test func dartBotEngine_baseballMediumBotScoresMoreRunsThanEasy() throws {
    var easyRuns = 0
    var mediumRuns = 0
    let samples = 120

    for seed in 0 ..< samples {
        for inning in 1 ... 9 {
            var easyRNG = SeededRandomNumberGenerator(seed: UInt64(seed * 10 + inning + 500))
            var mediumRNG = SeededRandomNumberGenerator(seed: UInt64(seed * 10 + inning + 500))
            let inningSegment = inning

            let easyDarts = DartBotEngine.generateBaseballTurn(
                targetSegment: inningSegment,
                phase: .innings,
                stretchGateOpen: true,
                seventhInningStretch: false,
                profile: BotDifficulty.easy.skillProfile,
                rng: &easyRNG
            )
            let mediumDarts = DartBotEngine.generateBaseballTurn(
                targetSegment: inningSegment,
                phase: .innings,
                stretchGateOpen: true,
                seventhInningStretch: false,
                profile: BotDifficulty.medium.skillProfile,
                rng: &mediumRNG
            )

            easyRuns += try scoreBaseballVisit(darts: easyDarts, inning: inningSegment)
            mediumRuns += try scoreBaseballVisit(darts: mediumDarts, inning: inningSegment)
        }
    }

    #expect(mediumRuns > easyRuns)
}

@Test func dartBotEngine_generatesCricketTurn() {
    let players = [UUID(), UUID()]
    let state = try! CricketEngine.makeInitialState(
        config: MatchConfigCricket(),
        playerIds: players
    )
    var rng = SeededRandomNumberGenerator(seed: 7)
    let darts = DartBotEngine.generateCricketTurn(
        state: state,
        playerIndex: 0,
        difficulty: .medium,
        rng: &rng
    )
    #expect(darts.count == 3)
}

@Test func dartBotEngine_resolvesParticipantDifficulty() {
    let botId = UUID()
    let participant = MatchParticipant(
        playerId: botId,
        displayNameAtMatchStart: BotDifficulty.medium.rosterName,
        turnOrder: 0,
        botDifficultyRaw: BotDifficulty.medium.rawValue
    )
    #expect(DartBotEngine.botDifficulty(for: participant) == .medium)
    #expect(DartBotEngine.botDifficulty(playerId: botId, in: [participant]) == .medium)
}

@Test func dartBotEngine_checkoutTurnProducesLegalDarts() throws {
    var rng = SeededRandomNumberGenerator(seed: 99)
    let darts = DartBotEngine.generateX01Turn(
        remaining: 40,
        difficulty: .hard,
        checkoutMode: .doubleOut,
        checkInMode: .straightIn,
        isCheckedIn: true,
        rng: &rng
    )
    #expect(!darts.isEmpty)
    #expect(darts.count <= 3)

    var state = try X01Engine.makeInitialState(
        config: MatchConfigX01(
            startScore: 501,
            legsToWin: 1,
            setsEnabled: false,
            setsToWin: nil,
            checkoutMode: .doubleOut
        ),
        playerIds: [UUID(), UUID()]
    )
    state.players[0].remainingScore = 40
    let outcome = try X01Engine.submitTurn(state: state, enteredTotal: nil, darts: darts)
    #expect(outcome.event.isBust == false || outcome.event.appliedTotal >= 0)
}

@Test func dartBotEngine_cricketTurnProducesZeroMarkDarts() {
    let players = [UUID(), UUID()]
    let state = try! CricketEngine.makeInitialState(
        config: MatchConfigCricket(),
        playerIds: players
    )
    var zeroMarkDarts = 0
    let samples = 300

    for seed in 0 ..< samples {
        var rng = SeededRandomNumberGenerator(seed: UInt64(seed + 400))
        let darts = DartBotEngine.generateCricketTurn(
            state: state,
            playerIndex: 0,
            difficulty: .medium,
            rng: &rng
        )
        zeroMarkDarts += darts.filter { dart in
            dart.isMiss || dart.segment.cricketTargetRaw == nil
        }.count
    }

    let rate = Double(zeroMarkDarts) / Double(samples * 3)
    #expect(rate >= 0.18)
}

@Test func dartBotEngine_cricketResolvedDartsStayOnBoard() {
    let players = [UUID(), UUID()]
    let state = try! CricketEngine.makeInitialState(
        config: MatchConfigCricket(),
        playerIds: players
    )
    var rng = SeededRandomNumberGenerator(seed: 21)
    let darts = DartBotEngine.generateCricketTurn(
        state: state,
        playerIndex: 0,
        difficulty: .hard,
        rng: &rng
    )
    for dart in darts {
        if dart.isMiss { continue }
        switch dart.segment {
        case .oneToTwenty, .innerBull, .outerBull:
            break
        case .miss:
            Issue.record("Non-miss dart used miss segment")
        }
    }
}

@Test func dartBotEngine_zeroVisitRateIsRareForStraightIn() {
    let limits: [BotDifficulty: Double] = [
        .veryEasy: 0.12,
        .easy: 0.08,
        .medium: 0.04,
        .hard: 0.03,
        .pro: 0.02
    ]
    let samples = 500

    for difficulty in BotDifficulty.allCases {
        var zeroVisits = 0
        for seed in 0 ..< samples {
            var rng = SeededRandomNumberGenerator(seed: UInt64(seed + 1_000))
            let darts = DartBotEngine.generateX01Turn(
                remaining: 501,
                difficulty: difficulty,
                checkoutMode: .doubleOut,
                checkInMode: .straightIn,
                isCheckedIn: true,
                rng: &rng
            )
            if darts.reduce(0, { $0 + $1.points }) == 0 {
                zeroVisits += 1
            }
        }
        let rate = Double(zeroVisits) / Double(samples)
        #expect(rate <= limits[difficulty]!)
    }
}

@Test func dartBotEngine_cricketCutThroatPrefersHighestOpenTarget() throws {
    let players = [UUID(), UUID()]
    var state = try CricketEngine.makeInitialState(
        config: cricketConfig(scoringMode: .cutThroat),
        playerIds: players
    )
    state.players[0].marks["20"] = 0
    state.players[0].marks["19"] = 3

    var foundAimAt20 = false
    for seed in 0 ..< 64 {
        var rng = SeededRandomNumberGenerator(seed: UInt64(seed))
        let darts = DartBotEngine.generateCricketTurn(
            state: state,
            playerIndex: 0,
            difficulty: .pro,
            rng: &rng
        )
        if darts.contains(where: { cricketDartAims(at: 20, dart: $0) }) {
            foundAimAt20 = true
            break
        }
    }
    #expect(foundAimAt20)
}

@Test func dartBotEngine_cricketCutThroatPunishesClosedBedWhenOpponentOpen() throws {
    let players = [UUID(), UUID()]
    var state = try CricketEngine.makeInitialState(
        config: cricketConfig(scoringMode: .cutThroat),
        playerIds: players
    )
    let allClosed = Dictionary(uniqueKeysWithValues: CricketTarget.allCases.map { ($0.rawValue, 3) })
    state.players[0].marks = allClosed
    state.players[1].marks = allClosed
    state.players[1].marks["20"] = 0

    var foundPunishAim = false
    for seed in 0 ..< 64 {
        var rng = SeededRandomNumberGenerator(seed: UInt64(seed))
        let darts = DartBotEngine.generateCricketTurn(
            state: state,
            playerIndex: 0,
            difficulty: .pro,
            rng: &rng
        )
        if darts.allSatisfy({ cricketDartAims(at: 20, dart: $0) }) {
            foundPunishAim = true
            break
        }
    }
    #expect(foundPunishAim)
}

@Test func dartBotEngine_cricketCutThroatPunishInflictsOpponentPoints() throws {
    let players = [UUID(), UUID()]
    var state = try CricketEngine.makeInitialState(
        config: cricketConfig(scoringMode: .cutThroat),
        playerIds: players
    )
    let allClosed = Dictionary(uniqueKeysWithValues: CricketTarget.allCases.map { ($0.rawValue, 3) })
    state.players[0].marks = allClosed
    state.players[1].marks = allClosed
    state.players[1].marks["20"] = 0

    for seed in 0 ..< 64 {
        var rng = SeededRandomNumberGenerator(seed: UInt64(seed + 200))
        let darts = DartBotEngine.generateCricketTurn(
            state: state,
            playerIndex: 0,
            difficulty: .pro,
            rng: &rng
        )
        let outcome = try CricketEngine.submitTurn(state: state, darts: darts)
        if outcome.updatedState.players[1].score > 0 {
            #expect(outcome.updatedState.players[0].score == 0)
            return
        }
    }
    Issue.record("Expected at least one seeded cut-throat punish visit to score on opponent")
}

@Test func dartBotEngine_cricketStandardStillClosesFromTwenty() throws {
    let players = [UUID(), UUID()]
    let state = try CricketEngine.makeInitialState(
        config: cricketConfig(scoringMode: .standard),
        playerIds: players
    )

    var foundAimAt20 = false
    for seed in 0 ..< 64 {
        var rng = SeededRandomNumberGenerator(seed: UInt64(seed))
        let darts = DartBotEngine.generateCricketTurn(
            state: state,
            playerIndex: 0,
            difficulty: .pro,
            rng: &rng
        )
        if darts.contains(where: { cricketDartAims(at: 20, dart: $0) }) {
            foundAimAt20 = true
            break
        }
    }
    #expect(foundAimAt20)
}

@Test func dartBotEngine_bustAvoidanceScoresOnBoard() {
    var rng = SeededRandomNumberGenerator(seed: 77)
    let darts = DartBotEngine.generateX01Turn(
        remaining: 32,
        difficulty: .medium,
        checkoutMode: .doubleOut,
        checkInMode: .straightIn,
        isCheckedIn: true,
        rng: &rng
    )
    #expect(darts.allSatisfy { $0.isMiss == false || $0.points == 0 })
    #expect(darts.contains { $0.points > 0 })
}

@Test func dartBotEngine_killerPickAvoidsTakenNumbers() {
    var rng = SeededRandomNumberGenerator(seed: 11)
    let profile = BotDifficulty.medium.skillProfile
    let taken: Set<Int> = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19]
    for _ in 0 ..< 32 {
        let dart = DartBotEngine.generateKillerPick(takenNumbers: taken, profile: profile, rng: &rng)
        if case let .oneToTwenty(value) = dart.segment {
            #expect(value == 20)
        }
    }
}

@Test func dartBotEngine_killerTurnAimsOwnDoublePreKiller() throws {
    let players = [UUID(), UUID(), UUID()]
    var state = try KillerEngine.makeInitialState(
        config: MatchConfigKiller(startingLives: 3),
        playerIds: players
    )
    state.phase = .playing
    state.players[0].assignedNumber = 12
    state.players[1].assignedNumber = 8
    state.players[2].assignedNumber = 16
    state.currentPlayerIndex = 0

    var foundOwnDouble = false
    for seed in 0 ..< 64 {
        var rng = SeededRandomNumberGenerator(seed: UInt64(seed))
        let darts = DartBotEngine.generateKillerTurn(
            state: state,
            throwerIndex: 0,
            profile: BotDifficulty.pro.skillProfile,
            rng: &rng
        )
        if darts.contains(where: killerDartAims(at: 12, multiplier: .double, dart: $0)) {
            foundOwnDouble = true
            break
        }
    }
    #expect(foundOwnDouble)
}

@Test func dartBotEngine_killerTurnTargetsWeakestOpponentWhenKiller() throws {
    let players = [UUID(), UUID(), UUID()]
    var state = try KillerEngine.makeInitialState(
        config: MatchConfigKiller(startingLives: 3),
        playerIds: players
    )
    state.phase = .playing
    state.players[0].assignedNumber = 12
    state.players[0].isKiller = true
    state.players[1].assignedNumber = 8
    state.players[1].lives = 1
    state.players[2].assignedNumber = 16
    state.players[2].lives = 3
    state.currentPlayerIndex = 0

    var foundWeakestTarget = false
    for seed in 0 ..< 64 {
        var rng = SeededRandomNumberGenerator(seed: UInt64(seed))
        let darts = DartBotEngine.generateKillerTurn(
            state: state,
            throwerIndex: 0,
            profile: BotDifficulty.pro.skillProfile,
            rng: &rng
        )
        if darts.contains(where: killerDartAims(at: 8, multiplier: .double, dart: $0)) {
            foundWeakestTarget = true
            break
        }
    }
    #expect(foundWeakestTarget)
}

@Test func dartBotEngine_killerTurnGeneratesThreeDarts() throws {
    let players = [UUID(), UUID(), UUID()]
    var state = try KillerEngine.makeInitialState(
        config: MatchConfigKiller(startingLives: 3),
        playerIds: players
    )
    state.phase = .playing
    state.players[0].assignedNumber = 12
    state.players[1].assignedNumber = 8
    state.players[2].assignedNumber = 16
    state.currentPlayerIndex = 0

    var rng = SeededRandomNumberGenerator(seed: 42)
    let darts = DartBotEngine.generateKillerTurn(
        state: state,
        throwerIndex: 0,
        profile: BotDifficulty.medium.skillProfile,
        rng: &rng
    )
    #expect(darts.count == 3)
}

private func scoreShanghaiVisit(darts: [DartInput], round: Int) throws -> Int {
    var state = try ShanghaiEngine.makeInitialState(
        config: MatchConfigShanghai(roundCount: round),
        playerIds: [UUID(), UUID()]
    )
    state.currentRound = round
    let outcome = try ShanghaiEngine.submitTurn(state: state, darts: darts)
    return outcome.event.pointsThisVisit
}

private func scoreBaseballVisit(darts: [DartInput], inning: Int) throws -> Int {
    var state = try BaseballEngine.makeInitialState(
        config: MatchConfigBaseball(inningCount: inning),
        playerIds: [UUID(), UUID()]
    )
    state.currentInning = inning
    let outcome = try BaseballEngine.submitTurn(state: state, darts: darts)
    return outcome.event.runsThisVisit
}

private func cricketDartAims(at value: Int, dart: DartInput) -> Bool {
    switch dart.segment {
    case let .oneToTwenty(segmentValue):
        return segmentValue == value
    default:
        return false
    }
}

private func killerDartAims(at value: Int, multiplier: DartMultiplier, dart: DartInput) -> Bool {
    dart.multiplier == multiplier && cricketDartAims(at: value, dart: dart)
}

private struct SeededRandomNumberGenerator: RandomNumberGenerator {
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
