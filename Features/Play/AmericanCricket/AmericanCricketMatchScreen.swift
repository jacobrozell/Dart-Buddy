import SwiftUI

struct AmericanCricketMatchScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: AmericanCricketMatchViewModel
    let onShowSummary: () -> Void
    let audio: any AudioFeedbackService
    let haptics: any HapticsService
    let feedbackPreferences: FeedbackPreferences
    let lifecycleDependencies: MatchLifecycleChromeDependencies
    @Environment(\.dismiss) private var dismiss
    @State private var showExitConfirmation = false
    @State private var actionTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            MatchGameplayHeader(onExit: { showExitConfirmation = true }) {
                VStack(alignment: .leading, spacing: 2) {
                    BrandMatchScreenTitle(title: "play.americanCricket.navTitle")
                    Text(viewModel.activeTargetLabel)
                        .font(.caption)
                        .foregroundStyle(Brand.amber)
                        .accessibilityIdentifier("americanCricket_active_target_label")
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(viewModel.activeTargetLabel)
                .accessibilityIdentifier("americanCricket_match_header")
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
                .accessibilityIdentifier("americanCricket_undo")
            }

            if viewModel.americanCricketState != nil {
                SideBySideMatchBody(playerCount: viewModel.boardColumns.count) {
                    AmericanCricketBoardView(
                        columns: viewModel.boardColumns,
                        activeColumnScrollID: viewModel.activeBoardColumnID
                    )
                } padChrome: {
                    stateBanner
                } controls: {
                    americanCricketPad
                }
                .onChange(of: viewModel.enteredDarts) { old, darts in
                    guard viewModel.canHumanInput else { return }
                    if darts.count > old.count, let dart = darts.last { playDartFeedback(dart) }
                    if darts.count == 3 { submit() }
                }
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
            case .targetAdvanced:
                haptics.playSuccess()
                postAccessibilityAnnouncement(L10n.string("play.americanCricket.segmentAdvanced"))
            case .matchCompleted:
                audio.playMatchFinished()
                onShowSummary()
            default:
                break
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
        .task { await viewModel.onAppear() }
        .onDisappear {
            actionTask?.cancel()
            guard !showExitConfirmation else { return }
            viewModel.onDisappear()
        }
    }

    @ViewBuilder
    private var stateBanner: some View {
        switch viewModel.state {
        case .readyTurn:
            if viewModel.isBotPlaying {
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
        case .targetAdvanced:
            MatchFeedbackBanner(text: "play.americanCricket.segmentAdvanced", style: .cricketClosure)
                .accessibilityHidden(true)
                .accessibilityIdentifier("americanCricket_target_advanced_banner")
        case let .entryInvalid(key), let .error(key):
            ErrorBanner(messageKey: key)
        case .matchCompleted:
            Text(L10n.matchCompleteRoute).foregroundStyle(Brand.textPrimary)
        }
    }

    private var americanCricketPad: some View {
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
        .disabled(!viewModel.canHumanInput)
        .opacity(viewModel.canHumanInput ? 1 : 0.45)
        .accessibilityElement(children: .contain)
        .modifier(
            OptionalAccessibilityHint(
                hint: viewModel.canHumanInput
                    ? L10n.string("play.americanCricket.activeTargetHint")
                    : L10n.string("play.americanCricket.pad.disabledWhileBot")
            )
        )
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
}
