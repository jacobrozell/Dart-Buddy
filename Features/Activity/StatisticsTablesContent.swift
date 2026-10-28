import SwiftUI

/// Statistics tables/charts extracted for Activity segment reuse.
struct StatisticsTablesContent: View {
    @ObservedObject var viewModel: StatisticsViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
            gamesTable
            if viewModel.isX01 {
                sectionTitle(L10n.string("stats.section.averageHighest"))
                averageTable
                MultiPlayerAverageChart(rows: viewModel.rows)
                if viewModel.showsTrendChart {
                    sectionTitle(L10n.string("stats.trend.title"))
                    AverageTrendChart(points: viewModel.trendPoints)
                }
                sectionTitle(L10n.string("stats.section.legsCheckout"))
                checkoutTable
            } else if !viewModel.isAllGames {
                sectionTitle(L10n.string("stats.section.marksPerRound"))
                mprTable
            }
            sectionTitle(L10n.string("stats.points"))
            pointsTable
            sectionTitle(L10n.string("stats.throws"))
            throwsTable
            if !viewModel.isAllGames, let matchType = viewModel.modeFilter.matchType {
                sectionTitle(L10n.string("stats.hitsInSector"))
                SectorHitsChart(hitsBySector: sectorHitsDictionary, mode: matchType)
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font((dynamicTypeSize.isAccessibilitySize ? Font.headline : Font.title2).weight(.bold))
            .foregroundStyle(Brand.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, DS.Spacing.s2)
    }

    private var gamesTable: some View {
        StatTable(
            title: L10n.string("stats.games"),
            columns: [(L10n.string("stats.games"), 70), (L10n.string("stats.wins"), 60), (L10n.string("stats.column.winsPercent"), 80)],
            rows: viewModel.rows
        ) { row in
            ["\(row.games)", "\(row.wins)", String(format: "%.0f%%", row.winPercent)]
        }
    }

    private var averageTable: some View {
        StatTable(
            columns: [(L10n.string("stats.threeDartAverage"), 90), (L10n.string("stats.column.highest"), 80)],
            rows: viewModel.rows
        ) { row in
            [String(format: "%.1f", row.average3Dart), "\(row.highestScore)"]
        }
    }

    private var checkoutTable: some View {
        StatTable(
            columns: [(L10n.string("stats.column.legs"), 60), (L10n.string("stats.checkouts"), 90), (L10n.string("stats.column.bestCO"), 80)],
            rows: viewModel.rows
        ) { row in
            ["\(row.legs)", "\(row.checkouts)", row.highestCheckout > 0 ? "\(row.highestCheckout)" : "-"]
        }
    }

    private var mprTable: some View {
        StatTable(
            columns: [(L10n.string("stats.mpr"), 80), (L10n.string("stats.marks"), 80), (L10n.string("stats.rounds"), 80)],
            rows: viewModel.rows
        ) { row in
            [
                String(format: "%.2f", row.marksPerRound),
                "\(row.cricketMarks)",
                "\(row.cricketRounds)"
            ]
        }
    }

    private var pointsTable: some View {
        StatTable(
            columns: [(L10n.string("stats.points"), 90)],
            rows: viewModel.rows
        ) { row in
            ["\(row.points)"]
        }
    }

    private var throwsTable: some View {
        StatTable(
            columns: [(L10n.string("stats.throws"), 70), (L10n.string("stats.doublePercent"), 80), (L10n.string("stats.triplePercent"), 80)],
            rows: viewModel.rows
        ) { row in
            ["\(row.darts)", String(format: "%.1f%%", row.doublePercent), String(format: "%.1f%%", row.triplePercent)]
        }
    }

    private var sectorHitsDictionary: [String: Int] {
        var totals: [String: Int] = [:]
        for row in viewModel.rows {
            for (sector, count) in row.hitsBySector {
                let key = StatsSectorOrder.normalizedSectorKey(sector)
                totals[key, default: 0] += count
            }
        }
        return totals
    }
}
