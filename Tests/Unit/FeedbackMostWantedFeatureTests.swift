import Foundation
import Testing
@testable import DartBuddy

@Suite("Feedback most wanted", .tags(.unit, .settings))
struct FeedbackMostWantedFeatureTests {
    @Test
    func pickerOptionsEndWithNotSure() {
        let options = FeedbackMostWantedFeature.pickerOptions
        #expect(options.last == .notSure)
        #expect(options.contains(.moreCoopGameModes))
    }

    @Test
    func mailLabelMatchesLocalizedBucket() {
        let label = FeedbackMostWantedFeature.moreCoopGameModes.mailLabel
        #expect(label == L10n.string("feedback.mostWanted.moreCoopGameModes"))
    }
}
