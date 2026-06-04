import SwiftUI

/// Vertical list of party game choices. One selection at a time; unavailable games show a badge.
struct PartyGamePickerView: View {
    let games: [PartyGame]
    @Binding var selection: PartyGame

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Text(L10n.string("play.party.gamesSection"))
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: DS.Spacing.s2) {
                ForEach(games) { game in
                    partyGameRow(game)
                }
            }
        }
    }

    private func partyGameRow(_ game: PartyGame) -> some View {
        let isSelected = selection == game
        return Button {
            selection = game
        } label: {
            HStack(alignment: .center, spacing: DS.Spacing.s3) {
                Image(systemName: game.systemImageName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? Brand.green : Brand.textSecondary)
                    .frame(width: 28)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.string(game.titleKey))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.textPrimary)
                    Text(L10n.string(game.subtitleKey))
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !game.isAvailable {
                    StatusBadge(
                        text: L10n.string("play.party.comingSoon"),
                        color: Brand.textSecondary
                    )
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Brand.green)
                        .accessibilityHidden(true)
                }
            }
            .padding(DS.Spacing.s3)
            .frame(minHeight: 44)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.sm)
                    .stroke(isSelected ? Brand.green : Color.clear, lineWidth: 2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(partyGameAccessibilityLabel(game, isSelected: isSelected))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(game.accessibilityIdentifier)
    }

    private func partyGameAccessibilityLabel(_ game: PartyGame, isSelected: Bool) -> String {
        let title = L10n.string(game.titleKey)
        let detail = L10n.string(game.subtitleKey)
        if !game.isAvailable {
            return L10n.format(
                "play.party.gameAccessibilityComingSoonFormat",
                title,
                detail,
                L10n.string("play.party.comingSoon")
            )
        }
        if isSelected {
            return L10n.format("play.party.gameAccessibilitySelectedFormat", title, detail)
        }
        return L10n.format("play.party.gameAccessibilityFormat", title, detail)
    }
}
