import SwiftUI

struct SetupFootballOptionChips: View {
    @ObservedObject var setupViewModel: MatchSetupViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

@ViewBuilder
    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: DS.Spacing.s3), GridItem(.flexible(), spacing: DS.Spacing.s3)],
                spacing: DS.Spacing.s3
            ) {
                footballGoalsChip
                footballKickoffModeChip
            }
        } else {
            HStack(spacing: DS.Spacing.s3) {
                footballGoalsChip
                footballKickoffModeChip
            }
        }
    }

    private var footballGoalsChip: some View {
        let value = L10n.format("play.football.setup.goalsValueFormat", setupViewModel.footballGoalsToWin)
        return SetupOptionChipHelpers.chip(titleKey: "play.football.setup.goalsToWin", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach([5, 7, 10, 15, 20], id: \.self) { count in
                    Button(L10n.format("play.football.setup.goalsValueFormat", count)) {
                        setupViewModel.footballGoalsToWin = count
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
                SetupOptionChipHelpers.chipAccessibilityLabel("play.football.setup.goalsToWin", value)
            )
            .accessibilityIdentifier("setup_footballGoalsChip")
        }
    }

    private var footballKickoffModeChip: some View {
        let value = setupViewModel.footballKickoffMode.displayName
        return SetupOptionChipHelpers.chip(titleKey: "play.football.setup.kickoffMode", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach(FootballKickoffMode.allCases, id: \.rawValue) { mode in
                    Button(mode.displayName) {
                        setupViewModel.footballKickoffMode = mode
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
                SetupOptionChipHelpers.chipAccessibilityLabel("play.football.setup.kickoffMode", value)
            )
            .accessibilityIdentifier("setup_footballKickoffModeChip")
        }
    }
}
