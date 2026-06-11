import Testing
@testable import DartBuddy

@Suite("Stats sector ordering", .tags(.unit, .stats, .regression))
struct StatsSectorOrderTests {
    @Test
    func missSectorNormalizesToZero() {
        #expect(StatsSectorOrder.normalizedSectorKey("miss") == StatsSectorOrder.missSectorKey)
        #expect(StatsSectorOrder.normalizedSectorKey("20") == "20")
    }

    @Test
    func cricketSectorsRankHighNumbersBeforeMissBeforeBull() {
        #expect(StatsSectorOrder.rank("20", mode: .cricket) < StatsSectorOrder.rank("15", mode: .cricket))
        #expect(StatsSectorOrder.rank("15", mode: .cricket) < StatsSectorOrder.rank(StatsSectorOrder.missSectorKey, mode: .cricket))
        #expect(StatsSectorOrder.rank(StatsSectorOrder.missSectorKey, mode: .cricket) < StatsSectorOrder.rank("innerBull", mode: .cricket))
    }

    @Test
    func x01SectorsRankTreblesBeforeSinglesBeforeBullBeforeMiss() {
        #expect(StatsSectorOrder.rank("20", mode: .x01) < StatsSectorOrder.rank("19", mode: .x01))
        #expect(StatsSectorOrder.rank("20", mode: .x01) < StatsSectorOrder.rank("1", mode: .x01))
        #expect(StatsSectorOrder.rank("20", mode: .x01) < StatsSectorOrder.rank("innerBull", mode: .x01))
        #expect(StatsSectorOrder.rank("1", mode: .x01) < StatsSectorOrder.rank(StatsSectorOrder.missSectorKey, mode: .x01))
    }

    @Test
    func baseballInningsRankNumerically() {
        #expect(StatsSectorOrder.rank("3", mode: .baseball) < StatsSectorOrder.rank("9", mode: .baseball))
        #expect(StatsSectorOrder.rank("innerBull", mode: .baseball) < StatsSectorOrder.rank(StatsSectorOrder.missSectorKey, mode: .baseball))
    }

    @Test
    func labelsUseLocalizedBullAndMissTokens() {
        #expect(StatsSectorOrder.label(StatsSectorOrder.missSectorKey, mode: .x01) == "0")
        #expect(StatsSectorOrder.label("innerBull", mode: .x01) == L10n.string("stats.sector.bull"))
        #expect(StatsSectorOrder.label("3", mode: .baseball) == L10n.format("stats.sector.inningFormat", 3))
    }
}
