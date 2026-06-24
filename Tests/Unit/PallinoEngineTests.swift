import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func single(_ n: Int) -> DartInput {
    DartInput(multiplier: .single, segment: .oneToTwenty(n))
}

private func double(_ n: Int) -> DartInput {
    DartInput(multiplier: .double, segment: .oneToTwenty(n))
}

private func triple(_ n: Int) -> DartInput {
    DartInput(multiplier: .triple, segment: .oneToTwenty(n))
}

private func miss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

// MARK: - Setup

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pallinoRequiresTwoToFourPlayers() {
    #expect(throws: AppError.self) {
        _ = try PallinoEngine.makeInitialState(
            config: MatchConfigPallino(),
            playerIds: [UUID()]
        )
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pallinoRejectsUnsupportedRoundsToWin() {
    #expect(throws: AppError.self) {
        _ = try PallinoEngine.makeInitialState(
            config: MatchConfigPallino(roundsToWin: 12),
            playerIds: [UUID(), UUID()]
        )
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pallinoInitialStateAwaitsPallino() throws {
    let state = try PallinoEngine.makeInitialState(
        config: MatchConfigPallino(),
        playerIds: [UUID(), UUID()]
    )
    #expect(state.phase == .awaitingPallino)
    #expect(state.roundIndex == 0)
    #expect(state.roundWins.values.allSatisfy { $0 == 0 })
}

// MARK: - Distance scoring

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pallinoExactHitScoresOneHundred() {
    let pallino = PallinoTarget(segment: 20, ring: .triple)
    let (score, exact) = PallinoEngine.distanceScore(dart: triple(20), pallino: pallino)
    #expect(score == 100)
    #expect(exact)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pallinoSameSegmentAdjacentRingScoresSeventy() {
    let pallino = PallinoTarget(segment: 20, ring: .triple)
    let (score, exact) = PallinoEngine.distanceScore(dart: double(20), pallino: pallino)
    #expect(score == 70)
    #expect(!exact)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pallinoSameSegmentNonAdjacentRingScoresForty() {
    // Pallino T20, dart S20: T↔S are not wire-adjacent (D between them).
    let pallino = PallinoTarget(segment: 20, ring: .triple)
    let (score, _) = PallinoEngine.distanceScore(dart: single(20), pallino: pallino)
    #expect(score == 40)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pallinoAdjacentSegmentSameRingScoresFifty() {
    let pallino = PallinoTarget(segment: 20, ring: .triple)
    let (clockwise, _) = PallinoEngine.distanceScore(dart: triple(1), pallino: pallino)
    let (counter, _) = PallinoEngine.distanceScore(dart: triple(19), pallino: pallino)
    #expect(clockwise == 50)
    #expect(counter == 50)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pallinoMissOrUnrelatedScoresZero() {
    let pallino = PallinoTarget(segment: 20, ring: .triple)
    #expect(PallinoEngine.distanceScore(dart: miss(), pallino: pallino).score == 0)
    #expect(PallinoEngine.distanceScore(dart: triple(10), pallino: pallino).score == 0)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pallinoSegmentAdjacencyWraps() {
    #expect(PallinoEngine.isAdjacentSegment(20, 1))
    #expect(PallinoEngine.isAdjacentSegment(1, 20))
    #expect(PallinoEngine.isAdjacentSegment(7, 8))
    #expect(!PallinoEngine.isAdjacentSegment(10, 12))
    #expect(!PallinoEngine.isAdjacentSegment(5, 5))
}

// MARK: - Round flow

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pallinoSubmitDartBeforePallinoThrows() throws {
    let state = try PallinoEngine.makeInitialState(
        config: MatchConfigPallino(),
        playerIds: [UUID(), UUID()]
    )
    #expect(throws: AppError.self) {
        _ = try PallinoEngine.submitDart(state: state, dart: triple(20))
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pallinoRotatesPlayersOneDartAtATime() throws {
    let a = UUID(); let b = UUID()
    var state = try PallinoEngine.makeInitialState(
        config: MatchConfigPallino(),
        playerIds: [a, b]
    )
    state = try PallinoEngine.setPallino(
        state: state,
        pallino: PallinoTarget(segment: 20, ring: .triple)
    )
    #expect(state.currentPlayerId == a)
    state = try PallinoEngine.submitDart(state: state, dart: miss()).updatedState
    #expect(state.currentPlayerId == b)
    state = try PallinoEngine.submitDart(state: state, dart: miss()).updatedState
    #expect(state.currentPlayerId == a)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pallinoBestStoneWinsRound() throws {
    let a = UUID(); let b = UUID()
    var state = try PallinoEngine.makeInitialState(
        config: MatchConfigPallino(roundsToWin: 7, kissEnabled: false),
        playerIds: [a, b]
    )
    state = try PallinoEngine.setPallino(
        state: state,
        pallino: PallinoTarget(segment: 20, ring: .triple)
    )
    // Order: a, b, a, b, a, b.
    let darts: [DartInput] = [
        triple(19),  // a — 50 (adj segment same ring)
        single(20),  // b — 40 (same segment non-adj ring)
        double(20),  // a — 70 (same segment adj ring)
        miss(),      // b — 0
        miss(),      // a — 0
        triple(1),   // b — 50 (adj segment same ring)
    ]
    var lastEvent: PallinoRoundEvent?
    for dart in darts {
        let outcome = try PallinoEngine.submitDart(state: state, dart: dart)
        state = outcome.updatedState
        lastEvent = outcome.roundEvent ?? lastEvent
    }
    // a's best = 70, b's best = 50.
    #expect(lastEvent?.winnerPlayerId == a)
    #expect(state.roundWins[a] == 1)
    #expect(state.roundWins[b] == 0)
    #expect(state.phase == .awaitingPallino)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pallinoTieMarksNoWinnerThatRound() throws {
    let a = UUID(); let b = UUID()
    var state = try PallinoEngine.makeInitialState(
        config: MatchConfigPallino(kissEnabled: false),
        playerIds: [a, b]
    )
    state = try PallinoEngine.setPallino(
        state: state,
        pallino: PallinoTarget(segment: 20, ring: .triple)
    )
    let darts: [DartInput] = [
        double(20),  // a — 70
        double(20),  // b — 70
        miss(), miss(), miss(), miss(),
    ]
    var lastEvent: PallinoRoundEvent?
    for dart in darts {
        let outcome = try PallinoEngine.submitDart(state: state, dart: dart)
        state = outcome.updatedState
        lastEvent = outcome.roundEvent ?? lastEvent
    }
    #expect(lastEvent?.isTie == true)
    #expect(lastEvent?.winnerPlayerId == nil)
    #expect(state.roundWins[a] == 0)
    #expect(state.roundWins[b] == 0)
}

// MARK: - Kiss

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pallinoKissRemovesOpponentBestStone() throws {
    let a = UUID(); let b = UUID()
    var state = try PallinoEngine.makeInitialState(
        config: MatchConfigPallino(kissEnabled: true),
        playerIds: [a, b]
    )
    state = try PallinoEngine.setPallino(
        state: state,
        pallino: PallinoTarget(segment: 20, ring: .triple)
    )
    // a throws a strong stone (70), b throws weak (40), a throws exact → kiss removes b's 40,
    // remaining b throws miss(0), miss(0), miss(0).
    // Without kiss: a best=100, b best=40. With kiss: b's 40 is removed; b best=0 (or nil).
    let darts: [DartInput] = [
        double(20),    // a — 70
        single(20),    // b — 40
        triple(20),    // a — 100 EXACT, kisses b's 40
        miss(),        // b — 0
        miss(),        // a — 0
        miss(),        // b — 0
    ]
    var lastEvent: PallinoRoundEvent?
    for dart in darts {
        let outcome = try PallinoEngine.submitDart(state: state, dart: dart)
        state = outcome.updatedState
        lastEvent = outcome.roundEvent ?? lastEvent
    }
    #expect(lastEvent?.kissCount == 1)
    #expect(lastEvent?.winnerPlayerId == a)
    // b should have only stones with score 0 in the recorded set.
    let bStones = lastEvent?.stones.filter { $0.playerId == b } ?? []
    #expect(bStones.allSatisfy { $0.distanceScore == 0 })
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pallinoKissDisabledLeavesOpponentStone() throws {
    let a = UUID(); let b = UUID()
    var state = try PallinoEngine.makeInitialState(
        config: MatchConfigPallino(kissEnabled: false),
        playerIds: [a, b]
    )
    state = try PallinoEngine.setPallino(
        state: state,
        pallino: PallinoTarget(segment: 20, ring: .triple)
    )
    let darts: [DartInput] = [
        single(20),    // a — 40
        single(20),    // b — 40
        triple(20),    // a — 100 (no kiss)
        miss(), miss(), miss(),
    ]
    var lastEvent: PallinoRoundEvent?
    for dart in darts {
        let outcome = try PallinoEngine.submitDart(state: state, dart: dart)
        state = outcome.updatedState
        lastEvent = outcome.roundEvent ?? lastEvent
    }
    let bStonesNonZero = lastEvent?.stones.filter { $0.playerId == b && $0.distanceScore > 0 }.count ?? 0
    #expect(bStonesNonZero == 1)
}

// MARK: - Match completion

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pallinoMatchEndsAtRoundsToWin() throws {
    let a = UUID(); let b = UUID()
    var state = try PallinoEngine.makeInitialState(
        config: MatchConfigPallino(roundsToWin: 7, kissEnabled: false),
        playerIds: [a, b]
    )
    for _ in 0 ..< 7 {
        state = try PallinoEngine.setPallino(
            state: state,
            pallino: PallinoTarget(segment: 20, ring: .triple)
        )
        // a hits T20 (100), b misses three times.
        let darts: [DartInput] = [triple(20), miss(), miss(), miss(), miss(), miss()]
        for dart in darts {
            state = try PallinoEngine.submitDart(state: state, dart: dart).updatedState
            if state.isComplete { break }
        }
        if state.isComplete { break }
    }
    #expect(state.isComplete)
    #expect(state.winnerPlayerId == a)
    #expect(state.roundWins[a] == 7)
}
