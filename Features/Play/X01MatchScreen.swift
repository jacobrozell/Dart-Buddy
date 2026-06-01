import SwiftUI

struct X01MatchScreen: View {
    @ObservedObject var viewModel: X01MatchViewModel
    let onShowSummary: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showExitConfirmation = false
    @State private var actionTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            header
            if let session = viewModel.session, let state = session.runtime.x01State {
                Text(configSummary(state))
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DS.Spacing.s4)
                    .padding(.bottom, DS.Spacing.s2)

                ScrollView {
                    VStack(spacing: DS.Spacing.s2) {
                        ForEach(Array(state.players.enumerated()), id: \.element.playerId) { index, player in
                            PlayerScoreCard(
                                name: name(for: player.playerId, fallbackIndex: index),
                                score: player.remainingScore,
                                setsWon: player.setsWon,
                                legsWon: player.legsWon,
                                isActive: index == state.currentPlayerIndex && session.runtime.status == .inProgress,
                                visitDarts: index == state.currentPlayerIndex ? viewModel.enteredDarts : [],
                                dartsThrown: dartsThrown(for: player.playerId),
                                average: average(for: player.playerId)
                            )
                        }
                    }
                    .padding(.horizontal, DS.Spacing.s4)
                    .padding(.top, DS.Spacing.s2)
                }

                stateBanner
                    .padding(.horizontal, DS.Spacing.s4)

                DartNumberPad(
                    enteredDarts: $viewModel.enteredDarts,
                    selectedMultiplier: $viewModel.selectedMultiplier,
                    onUndoTurn: { runUndo() }
                )
                .padding(.horizontal, DS.Spacing.s3)
                .padding(.bottom, DS.Spacing.s2)
                .onChange(of: viewModel.enteredDarts) { _, darts in
                    autoSubmitIfNeeded(darts: darts, state: state)
                }
            } else {
                Spacer()
                ProgressView().tint(.white)
                Spacer()
            }
        }
        .background(Brand.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .alert("Leave match?", isPresented: $showExitConfirmation) {
            Button("Stay", role: .cancel) {}
            Button("Leave", role: .destructive) { dismiss() }
        } message: {
            Text("Your progress is saved and you can resume later.")
        }
        .onChange(of: viewModel.state) { _, newValue in
            if newValue == .matchCompleted { onShowSummary() }
        }
        .task {
            viewModel.inputMode = .dartEntry
            await viewModel.onAppear()
        }
        .onDisappear { actionTask?.cancel() }
    }

    private var header: some View {
        HStack {
            Button { showExitConfirmation = true } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Brand.green)
                    .frame(width: 40, height: 40)
                    .background(Brand.card, in: Circle())
            }
            Spacer()
            Text("X01")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Spacer()
            Button { runUndo() } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Brand.green)
                    .frame(width: 40, height: 40)
                    .background(Brand.card, in: Circle())
            }
            .accessibilityLabel("Undo last turn")
        }
        .padding(.horizontal, DS.Spacing.s4)
        .padding(.top, DS.Spacing.s2)
        .padding(.bottom, DS.Spacing.s2)
    }

    @ViewBuilder
    private var stateBanner: some View {
        switch viewModel.state {
        case .bustFeedback:
            Text("BUST")
                .font(.headline.weight(.heavy))
                .foregroundStyle(Brand.red)
        case let .entryInvalid(key), let .error(key):
            Text(LocalizedStringKey(key)).foregroundStyle(Brand.red)
        default:
            EmptyView()
        }
    }

    private func autoSubmitIfNeeded(darts: [DartInput], state: X01State) {
        guard !darts.isEmpty, viewModel.state == .readyTurn else { return }
        let remaining = state.players[state.currentPlayerIndex].remainingScore
        let visitTotal = darts.reduce(0) { $0 + $1.points }
        if darts.count == 3 || visitTotal >= remaining {
            actionTask?.cancel()
            actionTask = Task { await viewModel.submitTurn() }
        }
    }

    private func runUndo() {
        actionTask?.cancel()
        actionTask = Task { await viewModel.undoLastTurn() }
    }

    private func name(for playerId: UUID, fallbackIndex: Int) -> String {
        guard let session = viewModel.session else { return "Player \(fallbackIndex + 1)" }
        let participant = session.runtime.participants.first { ($0.playerId ?? $0.id) == playerId }
        return participant?.displayNameAtMatchStart ?? "Player \(fallbackIndex + 1)"
    }

    private func turnEvents(for playerId: UUID) -> [X01TurnEvent] {
        guard let session = viewModel.session else { return [] }
        return session.events.compactMap { envelope in
            if case let .x01Turn(event) = envelope.payload, event.playerId == playerId {
                return event
            }
            return nil
        }
    }

    private func dartsThrown(for playerId: UUID) -> Int {
        turnEvents(for: playerId).reduce(0) { $0 + max($1.darts.count, 0) }
    }

    private func average(for playerId: UUID) -> Double {
        let events = turnEvents(for: playerId)
        let darts = events.reduce(0) { $0 + max($1.darts.count, 0) }
        guard darts > 0 else { return 0 }
        let points = events.reduce(0) { $0 + $1.appliedTotal }
        return Double(points) / Double(darts) * 3.0
    }

    private func configSummary(_ state: X01State) -> String {
        let config = state.config
        let checkout = config.checkoutMode == .doubleOut ? "Double Out" : "Straight Out"
        var parts = ["\(config.startScore)", checkout]
        if config.setsEnabled {
            parts.append("First to \(config.setsToWin ?? 1) Set\(config.setsToWin == 1 ? "" : "s")")
        }
        parts.append("First to \(config.legsToWin) Leg\(config.legsToWin == 1 ? "" : "s")")
        return parts.joined(separator: ", ")
    }
}

