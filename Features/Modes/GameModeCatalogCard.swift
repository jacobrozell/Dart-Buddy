import SwiftUI

/// Catalog row for one game mode in the Modes tab.
struct GameModeCatalogCard: View {
    let entry: GameModeCatalogEntry
    /// When set, overrides `entry.isAvailable` for tap + badge behavior (Play setup picker).
    var isSelectable: Bool?
    var isSelected = false
    var onSelect: (() -> Void)?
    var onLearnRules: (() -> Void)?

    private var selectable: Bool { isSelectable ?? entry.isAvailable }

    var body: some View {
        Group {
            if selectable {
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
        // The combined label drops the visible player-count text; surface it as the
        // element's value so VoiceOver still announces "1+ players" / "1 player".
        .accessibilityValue(entry.playerCountLabel)
        .accessibilityAddTraits(selectable ? .isButton : [])
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Brand.green)
                                .accessibilityHidden(true)
                        } else if !selectable {
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
                            .accessibilityHidden(true)
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
        if selectable {
            if isSelected {
                return L10n.format(
                    "modes.card.selectedAccessibilityFormat",
                    entry.localizedName,
                    entry.localizedBlurb
                )
            }
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
