import SwiftUI

struct X01MatchScreen: View {
    @ObservedObject var viewModel: X01MatchViewModel
    let onShowSummary: () -> Void
    let audio: any AudioFeedbackService
    let haptics: any HapticsService
    let turnTotalCaller: any TurnTotalCallerService
    let feedbackPreferences: FeedbackPreferences
    let lifecycleDependencies: MatchLifecycleChromeDependencies
    var visionScoringEnabled: Bool = false
    var visualDartboardInputEnabled: Bool = false
    var visionLogger: (any AppLogger)? = nil
    var defaultDartEntryPresentation: DartEntryPresentation = .default
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var showExitConfirmation = false
    @State private var dartEntryPresentationOverride: DartEntryPresentation?
    @State private var actionTask: Task<Void, Never>?
    @State private var lastAnnouncedCheckout: String?
    @State private var showLegWinBanner = false
    @State private var selectedCheckoutIndex = 0
    @State private var showVisionScoring = false

    /// How long the leg-win banner stays on screen before auto-dismissing.
    private static let legWinBannerDisplayNanoseconds: UInt64 = 1_200_000_000

    private var usesLandscapeMatchLayout: Bool {
        GameplayLayout.usesLandscapeMatchScoringLayout(verticalSizeClass: verticalSizeClass)
    }

    private var dartEntryPresentation: DartEntryPresentation {
        (dartEntryPresentationOverride ?? defaultDartEntryPresentation)
            .resolved(allowsVisualBoard: visualDartboardInputEnabled)
    }

    /// The number pad stays first-class: AX text sizes and VoiceOver always use it.
    private var usesVisualBoardEntry: Bool {
        visualDartboardInputEnabled
            && dartEntryPresentation == .visualBoard
            && !voiceOverEnabled
            && !GameplayLayout.usesAccessibilityMatchScoringLayout(dynamicTypeSize: dynamicTypeSize)
    }

