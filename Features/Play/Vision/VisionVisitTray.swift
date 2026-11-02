import SwiftUI

struct VisionVisitTray: View {
    @ObservedObject var viewModel: VisionScoringViewModel
    @State private var selectedDartID: UUID?
    @State private var isAddingDart = false
    @State private var editDarts: [DartInput] = []
    @State private var editMultiplier: DartMultiplier = .single

    var body: some View {
        VStack(spacing: DS.Spacing.s3) {
            Text(headline)
                .font(.title2.bold())
                .foregroundStyle(Brand.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            slotRow

            if isAddingDart {
                DartNumberPad(
                    enteredDarts: $editDarts,
                    selectedMultiplier: $editMultiplier,
                    maxDarts: 1,
                    showsVisitPreview: false,
                    onUndoTurn: { isAddingDart = false }
                )
                .onChange(of: editDarts) { _, darts in
                    guard let dart = darts.first else { return }
                    viewModel.addDart(dart)
                    editDarts = []
                    isAddingDart = false
                }
            } else if let selectedDartID, viewModel.visitStatus == .reviewing {
                DartNumberPad(
                    enteredDarts: $editDarts,
                    selectedMultiplier: $editMultiplier,
                    maxDarts: 1,
                    showsVisitPreview: false,
                    onUndoTurn: { self.selectedDartID = nil }
                )
                .onChange(of: editDarts) { _, darts in
                    guard let dart = darts.first else { return }
                    viewModel.editDart(id: selectedDartID, to: dart)
                    editDarts = []
                    self.selectedDartID = nil
                }
                Button(L10n.string("vision.visit.remove")) {
                    viewModel.removeDart(id: selectedDartID)
                    self.selectedDartID = nil
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.red)
                .frame(maxWidth: .infinity, minHeight: 52)
            }

            actionButtons
        }
    }

    private var headline: String {
        if viewModel.dartsAllowed == 0 {
            return L10n.string("vision.visit.notYourTurn")
        }
        switch viewModel.visitStatus {
        case .collecting:
            return L10n.format(
                "vision.visit.throwFormat",
                viewModel.visit.count + 1,
                viewModel.visitCapacity
            )
        case .reviewing:
            if viewModel.visitHasEnded || viewModel.visit.count >= viewModel.visitCapacity {
                return L10n.string("vision.visit.complete")
            }
            return L10n.string("vision.visit.review")
        }
    }

    private var slotRow: some View {
        HStack(spacing: DS.Spacing.s2) {
            ForEach(0 ..< viewModel.visitCapacity, id: \.self) { index in
                slotView(index: index)
            }
        }
    }

    @ViewBuilder
    private func slotView(index: Int) -> some View {
        let slotNumber = index + 1
        if index < viewModel.visit.count {
            let entry = viewModel.visit[index]
            let isSelected = selectedDartID == entry.id
            Button {
                guard viewModel.visitStatus == .reviewing else { return }
                selectedDartID = entry.id
                editDarts = []
                editMultiplier = .single
            } label: {
                VStack(spacing: 4) {
                    Text(entry.dart.compactDisplayLabel)
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(Brand.textPrimary)
                    slotCaption(entry: entry, slotNumber: slotNumber)
                }
                .frame(maxWidth: .infinity, minHeight: 72)
                .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                        .stroke(isSelected ? Brand.green : Color.clear, lineWidth: 2)
                )
            }
            .accessibilityLabel(
                L10n.format(
                    "vision.visit.slotAccessibilityFormat",
                    slotNumber,
                    entry.dart.compactDisplayLabel
                )
            )
        } else {
            Text(L10n.format("vision.visit.emptySlotFormat", slotNumber))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 72)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(Brand.textSecondary.opacity(0.4))
                )
        }
    }

    @ViewBuilder
    private func slotCaption(entry: VisitDart, slotNumber: Int) -> some View {
        if let detection = entry.detection {
            Text(L10n.format(
                "vision.proposal.confidenceFormat",
                Int((detection.visionConfidence * 100).rounded())
            ))
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Brand.textSecondary)
        } else {
            Text(L10n.format("vision.visit.emptySlotFormat", slotNumber))
                .font(.caption2)
                .foregroundStyle(Brand.textSecondary)
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        if viewModel.visitStatus == .collecting, viewModel.dartsAllowed > 0 {
            trayButton(L10n.string("vision.visit.doneThrowing"), prominent: false) {
                viewModel.doneThrowing()
            }
        }
        if viewModel.visitStatus == .reviewing {
            if viewModel.visit.count < viewModel.visitCapacity {
                trayButton(L10n.string("vision.visit.addDart"), prominent: false) {
                    isAddingDart = true
                    selectedDartID = nil
                }
            }
            if viewModel.visit.count < viewModel.visitCapacity, !viewModel.visitHasEnded {
                trayButton(L10n.string("vision.visit.keepThrowing"), prominent: false) {
                    viewModel.keepThrowing()
                }
            }
            let missing = viewModel.missingDartCount
            let submitTitle = missing > 0
                ? L10n.format("vision.visit.submitWithMissesFormat", missing)
                : L10n.string("vision.visit.submit")
            trayButton(submitTitle, prominent: true) {
                viewModel.submitVisit()
            }
            .disabled(viewModel.dartsAllowed == 0)
            .opacity(viewModel.dartsAllowed == 0 ? 0.45 : 1)
        }
    }

    private func trayButton(_ title: String, prominent: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(
                    prominent ? Brand.green : Brand.card,
                    in: RoundedRectangle(cornerRadius: DS.Radius.sm)
                )
                .foregroundStyle(prominent ? Color.black : Brand.textPrimary)
        }
    }
}
