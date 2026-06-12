import Foundation
import Testing
@testable import DartBuddy

@Suite("Activity filters", .tags(.unit, .history, .stats, .regression))
struct ActivityFilterTests {
    @Test
    func modeFilterMapsShippedModesToMatchTypes() {
        #expect(ActivityModeFilter.all.matchType == nil)
        #expect(ActivityModeFilter.x01.matchType == .x01)
        #expect(ActivityModeFilter.cricket.matchType == .cricket)
        #expect(ActivityModeFilter.baseball.matchType == .baseball)
        #expect(ActivityModeFilter.killer.matchType == .killer)
        #expect(ActivityModeFilter.shanghai.matchType == .shanghai)
    }

    @Test
    func modeFilterCatalogIdsRoundTripForShippedModes() throws {
        for filter in ActivityModeFilter.allCases where filter != .all {
            guard let catalogId = filter.catalogEntryId else { continue }
            #expect(ActivityModeFilter.from(catalogEntryId: catalogId) == filter)
            #expect(GameModeCatalog.entry(for: catalogId)?.matchType == filter.matchType)
        }
    }

    @Test
    func modeFilterTitlesAreLocalized() {
        for filter in ActivityModeFilter.allCases {
            #expect(!filter.title.isEmpty)
        }
    }

    @Test
    func modeFilterVisibleCasesRespectProductSurface() {
        let visible = Set(ActivityModeFilter.visibleCases)
        #expect(visible.contains(.all))
        #expect(visible.contains(.x01))
        #expect(visible.contains(.cricket))

        if ProductSurface.showsPartyModes {
            #expect(visible.contains(.baseball))
            #expect(visible.contains(.killer))
            #expect(visible.contains(.shanghai))
        } else {
            #expect(!visible.contains(.baseball))
            #expect(!visible.contains(.killer))
            #expect(!visible.contains(.shanghai))
        }
    }

    @Test
    func availableCatalogModesMatchVisibleActivityFilters() {
        let availableFilterIds = Set(
            GameModeCatalog.available.compactMap { ActivityModeFilter.from(catalogEntryId: $0.id)?.rawValue }
        )
        let visibleFilterIds = Set(
            ActivityModeFilter.visibleCases.map(\.rawValue).filter { $0 != ActivityModeFilter.all.rawValue }
        )
        #expect(availableFilterIds == visibleFilterIds)
    }

    @Test
    func periodAllHasNoCutoff() {
        #expect(ActivityPeriod.all.startedAfter == nil)
    }

    @Test
    func periodCutoffsAreOrderedAndNotInTheFuture() throws {
        let now = Date()
        let today = try #require(ActivityPeriod.today.startedAfter)
        let d7 = try #require(ActivityPeriod.d7.startedAfter)
        let d30 = try #require(ActivityPeriod.d30.startedAfter)

        #expect(d30 <= d7)
        #expect(d7 <= today)
        #expect(today <= now)
    }

    @Test
    func periodTitlesAreLocalized() {
        for period in ActivityPeriod.allCases {
            #expect(!period.title.isEmpty)
        }
    }

    @Test
    func historyListRowAccessibilitySummaryIncludesDateConfigAndStandings() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let summary = MatchSummary(
            id: UUID(),
            type: .x01,
            status: .completed,
            startedAt: now,
            endedAt: now,
            winnerPlayerId: UUID(),
            currentTurnPlayerId: nil,
            currentLegIndex: 0,
            currentSetIndex: 0,
            eventCount: 4,
            createdAt: now,
            updatedAt: now
        )
        let row = HistoryListRow(
            summary: summary,
            dateText: "06.06.2026 12:00",
            configText: "501 · Double Out",
            standings: [
                HistoryStanding(id: UUID(), name: "Alice", isWinner: true, sets: 0, legs: 1, score: 0),
                HistoryStanding(id: UUID(), name: "Bob", isWinner: false, sets: 0, legs: 0, score: 121)
            ],
            isFinished: true,
            isForfeited: false
        )

        let accessibility = row.accessibilitySummary
        #expect(accessibility.contains("06.06.2026 12:00"))
        #expect(accessibility.contains("501 · Double Out"))
        #expect(accessibility.contains("Alice"))
        #expect(accessibility.contains("Bob"))
        #expect(accessibility.contains("121"))
    }
}
