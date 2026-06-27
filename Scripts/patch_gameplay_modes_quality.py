#!/usr/bin/env python3
"""Cross-locale GameplayModes quality fixes (copy-paste gaps, untranslated UI)."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "Scripts/locale_data"
LOCALES = ("de", "es", "nl", "fr", "zh-Hans", "it")

QUALITY_FIXES: dict[str, dict[str, str]] = {
    "de": {
        "play.snooker.ball.colour": "Farbe",
        "play.snooker.ball.red": "Rot",
        "play.snooker.breakEnded": "Serie beendet",
        "play.snooker.breakScoreFormat": "Serie: %d",
        "play.snooker.colour.black": "Schwarz",
        "play.snooker.colour.blue": "Blau",
        "play.snooker.colour.brown": "Braun",
        "play.snooker.colour.green": "Grün",
        "play.snooker.colour.pink": "Rosa",
        "play.snooker.colour.yellow": "Gelb",
        "play.snooker.highestBreakFormat": "Beste Serie: %d",
        "play.snooker.nominateColour": "Farbe nominieren",
        "play.snooker.pad.disabledWhileBot": "Warten auf Bot-Wurf",
        "play.snooker.phase.awaitingColourFormat": "Loche %@",
        "play.snooker.phase.awaitingNomination": "Farbe nominieren",
        "play.snooker.phase.awaitingRed": "Rot lochen",
        "play.snooker.redAvailableAccessibilityFormat": "Rot %d verfügbar",
        "play.snooker.redPocketed": "Rot gelocht",
        "play.snooker.redPocketedAccessibilityFormat": "Rot %d gelocht",
        "play.snooker.redsRemainingFormat": "%d Roten auf dem Tisch",
        "play.scam.navTitle": "Betrug",
        "play.scam.title": "Betrug",
        "play.ticTacToe.target.outerBull": "Äußerer Bull",
        "play.golf.stroke.single": "Einfach",
    },
    "es": {
        "play.blindKiller.navTitle": "Killer ciego",
        "play.blindKiller.title": "Killer ciego",
        "play.knockout.navTitle": "Eliminación",
        "play.knockout.title": "Eliminación",
        "play.nineLives.navTitle": "Nueve vidas",
        "play.nineLives.title": "Nueve vidas",
        "play.scam.navTitle": "Estafa",
        "play.scam.title": "Estafa",
        "play.suddenDeath.navTitle": "Muerte súbita",
        "play.suddenDeath.title": "Muerte súbita",
        "play.snooker.breakScoreFormat": "Serie: %d",
        "play.ticTacToe.navTitle": "Tres en raya",
        "play.ticTacToe.title": "Tres en raya",
        "play.ticTacToe.target.outerBull": "Bull exterior",
    },
    "nl": {
        "play.blindKiller.navTitle": "Blinde killer",
        "play.blindKiller.title": "Blinde killer",
        "play.chaseTheDragon.step.innerBull": "Binnen bull",
        "play.chaseTheDragon.step.outerBull": "Buiten bull",
        "play.followTheLeader.targetArea.single": "Single",
        "play.followTheLeader.targetArea.outerBull": "Buiten bull",
        "play.followTheLeader.targetArea.innerBull": "Binnen bull",
        "play.golf.stroke.single": "Single",
        "play.knockout.navTitle": "Knock-out",
        "play.knockout.title": "Knock-out",
        "play.nineLives.navTitle": "Negen levens",
        "play.nineLives.title": "Negen levens",
        "play.prisoner.ringPicker.playableFormat": "Buiten-single, dubbel of triple op %d",
        "play.scam.navTitle": "Scam",
        "play.scam.title": "Scam",
        "play.suddenDeath.navTitle": "Sudden death",
        "play.suddenDeath.title": "Sudden death",
        "play.ticTacToe.target.outerBull": "Buiten bull",
    },
    "fr": {
        "play.blindKiller.navTitle": "Killer aveugle",
        "play.ticTacToe.target.outerBull": "Bull extérieur",
    },
    "zh-Hans": {
        "play.ticTacToe.target.outerBull": "外牛眼",
    },
    "it": {
        "play.knockout.navTitle": "Eliminazione",
        "play.knockout.title": "Eliminazione",
        "play.scam.navTitle": "Truffa",
        "play.scam.title": "Truffa",
        "play.suddenDeath.navTitle": "Morte improvvisa",
        "play.suddenDeath.title": "Morte improvvisa",
        "play.ticTacToe.navTitle": "Tris",
        "play.ticTacToe.title": "Tris",
    },
}

LOCALIZABLE_FIXES: dict[str, dict[str, str]] = {
    "de": {
        "error.match.followTheLeader.openingRequiresScoringDart": "Der Eröffnungswurf muss die Scheibe treffen.",
        "error.match.loop.openingRequiresScoringDart": "Der Eröffnungswurf muss die Scheibe treffen.",
        "modes.catalog.party.scam.name": "Betrug",
    },
    "es": {
        "error.match.blindKiller.assignmentsMissing": "No se pudieron asignar los números secretos de Killer ciego.",
        "error.match.mode.blindKillerUnavailable": "El estado de Killer ciego no está disponible para esta partida.",
        "error.match.mode.followTheLeaderUnavailable": "El estado de Sigue al líder no está disponible para esta partida.",
        "error.match.mode.loopUnavailable": "El estado de Bucle no está disponible para esta partida.",
        "error.match.mode.prisonerUnavailable": "El estado de Prisionero no está disponible para esta partida.",
        "modes.catalog.party.blindKiller.name": "Killer ciego",
        "modes.catalog.party.followTheLeader.name": "Sigue al líder",
        "modes.catalog.party.loop.name": "Bucle",
        "modes.catalog.party.prisoner.name": "Prisionero",
        "modes.catalog.party.ticTacToe.name": "Tres en raya",
        "setup.validation.blindKillerMinimumPlayers": "Killer ciego necesita al menos tres jugadores.",
        "setup.validation.followTheLeaderMinimumPlayers": "Sigue al líder necesita al menos dos jugadores.",
        "setup.validation.loopMinimumPlayers": "Bucle necesita al menos dos jugadores.",
        "setup.validation.prisonerMinimumPlayers": "Prisionero necesita al menos dos jugadores.",
        "setup.validation.ticTacToeExactTwoPlayers": "Tres en raya requiere exactamente dos jugadores.",
        "modes.catalog.party.scam.name": "Estafa",
    },
    "nl": {
        "error.match.blindKiller.assignmentsMissing": "Geheime nummers voor Blinde killer konden niet worden toegewezen.",
        "error.match.mode.blindKillerUnavailable": "Blinde-killer-status is niet beschikbaar voor deze wedstrijd.",
        "error.match.mode.followTheLeaderUnavailable": "Volg-de-leider-status is niet beschikbaar voor deze wedstrijd.",
        "error.match.mode.loopUnavailable": "Loop-status is niet beschikbaar voor deze wedstrijd.",
        "error.match.mode.prisonerUnavailable": "Gevangene-status is niet beschikbaar voor deze wedstrijd.",
        "modes.catalog.party.blindKiller.name": "Blinde killer",
        "modes.catalog.party.followTheLeader.name": "Volg de leider",
        "modes.catalog.party.prisoner.name": "Gevangene",
        "setup.validation.blindKillerMinimumPlayers": "Blinde killer heeft minstens drie spelers nodig.",
        "setup.validation.followTheLeaderMinimumPlayers": "Volg de leider heeft minstens twee spelers nodig.",
        "setup.validation.loopMinimumPlayers": "Loop heeft minstens twee spelers nodig.",
        "setup.validation.prisonerMinimumPlayers": "Gevangene heeft minstens twee spelers nodig.",
    },
    "it": {
        "modes.catalog.party.ticTacToe.name": "Tris",
    },
}


def patch_gameplay() -> None:
    touched: list[str] = []
    for locale, fixes in QUALITY_FIXES.items():
        path = DATA_DIR / f"{locale}_gameplay_modes.json"
        data = json.loads(path.read_text(encoding="utf-8"))
        updated = 0
        for key, value in fixes.items():
            if data.get(key) != value:
                data[key] = value
                updated += 1
        if updated:
            path.write_text(json.dumps(dict(sorted(data.items())), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            print(f"Updated {path.name} (+{updated} fixes)")
            touched.append(locale)
    if touched:
        subprocess.run(
            [sys.executable, str(ROOT / "Scripts/generate_gameplay_modes_l10n.py"), *sorted(set(touched))],
            check=True,
        )


def patch_localizable() -> None:
    for locale, fixes in LOCALIZABLE_FIXES.items():
        path = DATA_DIR / f"{locale}.json"
        data = json.loads(path.read_text(encoding="utf-8"))
        for key, value in fixes.items():
            data[key] = value
        path.write_text(json.dumps(dict(sorted(data.items())), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"Updated {path.name} (+{len(fixes)} Localizable fixes)")
    if LOCALIZABLE_FIXES:
        subprocess.run([sys.executable, str(ROOT / "Scripts/generate_localizable.py"), "all"], check=True)


def main() -> None:
    patch_gameplay()
    patch_localizable()


if __name__ == "__main__":
    main()
