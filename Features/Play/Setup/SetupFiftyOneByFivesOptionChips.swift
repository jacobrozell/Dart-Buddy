import SwiftUI

struct SetupFiftyOneByFivesOptionChips: View {
    @ObservedObject var setupViewModel: MatchSetupViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

@ViewBuilder
    var body: some View {
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
        let value = L10n.format(
            "play.fiftyOneByFives.setup.targetPointsValueFormat",
            setupViewModel.fiftyOneByFivesTargetPoints
        )
        return SetupOptionChipHelpers.chip(titleKey: "play.fiftyOneByFives.setup.targetPoints", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach([31, 41, 51, 61, 101], id: \.self) { target in
                    Button(L10n.format("play.fiftyOneByFives.setup.targetPointsValueFormat", target)) {
                        setupViewModel.fiftyOneByFivesTargetPoints = target
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
                SetupOptionChipHelpers.chipAccessibilityLabel("play.fiftyOneByFives.setup.targetPoints", value)
            )
            .accessibilityIdentifier("setup_fiftyOneByFivesTargetChip")
        }
    }

    private var fiftyOneByFivesMustFinishExactChip: some View {
        let value = setupViewModel.fiftyOneByFivesMustFinishExact
            ? L10n.string("common.on")
            : L10n.string("common.off")
        return SetupOptionChipHelpers.chip(titleKey: "play.fiftyOneByFives.setup.mustFinishExact", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
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
            .accessibilityLabel(
                SetupOptionChipHelpers.chipAccessibilityLabel("play.fiftyOneByFives.setup.mustFinishExact", value)
            )
            .accessibilityIdentifier("setup_fiftyOneByFivesMustFinishExactToggle")
        }
    }
}
