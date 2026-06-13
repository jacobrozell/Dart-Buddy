import Foundation
import Testing
@testable import DartBuddy

// Lifecycle coverage for shipped modes beyond the dedicated baseball/shanghai/killer suites.

private func miss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

private enum ShippedModeLifecycleSupport {
    static var types: [MatchType] {
        GameModeCatalog.all
            .filter { $0.status == .shipped }
            .compactMap(\.matchType)
            .filter { $0 != .killer }
    }

    static func participants(for type: MatchType) -> [MatchParticipant] {
        let count = type == .fleet ? 2 : (GameModeCatalog.entry(for: type)?.minimumPlayers ?? 2)
        return (0 ..< count).map { index in
            MatchParticipant(
                playerId: UUID(),
                displayNameAtMatchStart: "P\(index + 1)",
                turnOrder: index
            )
        }
    }

    static func submitTurn(session: MatchLifecycleSession) throws -> MatchLifecycleSession {
        switch session.runtime.type {
        case .x01:
            return try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
        case .cricket, .baseball, .shanghai, .americanCricket, .mickeyMouse, .mulligan,
             .englishCricket, .knockout, .suddenDeath, .fiftyOneByFives, .football,
             .grandNational, .hareAndHounds, .aroundTheClock, .aroundTheClock180,
             .chaseTheDragon, .nineLives:
            return try submitMissTurn(session: session)
        case .fleet:
            return try submitFleetTurn(session: session)
        case .golf:
            return try MatchLifecycleService.submitGolfTurn(
                session: session,
                input: GolfTurnInput(darts: [miss()])
            )
        case .killer, .blindKiller, .followTheLeader, .loop, .prisoner, .scam, .snooker, .ticTacToe, .bobs27, .halveIt:
            return session
        }
    }

    private static func submitFleetTurn(session: MatchLifecycleSession) throws -> MatchLifecycleSession {
        let playerId = session.runtime.participants.first.map { $0.playerId ?? $0.id } ?? UUID()
        let shipCount = session.runtime.fleetState?.config.shipCount.count ?? 5
        var updated = try MatchLifecycleService.confirmFleetHandoff(session: session, playerId: playerId)
        for segment in 1 ... shipCount {
            updated = try MatchLifecycleService.toggleFleetPlacementCell(
                session: updated,
                playerId: playerId,
                cell: .segment(segment)
            )
        }
        return try MatchLifecycleService.submitFleetPlacementLock(session: updated, playerId: playerId)
    }

    private static func submitMissTurn(session: MatchLifecycleSession) throws -> MatchLifecycleSession {
        switch session.runtime.type {
        case .cricket:
            return try MatchLifecycleService.submitCricketTurn(session: session, darts: [miss()])
        case .baseball:
            return try MatchLifecycleService.submitBaseballTurn(session: session, darts: [miss()])
        case .shanghai:
            return try MatchLifecycleService.submitShanghaiTurn(session: session, darts: [miss()])
        case .americanCricket:
            return try MatchLifecycleService.submitAmericanCricketTurn(session: session, darts: [miss()])
        case .mickeyMouse:
            return try MatchLifecycleService.submitMickeyMouseTurn(session: session, darts: [miss()])
        case .mulligan:
            return try MatchLifecycleService.submitMulliganTurn(session: session, darts: [miss()])
        case .englishCricket:
            return try MatchLifecycleService.submitEnglishCricketTurn(session: session, darts: [miss()])
        case .knockout:
            return try MatchLifecycleService.submitKnockoutTurn(session: session, darts: [miss(), miss(), miss()])
        case .suddenDeath:
            return try MatchLifecycleService.submitSuddenDeathTurn(session: session, darts: [miss()])
        case .fiftyOneByFives:
            return try MatchLifecycleService.submitFiftyOneByFivesTurn(session: session, darts: [miss(), miss(), miss()])
        case .football:
            return try MatchLifecycleService.submitFootballTurn(session: session, darts: [miss(), miss(), miss()])
        case .grandNational:
            return try MatchLifecycleService.submitGrandNationalTurn(session: session, darts: [miss()])
        case .hareAndHounds:
            return try MatchLifecycleService.submitHareAndHoundsTurn(session: session, darts: [miss()])
        case .aroundTheClock:
            return try MatchLifecycleService.submitAroundTheClockTurn(session: session, darts: [miss()])
        case .aroundTheClock180:
            return try MatchLifecycleService.submitAroundTheClock180Turn(session: session, darts: [miss()])
        case .chaseTheDragon:
            return try MatchLifecycleService.submitChaseTheDragonTurn(session: session, darts: [miss()])
        case .nineLives:
            return try MatchLifecycleService.submitNineLivesTurn(session: session, darts: [miss()])
        default:
            return session
        }
    }

