#!/usr/bin/env python3
"""Apply MatchPlaySessionHost + matchLifecycleChrome to modes missing them."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

MODES = [
    ("AmericanCricket", "americanCricket", True),
    ("MickeyMouse", "mickeyMouse", True),
    ("Mulligan", "mulligan", True),
    ("EnglishCricket", "englishCricket", True),
    ("Knockout", "knockout", True),
    ("SuddenDeath", "suddenDeath", True),
    ("FiftyOneByFives", "fiftyOneByFives", True),
    ("Golf", "golf", True),
    ("Football", "football", True),
    ("GrandNational", "grandNational", True),
    ("HareAndHounds", "hareAndHounds", True),
    ("AroundTheClock", "aroundTheClock", True),
    ("AroundTheClock180", "aroundTheClock180", True),
    ("ChaseTheDragon", "chaseTheDragon", True),
    ("NineLives", "nineLives", True),
    ("Fleet", "fleet", True),
    ("Raid", "raid", False),
]

ALERT_PATTERN = re.compile(
    r'\n        \.alert\("play\.match\.exit\.confirm\.title", isPresented: \$showExitConfirmation\) \{.*?\n        \} message: \{\n            Text\("play\.match\.exit\.confirm\.message"\)\n        \}',
    re.DOTALL,
)

CHROME_REPLACEMENT = """
        .matchLifecycleChrome(
            host: viewModel,
            showExitConfirmation: $showExitConfirmation,
            onShowSummary: onShowSummary,
            onDismiss: { dismiss() },
            dependencies: lifecycleDependencies
        )"""


def loader_block(match_type: str, prefix: str) -> str:
    return f"""    func loadSessionIfNeeded() async {{
        if session != nil {{ return }}
        switch await MatchSessionLoader.load(
            matchId: matchId,
            matchType: .{match_type},
            store: store,
            logger: logger,
            matchRepository: matchRepository,
            statsRepository: statsRepository,
            sessionMissingFallbackKey: "{prefix}.error.sessionMissing"
        ) {{
        case let .loaded(loaded):
            session = loaded
        case .missing:
            break
        case let .failed(messageKey):
            state = .error(messageKey)
        }}
    }}"""


def host_extension(class_name: str, match_type: str, has_bot: bool) -> str:
    blocking = "isBotPlaying || state == .submittingTurn" if has_bot else "state == .submittingTurn"
    return f"""
extension {class_name}: MatchPlaySessionHost {{
    var isBotTurnBlocking: Bool {{ {blocking} }}
    var hostMatchRepository: any MatchRepository {{ matchRepository }}
    var hostMatchStore: ActiveMatchStore {{ store }}
    var hostMatchLogger: any AppLogger {{ logger }}
    var hostMatchType: MatchType {{ .{match_type} }}
}}"""


def update_view_model(path: Path, mode_name: str, match_type: str, has_bot: bool) -> None:
    text = path.read_text()
    if "MatchPlaySessionHost" in text:
        print(f"skip vm (already host): {path}")
        return

    prefix = match_type
    text = re.sub(r"\n    func abandonMatch\(\) async \{.*?\n    \}\n", "\n", text, flags=re.DOTALL)

    replaced, count = re.subn(
        r"\n    (?:private )?func loadSessionIfNeeded\(\) async \{.*?\n    \}\n",
        "\n" + loader_block(match_type, prefix) + "\n",
        text,
        count=1,
        flags=re.DOTALL,
    )
    if count == 0:
        raise RuntimeError(f"loadSessionIfNeeded not found in {path}")
    text = replaced

    if mode_name == "Raid":
        if "statsRepository" not in text:
            text = text.replace(
                "    private let matchRepository: any MatchRepository\n    private let turnSubmitter",
                "    private let matchRepository: any MatchRepository\n    private let statsRepository: any StatsRepository\n    private let turnSubmitter",
            )
            text = text.replace(
                "        matchRepository: any MatchRepository\n    ) {",
                "        matchRepository: any MatchRepository,\n        statsRepository: any StatsRepository\n    ) {",
            )
            text = text.replace(
                "        self.matchRepository = matchRepository\n        self.turnSubmitter",
                "        self.matchRepository = matchRepository\n        self.statsRepository = statsRepository\n        self.turnSubmitter",
            )
        if "recoverBotPlaybackIfNeeded" not in text:
            text = text.replace(
                "    func onDisappear() {}\n",
                "    func onDisappear() {}\n\n    func recoverBotPlaybackIfNeeded() {}\n",
            )

    class_name = f"{mode_name}MatchViewModel"
    text = text.rstrip() + host_extension(class_name, match_type, has_bot) + "\n"
    path.write_text(text)
    print(f"updated vm: {path}")


def update_screen(path: Path) -> None:
    text = path.read_text()
    if "lifecycleDependencies" in text:
        print(f"skip screen (has lifecycle): {path}")
        return

    text = text.replace(
        "    let feedbackPreferences: FeedbackPreferences\n",
        "    let feedbackPreferences: FeedbackPreferences\n    let lifecycleDependencies: MatchLifecycleChromeDependencies\n",
    )
    if "@Environment(\\.dismiss)" not in text:
        text = text.replace(
            "    let lifecycleDependencies: MatchLifecycleChromeDependencies\n",
            "    let lifecycleDependencies: MatchLifecycleChromeDependencies\n    @Environment(\\.dismiss) private var dismiss\n",
        )

    new_text, count = ALERT_PATTERN.subn(CHROME_REPLACEMENT, text)
    if count == 0:
        raise RuntimeError(f"exit alert not found in {path}")
    path.write_text(new_text)
    print(f"updated screen: {path}")


def main() -> None:
    for mode_name, match_type, has_bot in MODES:
        vm_path = ROOT / f"Features/Play/{mode_name}/{mode_name}MatchViewModel.swift"
        screen_path = ROOT / f"Features/Play/{mode_name}/{mode_name}MatchScreen.swift"
        update_view_model(vm_path, mode_name, match_type, has_bot)
        update_screen(screen_path)


if __name__ == "__main__":
    main()
