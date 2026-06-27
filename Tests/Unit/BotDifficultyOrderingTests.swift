import Foundation
import Testing
@testable import DartBuddy

/// Guards monotonic skill separation across preset tiers for every shipped bot mode.
///
/// Each test compares paired difficulties with identical RNG seeds so differences
/// come from profile tables and tier heuristics, not luck-of-the-draw ordering.
@Suite("Bot difficulty ordering", .tags(.unit, .regression))
struct BotDifficultyOrderingTests {
    @Test func suddenDeath_adjacentTiersIncreaseVisitPoints() {
        expectBotDifficultyMonotonicIncrease("Sudden Death") { profile, rng in
            DartBotEngine.generateSuddenDeathTurn(profile: profile, rng: &rng)
                .reduce(0) { $0 + $1.points }
        }
    }

    @Test func aroundTheClock_adjacentTiersAdvanceFurther() {
        expectBotDifficultyMonotonicIncrease("Around the Clock") { profile, rng in
            return countATCProgress(
                darts: DartBotEngine.generateAroundTheClockTurn(
                    targetIndex: 0,
                    includeBullFinish: false,
                    profile: profile,
                    rng: &rng
                ),
                startIndex: 0
            )
        }
    }

    @Test func aroundTheClock180_adjacentTiersScoreMoreOnTrebleBed() {
        expectBotDifficultyMonotonicIncrease("Around the Clock 180") { profile, rng in
            atc180Points(
                for: DartBotEngine.generateAroundTheClock180Turn(
                    targetSegment: 20,
                    profile: profile,
                    rng: &rng
                ),
                target: 20
            )
        }
    }

    @Test func grandNational_adjacentTiersHitHurdleMoreOften() {
        expectBotDifficultyMonotonicIncrease("Grand National") { profile, rng in
            DartBotEngine.generateGrandNationalTurn(
                currentHurdle: 12,
                profile: profile,
                rng: &rng
            ).filter {
                !$0.isMiss && $0.segment == .oneToTwenty(12)
            }.count
        }
    }

    @Test func nineLives_adjacentTiersAdvanceFurther() {
        expectBotDifficultyMonotonicIncrease("Nine Lives") { profile, rng in
            return countATCProgress(
                darts: DartBotEngine.generateNineLivesTurn(
                    targetIndex: 0,
                    profile: profile,
                    rng: &rng
                ),
                startIndex: 0
            )
        }
    }

    @Test func hareAndHounds_adjacentTiersAdvanceFurther() {
        expectBotDifficultyMonotonicIncrease("Hare and Hounds") { profile, rng in
            countHareProgress(
                darts: DartBotEngine.generateHareAndHoundsTurn(
                    positionIndex: 0,
                    profile: profile,
                    rng: &rng
                ),
                startIndex: 0
            )
        }
    }

    @Test func chaseTheDragon_adjacentTiersAdvanceMoreSteps() {
        expectBotDifficultyMonotonicIncrease("Chase the Dragon") { profile, rng in
            countDragonProgress(
                darts: DartBotEngine.generateChaseTheDragonTurn(
                    stepIndex: 0,
                    lapsCompleted: 0,
                    lapsNeeded: 1,
                    profile: profile,
                    rng: &rng
                ),
                startStepIndex: 0
            )
        }
    }

    @Test func knockout_adjacentTiersScoreHigherVisits() {
        expectBotDifficultyMonotonicIncrease("Knockout") { profile, rng in
            DartBotEngine.generateKnockoutTurn(
                currentHigh: 0,
                profile: profile,
                rng: &rng
            ).reduce(0) { $0 + $1.points }
        }
    }

    @Test func fiftyOneByFives_adjacentTiersHitTargetMore() throws {
        let players = [UUID(), UUID()]
        let state = try FiftyOneByFivesEngine.makeInitialState(
            config: MatchConfigFiftyOneByFives(),
            playerIds: players
        )
        _ = state
        expectBotDifficultyMonotonicIncrease("51×5") { profile, rng in
            let darts = DartBotEngine.generateFiftyOneByFivesTurn(
                state: state,
                playerIndex: 0,
                profile: profile,
                rng: &rng
            )
            return darts.filter { !$0.isMiss && $0.segment == .oneToTwenty(20) }.count
        }
    }

