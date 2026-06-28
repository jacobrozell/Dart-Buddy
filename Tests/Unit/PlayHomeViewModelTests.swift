import Foundation
import Testing
@testable import DartBuddy

@MainActor
@Test(.tags(.integration, .navigation, .match, .smoke, .regression))
func playHomeShowsResumeWhenActiveMatchExists() async throws {
    let activeMatch = MatchSummary(
        id: UUID(),
        type: .x01,
        status: .inProgress,
        startedAt: Date(),
        endedAt: nil,
        winnerPlayerId: nil,
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: 0,
        createdAt: Date(),
        updatedAt: Date()
    )
    let vm = PlayHomeViewModel(
        playerRepository: FakePlayerRepository(players: [makePlayer("A"), makePlayer("B")]),
        matchRepository: FakeMatchRepositoryBuilder.withActiveMatch(activeMatch),
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink())
    )

    await vm.onAppear()

    switch vm.state {
    case let .readyWithActiveMatch(match):
        #expect(match.id == activeMatch.id)
    default:
        Issue.record("Expected resume state")
    }
}

@MainActor
@Test(.tags(.integration, .navigation, .smoke, .regression))
func playHomeDoesNotOfferAbandonedMatch() async {
    let vm = PlayHomeViewModel(
        playerRepository: FakePlayerRepository(players: [makePlayer("A"), makePlayer("B")]),
        matchRepository: FakeMatchRepositoryBuilder.withActiveMatch(nil),
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink())
    )

    await vm.onAppear()

    #expect(vm.state == .readyNoActiveMatch)
}

@MainActor
@Test(.tags(.integration, .navigation, .smoke, .regression))
func playHomeShowsNoActiveMatchWhenRosterExistsButNoActiveMatch() async {
    let vm = PlayHomeViewModel(
        playerRepository: FakePlayerRepository(players: [makePlayer("A"), makePlayer("B")]),
        matchRepository: FakeMatchRepositoryBuilder.withActiveMatch(nil),
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink())
    )

    await vm.onAppear()

    #expect(vm.state == .readyNoActiveMatch)
}

@MainActor
@Test(.tags(.integration, .navigation, .match, .regression))
func playHomeIgnoresActivePartyMatchWhenPartyHidden() async {
    guard !ProductSurface.showsPartyModes else { return }

    let activeMatch = MatchSummary(
        id: UUID(),
        type: .baseball,
        status: .inProgress,
        startedAt: Date(),
        endedAt: nil,
        winnerPlayerId: nil,
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: 0,
        createdAt: Date(),
        updatedAt: Date()
    )
    let vm = PlayHomeViewModel(
        playerRepository: FakePlayerRepository(players: [makePlayer("A"), makePlayer("B")]),
        matchRepository: FakeMatchRepositoryBuilder.withActiveMatch(activeMatch),
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink())
    )

    await vm.onAppear()

    #expect(vm.state == .readyNoActiveMatch)
}

@MainActor
@Test(.tags(.integration, .navigation, .match, .regression))
func playHomeIgnoresActiveGolfMatchWhenGolfNotReachable() async {
    guard ProductSurface.showsPartyModes, !ProductSurface.isFullProductSurfaceEnabled else { return }
    guard !ProductSurface.isMatchTypeReachable(.golf) else { return }

    let activeMatch = MatchSummary(
        id: UUID(),
        type: .golf,
        status: .inProgress,
        startedAt: Date(),
        endedAt: nil,
        winnerPlayerId: nil,
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: 0,
        createdAt: Date(),
        updatedAt: Date()
    )
    let vm = PlayHomeViewModel(
        playerRepository: FakePlayerRepository(players: [makePlayer("A"), makePlayer("B")]),
        matchRepository: FakeMatchRepositoryBuilder.withActiveMatch(activeMatch),
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink())
    )

    await vm.onAppear()

    #expect(vm.state == .readyNoActiveMatch)
}

@MainActor
@Test(.tags(.integration, .navigation, .match, .regression))
func playHomeShowsResumeForBaseballMatch() async throws {
    guard ProductSurface.showsPartyModes, !ProductSurface.isFullProductSurfaceEnabled else { return }

    let activeMatch = MatchSummary(
        id: UUID(),
        type: .baseball,
        status: .inProgress,
        startedAt: Date(),
        endedAt: nil,
        winnerPlayerId: nil,
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: 0,
        createdAt: Date(),
        updatedAt: Date()
    )
    let vm = PlayHomeViewModel(
        playerRepository: FakePlayerRepository(players: [makePlayer("A"), makePlayer("B")]),
        matchRepository: FakeMatchRepositoryBuilder.withActiveMatch(activeMatch),
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink())
    )

    await vm.onAppear()

    if case let .readyWithActiveMatch(match) = vm.state {
        #expect(match.type == .baseball)
    } else {
        Issue.record("Expected resume state for baseball match")
    }
}

