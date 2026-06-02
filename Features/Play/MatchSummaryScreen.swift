import SwiftUI

struct MatchSummaryScreen: View {
    @StateObject var viewModel: MatchSummaryViewModel
    let onStartNewMatch: () -> Void
    let onViewHistoryDetail: (UUID) -> Void

    @State private var celebrate = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.s4) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Brand.green)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Spacing.s6)
                } else if viewModel.hasResult {
                    celebrationHeader
                    ForEach(viewModel.playerRows) { row in
                        playerCard(row)
                    }
                } else {
                    Text(L10n.summaryResult).font(.title.weight(.heavy)).foregroundStyle(.white)
                }
                actions
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DS.Spacing.s4)
        }
        .background(Brand.background.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .sensoryFeedback(.success, trigger: celebrate)
        .task {
            await viewModel.loadIfNeeded()
            viewModel.refresh()
            if reduceMotion {
                celebrate = true
            } else {
                try? await Task.sleep(nanoseconds: 120_000_000)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { celebrate = true }
            }
        }
    }

    private var celebrationHeader: some View {
        VStack(spacing: DS.Spacing.s2) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 56))
                .foregroundStyle(Brand.amber)
                .scaleEffect(celebrate ? 1 : (reduceMotion ? 1 : 0.4))
                .opacity(celebrate ? 1 : (reduceMotion ? 1 : 0))
                .rotationEffect(.degrees(celebrate ? 0 : (reduceMotion ? 0 : -25)))
                .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.6), value: celebrate)
            if let winnerName = viewModel.winnerName {
                Text(L10n.format("play.summary.winsFormat", winnerName))
                    .font(.title.weight(.heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            Text(viewModel.typeLabel)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DS.Spacing.s4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(celebrationHeaderAccessibilityLabel)
        .accessibilityIdentifier("matchSummaryHeader")
    }

    private var celebrationHeaderAccessibilityLabel: String {
        guard let winnerName = viewModel.winnerName else { return viewModel.typeLabel }
        return L10n.format("play.summary.header.accessibilityFormat", winnerName, viewModel.typeLabel)
    }

    private func playerCard(_ row: MatchSummaryViewModel.PlayerRow) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(row.isWinner ? Brand.amber : Color.clear)
                .frame(width: 6)
            VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                HStack(spacing: 6) {
                    if row.isWinner {
                        Image(systemName: "crown.fill").font(.caption).foregroundStyle(Brand.amber)
                    }
                    Text(row.name)
                        .font(.headline)
                        .foregroundStyle(row.isWinner ? Brand.amber : .white)
                }
                HStack(spacing: DS.Spacing.s3) {
                    ForEach(row.stats, id: \.label) { stat in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stat.value)
                                .font(.title3.weight(.bold).monospacedDigit())
                                .foregroundStyle(.white)
                            Text(stat.label)
                                .font(.caption2)
                                .foregroundStyle(Brand.textSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(DS.Spacing.s3)
            Spacer(minLength: 0)
        }
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(playerRowAccessibilityLabel(row))
    }

    private func playerRowAccessibilityLabel(_ row: MatchSummaryViewModel.PlayerRow) -> String {
        let stats = row.stats.map { "\($0.label) \($0.value)" }.joined(separator: ", ")
        let prefix = row.isWinner ? L10n.string("play.summary.player.winnerPrefix") : ""
        return L10n.format("play.summary.player.accessibilityFormat", prefix, row.name, stats)
    }

    private var actions: some View {
        VStack(spacing: DS.Spacing.s3) {
            Button(action: onStartNewMatch) {
                Text(L10n.summaryNewMatch)
                    .font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Brand.red, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
            }
            .buttonStyle(.plain)
            Button(action: { onViewHistoryDetail(viewModel.matchId) }) {
                Text(L10n.summaryViewGameStatistics)
                    .font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, DS.Spacing.s2)
    }
}
