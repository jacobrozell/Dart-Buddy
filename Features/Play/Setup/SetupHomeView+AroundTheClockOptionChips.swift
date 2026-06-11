import SwiftUI

extension SetupHomeView {
    @ViewBuilder
    var aroundTheClockChipsGrid: some View {
        if dynamicTypeSize.isAccessibilitySize {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: DS.Spacing.s3), GridItem(.flexible(), spacing: DS.Spacing.s3)],
                spacing: DS.Spacing.s3
            ) {
                aroundTheClockBullFinishChip
                aroundTheClockResetPolicyChip
            }
        } else {
            HStack(spacing: DS.Spacing.s3) {
                aroundTheClockBullFinishChip
                aroundTheClockResetPolicyChip
            }
        }
    }

    private var aroundTheClockBullFinishChip: some View {
        chip(title: "play.aroundTheClock.setup.includeBullFinish", color: Brand.amber) {
            Button {
                setupViewModel.aroundTheClockIncludeBullFinish.toggle()
                setupViewModel.revalidate()
            } label: {
                chipBox(
                    setupViewModel.aroundTheClockIncludeBullFinish
                        ? L10n.string("common.on")
                        : L10n.string("common.off"),
                    color: Brand.amber,
                    showsMenuIndicator: false
                )
            }
            .accessibilityIdentifier("setup_aroundTheClockBullFinishChip")
        }
    }

    private var aroundTheClockResetPolicyChip: some View {
        chip(title: "play.aroundTheClock.setup.resetPolicy", color: Brand.key) {
            Menu {
                ForEach(AroundTheClockResetPolicy.allCases, id: \.rawValue) { policy in
                    Button(policy.displayName) {
                        setupViewModel.aroundTheClockResetPolicy = policy
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(
                    setupViewModel.aroundTheClockResetPolicy.displayName,
                    color: Brand.key,
                    showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_aroundTheClockResetPolicyChip")
        }
    }
}
