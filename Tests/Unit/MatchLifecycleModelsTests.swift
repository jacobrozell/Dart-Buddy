import Testing
@testable import DartBuddy

@Suite("Match lifecycle models", .tags(.unit, .x01, .cricket, .regression))
struct MatchLifecycleModelsTests {
    @Test
    func setupModeMapsToMatchType() {
        #expect(MatchSetupViewModel.SetupMode.x01.matchType == .x01)
        #expect(MatchSetupViewModel.SetupMode.cricket.matchType == .cricket)
    }

    @Test
    func x01OptionDisplayNamesAreLocalized() {
        for mode in X01CheckoutMode.allCases {
            #expect(!mode.displayName.isEmpty)
        }
        for mode in X01CheckInMode.allCases {
            #expect(!mode.displayName.isEmpty)
        }
        for format in X01LegFormat.allCases {
            #expect(!format.displayName.isEmpty)
        }
    }

    @Test
    func cricketScoringModesExposeDisplayNames() {
        for mode in CricketScoringMode.allCases {
            #expect(!mode.displayName.isEmpty)
        }
    }

    @Test
    func matchHistoryFilterDefaultsToAllMatches() {
        let filter = MatchHistoryFilter()
        #expect(filter.matchType == nil)
        #expect(filter.startedAfter == nil)
        #expect(filter.participantPlayerId == nil)
    }
}
