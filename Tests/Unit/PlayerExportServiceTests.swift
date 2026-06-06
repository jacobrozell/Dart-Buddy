import Foundation
import Testing
@testable import DartBuddy

@Test(.tags(.unit, .player, .regression))
func playerExportBundleRoundTripsThroughJSON() throws {
    let anchorId = UUID(uuidString: "A0000000-0000-4000-8000-000000000001")!
    let opponentId = UUID(uuidString: "A0000000-0000-4000-8000-000000000002")!
    let matchId = UUID(uuidString: "B0000000-0000-4000-8000-000000000001")!
    let eventOneId = UUID(uuidString: "C0000000-0000-4000-8000-000000000001")!
    let eventTwoId = UUID(uuidString: "C0000000-0000-4000-8000-000000000002")!
    let participantOneId = UUID(uuidString: "D0000000-0000-4000-8000-000000000001")!
    let participantTwoId = UUID(uuidString: "D0000000-0000-4000-8000-000000000002")!
    let snapshotId = UUID(uuidString: "E0000000-0000-4000-8000-000000000001")!
    // Integer epoch avoids ISO-8601 subsecond drift across encode/decode.
    let now = Date(timeIntervalSince1970: 1_700_000_000)

    let bundle = PlayerExportBundle(
        dbpeVersion: 1,
        producer: "com.jacobrozell.DartBuddy",
        producerVersion: "1.0.0",
        exportedAt: now,
        persistenceSchemaVersion: "2.0.0",
        anchorPlayerId: anchorId,
        player: PlayerExportRecord(from: makePlayer(id: anchorId, name: "Jacob", createdAt: now, updatedAt: now)),
        referencedPlayers: [
            PlayerExportRecord(from: makePlayer(id: opponentId, name: "Sam", createdAt: now, updatedAt: now))
        ],
        matches: [
            MatchExportBundle(
                match: MatchExportRecord(from: MatchSummary(
                    id: matchId,
                    type: .x01,
                    status: .completed,
                    startedAt: now,
                    endedAt: now,
                    winnerPlayerId: anchorId,
                    currentTurnPlayerId: nil,
                    currentLegIndex: 0,
                    currentSetIndex: 0,
                    eventCount: 2,
                    createdAt: now,
                    updatedAt: now
                )),
                configPayload: Data("config".utf8),
                participants: [
                    MatchParticipantExportRecord(from: MatchParticipantSummary(
                        id: participantOneId, matchId: matchId, playerId: anchorId, turnOrder: 0, displayNameAtMatchStart: "Jacob"
                    )),
                    MatchParticipantExportRecord(from: MatchParticipantSummary(
                        id: participantTwoId, matchId: matchId, playerId: opponentId, turnOrder: 1, displayNameAtMatchStart: "Sam"
                    ))
                ],
                events: [
                    MatchEventExportRecord(from: MatchEventSummary(
                        id: eventOneId, matchId: matchId, eventIndex: 0, eventTypeRaw: "turn", eventPayload: Data("a".utf8), createdAt: now
                    )),
                    MatchEventExportRecord(from: MatchEventSummary(
                        id: eventTwoId, matchId: matchId, eventIndex: 1, eventTypeRaw: "turn", eventPayload: Data("b".utf8), createdAt: now
                    ))
                ],
                snapshot: MatchSnapshotExportRecord(from: MatchSnapshotSummary(
                    id: snapshotId, matchId: matchId, snapshotVersion: 1, snapshotPayload: Data("snap".utf8), updatedAt: now
                ))
            )
        ]
    )

    let data = try PlayerExportBundleCoding.encode(bundle)
    let decoded = try PlayerExportBundleCoding.decode(data)
    #expect(decoded.dbpeVersion == bundle.dbpeVersion)
    #expect(decoded.anchorPlayerId == bundle.anchorPlayerId)
    #expect(decoded.exportedAt == bundle.exportedAt)
    #expect(decoded.player == bundle.player)
    #expect(decoded.referencedPlayers == bundle.referencedPlayers)
    #expect(decoded.matches == bundle.matches)
    try PlayerExportValidator.validate(decoded)
}

@Test(.tags(.unit, .player, .regression))
func playerExportValidatorRejectsUnsupportedVersion() {
    let bundle = PlayerExportBundle(
        dbpeVersion: 99,
        producer: "test",
        producerVersion: "1.0.0",
        exportedAt: Date(),
        persistenceSchemaVersion: "2.0.0",
        anchorPlayerId: UUID(),
        player: PlayerExportRecord(from: makePlayer(id: UUID(), name: "A", createdAt: Date(), updatedAt: Date())),
        referencedPlayers: [],
        matches: []
    )

    #expect(throws: PlayerExportValidationFailure.unsupportedVersion(99)) {
        try PlayerExportValidator.validate(bundle)
    }
}

