import SwiftUI

/// In-place mode picker for Play setup when the Modes tab is hidden (lean 1.0).
struct ModePickerSheet: View {
    let selectedEntryId: String?
    var onSelect: (GameModeCatalogEntry) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showsRulesForEntry: GameModeCatalogEntry?

    private var sections: [(GameModeSection, [GameModeCatalogEntry])] {
        GameModeCatalog.playSetupPickerSections()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                    ForEach(sections, id: \.0) { section, entries in
                        sectionBlock(section, entries: entries)
                    }
                }
                .padding(.horizontal, DS.Spacing.s4)
                .padding(.vertical, DS.Spacing.s3)
            }
            .background(Brand.background.ignoresSafeArea())
            .navigationTitle(L10n.string("play.setup.modePicker.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string("common.cancel")) {
                        dismiss()
                    }
                    .accessibilityIdentifier("modePicker_cancelButton")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(item: $showsRulesForEntry) { entry in
            if let matchType = entry.matchType {
                GameRulesGuideView(initialMode: matchType)
            }
        }
    }

    private func sectionBlock(_ section: GameModeSection, entries: [GameModeCatalogEntry]) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Text(L10n.string(section.titleKey))
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)
                .accessibilityAddTraits(.isHeader)

            if horizontalSizeClass == .regular {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: DS.Spacing.s2
                ) {
                    ForEach(entries) { entry in
                        pickerCard(entry)
                    }
                }
            } else {
                ForEach(entries) { entry in
                    pickerCard(entry)
                }
            }

            let moreComing = GameModeCatalog.playSetupPickerMoreComingCount(
                in: section,
                displayedCount: entries.count
            )
            if moreComing > 0 {
                Text(L10n.format("modes.section.moreComingFormat", moreComing))
                    .font(.caption)
                    .foregroundStyle(Brand.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, DS.Spacing.s1)
                    .accessibilityIdentifier("modePicker_moreComing_\(section.rawValue)")
            }
        }
    }

    private func pickerCard(_ entry: GameModeCatalogEntry) -> some View {
        GameModeCatalogCard(
            entry: entry,
            isSelectable: entry.isSelectableInPlaySetup,
            isSelected: entry.id == selectedEntryId,
            onSelect: entry.isSelectableInPlaySetup ? { onSelect(entry) } : nil,
            onLearnRules: entry.hasRulesGuide ? { showsRulesForEntry = entry } : nil
        )
    }
}
