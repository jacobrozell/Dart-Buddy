import SwiftUI

struct SetupHomeRosterSection: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ObservedObject var setupViewModel: MatchSetupViewModel
    @Binding var startTask: Task<Void, Never>?
    let onShowCustomBot: () -> Void
    let onShowAddPlayer: () -> Void

    private var usesWideLayout: Bool {
        GameplayLayout.usesWideSetupHomeLayout(
            horizontalSizeClass: horizontalSizeClass,
            dynamicTypeSize: dynamicTypeSize
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.addToMatchSection)
                    .font(.headline)
                    .foregroundStyle(Brand.textPrimary)
                Spacer(minLength: DS.Spacing.s2)
            }
            SetupSelectedRosterContent(setupViewModel: setupViewModel)
            if !usesWideLayout {
                SetupRosterActionButtons(
                    setupViewModel: setupViewModel,
                    startTask: $startTask,
                    onShowCustomBot: onShowCustomBot,
                    onShowAddPlayer: onShowAddPlayer
                )
                .padding(.top, DS.Spacing.s2)
            }
            SetupAvailablePlayersContent(setupViewModel: setupViewModel)
        }
    }
}
