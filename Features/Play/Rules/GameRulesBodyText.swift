import SwiftUI

/// Renders rules body copy with lightweight Markdown (bold labels, paragraph breaks).
struct GameRulesBodyText: View {
    let bodyKey: String

    var body: some View {
        Text(LocalizedStringKey(bodyKey))
            .font(.subheadline)
            .foregroundStyle(Brand.textBodyOnCard)
            .fixedSize(horizontal: false, vertical: true)
            .tint(Brand.textPrimary)
    }
}
