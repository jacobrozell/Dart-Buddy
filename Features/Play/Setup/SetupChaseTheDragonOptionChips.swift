import SwiftUI

struct SetupChaseTheDragonOptionChips: View {
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
                chaseTheDragonLapsChip
            }
        } else {
            HStack(spacing: DS.Spacing.s3) {
                chaseTheDragonLapsChip
            }
        }
    }

    private var chaseTheDragonLapsChip: some View {
        let value = setupViewModel.chaseTheDragonLaps.displayName
        return SetupOptionChipHelpers.chip(titleKey: "play.chaseTheDragon.setup.laps", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach(ChaseTheDragonLaps.allCases, id: \.rawValue) { laps in
                    Button(laps.displayName) {
                        setupViewModel.chaseTheDragonLaps = laps
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(
                    value,
                    color: Brand.key,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true
                )
            }
            .accessibilityLabel(
                SetupOptionChipHelpers.chipAccessibilityLabel("play.chaseTheDragon.setup.laps", value)
            )
            .accessibilityIdentifier("setup_chaseTheDragonLapsChip")
        }
    }
}
