import SwiftUI

struct PrimaryActionButton: View {
    let title: LocalizedStringKey
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(isEnabled ? Brand.red : Brand.red.opacity(0.4), in: RoundedRectangle(cornerRadius: DS.Radius.lg))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
