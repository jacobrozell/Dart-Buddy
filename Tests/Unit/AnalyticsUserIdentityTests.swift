import Foundation
import Testing
@testable import DartBuddy

@Suite("Analytics user identity", .tags(.unit, .logging, .regression))
struct AnalyticsUserIdentityTests {
    @Test
    func resolveUserIdUsesPrimaryHumanPlayerUUID() {
        let playerId = UUID(uuidString: "AABBCCDD-EEFF-0011-2233-445566778899")!
        let primary = PlayerSummary(
            id: playerId,
            name: "Jacob",
            isArchived: false,
            isBot: false,
            botDifficultyRaw: nil,
            botKindRaw: nil,
            linkedPlayerId: nil,
            avatarStyleRaw: nil,
            preferredColorToken: nil,
            notes: nil,
            playerRoleRaw: PlayerRole.primary.rawValue,
            createdAt: Date(),
            updatedAt: Date()
        )

        #expect(AnalyticsUserIdentity.resolveUserId(primaryPlayer: primary) == playerId.uuidString.lowercased())
    }

    @Test
    func resolveUserIdPrefersAuthenticatedFirebaseUID() {
        let primary = PlayerSummary(
            id: UUID(),
            name: "Jacob",
            isArchived: false,
            isBot: false,
            botDifficultyRaw: nil,
            botKindRaw: nil,
            linkedPlayerId: nil,
            avatarStyleRaw: nil,
            preferredColorToken: nil,
            notes: nil,
            playerRoleRaw: PlayerRole.primary.rawValue,
            createdAt: Date(),
            updatedAt: Date()
        )

        #expect(AnalyticsUserIdentity.resolveUserId(
            primaryPlayer: primary,
            authenticatedFirebaseUID: "firebase-auth-uid"
        ) == "firebase-auth-uid")
    }

    @Test
    func resolveUserIdIsNilForBotsAndMissingPrimary() {
        let bot = PlayerSummary(
            id: UUID(),
            name: "Medium Bot",
            isArchived: false,
            isBot: true,
            botDifficultyRaw: BotDifficulty.medium.rawValue,
            botKindRaw: BotKind.preset.rawValue,
            linkedPlayerId: nil,
            avatarStyleRaw: nil,
            preferredColorToken: nil,
            notes: nil,
            playerRoleRaw: PlayerRole.primary.rawValue,
            createdAt: Date(),
            updatedAt: Date()
        )

        #expect(AnalyticsUserIdentity.resolveUserId(primaryPlayer: nil) == nil)
        #expect(AnalyticsUserIdentity.resolveUserId(primaryPlayer: bot) == nil)
    }
}
