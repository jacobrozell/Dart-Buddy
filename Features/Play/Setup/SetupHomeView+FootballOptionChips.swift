import SwiftUI

extension SetupHomeView {
    @ViewBuilder
    var footballChipsGrid: some View {
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
        chip(title: "play.football.setup.goalsToWin", color: Brand.key) {
            Menu {
                ForEach([5, 7, 10, 15, 20], id: \.self) { count in
                    Button(L10n.format("play.football.setup.goalsValueFormat", count)) {
                        setupViewModel.footballGoalsToWin = count
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(
                    L10n.format("play.football.setup.goalsValueFormat", setupViewModel.footballGoalsToWin),
                    color: Brand.key,
                    showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_footballGoalsChip")
        }
    }

    private var footballKickoffModeChip: some View {
        chip(title: "play.football.setup.kickoffMode", color: Brand.amber) {
            Menu {
                ForEach(FootballKickoffMode.allCases, id: \.rawValue) { mode in
                    Button(mode.displayName) {
                        setupViewModel.footballKickoffMode = mode
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(
                    setupViewModel.footballKickoffMode.displayName,
                    color: Brand.amber,
                    showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_footballKickoffModeChip")
        }
    }
}
