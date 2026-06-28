import SwiftUI

struct ErrorBanner: View {
    enum Style {
        case error
        case hint

        var background: Color {
            switch self {
            case .error: Brand.redAccent
            case .hint: Brand.amber
            }
        }

        var foreground: Color {
            switch self {
            case .error: Brand.textOnAccent
            case .hint: Brand.inkOnBright
            }
        }
    }

    let messageKey: String
    var style: Style = .error

    var body: some View {
        Text(L10n.string(messageKey))
            .font(.footnote.weight(.semibold))
            .foregroundStyle(style.foreground)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DS.Spacing.s3)
            .padding(.vertical, DS.Spacing.s2)
            .background(style.background, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
            .accessibilityIdentifier("errorBanner")
            .motionBannerEntrance()
    }
}
