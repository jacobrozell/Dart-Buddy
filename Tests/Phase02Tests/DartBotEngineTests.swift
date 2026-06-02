import Foundation
import Testing
@testable import DartsScoreboard

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

@Test func dartBotEngine_cricketTargetsValidSegments() {
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
        #expect(dart.segment.cricketTargetRaw != nil || dart.segment == .innerBull || dart.segment == .outerBull)
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
