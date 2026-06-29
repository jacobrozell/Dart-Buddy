import Foundation

/// What the player wants to suggest — drives form labels and email subject lines.
enum FeedbackCategory: String, CaseIterable, Identifiable {
    case gameMode
    case scoringRules
    case botOpponent
    case scoringUX
    case statsActivity
    case bug
    case improvement
    case other

    var id: String { rawValue }

    var label: String {
        L10n.string("feedback.category.\(rawValue).label")
    }

    var systemImage: String {
        switch self {
        case .gameMode: "gamecontroller.fill"
        case .scoringRules: "list.number"
        case .botOpponent: "cpu.fill"
        case .scoringUX: "hand.tap.fill"
        case .statsActivity: "chart.bar.fill"
        case .bug: "ladybug.fill"
        case .improvement: "lightbulb.fill"
        case .other: "ellipsis.circle.fill"
        }
    }

    var specificItemLabel: String {
        L10n.string("feedback.category.\(rawValue).specificItemLabel")
    }

    var specificItemPlaceholder: String {
        L10n.string("feedback.category.\(rawValue).specificItemPlaceholder")
    }

    var summaryPlaceholder: String {
        L10n.string("feedback.category.\(rawValue).summaryPlaceholder")
    }

    var detailsPlaceholder: String {
        L10n.string("feedback.category.\(rawValue).detailsPlaceholder")
    }

    var subjectTag: String {
        L10n.string("feedback.category.\(rawValue).subjectTag")
    }
}

struct FeedbackDraft: Equatable {
    var category: FeedbackCategory
    var specificItem: String
    var summary: String
    var details: String

    var trimmedSummary: String {
        summary.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isValid: Bool {
        !trimmedSummary.isEmpty
    }
}
