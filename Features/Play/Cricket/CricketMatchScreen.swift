import SwiftUI

struct CricketMatchScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ObservedObject var viewModel: CricketMatchViewModel
    let onShowSummary: () -> Void
    let audio: any AudioFeedbackService
    let haptics: any HapticsService
    let turnTotalCaller: any TurnTotalCallerService
    let feedbackPreferences: FeedbackPreferences
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showExitConfirmation = false
    @State private var actionTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            MatchGameplayHeader(onExit: { showExitConfirmation = true }) {
                VStack(alignment: .leading, spacing: 2) {
                    BrandMatchScreenTitle(title: L10n.cricketTitle)
                    if let subtitle = viewModel.matchSubtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(Brand.textSecondary)
                            .accessibilityIdentifier("cricket_match_subtitle")
                    }
                }
            } trailing: {
                Button {
                    actionTask?.cancel()
                    actionTask = Task { await viewModel.undoLastDart() }
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Brand.green)
                        .frame(width: 44, height: 44)
                        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                }
                .accessibilityLabel(L10n.scoringUndoLastTurn)
            }

            if let state = viewModel.cricketState {
                if !usesSideBySideMatchLayout && !usesLandscapePinnedLayout {
                    roundTurnLabel(state: state)
                }

                Group {
                    if GameplayLayout.usesAccessibilityMatchScoringLayout(dynamicTypeSize: dynamicTypeSize) {
                        accessibilityScoringStack
                    } else if usesLandscapePinnedLayout {
                        landscapeIPhoneScoringStack
                    } else if usesSideBySideMatchLayout {
                        landscapeScoringStack
                    } else {
                        portraitScoringStack
                    }
                }
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
            switch newValue {
            case .closureTransition:
                haptics.playSuccess()
                postAccessibilityAnnouncement(L10n.string("play.cricket.targetClosed"))
            case .matchCompleted:
                audio.playMatchFinished()
                onShowSummary()
            default:
                break
            }
        }
        .onChange(of: viewModel.turnTotalCallerSignal) { _, signal in
            guard let signal else { return }
            turnTotalCaller.announceTurnTotal(signal.total)
        }
        .onChange(of: viewModel.enteredDarts.count) { oldCount, newCount in
            guard viewModel.isBotPlaying, newCount > oldCount else { return }
            guard feedbackPreferences.botDartHapticsEnabled else { return }
            haptics.playImpact()
        }
        .task { await viewModel.onAppear() }
        .onDisappear {
            actionTask?.cancel()
            viewModel.onDisappear()
        }
    }

    private var cricketBoard: some View {
        Group {
            if usesTransposedCricketBoard {
                if let active = viewModel.boardColumns.first(where: \.isActive) {
                    CricketTransposedBoardView(
                        column: active,
                        allColumns: viewModel.boardColumns
                    )
                }
            } else {
                CricketBoardView(
                    columns: viewModel.boardColumns,
                    activeColumnScrollID: viewModel.activeBoardColumnID,
                    fillsAvailableHeight: usesCricketBoardFillsAvailableHeight
                )
            }
        }
    }

    private var cricketControls: some View {
        VStack(spacing: DS.Spacing.s2) {
            stateBanner
            cricketTapPad
        }
    }

    /// Board scrolls above a pinned pad so stats and keys never overlap.
    private var portraitScoringStack: some View {
        VStack(spacing: 0) {
            ScrollView {
                cricketBoard
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            cricketControls
                .padding(.top, DS.Spacing.s2)
        }
        .padding(.horizontal, DS.Spacing.s4)
        .padding(.bottom, DS.Spacing.s2)
    }

    private var usesSideBySideMatchLayout: Bool {
        GameplayLayout.usesSideBySideMatchScoringLayout(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        )
        && !GameplayLayout.usesAccessibilityMatchScoringLayout(dynamicTypeSize: dynamicTypeSize)
    }

    /// iPhone landscape: current player board pinned at top, full-width pad pinned at bottom (X01-style).
    private var usesLandscapePinnedLayout: Bool {
        GameplayLayout.usesCricketLandscapePinnedLayout(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass,
            dynamicTypeSize: dynamicTypeSize
        )
    }

    private var usesTransposedCricketBoard: Bool {
        GameplayLayout.usesTransposedCricketBoardLayout(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        )
    }

    private var usesCricketBoardFillsAvailableHeight: Bool {
        GameplayLayout.usesCricketBoardFillsAvailableHeight(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        )
    }

    private var landscapeScoringStack: some View {
        HStack(alignment: .top, spacing: DS.Spacing.s2) {
            VStack(alignment: .leading, spacing: DS.Spacing.s1) {
                if let state = viewModel.cricketState {
                    landscapeRoundTurnLabel(state: state)
                }
                if usesTransposedCricketBoard || usesCricketBoardFillsAvailableHeight {
                    cricketBoard
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                } else {
                    ScrollView {
                        cricketBoard
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            cricketControls
                .frame(
                    width: GameplayLayout.scoringPadFixedWidth(
                        horizontalSizeClass: horizontalSizeClass,
                        verticalSizeClass: verticalSizeClass
                    ),
                    alignment: .top
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, DS.Spacing.s4)
        .padding(.bottom, DS.Spacing.s2)
    }

    /// iPhone landscape: the active player's board stays locked at the top while the
    /// full-width tap pad is pinned to the bottom — mirrors the X01 landscape layout.
    /// The board sits in a scroll view so the pad never clips on shorter devices.
    private var landscapeIPhoneScoringStack: some View {
        VStack(spacing: DS.Spacing.s2) {
            if let state = viewModel.cricketState {
                landscapeRoundTurnLabel(state: state)
            }
            ScrollView {
                cricketBoard
            }
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            cricketControls
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, DS.Spacing.s4)
        .padding(.bottom, DS.Spacing.s2)
    }

    private func landscapeRoundTurnLabel(state: CricketState) -> some View {
        let round = state.roundIndex + 1
        let turn = state.currentPlayerIndex + 1
        return Text(L10n.format("play.cricket.roundTurn", round, turn))
            .font(.caption)
            .foregroundStyle(Brand.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DS.Spacing.s2)
            .padding(.top, DS.Spacing.s1)
    }

    private var accessibilityScoringStack: some View {
        Group {
            // iPad landscape has the width for a side-by-side board + pad even at AX sizes;
            // iPhone landscape scrolls the board above the pad so nothing clips.
            if GameplayLayout.usesLandscapeMatchScoringLayout(verticalSizeClass: verticalSizeClass)
                && horizontalSizeClass == .regular {
                landscapeScoringStack
            } else {
                ScrollView {
                    VStack(spacing: DS.Spacing.s2) {
                        cricketBoard
                        cricketControls
                    }
                    .padding(.horizontal, DS.Spacing.s4)
                    .padding(.bottom, DS.Spacing.s2)
                }
            }
        }
    }

    @ViewBuilder
    private func roundTurnLabel(state: CricketState) -> some View {
        let round = state.roundIndex + 1
        let turn = state.currentPlayerIndex + 1

        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.format("play.cricket.round", round))
                    Text(L10n.format("play.cricket.turn", turn))
                }
                .font(.caption)
            } else {
                Text(L10n.format("play.cricket.roundTurn", round, turn))
                    .font(.subheadline)
            }
        }
        .foregroundStyle(Brand.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DS.Spacing.s4)
        .padding(.bottom, DS.Spacing.s2)
    }

    private var cricketTapPad: some View {
        CricketTapPad(
            enteredDarts: $viewModel.enteredDarts,
            selectedMultiplier: $viewModel.selectedMultiplier,
            canSubmit: viewModel.canSubmit,
            onSubmit: { submit() },
            onUndoTurn: {
                actionTask?.cancel()
                actionTask = Task { await viewModel.undoLastDart() }
            }
        )
        .disabled(viewModel.canHumanInput == false)
        .opacity(viewModel.canHumanInput ? 1 : 0.45)
        .accessibilityElement(children: .contain)
        .modifier(
            OptionalAccessibilityHint(
                hint: viewModel.canHumanInput ? nil : L10n.string("play.cricket.pad.disabledWhileBot")
            )
        )
        .onChange(of: viewModel.enteredDarts) { old, darts in
            guard viewModel.canHumanInput else { return }
            if darts.count > old.count, let dart = darts.last { playDartFeedback(dart) }
            if darts.count == 3 { submit() }
        }
    }

    private func playDartFeedback(_ dart: DartInput) {
        if dart.isMiss { audio.playMiss() } else { audio.playHit() }
        haptics.playImpact()
    }

    private func submit() {
        actionTask?.cancel()
        actionTask = Task { await viewModel.submitTurn() }
    }

    private func postAccessibilityAnnouncement(_ text: String) {
        guard !text.isEmpty else { return }
        AccessibilityNotification.Announcement(text).post()
    }

    @ViewBuilder
    private var stateBanner: some View {
        switch viewModel.state {
        case .readyTurn:
            if viewModel.isBotPlaying {
                // Amber-on-background fails AA contrast in light mode; tinted pill + primary
                // text keeps the bot turn indicator legible in both appearances.
                Text(L10n.botThrowing)
                    .foregroundStyle(Brand.textPrimary)
                    .padding(.vertical, DS.Spacing.s2)
                    .padding(.horizontal, DS.Spacing.s4)
                    .background(
                        Brand.amber.opacity(colorScheme == .dark ? 0.32 : 0.22),
                        in: RoundedRectangle(cornerRadius: DS.Radius.sm)
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(L10n.string("play.match.botThrowing"))
            } else {
                EmptyView()
            }
        case .submittingTurn:
            Text(L10n.submittingTurn).foregroundStyle(Brand.textPrimary)
        case .closureTransition:
            MatchFeedbackBanner(text: L10n.cricketTargetClosed, style: .cricketClosure)
                .accessibilityIdentifier("cricketTargetClosedBanner")
        case let .entryInvalid(key), let .error(key):
            ErrorBanner(messageKey: key)
        case .matchCompleted:
            Text(L10n.matchCompleteRoute).foregroundStyle(Brand.textPrimary)
        }
    }
}
