#!/usr/bin/env python3
"""Quality fixes for Italian GameplayModes JSON (copy-paste gaps, tic-tac-toe, mode titles)."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT_JSON = ROOT / "Scripts/locale_data/it_gameplay_modes.json"

IT_QUALITY_FIXES: dict[str, str] = {
    "phase.kickoff": "Calcio d'inizio",
    "play.aroundTheClock.navTitle": "Giro d'orologio",
    "play.aroundTheClock.title": "Giro d'orologio",
    "play.aroundTheClock180.navTitle": "180 Giro d'orologio",
    "play.aroundTheClock180.title": "180 Giro d'orologio",
    "play.chaseTheDragon.navTitle": "Caccia al drago",
    "play.chaseTheDragon.title": "Caccia al drago",
    "play.hareAndHounds.navTitle": "Lepre e levrieri",
    "play.hareAndHounds.title": "Lepre e levrieri",
    "play.blindKiller.navTitle": "Killer cieco",
    "play.blindKiller.title": "Killer cieco",
    "play.followTheLeader.navTitle": "Segui il leader",
    "play.followTheLeader.title": "Segui il leader",
    "play.loop.navTitle": "Anello",
    "play.loop.title": "Anello",
    "play.prisoner.navTitle": "Prigioniero",
    "play.prisoner.title": "Prigioniero",
    "play.nineLives.navTitle": "Nove vite",
    "play.nineLives.title": "Nove vite",
    "play.snooker.breakScoreFormat": "Serie: %d",
    "play.grandNational.setup.ruleset": "Regole",
    "play.knockout.roundFormat": "Turno %d",
    "play.suddenDeath.roundFormat": "Turno %d",
    "play.ticTacToe.target.outerBull": "Bull esterno",
    "play.ticTacToe.cellOpenAccessibilityFormat": "Casella %d, libera, bersaglio %@",
    "play.ticTacToe.cellClaimedAccessibilityFormat": "Casella %d, bersaglio %@, conquistata da %@",
    "ticTacToe.error.sessionMissing": "Sessione partita non trovata.",
    "ticTacToe.error.invalidTurn": "Impossibile registrare quella visita.",
    "play.rules.ticTacToe.overview.body": (
        "Tris su una griglia 3×3 di bersagli. Colpisci una casella per conquistarla. Tre in fila vincono."
    ),
    "play.rules.ticTacToe.grid.body": (
        "Nove caselle: al centro c'è il bull; le altre otto sono segmenti fissi. "
        "La griglia esatta si vede durante il gioco."
    ),
    "play.rules.ticTacToe.turns.body": (
        "Turni alterni da tre freccette. Il primo colpo su una casella libera la conquista per X o O. "
        "Le caselle già prese non contano."
    ),
    "play.rules.ticTacToe.winning.body": (
        "Tre caselle conquistate in fila — orizzontale, verticale o diagonale — vincono. "
        "Griglia piena senza tris: pareggio."
    ),
}


def main() -> None:
    data = json.loads(OUT_JSON.read_text(encoding="utf-8"))
    updated = 0
    for key, value in IT_QUALITY_FIXES.items():
        if data.get(key) != value:
            data[key] = value
            updated += 1
    OUT_JSON.write_text(json.dumps(dict(sorted(data.items())), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Updated {OUT_JSON.name} ({updated} quality fixes)")
    subprocess.run([sys.executable, str(ROOT / "Scripts/generate_gameplay_modes_l10n.py"), "it"], check=True)


if __name__ == "__main__":
    main()
