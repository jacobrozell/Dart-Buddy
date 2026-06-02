import SwiftUI

struct SetupHomeView: View {
    @ObservedObject var homeViewModel: PlayHomeViewModel
    @ObservedObject var setupViewModel: MatchSetupViewModel
    @ObservedObject var pendingMatchPlayerSelections: PendingMatchPlayerSelections
    let onResumeMatch: (MatchSummary) -> Void
    let onStartRoute: (PlayRoute) -> Void
    let onQuickAddPlayer: () -> Void
    @State private var startTask: Task<Void, Never>?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                Text("Dart Scoreboard")
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(.white)
                    .padding(.top, DS.Spacing.s2)

                if case let .readyWithActiveMatch(match) = homeViewModel.state {
                    resumeBanner(match)
                }

                modePill
                if setupViewModel.mode == .x01 {
                    chipsGrid
                }
                startButton
                rosterControls
                playerList
            }
            .padding(.horizontal, DS.Spacing.s4)
            .padding(.bottom, DS.Spacing.s6)
        }
        .background(Brand.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .onChange(of: pendingMatchPlayerSelections.changeCount) { _, _ in
            Task { await setupViewModel.onAppear() }
        }
        .alert("play.setup.activeConflict.title", isPresented: $setupViewModel.showActiveMatchConflict) {
            Button("common.cancel", role: .cancel) {}
            Button("play.setup.activeConflict.confirm", role: .destructive) {
                startTask?.cancel()
                startTask = Task {
                    if let route = await setupViewModel.confirmReplaceActiveMatch() {
                        onStartRoute(route)
                    }
                }
            }
        } message: {
            Text("play.setup.activeConflict.message")
        }
        .onDisappear { startTask?.cancel() }
    }

    private func resumeBanner(_ match: MatchSummary) -> some View {
        Button { onResumeMatch(match) } label: {
            HStack {
                Image(systemName: "play.circle.fill")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Resume match").font(.headline)
                    Text(match.type.rawValue.uppercased()).font(.caption).foregroundStyle(Brand.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Brand.textSecondary)
            }
            .foregroundStyle(.white)
            .padding(DS.Spacing.s4)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.md).stroke(Brand.green, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("resumeMatchButton")
    }

    private var modePill: some View {
        HStack(spacing: 0) {
            modeButton("X01", mode: .x01)
            modeButton("Cricket", mode: .cricket)
        }
        .padding(4)
        .background(Brand.card, in: Capsule())
        .frame(maxWidth: .infinity)
    }

    private func modeButton(_ title: String, mode: MatchSetupViewModel.SetupMode) -> some View {
        let isSelected = setupViewModel.mode == mode
        return Button { setupViewModel.updateMode(mode) } label: {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.s2)
                .background(isSelected ? Brand.cardElevated : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var chipsGrid: some View {
        VStack(spacing: DS.Spacing.s3) {
            HStack(spacing: DS.Spacing.s3) {
                pointsChip
                checkoutChip
                setsChip
            }
            HStack(spacing: DS.Spacing.s3) {
                legFormatChip
                checkInChip
                legsChip
            }
        }
    }

    private var pointsChip: some View {
        chip(title: "Points", color: Brand.green) {
            Menu {
                ForEach(X01StartScores.all, id: \.self) { score in
                    Button("\(score)") {
                        setupViewModel.x01StartScore = score
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox("\(setupViewModel.x01StartScore)", color: Brand.green, showsMenuIndicator: true)
            }
        }
    }

    private var checkoutChip: some View {
        chip(title: "Check-Out", color: Brand.red) {
            Menu {
                ForEach(X01CheckoutMode.allCases, id: \.rawValue) { value in
                    Button(value.displayName) {
                        setupViewModel.x01CheckoutMode = value
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(setupViewModel.x01CheckoutMode.displayName, color: Brand.red, showsMenuIndicator: true)
            }
        }
    }

    private var checkInChip: some View {
        chip(title: "Check-In", color: Brand.red) {
            Menu {
                ForEach(X01CheckInMode.allCases, id: \.rawValue) { value in
                    Button(value.displayName) {
                        setupViewModel.x01CheckInMode = value
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(setupViewModel.x01CheckInMode.displayName, color: Brand.red, showsMenuIndicator: true)
            }
        }
    }

    private var legFormatChip: some View {
        chip(title: "Set/Leg", color: Brand.green) {
            Menu {
                ForEach(X01LegFormat.allCases, id: \.rawValue) { value in
                    Button(value.displayName) {
                        setupViewModel.x01LegFormat = value
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(setupViewModel.x01LegFormat.displayName, color: Brand.green, showsMenuIndicator: true)
            }
        }
    }

    private var setsChip: some View {
        chip(title: "Sets", color: Brand.green) {
            Menu {
                ForEach(1 ... 5, id: \.self) { value in
                    Button("\(value)") {
                        setupViewModel.x01SetsToWin = value
                        setupViewModel.x01SetsEnabled = value > 1
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox("\(setupViewModel.x01SetsEnabled ? setupViewModel.x01SetsToWin : 1)", color: Brand.green, showsMenuIndicator: true)
            }
        }
    }

    private var legsChip: some View {
        chip(title: "Legs", color: Brand.green) {
            Menu {
                ForEach(1 ... 9, id: \.self) { value in
                    Button("\(value)") {
                        setupViewModel.x01LegsToWin = value
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox("\(setupViewModel.x01LegsToWin)", color: Brand.green, showsMenuIndicator: true)
            }
        }
    }

    private func chip<Content: View>(title: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 6) {
            Text(title).font(.caption).foregroundStyle(Brand.textSecondary)
            content()
        }
        .frame(maxWidth: .infinity)
    }

    private func chipBox(_ text: String, color: Color, showsMenuIndicator: Bool = false) -> some View {
        Text(text)
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(.horizontal, 4)
            .background(color, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
            .overlay(alignment: .topTrailing) {
                if showsMenuIndicator {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(5)
                }
            }
    }

    private var startButton: some View {
        VStack(spacing: 6) {
            Button {
                startTask?.cancel()
                startTask = Task {
                    if let route = await setupViewModel.startMatchRoute() {
                        onStartRoute(route)
                    }
                }
            } label: {
                Text(setupViewModel.isSubmitting ? "STARTING…" : "START")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(setupViewModel.canStart ? Brand.red : Brand.red.opacity(0.4), in: RoundedRectangle(cornerRadius: DS.Radius.lg))
            }
            .buttonStyle(.plain)
            .disabled(!setupViewModel.canStart)
            .accessibilityIdentifier("startMatchButton")

            ForEach(setupViewModel.validationErrors, id: \.self) { key in
                playLocalizedText(key).font(.footnote).foregroundStyle(Brand.red)
            }
        }
        .padding(.top, DS.Spacing.s2)
    }

    private var rosterControls: some View {
        HStack {
            Button { setupViewModel.randomOrder.toggle() } label: {
                HStack(spacing: 8) {
                    Image(systemName: setupViewModel.randomOrder ? "checkmark.square.fill" : "square")
                        .foregroundStyle(setupViewModel.randomOrder ? Brand.green : Brand.textSecondary)
                    Text("Random order").foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            Spacer()
            HStack(spacing: DS.Spacing.s2) {
                Menu {
                    botMenuButton("Easy", difficulty: .easy, color: Brand.green)
                    botMenuButton("Medium", difficulty: .medium, color: Brand.amber)
                    botMenuButton("Hard", difficulty: .hard, color: Brand.red)
                    botMenuButton("Pro", difficulty: .pro, color: Brand.proBot)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "cpu")
                        Text("Add Bot").font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, DS.Spacing.s3)
                    .padding(.vertical, DS.Spacing.s2)
                    .background(Brand.cardElevated, in: Capsule())
                    .overlay(Capsule().stroke(Brand.textSecondary.opacity(0.35), lineWidth: 1))
                }
                Button { onQuickAddPlayer() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.plus")
                        Text("Add Players").font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, DS.Spacing.s3)
                    .padding(.vertical, DS.Spacing.s2)
                    .background(Brand.green, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, DS.Spacing.s2)
    }

    private func botMenuButton(_ title: String, difficulty: BotDifficulty, color: Color) -> some View {
        Button {
            startTask?.cancel()
            startTask = Task { await setupViewModel.addBot(difficulty) }
        } label: {
            Label {
                Text(title)
            } icon: {
                Circle().fill(color).frame(width: 10, height: 10)
            }
        }
    }

    @ViewBuilder
    private var playerList: some View {
        if setupViewModel.availableHumans.isEmpty && setupViewModel.availableBots.isEmpty {
            Text("Add at least two players or bots to start a match.")
                .font(.footnote)
                .foregroundStyle(Brand.textSecondary)
        } else {
            VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                if !setupViewModel.availableBots.isEmpty {
                    Text("Bots").font(.headline).foregroundStyle(.white)
                    botRosterList
                }
                if !setupViewModel.availableHumans.isEmpty {
                    Text("Players").font(.headline).foregroundStyle(.white)
                    humanRosterList
                }
            }
        }
    }

    private var botRosterList: some View {
        VStack(spacing: 0) {
            ForEach(setupViewModel.availableBots) { bot in
                rosterRow(
                    id: bot.id,
                    name: bot.name,
                    difficulty: bot.botDifficulty,
                    accessibilityId: "select_bot_\(bot.botDifficultyRaw ?? "unknown")"
                )
                Divider().overlay(Brand.cardElevated)
            }
        }
    }

    private var humanRosterList: some View {
        VStack(spacing: 0) {
            ForEach(setupViewModel.availableHumans) { player in
                rosterRow(
                    id: player.id,
                    name: player.name,
                    difficulty: nil,
                    accessibilityId: "select_\(player.name)"
                )
                Divider().overlay(Brand.cardElevated)
            }
        }
    }

    private func rosterRow(id: UUID, name: String, difficulty: BotDifficulty?, accessibilityId: String) -> some View {
        let isSelected = setupViewModel.selectedPlayerIds.contains(id)
        return Button { setupViewModel.togglePlayer(id) } label: {
            HStack(spacing: DS.Spacing.s3) {
                if let difficulty {
                    Image(systemName: "cpu.fill")
                        .foregroundStyle(botDifficultyColor(difficulty))
                } else {
                    Image(systemName: "location.north.fill")
                        .rotationEffect(.degrees(135))
                        .foregroundStyle(Brand.textSecondary)
                }
                Text(name)
                    .font(.headline)
                    .foregroundStyle(isSelected ? .white : Brand.textSecondary)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? (difficulty.map(botDifficultyColor) ?? Brand.green) : Brand.textSecondary)
            }
            .padding(.vertical, DS.Spacing.s3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityId)
    }

    private func botDifficultyColor(_ difficulty: BotDifficulty) -> Color {
        switch difficulty {
        case .easy: Brand.green
        case .medium: Brand.amber
        case .hard: Brand.red
        case .pro: Brand.proBot
        }
    }
}
