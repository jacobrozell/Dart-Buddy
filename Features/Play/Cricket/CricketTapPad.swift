import SwiftUI

/// Tap-to-mark input: tap a target to add a dart for the active player. The
/// sticky DOUBLE / TRIPLE modifiers add 2 / 3 marks in one tap (Bull doubles to
/// the inner bull). Auto-submits at three darts; manual submit ends a short visit.
struct CricketTapPad: View {
    @Binding var enteredDarts: [DartInput]
    @Binding var selectedMultiplier: DartMultiplier
    let canSubmit: Bool
    let onSubmit: () -> Void
    let onUndoTurn: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @ScaledMetric(relativeTo: .body) private var keyMinHeight: CGFloat = 52
    @ScaledMetric(relativeTo: .caption) private var visitSlotMinHeight: CGFloat = 34

    private var usesAccessibilityLayout: Bool {
        GameplayLayout.usesAccessibilityMatchScoringLayout(dynamicTypeSize: dynamicTypeSize)
    }

    private var usesLandscapeLayout: Bool {
        !usesAccessibilityLayout
            && GameplayLayout.usesLandscapeMatchScoringLayout(verticalSizeClass: verticalSizeClass)
    }

    private var padSpacing: CGFloat {
        if usesAccessibilityLayout {
            return ScoringPadStyle.accessibilitySpacing
        }
        if usesLandscapeLayout {
            return 6
        }
        return ScoringPadStyle.compactSpacing
    }

    private var displayKeyMinHeight: CGFloat {
        if usesAccessibilityLayout {
            return min(keyMinHeight, 56)
        }
        if usesLandscapeLayout {
            return 44
        }
        return min(keyMinHeight, 48)
    }

    private var displayBullMissKeyMinHeight: CGFloat {
        if usesAccessibilityLayout {
            return displayKeyMinHeight
        }
        if usesLandscapeLayout {
            return 44
        }
        return 44
    }

    private var displayVisitSlotMinHeight: CGFloat {
        if usesAccessibilityLayout {
            return min(visitSlotMinHeight, 40)
        }
        if usesLandscapeLayout {
            return 30
        }
        return min(visitSlotMinHeight, 30)
    }

    private let numberRows: [[String]] = [
        ["20", "19", "18"],
        ["17", "16", "15"]
    ]

    private let accessibilitySegments: [Int] = [20, 19, 18, 17, 16, 15]

    var body: some View {
        if usesAccessibilityLayout {
            accessibilityPad
        } else if usesLandscapeLayout {
            landscapeWidePad
        } else {
            compactPad
        }
    }

    /// Landscape: one row of segments + bull/miss, then modifiers + enter.
    /// Keeps the pad short so the transposed board stays visible above it.
    private var landscapeWidePad: some View {
        VStack(spacing: padSpacing) {
            visitPreview
            HStack(spacing: padSpacing) {
                ForEach(accessibilitySegments, id: \.self) { segment in
                    numberKey(segment, title: String(segment))
                }
                bullKey()
                missKey()
            }
            HStack(spacing: padSpacing) {
                modifierKey(.double, identifier: "cricket_double")
                modifierKey(.triple, identifier: "cricket_triple")
                ScoringPadIconKey(
                    systemImage: "arrow.uturn.backward",
                    minHeight: displayKeyMinHeight,
                    accessibilityLabel: L10n.string("scoring.undoLastTurn"),
                    identifier: "cricket_undo",
                    action: undo
                )
                enterButton()
            }
        }
    }

    private var compactPad: some View {
        VStack(spacing: padSpacing) {
            visitPreview
            ForEach(numberRows, id: \.self) { row in
                HStack(spacing: padSpacing) {
                    ForEach(row, id: \.self) { value in
                        numberKey(Int(value) ?? 0, title: value)
                    }
                }
            }
            bullMissRow(showSpacer: true)
            controlRow()
            enterButton()
        }
    }

    private var accessibilityPad: some View {
        let columns = [
            GridItem(.flexible(), spacing: padSpacing),
            GridItem(.flexible(), spacing: padSpacing)
        ]
        return VStack(spacing: padSpacing) {
            visitPreview
            LazyVGrid(columns: columns, spacing: padSpacing) {
                ForEach(accessibilitySegments, id: \.self) { segment in
                    numberKey(segment, title: String(segment))
                }
            }
            bullMissRow(showSpacer: false)
            controlRow()
            enterButton()
        }
    }

    private func numberKey(_ segment: Int, title: String, minHeight: CGFloat? = nil) -> some View {
        ScoringPadKey(
            title: title,
            font: usesAccessibilityLayout ? .title3.weight(.semibold) : .body.weight(.semibold),
            minHeight: minHeight ?? displayKeyMinHeight,
            accessibilityLabel: DartInput.padKeyAccessibilityLabel(
                segmentValue: segment,
                armedMultiplier: selectedMultiplier
            ),
            identifier: "cricket_\(title)",
            action: { appendNumber(segment) }
        )
    }