    @Test func mickeyMouse_adjacentTiersCloseTargetFaster() {
        expectBotDifficultyMonotonicIncrease("Mickey Mouse") { profile, rng in
            DartBotEngine.generateMickeyMouseTurn(
                activeTarget: .number(20),
                marksAlreadyOnTarget: 0,
                profile: profile,
                rng: &rng
            ).reduce(0) {
                $0 + MickeyMouseEngine.marksForTarget(dart: $1, activeTarget: .number(20))
            }
        }
    }

    @Test func mulligan_adjacentTiersCloseTargetFaster() {
        expectBotDifficultyMonotonicIncrease("Mulligan") { profile, rng in
            let darts = DartBotEngine.generateMulliganTurn(
                activeTarget: .number(20),
                marksAlreadyOnTarget: 0,
                profile: profile,
                rng: &rng
            )
            return darts.reduce(0) { total, dart in
                guard !dart.isMiss,
                      case let .oneToTwenty(value) = dart.segment,
                      value == 20 else { return total }
                return total + dart.multiplier.markValue
            }
        }
    }

    @Test func americanCricket_adjacentTiersAddMoreMarks() throws {
        let players = [UUID(), UUID()]
        let state = try AmericanCricketEngine.makeInitialState(
            config: MatchConfigAmericanCricket(),
            playerIds: players
        )
        expectBotDifficultyMonotonicIncrease("American Cricket") { profile, rng in
            DartBotEngine.generateAmericanCricketTurn(
                state: state,
                playerIndex: 0,
                profile: profile,
                rng: &rng
            ).reduce(0) { total, dart in
                total + americanCricketMarksContributed(from: dart, target: state.activeTarget)
            }
        }
    }

    @Test func englishCricketBatter_adjacentTiersScoreHigher() {
        expectBotDifficultyMonotonicIncrease("English Cricket batter") { profile, rng in
            DartBotEngine.generateEnglishCricketTurn(
                role: .batter,
                profile: profile,
                rng: &rng
            ).reduce(0) { $0 + $1.points }
        }
    }

    @Test func englishCricketBowler_adjacentTiersHitBullMore() {
        expectBotDifficultyMonotonicIncrease("English Cricket bowler") { profile, rng in
            DartBotEngine.generateEnglishCricketTurn(
                role: .bowler,
                profile: profile,
                rng: &rng
            ).filter { !$0.isMiss && ($0.segment == .innerBull || $0.segment == .outerBull) }.count
        }
    }

    @Test func football_adjacentTiersScoreMoreGoalsAfterKickoff() {
        let player = FootballPlayerState(playerId: UUID(), kickoffComplete: true)
        let config = MatchConfigFootball()
        expectBotDifficultyMonotonicIncrease("Football") { profile, rng in
            DartBotEngine.generateFootballTurn(
                playerState: player,
                config: config,
                profile: profile,
                rng: &rng
            ).filter { FootballEngine.isGoal($0) }.count
        }
    }

    @Test func fleet_adjacentTiersHitCalledSegmentMore() {
        expectBotDifficultyMonotonicIncrease("Fleet") { profile, rng in
            fleetHitOnCall(
                DartBotEngine.generateFleetHuntDart(
                    callCell: .segment(20),
                    profile: profile,
                    callMode: .strict,
                    rng: &rng
                ),
                segment: 20
            )
        }
    }

