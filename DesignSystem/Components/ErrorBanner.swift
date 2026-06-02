import SwiftUI

struct ErrorBanner: View {
    let messageKey: String

    var body: some View {
        Text(LocalizedStringKey(messageKey))
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Brand.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DS.Spacing.s3)
            .padding(.vertical, DS.Spacing.s2)
            .background(Brand.red.opacity(0.12), in: RoundedRectangle(cornerRadius: DS.Radius.sm))
            .accessibilityIdentifier("errorBanner")
    }
}
