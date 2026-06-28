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

            ForEach(currentSections) { section in
                ruleCard(section)
            }
        }
        .onAppear {
            if let initialMode {
                selectedMode = initialMode
            }
        }
    }

    private var currentSections: [GameRulesSection] {
        if let catalogPreviewId {
            return GameRulesCatalog.previewGuide(for: catalogPreviewId).sections
        }
        let mode = showsModePicker ? selectedMode : (initialMode ?? .x01)
        return GameRulesCatalog.guide(for: mode).sections
    }

    private func ruleCard(_ section: GameRulesSection) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Text(L10n.string(section.titleKey))
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)
            Text(L10n.string(section.bodyKey))
                .font(.subheadline)
                .foregroundStyle(Brand.textBodyOnCard)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.s4)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("gameRulesSection_\(section.id)")
    }
}
