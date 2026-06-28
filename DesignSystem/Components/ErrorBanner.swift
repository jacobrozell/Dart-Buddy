import SwiftUI

struct ErrorBanner: View {
    let messageKey: String

    var body: some View {
        Text(L10n.string(messageKey))
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Brand.textOnAccent)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DS.Spacing.s3)
            .padding(.vertical, DS.Spacing.s2)
            .background(Brand.redAccent, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
            .accessibilityIdentifier("errorBanner")
            .motionBannerEntrance()
    }
}
