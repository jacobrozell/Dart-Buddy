import SwiftUI

struct GameRulesGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private let initialMode: MatchType
    private let showsModePicker: Bool

    init(initialMode: MatchType, showsModePicker: Bool = false) {
        self.initialMode = initialMode
        self.showsModePicker = showsModePicker
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                GameRulesGuideContent(initialMode: initialMode, showsModePicker: showsModePicker)
                    .padding(.horizontal, DS.Spacing.s4)
                    .padding(.vertical, DS.Spacing.s4)
                    .readableRootContentWidth(horizontalSizeClass)
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
