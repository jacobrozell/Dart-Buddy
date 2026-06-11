import SwiftUI

struct PrimaryActionButton: View {
    enum Accent {
        case red
        case green

        var fill: Color {
            switch self {
            case .red: Brand.redAccent
            case .green: Brand.green
            }
        }
    }

    let title: LocalizedStringKey
    var accent: Accent = .red
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var accessibilityIdentifier: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(Brand.textOnAccent)
                        .accessibilityLabel(L10n.loading)
                } else {
                    Text(title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(isEnabled ? Brand.textOnAccent : Brand.textDisabled)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                isEnabled ? accent.fill : Brand.cardElevated,
                in: RoundedRectangle(cornerRadius: DS.Radius.sm)
            )
                .overlay {
                    if !isEnabled {
                        RoundedRectangle(cornerRadius: DS.Radius.sm)
                            .stroke(Brand.textDisabled.opacity(0.6), lineWidth: 1.5)
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .modifier(OptionalAccessibilityIdentifier(identifier: accessibilityIdentifier))
    }
}
