import SwiftUI

struct FleetBoardGridView: View {
    enum Mode {
        case placement(selected: Set<FleetBoardCell>, color: Color)
        case ownFleet(fleet: FleetPlayerFleet, shipHealth: Int, color: Color)
        case enemyFog(probeMap: [FleetBoardCell: FleetProbeResult])
    }

    let mode: Mode
    let bullAllowed: Bool
    var onCellTap: ((FleetBoardCell) -> Void)?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: DS.Spacing.s2), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: DS.Spacing.s2) {
            ForEach(displayCells, id: \.self) { cell in
                cellButton(cell)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var displayCells: [FleetBoardCell] {
        var cells = (1 ... 20).map { FleetBoardCell.segment($0) }
        if bullAllowed { cells.append(.bull) }
        return cells
    }

    @ViewBuilder
    private func cellButton(_ cell: FleetBoardCell) -> some View {
        let appearance = appearance(for: cell)
        Button {
            onCellTap?(cell)
        } label: {
            VStack(spacing: 2) {
                Text(label(for: cell))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(appearance.foreground)
                if let pips = appearance.damagePips {
                    Text(pips)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(appearance.foreground.opacity(0.85))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(appearance.background, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.sm)
                    .strokeBorder(appearance.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(onCellTap == nil)
        .accessibilityLabel(appearance.accessibilityLabel)
        .accessibilityIdentifier(appearance.accessibilityIdentifier)
    }

    private func label(for cell: FleetBoardCell) -> String {
        switch cell {
        case let .segment(value): return "\(value)"
        case .bull: return "B"
        }
    }

    private func appearance(for cell: FleetBoardCell) -> CellAppearance {
        switch mode {
        case let .placement(selected, color):
            let isSelected = selected.contains(cell)
            return CellAppearance(
                background: isSelected ? color.opacity(0.35) : Brand.card,
                border: isSelected ? color : Brand.key,
                foreground: isSelected ? color : Brand.textPrimary,
                damagePips: nil,
                accessibilityLabel: isSelected
                    ? L10n.format("play.fleet.placement.selectedFormat", label(for: cell))
                    : L10n.string("play.fleet.cell.unprobed"),
                accessibilityIdentifier: isSelected ? "fleet-ship-own" : "fleet-cell-\(cellIdentifier(cell))"
            )
        case let .ownFleet(fleet, shipHealth, color):
            if fleet.sunk.contains(cell) {
                return CellAppearance(
                    background: Brand.red.opacity(0.25),
                    border: Brand.red,
                    foreground: Brand.red,
                    damagePips: nil,
                    accessibilityLabel: L10n.format("play.fleet.cell.sunk", label(for: cell)),
                    accessibilityIdentifier: "fleet-cell-sunk-\(cellIdentifier(cell))"
                )
            }
            if fleet.ships.contains(cell) {
                let damage = fleet.damage[cell] ?? 0
                let pips = shipHealth > 1 ? L10n.format("play.fleet.damageFormat", damage, shipHealth) : nil
                return CellAppearance(
                    background: color.opacity(0.3),
                    border: color,
                    foreground: color,
                    damagePips: pips,
                    accessibilityLabel: L10n.format("play.fleet.damageAccessibilityFormat", label(for: cell), damage, shipHealth),
                    accessibilityIdentifier: "fleet-ship-own"
                )
            }
            return CellAppearance(
                background: Brand.card,
                border: Brand.key,
                foreground: Brand.textSecondary,
                damagePips: nil,
                accessibilityLabel: L10n.string("play.fleet.cell.unprobed"),
                accessibilityIdentifier: "fleet-cell-\(cellIdentifier(cell))"
            )
        case let .enemyFog(probeMap):
            switch probeMap[cell] {
            case .sunk:
                return CellAppearance(
                    background: Brand.red.opacity(0.25),
                    border: Brand.red,
                    foreground: Brand.red,
                    damagePips: nil,
                    accessibilityLabel: L10n.format("play.fleet.cell.sunk", label(for: cell)),
                    accessibilityIdentifier: "fleet-cell-sunk-\(cellIdentifier(cell))"
                )
            case .hit:
                return CellAppearance(
                    background: Brand.amber.opacity(0.25),
                    border: Brand.amber,
                    foreground: Brand.amber,
                    damagePips: nil,
                    accessibilityLabel: L10n.string("play.fleet.cell.hit"),
                    accessibilityIdentifier: "fleet-cell-hit-\(cellIdentifier(cell))"
                )
            case .miss:
                return CellAppearance(
                    background: Brand.card,
                    border: Brand.key,
                    foreground: Brand.textSecondary,
                    damagePips: nil,
                    accessibilityLabel: L10n.string("play.fleet.cell.miss"),
                    accessibilityIdentifier: "fleet-cell-miss-\(cellIdentifier(cell))"
                )
            case nil:
                return CellAppearance(
                    background: Brand.background,
                    border: Brand.key.opacity(0.6),
                    foreground: Brand.textSecondary,
                    damagePips: nil,
                    accessibilityLabel: L10n.string("play.fleet.cell.unprobed"),
                    accessibilityIdentifier: "fleet-cell-fog-\(cellIdentifier(cell))"
                )
            }
        }
    }

    private func cellIdentifier(_ cell: FleetBoardCell) -> String {
        switch cell {
        case let .segment(value): return "\(value)"
        case .bull: return "bull"
        }
    }

    private struct CellAppearance {
        let background: Color
        let border: Color
        let foreground: Color
        let damagePips: String?
        let accessibilityLabel: String
        let accessibilityIdentifier: String
    }
}

private extension FleetBoardCell {
    var selfIdentifiable: FleetBoardCell { self }
}

extension FleetBoardCell: Identifiable {
    public var id: String {
        switch self {
        case let .segment(value): return "segment-\(value)"
        case .bull: return "bull"
        }
    }
}
