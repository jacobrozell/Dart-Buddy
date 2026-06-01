import SwiftUI

struct MatchHistoryDetailScreen: View {
    @ObservedObject var viewModel: HistoryDetailViewModel
    let matchId: UUID
    @State private var retryTask: Task<Void, Never>?
    @State private var showTimeline = false

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
                    if !viewModel.throwsRows.isEmpty {
                        sectionTitle("Throws")
                        throwsTable
                    }
                    timelineSection
                }
            }
            .padding(.horizontal, DS.Spacing.s4)
            .padding(.bottom, DS.Spacing.s6)
        }
        .background(Brand.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.onAppear() }
        .onDisappear { retryTask?.cancel() }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.title2.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
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

    private var throwsTable: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Players").frame(maxWidth: .infinity, alignment: .leading)
                Text("Throws").frame(width: 70, alignment: .trailing)
                Text("Double %").frame(width: 80, alignment: .trailing)
                Text("Triple %").frame(width: 80, alignment: .trailing)
            }
            .font(.caption)
            .foregroundStyle(Brand.textSecondary)
            .padding(.horizontal, DS.Spacing.s3)
            .padding(.vertical, DS.Spacing.s2)

            ForEach(Array(viewModel.throwsRows.enumerated()), id: \.element.id) { index, row in
                HStack {
                    Text("\(index + 1). \(row.name)")
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(1)
                    Text("\(row.throwCount)").frame(width: 70, alignment: .trailing).foregroundStyle(.white)
                    Text(String(format: "%.2f%%", row.doublePercent)).frame(width: 80, alignment: .trailing).foregroundStyle(.white)
                    Text(String(format: "%.2f%%", row.triplePercent)).frame(width: 80, alignment: .trailing).foregroundStyle(.white)
                }
                .font(.subheadline)
                .padding(.horizontal, DS.Spacing.s3)
                .padding(.vertical, DS.Spacing.s3)
                .background(index.isMultiple(of: 2) ? Color.clear : Brand.cardElevated.opacity(0.4))
            }
        }
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
}
