import SwiftUI

struct X01MatchScreen: View {
    @ObservedObject var viewModel: X01MatchViewModel
    let onShowSummary: () -> Void
    let audio: any AudioFeedbackService
    let haptics: any HapticsService
    let turnTotalCaller: any TurnTotalCallerService
    let feedbackPreferences: FeedbackPreferences
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme
    @State private var showExitConfirmation = false
    @State private var actionTask: Task<Void, Never>?
    @State private var lastAnnouncedCheckout: String?
    @State private var showLegWinBanner = false

    var body: some View {
        VStack(spacing: 0) {
            MatchGameplayHeader(onExit: { showExitConfirmation = true }) {
                Text(L10n.x01Title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Brand.textPrimary)
            } trailing: {
                Button { runUndo() } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Brand.green)
                        .frame(width: 44, height: 44)
                        .background(Brand.card, in: Circle())
                }
                .accessibilityLabel(L10n.scoringUndoLastTurn)
            }

            if let state = viewModel.x01State {
                Text(viewModel.configSummary ?? "")
                    .font(dynamicTypeSize.isAccessibilitySize ? .caption : .subheadline)
                    .foregroundStyle(Brand.textSecondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 2)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DS.Spacing.s4)
                    .padding(.bottom, DS.Spacing.s2)

                Group {
                    if GameplayLayout.usesAccessibilityMatchScoringLayout(dynamicTypeSize: dynamicTypeSize) {
                        accessibilityScoringStack(state: state)
                    } else {
                        ViewThatFits(in: .vertical) {
                            compactScoringStack(state: state)
                            scrollableScoringStack(state: state)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            } else {
                Spacer()
                ProgressView().tint(Brand.textPrimary)
                Spacer()
            }
        }
        .frame(maxWidth: GameplayLayout.matchContentMaxWidth(horizontalSizeClass: horizontalSizeClass))
        .frame(maxWidth: .infinity)
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
        .onChange(of: viewModel.legFinishSoundToken) { _, token in
            if token > 0 {
                audio.playLegFinished()
                postAccessibilityAnnouncement(L10n.string("play.x01.announce.legWon"))
                showLegWinBanner = true
                Task {
                    try? await Task.sleep(nanoseconds: 1_200_000_000)
                    await MainActor.run { showLegWinBanner = false }
                }
            }
        }
        .onChange(of: viewModel.enteredDarts.count) { oldCount, newCount in
            guard viewModel.isBotPlaying, newCount > oldCount else { return }
            guard feedbackPreferences.botDartHapticsEnabled else { return }
            haptics.playImpact()
        }
        .onChange(of: viewModel.turnTotalCallerSignal) { _, signal in
            guard let signal else { return }
            turnTotalCaller.announceTurnTotal(signal.total)
        }
        .onChange(of: viewModel.checkoutRoute) { _, route in
            guard let route else {
                lastAnnouncedCheckout = nil
                return
            }
            let spoken = route.joined(separator: ", ")
            guard spoken != lastAnnouncedCheckout else { return }
            lastAnnouncedCheckout = spoken
            postAccessibilityAnnouncement(
                L10n.format("play.x01.checkout.accessibilityFormat", spoken)
            )
        }
        .onChange(of: viewModel.state) { _, newValue in
            switch newValue {
            case .bustFeedback:
                postAccessibilityAnnouncement(L10n.string("play.x01.bustFeedback"))
            case .matchCompleted:
                audio.playMatchFinished()
                postAccessibilityAnnouncement(L10n.string("play.x01.announce.matchComplete"))
                onShowSummary()
            default:
                break
            }
        }
        .task {
            viewModel.inputMode = .dartEntry
            await viewModel.onAppear()
        }
        .onDisappear { actionTask?.cancel() }
    }

    private func compactScoringStack(state: X01State) -> some View {
        VStack(spacing: DS.Spacing.s2) {
            playerCardsStack
                .padding(.top, DS.Spacing.s2)
            statusBanners
            scoringPad(state: state)
        }
    }

