import SwiftUI

extension SetupHomeView {
    @ViewBuilder
    var fiftyOneByFivesChipsGrid: some View {
        if dynamicTypeSize.isAccessibilitySize {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: DS.Spacing.s3),
                    GridItem(.flexible(), spacing: DS.Spacing.s3),
                ],
                spacing: DS.Spacing.s3
            ) {
                fiftyOneByFivesTargetChip
                fiftyOneByFivesMustFinishExactChip
            }
        } else {
            HStack(spacing: DS.Spacing.s3) {
                fiftyOneByFivesTargetChip
                fiftyOneByFivesMustFinishExactChip
            }
        }
    }

    private var fiftyOneByFivesTargetChip: some View {
        chip(titleKey: "play.fiftyOneByFives.setup.targetPoints", color: Brand.key) {
            Menu {
                ForEach([31, 41, 51, 61, 101], id: \.self) { target in
                    Button(L10n.format("play.fiftyOneByFives.setup.targetPointsValueFormat", target)) {
                        setupViewModel.fiftyOneByFivesTargetPoints = target
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(
                    L10n.format(
                        "play.fiftyOneByFives.setup.targetPointsValueFormat",
                        setupViewModel.fiftyOneByFivesTargetPoints
                    ),
                    color: Brand.key,
                    showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_fiftyOneByFivesTargetChip")
        }
    }

    private var fiftyOneByFivesMustFinishExactChip: some View {
        chip(titleKey: "play.fiftyOneByFives.setup.mustFinishExact", color: Brand.amber) {
            Toggle(isOn: Binding(
                get: { setupViewModel.fiftyOneByFivesMustFinishExact },
                set: {
                    setupViewModel.fiftyOneByFivesMustFinishExact = $0
                    setupViewModel.revalidate()
                }
            )) {
                EmptyView()
            }
            .labelsHidden()
            .accessibilityIdentifier("setup_fiftyOneByFivesMustFinishExactToggle")
        }
    }
}
