import Testing
@testable import DartBuddy

@Suite("Game mode accent", .tags(.unit, .regression))
struct GameModeAccentTests {
    private static let allTypes: [MatchType] = [.x01, .cricket, .baseball, .killer, .shanghai]

    @Test
    func everyMatchTypeHasDistinctIcon() {
        let icons = Self.allTypes.map { GameModeAccent.icon(for: $0) }
        #expect(Set(icons).count == icons.count)
        #expect(icons.allSatisfy { !$0.isEmpty })
    }

    @Test
    func shippedCatalogIconsMatchAccentTable() throws {
        for type in Self.allTypes {
            let entry = try #require(GameModeCatalog.entry(for: type))
            #expect(entry.iconSystemName == GameModeAccent.icon(for: type))
        }
    }
}
