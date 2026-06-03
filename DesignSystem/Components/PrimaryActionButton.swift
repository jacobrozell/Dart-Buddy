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
                    in: RoundedRectangle(cornerRadius: DS.Radius.sm)
                )
                .overlay {
                    if !isEnabled {
                        RoundedRectangle(cornerRadius: DS.Radius.sm)
                            .stroke(Brand.textSecondary.opacity(0.35), lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
