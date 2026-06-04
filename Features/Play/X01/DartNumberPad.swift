import SwiftUI

/// Per-dart entry pad matching the reference scoreboard: a grid of 1-20 plus
/// the bull (25), with sticky DOUBLE / TRIPLE modifiers, a miss (0) key, and an
/// undo key. Tapping a number appends a dart to the current visit (max 3).
struct DartNumberPad: View {
    @Binding var enteredDarts: [DartInput]
    @Binding var selectedMultiplier: DartMultiplier
    /// When set, only this segment (and optionally bull) accepts scoring input.
    var lockedSegment: Int? = nil
    var showsBull: Bool = true
    /// Called when undo is tapped with an empty in-progress visit to revert the last accepted throw.
    let onUndoTurn: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var keyMinHeight: CGFloat = 52

    private var usesAccessibilityLayout: Bool {
        GameplayLayout.usesAccessibilityMatchScoringLayout(dynamicTypeSize: dynamicTypeSize)
    }

    private var padSpacing: CGFloat {
        usesAccessibilityLayout ? ScoringPadStyle.accessibilitySpacing : ScoringPadStyle.compactSpacing
    }

    private var displayKeyMinHeight: CGFloat {
        usesAccessibilityLayout ? min(keyMinHeight, 56) : keyMinHeight
    }

    private let compactRows: [[Int]] = [
        [1, 2, 3, 4, 5, 6, 7],
        [8, 9, 10, 11, 12, 13, 14],
        [15, 16, 17, 18, 19, 20, 25]
    ]

    private var visibleCompactRows: [[Int]] {
        compactRows.map { row in
            row.filter { value in
                if value == 25 { return showsBull }
                return isSegmentEnabled(value)
            }
        }.filter { !$0.isEmpty }
    }

    private var visibleAccessibilitySegments: [Int] {
        accessibilitySegments.filter { value in
            if value == 25 { return showsBull }
            return isSegmentEnabled(value)
        }
    }

    private let accessibilitySegments: [Int] = Array(1 ... 20) + [25]

    var body: some View {
        if usesAccessibilityLayout {
            accessibilityPad
        } else {
            compactPad
        }
    }

    private var compactPad: some View {
        VStack(spacing: padSpacing) {
            ForEach(visibleCompactRows, id: \.self) { row in
                HStack(spacing: padSpacing) {
                    ForEach(row, id: \.self) { value in
                        numberKey(value)
                    }
                }
            }
            controlRow
        }
    }

