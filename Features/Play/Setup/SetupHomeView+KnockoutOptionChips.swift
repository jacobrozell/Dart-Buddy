import SwiftUI

extension SetupHomeView {
    @ViewBuilder
    var knockoutChipsGrid: some View {
        if dynamicTypeSize.isAccessibilitySize {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: DS.Spacing.s3)],
                spacing: DS.Spacing.s3
            ) {
                knockoutStrikesChip
            }
        } else {
            HStack(spacing: DS.Spacing.s3) {
                knockoutStrikesChip
            }
        }
    }

    private var knockoutStrikesChip: some View {
        chip(title: "play.knockout.setup.strikesToEliminate", color: Brand.red) {
            Menu {
                ForEach([1, 2, 3, 4, 5], id: \.self) { count in
                    Button(L10n.format("play.knockout.setup.strikesValueFormat", count)) {
                        setupViewModel.knockoutStrikesToEliminate = count
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(
                    L10n.format("play.knockout.setup.strikesValueFormat", setupViewModel.knockoutStrikesToEliminate),
                    color: Brand.red,
                    showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_knockoutStrikesChip")
        }
    }
}
