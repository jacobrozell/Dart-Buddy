import SwiftUI

/// Shared filter row for the Activity tab (mode menu + period + player).
struct ActivityFilterBar: View {
    @Binding var modeFilter: ActivityModeFilter
    @Binding var period: ActivityPeriod
    @Binding var playerFilter: UUID?
    let playerOptions: [PlayerSummary]
    let selectedPlayerName: String?

    var body: some View {
        VStack(spacing: DS.Spacing.s2) {
            modeFilterMenu
            BrandSegmented(
                options: ActivityPeriod.allCases.map { ($0, $0.title) },
                selection: $period
            )
            playerFilterMenu
        }
    }

    private var modeFilterMenu: some View {
        Menu {
            Button { modeFilter = .all } label: {
                modeMenuLabel(for: .all)
            }
            ForEach(GameModeSection.allCases) { section in
                let entries = GameModeCatalog.entries(in: section).filter(\.isAvailable)
                if !entries.isEmpty {
                    Section(L10n.string(section.titleKey)) {
                        ForEach(entries) { entry in
                            if let filter = ActivityModeFilter.from(catalogEntryId: entry.id) {
                                Button { modeFilter = filter } label: {
                                    modeMenuLabel(for: filter)
                                }
                            }
                        }
                    }
                }
            }
        } label: {
            filterMenuLabel(
                title: modeFilter.title,
                leadingSymbol: "gamecontroller.fill"
            )
        }
        .accessibilityIdentifier("activityModeFilterMenu")
        .accessibilityLabel(
            L10n.format("activity.filter.mode.accessibilityFormat", modeFilter.title)
        )
    }

    @ViewBuilder
    private func modeMenuLabel(for filter: ActivityModeFilter) -> some View {
        if modeFilter == filter {
            if let matchType = filter.matchType {
                Label {
                    Text(filter.title)
                } icon: {
                    GameModeBadge(type: matchType, size: 20)
                }
            } else {
                Label(filter.title, systemImage: "checkmark")
            }
        } else if let matchType = filter.matchType {
            Label {
                Text(filter.title)
            } icon: {
                GameModeBadge(type: matchType, size: 20)
            }
        } else {
            Text(filter.title)
        }
    }

    private var playerFilterMenu: some View {
        Menu {
            Button { playerFilter = nil } label: {
                if playerFilter == nil {
                    Label(String(localized: "stats.filter.allPlayers"), systemImage: "checkmark")
                } else {
                    Text(String(localized: "stats.filter.allPlayers"))
                }
            }
            if !playerOptions.isEmpty {
                Divider()
                ForEach(playerOptions) { player in
                    Button { playerFilter = player.id } label: {
                        if playerFilter == player.id {
                            Label(player.name, systemImage: "checkmark")
                        } else {
                            Text(player.name)
                        }
                    }
                }
            }
        } label: {
            filterMenuLabel(
                title: selectedPlayerName ?? String(localized: "stats.filter.allPlayers"),
                leadingSymbol: "person.crop.circle"
            )
        }
        .accessibilityIdentifier("activityPlayerFilterMenu")
        .accessibilityLabel(
            L10n.format(
                "activity.filter.player.accessibilityFormat",
                selectedPlayerName ?? L10n.string("stats.filter.allPlayers")
            )
        )
    }

    private func filterMenuLabel(title: String, leadingSymbol: String) -> some View {
        HStack {
            Image(systemName: leadingSymbol)
                .accessibilityHidden(true)
            Text(title)
                .lineLimit(1)
            Spacer()
            Image(systemName: "chevron.down")
                .font(.caption.weight(.semibold))
                .accessibilityHidden(true)
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(Brand.textPrimary)
        .padding(.horizontal, DS.Spacing.s3)
        .padding(.vertical, DS.Spacing.s3)
        .frame(minHeight: 44)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }
}
