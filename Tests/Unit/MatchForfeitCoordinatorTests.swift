import Foundation
import Testing
@testable import DartBuddy

@MainActor
private final class ForfeitCoordinatorTestHost: ObservableObject, MatchPlaySessionHost {
    let matchId: UUID
    var session: MatchLifecycleSession?
    var isBotTurnBlocking = false
    let hostMatchRepository: any MatchRepository
    let hostMatchStore: ActiveMatchStore
    let hostMatchLogger: any AppLogger
    let hostMatchType: MatchType

    init(
        session: MatchLifecycleSession,
        matchRepository: any MatchRepository,
        store: ActiveMatchStore,
        logger: any AppLogger
    ) {
        matchId = session.runtime.matchId
        self.session = session
        hostMatchRepository = matchRepository
        hostMatchStore = store
        hostMatchLogger = logger
        hostMatchType = session.runtime.type
    }

    func loadSessionIfNeeded() async {}
    func recoverBotPlaybackIfNeeded() {}
    func onDisappear() {}
}

@MainActor
private func makeForfeitCoordinator(
    type: MatchType = .x01,
    participants: [MatchParticipant],
    preTurns: Int = 1
) throws -> (MatchForfeitCoordinator, ForfeitCoordinatorTestHost) {
    let config = MatchConfigDefaults.config(for: type)
    var session = try MatchLifecycleService.createMatch(type: type, config: config, participants: participants)
    for _ in 0 ..< preTurns {
        switch type {
        case .x01:
            session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
        case .cricket:
            session = try MatchLifecycleService.submitCricketTurn(
                session: session,
                darts: [DartInput(multiplier: .single, segment: .miss, isMiss: true)]
            )
        default:
            session = try MatchLifecycleService.submitKnockoutTurn(
                session: session,
                darts: [
                    DartInput(multiplier: .single, segment: .oneToTwenty(20)),
                    DartInput(multiplier: .single, segment: .oneToTwenty(20)),
                    DartInput(multiplier: .single, segment: .oneToTwenty(5))
                ]
            )
        }
    }
    let store = ActiveMatchStore()
    store.save(session)
    let host = ForfeitCoordinatorTestHost(
        session: session,
        matchRepository: FakeMatchRepository(),
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink())
    )
    let coordinator = MatchForfeitCoordinator(
        store: store,
        matchRepository: host.hostMatchRepository,
        logger: host.hostMatchLogger
    )
    coordinator.configure(host: host, onComplete: {})
    return (coordinator, host)
}

@Suite("Match forfeit coordinator", .tags(.unit, .match, .regression))
struct MatchForfeitCoordinatorTests {
    @Test
    @MainActor
    func canForfeitRequiresAtLeastOneEvent() throws {
        let p1 = UUID()
        let p2 = UUID()
        let (coordinator, host) = try makeForfeitCoordinator(
            participants: [
                MatchParticipant(playerId: p1, displayNameAtMatchStart: "P1", turnOrder: 0),
                MatchParticipant(playerId: p2, displayNameAtMatchStart: "P2", turnOrder: 1)
            ],
            preTurns: 0
        )
        _ = host
        #expect(coordinator.canForfeit == false)

        let (withTurn, withTurnHost) = try makeForfeitCoordinator(
            participants: [
                MatchParticipant(playerId: p1, displayNameAtMatchStart: "P1", turnOrder: 0),
                MatchParticipant(playerId: p2, displayNameAtMatchStart: "P2", turnOrder: 1)
            ],
            preTurns: 1
        )
        _ = withTurnHost
        #expect(withTurn.canForfeit == true)
    }

    @Test
    @MainActor
    func twoPlayerFlowSkipsPlayerPicker() throws {
        let p1 = UUID()
        let p2 = UUID()
        let (coordinator, host) = try makeForfeitCoordinator(
            participants: [
                MatchParticipant(playerId: p1, displayNameAtMatchStart: "P1", turnOrder: 0),
                MatchParticipant(playerId: p2, displayNameAtMatchStart: "P2", turnOrder: 1)
            ]
        )
        _ = host

        coordinator.beginForfeitFlow()

        #expect(coordinator.flowState == .confirm)
        #expect(coordinator.forfeitingPlayerId == p1)
        #expect(coordinator.winnerPlayerId == p2)
    }

