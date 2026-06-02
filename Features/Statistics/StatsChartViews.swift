import Charts
import SwiftUI

struct SectorHitsChart: View {
    let hitsBySector: [String: Int]
    let mode: MatchType
    var height: CGFloat = 200

    private var hits: [SectorHit] {
        hitsBySector
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
                        x: .value("Sector", StatsSectorOrder.label(hit.sector)),
                        y: .value("Hits", hit.count)
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
        hits.map { "\(StatsSectorOrder.label($0.sector)): \($0.count)" }.joined(separator: ", ")
    }
}

struct PlayerAverageChart: View {
    let average: Double
    let playerName: String

    var body: some View {
        Chart {
            BarMark(
                x: .value("Average", average),
                y: .value("Player", playerName)
            )
            .foregroundStyle(Brand.green)
            .annotation(position: .trailing) {
                Text(String(format: "%.1f", average))
                    .font(.caption2)
                    .foregroundStyle(Brand.textSecondary)
            }
        }
        .chartXAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(Brand.textSecondary) } }
        .chartYAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(.white) } }
        .frame(height: 72)
        .padding(DS.Spacing.s4)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "stats.threeDartAverage"))
        .accessibilityValue(String(format: "%.1f", average))
    }
}
