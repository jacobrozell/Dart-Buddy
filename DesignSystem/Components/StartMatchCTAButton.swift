import SwiftUI

/// Shared empty-state CTA that routes users to Play setup (Statistics, History).
struct StartMatchCTAButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(L10n.startMatchCTA)
                .font(.headline.weight(.bold))
                .foregroundStyle(Brand.textOnAccent)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Brand.redAccent, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("emptyStateStartMatchButton")
    }
}
