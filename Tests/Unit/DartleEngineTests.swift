import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func hit(_ target: DartleTarget) -> DartInput {
    switch target {
    case let .segment(n):
        return DartInput(multiplier: .single, segment: .oneToTwenty(n))
    case .bull:
        return DartInput(multiplier: .double, segment: .innerBull)
    }
}

private func wrongSingle(_ n: Int) -> DartInput {
    DartInput(multiplier: .single, segment: .oneToTwenty(n))
}

private func miss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

private let testDate = DartlePuzzleDate(year: 2026, month: 6, day: 17)

// MARK: - Setup

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func dartleRequiresSinglePlayer() {
    #expect(throws: AppError.self) {
        _ = try DartleEngine.makeInitialState(
            config: MatchConfigDartle(puzzleDate: testDate),
            playerIds: []
        )
    }
    #expect(throws: AppError.self) {
        _ = try DartleEngine.makeInitialState(
            config: MatchConfigDartle(puzzleDate: testDate),
            playerIds: [UUID(), UUID()]
        )
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func dartleInitialStateBuildsSixCellGrid() throws {
    let state = try DartleEngine.makeInitialState(
        config: MatchConfigDartle(puzzleDate: testDate),
        playerIds: [UUID()]
    )
    #expect(state.sequence.count == 6)
    #expect(state.cells.count == 6)
    #expect(state.cells.allSatisfy { $0.attempts == 0 && $0.dartsToHit == nil })
    #expect(state.dartsUsed == 0)
    #expect(state.status == .inProgress)
}

// MARK: - Deterministic sequence

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func dartleSequenceIsDeterministicPerDate() {
    let a = DartleEngine.generateSequence(for: testDate)
    let b = DartleEngine.generateSequence(for: testDate)
    #expect(a == b)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func dartleSequenceDiffersAcrossDates() {
    let a = DartleEngine.generateSequence(for: DartlePuzzleDate(year: 2026, month: 6, day: 17))
    let b = DartleEngine.generateSequence(for: DartlePuzzleDate(year: 2026, month: 6, day: 18))
    #expect(a != b)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func dartleSequenceHasNoDuplicates() {
    // Probe several dates to ensure draw-without-replacement holds.
    let dates: [DartlePuzzleDate] = [
        DartlePuzzleDate(year: 2026, month: 1, day: 1),
        DartlePuzzleDate(year: 2026, month: 6, day: 17),
        DartlePuzzleDate(year: 2027, month: 12, day: 31),
        DartlePuzzleDate(year: 2025, month: 3, day: 14),
    ]
    for date in dates {
        let sequence = DartleEngine.generateSequence(for: date)
        let unique = Set(sequence)
        #expect(unique.count == sequence.count, "duplicate target for \(date)")
        #expect(sequence.count == 6)
    }
}

// MARK: - Hit / miss flow

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func dartleHitAdvancesAndRecordsDarts() throws {
    let state = try DartleEngine.makeInitialState(
        config: MatchConfigDartle(puzzleDate: testDate),
        playerIds: [UUID()]
    )
    let target = state.sequence[0]
    let outcome = try DartleEngine.submitDart(state: state, dart: hit(target))
    #expect(outcome.event.wasHit)
    #expect(outcome.event.currentIndexAfter == 1)
    #expect(outcome.updatedState.cells[0].dartsToHit == 1)
    #expect(outcome.updatedState.cells[0].attempts == 1)
    #expect(outcome.updatedState.currentIndex == 1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func dartleMissesAccumulateAttemptsWithoutAdvancing() throws {
    let state = try DartleEngine.makeInitialState(
        config: MatchConfigDartle(puzzleDate: testDate),
        playerIds: [UUID()]
    )
    let target = state.sequence[0]
    var updated = state
    for _ in 0 ..< 3 {
        let outcome = try DartleEngine.submitDart(state: updated, dart: miss())
        updated = outcome.updatedState
    }
    #expect(updated.currentIndex == 0)
    #expect(updated.dartsUsed == 3)
    #expect(updated.cells[0].attempts == 3)
    #expect(updated.cells[0].dartsToHit == nil)
    #expect(updated.status == .inProgress)
    _ = target  // keep compiler happy
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func dartleOnlyTargetSegmentCountsAsHit() throws {
    let state = try DartleEngine.makeInitialState(
        config: MatchConfigDartle(puzzleDate: testDate),
        playerIds: [UUID()]
    )
    let target = state.sequence[0]
    let wrong: Int = {
        if case let .segment(n) = target { return n == 1 ? 2 : 1 }
        return 1
    }()
    let outcome = try DartleEngine.submitDart(state: state, dart: wrongSingle(wrong))
    #expect(outcome.event.wasHit == false)
    #expect(outcome.updatedState.currentIndex == 0)
}

// MARK: - Completion

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func dartleSolvedAfterSixHits() throws {
    var state = try DartleEngine.makeInitialState(
        config: MatchConfigDartle(puzzleDate: testDate),
        playerIds: [UUID()]
    )
    for index in 0 ..< 6 {
        let target = state.sequence[index]
        let outcome = try DartleEngine.submitDart(state: state, dart: hit(target))
        state = outcome.updatedState
    }
    #expect(state.status == .solved)
    #expect(state.dartsUsed == 6)
    #expect(state.cells.allSatisfy { $0.dartsToHit == 1 })
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func dartleDnfAfterEighteenDartsWithoutSolving() throws {
    var state = try DartleEngine.makeInitialState(
        config: MatchConfigDartle(puzzleDate: testDate),
        playerIds: [UUID()]
    )
    for _ in 0 ..< MatchConfigDartle.dartCap {
        let outcome = try DartleEngine.submitDart(state: state, dart: miss())
        state = outcome.updatedState
    }
    #expect(state.status == .dnf)
    #expect(state.dartsUsed == 18)
    #expect(state.currentIndex == 0)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func dartleSubmitAfterTerminalStatusThrows() throws {
    var state = try DartleEngine.makeInitialState(
        config: MatchConfigDartle(puzzleDate: testDate),
        playerIds: [UUID()]
    )
    state.status = .dnf
    #expect(throws: AppError.self) {
        _ = try DartleEngine.submitDart(state: state, dart: miss())
    }
}

// MARK: - Replay

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func dartleReplayReconstructsState() throws {
    var state = try DartleEngine.makeInitialState(
        config: MatchConfigDartle(puzzleDate: testDate),
        playerIds: [UUID()]
    )
    var events: [DartleDartEvent] = []
    // Two misses, then hit each remaining target on the first try.
    for _ in 0 ..< 2 {
        let outcome = try DartleEngine.submitDart(state: state, dart: miss())
        state = outcome.updatedState
        events.append(outcome.event)
    }
    for index in 0 ..< 6 {
        let target = state.sequence[index]
        let outcome = try DartleEngine.submitDart(state: state, dart: hit(target))
        state = outcome.updatedState
        events.append(outcome.event)
    }
    let replayed = try DartleEngine.replay(
        config: MatchConfigDartle(puzzleDate: testDate),
        playerIds: [state.playerId],
        events: events
    )
    #expect(replayed.cells == state.cells)
    #expect(replayed.dartsUsed == state.dartsUsed)
    #expect(replayed.currentIndex == state.currentIndex)
    #expect(replayed.status == state.status)
}

// MARK: - PRNG

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func splitMix64ProducesStableSequence() {
    var rng = SplitMix64(state: 0)
    let first = rng.next()
    let second = rng.next()
    var rng2 = SplitMix64(state: 0)
    #expect(rng2.next() == first)
    #expect(rng2.next() == second)
}
