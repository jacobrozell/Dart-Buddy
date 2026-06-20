import SwiftUI

struct SetupHomeScrollContent: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ObservedObject var homeViewModel: PlayHomeViewModel
    @ObservedObject var setupViewModel: MatchSetupViewModel
    @Binding var showsEditOptions: Bool
    @Binding var startTask: Task<Void, Never>?
    let onResumeMatch: (MatchSummary) -> Void
    let onLearnToPlay: () -> Void
    let onChangeMode: () -> Void
    let onShowModePicker: () -> Void
    let onShowCustomBot: () -> Void
    let onShowAddPlayer: () -> Void

    private var usesIPadDashboardLayout: Bool {
        GameplayLayout.usesIPadMainShell()
            && !GameplayLayout.usesAccessibilitySetupHomeLayout(dynamicTypeSize: dynamicTypeSize)
    }

    private var usesWideSetupLayout: Bool {
        !usesIPadDashboardLayout
            && GameplayLayout.usesWideSetupHomeLayout(
                horizontalSizeClass: horizontalSizeClass,
                dynamicTypeSize: dynamicTypeSize
            )
    }

    private var contentWidthCap: CGFloat {
        if usesIPadDashboardLayout { return .infinity }
        return GameplayLayout.contentMaxWidth(horizontalSizeClass: horizontalSizeClass)
    }

    var body: some View {
        Group {
            if usesIPadDashboardLayout {
                iPadDashboardContent
            } else if usesWideSetupLayout {
                wideSetupContent
            } else {
                compactSetupContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DS.Spacing.s4)
        .padding(.bottom, setupScrollBottomPadding)
        .frame(maxWidth: contentWidthCap)
        .frame(maxWidth: .infinity)
    }

    private var setupScrollBottomPadding: CGFloat {
        if GameplayLayout.usesAccessibilitySetupHomeLayout(dynamicTypeSize: dynamicTypeSize) {
            return 120
        }
        return setupViewModel.setupCategory == .party ? 96 : DS.Spacing.s4
    }

    private var iPadDashboardContent: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s5) {
            SetupHomeHeaderSection(homeViewModel: homeViewModel, onResumeMatch: onResumeMatch)
            HStack(alignment: .top, spacing: DS.Spacing.s5) {
                VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                    modeAndOptionsColumn
                    setupValidationSection
                }
                .frame(width: GameplayLayout.iPadSetupModeColumnWidth, alignment: .topLeading)

                rosterColumn
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    private var compactSetupContent: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
            SetupHomeHeaderSection(homeViewModel: homeViewModel, onResumeMatch: onResumeMatch)
            modeAndOptionsColumn
            setupValidationSection
            rosterColumn
        }
    }

    private var wideSetupContent: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
            SetupHomeHeaderSection(homeViewModel: homeViewModel, onResumeMatch: onResumeMatch)
            HStack(alignment: .top, spacing: DS.Spacing.s4) {
                VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                    modeAndOptionsColumn
                    setupValidationSection
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                rosterColumn
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    private var modeAndOptionsColumn: some View {
        Group {
            SetupHomeModeSection(
                setupViewModel: setupViewModel,
                showsEditOptions: $showsEditOptions,
                onLearnToPlay: onLearnToPlay,
                onChangeMode: onChangeMode,
                onShowModePicker: onShowModePicker
            )
            if showsEditOptions {
                SetupHomeModeOptionsSection(setupViewModel: setupViewModel)
            }
        }
    }

    private var rosterColumn: some View {
        SetupHomeRosterSection(
            setupViewModel: setupViewModel,
            startTask: $startTask,
            onShowCustomBot: onShowCustomBot,
            onShowAddPlayer: onShowAddPlayer
        )
    }

    @ViewBuilder
    private var setupValidationSection: some View {
        if GameplayLayout.usesAccessibilitySetupHomeLayout(dynamicTypeSize: dynamicTypeSize),
           !setupViewModel.displayValidationErrors.isEmpty {
            VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                ForEach(setupViewModel.displayValidationErrors, id: \.self) { key in
                    SetupValidationHint(messageKey: key)
                }
            }
            .accessibilityIdentifier("setupValidationHints")
        }
    }
}
