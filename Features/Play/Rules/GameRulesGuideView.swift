import SwiftUI

struct GameRulesGuideView: View {
    @Environment(\.dismiss) private var dismiss
    private let initialMode: MatchType

    init(initialMode: MatchType) {
        self.initialMode = initialMode
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                GameRulesGuideContent(initialMode: initialMode)
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
    }
}
