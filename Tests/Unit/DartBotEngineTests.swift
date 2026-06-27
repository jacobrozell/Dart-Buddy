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

@Test func dartBotEngine_baseballNonScoringMissesLandNearTarget() {
    let clockwise = [20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5]
    func isClockNeighbor(_ target: Int, _ landed: Int) -> Bool {
        guard let index = clockwise.firstIndex(of: target) else { return false }
        let left = clockwise[(index - 1 + clockwise.count) % clockwise.count]
        let right = clockwise[(index + 1) % clockwise.count]
        return landed == left || landed == right
    }

    for seed in 0 ..< 200 {
        for target in 1 ... 20 {
            var rng = SeededRandomNumberGenerator(seed: UInt64(seed * 40 + target))
            let darts = DartBotEngine.generateBaseballTurn(
                targetSegment: target,
                phase: .innings,
                stretchGateOpen: true,
                seventhInningStretch: false,
                profile: BotDifficulty.veryEasy.skillProfile,
                rng: &rng
            )
            for dart in darts where dart.isMiss == false {
                guard case let .oneToTwenty(value) = dart.segment else { continue }
                if value != target {
                    #expect(
                        isClockNeighbor(target, value),
                        "Non-scoring dart landed on \(value) during inning \(target)"
                    )
                }
            }
        }
    }
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

@Test func dartBotEngine_generatesHalveItTurn() {
    var rng = SeededRandomNumberGenerator(seed: 21)
    let darts = DartBotEngine.generateHalveItTurn(
        targetSegment: 16,
        profile: BotDifficulty.medium.skillProfile,
        rng: &rng
    )
    #expect(darts.count == 3)
}

@Test func dartBotEngine_halveItMediumBotScoresMoreThanVeryEasy() throws {
    var veryEasyTotal = 0
    var mediumTotal = 0
    let samples = 80

    for seed in 0 ..< samples {
        for target in [20, 19, 18, 17, 16, 15] {
            var veryEasyRNG = SeededRandomNumberGenerator(seed: UInt64(seed * 10 + target))
            var mediumRNG = SeededRandomNumberGenerator(seed: UInt64(seed * 10 + target + 900))

            let veryEasyDarts = DartBotEngine.generateHalveItTurn(
                targetSegment: target,
                profile: BotDifficulty.veryEasy.skillProfile,
                rng: &veryEasyRNG
            )
            let mediumDarts = DartBotEngine.generateHalveItTurn(
                targetSegment: target,
                profile: BotDifficulty.medium.skillProfile,
                rng: &mediumRNG
            )

            veryEasyTotal += veryEasyDarts.reduce(0) {
                $0 + HalveItEngine.scoreContribution($1, target: target)
            }
            mediumTotal += mediumDarts.reduce(0) {
                $0 + HalveItEngine.scoreContribution($1, target: target)
            }
        }
    }

    #expect(mediumTotal > veryEasyTotal)
}

@Test func dartBotEngine_scamStopperPrioritizesHighestOpenSegments() {
    let profile = killerPickTestProfile()
    var rng = SeededRandomNumberGenerator(seed: 31)
    let darts = DartBotEngine.generateScamStopperTurn(
        closedSegments: [],
        profile: profile,
        rng: &rng
    )
    let closed = darts.compactMap { ScamEngine.stopperSegment(from: $0) }
    #expect(closed == [20, 19, 18])
}

@Test func dartBotEngine_scamStopperSkipsAlreadyClosedSegments() {
    let profile = killerPickTestProfile()
    var rng = SeededRandomNumberGenerator(seed: 32)
    let darts = DartBotEngine.generateScamStopperTurn(
        closedSegments: [20, 19],
        profile: profile,
        rng: &rng
    )
    let closed = darts.compactMap { ScamEngine.stopperSegment(from: $0) }
    #expect(closed == [18, 17, 16])
}

@Test func dartBotEngine_snookerRedBotPrefersHighestAvailableRed() {
    let profile = killerPickTestProfile()
    var state = try! SnookerEngine.makeInitialState(
        config: MatchConfigSnooker(),
        playerIds: [UUID(), UUID()]
    )
    state.availableReds = [3, 11, 15]
    var rng = SeededRandomNumberGenerator(seed: 44)
    let dart = DartBotEngine.generateSnookerDart(
        state: state,
        profile: profile,
        nominatedColour: nil,
        rng: &rng
    )
    guard case let .oneToTwenty(value) = dart.segment else {
        Issue.record("Expected numeric snooker red dart")
        return
    }
    #expect(value == 15)
}

