import SwiftUI

struct LoopWireTargetPickerView: View {
    let dart: DartInput
    let options: [LoopWireTargetArea]
    let onSelect: (LoopWireTargetArea) -> Void

    var body: some View {
        NavigationStack {
            List(options, id: \.self) { option in
                Button {
                    onSelect(option)
                } label: {
                    Text(option.displayLabel)
                        .foregroundStyle(Brand.textPrimary)
                }
            }
            .navigationTitle(L10n.string("play.loop.wireTargetPicker.title"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .accessibilityLabel(L10n.string("play.loop.wireTargetPicker.accessibility"))
    }
}
