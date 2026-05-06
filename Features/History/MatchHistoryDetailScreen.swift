import SwiftUI

struct MatchHistoryDetailScreen: View {
    @ObservedObject var viewModel: HistoryDetailViewModel
    let matchId: UUID
    @State private var retryTask: Task<Void, Never>?

    var body: some View {
        List {
            Section(L10n.historyHeaderSection) {
                Text(L10n.format("history.detail.matchFormat", String(matchId.uuidString.prefix(8))))
                if let header = viewModel.header {
                    Text(L10n.format("history.modeFormat", header.modeText))
                    Text(L10n.format("history.winnerFormat", header.winnerText))
                    Text(L10n.format("history.dateFormat", header.dateText))
                    Text(L10n.format("history.durationFormat", header.durationText))
                    Text(L10n.format("history.participantsFormat", header.participantsText))
                    Text(header.modeSpecificSummaryText)
                        .foregroundStyle(DS.ColorRole.textSecondary)
                }
            }
            Section(L10n.historyTimelineSection) {
                if viewModel.state == "loading" {
                    ProgressView(L10n.loading)
                } else if viewModel.state == "error" {
                    VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                        Text(viewModel.errorMessageKey ?? "error.repository.storage")
                            .foregroundStyle(DS.ColorRole.danger)
                        Button(L10n.retry) {
                            retryTask?.cancel()
                            retryTask = Task { await viewModel.onAppear() }
                        }
                        .buttonStyle(.bordered)
                    }
                } else if viewModel.timeline.isEmpty {
                    Text(L10n.historyTimelineEmpty)
                        .foregroundStyle(DS.ColorRole.textSecondary)
                } else {
                    ForEach(Array(viewModel.timeline.enumerated()), id: \.offset) { _, row in
                        Text(row)
                    }
                }
            }
        }
        .navigationTitle(L10n.historyDetailTitle)
        .task { await viewModel.onAppear() }
        .onDisappear { retryTask?.cancel() }
    }
}
