import SwiftUI

/// Template E — dual-track sequence progress display for Hare and Hounds.
///
/// Shows two rows sharing the same 20-segment clockwise course, each with a
/// distinct role badge and a marker at their current position.
struct HareAndHoundsDualTrackView: View {
    struct Row: Identifiable {
        let id: UUID
        let name: String
        let role: HareAndHoundsRole
        /// Index into `MatchConfigHareAndHounds.clockwiseCourse` (0 = segment 20).
        let positionIndex: Int
        let isActive: Bool
        let colorToken: PlayerColorToken
    }

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let rows: [Row]

    private static let course = MatchConfigHareAndHounds.clockwiseCourse

    private var usesLandscapeLayout: Bool {
        GameplayLayout.usesLandscapeMatchScoringLayout(verticalSizeClass: verticalSizeClass)
    }

    var body: some View {
        VStack(spacing: usesLandscapeLayout ? DS.Spacing.s4 : DS.Spacing.s3) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                    playerHeader(row: row)
                    trackStrip(row: row)
                }
                .padding(.horizontal, usesLandscapeLayout ? DS.Spacing.s4 : DS.Spacing.s3)
                .padding(.vertical, usesLandscapeLayout ? DS.Spacing.s3 : DS.Spacing.s2)
                .background(
                    row.isActive ? Brand.cardElevated : Brand.card,
                    in: RoundedRectangle(cornerRadius: DS.Radius.sm)
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(rowAccessibilityLabel(row))
                .accessibilityIdentifier("hareAndHounds_track_row_\(index)")
            }
        }
    }

    // MARK: - Subviews

    private func playerHeader(row: Row) -> some View {
        HStack(spacing: DS.Spacing.s2) {
            Circle()
                .fill(PlayerVisualViews.color(for: row.colorToken))
                .frame(
                    width: usesLandscapeLayout ? 12 : 10,
                    height: usesLandscapeLayout ? 12 : 10
                )
            Text(row.name)
                .font(usesLandscapeLayout
                    ? .body.weight(row.isActive ? .bold : .regular)
                    : .subheadline.weight(row.isActive ? .bold : .regular))
                .foregroundStyle(Brand.textPrimary)
                .lineLimit(1)
            roleBadge(for: row.role, isActive: row.isActive)
            Spacer()
            if row.positionIndex < Self.course.count {
                Text(L10n.format(
                    "play.hareAndHounds.trackPositionFormat",
                    roleName(row.role),
                    Self.course[row.positionIndex]
                ))
                .font(usesLandscapeLayout ? .caption.weight(.semibold) : .caption2.weight(.semibold))
                .foregroundStyle(row.isActive ? Brand.green : Brand.textSecondary)
            }
        }
    }

    private func roleBadge(for role: HareAndHoundsRole, isActive: Bool) -> some View {
        let key = role == .hare ? "role.hare" : "role.hound"
        let color: Color = role == .hare ? Brand.amber : Brand.key
        return Text(L10n.string(key))
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
    }

    private func trackStrip(row: Row) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: chipsPerRow),
            spacing: 4
        ) {
            ForEach(0 ..< Self.course.count, id: \.self) { idx in
                chipView(for: idx, row: row)
            }
        }
    }

    private func chipView(for idx: Int, row: Row) -> some View {
        let segment = Self.course[idx]
        let isCurrent = idx == row.positionIndex
        let isPast = idx < row.positionIndex
        let chipColor: Color = isPast
            ? Brand.green
            : (isCurrent ? Brand.amber : Brand.textSecondary.opacity(0.25))
        return Text("\(segment)")
            .font(.system(size: 9, weight: isCurrent ? .bold : .regular, design: .monospaced))
            .foregroundStyle(isPast || isCurrent ? Brand.background : Brand.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(chipColor, in: RoundedRectangle(cornerRadius: 4))
            .overlay {
                if isCurrent {
                    RoundedRectangle(cornerRadius: 4).stroke(Brand.green, lineWidth: 1.5)
                }
            }
            .accessibilityHidden(true)
    }

    // MARK: - Accessibility

    private func rowAccessibilityLabel(_ row: Row) -> String {
        let roleKey = row.role == .hare ? "role.hare" : "role.hound"
        let segment = row.positionIndex < Self.course.count
            ? Self.course[row.positionIndex]
            : Self.course[0]
        var parts: [String] = [
            row.name,
            L10n.string(roleKey),
            L10n.format("play.hareAndHounds.dualTrackAccessibilityFormat", segment),
        ]
        if row.isActive {
            parts.append(L10n.string("common.active"))
        }
        return parts.joined(separator: ", ")
    }

    // MARK: - Layout

    private var chipsPerRow: Int {
        usesLandscapeLayout ? 20 : 10
    }

    // MARK: - Helpers

    private func roleName(_ role: HareAndHoundsRole) -> String {
        let key = role == .hare ? "role.hare" : "role.hound"
        return L10n.string(key)
    }
}