private struct PlayerScoreCard: View {
    let name: String
    let score: Int
    let setsWon: Int
    let legsWon: Int
    let isActive: Bool
    let visitDarts: [DartInput]
    let dartsThrown: Int
    let average: Double

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(isActive ? Brand.green : Color.clear)
                .frame(width: 6)
            HStack(alignment: .center, spacing: DS.Spacing.s3) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(score)")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text(name)
                        .font(.subheadline)
                        .foregroundStyle(isActive ? Brand.green : Brand.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: DS.Spacing.s2)
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        ForEach(0 ..< 3, id: \.self) { slot in
                            dartBox(slot < visitDarts.count ? dartLabel(visitDarts[slot]) : nil)
                        }
                    }
                    Text("\(visitTotal)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.textSecondary)
                }
                Spacer(minLength: DS.Spacing.s2)
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Sets:\(setsWon)  Legs:\(legsWon)")
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                    HStack(spacing: 4) {
                        Image(systemName: "scope").font(.caption2)
                        Text("\(dartsThrown)").font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(Brand.textSecondary)
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill").font(.caption2)
                        Text(String(format: "%.2f", average)).font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(Brand.textSecondary)
                }
            }
            .padding(DS.Spacing.s3)
        }
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(isActive ? "scoreCard_active" : "scoreCard")
    }

    private var visitTotal: Int {
        visitDarts.reduce(0) { $0 + $1.points }
    }

    private func dartBox(_ label: String?) -> some View {
        Text(label ?? "")
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 38, height: 38)
            .background(Brand.dartBox, in: RoundedRectangle(cornerRadius: 6))
    }

    private func dartLabel(_ dart: DartInput) -> String {
        if dart.isMiss { return "0" }
        switch dart.segment {
        case let .oneToTwenty(value):
            switch dart.multiplier {
            case .single: return "\(value)"
            case .double: return "D\(value)"
            case .triple: return "T\(value)"
            }
        case .outerBull: return "25"
        case .innerBull: return "50"
        case .miss: return "0"
        }
    }
}
