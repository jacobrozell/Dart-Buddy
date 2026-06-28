import SwiftUI

struct PresetBotCustomizeSection: View {
    let difficulty: BotDifficulty
    let onCustomize: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            Text(L10n.presetBotCustomizeTitle)
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)

            Text(L10n.format("presetBot.customize.bodyFormat", difficulty.displayName))
                .font(.footnote)
                .foregroundStyle(Brand.textSecondary)

            Button(action: onCustomize) {
                Label(L10n.presetBotCustomizeAction, systemImage: "slider.horizontal.3")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("presetBot_customize")
        }
        .padding(DS.Spacing.s4)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }
}
