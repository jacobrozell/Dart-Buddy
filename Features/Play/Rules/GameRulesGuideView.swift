import SwiftUI

struct GameRulesGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMode: MatchType
    private let initialMode: MatchType

    init(initialMode: MatchType) {
        self.initialMode = initialMode
        _selectedMode = State(initialValue: initialMode)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                    BrandSegmented(
                        options: GameRulesCatalog.supportedMatchTypes.map { mode in
                            (mode, mode == .x01 ? L10n.string("play.x01.title") : L10n.string("play.cricket.title"))
                        },
                        selection: $selectedMode,
                        accessibilityIdentifiers: [
                            .x01: "rules_mode_x01",
                            .cricket: "rules_mode_cricket"
                        ]
                    )
                    .frame(maxWidth: .infinity)

                    ForEach(currentGuide.sections) { section in
                        ruleCard(section)
                    }
                }
                .padding(.horizontal, DS.Spacing.s4)
                .padding(.vertical, DS.Spacing.s4)
            }
            .background(Brand.background.ignoresSafeArea())
            .navigationTitle(L10n.gameRulesSheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.gameRulesSheetDone) { dismiss() }
                        .accessibilityIdentifier("gameRulesDoneButton")
                }
            }
        }
        .presentationDragIndicator(.visible)
        .onAppear { selectedMode = initialMode }
    }

    private var currentGuide: GameRulesGuide {
        GameRulesCatalog.guide(for: selectedMode)
    }

    private func ruleCard(_ section: GameRulesSection) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Text(LocalizedStringKey(section.titleKey))
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)
            Text(LocalizedStringKey(section.bodyKey))
                .font(.subheadline)
                .foregroundStyle(Brand.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.s4)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("gameRulesSection_\(section.id)")
    }
}
