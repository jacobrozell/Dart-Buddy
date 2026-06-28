import SwiftUI

/// Reusable striped table that lists players in a leading column with trailing numeric columns.
struct StatTable: View {
    var title: String?
    let columns: [(label: String, width: CGFloat)]
    let rows: [PlayerStatBreakdown]
    let values: (PlayerStatBreakdown) -> [String]
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        title: String? = nil,
        columns: [(label: String, width: CGFloat)],
        rows: [PlayerStatBreakdown],
        values: @escaping (PlayerStatBreakdown) -> [String]
    ) {
        self.title = title
        self.columns = columns
        self.rows = rows
        self.values = values
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            if let title {
                Text(title)
                    .font(tableTitleFont.weight(.bold))
                    .foregroundStyle(Brand.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
            }
            if dynamicTypeSize.isAccessibilitySize {
                accessibilityTableBody
            } else {
                compactTableBody
            }
        }
    }

    private var tableTitleFont: Font {
        dynamicTypeSize.isAccessibilitySize ? .headline : .title2
    }

    private var accessibilityTableBody: some View {
        VStack(spacing: DS.Spacing.s2) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                accessibilityRow(index: index, row: row)
            }
        }
    }

    private func accessibilityRow(index: Int, row: PlayerStatBreakdown) -> some View {
        let cells = values(row)
        return VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Text("\(index + 1). \(row.name)")
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(Array(columns.enumerated()), id: \.offset) { columnIndex, column in
                HStack(alignment: .firstTextBaseline) {
                    Text(column.label)
                        .foregroundStyle(Brand.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(columnIndex < cells.count ? cells[columnIndex] : "-")
                        .foregroundStyle(Brand.textPrimary)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DS.Spacing.s3)
        .padding(.vertical, DS.Spacing.s3)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rowAccessibilityLabel(index: index, row: row, cells: cells))
    }

    private var compactTableBody: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L10n.statsTablePlayersColumn).frame(maxWidth: .infinity, alignment: .leading)
                ForEach(columns, id: \.label) { column in
                    Text(column.label)
                        .frame(minWidth: resolvedColumnWidth(column.width), alignment: .trailing)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Brand.textBodyOnCard)
            .padding(.horizontal, DS.Spacing.s3)
            .padding(.vertical, DS.Spacing.s2)
            .accessibilityHidden(true)

            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                let cells = values(row)
                HStack {
                    Text("\(index + 1). \(row.name)")
                        .foregroundStyle(Brand.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(1)
                    ForEach(Array(columns.enumerated()), id: \.offset) { columnIndex, column in
                        Text(columnIndex < cells.count ? cells[columnIndex] : "-")
                            .frame(minWidth: resolvedColumnWidth(column.width), alignment: .trailing)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .foregroundStyle(Brand.textPrimary)
                    }
                }
                .font(.subheadline)
                .padding(.horizontal, DS.Spacing.s3)
                .padding(.vertical, DS.Spacing.s3)
                .background(index.isMultiple(of: 2) ? Color.clear : Brand.cardElevated.opacity(0.4))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(rowAccessibilityLabel(index: index, row: row, cells: cells))
            }
        }
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    private func rowAccessibilityLabel(index: Int, row: PlayerStatBreakdown, cells: [String]) -> String {
        let stats = zip(columns.map(\.label), cells).map { "\($0) \($1)" }.joined(separator: ", ")
        return L10n.format("stats.table.row.accessibilityFormat", index + 1, row.name, stats)
    }

    private func resolvedColumnWidth(_ base: CGFloat) -> CGFloat {
        horizontalSizeClass == .regular ? max(base, base * 1.2) : base
    }
}
