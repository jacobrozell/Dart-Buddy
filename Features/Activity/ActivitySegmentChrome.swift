import SwiftUI

struct ActivitySegmentChrome: View {
    @Binding var segment: ActivitySegment
    @Binding var modeFilter: ActivityModeFilter
    @Binding var period: ActivityPeriod
    @Binding var playerFilter: UUID?
    let playerOptions: [PlayerSummary]
    let selectedPlayerName: String?

    var body: some View {
        BrandSegmented(
            options: ActivitySegment.allCases.map { ($0, $0.title) },
            selection: $segment,
            accessibilityIdentifiers: [
                .history: "activity_segment_history",
                .statistics: "activity_segment_statistics"
            ]
        )

        ActivityFilterBar(
            modeFilter: $modeFilter,
            period: $period,
            playerFilter: $playerFilter,
            playerOptions: playerOptions,
            selectedPlayerName: selectedPlayerName
        )
    }
}