@Test(.tags(.unit, .player, .regression))
func playerExportValidatorRejectsAnchorPlayerMismatch() {
    let anchorId = UUID()
    let now = Date()
    let bundle = PlayerExportBundle(
        dbpeVersion: 1,
        producer: "test",
        producerVersion: "1.0.0",
        exportedAt: now,
        persistenceSchemaVersion: "2.0.0",
        anchorPlayerId: anchorId,
        player: PlayerExportRecord(from: makePlayer(id: UUID(), name: "A", createdAt: now, updatedAt: now)),
        referencedPlayers: [],
        matches: []
    )

    #expect(throws: PlayerExportValidationFailure.anchorPlayerMismatch) {
        try PlayerExportValidator.validate(bundle)
    }
}

@Test(.tags(.unit, .player, .regression))
func playerExportValidatorRejectsIncompleteMatch() {
    let anchorId = UUID()
    let matchId = UUID()
    let now = Date()
    let bundle = PlayerExportBundle(
        dbpeVersion: 1,
        producer: "test",
        producerVersion: "1.0.0",
        exportedAt: now,
        persistenceSchemaVersion: "2.0.0",
        anchorPlayerId: anchorId,
        player: PlayerExportRecord(from: makePlayer(id: anchorId, name: "A", createdAt: now, updatedAt: now)),
        referencedPlayers: [],
        matches: [
            MatchExportBundle(
                match: MatchExportRecord(from: MatchSummary(
                    id: matchId,
                    type: .x01,
                    status: .inProgress,
                    startedAt: now,
                    endedAt: nil,
                    winnerPlayerId: nil,
                    currentTurnPlayerId: anchorId,
                    currentLegIndex: 0,
                    currentSetIndex: 0,
                    eventCount: 1,
                    createdAt: now,
                    updatedAt: now
                )),
                configPayload: nil,
                participants: [
                    MatchParticipantExportRecord(from: MatchParticipantSummary(
                        id: UUID(), matchId: matchId, playerId: anchorId, turnOrder: 0, displayNameAtMatchStart: "A"
                    ))
                ],
                events: [],
                snapshot: nil
            )
        ]
    )

    #expect(throws: PlayerExportValidationFailure.matchNotCompleted(matchId)) {
        try PlayerExportValidator.validate(bundle)
    }
}

@Test(.tags(.unit, .player, .regression))
func playerExportValidatorRejectsMissingParticipants() {
    let anchorId = UUID()
    let matchId = UUID()
    let now = Date()
    let bundle = PlayerExportBundle(
        dbpeVersion: 1,
        producer: "test",
        producerVersion: "1.0.0",
        exportedAt: now,
        persistenceSchemaVersion: "2.0.0",
        anchorPlayerId: anchorId,
        player: PlayerExportRecord(from: makePlayer(id: anchorId, name: "A", createdAt: now, updatedAt: now)),
        referencedPlayers: [],
        matches: [
            MatchExportBundle(
                match: MatchExportRecord(from: MatchSummary(
                    id: matchId,
                    type: .x01,
                    status: .completed,
                    startedAt: now,
                    endedAt: now,
                    winnerPlayerId: anchorId,
                    currentTurnPlayerId: nil,
                    currentLegIndex: 0,
                    currentSetIndex: 0,
                    eventCount: 0,
                    createdAt: now,
                    updatedAt: now
                )),
                configPayload: nil,
                participants: [],
                events: [],
                snapshot: nil
            )
        ]
    )

    #expect(throws: PlayerExportValidationFailure.missingParticipants(matchId)) {
        try PlayerExportValidator.validate(bundle)
    }
}

