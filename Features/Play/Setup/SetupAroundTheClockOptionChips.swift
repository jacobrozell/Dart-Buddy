import SwiftUI

struct SetupAroundTheClockOptionChips: View {
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
        SetupOptionChipHelpers.chip(titleKey: "play.aroundTheClock.setup.includeBullFinish", color: Brand.amber, dynamicTypeSize: dynamicTypeSize) {
            Button {
                setupViewModel.aroundTheClockIncludeBullFinish.toggle()
                setupViewModel.revalidate()
            } label: {
                SetupOptionChipHelpers.chipBox(
                    setupViewModel.aroundTheClockIncludeBullFinish
                        ? L10n.string("common.on")
                        : L10n.string("common.off"),
                    color: Brand.amber,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: false
                )
            }
            .accessibilityIdentifier("setup_aroundTheClockBullFinishChip")
        }
    }

    private var aroundTheClockResetPolicyChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.aroundTheClock.setup.resetPolicy", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach(AroundTheClockResetPolicy.allCases, id: \.rawValue) { policy in
                    Button(policy.displayName) {
                        setupViewModel.aroundTheClockResetPolicy = policy
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(
                    setupViewModel.aroundTheClockResetPolicy.displayName,
                    color: Brand.key,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_aroundTheClockResetPolicyChip")
        }
    }
}
