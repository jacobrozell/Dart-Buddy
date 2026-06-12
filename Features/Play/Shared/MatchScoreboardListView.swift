import SwiftUI

/// Shared row-list scoreboard chrome for the party modes whose scoreboard is a
/// simple "name + running total" list (Shanghai, Baseball). Per-mode views map
/// their rows into `Entry` and keep mode-specific copy and accessibility text.
struct MatchScoreboardListView: View {
    struct Entry: Identifiable {
        let id: UUID
        let name: String
        let totalText: String
        /// Optional secondary column (e.g. "This round: 12"); hidden when nil.
        let secondaryText: String?
        /// Localized "Leading" chip text; hidden when nil.
        let leadingText: String?
        let isActive: Bool
        let colorToken: PlayerColorToken
        let accessibilityLabel: String
    }

    let entries: [Entry]
    /// Prefix for `<prefix>_scoreboard_row_<index>` accessibility identifiers.
    let accessibilityIdentifierPrefix: String

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var usesLandscapeLayout: Bool {
        GameplayLayout.usesLandscapeMatchScoringLayout(verticalSizeClass: verticalSizeClass)
    }

    var body: some View {
        VStack(spacing: usesLandscapeLayout ? DS.Spacing.s3 : DS.Spacing.s2) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                HStack(spacing: DS.Spacing.s3) {
                    Circle()
                        .fill(PlayerVisualViews.color(for: entry.colorToken))
                        .frame(width: usesLandscapeLayout ? 12 : 10, height: usesLandscapeLayout ? 12 : 10)
                    Text(entry.name)
                        .font(rowNameFont(for: entry))
                        .foregroundStyle(Brand.textPrimary)
                        .lineLimit(1)
                    if let leadingText = entry.leadingText {
                        Text(leadingText)
                            .font(usesLandscapeLayout ? .caption.weight(.semibold) : .caption2.weight(.semibold))
                            .foregroundStyle(Brand.green)
                    }
                    Spacer()
                    if let secondaryText = entry.secondaryText {
                        Text(secondaryText)
                            .font(usesLandscapeLayout ? .subheadline : .caption)
                            .foregroundStyle(Brand.textSecondary)
                    }
                    Text(entry.totalText)
                        .font(usesLandscapeLayout ? .title2.weight(.bold) : .title3.weight(.bold))
                        .foregroundStyle(entry.isActive ? Brand.green : Brand.textPrimary)
                }
                .padding(.horizontal, usesLandscapeLayout ? DS.Spacing.s4 : DS.Spacing.s3)
                .padding(.vertical, usesLandscapeLayout ? DS.Spacing.s3 : DS.Spacing.s2)
                .background(entry.isActive ? Brand.cardElevated : Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(entry.accessibilityLabel)
                .accessibilityIdentifier("\(accessibilityIdentifierPrefix)_scoreboard_row_\(index)")
            }
        }
    }

    private func rowNameFont(for entry: Entry) -> Font {
        let emphasized = entry.isActive || entry.leadingText != nil
        return usesLandscapeLayout
            ? .body.weight(emphasized ? .bold : .regular)
            : .subheadline.weight(emphasized ? .bold : .regular)
    }
}

/// Shared round/inning progress dots: green for completed, amber-ringed for
/// current, dimmed for upcoming. Grows past `count` during extra rounds.
struct MatchProgressDotStrip: View {
    let count: Int
    let current: Int
    let accessibilityLabel: String

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1 ... max(count, current), id: \.self) { position in
                Circle()
                    .fill(fillColor(for: position))
                    .frame(width: 10, height: 10)
                    .overlay {
                        if position == current {
                            Circle().stroke(Brand.green, lineWidth: 2)
                        }
                    }
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private func fillColor(for position: Int) -> Color {
        if position < current { return Brand.green }
        if position == current { return Brand.amber }
        return Brand.textSecondary.opacity(0.35)
    }
}