    var body: some View {
        VStack(spacing: 0) {
            MatchGameplayHeader(onExit: { showExitConfirmation = true }) {
                VStack(alignment: .leading, spacing: usesLandscapeMatchLayout ? 0 : 2) {
                    BrandMatchScreenTitle(title: "play.x01.title")
                    if showsConfigSummaryInHeader, let summary = viewModel.configSummary {
                        Text(summary)
                            .font(.caption2)
                            .foregroundStyle(Brand.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .accessibilityIdentifier("x01_match_config_summary")
                    }
                }
            } trailing: {
                HStack(spacing: DS.Spacing.s2) {
                    if visualDartboardInputEnabled {
                        DartEntryPresentationToggle(presentation: dartEntryPresentation) {
                            dartEntryPresentationOverride = dartEntryPresentation.toggled
                        }
                    }
                    Button { runUndo() } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Brand.green)
                            .frame(width: 44, height: 44)
                            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                    }
                    .accessibilityLabel(L10n.scoringUndoLastTurn)
                    .accessibilityIdentifier("match_undo")
                }
            }

            if let state = viewModel.x01State {
                if !showsConfigSummaryInHeader {
                    Text(viewModel.configSummary ?? "")
                        .font(dynamicTypeSize.isAccessibilitySize ? .caption : .subheadline)
                        .foregroundStyle(Brand.textSecondary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 2)
                        .minimumScaleFactor(0.85)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DS.Spacing.s4)
                        .padding(.bottom, DS.Spacing.s2)
                }

                matchScoringBody(state: state)
                    .frame(maxHeight: .infinity)
            } else {
                Spacer()
                ProgressView().tint(Brand.textPrimary)
                    .accessibilityLabel(L10n.loading)
                Spacer()
            }
        }
        .frame(maxWidth: GameplayLayout.matchContentMaxWidth(horizontalSizeClass: horizontalSizeClass))
        .frame(maxWidth: .infinity)
        .background(Brand.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .matchLifecycleChrome(
            host: viewModel,
            showExitConfirmation: $showExitConfirmation,
            onShowSummary: onShowSummary,
            onDismiss: { dismiss() },
            dependencies: lifecycleDependencies
        )
        .sheet(isPresented: $showVisionScoring) {
            VisionScoringSheet(
                logger: visionLogger,
                isInputAllowed: viewModel.canHumanInput && viewModel.enteredDarts.count < 3,
                onDartConfirmed: { dart, _ in
                    guard viewModel.canHumanInput, viewModel.enteredDarts.count < 3 else { return }
                    viewModel.enteredDarts.append(dart)
                }
            )
        }
        .onChange(of: viewModel.legFinishSoundToken) { _, token in
            if token > 0 {
                audio.playLegFinished()
                postAccessibilityAnnouncement(L10n.string("play.x01.announce.legWon"))
                showLegWinBanner = true
                Task {
                    try? await Task.sleep(nanoseconds: Self.legWinBannerDisplayNanoseconds)
                    await MainActor.run { showLegWinBanner = false }
                }
            }
        }
        .onChange(of: viewModel.enteredDarts) { old, darts in
            playBotDartEntryFeedback(
                darts: darts,
                previousCount: old.count,
                isBotPlaying: viewModel.isBotPlaying,
                audio: audio,
                haptics: haptics,
                feedbackPreferences: feedbackPreferences
            )
        }
        .onChange(of: viewModel.turnTotalCallerSignal) { _, signal in
            guard let signal else { return }
            turnTotalCaller.announceTurnTotal(signal.total)
        }
        .onChange(of: viewModel.checkoutRoutes) { _, routes in
            selectedCheckoutIndex = 0
            announceCheckoutRoute(routes.first)
        }
        .onChange(of: selectedCheckoutIndex) { _, _ in
            guard let route = displayedCheckoutRoute else { return }
            announceCheckoutRoute(route)
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
        .onDisappear {
            actionTask?.cancel()
            guard !showExitConfirmation else { return }
            viewModel.onDisappear()
        }
    }

    private var showsConfigSummaryInHeader: Bool {
        usesLandscapeMatchLayout || horizontalSizeClass == .regular
    }

    private var pinsActivePlayerCard: Bool {
        GameplayLayout.usesPinnedActiveX01PlayerCard(
            playerCount: viewModel.playerCards.count,
            dynamicTypeSize: dynamicTypeSize,
            verticalSizeClass: verticalSizeClass
        )
    }

    private func matchScoringBody(state: X01State) -> some View {
        let cards = viewModel.playerCards
        let active = cards.first(where: \.isActive)
        let inactive = active.map { active in cards.filter { $0.id != active.id } } ?? cards
        let pinsActive = pinsActivePlayerCard

        return MatchScoringBody(
            playerCount: cards.count,
            showsActiveBand: pinsActive && active != nil,
            scoreboardSharesBottomRow: cards.count > 1,
            scoreboardFillsRemainingHeight: inactive.count >= 3,
            active: {
                if pinsActive, let active {
                    playerScoreCard(active)
                }
            },
            scoreboard: {
                playerCardStack(pinsActive ? inactive : cards)
            },
            padChrome: {
                statusBanners
            },
            pad: {
                scoringPad(
                    state: state,
                    landscape: GameplayLayout.usesLandscapeMatchScoringLayout(
                        verticalSizeClass: verticalSizeClass
                    )
                )
            }
        )
    }

    private func playerCardStack(_ cards: [X01MatchViewModel.PlayerCard]) -> some View {
        Group {
            if cards.isEmpty {
                EmptyView()
            } else if cards.count == 2,
                      GameplayLayout.usesIPadPortraitMatchScoringLayout(
                          horizontalSizeClass: horizontalSizeClass,
                          verticalSizeClass: verticalSizeClass
                      ) {
                HStack(spacing: DS.Spacing.s2) {
                    ForEach(cards) { card in
                        playerScoreCard(card)
                    }
                }
            } else {
                VStack(spacing: DS.Spacing.s2) {
                    ForEach(cards) { card in
                        playerScoreCard(card)
                    }
                }
            }
        }
    }

    private func playerScoreCard(_ card: X01MatchViewModel.PlayerCard) -> some View {
        PlayerScoreCard(
            name: card.name,
            score: card.score,
            setsWon: card.setsWon,
            legsWon: card.legsWon,
            isActive: card.isActive,
            colorToken: card.colorToken,
            visitDarts: card.visitDarts,
            dartsThrown: card.dartsThrown,
            average: card.average
        )
    }

    @ViewBuilder
    private var statusBanners: some View {
        VStack(spacing: DS.Spacing.s2) {
            checkoutBanner
            botTurnBanner
            stateBanner
            visionScoringButton
        }
    }

    @ViewBuilder
    private var visionScoringButton: some View {
        Group {
            if visionScoringEnabled {
                Button {
                    showVisionScoring = true
                } label: {
                    Label(L10n.string("vision.launchButton"), systemImage: "camera.viewfinder")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.green)
                        .padding(.vertical, DS.Spacing.s2)
                        .padding(.horizontal, DS.Spacing.s4)
                        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                }
                .accessibilityLabel(L10n.string("vision.launchButton.accessibility"))
                .accessibilityIdentifier("vision_scoring_button")
            }
        }
        .animation(
            MotionPolicy.fastAnimation(reduceMotion: reduceMotion),
            value: viewModel.checkoutRoutes.isEmpty
        )
    }

    private func scoringPad(state: X01State, landscape: Bool = false) -> some View {
        Group {
            if usesVisualBoardEntry {
                VisualDartboardInput(
                    enteredDarts: $viewModel.enteredDarts,
                    selectedMultiplier: $viewModel.selectedMultiplier,
                    showsVisitPreview: !landscape,
                    onUndoTurn: { runUndo() }
                )
            } else {
                DartNumberPad(
                    enteredDarts: $viewModel.enteredDarts,
                    selectedMultiplier: $viewModel.selectedMultiplier,
                    showsVisitPreview: !landscape,
                    onUndoTurn: { runUndo() }
                )
            }
        }
        .disabled(viewModel.canHumanInput == false)
        .opacity(viewModel.canHumanInput ? 1 : 0.45)
        .accessibilityElement(children: .contain)
        .modifier(
            OptionalAccessibilityHint(
                hint: viewModel.canHumanInput ? nil : L10n.string("play.x01.pad.disabledWhileBot")
            )
        )
        .padding(.horizontal, landscape ? 0 : DS.Spacing.s1)
        .padding(.bottom, landscape ? 0 : DS.Spacing.s1)
        .onChange(of: viewModel.enteredDarts) { old, darts in
            guard viewModel.canHumanInput else { return }
            if darts.count > old.count, let dart = darts.last { playDartFeedback(dart) }
            autoSubmitIfNeeded(darts: darts, state: state)
        }
    }

    @ViewBuilder
    private var checkoutBanner: some View {
        if viewModel.checkoutRoutes.isEmpty == false {
            CheckoutSuggestionBanner(
                routes: viewModel.checkoutRoutes,
                selectedIndex: $selectedCheckoutIndex
            )
            .transition(.opacity)
        }
    }

    private var displayedCheckoutRoute: [String]? {
        let routes = viewModel.checkoutRoutes
        guard routes.isEmpty == false else { return nil }
        let index = min(max(selectedCheckoutIndex, 0), routes.count - 1)
        return routes[index]
    }

    private func announceCheckoutRoute(_ route: [String]?) {
        guard let route else {
            lastAnnouncedCheckout = nil
            return
        }
        let spoken = CheckoutSuggester.localizedDisplayLabels(for: route).joined(separator: ", ")
        guard spoken != lastAnnouncedCheckout else { return }
        lastAnnouncedCheckout = spoken
        postAccessibilityAnnouncement(
            L10n.format("play.x01.checkout.accessibilityFormat", spoken)
        )
    }

    @ViewBuilder
    private var botTurnBanner: some View {
        if viewModel.isBotPlaying {
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
                in: RoundedRectangle(cornerRadius: DS.Radius.sm)
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
                .accessibilityHidden(true)
                .accessibilityIdentifier("legWonBanner")
        } else {
            switch viewModel.state {
            case .bustFeedback:
                MatchFeedbackBanner(text: L10n.bustFeedback, style: .bust)
                    .accessibilityHidden(true)
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
        actionTask = Task { await viewModel.undoLastDart() }
    }

    private func playDartFeedback(_ dart: DartInput) {
        if dart.isMiss { audio.playMiss() } else { audio.playHit() }
        haptics.playImpact()
    }
}
