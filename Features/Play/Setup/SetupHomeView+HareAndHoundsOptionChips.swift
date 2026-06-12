import SwiftUI

extension SetupHomeView {
    @ViewBuilder
    var hareAndHoundsChipsGrid: some View {
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
        chip(title: "play.hareAndHounds.setup.houndStart", color: Brand.key) {
            Menu {
                ForEach(HoundStartPosition.allCases, id: \.rawValue) { position in
                    Button(position.displayName) {
                        setupViewModel.hareAndHoundsHoundStart = position
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(
                    setupViewModel.hareAndHoundsHoundStart.displayName,
                    color: Brand.key,
                    showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_hareAndHoundsHoundStartChip")
        }
    }
}
