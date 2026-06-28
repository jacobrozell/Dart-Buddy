import Charts
import SwiftUI

private enum StatsChartStyle {
    static let barCornerRadius: CGFloat = 5
    static let cardPadding = DS.Spacing.s4
    static let gridOpacity: Double = 0.22

    static var horizontalBarFill: LinearGradient {
        LinearGradient(
            colors: [Brand.green.opacity(0.72), Brand.green],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var verticalBarFill: LinearGradient {
        LinearGradient(
            colors: [Brand.green, Brand.green.opacity(0.68)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var trendAreaFill: LinearGradient {
        LinearGradient(
            colors: [Brand.green.opacity(0.28), Brand.green.opacity(0.04)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private extension View {
    func statsChartPlotStyle() -> some View {
        chartPlotStyle { plotArea in
            plotArea
                .padding(.horizontal, DS.Spacing.s1)
                .padding(.top, DS.Spacing.s2)
                .padding(.bottom, DS.Spacing.s3)
        }
    }

    func statsValueAxis(desiredCount: Int = 4) -> some View {
        chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: desiredCount)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 4]))
                    .foregroundStyle(Brand.textSecondary.opacity(StatsChartStyle.gridOpacity))
                AxisValueLabel()
                    .foregroundStyle(Brand.textSecondary)
            }
        }
    }

    func statsSectorCategoryAxis() -> some View {
        chartXAxis {
            AxisMarks { _ in
                AxisValueLabel(centered: true)
                    .font(.caption2)
                    .foregroundStyle(Brand.textSecondary)
            }
        }
    }

    func statsHorizontalValueAxis(maxValue: Double) -> some View {
        chartXScale(domain: 0...(max(maxValue * 1.14, 1)))
            .chartXAxis {
                AxisMarks { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 4]))
                        .foregroundStyle(Brand.textSecondary.opacity(StatsChartStyle.gridOpacity))
                    AxisValueLabel()
                        .foregroundStyle(Brand.textSecondary)
                }
            }
    }
}

struct SectorHitsChart: View {
    let hitsBySector: [String: Int]
    let mode: MatchType
    /// Optional override for the bar plot area (excluding the x-axis label band).
    var plotHeight: CGFloat?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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

    private var maxHit: Int {
        hits.map(\.count).max() ?? 0
    }

    private var yUpperBound: Double {
        max(Double(maxHit) * 1.28 + 0.5, 1)
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
                let barPlotHeight = resolvedPlotHeight
                let labelBandHeight = resolvedLabelBandHeight
                let chartWidth = max(CGFloat(hits.count) * sectorSlotWidth + DS.Spacing.s6, 280)
                ScrollView(.horizontal, showsIndicators: false) {
                    Chart(hits) { hit in
                        BarMark(
                            x: .value(L10n.string("stats.chart.axis.sector"), StatsSectorOrder.label(hit.sector, mode: mode)),
                            y: .value(L10n.string("stats.chart.axis.hits"), hit.count)
                        )
                        .foregroundStyle(StatsChartStyle.verticalBarFill)
                        .cornerRadius(StatsChartStyle.barCornerRadius)
                        .annotation(position: .top, spacing: DS.Spacing.s1) {
                            if hit.count > 0 {
                                Text("\(hit.count)")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(Brand.textSecondary)
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                    .chartYScale(domain: 0...yUpperBound)
                    .statsSectorCategoryAxis()
                    .statsValueAxis()
                    .statsChartPlotStyle()
                    .frame(width: chartWidth, height: barPlotHeight + labelBandHeight)
                }
                .frame(height: barPlotHeight + labelBandHeight)
                .padding(StatsChartStyle.cardPadding)
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

    private var sectorSlotWidth: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 46 : 40
    }

    private var resolvedPlotHeight: CGFloat {
        if let plotHeight {
            return plotHeight
        }
        let base: CGFloat = 152
        return dynamicTypeSize.isAccessibilitySize ? base * 1.12 : base
    }

    private var resolvedLabelBandHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 42 : 34
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
                        .accessibilityAddTraits(.isHeader)
                    SectorHitsChart(
                        hitsBySector: row.hitsBySector,
                        mode: mode
                    )
                    .accessibilityIdentifier("gameDetail_sectorChart_\(row.playerId.uuidString)")
                }
            }
        }
    }
}

