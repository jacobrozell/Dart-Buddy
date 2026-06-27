import SwiftUI

struct BlindKillerSegmentGridView: View {
    let hitCounts: [Int]
    let threshold: Int

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 5)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(1 ... 20, id: \.self) { segment in
                let hits = hitCounts.indices.contains(segment) ? hitCounts[segment] : 0
                VStack(spacing: 2) {
                    Text("\(segment)")
                        .font(.caption.weight(.semibold))
                    HStack(spacing: 3) {
                        ForEach(0 ..< threshold, id: \.self) { index in
                            Circle()
                                .fill(index < hits ? Brand.red : Brand.textSecondary.opacity(0.25))
                                .frame(width: 6, height: 6)
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                .accessibilityLabel(
                    L10n.format("play.blindKiller.anonymousTallyAccessibilityFormat", segment, hits, threshold)
                )
                .accessibilityIdentifier("blind_killer_segment_\(segment)")
            }
        }
    }
}