    @ViewBuilder
    private func bullMissRow(showSpacer: Bool, minHeight: CGFloat? = nil) -> some View {
        HStack(spacing: padSpacing) {
            bullKey(minHeight: minHeight)
            missKey(minHeight: minHeight)
            if showSpacer {
                Color.clear
                    .frame(maxWidth: .infinity, minHeight: displayBullMissKeyMinHeight)
                    .accessibilityHidden(true)
            }
        }
    }

    private func bullKey(minHeight: CGFloat? = nil) -> some View {
        ScoringPadKey(
            title: L10n.string("scoring.pad.bullLabel"),
            font: usesAccessibilityLayout ? .title3.weight(.semibold) : .body.weight(.semibold),
            minHeight: minHeight ?? displayBullMissKeyMinHeight,
            accessibilityLabel: DartInput.padKeyAccessibilityLabel(segmentValue: 25, armedMultiplier: selectedMultiplier),
            identifier: "cricket_bull",
            action: appendBull
        )
    }

    private func missKey(minHeight: CGFloat? = nil) -> some View {
        ScoringPadKey(
            title: L10n.string("scoring.pad.missLabel"),
            font: usesAccessibilityLayout ? .title3.weight(.semibold) : .body.weight(.semibold),
            minHeight: minHeight ?? displayBullMissKeyMinHeight,
            accessibilityLabel: DartInput.padKeyAccessibilityLabel(segmentValue: 0, armedMultiplier: .single),
            identifier: "cricket_miss",
            action: appendMiss
        )
    }

    private func controlRow(minHeight: CGFloat? = nil) -> some View {
        let keyHeight = minHeight ?? displayKeyMinHeight
        return HStack(spacing: padSpacing) {
            modifierKey(.double, identifier: "cricket_double", minHeight: keyHeight)
            modifierKey(.triple, identifier: "cricket_triple", minHeight: keyHeight)
            ScoringPadIconKey(
                systemImage: "arrow.uturn.backward",
                minHeight: keyHeight,
                accessibilityLabel: L10n.string("scoring.undoLastTurn"),
                identifier: "cricket_undo",
                action: undo
            )
        }
    }

    private func enterButton(minHeight: CGFloat? = nil) -> some View {
        let keyHeight = minHeight ?? displayKeyMinHeight
        return Button(action: onSubmit) {
            Text(L10n.scoringEnter)
                .font(usesAccessibilityLayout ? .title3.weight(.bold) : .headline.weight(.bold))
                .foregroundStyle(canSubmit ? Brand.inkOnBright : Brand.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: keyHeight)
                .background(canSubmit ? Brand.green : Brand.green.opacity(0.4), in: ScoringPadStyle.keyShape)
        }
        .disabled(!canSubmit)
        .accessibilityLabel(L10n.scoringEnter)
        .accessibilityIdentifier("cricket_enter")
    }

    @ViewBuilder
    private var visitPreview: some View {
        HStack(spacing: 6) {
            ForEach(0 ..< 3, id: \.self) { slot in
                Text(slot < enteredDarts.count ? dartLabel(enteredDarts[slot]) : "")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(Brand.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, minHeight: displayVisitSlotMinHeight)
                    .background(Brand.dartBox, in: ScoringPadStyle.visitSlotShape)
            }
        }
        .accessibilityHidden(true)
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
        // Armed modifier = solid bright fill; dark ink stays legible in dark mode where white
        // would fail AA. Idle (dimmed) fill keeps adaptive text.
        let foreground: Color = (isSelected && multiplier != .single) ? Brand.inkOnBright : Brand.textPrimary
        return ScoringPadKey(
            title: title,
            background: background,
            foreground: foreground,
            font: usesAccessibilityLayout ? .title3.weight(.bold) : .body.weight(.bold),
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

    private func appendNumber(_ value: Int) {
        guard enteredDarts.count < 3, (15 ... 20).contains(value) else { return }
        enteredDarts.append(DartInput(multiplier: selectedMultiplier, segment: .oneToTwenty(value)))
        selectedMultiplier = .single
    }

    private func appendBull() {
        guard enteredDarts.count < 3 else { return }
        let dart = selectedMultiplier == .double
            ? DartInput(multiplier: .single, segment: .innerBull)
            : DartInput(multiplier: .single, segment: .outerBull)
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

    private func dartLabel(_ dart: DartInput) -> String {
        if dart.isMiss { return "—" }
        switch dart.segment {
        case let .oneToTwenty(value):
            switch dart.multiplier {
            case .single: return "\(value)"
            case .double: return "D\(value)"
            case .triple: return "T\(value)"
            }
        case .outerBull: return "B"
        case .innerBull: return "BB"
        case .miss: return "—"
        }
    }
}
