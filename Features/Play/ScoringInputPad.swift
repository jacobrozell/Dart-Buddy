import SwiftUI

enum ScoringInputMode: String, CaseIterable {
    case totalEntry
    case dartEntry
}

struct ScoringInputPad: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let modeOptions: [ScoringInputMode]
    @Binding var mode: ScoringInputMode
    @Binding var selectedMultiplier: DartMultiplier
    @Binding var enteredDarts: [DartInput]
    @Binding var totalEntryText: String
    let canSubmit: Bool
    let onSubmit: () -> Void
    let onUndo: () -> Void

    private let segments: [DartSegment] = (1 ... 20).map { .oneToTwenty($0) } + [.outerBull, .innerBull]
    private var usesCompactPickerStyles: Bool { dynamicTypeSize.isAccessibilitySize }
    private var segmentGridColumns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 3 : 4
        return Array(repeating: GridItem(.flexible()), count: count)
    }

    var body: some View {
        VStack(spacing: 12) {
            if modeOptions.count > 1 {
                Group {
                    if usesCompactPickerStyles {
                        Picker("scoring.inputMode", selection: $mode) {
                            ForEach(modeOptions, id: \.rawValue) { option in
                                Text(option == .totalEntry ? "scoring.mode.total" : "scoring.mode.darts").tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                    } else {
                        Picker("scoring.inputMode", selection: $mode) {
                            ForEach(modeOptions, id: \.rawValue) { option in
                                Text(option == .totalEntry ? "scoring.mode.total" : "scoring.mode.darts").tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }

            if mode == .totalEntry {
                TextField("scoring.turnTotalPlaceholder", text: $totalEntryText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .accessibilityLabel("scoring.turnTotal.accessibilityLabel")
            } else {
                HStack {
                    ForEach([DartMultiplier.single, .double, .triple], id: \.rawValue) { multiplier in
                        Button(multiplierLabel(multiplier)) {
                            selectedMultiplier = multiplier
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(selectedMultiplier == multiplier ? .blue : .gray)
                        .frame(minWidth: 52, minHeight: 52)
                        .accessibilityLabel("\(multiplierAccessibility(multiplier))")
                        .accessibilityHint("scoring.multiplier.hint")
                    }
                }

                LazyVGrid(columns: segmentGridColumns, spacing: 8) {
                    ForEach(segments, id: \.self) { segment in
                        Button {
                            guard enteredDarts.count < 3 else { return }
                            enteredDarts.append(DartInput(multiplier: selectedMultiplier, segment: segment))
                        } label: {
                            Text(segmentLabel(segment))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .buttonStyle(.bordered)
                        .frame(minHeight: 52)
                        .accessibilityLabel(accessibilityLabel(for: segment))
                        .accessibilityHint("scoring.segment.hint")
                    }
                }

                if !enteredDarts.isEmpty {
                    Text(enteredDarts.map(dartLabel).joined(separator: ", "))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            ViewThatFits {
                HStack {
                    Button(L10n.scoringBackspace) {
                        _ = enteredDarts.popLast()
                    }
                    .buttonStyle(.bordered)
                    .accessibilityHint("scoring.backspace.hint")

                    Button(L10n.scoringClearTurn) {
                        enteredDarts.removeAll()
                        totalEntryText = ""
                    }
                    .buttonStyle(.bordered)
                    .accessibilityHint("scoring.clearTurn.hint")
                }
                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                    Button(L10n.scoringBackspace) {
                        _ = enteredDarts.popLast()
                    }
                    .buttonStyle(.bordered)
                    .accessibilityHint("scoring.backspace.hint")
                    Button(L10n.scoringClearTurn) {
                        enteredDarts.removeAll()
                        totalEntryText = ""
                    }
                    .buttonStyle(.bordered)
                    .accessibilityHint("scoring.clearTurn.hint")
                }
            }

            ViewThatFits {
                HStack {
                    Button(L10n.scoringSubmitTurn, action: onSubmit)
                        .buttonStyle(.borderedProminent)
                        .disabled(!canSubmit)
                        .accessibilityHint("scoring.submitTurn.hint")
                    Button(L10n.scoringUndoLastTurn, action: onUndo)
                        .buttonStyle(.bordered)
                        .accessibilityHint("scoring.undoTurn.hint")
                }
                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                    Button(L10n.scoringSubmitTurn, action: onSubmit)
                        .buttonStyle(.borderedProminent)
                        .disabled(!canSubmit)
                        .accessibilityHint("scoring.submitTurn.hint")
                    Button(L10n.scoringUndoLastTurn, action: onUndo)
                        .buttonStyle(.bordered)
                        .accessibilityHint("scoring.undoTurn.hint")
                }
            }
        }
        .padding(DS.Spacing.s3)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    private func segmentLabel(_ segment: DartSegment) -> String {
        switch segment {
        case let .oneToTwenty(value): return String(value)
        case .outerBull: return "OB"
        case .innerBull: return "IB"
        case .miss: return "MISS"
        }
    }

    private func dartLabel(_ dart: DartInput) -> String {
        let prefix = multiplierLabel(dart.multiplier)
        switch dart.segment {
        case let .oneToTwenty(value): return "\(prefix)\(value)"
        case .outerBull: return "\(prefix)OB"
        case .innerBull: return "\(prefix)IB"
        case .miss: return "MISS"
        }
    }

    private func multiplierLabel(_ multiplier: DartMultiplier) -> String {
        switch multiplier {
        case .single: return "S"
        case .double: return "D"
        case .triple: return "T"
        }
    }

    private func multiplierAccessibility(_ multiplier: DartMultiplier) -> String {
        switch multiplier {
        case .single: return NSLocalizedString("scoring.multiplier.single.accessibility", comment: "")
        case .double: return NSLocalizedString("scoring.multiplier.double.accessibility", comment: "")
        case .triple: return NSLocalizedString("scoring.multiplier.triple.accessibility", comment: "")
        }
    }

    private func accessibilityLabel(for segment: DartSegment) -> String {
        switch segment {
        case let .oneToTwenty(value):
            return L10n.format("scoring.segment.number.accessibility", value)
        case .outerBull:
            return NSLocalizedString("scoring.segment.outerBull.accessibility", comment: "")
        case .innerBull:
            return NSLocalizedString("scoring.segment.innerBull.accessibility", comment: "")
        case .miss:
            return NSLocalizedString("scoring.segment.miss.accessibility", comment: "")
        }
    }
}
