import SwiftUI

/// Per-dart entry pad matching the reference scoreboard: a grid of 1-20 plus
/// the bull (25), with sticky DOUBLE / TRIPLE modifiers, a miss (0) key, and an
/// undo key. Tapping a number appends a dart to the current visit (max 3).
struct DartNumberPad: View {
    @Binding var enteredDarts: [DartInput]
    @Binding var selectedMultiplier: DartMultiplier
    /// Called when undo is tapped while the current visit has no darts yet.
    let onUndoTurn: () -> Void

    private let spacing: CGFloat = 6
    private let rows: [[Int]] = [
        [1, 2, 3, 4, 5, 6, 7],
        [8, 9, 10, 11, 12, 13, 14],
        [15, 16, 17, 18, 19, 20, 25]
    ]

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(row, id: \.self) { value in
                        numberKey(value)
                    }
                }
            }
            HStack(spacing: spacing) {
                key("0", background: Brand.key, identifier: "pad_0") { appendMiss() }
                key(L10n.string("scoring.pad.double"), background: selectedMultiplier == .double ? Brand.amber : Brand.amber.opacity(0.55), weight: .bold, identifier: "pad_double") {
                    toggle(.double)
                }
                .frame(maxWidth: .infinity)
                key(L10n.string("scoring.pad.triple"), background: selectedMultiplier == .triple ? Brand.orange : Brand.orange.opacity(0.55), weight: .bold, identifier: "pad_triple") {
                    toggle(.triple)
                }
                .frame(maxWidth: .infinity)
                Button(action: undo) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Brand.red, in: RoundedRectangle(cornerRadius: 8))
                }
                .frame(maxWidth: .infinity)
                .accessibilityLabel(L10n.scoringUndoLastTurn)
                .accessibilityIdentifier("pad_undo")
            }
        }
    }

    private func numberKey(_ value: Int) -> some View {
        key(String(value), background: Brand.key, identifier: "pad_\(value)") { append(value) }
    }

    private func key(_ title: String, background: Color, weight: Font.Weight = .semibold, identifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: weight))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(background, in: RoundedRectangle(cornerRadius: 8))
        }
        .accessibilityIdentifier(identifier)
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
