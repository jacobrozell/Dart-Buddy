import SwiftUI

struct MatchHistoryCard: View {
    let row: HistoryListRow
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            cardHeader
            Text(row.configText)
                .font(.subheadline)
                .foregroundStyle(Brand.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Array(row.standings.enumerated()), id: \.element.id) { index, standing in
                HStack(alignment: .center) {
                    Text("\(index + 1). \(standing.name)")
                        .font(.body.weight(standing.isWinner ? .semibold : .regular))
                        .foregroundStyle(standing.isWinner ? Brand.textPrimary : Brand.textSecondary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: DS.Spacing.s2)
                    VStack(alignment: .trailing, spacing: 0) {
                        if row.summary.type == .x01 {
                            Text(L10n.format("history.standing.setsLegsFormat", standing.sets, standing.legs))
                                .font(.caption)
                                .foregroundStyle(Brand.textSecondary)
                        }
                        Text("\(standing.score)")
                            .font(.title3.weight(.bold))
                            .monospacedDigit()
                            .foregroundStyle(standing.isWinner ? Brand.textPrimary : Brand.textSecondary)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(DS.Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var cardHeader: some View {
        ViewThatFits(in: .horizontal) {
            compactHeader
            stackedHeader
        }
    }

    private var compactHeader: some View {
        HStack(spacing: DS.Spacing.s2) {
            GameModeBadge(type: row.summary.type)
            Text(row.dateText)
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)
            Spacer(minLength: DS.Spacing.s2)
            statusBadge
        }
    }

    private var stackedHeader: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            HStack(spacing: DS.Spacing.s2) {
                GameModeBadge(type: row.summary.type)
                Text(row.dateText)
                    .font(.headline)
                    .foregroundStyle(Brand.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            statusBadge
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        if row.isForfeited {
            StatusBadge(text: L10n.string("history.status.forfeit"), color: Brand.amber)
        } else if row.isFinished {
            StatusBadge(text: L10n.string("history.status.finished"), color: Brand.green)
        }
    }
}
