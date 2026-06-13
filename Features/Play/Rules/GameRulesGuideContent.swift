import SwiftUI

struct GameRulesGuideContent: View {
    @State private var selectedMode: MatchType
    private let initialMode: MatchType
    private let showsModePicker: Bool

    init(initialMode: MatchType, showsModePicker: Bool = false) {
        self.initialMode = initialMode
        self.showsModePicker = showsModePicker
        _selectedMode = State(initialValue: initialMode)
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

            ForEach(currentGuide.sections) { section in
                ruleCard(section)
            }
        }
        .onAppear { selectedMode = initialMode }
    }

    private var currentGuide: GameRulesGuide {
        GameRulesCatalog.guide(for: showsModePicker ? selectedMode : initialMode)
    }

    private func ruleCard(_ section: GameRulesSection) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Text(LocalizedStringKey(section.titleKey))
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)
            Text(LocalizedStringKey(section.bodyKey))
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
