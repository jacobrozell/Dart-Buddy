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
    func shippedModesLiveInStandardOrPartySections() {
        for entry in GameModeCatalog.available {
            #expect(entry.section == .standard || entry.section == .party)
        }
    }

    @Test
    func practiceSectionContainsOnlyPlannedModesToday() {
        let practice = GameModeCatalog.entries(in: .practice)
        #expect(!practice.isEmpty)
        #expect(practice.allSatisfy { !$0.isAvailable })
    }
}
