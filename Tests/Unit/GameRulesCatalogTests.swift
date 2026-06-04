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
}