    private var accessibilityPad: some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: padSpacing),
            count: GameplayLayout.scoringPadColumnCount(dynamicTypeSize: dynamicTypeSize)
        )
        return VStack(spacing: padSpacing) {
            LazyVGrid(columns: columns, spacing: padSpacing) {
                ForEach(visibleAccessibilitySegments, id: \.self) { value in
                    numberKey(value)
                }
            }
            controlRow
        }
    }

    private var controlRow: some View {
        HStack(spacing: padSpacing) {
            ScoringPadKey(
                title: "0",
                minHeight: displayKeyMinHeight,
                accessibilityLabel: DartInput.padKeyAccessibilityLabel(segmentValue: 0, armedMultiplier: .single),
                accessibilityHint: L10n.string("scoring.segment.hint"),
                identifier: "pad_0",
                action: appendMiss
            )
            modifierKey(.double, identifier: "pad_double")
            modifierKey(.triple, identifier: "pad_triple")
            ScoringPadIconKey(
                systemImage: "arrow.uturn.backward",
                minHeight: displayKeyMinHeight,
                accessibilityLabel: L10n.string("scoring.undoLastTurn"),
                identifier: "pad_undo",
                action: undo
            )
        }
    }

    private func numberKey(_ value: Int) -> some View {
        let enabled = value == 25 ? showsBull : isSegmentEnabled(value)
        return ScoringPadKey(
            title: String(value),
            font: usesAccessibilityLayout ? .title3.weight(.semibold) : .body.weight(.semibold),
            minHeight: displayKeyMinHeight,
            accessibilityLabel: DartInput.padKeyAccessibilityLabel(
                segmentValue: value,
                armedMultiplier: selectedMultiplier
            ),
            accessibilityHint: L10n.string("scoring.segment.hint"),
            identifier: "pad_\(value)",
            action: { append(value) }
        )
        .opacity(enabled ? 1 : 0.35)
        .allowsHitTesting(enabled)
    }

    private func isSegmentEnabled(_ value: Int) -> Bool {
        guard let lockedSegment else { return true }
        return value == lockedSegment
    }

    private func modifierKey(_ multiplier: DartMultiplier, identifier: String) -> some View {
        let title = ScoringPadLabels.modifierTitle(multiplier, dynamicTypeSize: dynamicTypeSize)
        let isSelected = selectedMultiplier == multiplier
        let background: Color = {
            switch multiplier {
            case .double:
                return isSelected ? Brand.amber : Brand.amber.opacity(0.55)
            case .triple:
                return isSelected ? Brand.orange : Brand.orange.opacity(0.55)
            case .single:
                return Brand.key
            }
        }()
        let foreground: Color = (isSelected && multiplier != .single) ? Brand.inkOnBright : Brand.textPrimary
        return ScoringPadKey(
            title: title,
            background: background,
            foreground: foreground,
            font: usesAccessibilityLayout ? .title3.weight(.bold) : .body.weight(.bold),
            minHeight: displayKeyMinHeight,
            accessibilityLabel: multiplierAccessibilityLabel(multiplier),
            accessibilityHint: modifierHint(multiplier, isSelected: isSelected),
            isSelected: isSelected,
            identifier: identifier,
            action: { toggle(multiplier) }
        )
        .frame(maxWidth: .infinity)
    }

    private func multiplierAccessibilityLabel(_ multiplier: DartMultiplier) -> String {
        switch multiplier {
        case .single:
            return L10n.string("scoring.multiplier.single.accessibility")
        case .double:
            return L10n.string("scoring.multiplier.double.accessibility")
        case .triple:
            return L10n.string("scoring.multiplier.triple.accessibility")
        }
    }

    private func modifierHint(_ multiplier: DartMultiplier, isSelected: Bool) -> String {
        if isSelected {
            switch multiplier {
            case .double:
                return L10n.string("scoring.pad.double.hint.armed")
            case .triple:
                return L10n.string("scoring.pad.triple.hint.armed")
            case .single:
                return L10n.string("scoring.multiplier.hint")
            }
        }
        switch multiplier {
        case .double:
            return L10n.string("scoring.pad.double.hint")
        case .triple:
            return L10n.string("scoring.pad.triple.hint")
        case .single:
            return L10n.string("scoring.multiplier.hint")
        }
    }

    private func append(_ value: Int) {
        guard enteredDarts.count < 3 else { return }
        if value != 25, let lockedSegment, value != lockedSegment { return }
        if value == 25, !showsBull { return }
        let dart: DartInput
        if value == 25 {
            dart = selectedMultiplier == .double
                ? DartInput(multiplier: .single, segment: .innerBull)
                : DartInput(multiplier: .single, segment: .outerBull)
        } else {
            dart = DartInput(multiplier: selectedMultiplier, segment: .oneToTwenty(value))
        }
        enteredDarts.append(dart)
        selectedMultiplier = .single
    }

    private func appendMiss() {
        guard enteredDarts.count < 3 else { return }
        enteredDarts.append(DartInput(multiplier: .single, segment: .miss, isMiss: true))
        selectedMultiplier = .single
    }

    private func toggle(_ multiplier: DartMultiplier) {
        selectedMultiplier = selectedMultiplier == multiplier ? .single : multiplier
    }

    private func undo() {
        if enteredDarts.isEmpty {
            onUndoTurn()
        } else {
            enteredDarts.removeLast()
            selectedMultiplier = .single
        }
    }
}

struct OptionalAccessibilityHint: ViewModifier {
    let hint: String?

    func body(content: Content) -> some View {
        if let hint, !hint.isEmpty {
            content.accessibilityHint(hint)
        } else {
            content
        }
    }
}
