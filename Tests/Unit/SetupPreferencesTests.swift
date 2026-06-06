import Foundation
import Testing
@testable import DartBuddy

@Suite("Setup preferences", .tags(.unit, .setupFlow, .regression))
struct SetupPreferencesTests {
    @Test
    func partyAndCricketPreferencesRoundTripAndClamp() {
        defer {
            BaseballSetupPreferences.clearStored()
            ShanghaiSetupPreferences.clearStored()
            CricketSetupPreferences.clearStored()
        }

        BaseballSetupPreferences.save(inningCount: 0, tieBreaker: .bullPlayoff, seventhInningStretch: true)
        let baseball = BaseballSetupPreferences.load()
        #expect(baseball.inningCount == 1)
        #expect(baseball.tieBreaker == .bullPlayoff)
        #expect(baseball.seventhInningStretch == true)

        ShanghaiSetupPreferences.save(roundCount: 99, bonusRule: .instantWin)
        let shanghai = ShanghaiSetupPreferences.load()
        #expect(shanghai.roundCount == 20)
        #expect(shanghai.bonusRule == .instantWin)

        CricketSetupPreferences.clearStored()
        let defaults = CricketSetupPreferences.load()
        #expect(defaults.pointsEnabled == true)
        #expect(defaults.scoringMode == .standard)

        CricketSetupPreferences.save(pointsEnabled: false, scoringMode: .cutThroat)
        let cutThroat = CricketSetupPreferences.load()
        #expect(cutThroat.pointsEnabled == false)
        #expect(cutThroat.scoringMode == .cutThroat)
    }
}
