import SwiftUI

struct MatchSummaryScreen: View {
    @StateObject var viewModel: MatchSummaryViewModel
    let onStartNewMatch: () -> Void
    let onViewHistoryDetail: (UUID) -> Void
    let onUndoLastThrow: ([DartInput]) -> Void

    @State private var undoTask: Task<Void, Never>?

    @State private var celebrate = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var trophySize: CGFloat = 56
    @ScaledMetric(relativeTo: .largeTitle) private var landscapeTrophySize: CGFloat = 72

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
            if reduceMotion {
                celebrate = true
            } else {
                try? await Task.sleep(nanoseconds: 120_000_000)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { celebrate = true }
            }
        }
        .onDisappear { undoTask?.cancel() }
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
                } else {
                    Text(L10n.summaryResult)
                        .font(.title.weight(.heavy))
                        .foregroundStyle(Brand.textPrimary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                landscapeActions
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
                ForEach(viewModel.playerRows) { row in
                    playerCard(row, layout: .horizontal, compactStats: true)
                        .frame(maxWidth: .infinity)
                }
            }
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: DS.Spacing.s3) {
                    ForEach(viewModel.playerRows) { row in
                        playerCard(row, layout: .horizontal, compactStats: true)
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
            } else {
                Text(L10n.summaryResult).font(.title.weight(.heavy)).foregroundStyle(Brand.textPrimary)
            }
            if !isRegularWidth { Spacer(minLength: DS.Spacing.s4) }
            actions(compact: false)
        }
        .frame(
            maxWidth: GameplayLayout.contentMaxWidth(horizontalSizeClass: horizontalSizeClass),
            maxHeight: isRegularWidth ? .infinity : nil,
            alignment: .top
        )
        .frame(maxWidth: .infinity, alignment: isRegularWidth ? .center : .leading)
        .padding(DS.Spacing.s4)
        .padding(.top, isRegularWidth ? DS.Spacing.s6 : 0)
    }

    private func celebrationHeader(trophyPointSize: CGFloat) -> some View {
        VStack(spacing: DS.Spacing.s2) {
            Image(systemName: "trophy.fill")
                .font(.system(size: trophyPointSize))
                .foregroundStyle(Brand.amber)
                .scaleEffect(celebrate ? 1 : (reduceMotion ? 1 : 0.4))
                .opacity(celebrate ? 1 : (reduceMotion ? 1 : 0))
                .rotationEffect(.degrees(celebrate ? 0 : (reduceMotion ? 0 : -25)))
                .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.6), value: celebrate)
            if let winnerName = viewModel.winnerName {
                Text(L10n.format("play.summary.winsFormat", winnerName))
                    .font(usesLandscapeSplit ? .largeTitle.weight(.heavy) : .title.weight(.heavy))
                    .foregroundStyle(Brand.textPrimary)
                    .multilineTextAlignment(.center)
            }
            Text(viewModel.typeLabel)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, usesLandscapeSplit ? 0 : DS.Spacing.s4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(celebrationHeaderAccessibilityLabel)
        .accessibilityIdentifier("matchSummaryHeader")
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
                ForEach(viewModel.playerRows) { row in
                    playerCard(row, layout: .horizontal, compactStats: true)
                        .frame(maxWidth: .infinity)
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
                ForEach(viewModel.playerRows) { row in
                    playerCard(row, layout: .fitsWidth)
                }
            }
        }
    }

    private var stackedPlayerCards: some View {
        ForEach(viewModel.playerRows) { row in
            playerCard(row, layout: .fitsWidth)
        }
    }

    private var celebrationHeaderAccessibilityLabel: String {
        guard let winnerName = viewModel.winnerName else { return viewModel.typeLabel }
        return L10n.format("play.summary.header.accessibilityFormat", winnerName, viewModel.typeLabel)
    }

    private enum PlayerCardStatLayout {
        case horizontal
        case fitsWidth
    }

    private func playerCard(
        _ row: MatchSummaryViewModel.PlayerRow,
        layout: PlayerCardStatLayout,
        compactStats: Bool = false
    ) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(row.isWinner ? Brand.amber : Color.clear)
                .frame(width: 6)
            VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                HStack(spacing: 6) {
                    if row.isWinner {
                        Image(systemName: "crown.fill").font(.caption).foregroundStyle(Brand.amber)
                    }
                    Text(row.name)
                        .font(.headline)
                        .foregroundStyle(row.isWinner ? Brand.amber : Brand.textPrimary)
                        .lineLimit(1)
                }
                switch layout {
                case .horizontal:
                    playerCardStats(row, layout: .horizontal, compact: compactStats)
                case .fitsWidth:
                    ViewThatFits(in: .horizontal) {
                        playerCardStats(row, layout: .horizontal, compact: compactStats)
                        playerCardStats(row, layout: .vertical, compact: compactStats)
                    }
                }
            }
            .padding(compactStats ? DS.Spacing.s2 : DS.Spacing.s3)
            Spacer(minLength: 0)
        }
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(playerRowAccessibilityLabel(row))
    }

    private enum PlayerCardStatsAxis {
        case horizontal
        case vertical
    }

    @ViewBuilder
    private func playerCardStats(
        _ row: MatchSummaryViewModel.PlayerRow,
        layout: PlayerCardStatsAxis,
        compact: Bool
    ) -> some View {
        let spacing = compact ? DS.Spacing.s2 : DS.Spacing.s3
        switch layout {
        case .horizontal:
            HStack(spacing: spacing) {
                ForEach(row.stats, id: \.label) { stat in
                    StatChip(value: stat.value, label: LocalizedStringKey(stat.label), compact: compact)
                }
            }
        case .vertical:
            VStack(alignment: .leading, spacing: spacing) {
                ForEach(row.stats, id: \.label) { stat in
                    StatChip(value: stat.value, label: LocalizedStringKey(stat.label), compact: compact)
                }
            }
        }
    }

    private func playerRowAccessibilityLabel(_ row: MatchSummaryViewModel.PlayerRow) -> String {
        let stats = row.stats.map { "\($0.label) \($0.value)" }.joined(separator: ", ")
        let prefix = row.isWinner ? L10n.string("play.summary.player.winnerPrefix") : ""
        return L10n.format("play.summary.player.accessibilityFormat", prefix, row.name, stats)
    }

    @ViewBuilder
    private func actions(compact: Bool) -> some View {
        if compact {
            landscapeActions
        } else {
            VStack(spacing: DS.Spacing.s3) {
                portraitActionButtons
            }
            .padding(.top, DS.Spacing.s2)
        }
    }

    private var landscapeActions: some View {
        HStack(spacing: DS.Spacing.s3) {
            if viewModel.canUndoLastThrow {
                summarySecondaryButton(
                    title: L10n.summaryUndoLastThrow,
                    action: runUndoLastThrow,
                    isLoading: viewModel.isUndoing,
                    identifier: "matchSummaryUndoLastThrow",
                    hint: L10n.summaryUndoLastThrowHint,
                    compact: true
                )
            }
            if let undoErrorKey = viewModel.undoErrorKey {
                ErrorBanner(messageKey: undoErrorKey)
            }
            PrimaryActionButton(title: L10n.summaryNewMatch, action: onStartNewMatch)
            summarySecondaryButton(
                title: L10n.summaryViewGameStatistics,
                action: { onViewHistoryDetail(viewModel.matchId) },
                compact: true
            )
        }
        .padding(.top, DS.Spacing.s1)
    }

    @ViewBuilder
    private var portraitActionButtons: some View {
        if viewModel.canUndoLastThrow {
            Button(action: runUndoLastThrow) {
                Group {
                    if viewModel.isUndoing {
                        ProgressView()
                            .tint(Brand.textPrimary)
                            .accessibilityLabel(L10n.loading)
                    } else {
                        Text(L10n.summaryUndoLastThrow)
                            .font(.headline)
                            .foregroundStyle(Brand.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isUndoing)
            .accessibilityHint(L10n.summaryUndoLastThrowHint)
            .accessibilityIdentifier("matchSummaryUndoLastThrow")
        }
        if let undoErrorKey = viewModel.undoErrorKey {
            ErrorBanner(messageKey: undoErrorKey)
        }
        PrimaryActionButton(title: L10n.summaryNewMatch, action: onStartNewMatch)
        Button(action: { onViewHistoryDetail(viewModel.matchId) }) {
            Text(L10n.summaryViewGameStatistics)
                .font(.headline).foregroundStyle(Brand.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
        }
        .buttonStyle(.plain)
    }

    private func summarySecondaryButton(
        title: LocalizedStringKey,
        action: @escaping () -> Void,
        isLoading: Bool = false,
        identifier: String? = nil,
        hint: LocalizedStringKey? = nil,
        compact: Bool = false
    ) -> some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(Brand.textPrimary)
                        .accessibilityLabel(L10n.loading)
                } else {
                    Text(title)
                        .font(compact ? .subheadline.weight(.semibold) : .headline)
                        .foregroundStyle(Brand.textPrimary)
                        .lineLimit(compact ? 2 : 1)
                        .minimumScaleFactor(compact ? 0.85 : 1)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, minHeight: compact ? 48 : 52)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .modifier(SummarySecondaryButtonAccessibility(identifier: identifier, hint: hint))
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

private struct SummarySecondaryButtonAccessibility: ViewModifier {
    let identifier: String?
    let hint: LocalizedStringKey?

    func body(content: Content) -> some View {
        if let identifier, let hint {
            content
                .accessibilityIdentifier(identifier)
                .accessibilityHint(hint)
        } else if let identifier {
            content.accessibilityIdentifier(identifier)
        } else if let hint {
            content.accessibilityHint(hint)
        } else {
            content
        }
    }
}