struct AverageTrendChart: View {
    let points: [StatsTrendPoint]

    private var yDomain: ClosedRange<Double> {
        let values = points.map(\.average3Dart)
        guard let minValue = values.min(), let maxValue = values.max() else {
            return 0...100
        }
        let padding = max((maxValue - minValue) * 0.18, 4)
        return max(0, minValue - padding)...(maxValue + padding)
    }

    var body: some View {
        Chart(points) { point in
            AreaMark(
                x: .value(L10n.string("stats.chart.axis.date"), point.date),
                y: .value(L10n.string("stats.chart.axis.average"), point.average3Dart)
            )
            .foregroundStyle(StatsChartStyle.trendAreaFill)
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value(L10n.string("stats.chart.axis.date"), point.date),
                y: .value(L10n.string("stats.chart.axis.average"), point.average3Dart)
            )
            .foregroundStyle(Brand.green)
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value(L10n.string("stats.chart.axis.date"), point.date),
                y: .value(L10n.string("stats.chart.axis.average"), point.average3Dart)
            )
            .symbolSize(44)
            .foregroundStyle(Brand.green)
            .annotation(position: .top, spacing: DS.Spacing.s1) {
                Text(String(format: "%.1f", point.average3Dart))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Brand.textSecondary)
                    .accessibilityHidden(true)
            }
        }
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 4]))
                    .foregroundStyle(Brand.textSecondary.opacity(StatsChartStyle.gridOpacity))
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(Brand.textSecondary)
            }
        }
        .statsValueAxis()
        .statsChartPlotStyle()
        .frame(height: 220)
        .padding(StatsChartStyle.cardPadding)
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

struct MultiPlayerAverageChart: View {
    let rows: [PlayerStatBreakdown]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var maxAverage: Double {
        rows.map(\.average3Dart).max() ?? 0
    }

    var body: some View {
        Chart(rows) { row in
            BarMark(
                x: .value(L10n.string("stats.chart.axis.average"), row.average3Dart),
                y: .value(L10n.string("stats.chart.axis.player"), row.name)
            )
            .foregroundStyle(StatsChartStyle.horizontalBarFill)
            .cornerRadius(StatsChartStyle.barCornerRadius)
            .annotation(position: .trailing, spacing: DS.Spacing.s1) {
                Text(String(format: "%.1f", row.average3Dart))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Brand.textSecondary)
                    .accessibilityHidden(true)
            }
        }
        .statsHorizontalValueAxis(maxValue: maxAverage)
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel(horizontalSpacing: DS.Spacing.s2)
                    .foregroundStyle(Brand.textPrimary)
            }
        }
        .statsChartPlotStyle()
        .frame(height: CGFloat(rows.count) * rowHeight + 28)
        .padding(StatsChartStyle.cardPadding)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "stats.section.averageHighest"))
        .accessibilityValue(accessibilityValue)
    }

    private var accessibilityValue: String {
        rows.map { row in
            L10n.format("stats.trend.accessibilityPointFormat", row.name, row.average3Dart)
        }.joined(separator: ", ")
    }

    private var rowHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 52 : 44
    }
}

struct PlayerAverageChart: View {
    let average: Double
    let playerName: String
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Chart {
            BarMark(
                x: .value(L10n.string("stats.chart.axis.average"), average),
                y: .value(L10n.string("stats.chart.axis.player"), playerName)
            )
            .foregroundStyle(StatsChartStyle.horizontalBarFill)
            .cornerRadius(StatsChartStyle.barCornerRadius)
            .annotation(position: .trailing, spacing: DS.Spacing.s1) {
                Text(String(format: "%.1f", average))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Brand.textSecondary)
                    .accessibilityHidden(true)
            }
        }
        .statsHorizontalValueAxis(maxValue: average)
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel(horizontalSpacing: DS.Spacing.s2)
                    .foregroundStyle(Brand.textPrimary)
            }
        }
        .statsChartPlotStyle()
        .frame(height: rowHeight + 28)
        .padding(StatsChartStyle.cardPadding)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "stats.threeDartAverage"))
        .accessibilityValue(String(format: "%.1f", average))
    }

    private var rowHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 52 : 44
    }
}
