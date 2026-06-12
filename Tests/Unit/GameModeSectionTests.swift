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
}
