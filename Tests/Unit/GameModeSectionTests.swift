import Testing
@testable import DartBuddy

@Suite("Game mode sections", .tags(.unit, .setupFlow, .regression))
struct GameModeSectionTests {
    @Test
    func sectionTitleKeysResolve() {
        for section in GameModeSection.allCases {
            #expect(!L10n.string(section.titleKey).isEmpty)
            #expect(section.titleKey == "modes.section.\(section.rawValue)")
        }
    }

    @Test
    func shippedModesHaveValidSections() {
        for entry in GameModeCatalog.available {
            #expect(GameModeSection.allCases.contains(entry.section))
        }
    }

    @Test
    func practiceSectionContainsShippedDrillsOnDev() {
        let practice = GameModeCatalog.entries(in: .practice)
        #expect(!practice.isEmpty)
        #expect(practice.contains { $0.isAvailable })
    }

    @Test
    func coopSectionListsRaidAndPlannedModes() {
        let coop = GameModeCatalog.entries(in: .coop)
        #expect(coop.count == 4)
        #expect(coop.map(\.id) == [
            "coop.raid",
            "coop.cerberus",
            "coop.theVault",
            "coop.clearTheBoard"
        ])
        #expect(coop.filter(\.isAvailable).map(\.id) == ["coop.raid"])
        #expect(coop.filter { !$0.isAvailable }.count == 3)
    }
}
