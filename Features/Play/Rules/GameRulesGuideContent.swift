import SwiftUI

struct GameRulesGuideContent: View {
    @State private var selectedMode: MatchType
    private let initialMode: MatchType?
    private let catalogPreviewId: String?
    private let showsModePicker: Bool

    init(initialMode: MatchType, showsModePicker: Bool = false) {
        self.initialMode = initialMode
        self.catalogPreviewId = nil
        self.showsModePicker = showsModePicker
        _selectedMode = State(initialValue: initialMode)
    }

    init(catalogPreviewId: String) {
        self.initialMode = nil
        self.catalogPreviewId = catalogPreviewId
        self.showsModePicker = false
        _selectedMode = State(initialValue: .x01)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
            if showsModePicker {
                BrandSegmented(
                    options: GameRulesCatalog.supportedMatchTypes.map { mode in
                        (mode, MatchConfigText.modeLabel(for: mode))
                    },
                    selection: $selectedMode,
                    accessibilityIdentifiers: Dictionary(
                        uniqueKeysWithValues: GameRulesCatalog.supportedMatchTypes.map {
                            ($0, "rules_mode_\($0.rawValue)")
                        }
                    )
                )
                .frame(maxWidth: .infinity)
            }

            if let entry = headerCatalogEntry {
                modeHeader(entry)
            }

            ForEach(currentSections) { section in
                ruleCard(section, accent: headerMatchType.map { GameModeAccent.color(for: $0) } ?? Brand.green)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedMode)
        .onAppear {
            if let initialMode {
                selectedMode = initialMode
            }
        }
    }

    private var headerCatalogEntry: GameModeCatalogEntry? {
        if let catalogPreviewId {
            return GameModeCatalog.entry(for: catalogPreviewId)
        }
        return headerMatchType.flatMap { GameModeCatalog.entry(for: $0) }
    }

    private var headerMatchType: MatchType? {
        if let catalogPreviewId {
            return GameModeCatalog.entry(for: catalogPreviewId)?.matchType
        }
        if showsModePicker {
            return selectedMode
        }
        return initialMode
    }

    private var currentSections: [GameRulesSection] {
        if let catalogPreviewId {
            return GameRulesCatalog.previewGuide(for: catalogPreviewId).sections
        }
        let mode = showsModePicker ? selectedMode : (initialMode ?? .x01)
        return GameRulesCatalog.guide(for: mode).sections
    }

    private func modeHeader(_ entry: GameModeCatalogEntry) -> some View {
        HStack(alignment: .top, spacing: DS.Spacing.s3) {
            if let matchType = entry.matchType {
                GameModeBadge(type: matchType, size: 44)
            }

            VStack(alignment: .leading, spacing: DS.Spacing.s1) {
                Text(entry.localizedName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Brand.textPrimary)
                Text(entry.localizedBlurb)
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DS.Spacing.s4)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.md)
                .fill(Brand.card)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.md)
                        .strokeBorder(
                            (entry.matchType.map { GameModeAccent.color(for: $0) } ?? Brand.green).opacity(0.22),
                            lineWidth: 1
                        )
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("gameRulesModeHeader")
    }

    private func ruleCard(_ section: GameRulesSection, accent: Color) -> some View {
        HStack(alignment: .top, spacing: DS.Spacing.s3) {
            Image(systemName: section.symbolName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(accent)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 36, height: 36)
                .background(accent.opacity(0.14), in: RoundedRectangle(cornerRadius: DS.Radius.xs))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                Text(LocalizedStringKey(section.titleKey))
                    .font(.headline)
                    .foregroundStyle(Brand.textPrimary)
                GameRulesBodyText(bodyKey: section.bodyKey)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DS.Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("gameRulesSection_\(section.id)")
    }
}
