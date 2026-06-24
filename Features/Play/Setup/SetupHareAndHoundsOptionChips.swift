import SwiftUI

struct SetupHareAndHoundsOptionChips: View {
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
                hareAndHoundsHoundStartChip
            }
        } else {
            HStack(spacing: DS.Spacing.s3) {
                hareAndHoundsHoundStartChip
            }
        }
    }

    private var hareAndHoundsHoundStartChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.hareAndHounds.setup.houndStart", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach(HoundStartPosition.allCases, id: \.rawValue) { position in
                    Button(position.displayName) {
                        setupViewModel.hareAndHoundsHoundStart = position
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(
                    setupViewModel.hareAndHoundsHoundStart.displayName,
                    color: Brand.key,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_hareAndHoundsHoundStartChip")
        }
    }
}
