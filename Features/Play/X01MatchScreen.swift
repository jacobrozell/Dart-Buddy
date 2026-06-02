import SwiftUI

struct X01MatchScreen: View {
    @ObservedObject var viewModel: X01MatchViewModel
    let onShowSummary: () -> Void
    let audio: any AudioFeedbackService
    let haptics: any HapticsService
    @Environment(\.dismiss) private var dismiss
    @State private var showExitConfirmation = false
    @State private var actionTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            header
            if let state = viewModel.x01State {
                Text(viewModel.configSummary ?? "")
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DS.Spacing.s4)
                    .padding(.bottom, DS.Spacing.s2)

                ScrollView {
                    VStack(spacing: DS.Spacing.s2) {
                        ForEach(viewModel.playerCards) { card in
                            PlayerScoreCard(
                                name: card.name,
                                score: card.score,
                                setsWon: card.setsWon,
                                legsWon: card.legsWon,
                                isActive: card.isActive,
                                visitDarts: card.visitDarts,
                                dartsThrown: card.dartsThrown,
                                average: card.average
                            )
                        }
                    }
                    .padding(.horizontal, DS.Spacing.s4)
                    .padding(.top, DS.Spacing.s2)
                }

                checkoutBanner
                    .padding(.horizontal, DS.Spacing.s4)

                botTurnBanner
                    .padding(.horizontal, DS.Spacing.s4)

                stateBanner
                    .padding(.horizontal, DS.Spacing.s4)

                DartNumberPad(
                    enteredDarts: $viewModel.enteredDarts,
                    selectedMultiplier: $viewModel.selectedMultiplier,
                    onUndoTurn: { runUndo() }
                )
                .disabled(viewModel.canHumanInput == false)
                .opacity(viewModel.canHumanInput ? 1 : 0.45)
                .padding(.horizontal, DS.Spacing.s3)
                .padding(.bottom, DS.Spacing.s2)
                .onChange(of: viewModel.enteredDarts) { old, darts in
                    if darts.count > old.count, let dart = darts.last { playDartFeedback(dart) }
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
        .alert("play.match.exit.confirm.title", isPresented: $showExitConfirmation) {
            Button("common.stay", role: .cancel) {}
            Button("play.match.exit.saveAndExit") { dismiss() }
            Button("play.match.exit.abandon", role: .destructive) {
                actionTask?.cancel()
                actionTask = Task {
                    await viewModel.abandonMatch()
                    dismiss()
                }
            }
        } message: {
            Text("play.match.exit.confirm.message")
        }
        .onChange(of: viewModel.state) { _, newValue in
            if newValue == .matchCompleted {
                audio.playMatchFinished()
                onShowSummary()
            }
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
                    .frame(width: 44, height: 44)
                    .background(Brand.card, in: Circle())
            }
            .accessibilityLabel("Leave match")
            Spacer()
            Text("X01")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Spacer()
            Button { runUndo() } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Brand.green)
                    .frame(width: 44, height: 44)
                    .background(Brand.card, in: Circle())
            }
            .accessibilityLabel("Undo last turn")
        }
        .padding(.horizontal, DS.Spacing.s4)
        .padding(.top, DS.Spacing.s2)
        .padding(.bottom, DS.Spacing.s2)
    }

    @ViewBuilder
    private var checkoutBanner: some View {
        if let route = viewModel.checkoutRoute {
            HStack(spacing: 6) {
                Image(systemName: "target")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Brand.green)
                Text(route.joined(separator: "  "))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.s2)
            .background(Brand.card, in: Capsule())
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Checkout: \(route.joined(separator: ", "))")
            .accessibilityIdentifier("checkoutSuggestion")
        }
    }

    @ViewBuilder
    private var botTurnBanner: some View {
        if viewModel.isBotPlaying || viewModel.isCurrentPlayerBot && viewModel.canHumanInput == false {
            HStack(spacing: 8) {
                ProgressView().tint(Brand.amber)
                Text("Bot throwing…")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.amber)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.s2)
        }
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
        guard viewModel.canHumanInput else { return }
        guard !darts.isEmpty else { return }
        // Starting the next visit dismisses the BUST banner and re-arms scoring.
        viewModel.acknowledgeBustFeedback()
        guard viewModel.state == .readyTurn else { return }
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

    private func playDartFeedback(_ dart: DartInput) {
        if dart.isMiss { audio.playMiss() } else { audio.playHit() }
        haptics.playImpact()
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
