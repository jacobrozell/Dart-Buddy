import SwiftUI

// MARK: - Scoreboard rows

struct MulliganScoreboardView: View {
    struct Row: Identifiable {
        let id: UUID
        let name: String
        let marksOnActiveTarget: Int
        let isActive: Bool
        let colorToken: PlayerColorToken
    }

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let rows: [Row]

    private var usesLandscapeLayout: Bool {
        GameplayLayout.usesLandscapeMatchScoringLayout(verticalSizeClass: verticalSizeClass)
    }

    var body: some View {
        VStack(spacing: usesLandscapeLayout ? DS.Spacing.s3 : DS.Spacing.s2) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                HStack(spacing: DS.Spacing.s3) {
                    Circle()
                        .fill(PlayerVisualViews.color(for: row.colorToken))
                        .frame(
                            width: usesLandscapeLayout ? 12 : 10,
                            height: usesLandscapeLayout ? 12 : 10
                        )
                    Text(row.name)
                        .font(
                            usesLandscapeLayout
                                ? .body.weight(row.isActive ? .bold : .regular)
                                : .subheadline.weight(row.isActive ? .bold : .regular)
                        )
                        .foregroundStyle(Brand.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    // Mark pips for active target
                    markPips(for: row)
                }
                .padding(.horizontal, usesLandscapeLayout ? DS.Spacing.s4 : DS.Spacing.s3)
                .padding(.vertical, usesLandscapeLayout ? DS.Spacing.s3 : DS.Spacing.s2)
                .background(
                    row.isActive ? Brand.cardElevated : Brand.card,
                    in: RoundedRectangle(cornerRadius: DS.Radius.sm)
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(rowAccessibilityLabel(row))
                .accessibilityIdentifier("mulligan_scoreboard_row_\(index)")
            }
        }
    }

    @ViewBuilder
    private func markPips(for row: Row) -> some View {
        HStack(spacing: 4) {
            ForEach(0 ..< 3, id: \.self) { pip in
                Circle()
                    .fill(pip < row.marksOnActiveTarget
                          ? PlayerVisualViews.accentColor(token: row.colorToken)
                          : Brand.textSecondary.opacity(0.25))
                    .frame(width: 10, height: 10)
            }
        }
        .accessibilityHidden(true)
    }

    private func rowAccessibilityLabel(_ row: Row) -> String {
        var parts = [row.name]
        parts.append(L10n.format("play.mulligan.marksAccessibilityFormat", row.marksOnActiveTarget))
        if row.isActive {
            parts.append(L10n.string("common.active"))
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Drawn target chips strip

/// Horizontal strip showing the drawn sequence; the active chip is highlighted.
struct MulliganTargetStrip: View {
    let sequence: [MulliganSegment]
    let currentIndex: Int
    let isComplete: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.s2) {
                ForEach(Array(sequence.enumerated()), id: \.offset) { index, segment in
                    chip(for: segment, at: index)
                }
            }
            .padding(.horizontal, DS.Spacing.s1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(stripAccessibilityLabel)
    }

    @ViewBuilder
    private func chip(for segment: MulliganSegment, at index: Int) -> some View {
        let state = chipState(at: index)
        Text(segment.displayLabel)
            .font(.subheadline.weight(state == .active ? .bold : .semibold))
            .monospacedDigit()
            .foregroundStyle(foreground(for: state))
            .padding(.horizontal, DS.Spacing.s3)
            .padding(.vertical, DS.Spacing.s2)
            .background(background(for: state), in: RoundedRectangle(cornerRadius: DS.Radius.sm))
            .overlay {
                if state == .active {
                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                        .stroke(Brand.amber, lineWidth: 2)
                }
            }
    }

    private enum ChipState { case done, active, upcoming }

    private func chipState(at index: Int) -> ChipState {
        if isComplete || index < currentIndex { return .done }
        if index == currentIndex { return .active }
        return .upcoming
    }

    private func foreground(for state: ChipState) -> Color {
        switch state {
        case .done: return Brand.textSecondary
        case .active: return Brand.amber
        case .upcoming: return Brand.textPrimary
        }
    }

    private func background(for state: ChipState) -> Color {
        switch state {
        case .done: return Brand.card.opacity(0.5)
        case .active: return Brand.cardElevated
        case .upcoming: return Brand.card
        }
    }

    private var stripAccessibilityLabel: String {
        guard currentIndex < sequence.count, !isComplete else {
            return L10n.string("play.mulligan.drawnTargets.title")
        }
        return L10n.format(
            "play.mulligan.activeTargetFormat",
            sequence[currentIndex].displayLabel
        )
    }
}
