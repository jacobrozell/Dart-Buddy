import SwiftUI

struct SetupGolfOptionChips: View {
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
                golfCourseLengthChip
            }
        } else {
            HStack(spacing: DS.Spacing.s3) {
                golfCourseLengthChip
            }
        }
    }

    private var golfCourseLengthChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.golf.setup.courseLength", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach(GolfCourseLength.allCases, id: \.rawValue) { length in
                    Button(L10n.format("play.golf.setup.courseLengthValueFormat", length.rawValue)) {
                        setupViewModel.golfCourseLength = length.rawValue
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(
                    L10n.format("play.golf.setup.courseLengthValueFormat", setupViewModel.golfCourseLength),
                    color: Brand.key,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_golfCourseLengthChip")
        }
    }
}