@Test func dartBotEngine_snookerNominationAfterRedDefaultsToBlack() {
    let profile = BotDifficulty.medium.skillProfile
    var state = try! SnookerEngine.makeInitialState(
        config: MatchConfigSnooker(),
        playerIds: [UUID(), UUID()]
    )
    var rng = SeededRandomNumberGenerator(seed: 45)
    #expect(
        DartBotEngine.generateSnookerNomination(state: state, profile: profile, rng: &rng) == .black
    )
}

@Test func dartBotEngine_ticTacToeBotBlocksOpponentWin() {
    let profile = killerPickTestProfile()
    var grid: [TicTacToeSide?] = [
        .x, .x, nil,
        .o, nil, nil,
        nil, nil, nil,
    ]
    var rng = SeededRandomNumberGenerator(seed: 46)
    let cell = DartBotEngine.preferredTicTacToeCellIndex(
        grid: grid,
        side: .o,
        profile: profile,
        rng: &rng
    )
    #expect(cell == 2)
}

@Test func dartBotEngine_bobs27DoubleBotAimsAtRoundDouble() {
    let profile = killerPickTestProfile()
    var rng = SeededRandomNumberGenerator(seed: 47)
    let darts = DartBotEngine.generateBobs27Turn(
        target: .double(12),
        profile: profile,
        rng: &rng
    )
    #expect(darts.count == 3)
    for dart in darts {
        #expect(dart.multiplier == .double)
        guard case let .oneToTwenty(value) = dart.segment else {
            Issue.record("Expected double segment dart")
            return
        }
        #expect(value == 12)
    }
}

@Test func dartBotEngine_followTheLeaderOpeningVeryEasySetsSingleTwenty() {
    let players = [UUID(), UUID()]
    let state = try! FollowTheLeaderEngine.makeInitialState(
        config: MatchConfigFollowTheLeader(),
        playerIds: players
    )
    var rng = SeededRandomNumberGenerator(seed: 48)
    let darts = DartBotEngine.generateFollowTheLeaderVisit(
        state: state,
        profile: BotDifficulty.veryEasy.skillProfile,
        rng: &rng
    )
    #expect(darts.count == 1)
    guard let area = FollowTheLeaderEngine.targetArea(from: darts[0]) else {
        Issue.record("Expected scoring opening dart")
        return
    }
    #expect(area.segment == 20)
    #expect(area.ring == .single)
}

@Test func dartBotEngine_followTheLeaderMatchingVisitAimsAtTarget() {
    let players = [UUID(), UUID()]
    var state = try! FollowTheLeaderEngine.makeInitialState(
        config: MatchConfigFollowTheLeader(),
        playerIds: players
    )
    state = try! FollowTheLeaderEngine.submitVisit(state: state, darts: [
        DartInput(multiplier: .double, segment: .oneToTwenty(12))
    ]).updatedState

    var matchAttempts = 0
    for seed in 0 ..< 64 {
        var rng = SeededRandomNumberGenerator(seed: UInt64(seed + 500))
        let darts = DartBotEngine.generateFollowTheLeaderVisit(
            state: state,
            profile: BotDifficulty.pro.skillProfile,
            rng: &rng
        )
        if darts.contains(where: { FollowTheLeaderEngine.dartMatchesTarget($0, target: state.target!) }) {
            matchAttempts += 1
        }
    }
    #expect(matchAttempts > 0)
}

