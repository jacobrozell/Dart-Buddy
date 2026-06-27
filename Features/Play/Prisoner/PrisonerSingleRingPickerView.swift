import SwiftUI

struct PrisonerSingleRingPickerView: View {
    let segment: Int
    let onSelect: (PrisonerDartHit) -> Void

    var body: some View {
        NavigationStack {
            List {
                Button {
                    onSelect(.playable(segment: segment))
                } label: {
                    Text(L10n.format("play.prisoner.ringPicker.playableFormat", segment))
                        .foregroundStyle(Brand.textPrimary)
                }
                Button {
                    onSelect(.innerSingle(segment: segment))
                } label: {
                    Text(L10n.format("play.prisoner.ringPicker.innerSingleFormat", segment))
                        .foregroundStyle(Brand.textPrimary)
                }
            }
            .navigationTitle(L10n.string("play.prisoner.ringPicker.title"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
        .accessibilityLabel(L10n.string("play.prisoner.ringPicker.accessibility"))
    }
}