    @Test func golf_adjacentTiersUseFewerStrokes() {
        for (lower, upper) in botDifficultyAdjacentPairs {
            var lowerStrokes = 0
            var upperStrokes = 0
            for seed in 0 ..< botDifficultySampleCount {
                for hole in 1 ... 9 {
                    var lowerRNG = SeededRandomNumberGenerator(seed: UInt64(seed * 10 + hole))
                    var upperRNG = SeededRandomNumberGenerator(seed: UInt64(seed * 10 + hole))
                    lowerStrokes += golfStrokes(
                        for: DartBotEngine.generateGolfTurn(
                            holeSegment: hole,
                            profile: lower.skillProfile,
                            rng: &lowerRNG
                        ),
                        holeSegment: hole
                    )
                    upperStrokes += golfStrokes(
                        for: DartBotEngine.generateGolfTurn(
                            holeSegment: hole,
                            profile: upper.skillProfile,
                            rng: &upperRNG
                        ),
                        holeSegment: hole
                    )
                }
            }
            #expect(
                upperStrokes < lowerStrokes,
                "Golf: \(upper.displayName) should use fewer strokes than \(lower.displayName)"
            )
        }
    }

    @Test func loop_proMatchesLeaderMoreThanVeryEasy() throws {
        let players = [UUID(), UUID()]
        var state = try LoopEngine.makeInitialState(
            config: MatchConfigLoop(),
            playerIds: players
        )
        let opening = LoopSubmittedDart(
            dart: DartInput(multiplier: .double, segment: .oneToTwenty(16)),
            wireTarget: LoopWireTargetArea(segment: 16, kind: .standard, ring: .double)
        )
        state = try LoopEngine.submitVisit(state: state, darts: [opening]).updatedState

        let (veryEasy, pro) = compareBotDifficultyTotals(lower: .veryEasy, upper: .pro) { profile, rng in
            DartBotEngine.generateLoopVisit(state: state, profile: profile, rng: &rng)
                .filter { $0.wireTarget == state.target }.count
        }
        #expect(pro > veryEasy, "Loop: Pro should match the leader target more often than Very Easy")
    }

    @Test func followTheLeader_adjacentTiersMatchLeaderMore() throws {
        let players = [UUID(), UUID()]
        var state = try FollowTheLeaderEngine.makeInitialState(
            config: MatchConfigFollowTheLeader(),
            playerIds: players
        )
        state = try FollowTheLeaderEngine.submitVisit(
            state: state,
            darts: [DartInput(multiplier: .double, segment: .oneToTwenty(18))]
        ).updatedState

        expectBotDifficultyMonotonicIncrease("Follow the Leader") { profile, rng in
            guard let target = state.target else { return 0 }
            return DartBotEngine.generateFollowTheLeaderVisit(state: state, profile: profile, rng: &rng)
                .filter { FollowTheLeaderEngine.dartMatchesTarget($0, target: target) }.count
        }
    }

    @Test func blindKiller_adjacentTiersLandMoreDoubles() throws {
        let players = [UUID(), UUID(), UUID()]
        let config = BlindKillerEngine.resolvedConfig(
            MatchConfigBlindKiller(assignmentSeed: 99),
            playerIds: players
        )
        let state = try BlindKillerEngine.makeInitialState(config: config, playerIds: players)

        expectBotDifficultyMonotonicIncrease("Blind Killer") { profile, rng in
            DartBotEngine.generateBlindKillerTurn(
                state: state,
                playerId: players[0],
                profile: profile,
                rng: &rng
            ).filter { $0.multiplier == .double && !$0.isMiss }.count
        }
    }

    @Test func bobs27_adjacentTiersHitRoundDoubleMore() {
        expectBotDifficultyMonotonicIncrease("Bob's 27") { profile, rng in
            DartBotEngine.generateBobs27Turn(
                target: .double(15),
                profile: profile,
                rng: &rng
            ).filter {
                $0.multiplier == .double && !$0.isMiss && $0.segment == .oneToTwenty(15)
            }.count
        }
    }

    @Test func scamScorer_adjacentTiersScoreMoreOnTarget() throws {
        expectBotDifficultyMonotonicIncrease("Scam scorer") { profile, rng in
            let darts = DartBotEngine.generateScamScorerTurn(
                targetSegment: 17,
                profile: profile,
                rng: &rng
            )
            return darts.reduce(0) { total, dart in
                total + ScamEngine.scorerPoints(dart: dart, target: 17)
            }
        }
    }

    @Test func halveIt_adjacentTiersScoreMoreOnTarget() {
        expectBotDifficultyMonotonicIncrease("Halve-It") { profile, rng in
            DartBotEngine.generateHalveItTurn(
                targetSegment: 16,
                profile: profile,
                rng: &rng
            ).reduce(0) { $0 + HalveItEngine.scoreContribution($1, target: 16) }
        }
    }

    @Test func snooker_adjacentTiersPotMoreReds() throws {
        var state = try SnookerEngine.makeInitialState(
            config: MatchConfigSnooker(),
            playerIds: [UUID(), UUID()]
        )
        state.availableReds = Set(1 ... 15)

        expectBotDifficultyMonotonicIncrease("Snooker") { profile, rng in
            let dart = DartBotEngine.generateSnookerDart(
                state: state,
                profile: profile,
                nominatedColour: nil,
                rng: &rng
            )
            guard case let .oneToTwenty(value) = dart.segment, !dart.isMiss else { return 0 }
            return state.availableReds.contains(value) ? 1 : 0
        }
    }

    @Test func ticTacToe_adjacentTiersHitCellTargetsMore() throws {
        var state = try TicTacToeEngine.makeInitialState(
            config: MatchConfigTicTacToe(),
            playerIds: [UUID(), UUID()]
        )
        expectBotDifficultyMonotonicIncrease("Tic-Tac-Toe") { profile, rng in
            DartBotEngine.generateTicTacToeTurn(
                state: state,
                profile: profile,
                rng: &rng
            ).filter { dart in
                state.config.cells.contains { $0.matches(dart) }
            }.count
        }
    }

    @Test func prisoner_adjacentTiersAdvanceSequenceFurther() throws {
        let players = [UUID(), UUID()]
        let state = try PrisonerEngine.makeInitialState(
            config: MatchConfigPrisoner(),
            playerIds: players
        )

        expectBotDifficultyMonotonicIncrease("Prisoner") { profile, rng in
            let hits = DartBotEngine.generatePrisonerVisit(
                state: state,
                profile: profile,
                rng: &rng
            )
            let sequence = MatchConfigPrisoner.clockwiseSequence
            var progress = state.currentPlayer.progressIndex
            var advanced = 0
            for hit in hits {
                guard progress < sequence.count else { break }
                let target = sequence[progress]
                if case let .playable(segment) = hit, segment == target {
                    progress += 1
                    advanced += 1
                }
            }
            return advanced
        }
    }

    @Test func cricket_adjacentTiersAddMoreMarks() throws {
        let players = [UUID(), UUID()]
        let state = try CricketEngine.makeInitialState(
            config: MatchConfigCricket(),
            playerIds: players
        )
        expectBotDifficultyMonotonicIncrease("Cricket") { profile, rng in
            DartBotEngine.generateCricketTurn(
                state: state,
                playerIndex: 0,
                profile: profile,
                rng: &rng
            ).reduce(0) { $0 + cricketMarksContributed(from: $1) }
        }
    }

    @Test func killer_adjacentTiersHitOwnDoubleMore() throws {
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

        expectBotDifficultyMonotonicIncrease("Killer") { profile, rng in
            DartBotEngine.generateKillerTurn(
                state: state,
                throwerIndex: 0,
                profile: profile,
                rng: &rng
            ).filter {
                !$0.isMiss && $0.multiplier == .double && $0.segment == .oneToTwenty(12)
            }.count
        }
    }

    @Test func baseball_adjacentTiersScoreMoreRuns() {
        expectBotDifficultyMonotonicIncrease("Baseball") { profile, rng in
            DartBotEngine.generateBaseballTurn(
                targetSegment: 5,
                phase: .innings,
                stretchGateOpen: true,
                seventhInningStretch: false,
                profile: profile,
                rng: &rng
            ).reduce(0) { total, dart in
                guard !dart.isMiss, case let .oneToTwenty(value) = dart.segment, value == 5 else {
                    return total
                }
                return total + dart.multiplier.markValue
            }
        }
    }

    @Test func shanghai_adjacentTiersScoreMoreMarks() {
        expectBotDifficultyMonotonicIncrease("Shanghai") { profile, rng in
            DartBotEngine.generateShanghaiTurn(
                targetSegment: 5,
                profile: profile,
                rng: &rng
            ).reduce(0) { total, dart in
                guard !dart.isMiss, case let .oneToTwenty(value) = dart.segment, value == 5 else {
                    return total
                }
                return total + dart.multiplier.markValue
            }
        }
    }

    @Test func presetTiers_veryEasyAlwaysBelowProAcrossCoreModes() {
        let pairs: [(String, (BotSkillProfile, inout SeededRandomNumberGenerator) -> Int)] = [
            ("X01", { profile, rng in
                DartBotEngine.generateX01Turn(
                    remaining: 501,
                    profile: profile,
                    checkoutMode: .doubleOut,
                    checkInMode: .straightIn,
                    isCheckedIn: true,
                    rng: &rng
                ).reduce(0) { $0 + $1.points }
            }),
            ("Sudden Death", { profile, rng in
                DartBotEngine.generateSuddenDeathTurn(profile: profile, rng: &rng)
                    .reduce(0) { $0 + $1.points }
            }),
            ("Knockout", { profile, rng in
                DartBotEngine.generateKnockoutTurn(currentHigh: 0, profile: profile, rng: &rng)
                    .reduce(0) { $0 + $1.points }
            }),
        ]

        for (name, metric) in pairs {
            let (veryEasy, pro) = compareBotDifficultyTotals(lower: .veryEasy, upper: .pro, metric: metric)
            #expect(pro > veryEasy, "\(name): Pro should beat Very Easy (\(pro) vs \(veryEasy))")
        }
    }
}

