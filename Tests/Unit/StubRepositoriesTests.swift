import Foundation
import Testing
@testable import DartBuddy

@Suite("Stub repositories", .tags(.unit, .regression))
struct StubRepositoriesTests {
    @Test
    func playerRepositoryReturnsEmptyList() async throws {
        let repository = StubPlayerRepository()
        #expect(try await repository.fetchPlayers(includeArchived: false).isEmpty)
        #expect(try await repository.fetchPlayers(includeArchived: true).isEmpty)
    }

    @Test
    func playerRepositoryRejectsMutations() async throws {
        let repository = StubPlayerRepository()
        await expectUnsupported {
            _ = try await repository.createPlayer(name: "Alice")
        }
        await expectUnsupported {
            _ = try await repository.createBot(difficulty: .easy)
        }
        await expectUnsupported {
            _ = try await repository.updatePlayerName(playerId: UUID(), name: "Bob")
        }
    }

    @Test
    func matchRepositoryReturnsEmptyHistory() async throws {
        let repository = StubMatchRepository()
        #expect(try await repository.fetchActiveMatch() == nil)
        #expect(try await repository.fetchHistory(page: 0, pageSize: 10).isEmpty)
        #expect(
            try await repository.fetchHistoryWithParticipants(
                page: 0,
                pageSize: 10,
                filter: MatchHistoryFilter()
            ).isEmpty
        )
        #expect(try await repository.fetchLatestSnapshot(matchId: UUID()) == nil)
        #expect(try await repository.fetchMatch(matchId: UUID()) == nil)
        #expect(try await repository.fetchParticipants(matchId: UUID()).isEmpty)
    }

    @Test
    func matchRepositoryRejectsMutations() async throws {
        let repository = StubMatchRepository()
        await expectUnsupported {
            _ = try await repository.createMatch(type: .x01, configPayload: Data(), participants: [])
        }
        await expectUnsupported {
            _ = try await repository.completeMatch(matchId: UUID(), endedAt: Date(), winnerPlayerId: nil)
        }
        await expectUnsupported {
            _ = try await repository.appendEvent(matchId: UUID(), eventTypeRaw: "x01Turn", eventPayload: Data())
        }
    }

    @Test
    func statsRepositoryReturnsNoEvents() async throws {
        let repository = StubStatsRepository()
        let matchId = UUID()
        #expect(try await repository.fetchEvents(matchId: matchId).isEmpty)
        #expect(try await repository.fetchEvents(matchIds: [matchId]).isEmpty)
    }

    @Test
    func settingsRepositorySeedsAndPersistsDefaults() async throws {
        let repository = StubSettingsRepository()
        let seeded = try await repository.seedDefaultsIfNeeded()
        #expect(seeded.appearanceModeRaw == "system")
        #expect(seeded.defaultMatchTypeRaw == "x01")
        #expect(seeded.defaultX01StartScore == 501)
        #expect(seeded.hapticsEnabled)
        #expect(seeded.soundEnabled)
        #expect(seeded.botStaggerEnabled)
        #expect(seeded.botDartHapticsEnabled)

        let updated = SettingsSummary(
            id: seeded.id,
            appearanceModeRaw: "dark",
            hapticsEnabled: false,
            soundEnabled: false,
            turnTotalCallerEnabled: true,
            defaultMatchTypeRaw: "cricket",
            defaultX01StartScore: 301,
            defaultCheckoutModeRaw: "singleOut",
            defaultCheckInModeRaw: "doubleIn",
            defaultLegFormatRaw: "bestOf",
            defaultLegsToWin: 5,
            defaultSetsEnabled: true,
            botStaggerEnabled: false,
            botDartHapticsEnabled: false,
            defaultDartEntryPresentationRaw: "numberPad",
            updatedAt: Date()
        )
        let saved = try await repository.updateSettings(updated)
        #expect(saved.appearanceModeRaw == "dark")
        #expect(try await repository.fetchSettings().defaultMatchTypeRaw == "cricket")

        try await repository.resetPreferencesToDefaults()
        let reset = try await repository.fetchSettings()
        #expect(reset.appearanceModeRaw == "system")
        #expect(reset.defaultMatchTypeRaw == "x01")
        #expect(reset.hapticsEnabled)
        #expect(reset.soundEnabled)
    }

    @Test
    func settingsRepositoryResetAllLocalDataRestoresDefaults() async throws {
        let repository = StubSettingsRepository()
        let baseline = try await repository.fetchSettings()
        let updated = SettingsSummary(
            id: baseline.id,
            appearanceModeRaw: "light",
            hapticsEnabled: false,
            soundEnabled: false,
            turnTotalCallerEnabled: true,
            defaultMatchTypeRaw: "killer",
            defaultX01StartScore: 701,
            defaultCheckoutModeRaw: "masterOut",
            defaultCheckInModeRaw: "doubleIn",
            defaultLegFormatRaw: "bestOf",
            defaultLegsToWin: 7,
            defaultSetsEnabled: true,
            botStaggerEnabled: false,
            botDartHapticsEnabled: false,
            defaultDartEntryPresentationRaw: "numberPad",
            updatedAt: Date()
        )
        _ = try await repository.updateSettings(updated)

        try await repository.resetAllLocalData()

        let reset = try await repository.fetchSettings()
        #expect(reset.appearanceModeRaw == "system")
        #expect(reset.defaultX01StartScore == 501)
        #expect(reset.hapticsEnabled)
    }

    private func expectUnsupported(_ operation: () async throws -> Void) async {
        do {
            try await operation()
            Issue.record("Expected unsupported operation")
        } catch let error as AppError {
            #expect(error.userMessageKey == "error.repository.notImplemented")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
