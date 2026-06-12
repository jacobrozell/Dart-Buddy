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
    let lifecycleDependencies: MatchLifecycleChromeDependencies
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
                .accessibilityIdentifier("match_undo")
            }

            if let state = viewModel.cricketState {
                if shouldShowPortraitRoundLabel {
                    roundTurnLabel(state: state)
                }

                cricketScoringBody
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
        .matchLifecycleChrome(
            host: viewModel,
            showExitConfirmation: $showExitConfirmation,
            onShowSummary: onShowSummary,
            onDismiss: { dismiss() },
            dependencies: lifecycleDependencies
        )
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
            guard !showExitConfirmation else { return }
            viewModel.onDisappear()
        }
    }

    private var shouldShowPortraitRoundLabel: Bool {
        !GameplayLayout.usesLandscapeMatchScoringLayout(verticalSizeClass: verticalSizeClass)
            && horizontalSizeClass != .regular
    }

    private var usesSplitCricketScoreboard: Bool {
        GameplayLayout.usesSideBySideBottomScoringRegion(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        )
    }

    private var cricketScoringBody: some View {
        let columns = viewModel.boardColumns
        let activeColumns = columns.filter(\.isActive)
        let inactiveColumns = columns.filter { !$0.isActive }
        let split = usesSplitCricketScoreboard

        let inactiveCount = split ? inactiveColumns.count : max(0, columns.count - 1)

        return MatchScoringBody(
            showsActiveBand: split && !activeColumns.isEmpty,
            scoreboardSharesBottomRow: split ? !inactiveColumns.isEmpty : true,
            scoreboardFillsRemainingHeight: inactiveCount >= 3,
            active: {
                if split {
                    activeCricketBoard(columns: activeColumns, allColumns: columns)
                }
            },
            scoreboard: {
                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                    if GameplayLayout.usesLandscapeMatchScoringLayout(verticalSizeClass: verticalSizeClass),
                       let state = viewModel.cricketState {
                        landscapeRoundTurnLabel(state: state)
                    }
                    if split {
                        inactiveCricketBoard(columns: inactiveColumns, allColumns: columns)
                    } else {
                        fullCricketBoard(columns: columns)
                    }
                }
            },
            padChrome: {
                stateBanner
            },
            pad: {
                cricketTapPad
            }
        )
    }

    @ViewBuilder
    private func fullCricketBoard(columns: [CricketBoardView.Column]) -> some View {
        if usesTransposedCricketBoard, let active = columns.first(where: \.isActive) {
            CricketTransposedBoardView(column: active, allColumns: columns)
        } else {
            CricketBoardView(
                columns: columns,
                activeColumnScrollID: viewModel.activeBoardColumnID,
                fillsAvailableHeight: usesCricketBoardFillsAvailableHeight
            )
        }
    }

    @ViewBuilder
    private func activeCricketBoard(columns: [CricketBoardView.Column], allColumns: [CricketBoardView.Column]) -> some View {
        if usesTransposedCricketBoard, let active = columns.first {
            CricketTransposedBoardView(column: active, allColumns: allColumns)
        } else if let active = columns.first {
            CricketBoardView(
                columns: [active],
                activeColumnScrollID: viewModel.activeBoardColumnID
            )
        }
    }

    @ViewBuilder
    private func inactiveCricketBoard(columns: [CricketBoardView.Column], allColumns: [CricketBoardView.Column]) -> some View {
        if columns.isEmpty {
            EmptyView()
        } else if usesTransposedCricketBoard {
            CricketBoardView(
                columns: columns,
                activeColumnScrollID: viewModel.activeBoardColumnID
            )
        } else {
            CricketBoardView(
                columns: columns,
                activeColumnScrollID: viewModel.activeBoardColumnID,
                fillsAvailableHeight: usesCricketBoardFillsAvailableHeight
            )
        }
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
                .accessibilityHidden(true)
                .accessibilityIdentifier("cricketTargetClosedBanner")
        case let .entryInvalid(key), let .error(key):
            ErrorBanner(messageKey: key)
        case .matchCompleted:
            Text(L10n.matchCompleteRoute).foregroundStyle(Brand.textPrimary)
        }
    }
}
