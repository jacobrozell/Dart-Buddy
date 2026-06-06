import Testing
@testable import DartBuddy

@Suite("Game rules catalog", .tags(.unit))
struct GameRulesCatalogTests {
    @Test("Every supported match type has rule sections")
    func guidesArePopulated() {
        for mode in GameRulesCatalog.supportedMatchTypes {
            let guide = GameRulesCatalog.guide(for: mode)
            #expect(guide.matchType == mode)
            #expect(!guide.sections.isEmpty)
            #expect(guide.sections.allSatisfy { !$0.titleKey.isEmpty && !$0.bodyKey.isEmpty })
        }
    }

    @Test("Cricket guide covers scoring variants")
    func cricketIncludesVariantSections() {
        let ids = Set(GameRulesCatalog.guide(for: .cricket).sections.map(\.id))
        #expect(ids.contains("normalScore"))
        #expect(ids.contains("cutThroatScore"))
        #expect(ids.contains("noScore"))
    }

    @Test("X01 guide covers setup variants")
    func x01IncludesCheckInAndCheckOutSections() {
        let ids = Set(GameRulesCatalog.guide(for: .x01).sections.map(\.id))
        #expect(ids.contains("checkIn"))
        #expect(ids.contains("checkOut"))
    }

    @Test("Party mode guides include overview sections")
    func partyGuidesIncludeOverview() {
        for type in [MatchType.baseball, .killer, .shanghai] {
            let ids = Set(GameRulesCatalog.guide(for: type).sections.map(\.id))
            #expect(ids.contains("overview"), "Expected overview in \(type) guide")
        }
    }

    @Test("Supported match types match current product surface")
    func supportedTypesCoverShippedModes() {
        let expected: Set<MatchType> = ProductSurface.showsPartyModes
            ? [.x01, .cricket, .baseball, .killer, .shanghai]
            : [.x01, .cricket]
        #expect(Set(GameRulesCatalog.supportedMatchTypes) == expected)
    }
}
