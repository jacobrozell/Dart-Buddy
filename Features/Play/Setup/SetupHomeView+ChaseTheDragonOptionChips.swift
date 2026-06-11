import SwiftUI

extension SetupHomeView {
    @ViewBuilder
    var chaseTheDragonChipsGrid: some View {
        if dynamicTypeSize.isAccessibilitySize {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: DS.Spacing.s3)],
                spacing: DS.Spacing.s3
            ) {
                chaseTheDragonLapsChip
            }
        } else {
            HStack(spacing: DS.Spacing.s3) {
                chaseTheDragonLapsChip
            }
        }
    }

    private var chaseTheDragonLapsChip: some View {
        chip(title: "play.chaseTheDragon.setup.laps", color: Brand.amber) {
            Menu {
                ForEach(ChaseTheDragonLaps.allCases, id: \.rawValue) { laps in
                    Button(laps.displayName) {
                        setupViewModel.chaseTheDragonLaps = laps
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(
                    setupViewModel.chaseTheDragonLaps.displayName,
                    color: Brand.amber,
                    showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_chaseTheDragonLapsChip")
        }
    }
}
