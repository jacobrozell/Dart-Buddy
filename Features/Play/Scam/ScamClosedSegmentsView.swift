import SwiftUI

struct ScamClosedSegmentsView: View {
    let closedSegments: Set<Int>
    let highestOpenSegment: Int?

    private let segments = Array((1 ... 20).reversed())

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            if let highestOpenSegment {
                Text(L10n.format("play.scam.highestOpenSegmentFormat", highestOpenSegment))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.amber)
            }
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: DS.Spacing.s1), count: 5),
                spacing: DS.Spacing.s1
            ) {
                ForEach(segments, id: \.self) { segment in
                    segmentCell(segment)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(closedSegmentsAccessibilityLabel)
            .accessibilityIdentifier("scam_closed_segments")
        }
    }

    private func segmentCell(_ segment: Int) -> some View {
        let isClosed = closedSegments.contains(segment)
        let isTarget = highestOpenSegment == segment
        return Text("\(segment)")
            .font(.caption.weight(isTarget ? .bold : .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .foregroundStyle(isClosed ? Brand.textSecondary.opacity(0.45) : Brand.textPrimary)
            .background(
                isTarget ? Brand.amber.opacity(0.25) : Brand.card.opacity(isClosed ? 0.35 : 0.9),
                in: RoundedRectangle(cornerRadius: DS.Radius.xs)
            )
            .overlay {
                if isClosed {
                    RoundedRectangle(cornerRadius: DS.Radius.xs)
                        .strokeBorder(Brand.textSecondary.opacity(0.35), lineWidth: 1)
                }
            }
            .strikethrough(isClosed)
    }

    private var closedSegmentsAccessibilityLabel: String {
        L10n.format(
            "play.scam.closedSegmentsAccessibilityFormat",
            closedSegments.count,
            highestOpenSegment ?? 0
        )
    }
}