    private func scrollableScoringStack(state: X01State) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                playerCardsStack
                    .padding(.top, DS.Spacing.s2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            statusBanners
                .padding(.vertical, DS.Spacing.s2)
            scoringPad(state: state)
        }
        .frame(maxHeight: .infinity)
    }

    /// Scrollable score + banners; pad stays pinned so both remain reachable at AX sizes.
    private func accessibilityScoringStack(state: X01State) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: DS.Spacing.s2) {
                    playerCardsStack
                        .padding(.top, DS.Spacing.s2)
                    statusBanners
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            scoringPad(state: state)
        }
        .frame(maxHeight: .infinity)
    }

    private var playerCardsStack: some View {
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
    }

    @ViewBuilder
    private var statusBanners: some View {
        VStack(spacing: DS.Spacing.s2) {
            checkoutBanner
            botTurnBanner
            stateBanner
        }
        .padding(.horizontal, DS.Spacing.s4)
    }

    private func scoringPad(state: X01State) -> some View {
        DartNumberPad(
            enteredDarts: $viewModel.enteredDarts,
            selectedMultiplier: $viewModel.selectedMultiplier,
            onUndoTurn: { runUndo() }
        )
        .disabled(viewModel.canHumanInput == false)
        .opacity(viewModel.canHumanInput ? 1 : 0.45)
        .accessibilityElement(children: .contain)
        .modifier(
            OptionalAccessibilityHint(
                hint: viewModel.canHumanInput ? nil : L10n.string("play.x01.pad.disabledWhileBot")
            )
        )
        .padding(.horizontal, DS.Spacing.s3)
        .padding(.bottom, DS.Spacing.s2)
        .onChange(of: viewModel.enteredDarts) { old, darts in
            if darts.count > old.count, let dart = darts.last { playDartFeedback(dart) }
            autoSubmitIfNeeded(darts: darts, state: state)
        }
    }

    @ViewBuilder
    private var checkoutBanner: some View {
        if let route = viewModel.checkoutRoute {
            let labels = CheckoutSuggester.localizedDisplayLabels(for: route)
            HStack(spacing: 6) {
                Image(systemName: "target")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Brand.green)
                Text(labels.joined(separator: "  "))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Brand.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.s2)
            .background(Brand.card, in: Capsule())
            .accessibilityElement(children: .combine)
            .accessibilityLabel(L10n.format("play.x01.checkout.accessibilityFormat", labels.joined(separator: ", ")))
            .accessibilityIdentifier("checkoutSuggestion")
        }
    }

    @ViewBuilder
    private var botTurnBanner: some View {
        if viewModel.isBotPlaying || viewModel.isCurrentPlayerBot && viewModel.canHumanInput == false {
            // Amber-on-background fails AA contrast in light mode, so the banner sits on an
            // amber-tinted pill with primary-text foreground (legible in both appearances).
            HStack(spacing: 8) {
                ProgressView().tint(Brand.textPrimary)
                Text(L10n.botThrowing)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.textPrimary)
            }
            .padding(.vertical, DS.Spacing.s2)
            .padding(.horizontal, DS.Spacing.s4)
            .background(
                Brand.amber.opacity(colorScheme == .dark ? 0.32 : 0.22),
                in: Capsule()
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.s1)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(L10n.string("play.match.botThrowing"))
        }
    }

    @ViewBuilder
    private var stateBanner: some View {
        if showLegWinBanner {
            MatchFeedbackBanner(text: L10n.x01LegWonBanner, style: .legWin)
                .accessibilityIdentifier("legWonBanner")
        } else {
            switch viewModel.state {
            case .bustFeedback:
                MatchFeedbackBanner(text: L10n.bustFeedback, style: .bust)
                    .accessibilityIdentifier("bustBanner")
            case let .entryInvalid(key), let .error(key):
                ErrorBanner(messageKey: key)
            default:
                EmptyView()
            }
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

    private func postAccessibilityAnnouncement(_ text: String) {
        guard !text.isEmpty else { return }
        AccessibilityNotification.Announcement(text).post()
    }
}
