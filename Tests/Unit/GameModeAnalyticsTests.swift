import Foundation
import Testing
@testable import DartBuddy

@Suite("Game mode analytics", .tags(.unit, .logging, .regression))
struct GameModeAnalyticsTests {
    @Test
    func metadataMapsShippedCatalogModes() {
        for entry in GameModeCatalog.available {
            guard let matchType = entry.matchType else { continue }
            let metadata = GameModeAnalytics.metadata(for: matchType, participantCount: 2)

            #expect(metadata["matchType"] == matchType.rawValue)
            #expect(metadata["participantCount"] == "2")
            #expect(metadata["gameModeId"] == entry.id)
            #expect(metadata["gameModeSection"] == entry.section.rawValue)
            #expect(metadata["uiTemplate"] == entry.uiTemplate.rawValue)
            #expect(metadata["statKind"] == entry.statKind.rawValue)
        }
    }

    @Test
    func metadataFallsBackWhenCatalogEntryMissing() {
        let metadata = GameModeAnalytics.metadata(for: .x01, participantCount: 1, extra: ["source": "test"])

        #expect(metadata["gameModeId"] == GameModeCatalog.entry(for: .x01)?.id)
        #expect(metadata["source"] == "test")
    }
}
