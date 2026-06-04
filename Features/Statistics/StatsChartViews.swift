import Charts
import SwiftUI

struct SectorHitsChart: View {
    let hitsBySector: [String: Int]
    let mode: MatchType
    var height: CGFloat = 200

    private var hits: [SectorHit] {
        var merged: [String: Int] = [:]
        for (sector, count) in hitsBySector {
            let key = StatsSectorOrder.normalizedSectorKey(sector)
            merged[key, default: 0] += count
        }
        return merged
            .map { SectorHit(sector: $0.key, count: $0.value) }
            .sorted { StatsSectorOrder.rank($0.sector, mode: mode) < StatsSectorOrder.rank($1.sector, mode: mode) }
    }

    var body: some View {
        Group {
            if hits.isEmpty {
                Text(L10n.statsNoDartData)
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.s4)
            } else {
                Chart(hits) { hit in
                    BarMark(
                        x: .value(L10n.string("stats.chart.axis.sector"), StatsSectorOrder.label(hit.sector, mode: mode)),
                        y: .value(L10n.string("stats.chart.axis.hits"), hit.count)
                    )
                    .foregroundStyle(Brand.green)
                }
                .chartXAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(Brand.textSecondary) } }
                .chartYAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(Brand.textSecondary) } }
                .frame(height: height)
                .padding(DS.Spacing.s4)
                .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(String(localized: "stats.hitsInSector"))
                .accessibilityValue(sectorAccessibilityValue)
            }
        }
    }

    private var sectorAccessibilityValue: String {
        hits.map { "\(StatsSectorOrder.label($0.sector, mode: mode)): \($0.count)" }.joined(separator: ", ")
    }
}

struct PerPlayerSectorHitsSection: View {
    let breakdowns: [PlayerStatBreakdown]
    let mode: MatchType

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
            ForEach(breakdowns.filter { !$0.hitsBySector.isEmpty }) { row in
                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                    Text(row.name)
                        .font(.headline)
                        .foregroundStyle(Brand.textPrimary)
                    SectorHitsChart(
                        hitsBySector: row.hitsBySector,
                        mode: mode,
                        height: min(180, CGFloat(max(row.hitsBySector.count, 4)) * 28)
                    )
                    .accessibilityIdentifier("gameDetail_sectorChart_\(row.playerId.uuidString)")
                }
            }
        }
    }
}

struct AverageTrendChart: View {
    let points: [StatsTrendPoint]

    var body: some View {
        Chart(points) { point in
            LineMark(
                x: .value(L10n.string("stats.chart.axis.date"), point.date),
                y: .value(L10n.string("stats.chart.axis.average"), point.average3Dart)
            )
            .foregroundStyle(Brand.green)
            .interpolationMethod(.catmullRom)
            PointMark(
                x: .value(L10n.string("stats.chart.axis.date"), point.date),
                y: .value(L10n.string("stats.chart.axis.average"), point.average3Dart)
            )
            .foregroundStyle(Brand.green)
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(Brand.textSecondary)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel().foregroundStyle(Brand.textSecondary)
            }
        }
        .frame(height: 200)
        .padding(DS.Spacing.s4)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "stats.trend.title"))
        .accessibilityValue(trendAccessibilityValue)
    }

    private var trendAccessibilityValue: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return points.map { point in
            L10n.format(
                "stats.trend.accessibilityPointFormat",
                formatter.string(from: point.date),
                point.average3Dart
            )
        }.joined(separator: ", ")
    }
}

struct PlayerAverageChart: View {
    let average: Double
    let playerName: String

    var body: some View {
        Chart {
            BarMark(
                x: .value(L10n.string("stats.chart.axis.average"), average),
                y: .value(L10n.string("stats.chart.axis.player"), playerName)
            )
            .foregroundStyle(Brand.green)
            .annotation(position: .trailing) {
                Text(String(format: "%.1f", average))
                    .font(.caption2)
                    .foregroundStyle(Brand.textSecondary)
            }
        }
        .chartXAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(Brand.textSecondary) } }
        .chartYAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(Brand.textPrimary) } }
        .frame(height: 72)
        .padding(DS.Spacing.s4)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "stats.threeDartAverage"))
        .accessibilityValue(String(format: "%.1f", average))
    }
}
