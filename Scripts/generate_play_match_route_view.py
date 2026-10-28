#!/usr/bin/env python3
"""Generate PlayMatchRouteView.swift, per-mode route views, and MatchRouteScreen.swift.

Outputs:
  Features/Play/Setup/PlayMatchRouteView.swift        thin dispatcher
  Features/Play/Setup/Routes/{Mode}MatchRouteView.swift  one per mode
  Features/Play/Shared/MatchRouteScreen.swift         shared @StateObject host

Re-run after adding a mode; stale route files for removed modes are deleted.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ROUTES_DIR = ROOT / "Features/Play/Setup/Routes"

FEEDBACK = "feedbackPreferences: dependencies.userPreferencesStore.feedback"
AUDIO = "audio: dependencies.audioFeedbackService"
HAPTICS = "haptics: dependencies.hapticsService"
LIFECYCLE = "lifecycleDependencies: lifecycle"
VISUAL_BOARD_ENABLED = (
    "visualDartboardInputEnabled: dependencies.featureFlags.isEnabled(.enableVisualDartboardInput)"
)
DEFAULT_ENTRY = (
    "defaultDartEntryPresentation: dependencies.userPreferencesStore.defaultDartEntryPresentation\n"
    "    .resolved(allowsVisualBoard: dependencies.featureFlags.isEnabled(.enableVisualDartboardInput))"
)

STANDARD_SCREEN_ARGS = [AUDIO, HAPTICS, FEEDBACK, LIFECYCLE]

# (route key, type prefix) — standard VM + screen with lifecycle chrome.
STANDARD_MODES = [
    ("baseball", "Baseball"),
    ("killer", "Killer"),
    ("shanghai", "Shanghai"),
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

# 1.2 modes whose screens do not take lifecycle chrome.
NO_LIFECYCLE_MODES = [
    ("halveIt", "HalveIt"),
    ("scam", "Scam"),
    ("snooker", "Snooker"),
    ("ticTacToe", "TicTacToe"),
    ("blindKiller", "BlindKiller"),
    ("followTheLeader", "FollowTheLeader"),
    ("loop", "Loop"),
    ("prisoner", "Prisoner"),
]


def mode(route_key, prefix, screen_args, vm_feedback=True):
    return {
        "route_key": route_key,
        "prefix": prefix,
        "screen_args": screen_args,
        "vm_feedback": vm_feedback,
    }


MODES = [
    mode("x01", "X01", [
        AUDIO,
        HAPTICS,
        "turnTotalCaller: dependencies.turnTotalCallerService",
        FEEDBACK,
        LIFECYCLE,
        "visionScoringEnabled: dependencies.featureFlags.isEnabled(.enableVisionAutoScoring)",
        VISUAL_BOARD_ENABLED,
        "visionLogger: dependencies.logger",
        DEFAULT_ENTRY,
    ]),
    mode("cricket", "Cricket", [
        AUDIO,
        HAPTICS,
        "turnTotalCaller: dependencies.turnTotalCallerService",
        FEEDBACK,
        LIFECYCLE,
        VISUAL_BOARD_ENABLED,
        DEFAULT_ENTRY,
    ]),
]
MODES += [mode(rk, prefix, STANDARD_SCREEN_ARGS) for rk, prefix in STANDARD_MODES]
MODES.append(mode("raid", "Raid", STANDARD_SCREEN_ARGS, vm_feedback=False))
MODES.append(mode("bobs27", "Bobs27", [AUDIO, HAPTICS]))
MODES += [mode(rk, prefix, [AUDIO, HAPTICS, FEEDBACK]) for rk, prefix in NO_LIFECYCLE_MODES]


def indent(text, spaces):
    pad = " " * spaces
    return "\n".join(pad + line for line in text.split("\n"))


def arg_lines(args, spaces):
    return ",\n".join(indent(arg, spaces) for arg in args)


def route_view(m):
    prefix = m["prefix"]
    vm_args = [
        "matchId: matchId",
        "store: dependencies.activeMatchStore",
        "logger: dependencies.logger",
        "matchRepository: dependencies.matchRepository",
        "statsRepository: dependencies.statsRepository",
    ]
    if m["vm_feedback"]:
        vm_args.append(FEEDBACK)
    screen_args = ["viewModel: viewModel", "onShowSummary: onShowSummary"] + m["screen_args"]
    lifecycle_param = "lifecycle" if LIFECYCLE in m["screen_args"] else "_"
    return f"""import SwiftUI

struct {prefix}MatchRouteView: View {{
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void

    var body: some View {{
        MatchRouteScreen(
            matchId: matchId,
            dependencies: dependencies,
            onShowSummary: onShowSummary
        ) {{
            {prefix}MatchViewModel(
{arg_lines(vm_args, 16)}
            )
        }} content: {{ viewModel, {lifecycle_param} in
            {prefix}MatchScreen(
{arg_lines(screen_args, 16)}
            )
        }}
    }}
}}
"""


def dispatcher():
    cases = "\n".join(
        f"""        case let .{m["route_key"]}Match(matchId):
            {m["prefix"]}MatchRouteView(matchId: matchId, dependencies: dependencies, onShowSummary: onShowSummary)"""
        for m in MODES
    )
    return f"""import SwiftUI

/// Routes active match screens from `PlayRoute`. Generated by `Scripts/generate_play_match_route_view.py`.
struct PlayMatchRouteView: View {{
    let route: PlayRoute
    let dependencies: AppDependencies
    let onShowSummary: () -> Void

    var body: some View {{
        if let matchType = route.inProgressRulesMatchType {{
            MatchInProgressRulesAccess(matchType: matchType) {{
                routeBody
            }}
        }} else {{
            routeBody
        }}
    }}

    @ViewBuilder
    private var routeBody: some View {{
        switch route {{
{cases}
        default:
            EmptyView()
        }}
    }}
}}
"""


MATCH_ROUTE_SCREEN = """import SwiftUI

/// Shared `@StateObject` host for match route screens.
struct MatchRouteScreen<VM: ObservableObject, Content: View>: View {
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
    ) {
        self.dependencies = dependencies
        self.onShowSummary = onShowSummary
        _viewModel = StateObject(wrappedValue: makeViewModel())
        self.content = content
    }

    var body: some View {
        let lifecycle = MatchLifecycleChromeDependencies(
            store: dependencies.activeMatchStore,
            matchRepository: dependencies.matchRepository,
            logger: dependencies.logger
        )
        content(viewModel, lifecycle)
    }
}
"""


def write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)
    print(f"wrote {path.relative_to(ROOT)}")


def main():
    write(ROOT / "Features/Play/Setup/PlayMatchRouteView.swift", dispatcher())
    write(ROOT / "Features/Play/Shared/MatchRouteScreen.swift", MATCH_ROUTE_SCREEN)
    expected = set()
    for m in MODES:
        path = ROUTES_DIR / f"{m['prefix']}MatchRouteView.swift"
        expected.add(path)
        write(path, route_view(m))
    for stale in ROUTES_DIR.glob("*MatchRouteView.swift"):
        if stale not in expected:
            stale.unlink()
            print(f"removed {stale.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
