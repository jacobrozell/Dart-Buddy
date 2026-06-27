#!/usr/bin/env python3
"""Bootstrap Scripts/locale_data/it_gameplay_modes.json and regenerate it.lproj/GameplayModes.strings."""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EN_PATH = ROOT / "Resources/en.lproj/GameplayModes.strings"
IT_STRINGS = ROOT / "Resources/it.lproj/GameplayModes.strings"
OUT_JSON = ROOT / "Scripts/locale_data/it_gameplay_modes.json"

# Keys missing from Italian GameplayModes (party-mode backfill + rules).
IT_GAPS: dict[str, str] = {
    "blindKiller.error.invalidTurn": "Impossibile registrare quella visita.",
    "blindKiller.error.sessionMissing": "Sessione partita non trovata.",
    "followTheLeader.error.invalidVisit": "Impossibile registrare quella visita.",
    "followTheLeader.error.sessionMissing": "Sessione partita non trovata.",
    "history.timeline.blindKillerTurnFormat": "%@ ha lanciato — %d doppi",
    "history.timeline.followTheLeaderMatched": "Colpito",
    "history.timeline.followTheLeaderMissed": "Mancato",
    "history.timeline.followTheLeaderPassFormat": "%@ ha passato",
    "history.timeline.followTheLeaderVisitFormat": "%@ — %@",
    "history.timeline.loopPassFormat": "%@ ha passato",
    "history.timeline.loopVisitFormat": "%@ — %@",
    "history.timeline.prisonerVisitFormat": "%@ — %d freccette",
    "loop.error.invalidVisit": "Impossibile registrare quella visita.",
    "loop.error.sessionMissing": "Sessione partita non trovata.",
    "play.blindKiller.anonymousTallyAccessibilityFormat": "Segmento %d, %d su %d doppi",
    "play.blindKiller.doubleHitRecorded": "Doppio registrato",
    "play.blindKiller.eliminationRecorded": "Giocatore eliminato",
    "play.blindKiller.navTitle": "Killer cieco",
    "play.blindKiller.pad.disabledWhileBot": "In attesa del turno del bot",
    "play.blindKiller.pad.hint": "I doppi sui segmenti da 1 a 20 contano",
    "play.blindKiller.playerEliminated": "Eliminato",
    "play.blindKiller.throwFormat": "%@ lancia",
    "play.blindKiller.yourSecretNumberFormat": "Il tuo numero segreto: %d",
    "play.followTheLeader.announce.targetMatched": "Obiettivo colpito",
    "play.followTheLeader.currentTargetFormat": "%1$d %2$@",
    "play.followTheLeader.currentTargetTitle": "Obiettivo attuale",
    "play.followTheLeader.lifeLost": "Vita persa",
    "play.followTheLeader.livesRemainingFormat": "%d vite rimaste",
    "play.followTheLeader.navTitle": "Segui il leader",
    "play.followTheLeader.nonDominantPickReminder": "L'ultima freccetta che segna fissa il prossimo obiettivo",
    "play.followTheLeader.openingTargetTitle": "Imposta l'obiettivo",
    "play.followTheLeader.openingThrowFormat": "%@ imposta l'obiettivo iniziale",
    "play.followTheLeader.pad.disabledWhileBot": "In attesa del turno del bot",
    "play.followTheLeader.pad.hint": "Colpisci l'obiettivo in tre freccette o perdi una vita",
    "play.followTheLeader.pad.passOrThrowHint": "Tutti hanno mancato — passa il turno o lancia di nuovo",
    "play.followTheLeader.passTurn": "Passa turno",
    "play.followTheLeader.passTurnFormat": "%@ — passa o lancia",
    "play.followTheLeader.playerEliminated": "Eliminato",
    "play.followTheLeader.targetArea.double": "Doppio",
    "play.followTheLeader.targetArea.innerBull": "Bull interno",
    "play.followTheLeader.targetArea.outerBull": "Bull esterno",
    "play.followTheLeader.targetArea.single": "Singolo",
    "play.followTheLeader.targetArea.triple": "Triplo",
    "play.followTheLeader.throwFormat": "%@ lancia",
    "play.loop.announce.targetMatched": "Filo colpito",
    "play.loop.currentTargetFormat": "%1$d %2$@",
    "play.loop.currentTargetTitle": "Filo attuale",
    "play.loop.currentWireTargetAccessibilityFormat": "Obiettivo attuale: %@",
    "play.loop.lifeLost": "Vita persa",
    "play.loop.livesRemainingFormat": "%d vite rimaste",
    "play.loop.navTitle": "Anello",
    "play.loop.nonDominantPickReminder": "Scegli l'area filo esatta colpita",
    "play.loop.openingTargetTitle": "Imposta il filo",
    "play.loop.openingThrowFormat": "%@ imposta il filo iniziale",
    "play.loop.pad.disabledWhileBot": "In attesa del turno del bot",
    "play.loop.pad.hint": "Colpisci il filo in tre freccette o perdi una vita",
    "play.loop.pad.passOrThrowHint": "Tutti hanno mancato — passa il turno o lancia di nuovo",
    "play.loop.passTurn": "Passa turno",
    "play.loop.passTurnFormat": "%@ — passa o lancia",
    "play.loop.playerEliminated": "Eliminato",
    "play.loop.throwFormat": "%@ lancia",
    "play.loop.wireTarget.loopFormat": "%1$d %2$@",
    "play.loop.wireTarget.lowerLoop": "Loop inferiore",
    "play.loop.wireTarget.split": "Split",
    "play.loop.wireTarget.splitFormat": "Split %d",
    "play.loop.wireTarget.standard": "Standard",
    "play.loop.wireTarget.upperLoop": "Loop superiore",
    "play.loop.wireTargetPicker.accessibility": "Scegli filo obiettivo",
    "play.loop.wireTargetPicker.title": "Quale filo hai colpito?",
    "play.prisoner.boardOverlayAccessibilityFormat": "Prigionieri sul bersaglio: %@",
    "play.prisoner.bullSegmentLabel": "Bull",
    "play.prisoner.completed": "Completato",
    "play.prisoner.currentTargetTitle": "Obiettivo attuale",
    "play.prisoner.dartLostOneTurn": "Freccetta bloccata fuori dai doppi",
    "play.prisoner.dartPoolFormat": "%d freccette",
    "play.prisoner.navTitle": "Prigioniero",
    "play.prisoner.noPrisoners": "Nessun prigioniero sul bersaglio",
    "play.prisoner.pad.disabledWhileBot": "In attesa del turno del bot",
    "play.prisoner.pad.hint": "Colpisci l'obiettivo nell'anello giocabile o gestisci i prigionieri",
    "play.prisoner.playableRingHint": "Tripli, singoli esterni e doppi contano per l'obiettivo",
    "play.prisoner.prisonerCaptured": "Prigioniero catturato",
    "play.prisoner.prisonerOnBoard": "Freccetta imprigionata",
    "play.prisoner.prisonerOnBoardFormat": "%1$@ — %2$@",
    "play.prisoner.prisonersOnBoardTitle": "Prigionieri sul bersaglio",
    "play.prisoner.progressSegmentFormat": "Segmento %d",
    "play.prisoner.ringPicker.accessibility": "Scegli anello di punteggio",
    "play.prisoner.ringPicker.innerSingleFormat": "Singolo interno su %d",
    "play.prisoner.ringPicker.playableFormat": "Singolo esterno, doppio o triplo su %d",
    "play.prisoner.ringPicker.title": "Quale anello hai colpito?",
    "play.prisoner.stuckDartsFormat": "%d bloccate sul bersaglio",
    "play.prisoner.targetProgressFormat": "%1$d di %2$d",
    "play.prisoner.throwFormat": "%@ lancia",
    "play.rules.blindKiller.elimination.body": "Quando un segmento raggiunge tre doppi, il giocatore con quel numero segreto viene eliminato immediatamente.",
    "play.rules.blindKiller.elimination.title": "Eliminazione",
    "play.rules.blindKiller.overview.body": "A ognuno viene assegnato un numero segreto da 1 a 20. Lancia sui doppi — ogni doppio conta su quel segmento. A tre doppi su un segmento, chi ha quel numero esce. Vince l'ultimo rimasto.",
    "play.rules.blindKiller.overview.title": "Panoramica",
    "play.rules.blindKiller.secret.body": "Solo tu vedi il tuo numero sul dispositivo. Gli avversari vedono i segmenti colpiti, non chi possiede quale numero.",
    "play.rules.blindKiller.secret.title": "Il tuo numero segreto",
    "play.rules.blindKiller.throwing.body": "A ogni turno lanci tre freccette. Ogni doppio aggiunge un colpo su quel segmento. Singoli e tripli non contano.",
    "play.rules.blindKiller.throwing.title": "Lanciare",
    "play.rules.followTheLeader.match.body": "Al tuo turno, eguaglia segmento e anello esatti in massimo tre freccette. Singoli, doppi, tripli e bull sono obiettivi distinti.",
    "play.rules.followTheLeader.match.title": "Eguagliare",
    "play.rules.followTheLeader.overview.body": "I giocatori si alternano per eguagliare un obiettivo condiviso. Se sbagli in tre freccette perdi una vita. Vince l'ultimo con vite rimaste.",
    "play.rules.followTheLeader.overview.title": "Panoramica",
    "play.rules.followTheLeader.pass.body": "Se tutti i giocatori attivi mancano l'obiettivo, chi l'ha impostato può passare il turno o lanciare di nuovo.",
    "play.rules.followTheLeader.pass.title": "Passare o rilanciare",
    "play.rules.followTheLeader.target.body": "Il primo giocatore lancia una freccetta per l'obiettivo iniziale. Se colpisci con freccette rimanenti, l'ultima che segna può fissare un nuovo obiettivo.",
    "play.rules.followTheLeader.target.title": "Impostare l'obiettivo",
    "play.rules.loop.overview.body": "Loop è Follow the Leader sul cablaggio del bersaglio. Eguaglia il filo del leader — loop, split e anelli — o perdi una vita. Vince l'ultimo con vite rimaste.",
    "play.rules.loop.overview.title": "Panoramica",
    "play.rules.loop.play.body": "La prima freccetta fissa l'obiettivo. Gli altri devono colpire quell'area filo esatta in massimo tre freccette o perdono una vita. Colpire presto con freccette rimanenti può fissare un nuovo obiettivo.",
    "play.rules.loop.play.title": "Gioco",
    "play.rules.loop.targets.body": "Un obiettivo può essere una fetta normale, un loop filo su numeri come 6 o 20, o uno split tra le cifre dell'11. Loop alto e basso sullo stesso numero sono obiettivi diversi.",
    "play.rules.loop.targets.title": "Obiettivi validi",
    "play.rules.loop.wires.body": "Se una freccetta può significare più aree filo, l'app chiede conferma. Una freccetta nel loop del 6 non è lo stesso del singolo grande del 6.",
    "play.rules.loop.wires.title": "Loop e split",
    "play.rules.prisoner.capture.body": "Colpisci il campo interno e la freccetta diventa prigioniera. Chi colpisce poi l'area giocabile di quel numero la cattura e la aggiunge al proprio pool.",
    "play.rules.prisoner.capture.title": "Prigionieri",
    "play.rules.prisoner.lost.body": "Mancando fuori dai doppi o rimbalzando, la freccetta resta sul bersaglio per una visita — lanci meno freccette alla visita successiva, poi la recuperi.",
    "play.rules.prisoner.lost.title": "Freccette perse",
    "play.rules.prisoner.overview.body": "Gara in senso orario da 1 a 20 nell'anello esterno. Vince chi finisce per primo — le freccette mancate possono diventare prigionieri che gli altri catturano.",
    "play.rules.prisoner.overview.title": "Panoramica",
    "play.rules.prisoner.progress.body": "Dopo l'1 vengono 18, 4, 13 e così via in senso orario. Solo i colpi nell'anello giocabile (tripli fino ai doppi) fanno avanzare l'obiettivo.",
    "play.rules.prisoner.progress.title": "Progresso",
    "prisoner.error.invalidVisit": "Impossibile registrare quella visita.",
    "prisoner.error.sessionMissing": "Sessione partita non trovata.",
}


def parse_strings(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    return dict(re.findall(r'"([^"\\]+)"\s*=\s*"([^"]*)"\s*;', text))


def main() -> None:
    en = parse_strings(EN_PATH)
    it_existing = parse_strings(IT_STRINGS)

    data = dict(sorted(it_existing.items()))
    added = 0
    for key, value in IT_GAPS.items():
        if key not in en:
            raise SystemExit(f"Unknown English key: {key}")
        if key not in data:
            data[key] = value
            added += 1
        elif data[key] != value and data[key] == en.get(key):
            data[key] = value
            added += 1

    missing = sorted(set(en) - set(data))
    if missing:
        raise SystemExit(f"Still missing {len(missing)} keys after bootstrap: {missing[:8]}…")

    OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUT_JSON.name} ({len(data)} keys, +{added} gaps filled)")

    subprocess.run([sys.executable, str(ROOT / "Scripts/generate_gameplay_modes_l10n.py"), "it"], check=True)


if __name__ == "__main__":
    main()