@MainActor
@Test(.tags(.integration, .navigation, .match, .regression))
func playHomeShowsResumeForKillerMatch() async throws {
    guard ProductSurface.showsPartyModes, !ProductSurface.isFullProductSurfaceEnabled else { return }

    let activeMatch = MatchSummary(
        id: UUID(),
        type: .killer,
        status: .inProgress,
        startedAt: Date(),
        endedAt: nil,
        winnerPlayerId: nil,
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: 0,
        createdAt: Date(),
        updatedAt: Date()
    )
    let vm = PlayHomeViewModel(
        playerRepository: FakePlayerRepository(players: [makePlayer("A"), makePlayer("B"), makePlayer("C")]),
        matchRepository: FakeMatchRepositoryBuilder.withActiveMatch(activeMatch),
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink())
    )

    await vm.onAppear()

    if case let .readyWithActiveMatch(match) = vm.state {
        #expect(match.type == .killer)
    } else {
        Issue.record("Expected resume state for killer match")
    }
}

@MainActor
@Test(.tags(.integration, .navigation, .match, .regression))
func playHomeShowsResumeForShanghaiMatch() async throws {
    guard ProductSurface.showsPartyModes, !ProductSurface.isFullProductSurfaceEnabled else { return }

    let activeMatch = MatchSummary(
        id: UUID(),
        type: .shanghai,
        status: .inProgress,
        startedAt: Date(),
        endedAt: nil,
        winnerPlayerId: nil,
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: 0,
        createdAt: Date(),
        updatedAt: Date()
    )
    let vm = PlayHomeViewModel(
        playerRepository: FakePlayerRepository(players: [makePlayer("A"), makePlayer("B")]),
        matchRepository: FakeMatchRepositoryBuilder.withActiveMatch(activeMatch),
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink())
    )

    await vm.onAppear()

    if case let .readyWithActiveMatch(match) = vm.state {
        #expect(match.type == .shanghai)
    } else {
        Issue.record("Expected resume state for shanghai match")
    }
}

@MainActor
@Test(.tags(.integration, .navigation, .match, .regression))
func playHomeShowsResumeForAroundTheClockMatch() async throws {
    guard !ProductSurface.isFullProductSurfaceEnabled else { return }

    let activeMatch = MatchSummary(
        id: UUID(),
        type: .aroundTheClock,
        status: .inProgress,
        startedAt: Date(),
        endedAt: nil,
        winnerPlayerId: nil,
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: 0,
        createdAt: Date(),
        updatedAt: Date()
    )
    let vm = PlayHomeViewModel(
        playerRepository: FakePlayerRepository(players: [makePlayer("A")]),
        matchRepository: FakeMatchRepositoryBuilder.withActiveMatch(activeMatch),
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink())
    )

    await vm.onAppear()

    if case let .readyWithActiveMatch(match) = vm.state {
        #expect(match.type == .aroundTheClock)
    } else {
        Issue.record("Expected resume state for Around the Clock match")
    }
}

@MainActor
@Test(.tags(.integration, .navigation, .match, .regression))
func playHomeShowsResumeForCricketMatch() async throws {
    var session = try MatchLifecycleService.createMatch(
        type: .cricket,
        config: .cricket(MatchConfigCricket()),
        participants: [
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitCricketTurn(session: session, darts: [CricketTestDarts.triple(20)])
    let activeMatch = MatchSummary(
        id: session.runtime.matchId,
        type: .cricket,
        status: .inProgress,
        startedAt: Date(),
        endedAt: nil,
        winnerPlayerId: nil,
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: session.runtime.eventCount,
        createdAt: Date(),
        updatedAt: Date()
    )
    let vm = PlayHomeViewModel(
        playerRepository: FakePlayerRepository(players: [makePlayer("A"), makePlayer("B")]),
        matchRepository: FakeMatchRepositoryBuilder.withActiveMatch(activeMatch),
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink())
    )

    await vm.onAppear()

    if case let .readyWithActiveMatch(match) = vm.state {
        #expect(match.type == .cricket)
    } else {
        Issue.record("Expected resume state for cricket match")
    }
}

@MainActor
@Test(.tags(.integration, .navigation, .regression))
func playHomeSurfacesErrorWhenActiveMatchLookupFails() async {
    let vm = PlayHomeViewModel(
        playerRepository: FakePlayerRepository(players: [makePlayer("A"), makePlayer("B")]),
        matchRepository: FakeMatchRepositoryBuilder.failingActiveLookup(userMessageKey: "error.playHome.load"),
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink())
    )

    await vm.onAppear()

    if case let .error(messageKey) = vm.state {
        #expect(messageKey == "error.playHome.load")
    } else {
        Issue.record("Expected error state when match repository fails")
    }
}

@MainActor
@Test(.tags(.integration, .navigation, .regression))
func playHomeSurfacesErrorWhenPlayerLoadFails() async {
    let vm = PlayHomeViewModel(
        playerRepository: FakePlayerRepositoryBuilder.failingFetch(userMessageKey: "error.playHome.load"),
        matchRepository: FakeMatchRepositoryBuilder.withActiveMatch(nil),
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink())
    )

    await vm.onAppear()

    if case let .error(messageKey) = vm.state {
        #expect(messageKey == "error.playHome.load")
    } else {
        Issue.record("Expected error state when player repository fails")
    }
}

@MainActor
@Test(.tags(.integration, .navigation, .smoke, .regression))
func playHomeShowsNoActiveMatchWhenRosterEmpty() async {
    let vm = PlayHomeViewModel(
        playerRepository: FakePlayerRepository(players: []),
        matchRepository: FakeMatchRepositoryBuilder.withActiveMatch(nil),
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink())
    )

    await vm.onAppear()

    #expect(vm.state == .readyNoActiveMatch)
}
