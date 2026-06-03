import SwiftUI

/// Per-dart entry pad matching the reference scoreboard: a grid of 1-20 plus
/// the bull (25), with sticky DOUBLE / TRIPLE modifiers, a miss (0) key, and an
/// undo key. Tapping a number appends a dart to the current visit (max 3).
struct DartNumberPad: View {
    @Binding var enteredDarts: [DartInput]
    @Binding var selectedMultiplier: DartMultiplier
    /// Called when undo is tapped while the current visit has no darts yet.
    let onUndoTurn: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var keyMinHeight: CGFloat = 52

    private var usesAccessibilityLayout: Bool {
        GameplayLayout.usesAccessibilityMatchScoringLayout(dynamicTypeSize: dynamicTypeSize)
    }

    private var padSpacing: CGFloat {
        usesAccessibilityLayout ? 8 : 6
    }

    private var displayKeyMinHeight: CGFloat {
        usesAccessibilityLayout ? min(keyMinHeight, 56) : keyMinHeight
    }

    private let compactRows: [[Int]] = [
        [1, 2, 3, 4, 5, 6, 7],
        [8, 9, 10, 11, 12, 13, 14],
        [15, 16, 17, 18, 19, 20, 25]
    ]

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
            ForEach(compactRows, id: \.self) { row in
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
                ForEach(accessibilitySegments, id: \.self) { value in
                    numberKey(value)
                }
            }
            controlRow
        }
    }

    private var controlRow: some View {
        HStack(spacing: padSpacing) {
            key(
                "0",
                background: Brand.key,
                identifier: "pad_0",
                accessibilityLabel: DartInput.padKeyAccessibilityLabel(segmentValue: 0, armedMultiplier: .single),
                accessibilityHint: L10n.string("scoring.segment.hint")
            ) { appendMiss() }
            modifierKey(.double, identifier: "pad_double")
            modifierKey(.triple, identifier: "pad_triple")
            Button(action: undo) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Brand.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: displayKeyMinHeight)
                    .background(Brand.red, in: RoundedRectangle(cornerRadius: 8))
            }
            .frame(maxWidth: .infinity)
            .accessibilityLabel(L10n.scoringUndoLastTurn)
            .accessibilityIdentifier("pad_undo")
        }
    }

    private func numberKey(_ value: Int) -> some View {
        key(
            String(value),
            background: Brand.key,
            identifier: "pad_\(value)",
            accessibilityLabel: DartInput.padKeyAccessibilityLabel(
                segmentValue: value,
                armedMultiplier: selectedMultiplier
            ),
            accessibilityHint: L10n.string("scoring.segment.hint")
        ) { append(value) }
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
        // When armed the fill is a solid bright color (amber/orange); dark ink keeps the label
        // legible in dark mode where white would drop below AA. The dimmed idle fill is dark
        // enough that adaptive text stays the better choice.
        let foreground: Color = (isSelected && multiplier != .single) ? Brand.inkOnBright : Brand.textPrimary
        return key(
            title,
            background: background,
            foreground: foreground,
            weight: .bold,
            identifier: identifier,
            accessibilityLabel: multiplierAccessibilityLabel(multiplier),
            accessibilityHint: modifierHint(multiplier, isSelected: isSelected),
            isSelected: isSelected
        ) {
            toggle(multiplier)
        }
        .frame(maxWidth: .infinity)
    }

    private func key(
        _ title: String,
        background: Color,
        foreground: Color = Brand.textPrimary,
        weight: Font.Weight = .semibold,
        identifier: String,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(usesAccessibilityLayout ? .title3.weight(weight) : .body.weight(weight))
                .foregroundStyle(foreground)
                .lineLimit(1)
                .minimumScaleFactor(usesAccessibilityLayout ? 0.85 : 0.7)
                .frame(maxWidth: .infinity, minHeight: displayKeyMinHeight)
                .background(background, in: RoundedRectangle(cornerRadius: 8))
        }
        .accessibilityLabel(accessibilityLabel ?? title)
        .modifier(OptionalAccessibilityHint(hint: accessibilityHint))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(identifier)
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
