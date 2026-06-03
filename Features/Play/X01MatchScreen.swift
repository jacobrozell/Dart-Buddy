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
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DS.Spacing.s4)
                    .padding(.bottom, DS.Spacing.s2)

                ViewThatFits(in: .vertical) {
                    compactScoringStack(state: state)
                    scrollableScoringStack(state: state)
                }
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
            statusBanners
                .padding(.vertical, DS.Spacing.s2)
            scoringPad(state: state)
        }
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
            HStack(spacing: 8) {
                ProgressView().tint(Brand.amber)
                Text(L10n.botThrowing)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.amber)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.s2)
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

private struct PlayerScoreCard: View {
    let name: String
    let score: Int
    let setsWon: Int
    let legsWon: Int
    let isActive: Bool
    let visitDarts: [DartInput]
    let dartsThrown: Int
    let average: Double

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var scoreFontSize: CGFloat = 40
    @ScaledMetric(relativeTo: .caption) private var dartBoxSize: CGFloat = 38

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(isActive ? Brand.green : Color.clear)
                .frame(width: 6)
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    accessibilityBody
                } else {
                    compactBody
                }
            }
            .padding(DS.Spacing.s3)
        }
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityIdentifier(isActive ? "scoreCard_active" : "scoreCard")
    }

    private var compactBody: some View {
        HStack(alignment: .center, spacing: DS.Spacing.s3) {
            scoreNameColumn
            Spacer(minLength: DS.Spacing.s2)
            visitColumn
            Spacer(minLength: DS.Spacing.s2)
            statsColumn
        }
    }

    private var accessibilityBody: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            scoreNameColumn
            visitColumn
            statsColumn
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var scoreNameColumn: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(score)")
                .font(.system(size: scoreFontSize, weight: .heavy, design: .rounded))
                .foregroundStyle(Brand.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityIdentifier(isActive ? "scoreCard_remaining" : "")
            Text(name)
                .font(.subheadline)
                .foregroundStyle(isActive ? Brand.green : Brand.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
    }

    private var visitColumn: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                ForEach(0 ..< 3, id: \.self) { slot in
                    dartBox(slot < visitDarts.count ? dartLabel(visitDarts[slot]) : nil)
                        .accessibilityIdentifier(isActive ? "scoreCard_dartSlot_\(slot)" : "")
                }
            }
            Text("\(visitTotal)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.textSecondary)
                .accessibilityIdentifier(isActive ? "scoreCard_visitTotal" : "")
        }
    }

    private var statsColumn: some View {
        VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: 6) {
            setsLegsLabels
            HStack(spacing: 4) {
                Image(systemName: "scope").font(.footnote)
                Text("\(dartsThrown)").font(.footnote.weight(.semibold))
            }
            .foregroundStyle(Brand.textSecondary)
            .accessibilityIdentifier(isActive ? "scoreCard_dartsThrown" : "")
            HStack(spacing: 4) {
                Image(systemName: "chart.bar.fill").font(.footnote)
                Text(String(format: "%.2f", average)).font(.footnote.weight(.semibold))
            }
            .foregroundStyle(Brand.textSecondary)
            .accessibilityIdentifier(isActive ? "scoreCard_average" : "")
        }
        .frame(minWidth: dynamicTypeSize.isAccessibilitySize ? nil : 72, alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing)
    }

    private var setsLegsLabels: some View {
        VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: 2) {
            Text(L10n.format("play.x01.setsCountFormat", setsWon))
            Text(L10n.format("play.x01.legsCountFormat", legsWon))
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(Brand.textSecondary)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    private var visitTotal: Int {
        visitDarts.reduce(0) { $0 + $1.points }
    }

    private var accessibilitySummary: String {
        var parts = [L10n.format("play.x01.scoreCard.summaryFormat", name, score)]
        if isActive {
            parts.append(L10n.string("play.x01.turn.active"))
        }
        let dartSpeech = visitDarts.map(\.spokenAccessibilityName)
        if !dartSpeech.isEmpty {
            parts.append(L10n.format("play.x01.scoreCard.visitDartsFormat", dartSpeech.joined(separator: ", ")))
        }
        parts.append(L10n.format("play.x01.scoreCard.visitTotalFormat", visitTotal))
        parts.append(L10n.format("play.x01.setsLegsFormat", setsWon, legsWon))
        parts.append(L10n.format("play.x01.scoreCard.dartsThrownFormat", dartsThrown))
        parts.append(L10n.format("play.x01.scoreCard.averageFormat", average))
        return parts.joined(separator: ". ")
    }

    private func dartBox(_ label: String?) -> some View {
        Text(label ?? "")
            .font(.system(size: max(13, dartBoxSize * 0.4), weight: .bold, design: .rounded))
            .foregroundStyle(Brand.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(width: dartBoxSize, height: dartBoxSize)
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
