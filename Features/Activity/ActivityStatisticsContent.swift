import SwiftUI

struct ActivityStatisticsContent: View {
    @ObservedObject var viewModel: StatisticsViewModel
    var onStartMatch: (() -> Void)?

    var body: some View {
        if viewModel.includesPartialActiveMatch {
            ActivityStatisticsPartialBanner()
        }

        if viewModel.isLoading && viewModel.rows.isEmpty {
            ProgressView()
                .tint(Brand.green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.s6)
                .accessibilityLabel(L10n.loading)
        } else {
            Group {
                if viewModel.rows.isEmpty {
                    emptyState
                } else {
                    StatisticsTablesContent(viewModel: viewModel)
                }
            }
            .motionTabContentReveal(when: true)
        }
    }

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.s3) {
            Text(L10n.statsEmptyTitle)
                .foregroundStyle(Brand.textSecondary)
                .multilineTextAlignment(.center)
            if let onStartMatch,
               viewModel.playerFilter == nil,
               viewModel.period == .all {
                StartMatchCTAButton(action: onStartMatch)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, DS.Spacing.s6)
    }
}

private struct ActivityStatisticsPartialBanner: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.s2) {
            Image(systemName: "clock.arrow.circlepath")
                .accessibilityHidden(true)
            Text(L10n.statsPartialMatchBanner)
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(Brand.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.s3)
        .background(
            Brand.amber.opacity(colorScheme == .dark ? 0.32 : 0.22),
            in: RoundedRectangle(cornerRadius: DS.Radius.md)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.string("stats.partialMatchBanner.accessibility"))
        .accessibilityIdentifier("statsPartialMatchBanner")
    }
}
