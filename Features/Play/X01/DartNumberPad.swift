import SwiftUI

/// Per-dart entry pad matching the reference scoreboard: a grid of 1-20 plus
/// the bull, with sticky DOUBLE / TRIPLE modifiers, a miss (0) key, and an
/// undo key. Tapping a number appends a dart to the current visit (max 3).
struct DartNumberPad: View {
    @Binding var enteredDarts: [DartInput]
    @Binding var selectedMultiplier: DartMultiplier
    /// When set, only this segment (and optionally bull) accepts scoring input.
    var lockedSegment: Int? = nil
    /// When true, number keys are disabled (miss and undo still work).
    var scoringSegmentsDisabled: Bool = false
    var showsBull: Bool = true
    var maxDarts: Int = 3
    /// When false, hides the in-pad visit row (e.g. X01 landscape where the score card already shows darts).
    var showsVisitPreview: Bool = true
    /// Called when undo is tapped with an empty in-progress visit to revert the last accepted throw.
    let onUndoTurn: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.matchLayoutPlayerCount) private var matchLayoutPlayerCount
    @ScaledMetric(relativeTo: .body) private var keyMinHeight: CGFloat = 52
    @ScaledMetric(relativeTo: .caption) private var visitSlotMinHeight: CGFloat = 34

    private var usesAccessibilityLayout: Bool {
        GameplayLayout.usesAccessibilityMatchScoringLayout(dynamicTypeSize: dynamicTypeSize)
    }

    private var usesLandscapeCompactLayout: Bool {
        !usesAccessibilityLayout
            && (
                GameplayLayout.usesLandscapeMatchScoringLayout(verticalSizeClass: verticalSizeClass)
                    || GameplayLayout.usesSideBySideBottomScoringRegion(
                        horizontalSizeClass: horizontalSizeClass,
                        verticalSizeClass: verticalSizeClass,
                        playerCount: matchLayoutPlayerCount
                    )
            )
    }

    private var usesIPadSideBySidePad: Bool {
        false
    }

    private var padSpacing: CGFloat {
        if usesAccessibilityLayout {
            return ScoringPadStyle.accessibilitySpacing
        }
        if usesIPadSideBySidePad {
            return GameplayLayout.iPadSideBySidePadSpacing
        }
        if usesLandscapeCompactLayout {
            return 4
        }
        return ScoringPadStyle.compactSpacing
    }

    private var displayKeyMinHeight: CGFloat {
        if usesAccessibilityLayout {
            return min(keyMinHeight, 56)
        }
        if usesIPadSideBySidePad {
            return GameplayLayout.iPadSideBySidePadKeyMinHeight
        }
        if usesLandscapeCompactLayout {
            return lockedSegment == nil ? 40 : 56
        }
        return keyMinHeight
    }

    private var displayVisitSlotMinHeight: CGFloat {
        if usesAccessibilityLayout {
            return min(visitSlotMinHeight, 40)
        }
        if usesIPadSideBySidePad {
            return 40
        }
        if usesLandscapeCompactLayout {
            return 28
        }
        return min(visitSlotMinHeight, 30)
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
            if showsVisitPreview {
                visitPreview
            }
            ForEach(visibleCompactRows, id: \.self) { row in
                HStack(spacing: padSpacing) {
                    ForEach(row, id: \.self) { value in
                        numberKey(value)
                    }
                }
            }
            controlRow()
        }
    }

    private var accessibilityPad: some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: padSpacing),
            count: GameplayLayout.scoringPadColumnCount(dynamicTypeSize: dynamicTypeSize)
        )
        return VStack(spacing: padSpacing) {
            if showsVisitPreview {
                visitPreview
            }
            LazyVGrid(columns: columns, spacing: padSpacing) {
                ForEach(visibleAccessibilitySegments, id: \.self) { value in
                    numberKey(value)
                }
            }
            controlRow()
        }
    }

    private var visitPreview: some View {
        HStack(spacing: 6) {
            ForEach(0 ..< maxDarts, id: \.self) { slot in
                Text(slot < enteredDarts.count ? enteredDarts[slot].compactDisplayLabel : "")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(Brand.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .scoringPadVisitSlotStyle(minHeight: displayVisitSlotMinHeight)
            }
        }
        .accessibilityHidden(true)
        .accessibilityIdentifier("dart_visit_preview")
    }

    private func controlRow(minHeight: CGFloat? = nil) -> some View {
        let keyHeight = minHeight ?? displayKeyMinHeight
        return HStack(spacing: padSpacing) {
            ScoringPadKey(
                title: "0",
                minHeight: keyHeight,
                accessibilityLabel: DartInput.padKeyAccessibilityLabel(segmentValue: 0, armedMultiplier: .single),
                identifier: "pad_0",
                action: appendMiss
            )
            modifierKey(.double, identifier: "pad_double", minHeight: keyHeight)
            modifierKey(.triple, identifier: "pad_triple", minHeight: keyHeight)
            ScoringPadIconKey(
                systemImage: "arrow.uturn.backward",
                minHeight: keyHeight,
                accessibilityLabel: L10n.string("scoring.undoLastTurn"),
                identifier: "pad_undo",
                action: undo
            )
        }
    }

    private var numberKeyFont: Font {
        if usesAccessibilityLayout || usesIPadSideBySidePad {
            return .title3.weight(.semibold)
        }
        return .body.weight(.semibold)
    }

    private func segmentKeyTitle(_ value: Int) -> String {
        if value == 25 {
            return ScoringPadLabels.bullTitle(armedMultiplier: selectedMultiplier)
        }
        return String(value)
    }

    private func numberKey(_ value: Int, minHeight: CGFloat? = nil) -> some View {
        let enabled = value == 25 ? showsBull : isSegmentEnabled(value)
        let bullHint = value == 25 && selectedMultiplier == .double
            ? L10n.string("scoring.pad.bull.hint.armedDouble")
            : nil
        return ScoringPadKey(
            title: segmentKeyTitle(value),
            font: numberKeyFont,
            minHeight: minHeight ?? displayKeyMinHeight,
            accessibilityLabel: DartInput.padKeyAccessibilityLabel(
                segmentValue: value,
                armedMultiplier: selectedMultiplier
            ),
            accessibilityHint: bullHint,
            identifier: "pad_\(value)",
            action: { append(value) }
        )
        .opacity(enabled ? 1 : 0.35)
        .allowsHitTesting(enabled)
    }

    private func isSegmentEnabled(_ value: Int) -> Bool {
        if scoringSegmentsDisabled { return false }
        guard let lockedSegment else { return true }
        return value == lockedSegment
    }

    private func modifierKey(
        _ multiplier: DartMultiplier,
        identifier: String,
        minHeight: CGFloat? = nil
    ) -> some View {
        let keyHeight = minHeight ?? displayKeyMinHeight
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
            font: usesAccessibilityLayout || usesIPadSideBySidePad ? .title3.weight(.bold) : .body.weight(.bold),
            minHeight: keyHeight,
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

    private func modifierHint(_ multiplier: DartMultiplier, isSelected: Bool) -> String? {
        guard isSelected else { return nil }
        switch multiplier {
        case .double:
            return L10n.string("scoring.pad.double.hint.armed")
        case .triple:
            return L10n.string("scoring.pad.triple.hint.armed")
        case .single:
            return nil
        }
    }

    private func append(_ value: Int) {
        guard enteredDarts.count < maxDarts else { return }
        if scoringSegmentsDisabled { return }
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
        guard enteredDarts.count < maxDarts else { return }
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
