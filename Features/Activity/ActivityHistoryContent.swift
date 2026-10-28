import SwiftUI

struct ActivityHistoryContent: View {
    @ObservedObject var viewModel: HistoryListViewModel
    let onSelectMatch: (UUID) -> Void
    let onLoadMore: () -> Void
    var onResumeActiveMatch: ((MatchSummary) -> Void)?
    var onStartMatch: (() -> Void)?

    var body: some View {
        if let activeMatch = viewModel.activeMatch {
            ActivityHistoryResumeBanner(match: activeMatch) { onResumeActiveMatch?(activeMatch) }
        }

        if viewModel.state == .loading && viewModel.rows.isEmpty {
            ProgressView()
                .tint(Brand.green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.s6)
                .accessibilityLabel(L10n.loading)
        } else {
            Group {
                if viewModel.state == .error {
                    Text(LocalizedStringKey(viewModel.errorMessageKey ?? "error.repository.storage"))
                        .foregroundStyle(Brand.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Spacing.s6)
                } else if viewModel.rows.isEmpty {
                    ActivityHistoryEmptyState(
                        showsFilteredCopy: viewModel.state == .emptyFiltered && viewModel.hasActiveFilters,
                        showsStartCTA: viewModel.state == .emptyFiltered && !viewModel.hasActiveFilters,
                        onStartMatch: onStartMatch
                    )
                } else {
                    ForEach(viewModel.rows) { row in
                        Button { onSelectMatch(row.summary.id) } label: {
                            MatchHistoryCard(row: row)
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(row.accessibilitySummary)
                    }

                    if viewModel.hasMorePages {
                        Button(action: onLoadMore) {
                            Group {
                                if viewModel.isLoadingMore {
                                    ProgressView().tint(Brand.green)
                                        .accessibilityLabel(L10n.loading)
                                } else {
                                    Text(L10n.historyLoadMore)
                                        .font(.subheadline.weight(.semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DS.Spacing.s3)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Brand.green)
                        .accessibilityIdentifier("historyLoadMoreButton")
                    }
                }
            }
            .motionTabContentReveal(when: true)
        }
    }
}

private struct ActivityHistoryEmptyState: View {
    let showsFilteredCopy: Bool
    let showsStartCTA: Bool
    let onStartMatch: (() -> Void)?

    var body: some View {
        VStack(spacing: DS.Spacing.s3) {
            Text(showsFilteredCopy ? L10n.historyEmptyFiltered : L10n.historyEmptyPrompt)
                .foregroundStyle(Brand.textSecondary)
                .multilineTextAlignment(.center)
            if let onStartMatch, showsStartCTA {
                StartMatchCTAButton(action: onStartMatch)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.s6)
    }
}

private struct ActivityHistoryResumeBanner: View {
    let match: MatchSummary
    let onResume: () -> Void

    var body: some View {
        Button(action: onResume) {
            HStack(alignment: .top) {
                Image(systemName: "play.circle.fill")
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.resumeMatch)
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(MatchConfigText.modeLabel(for: match.type))
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right").foregroundStyle(Brand.textSecondary)
            }
            .foregroundStyle(Brand.textPrimary)
            .padding(DS.Spacing.s4)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.md).stroke(Brand.green, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            L10n.format(
                "play.home.resumeAccessibilityFormat",
                L10n.string("play.home.resumeButton"),
                MatchConfigText.modeLabel(for: match.type)
            )
        )
        .accessibilityIdentifier("historyResumeMatchButton")
    }
}
