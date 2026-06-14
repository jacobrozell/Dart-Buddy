import SwiftUI

struct SetupHomeHeaderSection: View {
    @ObservedObject var homeViewModel: PlayHomeViewModel
    let onResumeMatch: (MatchSummary) -> Void

    var body: some View {
        BrandAppTitle()
            .padding(.top, DS.Spacing.s2)
        if case let .readyWithActiveMatch(match) = homeViewModel.state {
            resumeBanner(match)
        }
    }

    private func resumeBanner(_ match: MatchSummary) -> some View {
        Button { onResumeMatch(match) } label: {
            HStack {
                Image(systemName: "play.circle.fill")
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.resumeMatch).font(.headline)
                    Text(MatchConfigText.modeLabel(for: match.type)).font(.caption).foregroundStyle(Brand.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Brand.textSecondary)
            }
            .foregroundStyle(Brand.textPrimary)
            .padding(DS.Spacing.s4)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.sm).stroke(Brand.green, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            L10n.format(
                "play.home.resumeAccessibilityFormat",
                L10n.string("play.home.resumeButton"),
                MatchConfigText.modeLabel(for: match.type)
            )
        )
        .accessibilityIdentifier("resumeMatchButton")
        .motionBannerEntrance()
    }
}