    @Test
    @MainActor
    func threePlayerFlowStartsAtPlayerPicker() throws {
        let ids = (0 ..< 3).map { _ in UUID() }
        let (coordinator, host) = try makeForfeitCoordinator(
            type: .knockout,
            participants: ids.enumerated().map { index, id in
                MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
            }
        )
        _ = host

        coordinator.beginForfeitFlow()

        #expect(coordinator.flowState == .pickPlayer)
        #expect(coordinator.forfeitingPlayerId == nil)
    }

    @Test
    @MainActor
    func selectForfeitingPlayerResolvesAutomaticWinner() throws {
        let p1 = UUID()
        let p2 = UUID()
        let p3 = UUID()
        let (coordinator, host) = try makeForfeitCoordinator(
            type: .knockout,
            participants: [
                MatchParticipant(playerId: p1, displayNameAtMatchStart: "P1", turnOrder: 0),
                MatchParticipant(playerId: p2, displayNameAtMatchStart: "P2", turnOrder: 1),
                MatchParticipant(playerId: p3, displayNameAtMatchStart: "P3", turnOrder: 2)
            ]
        )
        _ = host

        coordinator.beginForfeitFlow()
        coordinator.selectForfeitingPlayer(p1)

        #expect(coordinator.flowState == .confirm)
        #expect(coordinator.forfeitingPlayerId == p1)
        #expect(coordinator.winnerPlayerId != p1)
    }

    @Test
    @MainActor
    func cancelFlowResetsState() throws {
        let p1 = UUID()
        let p2 = UUID()
        let (coordinator, host) = try makeForfeitCoordinator(
            participants: [
                MatchParticipant(playerId: p1, displayNameAtMatchStart: "P1", turnOrder: 0),
                MatchParticipant(playerId: p2, displayNameAtMatchStart: "P2", turnOrder: 1)
            ]
        )
        _ = host
        coordinator.beginForfeitFlow()
        coordinator.cancelFlow()

        #expect(coordinator.flowState == .idle)
        #expect(coordinator.forfeitingPlayerId == nil)
        #expect(coordinator.winnerPlayerId == nil)
        #expect(coordinator.tiedCandidates.isEmpty)
    }

    @Test
    @MainActor
    func confirmMessageIncludesParticipantNames() throws {
        let p1 = UUID()
        let p2 = UUID()
        let (coordinator, host) = try makeForfeitCoordinator(
            participants: [
                MatchParticipant(playerId: p1, displayNameAtMatchStart: "Alice", turnOrder: 0),
                MatchParticipant(playerId: p2, displayNameAtMatchStart: "Bob", turnOrder: 1)
            ]
        )
        _ = host
        coordinator.beginForfeitFlow()

        let message = coordinator.confirmMessageKey
        #expect(message.contains("Alice"))
        #expect(message.contains("Bob"))
    }

    @Test
    @MainActor
    func confirmForfeitPersistsAndResetsFlow() async throws {
        let p1 = UUID()
        let p2 = UUID()
        let repository = FakeMatchRepositoryBuilder.forfeitCapturing()
        let store = ActiveMatchStore()
        var session = try MatchLifecycleService.createMatch(
            type: .x01,
            config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
            participants: [
                MatchParticipant(playerId: p1, displayNameAtMatchStart: "P1", turnOrder: 0),
                MatchParticipant(playerId: p2, displayNameAtMatchStart: "P2", turnOrder: 1)
            ]
        )
        session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
        store.save(session)
        let host = ForfeitCoordinatorTestHost(
            session: session,
            matchRepository: repository,
            store: store,
            logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink())
        )
        let coordinator = MatchForfeitCoordinator(
            store: store,
            matchRepository: repository,
            logger: host.hostMatchLogger
        )
        var completed = false
        coordinator.configure(host: host, onComplete: { completed = true })
        coordinator.beginForfeitFlow()

        await coordinator.confirmForfeit()

        #expect(coordinator.flowState == .idle)
        #expect(completed)
        #expect(store.session(for: session.runtime.matchId) == nil)
        #expect(await repository.forfeitCallCount == 1)
    }
}