    static func eventCount(in session: MatchLifecycleSession) -> Int {
        session.runtime.eventCount
    }
}

@Suite("Shipped mode lifecycle", .tags(.unit, .match, .regression, .offline))
struct MatchLifecycleServiceShippedModesTests {
    @Test
    func everyShippedModeCreatesWithDefaultConfig() throws {
        for type in ShippedModeLifecycleSupport.types {
            let session = try MatchLifecycleService.createMatch(
                type: type,
                config: MatchConfigDefaults.config(for: type),
                participants: ShippedModeLifecycleSupport.participants(for: type)
            )
            #expect(session.runtime.type == type)
            #expect(session.runtime.status == .inProgress)
            #expect(session.runtime.eventCount == 0)
            #expect(!session.latestSnapshot.payload.isEmpty)
        }
    }

    @Test
    func everyShippedModeAcceptsSubmittedTurn() throws {
        for type in ShippedModeLifecycleSupport.types {
            var session = try MatchLifecycleService.createMatch(
                type: type,
                config: MatchConfigDefaults.config(for: type),
                participants: ShippedModeLifecycleSupport.participants(for: type)
            )
            session = try ShippedModeLifecycleSupport.submitTurn(session: session)
            if type == .fleet {
                #expect(ShippedModeLifecycleSupport.eventCount(in: session) >= 1)
            } else {
                #expect(ShippedModeLifecycleSupport.eventCount(in: session) == 1)
            }
        }
    }

    @Test
    func everyShippedModeAcceptsSecondTurnWhileInProgress() throws {
        for type in ShippedModeLifecycleSupport.types {
            var session = try MatchLifecycleService.createMatch(
                type: type,
                config: MatchConfigDefaults.config(for: type),
                participants: ShippedModeLifecycleSupport.participants(for: type)
            )
            session = try ShippedModeLifecycleSupport.submitTurn(session: session)
            guard session.runtime.status == .inProgress else { continue }
            session = try ShippedModeLifecycleSupport.submitTurn(session: session)
            #expect(ShippedModeLifecycleSupport.eventCount(in: session) == 2)
        }
    }

    @Test
    func everyShippedModeUndoLastTurnReplaysDeterministically() throws {
        for type in ShippedModeLifecycleSupport.types {
            var session = try MatchLifecycleService.createMatch(
                type: type,
                config: MatchConfigDefaults.config(for: type),
                participants: ShippedModeLifecycleSupport.participants(for: type)
            )
            session = try ShippedModeLifecycleSupport.submitTurn(session: session)
            guard session.runtime.eventCount == 1 else { continue }

            let undone = try MatchLifecycleService.undoLastTurn(session: session)

            #expect(undone.runtime.eventCount == 0)
            #expect(undone.events.isEmpty)
        }
    }

    @Test
    func soloPracticeModesAllowSingleParticipant() throws {
        for type in [MatchType.aroundTheClock, .aroundTheClock180, .chaseTheDragon] {
            let session = try MatchLifecycleService.createMatch(
                type: type,
                config: MatchConfigDefaults.config(for: type),
                participants: [
                    MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "Solo", turnOrder: 0)
                ]
            )
            #expect(session.runtime.participants.count == 1)
        }
    }

    @Test
    func multiPlayerModesRejectSingleParticipant() {
        for type in [MatchType.americanCricket, .golf, .knockout, .mickeyMouse] {
            #expect(throws: (any Error).self) {
                _ = try MatchLifecycleService.createMatch(
                    type: type,
                    config: MatchConfigDefaults.config(for: type),
                    participants: [
                        MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "Only", turnOrder: 0)
                    ]
                )
            }
        }
    }
}
