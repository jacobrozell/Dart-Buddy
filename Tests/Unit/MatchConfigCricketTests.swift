import Testing
@testable import DartBuddy

@Suite("Cricket match config", .tags(.unit, .cricket, .regression))
struct MatchConfigCricketTests {
    @Test
    func showsSetsOnBoardOnlyWhenSetsEnabled() {
        let legsOnly = MatchConfigCricket(legsToWin: 3, setsEnabled: false)
        #expect(legsOnly.showsSetsOnBoard == false)
        #expect(legsOnly.showsLegsOrSetsOnBoard == true)

        let withSets = MatchConfigCricket(legsToWin: 1, setsEnabled: true, setsToWin: 2)
        #expect(withSets.showsSetsOnBoard == true)
        #expect(withSets.showsLegsOrSetsOnBoard == true)

        let singleLeg = MatchConfigCricket(legsToWin: 1, setsEnabled: false)
        #expect(singleLeg.showsLegsOrSetsOnBoard == false)
    }

    @Test
    func legacyPayloadDefaultsCheckInAndLegFormat() {
        let config = MatchConfigX01(
            startScore: 501,
            legsToWin: 3,
            setsEnabled: false,
            setsToWin: nil,
            checkoutMode: .doubleOut
        )
        #expect(config.checkInMode == .straightIn)
        #expect(config.legFormat == .firstTo)
    }

    @Test
    func cricketScoringModeDefaultsToStandard() {
        let config = MatchConfigCricket()
        #expect(config.scoringMode == .standard)
        #expect(config.pointsEnabled == true)
        #expect(config.bullScoreValue == 25)
    }
}
