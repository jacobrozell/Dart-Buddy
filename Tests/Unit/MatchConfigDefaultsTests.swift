import Foundation
import Testing
@testable import DartBuddy

@Suite("Match config defaults", .tags(.unit, .match, .setupFlow, .regression))
struct MatchConfigDefaultsTests {
    private static let shippedTypes: [MatchType] = GameModeCatalog.all
        .filter { $0.status == .shipped }
        .compactMap(\.matchType)

    @Test
    func defaultsExistForEveryShippedMode() {
        for type in Self.shippedTypes {
            let config = MatchConfigDefaults.config(for: type)
            switch (type, config) {
            case (.x01, .x01), (.cricket, .cricket), (.baseball, .baseball), (.killer, .killer),
                 (.shanghai, .shanghai), (.americanCricket, .americanCricket), (.mickeyMouse, .mickeyMouse),
                 (.mulligan, .mulligan), (.englishCricket, .englishCricket), (.knockout, .knockout),
                 (.suddenDeath, .suddenDeath), (.fiftyOneByFives, .fiftyOneByFives), (.golf, .golf),
                 (.football, .football), (.grandNational, .grandNational), (.hareAndHounds, .hareAndHounds),
                 (.aroundTheClock, .aroundTheClock), (.aroundTheClock180, .aroundTheClock180),
                 (.chaseTheDragon, .chaseTheDragon), (.nineLives, .nineLives),
                 (.fleet, .fleet), (.raid, .raid):
                break
            default:
                Issue.record("Default config payload mismatch for \(type)")
            }
        }
    }

    @Test
    func defaultsRoundTripThroughJSON() throws {
        for type in Self.shippedTypes {
            let original = MatchConfigDefaults.config(for: type)
            let data = try CodablePayloadCoder.encode(original)
            let decoded = try CodablePayloadCoder.decode(MatchConfigPayload.self, from: data)
            #expect(decoded == original)
        }
    }

    @Test
    func defaultsSeedPlayableSessions() throws {
        for type in Self.shippedTypes {
            let minimum = GameModeCatalog.entry(for: type)?.minimumPlayers ?? 2
            let participants = (0 ..< minimum).map { index in
                MatchParticipant(
                    playerId: UUID(),
                    displayNameAtMatchStart: "P\(index + 1)",
                    turnOrder: index
                )
            }
            let session = try MatchLifecycleService.createMatch(
                type: type,
                config: MatchConfigDefaults.config(for: type),
                participants: participants
            )
            #expect(session.runtime.type == type)
            #expect(session.runtime.status == .inProgress)
        }
    }

    @Test
    func mulliganDefaultConfigIncludesGeneratedSequence() throws {
        guard case let .mulligan(config) = MatchConfigDefaults.config(for: .mulligan) else {
            Issue.record("Expected mulligan default config")
            return
        }
        #expect(config.targetCount == 6)
        #expect(config.targetSequence.count == 7)
        #expect(config.targetSequence.last == .bull)
    }
}
