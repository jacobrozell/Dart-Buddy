import SwiftUI

struct MatchSummaryScreen: View {
    @StateObject var viewModel: MatchSummaryViewModel
    /// Returns an error message key when rematch cannot start; `nil` on success.
    let onRematch: (MatchRuntimeState) async -> String?
    let onDone: () -> Void
    let onViewHistoryDetail: (UUID) -> Void
    let onUndoLastThrow: ([DartInput]) -> Void

    @State private var undoTask: Task<Void, Never>?
    @State private var rematchTask: Task<Void, Never>?
    @State private var isRematching = false
    @State private var rematchErrorKey: String?

    @State private var celebrate = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var trophySize: CGFloat = 56
    @ScaledMetric(relativeTo: .largeTitle) private var landscapeTrophySize: CGFloat = 72

    /// Brief beat before the trophy celebration springs in, so the summary settles first.
    private static let celebrationDelayNanoseconds: UInt64 = 120_000_000

    private var isRegularWidth: Bool { horizontalSizeClass == .regular }

    private var usesLandscapeSplit: Bool {
        GameplayLayout.usesLandscapeIPhoneMatchSummaryLayout(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass,
            dynamicTypeSize: dynamicTypeSize
        )
    }

    private var usesSideBySidePlayerGrid: Bool {
        GameplayLayout.usesMatchSummarySideBySidePlayerGrid(
            horizontalSizeClass: horizontalSizeClass,
            playerCount: viewModel.playerRows.count,
            dynamicTypeSize: dynamicTypeSize
        )
    }

