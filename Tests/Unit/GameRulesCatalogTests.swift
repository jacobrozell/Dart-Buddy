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
        for type in [MatchType.baseball, .killer, .shanghai, .golf, .football] {
            let ids = Set(GameRulesCatalog.guide(for: type).sections.map(\.id))
            #expect(ids.contains("overview"), "Expected overview in \(type) guide")
        }
    }

    @Test("Onboarding rules picker covers core modes only")
    func supportedTypesForOnboarding() {
        #expect(GameRulesCatalog.supportedMatchTypes == [.x01, .cricket])
    }

    @Test("Every shipped mode has a rules guide")
    func shippedModesHaveGuides() {
        for entry in GameModeCatalog.available {
            guard let matchType = entry.matchType else { continue }
            #expect(GameRulesCatalog.hasGuide(for: matchType), "Missing guide for \(matchType)")
        }
    }

    @Test("Only cataloged modes expose a rules guide")
    func hasGuideMatchesCatalog() {
        #expect(GameRulesCatalog.hasGuide(for: .x01))
        #expect(GameRulesCatalog.hasGuide(for: .cricket))
        #expect(GameRulesCatalog.hasGuide(for: .golf))
        #expect(!GameRulesCatalog.hasGuide(for: .blindKiller))
    }

    @Test("Setup mode maps to match type")
    func setupModeMatchTypeMapping() {
        #expect(MatchSetupViewModel.SetupMode.x01.matchType == .x01)
        #expect(MatchSetupViewModel.SetupMode.cricket.matchType == .cricket)
    }

    @Test("Raid preview guide covers co-op phases")
    func raidPreviewGuideSections() {
        #expect(GameRulesCatalog.hasPreviewGuide(for: "coop.raid"))
        let guide = GameRulesCatalog.previewGuide(for: "coop.raid")
        #expect(guide.id == "coop.raid")
        let ids = Set(guide.sections.map(\.id))
        #expect(ids == ["overview", "shield", "expose", "enrage", "hearts", "winning"])
        #expect(guide.sections.allSatisfy { !$0.titleKey.isEmpty && !$0.bodyKey.isEmpty })
        #expect(guide.sections.allSatisfy { L10n.string($0.titleKey) != $0.titleKey })
    }
}
