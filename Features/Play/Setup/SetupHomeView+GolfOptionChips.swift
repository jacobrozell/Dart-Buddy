import SwiftUI

extension SetupHomeView {
    @ViewBuilder
    var golfChipsGrid: some View {
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
        chip(titleKey: "play.golf.setup.courseLength", color: Brand.key) {
            Menu {
                ForEach(GolfCourseLength.allCases, id: \.rawValue) { length in
                    Button(L10n.format("play.golf.setup.courseLengthValueFormat", length.rawValue)) {
                        setupViewModel.golfCourseLength = length.rawValue
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(
                    L10n.format("play.golf.setup.courseLengthValueFormat", setupViewModel.golfCourseLength),
                    color: Brand.key,
                    showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_golfCourseLengthChip")
        }
    }
}
