import SwiftUI

struct GameRulesGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private let initialMode: MatchType?
    private let catalogPreviewId: String?
    private let showsModePicker: Bool

    init(initialMode: MatchType, showsModePicker: Bool = false) {
        self.initialMode = initialMode
        self.catalogPreviewId = nil
        self.showsModePicker = showsModePicker
    }

    init(catalogPreviewId: String) {
        self.initialMode = nil
        self.catalogPreviewId = catalogPreviewId
        self.showsModePicker = false
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                guideContent
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

    @ViewBuilder
    private var guideContent: some View {
        if let catalogPreviewId {
            GameRulesGuideContent(catalogPreviewId: catalogPreviewId)
        } else if let initialMode {
            GameRulesGuideContent(initialMode: initialMode, showsModePicker: showsModePicker)
        }
    }
}