// MARK: - Helpers

private let botDifficultyAdjacentPairs: [(BotDifficulty, BotDifficulty)] = [
    (.veryEasy, .easy),
    (.easy, .medium),
    (.medium, .hard),
    (.hard, .pro),
]

private let botDifficultySampleCount = 60

private func compareBotDifficultyTotals(
    lower: BotDifficulty,
    upper: BotDifficulty,
    samples: Int = botDifficultySampleCount,
    metric: (BotSkillProfile, inout SeededRandomNumberGenerator) -> Int
) -> (Int, Int) {
    var lowerTotal = 0
    var upperTotal = 0
    for seed in 0 ..< samples {
        var lowerRNG = SeededRandomNumberGenerator(seed: UInt64(seed))
        var upperRNG = SeededRandomNumberGenerator(seed: UInt64(seed))
        lowerTotal += metric(lower.skillProfile, &lowerRNG)
        upperTotal += metric(upper.skillProfile, &upperRNG)
    }
    return (lowerTotal, upperTotal)
}

private func expectBotDifficultyMonotonicIncrease(
    _ name: String,
    metric: (BotSkillProfile, inout SeededRandomNumberGenerator) -> Int
) {
    for (lower, upper) in botDifficultyAdjacentPairs {
        let (lowerTotal, upperTotal) = compareBotDifficultyTotals(lower: lower, upper: upper, metric: metric)
        #expect(
            upperTotal > lowerTotal,
            "\(name): \(upper.displayName) should outperform \(lower.displayName) (\(upperTotal) vs \(lowerTotal))"
        )
    }
}

