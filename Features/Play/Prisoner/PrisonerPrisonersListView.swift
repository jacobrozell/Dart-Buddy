import SwiftUI

struct PrisonerPrisonersListView: View {
    struct Row: Identifiable, Equatable {
        let id: Int
        let segmentLabel: String
        let ownerName: String
    }

    let rows: [Row]

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Text(L10n.string("play.prisoner.prisonersOnBoardTitle"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.textSecondary)
            if rows.isEmpty {
                Text(L10n.string("play.prisoner.noPrisoners"))
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
            } else {
                ForEach(rows) { row in
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(Brand.redAccent)
                        Text(L10n.format("play.prisoner.prisonerOnBoardFormat", row.segmentLabel, row.ownerName))
                            .font(.subheadline)
                            .foregroundStyle(Brand.textPrimary)
                        Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.s3)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(boardAccessibilityLabel)
    }

    private var boardAccessibilityLabel: String {
        if rows.isEmpty {
            return L10n.string("play.prisoner.noPrisoners")
        }
        let summary = rows.map { "\($0.segmentLabel) \($0.ownerName)" }.joined(separator: ", ")
        return L10n.format("play.prisoner.boardOverlayAccessibilityFormat", summary)
    }
}
