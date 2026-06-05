import SwiftUI

struct KillerNumberGridView: View {
    struct Assignment: Identifiable {
        let number: Int
        let playerInitial: String?

        var id: Int { number }
    }

    let assignments: [Assignment]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 5)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(1 ... 20, id: \.self) { number in
                let assignment = assignments.first(where: { $0.number == number })
                VStack(spacing: 2) {
                    Text("\(number)")
                        .font(.caption.weight(.semibold))
                    if let initial = assignment?.playerInitial {
                        Text(initial)
                            .font(.caption2)
                            .foregroundStyle(Brand.green)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(
                    assignment == nil ? Brand.card : Brand.cardElevated,
                    in: RoundedRectangle(cornerRadius: DS.Radius.sm)
                )
                .overlay {
                    if assignment != nil {
                        RoundedRectangle(cornerRadius: DS.Radius.sm)
                            .stroke(Brand.green.opacity(0.5), lineWidth: 1)
                    }
                }
                .accessibilityLabel(numberAccessibilityLabel(number: number, assignment: assignment))
                .accessibilityIdentifier("killer_number_grid_\(number)")
            }
        }
    }

    private func numberAccessibilityLabel(number: Int, assignment: Assignment?) -> String {
        if let initial = assignment?.playerInitial {
            return L10n.format("play.killer.numberTakenAccessibilityFormat", number, initial)
        }
        return L10n.format("play.killer.numberOpenAccessibilityFormat", number)
    }
}
