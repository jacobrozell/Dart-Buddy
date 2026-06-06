import SwiftUI

/// Catalog row for one game mode in the Modes tab.
struct GameModeCatalogCard: View {
    let entry: GameModeCatalogEntry
    var onSelect: (() -> Void)?
    var onLearnRules: (() -> Void)?

    var body: some View {
        Group {
            if entry.isAvailable {
                Button(action: { onSelect?() }) {
                    cardContent
                }
                .buttonStyle(.plain)
            } else {
                cardContent
                    .opacity(0.72)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(cardAccessibilityLabel)
        .accessibilityAddTraits(entry.isAvailable ? .isButton : [])
        .accessibilityIdentifier("modes_card_\(entry.id)")
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            HStack(alignment: .top, spacing: DS.Spacing.s3) {
                if let matchType = entry.matchType {
                    GameModeBadge(type: matchType, size: 32)
                } else {
                    GameModeCatalogBadge(entry: entry, size: 32)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: DS.Spacing.s2) {
                        Text(entry.localizedName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Brand.textPrimary)
                        Spacer(minLength: 0)
                        if !entry.isAvailable {
                            StatusBadge(
                                text: L10n.string("play.party.comingSoon"),
                                color: Brand.textSecondary
                            )
                        }
                        Text(entry.playerCountLabel)
                            .font(.caption)
                            .foregroundStyle(Brand.textSecondary)
                    }
                    Text(entry.localizedBlurb)
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let onLearnRules {
                Button(action: onLearnRules) {
                    HStack(spacing: 4) {
                        Image(systemName: "book.pages")
                        Text(L10n.gameRulesLearnButton)
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(Brand.green)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .frame(minHeight: 44, alignment: .trailing)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.gameRulesLearnButton)
                .accessibilityIdentifier("modes_learnRules_\(entry.id)")
            }
        }
        .padding(DS.Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .contentShape(Rectangle())
    }

    private var cardAccessibilityLabel: String {
        if entry.isAvailable {
            return L10n.format("modes.card.availableAccessibilityFormat", entry.localizedName, entry.localizedBlurb)
        }
        return L10n.format(
            "modes.card.comingSoonAccessibilityFormat",
            entry.localizedName,
            entry.localizedBlurb,
            L10n.string("play.party.comingSoon")
        )
    }
}