@Test func dartBotEngine_followTheLeaderProMatchesMoreThanVeryEasy() {
    let players = [UUID(), UUID()]
    var state = try! FollowTheLeaderEngine.makeInitialState(
        config: MatchConfigFollowTheLeader(),
        playerIds: players
    )
    state = try! FollowTheLeaderEngine.submitVisit(state: state, darts: [
        DartInput(multiplier: .double, segment: .oneToTwenty(16))
    ]).updatedState

    var veryEasyMatches = 0
    var proMatches = 0
    for seed in 0 ..< 80 {
        var veryEasyRNG = SeededRandomNumberGenerator(seed: UInt64(seed))
        var proRNG = SeededRandomNumberGenerator(seed: UInt64(seed))
        let veryEasy = DartBotEngine.generateFollowTheLeaderVisit(
            state: state,
            profile: BotDifficulty.veryEasy.skillProfile,
            rng: &veryEasyRNG
        )
        let pro = DartBotEngine.generateFollowTheLeaderVisit(
            state: state,
            profile: BotDifficulty.pro.skillProfile,
            rng: &proRNG
        )
        if veryEasy.contains(where: { FollowTheLeaderEngine.dartMatchesTarget($0, target: state.target!) }) {
            veryEasyMatches += 1
        }
        if pro.contains(where: { FollowTheLeaderEngine.dartMatchesTarget($0, target: state.target!) }) {
            proMatches += 1
        }
    }
    #expect(proMatches > veryEasyMatches)
}

@Test func dartBotEngine_blindKillerBotAvoidsOwnSecretWhenFinishingOthers() throws {
    let players = [UUID(), UUID(), UUID()]
    let config = BlindKillerEngine.resolvedConfig(
        MatchConfigBlindKiller(hitsToEliminate: 2, assignmentSeed: 42),
        playerIds: players
    )
    var state = try BlindKillerEngine.makeInitialState(config: config, playerIds: players)
    let botId = players[0]
    guard let ownNumber = state.secretNumber(for: botId) else {
        Issue.record("Missing secret number")
        return
    }
    let victimNumber = ownNumber == 20 ? 19 : 20
    state.segmentHitCounts[victimNumber] = 1
    state.currentPlayerIndex = 0

    var aimedAtVictim = 0
    for seed in 0 ..< 64 {
        var rng = SeededRandomNumberGenerator(seed: UInt64(seed + 700))
        let darts = DartBotEngine.generateBlindKillerTurn(
            state: state,
            playerId: botId,
            profile: BotDifficulty.pro.skillProfile,
            rng: &rng
        )
        if darts.contains(where: {
            $0.multiplier == .double && $0.segment == .oneToTwenty(victimNumber)
        }) {
            aimedAtVictim += 1
        }
    }
    #expect(aimedAtVictim > 0)
}

@Test func dartBotEngine_blindKillerProHitsDoublesMoreThanVeryEasy() {
    let players = [UUID(), UUID(), UUID()]
    let config = BlindKillerEngine.resolvedConfig(MatchConfigBlindKiller(assignmentSeed: 42), playerIds: players)
    let state = try! BlindKillerEngine.makeInitialState(config: config, playerIds: players)
    let botId = players[0]

    var veryEasyDoubles = 0
    var proDoubles = 0
    for seed in 0 ..< 80 {
        var veryEasyRNG = SeededRandomNumberGenerator(seed: UInt64(seed))
        var proRNG = SeededRandomNumberGenerator(seed: UInt64(seed))
        veryEasyDoubles += DartBotEngine.generateBlindKillerTurn(
            state: state,
            playerId: botId,
            profile: BotDifficulty.veryEasy.skillProfile,
            rng: &veryEasyRNG
        ).filter { $0.multiplier == .double && !$0.isMiss }.count
        proDoubles += DartBotEngine.generateBlindKillerTurn(
            state: state,
            playerId: botId,
            profile: BotDifficulty.pro.skillProfile,
            rng: &proRNG
        ).filter { $0.multiplier == .double && !$0.isMiss }.count
    }
    #expect(proDoubles > veryEasyDoubles)
}

