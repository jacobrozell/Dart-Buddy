import SwiftUI

struct ModesRootView: View {
    var onSelectMode: (GameModeCatalogEntry) -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var searchText = ""
    @State private var showsRulesForEntry: GameModeCatalogEntry?

    private var filteredSections: [(GameModeSection, [GameModeCatalogEntry])] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return GameModeSection.allCases.compactMap { section in
            let entries = GameModeCatalog.entries(in: section).filter { entry in
                entry.matchesSearchQuery(query)
            }
            guard !entries.isEmpty else { return nil }
            return (section, entries)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                    BrandRootScreenTitle(title: L10n.modesTitle)

                    searchField

                    ForEach(filteredSections, id: \.0) { section, entries in
                        sectionHeader(section, count: entries.count)
                        if horizontalSizeClass == .regular {
                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible())],
                                spacing: DS.Spacing.s2
                            ) {
                                ForEach(entries) { entry in
                                    catalogCard(entry)
                                }
                            }
                        } else {
                            ForEach(entries) { entry in
                                catalogCard(entry)
                            }
                        }
                    }
                    .animation(MotionPolicy.fastAnimation(reduceMotion: reduceMotion), value: searchText)
                }
                .padding(.horizontal, DS.Spacing.s4)
                .tabRootScrollChrome()
                .frame(maxWidth: GameplayLayout.contentMaxWidth(horizontalSizeClass: horizontalSizeClass))
                .frame(maxWidth: .infinity)
            }
            .background(Brand.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(item: $showsRulesForEntry) { entry in
                if let matchType = entry.matchType {
                    GameRulesGuideView(initialMode: matchType)
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: DS.Spacing.s2) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Brand.textSecondary)
                .accessibilityHidden(true)
            TextField(L10n.modesSearchPlaceholder, text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(Brand.textPrimary)
                .accessibilityIdentifier("modesSearchField")
        }
        .padding(.horizontal, DS.Spacing.s3)
        .padding(.vertical, DS.Spacing.s3)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    private func sectionHeader(_ section: GameModeSection, count: Int) -> some View {
        HStack {
            Text(L10n.string(section.titleKey))
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)
            Spacer()
            Text(L10n.format("modes.section.countFormat", count))
                .font(.caption)
                .foregroundStyle(Brand.textSecondary)
        }
        .accessibilityAddTraits(.isHeader)
    }

    private func catalogCard(_ entry: GameModeCatalogEntry) -> some View {
        GameModeCatalogCard(
            entry: entry,
            isSelectable: entry.isSelectableInPlaySetup,
            onSelect: entry.isSelectableInPlaySetup ? { onSelectMode(entry) } : nil,
            onLearnRules: entry.hasRulesGuide ? { showsRulesForEntry = entry } : nil
        )
    }
}