private func countATCProgress(darts: [DartInput], startIndex: Int) -> Int {
    var currentIndex = startIndex
    var progressed = 0
    for dart in darts {
        guard currentIndex < 20 else { break }
        let segmentValue = currentIndex + 1
        if case let .oneToTwenty(value) = dart.segment, value == segmentValue, !dart.isMiss {
            currentIndex += 1
            progressed += 1
        }
    }
    return progressed
}

private func countHareProgress(darts: [DartInput], startIndex: Int) -> Int {
    let course = MatchConfigHareAndHounds.clockwiseCourse
    var currentIndex = startIndex
    var progressed = 0
    for dart in darts {
        guard currentIndex < course.count else { break }
        let segmentValue = course[currentIndex]
        if case let .oneToTwenty(value) = dart.segment, value == segmentValue, !dart.isMiss {
            currentIndex += 1
            progressed += 1
        }
    }
    return progressed
}

private func countDragonProgress(darts: [DartInput], startStepIndex: Int) -> Int {
    var stepIndex = startStepIndex
    var progressed = 0
    for dart in darts {
        guard stepIndex < ChaseTheDragonEngine.dragonSequence.count else { break }
        if ChaseTheDragonEngine.dragonSequence[stepIndex].isQualifyingHit(dart) {
            stepIndex += 1
            progressed += 1
        }
    }
    return progressed
}

private func atc180Points(for darts: [DartInput], target: Int) -> Int {
    darts.reduce(0) { total, dart in
        guard !dart.isMiss, case let .oneToTwenty(value) = dart.segment, value == target else {
            return total
        }
        switch dart.multiplier {
        case .triple: return total + 3
        case .single, .double: return total + 1
        }
    }
}

private func fleetHitOnCall(_ dart: DartInput, segment: Int) -> Int {
    guard !dart.isMiss, case let .oneToTwenty(value) = dart.segment, value == segment else { return 0 }
    return 1
}

private func golfStrokes(for turn: GolfTurnInput, holeSegment: Int) -> Int {
    turn.darts.reduce(0) { $0 + GolfEngine.strokesForLastDart($1, holeSegment: holeSegment) }
}

private func americanCricketMarksContributed(from dart: DartInput, target: CricketTarget) -> Int {
    guard !dart.isMiss else { return 0 }
    switch target {
    case .bull:
        switch dart.segment {
        case .innerBull: return 2
        case .outerBull: return 1
        default: return 0
        }
    default:
        guard let value = Int(target.rawValue),
              case let .oneToTwenty(segment) = dart.segment,
              segment == value else { return 0 }
        return dart.multiplier.markValue
    }
}

private func cricketMarksContributed(from dart: DartInput) -> Int {
    guard !dart.isMiss else { return 0 }
    switch dart.segment {
    case .innerBull:
        return 2
    case .outerBull:
        return 1
    case let .oneToTwenty(value):
        guard CricketTarget.allCases.contains(where: { Int($0.rawValue) == value }) else { return 0 }
        return dart.multiplier.markValue
    case .miss:
        return 0
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