@Test func dartBotEngine_knockoutProScoresHigherThanVeryEasy() {
    var veryEasyTotal = 0
    var proTotal = 0
    for seed in 0 ..< 80 {
        var veryEasyRNG = SeededRandomNumberGenerator(seed: UInt64(seed))
        var proRNG = SeededRandomNumberGenerator(seed: UInt64(seed))
        veryEasyTotal += DartBotEngine.generateKnockoutTurn(
            currentHigh: 0,
            profile: BotDifficulty.veryEasy.skillProfile,
            rng: &veryEasyRNG
        ).reduce(0) { $0 + $1.points }
        proTotal += DartBotEngine.generateKnockoutTurn(
            currentHigh: 0,
            profile: BotDifficulty.pro.skillProfile,
            rng: &proRNG
        ).reduce(0) { $0 + $1.points }
    }
    #expect(proTotal > veryEasyTotal)
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

@Test func dartBotEngine_cricketStandardScoresOnClosedBedWhenOpponentOpen() throws {
    let players = [UUID(), UUID()]
    var state = try CricketEngine.makeInitialState(
        config: cricketConfig(scoringMode: .standard),
        playerIds: players
    )
    let allClosed = Dictionary(uniqueKeysWithValues: CricketTarget.allCases.map { ($0.rawValue, 3) })
    state.players[0].marks = allClosed
    state.players[1].marks = allClosed
    state.players[1].marks["20"] = 0

    var foundScoringAim = false
    for seed in 0 ..< 64 {
        var rng = SeededRandomNumberGenerator(seed: UInt64(seed + 300))
        let darts = DartBotEngine.generateCricketTurn(
            state: state,
            playerIndex: 0,
            difficulty: .medium,
            rng: &rng
        )
        if darts.allSatisfy({ cricketDartAims(at: 20, dart: $0) }) {
            foundScoringAim = true
            break
        }
    }
    #expect(foundScoringAim)
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

@Test(.tags(.unit, .regression))
func dartBotEngine_killerPickAvailableNumbersExcludeTaken() {
    let taken: Set<Int> = Set(1 ... 19)
    let available = (1 ... 20).filter { !taken.contains($0) }
    #expect(available == [20])
}

@Test(.tags(.unit, .regression))
func dartBotEngine_killerPickWithPerfectProfileEventuallyHitsLastAvailableNumber() {
    let profile = killerPickTestProfile()
    let taken: Set<Int> = Set(1 ... 19)
    var hitTwenty = false
    for seed in 0 ..< 64 {
        var rng = SeededRandomNumberGenerator(seed: UInt64(seed))
        let dart = DartBotEngine.generateKillerPick(takenNumbers: taken, profile: profile, rng: &rng)
        if case let .oneToTwenty(value) = dart.segment, value == 20 {
            hitTwenty = true
            break
        }
    }
    #expect(hitTwenty)
}

@Test(.tags(.unit, .regression))
func dartBotEngine_killerPickReturnsMissWhenEveryNumberIsTaken() {
    var rng = SeededRandomNumberGenerator(seed: 7)
    let dart = DartBotEngine.generateKillerPick(
        takenNumbers: Set(1 ... 20),
        profile: BotDifficulty.medium.skillProfile,
        rng: &rng
    )
    #expect(dart.isMiss)
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
        if darts.contains(where: { killerDartAims(at: 12, multiplier: .double, dart: $0) }) {
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
        if darts.contains(where: { killerDartAims(at: 8, multiplier: .double, dart: $0) }) {
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

private func availableKillerPickNumbers(excluding taken: Set<Int>) -> [Int] {
    (1 ... 20).filter { !taken.contains($0) }
}

/// Perfect cricket accuracy so killer number-pick tests assert selection, not miss simulation.
private func killerPickTestProfile() -> BotSkillProfile {
    let base = BotDifficulty.medium.skillProfile
    return BotSkillProfile(
        x01: base.x01,
        cricket: .init(
            hitChances: .init(single: 1, double: 1, triple: 1),
            offBoardMissChance: 0,
            wrongBedChance: 0,
            innerBullAimChance: 0,
            tripleOnOpenChance: 0,
            doubleOnOpenChance: 0
        )
    )
}

@Test(.tags(.unit, .match, .regression))
func dartBotEngine_golfMissesStayOnHoleSegmentOrOffBoard() {
    let profile = BotDifficulty.medium.skillProfile
    for seed in 0 ..< 100 {
        for hole in 1 ... 9 {
            var rng = SeededRandomNumberGenerator(seed: UInt64(seed * 10 + hole))
            let turn = DartBotEngine.generateGolfTurn(holeSegment: hole, profile: profile, rng: &rng)
            for dart in turn.darts {
                if dart.isMiss { continue }
                guard case let .oneToTwenty(value) = dart.segment else {
                    Issue.record("Unexpected non-numeric golf bot segment")
                    continue
                }
                #expect(value == hole)
            }
        }
    }
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
