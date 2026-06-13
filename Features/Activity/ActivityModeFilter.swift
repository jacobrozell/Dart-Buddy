import Foundation

/// Shared mode filter for Activity (History + Statistics segments).
///
/// Raw values mirror `MatchType` raw values (plus `all`) so per-mode lookups —
/// catalog entry, title, visibility — derive from the catalog instead of
/// hand-maintained switches now that the mode count is large.
enum ActivityModeFilter: String, CaseIterable, Identifiable, Hashable {
    case all
    case x01
    case cricket
    case baseball
    case killer
    case shanghai
    case americanCricket
    case mickeyMouse
    case mulligan
    case englishCricket
    case blindKiller
    case knockout
    case suddenDeath
    case fiftyOneByFives
    case golf
    case football
    case grandNational
    case hareAndHounds
    case followTheLeader
    case loop
    case prisoner
    case scam
    case snooker
    case ticTacToe
    case aroundTheClock
    case aroundTheClock180
    case chaseTheDragon
    case nineLives
    case fleet
    case bobs27
    case halveIt

    var id: String { rawValue }

    var matchType: MatchType? {
        self == .all ? nil : MatchType(rawValue: rawValue)
    }

    var catalogEntryId: String? {
        guard let matchType else { return nil }
        guard let entry = GameModeCatalog.entry(for: matchType), entry.isAvailable else { return nil }
        return entry.id
    }

    var title: String {
        guard let matchType else { return L10n.string("history.filter.allGames") }
        return MatchConfigText.modeLabel(for: matchType)
    }

    static func from(catalogEntryId: String) -> ActivityModeFilter? {
        allCases.first { $0.catalogEntryId == catalogEntryId }
    }

    /// Filters shown in Activity UI for the current product surface.
    static var visibleCases: [ActivityModeFilter] {
        allCases.filter { filter in
            guard let matchType = filter.matchType else { return true }
            guard let entry = GameModeCatalog.entry(for: matchType) else { return false }
            if entry.section == .party { return ProductSurface.showsPartyModes }
            return true
        }
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
