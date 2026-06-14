import SwiftUI

struct SetupNineLivesOptionChips: View {
    @ObservedObject var setupViewModel: MatchSetupViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

@ViewBuilder
    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: DS.Spacing.s3)],
                spacing: DS.Spacing.s3
            ) {
                nineLivesStartingLivesChip
            }
        } else {
            HStack(spacing: DS.Spacing.s3) {
                nineLivesStartingLivesChip
            }
        }
    }

    private var nineLivesStartingLivesChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.nineLives.setup.startingLives", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach(NineLivesStartingLives.allCases, id: \.rawValue) { option in
                    Button(option.displayName) {
                        setupViewModel.nineLivesStartingLives = option
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(
                    setupViewModel.nineLivesStartingLives.displayName,
                    color: Brand.key,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_nineLivesStartingLivesChip")
        }
    }
}