@Test(.tags(.unit, .player, .regression))
func playerExportValidatorRejectsNonContiguousEventIndices() {
    let matchId = UUID()
    let anchorId = UUID()
    let now = Date()
    let bundle = PlayerExportBundle(
        dbpeVersion: 1,
        producer: "test",
        producerVersion: "1.0.0",
        exportedAt: now,
        persistenceSchemaVersion: "2.0.0",
        anchorPlayerId: anchorId,
        player: PlayerExportRecord(from: makePlayer(id: anchorId, name: "A", createdAt: now, updatedAt: now)),
        referencedPlayers: [],
        matches: [
            MatchExportBundle(
                match: MatchExportRecord(from: MatchSummary(
                    id: matchId,
                    type: .x01,
                    status: .completed,
                    startedAt: now,
                    endedAt: now,
                    winnerPlayerId: anchorId,
                    currentTurnPlayerId: nil,
                    currentLegIndex: 0,
                    currentSetIndex: 0,
                    eventCount: 2,
                    createdAt: now,
                    updatedAt: now
                )),
                configPayload: nil,
                participants: [
                    MatchParticipantExportRecord(from: MatchParticipantSummary(
                        id: UUID(), matchId: matchId, playerId: anchorId, turnOrder: 0, displayNameAtMatchStart: "A"
                    ))
                ],
                events: [
                    MatchEventExportRecord(from: MatchEventSummary(
                        id: UUID(), matchId: matchId, eventIndex: 0, eventTypeRaw: "turn", eventPayload: Data(), createdAt: now
                    )),
                    MatchEventExportRecord(from: MatchEventSummary(
                        id: UUID(), matchId: matchId, eventIndex: 2, eventTypeRaw: "turn", eventPayload: Data(), createdAt: now
                    ))
                ],
                snapshot: nil
            )
        ]
    )

    #expect(throws: PlayerExportValidationFailure.eventIndicesNotContiguous(matchId: matchId, expected: 1, actual: 2)) {
        try PlayerExportValidator.validate(bundle)
    }
}

@Test(.tags(.integration, .player, .swiftdata, .regression))
func playerExportServiceIncludesParticipantsAndEventsForSeededMatch() async throws {
    let repos = try makeExportTestRepositories()
    let alice = try await repos.player.createPlayer(name: "Alice")
    let bob = try await repos.player.createPlayer(name: "Bob")
    let payload = try CodablePayloadCoder.encode(MatchConfigPayload.x01(MatchConfigX01(
        startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut
    )))
    let matchId = UUID()
    let participants = [
        MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: alice.id, turnOrder: 0, displayNameAtMatchStart: "Alice"),
        MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: bob.id, turnOrder: 1, displayNameAtMatchStart: "Bob")
    ]
    let created = try await repos.match.createMatch(type: .x01, configPayload: payload, participants: participants)
    _ = try await repos.match.appendEvent(matchId: created.id, eventTypeRaw: "turn", eventPayload: Data("event0".utf8))
    _ = try await repos.match.appendEvent(matchId: created.id, eventTypeRaw: "turn", eventPayload: Data("event1".utf8))
    _ = try await repos.match.completeMatch(matchId: created.id, endedAt: Date(), winnerPlayerId: alice.id)

    let bundle = try await PlayerExportService.buildBundle(
        anchorPlayerId: alice.id,
        matchRepository: repos.match,
        statsRepository: repos.stats,
        playerRepository: repos.player,
        metadata: PlayerExportMetadata(producer: "test", producerVersion: "1.0.0", persistenceSchemaVersion: "2.0.0")
    )

    #expect(bundle.matches.count == 1)
    #expect(bundle.matches[0].participants.count == 2)
    #expect(bundle.matches[0].events.count == 2)
    #expect(bundle.matches[0].configPayload != nil)
    #expect(bundle.referencedPlayers.contains(where: { $0.id == bob.id }))
    #expect(bundle.referencedPlayers.contains(where: { $0.id == alice.id }) == false)

    let url = try PlayerExportService.writeExportFile(bundle: bundle, playerName: "Alice")
    defer { try? FileManager.default.removeItem(at: url) }
    #expect(url.lastPathComponent.contains("Alice-dartbuddy-export.dartbuddy.json"))
    let decoded = try PlayerExportBundleCoding.decode(Data(contentsOf: url))
    try PlayerExportValidator.validate(decoded)
}

private func makeExportTestRepositories() throws -> (
    player: SwiftDataPlayerRepository,
    match: SwiftDataMatchRepository,
    stats: SwiftDataStatsRepository
) {
    let container = try ModelContainerFactory.makeContainer(mode: .inMemory)
    let match = SwiftDataMatchRepository(container: container)
    let stats = SwiftDataStatsRepository(container: container)
    return (
        SwiftDataPlayerRepository(container: container, matchRepository: match, statsRepository: stats),
        match,
        stats
    )
}

private func makePlayer(id: UUID, name: String, createdAt: Date, updatedAt: Date) -> PlayerSummary {
    PlayerSummary(
        id: id,
        name: name,
        isArchived: false,
        isBot: false,
        createdAt: createdAt,
        updatedAt: updatedAt
    )
}