    var body: some View {
        Group {
            if usesLandscapeSplit {
                landscapeSplitContent
            } else {
                GeometryReader { geometry in
                    ScrollView {
                        stackedSummaryContent
                            .frame(minHeight: geometry.size.height)
                    }
                }
            }
        }
        .background(Brand.background.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .sensoryFeedback(.success, trigger: celebrate)
        .task {
            await viewModel.loadIfNeeded()
            viewModel.refresh()
            await viewModel.reloadAchievementPresentations()
            if reduceMotion {
                celebrate = true
            } else {
                try? await Task.sleep(nanoseconds: Self.celebrationDelayNanoseconds)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { celebrate = true }
            }
        }
        .onDisappear {
            undoTask?.cancel()
            rematchTask?.cancel()
        }
    }

    private var landscapeSplitContent: some View {
        GeometryReader { geometry in
            VStack(spacing: DS.Spacing.s3) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Brand.green)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityLabel(L10n.loading)
                } else if viewModel.hasResult {
                    HStack(alignment: .center, spacing: DS.Spacing.s4) {
                        celebrationHeader(trophyPointSize: landscapeTrophySize)
                            .frame(width: min(280, geometry.size.width * 0.34), alignment: .center)
                        landscapePlayerCards
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: max(0, geometry.size.height - 64))
                    MatchSummaryAchievementsSection(presentations: viewModel.achievementPresentations)
                } else {
                    Text(L10n.summaryResult)
                        .font(.title.weight(.heavy))
                        .foregroundStyle(Brand.textPrimary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                actions(compact: true)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            .padding(.horizontal, DS.Spacing.s4)
            .padding(.vertical, DS.Spacing.s3)
        }
    }

    @ViewBuilder
    private var landscapePlayerCards: some View {
        if usesSideBySidePlayerGrid {
            HStack(spacing: DS.Spacing.s3) {
                ForEach(Array(viewModel.playerRows.enumerated()), id: \.element.id) { index, row in
                    MatchSummaryPlayerCard(row: row, layout: .horizontal, compactStats: true)
                        .frame(maxWidth: .infinity)
                        .motionStaggeredReveal(index: index, when: celebrate)
                }
            }
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: DS.Spacing.s3) {
                    ForEach(Array(viewModel.playerRows.enumerated()), id: \.element.id) { index, row in
                        MatchSummaryPlayerCard(row: row, layout: .horizontal, compactStats: true)
                            .motionStaggeredReveal(index: index, when: celebrate)
                    }
                }
            }
        }
    }

    private var stackedSummaryContent: some View {
        VStack(spacing: DS.Spacing.s4) {
            if viewModel.isLoading {
                ProgressView()
                    .tint(Brand.green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.s6)
                    .accessibilityLabel(L10n.loading)
            } else if viewModel.hasResult {
                celebrationHeader(trophyPointSize: trophySize)
                playerResultsGrid(axis: .vertical)
                MatchSummaryAchievementsSection(presentations: viewModel.achievementPresentations)
            } else {
                Text(L10n.summaryResult).font(.title.weight(.heavy)).foregroundStyle(Brand.textPrimary)
            }
            if !isRegularWidth { Spacer(minLength: DS.Spacing.s4) }
            actions(compact: false)
        }
        .frame(
            maxWidth: GameplayLayout.contentMaxWidth(horizontalSizeClass: horizontalSizeClass),
            maxHeight: isRegularWidth ? .infinity : nil,
            alignment: isRegularWidth ? .center : .top
        )
        .frame(maxWidth: .infinity, alignment: isRegularWidth ? .center : .leading)
        .padding(DS.Spacing.s4)
        .padding(.vertical, isRegularWidth ? DS.Spacing.s6 : 0)
    }

    private func celebrationHeader(trophyPointSize: CGFloat) -> some View {
        MatchSummaryCelebrationHeader(
            viewModel: viewModel,
            trophyPointSize: trophyPointSize,
            celebrate: celebrate,
            usesLandscapeSplit: usesLandscapeSplit
        )
    }

    private func actions(compact: Bool) -> some View {
        MatchSummaryActions(
            viewModel: viewModel,
            compact: compact,
            isRematching: isRematching,
            rematchErrorKey: rematchErrorKey,
            onRematch: runRematch,
            onDone: onDone,
            onViewStatistics: { onViewHistoryDetail(viewModel.matchId) },
            onUndoLastThrow: runUndoLastThrow
        )
    }

    @ViewBuilder
    private func playerResultsGrid(axis: Axis) -> some View {
        if usesSideBySidePlayerGrid {
            sideBySidePlayerGrid(axis: axis)
        } else {
            stackedPlayerCards
        }
    }

    @ViewBuilder
    private func sideBySidePlayerGrid(axis: Axis) -> some View {
        if axis == .horizontal {
            HStack(spacing: DS.Spacing.s3) {
                ForEach(Array(viewModel.playerRows.enumerated()), id: \.element.id) { index, row in
                    MatchSummaryPlayerCard(row: row, layout: .horizontal, compactStats: true)
                        .frame(maxWidth: .infinity)
                        .motionStaggeredReveal(index: index, when: celebrate)
                }
            }
        } else {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: DS.Spacing.s3),
                    GridItem(.flexible(), spacing: DS.Spacing.s3)
                ],
                spacing: DS.Spacing.s3
            ) {
                ForEach(Array(viewModel.playerRows.enumerated()), id: \.element.id) { index, row in
                    MatchSummaryPlayerCard(row: row, layout: .fitsWidth)
                        .motionStaggeredReveal(index: index, when: celebrate)
                }
            }
        }
    }

    private var stackedPlayerCards: some View {
        ForEach(Array(viewModel.playerRows.enumerated()), id: \.element.id) { index, row in
            MatchSummaryPlayerCard(row: row, layout: .fitsWidth)
                .motionStaggeredReveal(index: index, when: celebrate)
        }
    }

    private func runRematch() {
        guard viewModel.canRematch, let runtime = viewModel.session?.runtime else { return }
        rematchTask?.cancel()
        rematchTask = Task {
            rematchErrorKey = nil
            isRematching = true
            defer { isRematching = false }
            rematchErrorKey = await onRematch(runtime)
        }
    }

    private func runUndoLastThrow() {
        undoTask?.cancel()
        undoTask = Task {
            if let restoredDarts = await viewModel.undoLastThrow() {
                onUndoLastThrow(restoredDarts)
            }
        }
    }
}
