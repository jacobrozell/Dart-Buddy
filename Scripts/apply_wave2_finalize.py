#!/usr/bin/env python3
"""Apply final wave-2 locale cleanup fixes and expand neutral keys."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "Scripts" / "locale_data"
NEUTRAL = ROOT / "Scripts/locale_neutral_keys.json"

# Keys that should differ from English in locale JSON.
FINAL = {
    "es.json": {
        "feedback.category.botOpponent.subjectTag": "Bots oponentes",
        "players.bots.roster.accessibilityFormat": "%@, robot %@",
        "players.row.botSuffix": ", robot %@",
    },
    "nl.json": {
        "achievement.db_legs_win_100.description": "Win in totaal 100 legs.",
        "feedback.mostWanted.onlinePlay": "Online multispeler",
    },
    "fr.json": {
        "play.fleet.phase.placement": "Positionnement",
        "play.raid.setup.bossTier.challenger": "Adversaire",
    },
    "it.json": {
        "feedback.category.bug.subjectTag": "Errore",
        "modes.section.coop": "Cooperativo",
        "modes.section.party": "Divertimento",
        "play.setup.category.party": "Divertimento",
        "players.row.botSuffix": ", robot %@",
    },
}

# Documented intentional EN matches (cognates, format shells, jargon).
NEUTRAL_ADD_LOC = [
    "achievements.progressCountFormat",
    "bot.rosterNameFormat",
    "feedback.category.statsActivity.specificItemLabel",
    "history.detail.durationFormat",
    "history.filter.date",
    "history.filter.mode",
    "history.lineScore.inningRunsFormat",
    "history.timeline.baseballTurnFormat",
    "history.timeline.fleetSonarFormat",
    "history.timeline.snookerDartFormat",
    "modes.catalog.party.ticTacToe.name",
    "modes.section.countFormat",
    "play.fleet.setup.callMode.strict",
    "play.raid.bossHPFormat",
    "play.raid.headerFormat",
    "play.raid.mvpFormat",
    "play.setup.chip.mode",
    "play.setup.chip.points",
    "play.setup.mode",
    "play.summary.stat.score",
    "play.x01.checkout.accessibilityFormat",
    "players.edit.color",
    "players.edit.notes",
    "players.edit.notes.accessibility",
    "players.identity.color.coral",
    "players.identity.color.indigo",
    "players.identity.color.lime",
    "scoring.dart.double.accessibility",
    "scoring.mode.total",
    "scoring.multiplier.double.accessibility",
    "scoring.pad.double",
    "scoring.segment.number.accessibility",
    "settings.about.versionFormat",
    "settings.mode.label",
    "stats.chart.axis.sector",
    "stats.points",
    "stats.sector.inningFormat",
    "stats.table.row.accessibilityFormat",
    "bot.namePrefixFormat",
    "history.standing.setsLegsFormat",
    "play.x01.checkout.setupDartFormat",
    "play.x01.legsCountFormat",
    "play.x01.setsCountFormat",
    "play.x01.setsLegsFormat",
]

NEUTRAL_ADD_GM = [
    "play.americanCricket.pointsFormat",
    "play.aroundTheClock180.setup.parScoreValueFormat",
    "play.bobs27.scoreFormat",
    "play.englishCricket.header.inningsFormat",
    "play.englishCricket.runsFormat",
    "play.englishCricket.setup.wicketsValueFormat",
    "play.fiftyOneByFives.setup.targetPointsValueFormat",
    "play.followTheLeader.currentTargetFormat",
    "play.golf.setup.courseLengthValueFormat",
    "play.hareAndHounds.dualTrackAccessibilityFormat",
    "play.knockout.setup.strikesValueFormat",
    "play.loop.currentTargetFormat",
    "play.loop.wireTarget.loopFormat",
    "play.loop.wireTarget.splitFormat",
    "play.prisoner.prisonerOnBoardFormat",
    "play.prisoner.progressSegmentFormat",
    "play.snooker.breakScoreFormat",
    "play.snooker.frameScoreFormat",
    "play.snooker.phase.awaitingColourFormat",
    "play.ticTacToe.target.anySegmentFormat",
    "play.ticTacToe.target.doubleFormat",
    "play.ticTacToe.target.singleFormat",
    "play.ticTacToe.target.tripleFormat",
    "history.timeline.followTheLeaderVisitFormat",
    "history.timeline.loopVisitFormat",
]


def main() -> None:
    for fname, updates in FINAL.items():
        path = DATA / fname
        data = json.loads(path.read_text(encoding="utf-8"))
        data.update(updates)
        path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"Updated {fname} ({len(updates)} keys)")

    neutral = json.loads(NEUTRAL.read_text(encoding="utf-8"))
    loc = set(neutral["localizable"])
    loc |= set(NEUTRAL_ADD_LOC)
    neutral["localizable"] = sorted(loc)

    gm = set(neutral["gameplayModes"])
    gm |= set(NEUTRAL_ADD_GM)
    neutral["gameplayModes"] = sorted(gm)

    cats = neutral.setdefault("regionalJargon", {}).setdefault("categories", {})
    cognates = set(cats.get("internationalCognate", []))
    cognates |= set(NEUTRAL_ADD_LOC)
    cats["internationalCognate"] = sorted(cognates)

    format_shells = set(cats.get("formatShell", []))
    format_shells |= set(NEUTRAL_ADD_GM)
    cats["formatShell"] = sorted(format_shells)

    NEUTRAL.write_text(json.dumps(neutral, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Neutral localizable keys: {len(neutral['localizable'])}")
    print(f"Neutral gameplayModes keys: {len(neutral['gameplayModes'])}")


if __name__ == "__main__":
    main()
