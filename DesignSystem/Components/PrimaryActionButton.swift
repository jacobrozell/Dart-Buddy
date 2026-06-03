import SwiftUI

struct PrimaryActionButton: View {
    let title: LocalizedStringKey
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(isEnabled ? Brand.textOnAccent : Brand.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                    isEnabled ? Brand.redAccent : Brand.cardElevated,
                    in: RoundedRectangle(cornerRadius: DS.Radius.lg)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
