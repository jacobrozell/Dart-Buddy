import Foundation
import Testing
@testable import DartBuddy

@Suite("Match config analytics", .tags(.unit, .logging, .regression))
struct MatchConfigAnalyticsTests {
    @Test
    func metadataMapsX01Variants() {
        let metadata = MatchConfigAnalytics.metadata(
            for: .x01(
                MatchConfigX01(
                    startScore: 501,
                    legsToWin: 3,
                    setsEnabled: true,
                    setsToWin: 2,
                    checkoutMode: .doubleOut,
                    checkInMode: .masterIn,
                    legFormat: .bestOf
                )
            )
        )

        #expect(metadata["configStartScore"] == "501")
        #expect(metadata["configCheckoutMode"] == "doubleOut")
        #expect(metadata["configCheckInMode"] == "masterIn")
        #expect(metadata["configLegFormat"] == "bestOf")
        #expect(metadata["configSetsEnabled"] == "true")
    }

    @Test
    func metadataMapsCricketVariants() {
        let metadata = MatchConfigAnalytics.metadata(
            for: .cricket(
                MatchConfigCricket(
                    pointsEnabled: false,
                    scoringMode: .cutThroat,
                    legsToWin: 2,
                    setsEnabled: true,
                    setsToWin: 3,
                    legFormat: .firstTo
                )
            )
        )

        #expect(metadata["configPointsEnabled"] == "false")
        #expect(metadata["configScoringMode"] == "cutThroat")
        #expect(metadata["configSetsEnabled"] == "true")
    }

    @Test
    func metadataMapsBaseballVariants() {
        let metadata = MatchConfigAnalytics.metadata(
            for: .baseball(
                MatchConfigBaseball(
                    inningCount: 7,
                    tieBreaker: .bullPlayoff,
                    seventhInningStretch: true
                )
            )
        )

        #expect(metadata["configInningCount"] == "7")
        #expect(metadata["configTieBreaker"] == "bullPlayoff")
        #expect(metadata["configSeventhInningStretch"] == "true")
    }
}
