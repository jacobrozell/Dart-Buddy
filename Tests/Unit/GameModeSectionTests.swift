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
    func coopSectionContainsShippedRaidAndPlannedModes() {
        let coop = GameModeCatalog.entries(in: .coop)
        #expect(coop.count == 4)
        #expect(coop.map(\.id) == [
            "coop.raid",
            "coop.cerberus",
            "coop.theVault",
            "coop.clearTheBoard"
        ])
        let raid = coop.first { $0.id == "coop.raid" }
        #expect(raid?.isAvailable == true)
        #expect(coop.filter { $0.id != "coop.raid" }.allSatisfy { !$0.isAvailable })
    }
}
