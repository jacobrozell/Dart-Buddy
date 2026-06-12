import SwiftUI

extension SetupHomeView {
    @ViewBuilder
    var nineLivesChipsGrid: some View {
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
        chip(title: "play.nineLives.setup.startingLives", color: Brand.key) {
            Menu {
                ForEach(NineLivesStartingLives.allCases, id: \.rawValue) { option in
                    Button(option.displayName) {
                        setupViewModel.nineLivesStartingLives = option
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(
                    setupViewModel.nineLivesStartingLives.displayName,
                    color: Brand.key,
                    showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_nineLivesStartingLivesChip")
        }
    }
}
