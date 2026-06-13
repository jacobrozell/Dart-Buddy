import SwiftUI

struct SetupHomeView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) var rosterRowHeight: CGFloat = 52
    @ScaledMetric(relativeTo: .body) var turnOrderRowVerticalInset: CGFloat = 8
    @ObservedObject var homeViewModel: PlayHomeViewModel
    @ObservedObject var setupViewModel: MatchSetupViewModel
    @ObservedObject var pendingMatchPlayerSelections: PendingMatchPlayerSelections
    let onResumeMatch: (MatchSummary) -> Void
    let onStartRoute: (PlayRoute) -> Void
    let onChangeMode: () -> Void
    @State var startTask: Task<Void, Never>?
    @State var showsAddPlayerSheet = false
    @State private var showsGameRules = false
    @State var showsCustomBotSheet = false
    @State private var showsEditOptions = false
    @State private var showsModePicker = false

    private var usesWideSetupLayout: Bool {
        GameplayLayout.usesWideSetupHomeLayout(
            horizontalSizeClass: horizontalSizeClass,
            dynamicTypeSize: dynamicTypeSize
        )
    }

    var body: some View {
        ScrollView {
            Group {
                if usesWideSetupLayout {
                    wideSetupContent
                } else {
                    compactSetupContent
                }
            }
            .padding(.horizontal, DS.Spacing.s4)
            .padding(.bottom, setupScrollBottomPadding)
            .frame(maxWidth: GameplayLayout.contentMaxWidth(horizontalSizeClass: horizontalSizeClass))
            .frame(maxWidth: .infinity)
        }
        .background(Brand.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            startButton
                .frame(maxWidth: GameplayLayout.contentMaxWidth(horizontalSizeClass: horizontalSizeClass))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, DS.Spacing.s4)
                .padding(.top, DS.Spacing.s3)
                .padding(.bottom, DS.Spacing.s2)
                .background {
                    Brand.background
                        .shadow(color: setupStickyShadowColor, radius: 10, y: -4)
                        .ignoresSafeArea(edges: .bottom)
                }
        }
        .onAppear {
            Task { await setupViewModel.onAppear() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .settingsDidUpdate)) { _ in
            Task { await setupViewModel.onAppear() }
        }
        .onChange(of: pendingMatchPlayerSelections.changeCount) { _, _ in
            if let selection = pendingMatchPlayerSelections.consumeModeSelection() {
                setupViewModel.applyPendingModeSelection(selection)
            }
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
        .sheet(isPresented: $showsGameRules) {
            if let matchType = learnToPlayMatchType {
                GameRulesGuideView(initialMode: matchType)
            }
        }
        .sheet(isPresented: $showsCustomBotSheet) {
            CustomBotCreationSheet { name, metrics in
                startTask?.cancel()
                startTask = Task { await setupViewModel.addCustomBot(name: name, metrics: metrics) }
            }
        }
        .sheet(isPresented: $showsModePicker) {
            ModePickerSheet(selectedEntryId: selectedCatalogEntry?.id) { entry in
                if let selection = entry.pendingModeSelection {
                    setupViewModel.applyPendingModeSelection(selection)
                }
                showsModePicker = false
            }
        }
        .sheet(isPresented: $showsAddPlayerSheet) {
            PlayerEditSheet(
                viewModel: PlayerEditViewModel(
                    existingNames: setupViewModel.availableHumans.map(\.name),
                    editing: nil
                ),
                existing: nil,
                onSave: { player in
                    await setupViewModel.createHumanPlayer(player)
                }
            )
        }
        .onDisappear {
            startTask?.cancel()
        }
    }

    private var learnToPlayMatchType: MatchType? {
        let candidate: MatchType = {
            if let selected = setupViewModel.selectedCatalogMatchType {
                return selected
            }
            if setupViewModel.setupCategory == .party {
                switch setupViewModel.partyGame {
                case .baseball: return .baseball
                case .killer: return .killer
                case .shanghai: return .shanghai
                }
            }
            return setupViewModel.mode.matchType
        }()
        return GameRulesCatalog.hasGuide(for: candidate) ? candidate : nil
    }

    private var compactSetupContent: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
            setupHeader
            selectedModeHeader
            if showsEditOptions {
                modeOptionChips
            }
            setupValidationSection
            rosterControls
            selectedRosterSection
            availablePlayerList
        }
    }

    private var wideSetupContent: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
            setupHeader
            HStack(alignment: .top, spacing: DS.Spacing.s4) {
                VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                    selectedModeHeader
                    if showsEditOptions {
                        modeOptionChips
                    }
                    setupValidationSection
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                    rosterControls
                    selectedRosterSection
                    availablePlayerList
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    @ViewBuilder
    private var setupHeader: some View {
        BrandAppTitle()
            .padding(.top, DS.Spacing.s2)
        if case let .readyWithActiveMatch(match) = homeViewModel.state {
            resumeBanner(match)
        }
    }

    @ViewBuilder
    private var setupValidationSection: some View {
        if GameplayLayout.usesAccessibilitySetupHomeLayout(dynamicTypeSize: dynamicTypeSize),
           !setupViewModel.displayValidationErrors.isEmpty {
            setupInlineValidationHints
        }
    }

    private var learnToPlayButton: some View {
        Button { showsGameRules = true } label: {
            HStack(spacing: 6) {
                Image(systemName: "book.pages")
                Text(L10n.gameRulesLearnButton)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(Brand.green)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.gameRulesLearnButton)
        .accessibilityIdentifier("setup_learnToPlayButton")
    }

    private func resumeBanner(_ match: MatchSummary) -> some View {
        Button { onResumeMatch(match) } label: {
            HStack {
                Image(systemName: "play.circle.fill")
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.resumeMatch).font(.headline)
                    Text(MatchConfigText.modeLabel(for: match.type)).font(.caption).foregroundStyle(Brand.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Brand.textSecondary)
            }
            .foregroundStyle(Brand.textPrimary)
            .padding(DS.Spacing.s4)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.sm).stroke(Brand.green, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            L10n.format(
                "play.home.resumeAccessibilityFormat",
                L10n.string("play.home.resumeButton"),
                MatchConfigText.modeLabel(for: match.type)
            )
        )
        .accessibilityIdentifier("resumeMatchButton")
        .motionBannerEntrance()
    }

    private var selectedCatalogEntry: GameModeCatalogEntry? {
        if let matchType = setupViewModel.selectedCatalogMatchType {
            return GameModeCatalog.entry(for: matchType)
        }
        if setupViewModel.setupCategory == .party {
            switch setupViewModel.partyGame {
            case .baseball: return GameModeCatalog.entry(for: .baseball)
            case .killer: return GameModeCatalog.entry(for: .killer)
            case .shanghai: return GameModeCatalog.entry(for: .shanghai)
            }
        }
        return setupViewModel.mode == .cricket
            ? GameModeCatalog.entry(for: .cricket)
            : GameModeCatalog.entry(for: .x01)
    }

    private var selectedModeHeader: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Text(L10n.string("play.setup.selectedMode"))
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)
                .accessibilityHidden(true)

            HStack(alignment: .top, spacing: DS.Spacing.s3) {
                HStack(alignment: .top, spacing: DS.Spacing.s3) {
                    if let entry = selectedCatalogEntry, let matchType = entry.matchType {
                        GameModeBadge(type: matchType, size: 36)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedCatalogEntry?.localizedName ?? L10n.string("play.x01.title"))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Brand.textPrimary)
                        Text(modeConfigSummary)
                            .font(.subheadline)
                            .foregroundStyle(Brand.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(selectedModeAccessibilityLabel)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("setup_selectedModeName")
                Spacer(minLength: 0)
                Button(action: changeModeTapped) {
                    Text(L10n.string("play.setup.changeMode"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.green)
                        .padding(.horizontal, DS.Spacing.s2)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("setup_changeModeButton")
            }
            .padding(DS.Spacing.s3)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))

            if learnToPlayMatchType != nil {
                learnToPlayButton
            }

            if hasModeOptionChips {
                HStack {
                    Spacer(minLength: 0)
                    Button {
                        showsEditOptions.toggle()
                    } label: {
                        HStack(spacing: 4) {
                            Text(L10n.string(showsEditOptions ? "play.setup.hideOptions" : "play.setup.editOptions"))
                                .font(.subheadline.weight(.semibold))
                            Image(systemName: showsEditOptions ? "chevron.up" : "chevron.down")
                                .font(.caption.weight(.semibold))
                                .accessibilityHidden(true)
                        }
                        .foregroundStyle(Brand.green)
                        .padding(.horizontal, DS.Spacing.s2)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("setup_editOptionsButton")
                }
            }
        }
    }

    private var activeMatchTypeForSetupOptions: MatchType? {
        if let selected = setupViewModel.selectedCatalogMatchType {
            return selected
        }
        if setupViewModel.setupCategory == .party {
            switch setupViewModel.partyGame {
            case .baseball: return .baseball
            case .killer: return .killer
            case .shanghai: return .shanghai
            }
        }
        return setupViewModel.mode.matchType
    }

    private var hasModeOptionChips: Bool {
        guard let matchType = activeMatchTypeForSetupOptions else { return false }
        switch matchType {
        case .mickeyMouse, .mulligan,
             .blindKiller, .followTheLeader, .loop, .prisoner, .scam, .snooker, .ticTacToe, .bobs27, .halveIt:
            return false
        default:
            return true
        }
    }

    @ViewBuilder
    private var modeOptionChips: some View {
        switch activeMatchTypeForSetupOptions {
        case .x01:
            chipsGrid
        case .cricket:
            cricketChipsGrid
        case .americanCricket:
            americanCricketChipsGrid
        case .baseball:
            baseballChipsGrid
        case .killer:
            killerChipsGrid
        case .shanghai:
            shanghaiChipsGrid
        case .englishCricket:
            englishCricketChipsGrid
        case .knockout:
            knockoutChipsGrid
        case .suddenDeath:
            suddenDeathChipsGrid
        case .fiftyOneByFives:
            fiftyOneByFivesChipsGrid
        case .golf:
            golfChipsGrid
        case .football:
            footballChipsGrid
        case .grandNational:
            grandNationalChipsGrid
        case .hareAndHounds:
            hareAndHoundsChipsGrid
        case .aroundTheClock:
            aroundTheClockChipsGrid
        case .aroundTheClock180:
            aroundTheClock180ChipsGrid
        case .chaseTheDragon:
            chaseTheDragonChipsGrid
        case .nineLives:
            nineLivesChipsGrid
        case .mickeyMouse, .mulligan,
             .blindKiller, .followTheLeader, .loop, .prisoner, .scam, .snooker, .ticTacToe, .bobs27, .halveIt, .none:
            EmptyView()
        }
    }

    private var modeConfigSummary: String {
        selectedCatalogEntry?.blurb ?? ""
    }

    private var selectedModeAccessibilityLabel: String {
        let name = selectedCatalogEntry?.localizedName ?? L10n.string("play.x01.title")
        return L10n.format("play.setup.selectedMode.accessibilityFormat", name, modeConfigSummary)
    }

    private func changeModeTapped() {
        if ProductSurface.showsModesTab {
            onChangeMode()
        } else {
            showsModePicker = true
        }
    }

    private var startButton: some View {
        VStack(spacing: 6) {
            PrimaryActionButton(
                title: setupViewModel.isSubmitting ? L10n.setupStartingButton : L10n.setupStartButton,
                isEnabled: setupViewModel.canStart && !setupViewModel.isSubmitting
            ) {
                startTask?.cancel()
                startTask = Task {
                    if let route = await setupViewModel.startMatchRoute() {
                        onStartRoute(route)
                    }
                }
            }
            .accessibilityLabel(L10n.string(setupViewModel.isSubmitting ? "play.setup.startingButton" : "play.setup.startButton"))
            .modifier(OptionalAccessibilityHint(hint: setupStartAccessibilityHint))
            .accessibilityIdentifier("startMatchButton")

            if !GameplayLayout.usesAccessibilitySetupHomeLayout(dynamicTypeSize: dynamicTypeSize) {
                ForEach(setupViewModel.displayValidationErrors, id: \.self) { key in
                    ErrorBanner(messageKey: key)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    private var setupInlineValidationHints: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            ForEach(setupViewModel.displayValidationErrors, id: \.self) { key in
                SetupValidationHint(messageKey: key)
            }
        }
        .accessibilityIdentifier("setupValidationHints")
    }

    private var setupStartAccessibilityHint: String? {
        guard !setupViewModel.canStart else { return nil }
        if setupViewModel.isRosterEmpty {
            return L10n.string("play.setup.playersEmptyHint")
        }
        if setupViewModel.setupCategory == .party,
           setupViewModel.validationErrors.contains("setup.validation.partyComingSoon") {
            return L10n.string("setup.validation.partyComingSoon")
        }
        return SetupValidationMessages.startButtonAccessibilityHint(
            canStart: setupViewModel.canStart,
            validationErrors: setupViewModel.validationErrors
        )
    }

    private var setupStickyShadowColor: Color {
        colorScheme == .light ? .black.opacity(0.08) : .black.opacity(0.25)
    }

    /// Keep roster rows scrollable above the sticky Start footer.
    private var setupScrollBottomPadding: CGFloat {
        if GameplayLayout.usesAccessibilitySetupHomeLayout(dynamicTypeSize: dynamicTypeSize) {
            return 120
        }
        return setupViewModel.setupCategory == .party ? 96 : DS.Spacing.s4
    }
}
