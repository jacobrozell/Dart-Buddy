import Foundation

/// Shared mode filter for Activity (History + Statistics segments).
enum ActivityModeFilter: String, CaseIterable, Identifiable, Hashable {
    case all
    case x01
    case cricket
    case baseball
    case killer
    case shanghai

    var id: String { rawValue }

    var matchType: MatchType? {
        switch self {
        case .all: nil
        case .x01: .x01
        case .cricket: .cricket
        case .baseball: .baseball
        case .killer: .killer
        case .shanghai: .shanghai
        }
    }

    var catalogEntryId: String? {
        switch self {
        case .all: nil
        case .x01: "standard.x01"
        case .cricket: "standard.cricket"
        case .baseball: "party.baseball"
        case .killer: "party.killer"
        case .shanghai: "party.shanghai"
        }
    }

    var title: String {
        switch self {
        case .all: L10n.string("history.filter.allGames")
        case .x01: L10n.string("play.x01.title")
        case .cricket: L10n.string("play.cricket.title")
        case .baseball: L10n.string("play.baseball.title")
        case .killer: L10n.string("play.killer.title")
        case .shanghai: L10n.string("play.shanghai.title")
        }
    }

    static func from(catalogEntryId: String) -> ActivityModeFilter? {
        allCases.first { $0.catalogEntryId == catalogEntryId }
    }
}

/// Shared time period filter for Activity segments.
enum ActivityPeriod: String, CaseIterable, Identifiable, Hashable {
    case today
    case d7
    case d30
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: L10n.string("stats.period.today")
        case .d7: L10n.string("stats.period.7d")
        case .d30: L10n.string("stats.period.30d")
        case .all: L10n.string("stats.period.all")
        }
    }

    var startedAfter: Date? {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .all: return nil
        case .today: return calendar.startOfDay(for: now)
        case .d7: return calendar.date(byAdding: .day, value: -7, to: now)
        case .d30: return calendar.date(byAdding: .day, value: -30, to: now)
        }
    }
}
