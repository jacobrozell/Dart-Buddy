import Foundation
import Testing
@testable import DartBuddy

@Suite("Player aggregate stats", .tags(.unit, .stats, .regression))
struct PlayerAggregateStatsTests {
    @Test
    func defaultsToZeroCounts() {
        let stats = PlayerAggregateStats()
        #expect(stats.matchesPlayed == 0)
        #expect(stats.matchesWon == 0)
        #expect(stats.x01Average3Dart == 0)
        #expect(stats.cricketWins == 0)
        #expect(stats.lastPlayedAt == nil)
    }

    @Test
    func initializerStoresProvidedValues() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let stats = PlayerAggregateStats(
            matchesPlayed: 10,
            matchesWon: 4,
            x01Average3Dart: 55.5,
            cricketWins: 2,
            lastPlayedAt: date
        )
        #expect(stats.matchesPlayed == 10)
        #expect(stats.matchesWon == 4)
        #expect(stats.x01Average3Dart == 55.5)
        #expect(stats.cricketWins == 2)
        #expect(stats.lastPlayedAt == date)
    }
}

@Suite("Stats trend point", .tags(.unit, .stats, .regression))
struct StatsTrendPointTests {
    @Test
    func storesIdentityFields() {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 2_000_000)
        let point = StatsTrendPoint(id: id, date: date, average3Dart: 62.5)
        #expect(point.id == id)
        #expect(point.date == date)
        #expect(point.average3Dart == 62.5)
    }
}

@Suite("Firebase analytics event", .tags(.unit, .logging, .regression))
struct FirebaseAnalyticsEventTests {
    @Test
    func storesNameAndParameters() {
        let event = FirebaseAnalyticsEvent(name: "match_started", parameters: ["matchType": "x01"])
        #expect(event.name == "match_started")
        #expect(event.parameters["matchType"] == "x01")
    }

    @Test
    func equatableComparesAllFields() {
        let lhs = FirebaseAnalyticsEvent(name: "app_open", parameters: ["deviceClass": "iphone"])
        let rhs = FirebaseAnalyticsEvent(name: "app_open", parameters: ["deviceClass": "iphone"])
        #expect(lhs == rhs)
    }
}
