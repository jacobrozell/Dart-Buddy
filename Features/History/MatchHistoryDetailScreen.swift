import SwiftUI

struct MatchHistoryDetailScreen: View {
    @ObservedObject var viewModel: HistoryDetailViewModel
    let matchId: UUID
    var onDeleted: () -> Void = {}
    @State private var retryTask: Task<Void, Never>?
    @State private var deleteTask: Task<Void, Never>?
    @State private var showTimeline = false
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.s5) {
                Text("Game Statistics")
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(.white)

                if viewModel.state == "loading" {
                    ProgressView().tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Spacing.s6)
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
                    statTables
                    sectorSection
                    timelineSection
                    deleteButton
                }
            }
            .padding(.horizontal, DS.Spacing.s4)
            .padding(.bottom, DS.Spacing.s6)
        }
        .background(Brand.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.onAppear() }
        .onDisappear {
            retryTask?.cancel()
            deleteTask?.cancel()
        }
        .alert("Delete this game?", isPresented: $showDeleteConfirm) {
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.delete, role: .destructive) {
                deleteTask?.cancel()
                deleteTask = Task {
                    if await viewModel.deleteMatch() { onDeleted() }
                }
            }
        } message: {
            Text("This permanently removes the game and its stats. This cannot be undone.")
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.title2.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var statTables: some View {
        if !viewModel.breakdowns.isEmpty {
            if viewModel.isX01 {
                sectionTitle("Average & Highest Score")
                StatTable(
                    columns: [("3-Dart Avg", 90), ("Highest", 80)],
                    rows: viewModel.breakdowns
                ) { row in
                    [String(format: "%.1f", row.average3Dart), "\(row.highestScore)"]
                }
                sectionTitle("Legs & Checkout")
                StatTable(
                    columns: [("Legs", 60), ("Checkouts", 90), ("Best CO", 80)],
                    rows: viewModel.breakdowns
                ) { row in
                    ["\(row.legs)", "\(row.checkouts)", row.highestCheckout > 0 ? "\(row.highestCheckout)" : "-"]
                }
            }
            sectionTitle("Points")
            StatTable(
                columns: [("Points", 90)],
                rows: viewModel.breakdowns
            ) { row in
                ["\(row.points)"]
            }
            sectionTitle("Throws")
            StatTable(
                columns: [("Throws", 70), ("Double %", 80), ("Triple %", 80)],
                rows: viewModel.breakdowns
            ) { row in
                ["\(row.darts)", String(format: "%.1f%%", row.doublePercent), String(format: "%.1f%%", row.triplePercent)]
            }
        }
    }

    @ViewBuilder
    private var sectorSection: some View {
        if viewModel.breakdowns.contains(where: { !$0.hitsBySector.isEmpty }) {
            sectionTitle("Hits in Sector")
            PerPlayerSectorHitsSection(breakdowns: viewModel.breakdowns, mode: viewModel.matchType)
        }
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            HStack {
                Text(viewModel.dateText)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                StatusBadge(text: "FINISHED", color: Brand.green)
            }
            if !viewModel.configText.isEmpty {
                Text(viewModel.configText)
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
            }
            ForEach(Array(viewModel.standings.enumerated()), id: \.element.id) { index, standing in
                HStack {
                    Text("\(index + 1). \(standing.name)")
                        .font(.body.weight(standing.isWinner ? .semibold : .regular))
                        .foregroundStyle(standing.isWinner ? .white : Brand.textSecondary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("Sets: \(standing.sets)  Legs: \(standing.legs)")
                            .font(.caption)
                            .foregroundStyle(Brand.textSecondary)
                        Text("\(standing.score)")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .padding(DS.Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Button {
                withAnimation { showTimeline.toggle() }
            } label: {
                HStack {
                    Text("Turn-by-turn").font(.headline).foregroundStyle(.white)
                    Spacer()
                    Image(systemName: showTimeline ? "chevron.up" : "chevron.down")
                        .foregroundStyle(Brand.textSecondary)
                }
            }
            .buttonStyle(.plain)
            if showTimeline {
                ForEach(Array(viewModel.timeline.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.subheadline)
                        .foregroundStyle(Brand.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
    }
}
