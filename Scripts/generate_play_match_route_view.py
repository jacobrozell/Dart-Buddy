#!/usr/bin/env python3
"""Generate consolidated PlayMatchRouteView.swift."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

STANDARD_MODES = [
    ("americanCricket", "AmericanCricket"),
    ("mickeyMouse", "MickeyMouse"),
    ("mulligan", "Mulligan"),
    ("englishCricket", "EnglishCricket"),
    ("knockout", "Knockout"),
    ("suddenDeath", "SuddenDeath"),
    ("fiftyOneByFives", "FiftyOneByFives"),
    ("golf", "Golf"),
    ("football", "Football"),
    ("grandNational", "GrandNational"),
    ("hareAndHounds", "HareAndHounds"),
    ("aroundTheClock", "AroundTheClock"),
    ("aroundTheClock180", "AroundTheClock180"),
    ("chaseTheDragon", "ChaseTheDragon"),
    ("nineLives", "NineLives"),
    ("fleet", "Fleet"),
]

SPECIAL_MODES = [
    ("x01", "X01"),
    ("cricket", "Cricket"),
    ("baseball", "Baseball"),
    ("killer", "Killer"),
    ("shanghai", "Shanghai"),
    ("raid", "Raid"),
]

def standard_route_case(route_key: str, mode_name: str) -> str:
    return f"""        case let .{route_key}Match(matchId):
            MatchRouteScreen(
                matchId: matchId,
                dependencies: dependencies,
                onShowSummary: onShowSummary
            ) {{
                {mode_name}MatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            }} content: {{ viewModel, lifecycle in
                {mode_name}MatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback,
                    lifecycleDependencies: lifecycle
                )
            }}"""

def raid_case() -> str:
    return """        case let .raidMatch(matchId):
            MatchRouteScreen(
                matchId: matchId,
                dependencies: dependencies,
                onShowSummary: onShowSummary
            ) {
                RaidMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository
                )
            } content: { viewModel, lifecycle in
                RaidMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback,
                    lifecycleDependencies: lifecycle
                )
            }"""

def x01_case() -> str:
    return """        case let .x01Match(matchId):
            MatchRouteScreen(
                matchId: matchId,
                dependencies: dependencies,
                onShowSummary: onShowSummary
            ) {
                X01MatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel, lifecycle in
                X01MatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    turnTotalCaller: dependencies.turnTotalCallerService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback,
                    lifecycleDependencies: lifecycle,
                    visionScoringEnabled: dependencies.featureFlags.isEnabled(.enableVisionAutoScoring),
                    visualDartboardInputEnabled: dependencies.featureFlags.isEnabled(.enableVisualDartboardInput),
                    visionLogger: dependencies.logger,
                    defaultDartEntryPresentation: dependencies.userPreferencesStore.defaultDartEntryPresentation
                        .resolved(allowsVisualBoard: dependencies.featureFlags.isEnabled(.enableVisualDartboardInput))
                )
            }"""

def cricket_case() -> str:
    return """        case let .cricketMatch(matchId):
            MatchRouteScreen(
                matchId: matchId,
                dependencies: dependencies,
                onShowSummary: onShowSummary
            ) {
                CricketMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel, lifecycle in
                CricketMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    turnTotalCaller: dependencies.turnTotalCallerService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback,
                    lifecycleDependencies: lifecycle,
                    visualDartboardInputEnabled: dependencies.featureFlags.isEnabled(.enableVisualDartboardInput),
                    defaultDartEntryPresentation: dependencies.userPreferencesStore.defaultDartEntryPresentation
                        .resolved(allowsVisualBoard: dependencies.featureFlags.isEnabled(.enableVisualDartboardInput))
                )
            }"""

def simple_legacy_case(route_key: str, mode_name: str) -> str:
    return standard_route_case(route_key, mode_name)

cases = [x01_case(), cricket_case()]
for rk, mn in [("baseball", "Baseball"), ("killer", "Killer"), ("shanghai", "Shanghai")]:
    cases.append(simple_legacy_case(rk, mn))
for rk, mn in STANDARD_MODES:
    cases.append(standard_route_case(rk, mn))
cases.append(raid_case())

body = "\n".join(cases)

content = f'''import SwiftUI

/// Routes active match screens from `PlayRoute` without per-mode route wrapper structs.
struct PlayMatchRouteView: View {{
    let route: PlayRoute
    let dependencies: AppDependencies
    let onShowSummary: () -> Void

    var body: some View {{
        switch route {{
{body}
        default:
            EmptyView()
        }}
    }}
}}

/// Shared `@StateObject` host for match route screens.
private struct MatchRouteScreen<VM: ObservableObject, Content: View>: View {{
    let dependencies: AppDependencies
    let onShowSummary: () -> Void
    @StateObject private var viewModel: VM
    private let content: (VM, MatchLifecycleChromeDependencies) -> Content

    init(
        matchId: UUID,
        dependencies: AppDependencies,
        onShowSummary: @escaping () -> Void,
        makeViewModel: @escaping () -> VM,
        @ViewBuilder content: @escaping (VM, MatchLifecycleChromeDependencies) -> Content
    ) {{
        self.dependencies = dependencies
        self.onShowSummary = onShowSummary
        _viewModel = StateObject(wrappedValue: makeViewModel())
        self.content = content
    }}

    var body: some View {{
        let lifecycle = MatchLifecycleChromeDependencies(
            store: dependencies.activeMatchStore,
            matchRepository: dependencies.matchRepository,
            logger: dependencies.logger
        )
        content(viewModel, lifecycle)
    }}
}}
'''

out = ROOT / "Features/Play/Setup/PlayMatchRouteView.swift"
out.write_text(content)
print(f"wrote {out} ({len(content)} bytes)")
