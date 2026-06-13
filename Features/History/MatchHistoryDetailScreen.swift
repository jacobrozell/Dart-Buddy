import SwiftUI

struct MatchHistoryDetailScreen: View {
    @StateObject private var viewModel: HistoryDetailViewModel
    let matchId: UUID
    var onDeleted: () -> Void = {}
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var retryTask: Task<Void, Never>?
    @State private var deleteTask: Task<Void, Never>?
    @State private var showTimeline = false
    @State private var showDeleteConfirm = false

    init(
        matchId: UUID,
        matchRepository: any MatchRepository,
        statsRepository: any StatsRepository,
        onDeleted: @escaping () -> Void = {}
    ) {
        self.matchId = matchId
        self.onDeleted = onDeleted
        _viewModel = StateObject(
            wrappedValue: HistoryDetailViewModel(
                matchId: matchId,
                matchRepository: matchRepository,
                statsRepository: statsRepository
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.s5) {
                Text(L10n.historyGameStatistics)
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(Brand.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                if viewModel.state == "loading" {
                    ProgressView().tint(Brand.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Spacing.s6)
                        .accessibilityLabel(L10n.loading)
                } else if viewModel.state == "error" {
                    VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                        Text(LocalizedStringKey(viewModel.errorMessageKey ?? "error.repository.storage"))
                            .foregroundStyle(Brand.red)
                        Button(L10n.retry) {
                            retryTask?.cancel()
                            retryTask = Task { await viewModel.onAppear() }
                        }
                        .tint(Brand.green)
                    }
                } else {
                    resultCard
                    if let lineScore = viewModel.lineScore {
                        BaseballLineScoreView(lineScore: lineScore)
                    }
                    statTables
                    sectorSection
                    timelineSection
                    deleteButton
                }
            }
            .padding(.horizontal, DS.Spacing.s4)
            .padding(.bottom, DS.Spacing.s6)
            .readableRootContentWidth(horizontalSizeClass)
        }
        .background(Brand.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.onAppear() }
        .onDisappear {
            retryTask?.cancel()
            deleteTask?.cancel()
        }
        .alert(L10n.historyDeleteConfirmTitle, isPresented: $showDeleteConfirm) {
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.delete, role: .destructive) {
                deleteTask?.cancel()
                deleteTask = Task {
                    if await viewModel.deleteMatch() { onDeleted() }
                }
            }
        } message: {
            Text(L10n.historyDeleteConfirmMessage)
        }
    }

    @ViewBuilder
    private var statTables: some View {
        if !viewModel.breakdowns.isEmpty {
            if viewModel.isX01 {
                StatTable(
                    title: L10n.string("stats.section.averageHighest"),
                    columns: [(L10n.string("stats.threeDartAverage"), 90), (L10n.string("stats.column.highest"), 80)],
                    rows: viewModel.breakdowns
                ) { row in
                    [String(format: "%.1f", row.average3Dart), "\(row.highestScore)"]
                }
                StatTable(
                    title: L10n.string("stats.section.legsCheckout"),
                    columns: [(L10n.string("stats.column.legs"), 60), (L10n.string("stats.checkouts"), 90), (L10n.string("stats.column.bestCO"), 80)],
                    rows: viewModel.breakdowns
                ) { row in
                    ["\(row.legs)", "\(row.checkouts)", row.highestCheckout > 0 ? "\(row.highestCheckout)" : "-"]
                }
            }
            StatTable(
                title: L10n.string("stats.points"),
                columns: [(L10n.string("stats.points"), 90)],
                rows: viewModel.breakdowns
            ) { row in
                ["\(row.points)"]
            }
            StatTable(
                title: L10n.string("stats.throws"),
                columns: [(L10n.string("stats.throws"), 70), (L10n.string("stats.doublePercent"), 80), (L10n.string("stats.triplePercent"), 80)],
                rows: viewModel.breakdowns
            ) { row in
                ["\(row.darts)", String(format: "%.1f%%", row.doublePercent), String(format: "%.1f%%", row.triplePercent)]
            }
        }
    }

    @ViewBuilder
    private var sectorSection: some View {
        if viewModel.breakdowns.contains(where: { !$0.hitsBySector.isEmpty }) {
            PerPlayerSectorHitsSection(breakdowns: viewModel.breakdowns, mode: viewModel.matchType)
        }
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            HStack {
                Text(viewModel.dateText)
                    .font(.headline)
                    .foregroundStyle(Brand.textPrimary)
                    .accessibilityHidden(true)
                Spacer()
                StatusBadge(text: L10n.string("history.status.finished"), color: Brand.green)
                    .accessibilityHidden(true)
            }
            if !viewModel.configText.isEmpty {
                Text(viewModel.configText)
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
                    .accessibilityHidden(true)
            }
            ForEach(Array(viewModel.standings.enumerated()), id: \.element.id) { index, standing in
                HStack {
                    Text("\(index + 1). \(standing.name)")
                        .font(.body.weight(standing.isWinner ? .semibold : .regular))
                        .foregroundStyle(standing.isWinner ? Brand.textPrimary : Brand.textSecondary)
                        .accessibilityHidden(true)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        if viewModel.isX01 {
                            Text(L10n.format("history.standing.setsLegsFormat", standing.sets, standing.legs))
                                .font(.caption)
                                .foregroundStyle(Brand.textSecondary)
                                .accessibilityHidden(true)
                        }
                        Text("\(standing.score)")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Brand.textPrimary)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
        .padding(DS.Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(viewModel.resultAccessibilitySummary)
        .accessibilityIdentifier("historyDetailResultCard")
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Button {
                MotionPolicy.animateIfAllowed(reduceMotion: reduceMotion, Motion.standard) {
                    showTimeline.toggle()
                }
            } label: {
                HStack {
                    Text(L10n.historyTurnByTurn).font(.headline).foregroundStyle(Brand.textPrimary)
                    Spacer()
                    Image(systemName: showTimeline ? "chevron.up" : "chevron.down")
                        .foregroundStyle(Brand.textSecondary)
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityValue(
                L10n.string(showTimeline ? "history.detail.timeline.expanded" : "history.detail.timeline.collapsed")
            )
            .accessibilityIdentifier("historyDetailTimelineToggle")
            if showTimeline {
                ForEach(Array(viewModel.timeline.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.subheadline)
                        .foregroundStyle(Brand.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel(line)
                }
            }
        }
        .padding(DS.Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirm = true
        } label: {
            Label(L10n.delete, systemImage: "trash")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(Brand.red)
        .controlSize(.large)
        .padding(.top, DS.Spacing.s4)
        .accessibilityLabel(L10n.string("history.detail.delete.accessibility"))
        .accessibilityHint(L10n.string("history.detail.delete.hint"))
        .accessibilityIdentifier("historyDetailDeleteButton")
    }
}
