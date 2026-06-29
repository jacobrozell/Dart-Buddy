import Foundation

/// Generic roadmap buckets for the feedback priority poll.
enum FeedbackMostWantedFeature: String, CaseIterable, Identifiable {
    case morePartyGameModes
    case moreCoopGameModes
    case morePracticeGameModes
    case moreStandardGameModes
    case onlinePlay
    case accessibility
    case achievementsAndProgress
    case widgetsAndWatch
    case autoScoring
    case iPadLayout
    case somethingElse
    case notSure

    var id: String { rawValue }

    var label: String {
        L10n.string("feedback.mostWanted.\(rawValue)")
    }

    var mailLabel: String { label }

    static var pickerOptions: [FeedbackMostWantedFeature] {
        allCases.filter { $0 != .notSure } + [.notSure]
    }
}
