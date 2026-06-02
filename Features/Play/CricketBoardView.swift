import SwiftUI

/// Authentic Cricket scoreboard: a marks grid (20–15 + Bull) with one column
/// per player, standard slash / cross / circle marks, and a tap-to-mark input
/// pad. Replaces the X01-style dart pad that Cricket previously borrowed.
struct CricketBoardView: View {
    struct Column: Identifiable {
        let id: UUID
        let name: String
        let score: Int
        let marks: [String: Int]
        let isActive: Bool
    }

    let columns: [Column]
    private let targets = CricketTarget.allCases

    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            GridRow {
                Color.clear.frame(height: 1).gridCellColumns(1)
                ForEach(columns) { column in
                    VStack(spacing: 2) {
                        Text(column.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(column.isActive ? Brand.green : .white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text("\(column.score)")
                            .font(.title3.weight(.heavy))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.s2)
                    .background(column.isActive ? Brand.cardElevated : Color.clear)
                }
            }
            ForEach(targets, id: \.rawValue) { target in
                GridRow {
                    Text(label(for: target))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Brand.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Spacing.s2)
                    ForEach(columns) { column in
                        CricketMarkCell(marks: column.marks[target.rawValue] ?? 0)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DS.Spacing.s2)
                            .background(column.isActive ? Brand.cardElevated.opacity(0.4) : Color.clear)
                    }
                }
                Divider().overlay(Brand.cardElevated)
            }
        }
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    private func label(for target: CricketTarget) -> String {
        target == .bull ? "Bull" : target.rawValue
    }
}

/// Standard cricket mark glyph: "/" for one, "X" for two, and a circled "X"
/// (closed) for three. Closed marks turn green to read at a glance.
struct CricketMarkCell: View {
    let marks: Int

    private var tint: Color { marks >= 3 ? Brand.green : .white }

    var body: some View {
        ZStack {
            if marks >= 1 {
                DiagonalStroke(downward: false).stroke(tint, style: .init(lineWidth: 2.5, lineCap: .round))
            }
            if marks >= 2 {
                DiagonalStroke(downward: true).stroke(tint, style: .init(lineWidth: 2.5, lineCap: .round))
            }
            if marks >= 3 {
                Circle().stroke(tint, lineWidth: 2.5)
            }
        }
        .frame(width: 26, height: 26)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        switch marks {
        case 0: return "Open"
        case 1: return "1 mark"
        case 2: return "2 marks"
        default: return "Closed"
        }
    }
}

private struct DiagonalStroke: Shape {
    let downward: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if downward {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
        return path
    }
}

/// Tap-to-mark input: tap a target to add a dart for the active player. The
/// sticky DOUBLE / TRIPLE modifiers add 2 / 3 marks in one tap (Bull doubles to
/// the inner bull). Auto-submits at three darts; manual submit ends a short visit.
struct CricketTapPad: View {
    @Binding var enteredDarts: [DartInput]
    @Binding var selectedMultiplier: DartMultiplier
    let canSubmit: Bool
    let onSubmit: () -> Void
    let onUndoTurn: () -> Void

    private let spacing: CGFloat = 6
    private let numberRows: [[String]] = [
        ["20", "19", "18"],
        ["17", "16", "15"]
    ]

    var body: some View {
        VStack(spacing: spacing) {
            visitPreview
            ForEach(numberRows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(row, id: \.self) { value in
                        key(value, background: Brand.key, identifier: "cricket_\(value)") {
                            appendNumber(Int(value) ?? 0)
                        }
                    }
                }
            }
            HStack(spacing: spacing) {
                key("BULL", background: Brand.key, identifier: "cricket_bull") { appendBull() }
                key("MISS", background: Brand.key, identifier: "cricket_miss") { appendMiss() }
            }
            HStack(spacing: spacing) {
                key("DOUBLE", background: selectedMultiplier == .double ? Brand.amber : Brand.amber.opacity(0.55), weight: .bold, identifier: "cricket_double") {
                    toggle(.double)
                }
                key("TRIPLE", background: selectedMultiplier == .triple ? Brand.orange : Brand.orange.opacity(0.55), weight: .bold, identifier: "cricket_triple") {
                    toggle(.triple)
                }
                Button(action: undo) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Brand.red, in: RoundedRectangle(cornerRadius: 8))
                }
                .accessibilityLabel(L10n.scoringUndoLastTurn)
                .accessibilityIdentifier("cricket_undo")
            }
            Button(action: onSubmit) {
                Text(L10n.scoringEnter)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(canSubmit ? Brand.green : Brand.green.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
            }
            .disabled(!canSubmit)
            .accessibilityIdentifier("cricket_enter")
        }
    }

    @ViewBuilder
    private var visitPreview: some View {
        HStack(spacing: 6) {
            ForEach(0 ..< 3, id: \.self) { slot in
                Text(slot < enteredDarts.count ? dartLabel(enteredDarts[slot]) : "")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 34)
                    .background(Brand.dartBox, in: RoundedRectangle(cornerRadius: 6))
            }
        }
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
