#!/usr/bin/env python3
"""Generate de/es/nl/fr/zh-Hans GameplayModes.strings from en.lproj/GameplayModes.strings."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EN_PATH = ROOT / "Resources/en.lproj/GameplayModes.strings"

# key -> (de, es, nl, fr)
TRANSLATIONS: dict[str, tuple[str, str, str, str]] = {
    "mickeyMouse.targetStrip.bull": ("Bull", "Bull", "Bull", "Bull"),
    "phase.kickoff": ("Anstoß", "Saque inicial", "Aftrap", "Coup d'envoi"),
    "phase.scoring": ("Tore", "Anotación", "Scoren", "Buts"),
    "role.hare": ("Hase", "Liebre", "Haas", "Lièvre"),
    "role.hound": ("Hund", "Perro", "Hond", "Chien"),
    "play.americanCricket.activeTargetHint": (
        "Nur das aktive Ziel zählt Marken",
        "Solo el objetivo activo suma marcas",
        "Alleen het actieve doel telt markeringen",
        "Seule la cible active compte les marques",
    ),
    "play.americanCricket.header.activeTargetFormat": (
        "Ziel %@, %d von %d",
        "Objetivo %@, %d de %d",
        "Doel %@, %d van %d",
        "Cible %@, %d sur %d",
    ),
    "play.americanCricket.navTitle": ("American Cricket", "American Cricket", "American Cricket", "American Cricket"),
    "play.americanCricket.pad.disabledWhileBot": (
        "Warten auf Bot-Wurf",
        "Esperando turno del bot",
        "Wachten op botbeurt",
        "En attente du bot",
    ),
    "play.americanCricket.pointsFormat": ("%d Punkte", "%d puntos", "%d punten", "%d points"),
    "play.americanCricket.segmentAdvanced": ("Ziel weiter", "Objetivo avanzado", "Doel verder", "Cible suivante"),
    "play.americanCricket.setup.points": ("Punkte", "Puntos", "Punten", "Points"),
    "play.americanCricket.setup.pointsOff": ("Punkte aus", "Puntos apagados", "Punten uit", "Points désactivés"),
    "play.americanCricket.setup.pointsOn": ("Punkte an", "Puntos encendidos", "Punten aan", "Points activés"),
    "play.americanCricket.title": ("American Cricket", "American Cricket", "American Cricket", "American Cricket"),
    "play.aroundTheClock.announce.complete": (
        "Sequenz abgeschlossen",
        "Secuencia completa",
        "Reeks voltooid",
        "Séquence terminée",
    ),
    "play.aroundTheClock.bullFinishEnabled": (
        "Mit Bull abschließen",
        "Finalizar en bull",
        "Afronden op bull",
        "Terminer sur le bull",
    ),
    "play.aroundTheClock.currentTargetFormat": ("Ziel %d", "Objetivo %d", "Doel %d", "Cible %d"),
    "play.aroundTheClock.navTitle": ("Around The Clock", "Around The Clock", "Around The Clock", "Around The Clock"),
    "play.aroundTheClock.pad.disabledWhileBot": (
        "Warten auf Bot-Wurf",
        "Esperando turno del bot",
        "Wachten op botbeurt",
        "En attente du bot",
    ),
    "play.aroundTheClock.pad.lockedSegmentHint": (
        "Nur Segment %d bringt dein Ziel weiter",
        "Solo el segmento %d avanza tu objetivo",
        "Alleen segment %d verplaatst je doel",
        "Seul le segment %d fait avancer ta cible",
    ),
    "play.aroundTheClock.progressReset": ("Fortschritt zurückgesetzt", "Progreso reiniciado", "Voortgang gereset", "Progression réinitialisée"),
    "play.aroundTheClock.sequenceProgressFormat": (
        "%@, %d von %d",
        "%@, %d de %d",
        "%@, %d van %d",
        "%@, %d sur %d",
    ),
    "play.aroundTheClock.setup.includeBullFinish": ("Bull-Finish", "Final en bull", "Bull-finish", "Finish sur bull"),
    "play.aroundTheClock.setup.resetPolicy": ("Reset-Regel", "Regla de reinicio", "Resetregel", "Règle de réinitialisation"),
    "play.aroundTheClock.setup.resetPolicy.noReset": ("Kein Reset", "Sin reinicio", "Geen reset", "Pas de réinitialisation"),
    "play.aroundTheClock.setup.resetPolicy.resetEntireSequence": (
        "Ganze Sequenz zurücksetzen",
        "Reiniciar secuencia completa",
        "Hele reeks resetten",
        "Réinitialiser toute la séquence",
    ),
    "play.aroundTheClock.setup.resetPolicy.resetOnThreeMisses": (
        "Reset nach drei Fehlwürfen",
        "Reiniciar tras tres fallos",
        "Reset na drie missers",
        "Réinitialiser après trois ratés",
    ),
    "play.aroundTheClock.targetAdvanced": ("Ziel weiter", "Objetivo avanzado", "Doel verder", "Cible suivante"),
    "play.aroundTheClock.title": ("Around The Clock", "Around The Clock", "Around The Clock", "Around The Clock"),
    "play.aroundTheClock180.leading": ("Führt", "Liderando", "Leidend", "En tête"),
    "play.aroundTheClock180.navTitle": (
        "180 Around The Clock",
        "180 Around The Clock",
        "180 Around The Clock",
        "180 Around The Clock",
    ),
    "play.aroundTheClock180.numberIndexFormat": ("Zahl %d von %d", "Número %d de %d", "Nummer %d van %d", "Numéro %d sur %d"),
    "play.aroundTheClock180.numberStrip.accessibilityFormat": (
        "Zahl %d von %d",
        "Número %d de %d",
        "Nummer %d van %d",
        "Numéro %d sur %d",
    ),
    "play.aroundTheClock180.pad.disabledWhileBot": (
        "Warten auf Bot-Wurf",
        "Esperando turno del bot",
        "Wachten op botbeurt",
        "En attente du bot",
    ),
    "play.aroundTheClock180.pad.lockedSegmentHint": (
        "Nur Segment %d zählt auf dieser Zahl",
        "Solo el segmento %d puntúa en este número",
        "Alleen segment %d telt op dit nummer",
        "Seul le segment %d compte sur ce numéro",
    ),
    "play.aroundTheClock180.runningTotalAccessibilityFormat": (
        "%d Punkte gesamt",
        "%d puntos en total",
        "%d punten totaal",
        "%d points au total",
    ),
    "play.aroundTheClock180.runningTotalFormat": ("%d / %d", "%d / %d", "%d / %d", "%d / %d"),
    "play.aroundTheClock180.setup.parScore": ("Par %d", "Par %d", "Par %d", "Par %d"),
    "play.aroundTheClock180.setup.parScore.none": ("Kein Par", "Sin par", "Geen par", "Pas de par"),
    "play.aroundTheClock180.setup.parScoreValueFormat": ("Par %d", "Par %d", "Par %d", "Par %d"),
    "play.aroundTheClock180.title": (
        "180 Around The Clock",
        "180 Around The Clock",
        "180 Around The Clock",
        "180 Around The Clock",
    ),
    "play.aroundTheClock180.visitPointsFormat": (
        "%d Punkte dieser Wurf, %d gesamt",
        "%d puntos esta visita, %d total",
        "%d punten deze beurt, %d totaal",
        "%d points cette volée, %d au total",
    ),
    "play.blindKiller.title": ("Blind Killer", "Blind Killer", "Blind Killer", "Blind Killer"),
    "play.bobs27.title": ("Bob's 27", "Bob's 27", "Bob's 27", "Bob's 27"),
    "play.chaseTheDragon.dragonComplete": ("Drache vollendet", "Dragón completo", "Draak voltooid", "Dragon terminé"),
    "play.chaseTheDragon.lapFormat": ("Runde %d von %d", "Vuelta %d de %d", "Ronde %d van %d", "Tour %d sur %d"),
    "play.chaseTheDragon.leading": ("Führt", "Liderando", "Leidend", "En tête"),
    "play.chaseTheDragon.navTitle": ("Chase The Dragon", "Chase The Dragon", "Chase The Dragon", "Chase The Dragon"),
    "play.chaseTheDragon.pad.disabledWhileBot": (
        "Warten auf Bot-Wurf",
        "Esperando turno del bot",
        "Wachten op botbeurt",
        "En attente du bot",
    ),
    "play.chaseTheDragon.sequenceProgressFormat": ("Schritt %d von %d", "Paso %d de %d", "Stap %d van %d", "Étape %d sur %d"),
    "play.chaseTheDragon.setup.laps": ("Runden", "Vueltas", "Rondes", "Tours"),
    "play.chaseTheDragon.setup.laps.one": ("Eine Runde", "Una vuelta", "Eén ronde", "Un tour"),
    "play.chaseTheDragon.setup.laps.three": ("Drei Runden", "Tres vueltas", "Drie rondes", "Trois tours"),
    "play.chaseTheDragon.step.innerBull": ("Innerer Bull", "Bull interior", "Inner bull", "Bull intérieur"),
    "play.chaseTheDragon.step.outerBull": ("Äußerer Bull", "Bull exterior", "Outer bull", "Bull extérieur"),
    "play.chaseTheDragon.step.trebleFormat": ("Triple %d", "Triple %d", "Triple %d", "Triple %d"),
    "play.chaseTheDragon.title": ("Chase The Dragon", "Chase The Dragon", "Chase The Dragon", "Chase The Dragon"),
    "play.englishCricket.announce.inningsComplete": (
        "Innings beendet",
        "Entrada completada",
        "Innings voltooid",
        "Innings terminé",
    ),
    "play.englishCricket.header.inningsFormat": ("Innings %d", "Entrada %d", "Innings %d", "Innings %d"),
    "play.englishCricket.navTitle": ("English Cricket", "English Cricket", "English Cricket", "English Cricket"),
    "play.englishCricket.pad.bullOnlyHint": (
        "Werfer wirft nur auf Bull",
        "El lanzador solo apunta al bull",
        "Bowler gooit alleen op bull",
        "Le lanceur vise uniquement le bull",
    ),
    "play.englishCricket.pad.fullBoardHint": (
        "Schlagmann kann auf jedem Segment punkten",
        "El bateador puede puntuar en cualquier segmento",
        "Slagman kan op elk segment scoren",
        "Le batteur peut marquer sur n'importe quel segment",
    ),
    "play.englishCricket.role.batter": ("Schlagmann", "Bateador", "Slagman", "Batteur"),
    "play.englishCricket.role.bowler": ("Werfer", "Lanzador", "Bowler", "Lanceur"),
    "play.englishCricket.runsFormat": ("%d Runs", "%d carreras", "%d runs", "%d runs"),
    "play.englishCricket.setup.endWhenTargetPassed": (
        "Ende wenn Ziel überschritten",
        "Terminar al superar el objetivo",
        "Einde bij overschrijden doel",
        "Terminer une fois l'objectif dépassé",
    ),
    "play.englishCricket.setup.wicketsPerInnings": ("Wickets pro Innings", "Wickets por entrada", "Wickets per innings", "Wickets par innings"),
    "play.englishCricket.setup.wicketsValueFormat": ("%d Wickets", "%d wickets", "%d wickets", "%d wickets"),
    "play.englishCricket.title": ("English Cricket", "English Cricket", "English Cricket", "English Cricket"),
    "play.englishCricket.visitRunsFormat": (
        "%d Runs dieser Wurf",
        "%d carreras esta visita",
        "%d runs deze beurt",
        "%d runs cette volée",
    ),
    "play.englishCricket.wicketsRemainingFormat": (
        "%d Wickets übrig",
        "%d wickets restantes",
        "%d wickets over",
        "%d wickets restants",
    ),
    "play.fiftyOneByFives.divisibleByFiveReminder": (
        "Punkte müssen durch fünf teilbar sein",
        "La puntuación debe ser divisible por cinco",
        "Score moet deelbaar zijn door vijf",
        "Le score doit être divisible par cinq",
    ),
    "play.fiftyOneByFives.leading": ("Führt", "Liderando", "Leidend", "En tête"),
    "play.fiftyOneByFives.navTitle": ("51 By 5's", "51 By 5's", "51 By 5's", "51 By 5's"),
    "play.fiftyOneByFives.noPointsDivisibleHint": (
        "Nur durch fünf teilbare Punkte zählen",
        "Solo cuentan puntuaciones divisibles por cinco",
        "Alleen scores deelbaar door vijf tellen",
        "Seuls les scores divisibles par cinq comptent",
    ),
    "play.fiftyOneByFives.pad.disabledWhileBot": (
        "Warten auf Bot-Wurf",
        "Esperando turno del bot",
        "Wachten op botbeurt",
        "En attente du bot",
    ),
    "play.fiftyOneByFives.pointsAwardedFormat": (
        "%d Punkte erzielt, %d gesamt",
        "%d puntos anotados, %d total",
        "%d punten gescoord, %d totaal",
        "%d points marqués, %d au total",
    ),
    "play.fiftyOneByFives.runningScoreFormat": ("Ziel %d", "Objetivo %d", "Doel %d", "Objectif %d"),
    "play.fiftyOneByFives.setup.mustFinishExact": (
        "Exakt ausspielen",
        "Debe terminar exacto",
        "Moet exact uitspelen",
        "Finir au score exact",
    ),
    "play.fiftyOneByFives.setup.targetPoints": ("Zielpunkte", "Puntos objetivo", "Doelpuntentotal", "Objectif de points"),
    "play.fiftyOneByFives.setup.targetPointsValueFormat": ("%d Punkte", "%d puntos", "%d punten", "%d points"),
    "play.fiftyOneByFives.title": ("51 By 5's", "51 By 5's", "51 By 5's", "51 By 5's"),
    "play.followTheLeader.title": ("Follow the Leader", "Follow the Leader", "Follow the Leader", "Follow the Leader"),
    "play.football.goalScored": (
        "%d Tor erzielt, %d gesamt",
        "%d gol anotado, %d total",
        "%d doelpunt gescoord, %d totaal",
        "%d but marqué, %d au total",
    ),
    "play.football.goalsFormat": ("%d Tore", "%d goles", "%d doelpunten", "%d buts"),
    "play.football.goalsTotalFormat": ("Erstes zu %d", "Primero en %d", "Eerste tot %d", "Premier à %d"),
    "play.football.navTitle": ("Football", "Football", "Football", "Football"),
    "play.football.pad.bullOnlyHint": (
        "Bull treffen zum Anstoß",
        "Acierta el bull para el saque",
        "Raak bull voor aftrap",
        "Touche le bull pour le coup d'envoi",
    ),
    "play.football.pad.disabledWhileBot": (
        "Warten auf Bot-Wurf",
        "Esperando turno del bot",
        "Wachten op botbeurt",
        "En attente du bot",
    ),
    "play.football.pad.doublesHint": ("Doppelte erzielen Tore", "Los dobles marcan goles", "Doubles scoren doelpunten", "Les doubles marquent des buts"),
    "play.football.setup.goalsToWin": ("Tore zum Sieg", "Goles para ganar", "Doelpunten om te winnen", "Buts pour gagner"),
    "play.football.setup.goalsValueFormat": ("%d Tore", "%d goles", "%d doelpunten", "%d buts"),
    "play.football.setup.kickoffMode": ("Anstoß-Modus", "Modo de saque", "Aftrapmodus", "Mode de coup d'envoi"),
    "play.football.setup.kickoffMode.singleBull": ("Einzelner Bull", "Bull simple", "Enkele bull", "Bull simple"),
    "play.football.setup.kickoffMode.twoOuterBulls": (
        "Zwei äußere Bulls",
        "Dos bulls exteriores",
        "Twee outer bulls",
        "Deux bulls extérieurs",
    ),
    "play.football.title": ("Football", "Football", "Football", "Football"),
    "play.golf.announce.holeComplete": (
        "Loch in %d Würfen abgeschlossen",
        "Hoyo completado en %d lanzamientos",
        "Hole voltooid in %d worpen",
        "Trou terminé en %d coups",
    ),
    "play.golf.announce.holeCompleteDetail": (
        "Loch %1$d — %2$@ (%3$d Würfe)",
        "Hoyo %1$d — %2$@ (%3$d lanzamientos)",
        "Hole %1$d — %2$@ (%3$d worpen)",
        "Trou %1$d — %2$@ (%3$d coups)",
    ),
    "play.golf.bot.throwingAtSegment": (
        "Bot wirft auf Segment %d — nur der letzte Dart zählt",
        "Bot lanzando al segmento %d — solo cuenta el último dardo",
        "Bot werpt op segment %d — alleen de laatste dart telt",
        "Bot lance sur le segment %d — seule la dernière fléchette compte",
    ),
    "play.golf.endTurnEarly": ("Wurf früh beenden", "Terminar turno antes", "Beurt vroegtijdig beëindigen", "Terminer le tour plus tôt"),
    "play.golf.header.targetFormat": (
        "Ziel Segment %d",
        "Apunta al segmento %d",
        "Richt op segment %d",
        "Vise le segment %d",
    ),
    "play.golf.header.holeFormat": ("Loch %d von %d", "Hoyo %d de %d", "Hole %d van %d", "Trou %d sur %d"),
    "play.golf.holeStrip.accessibilityFormat": ("Loch %d von %d", "Hoyo %d de %d", "Hole %d van %d", "Trou %d sur %d"),
    "play.golf.lastDartCountsHint": (
        "Letzter Dart zählt auf diesem Loch",
        "El último dardo cuenta en este hoyo",
        "Laatste dart telt op deze hole",
        "La dernière fléchette compte sur ce trou",
    ),
    "play.golf.lastDartPreviewLabel": (
        "Wenn du jetzt stoppst:",
        "Si paras ahora:",
        "Als je nu stopt:",
        "Si tu t'arrêtes maintenant :",
    ),
    "play.golf.lastDartPreviewStrokes": ("%d Würfe", "%d lanzamientos", "%d worpen", "%d coups"),
    "play.golf.leading": ("Führt", "Liderando", "Leidend", "En tête"),
    "play.golf.strokeLegend": (
        "Doppel 1 · Triple 2 · Einfach 3 · Fehlwurf 5",
        "Doble 1 · Triple 2 · Simple 3 · Fallo 5",
        "Double 1 · Triple 2 · Single 3 · Mis 5",
        "Double 1 · Triple 2 · Simple 3 · Raté 5",
    ),
    "play.golf.strokeLegend.accessibility": (
        "Wertung: Doppel = ein Wurf, Triple = zwei, Einfach = drei, Fehlwurf = fünf",
        "Puntuación: doble = un lanzamiento, triple = dos, simple = tres, fallo = cinco",
        "Score: double = één worp, triple = twee, single = drie, mis = vijf",
        "Score : double = un coup, triple = deux, simple = trois, raté = cinq",
    ),
    "play.golf.navTitle": ("Golf", "Golf", "Golf", "Golf"),
    "play.golf.pad.disabledWhileBot": (
        "Warten auf Bot-Wurf",
        "Esperando turno del bot",
        "Wachten op botbeurt",
        "En attente du bot",
    ),
    "play.golf.pad.lockedHoleHint": (
        "Nur Segment %d zählt auf diesem Loch",
        "Solo el segmento %d puntúa en este hoyo",
        "Alleen segment %d telt op deze hole",
        "Seul le segment %d compte sur ce trou",
    ),
    "play.golf.scorecard.holeAccessibilityFormat": (
        "Loch %d, %d Würfe",
        "Hoyo %d, %d lanzamientos",
        "Hole %d, %d worpen",
        "Trou %d, %d coups",
    ),
    "play.golf.scorecard.holeHeader": ("Loch", "Hoyo", "Hole", "Trou"),
    "play.golf.scorecard.playerHeader": ("Spieler", "Jugador", "Speler", "Joueur"),
    "play.golf.scorecard.totalAccessibilityFormat": (
        "%d Würfe gesamt",
        "%d lanzamientos en total",
        "%d worpen totaal",
        "%d coups au total",
    ),
    "play.golf.scorecard.totalFormat": ("%d", "%d", "%d", "%d"),
    "play.golf.scorecard.totalHeader": ("Gesamt", "Total", "Totaal", "Total"),
    "play.golf.setup.courseLength": ("Platzlänge", "Longitud del recorrido", "Baanlengte", "Longueur du parcours"),
    "play.golf.setup.courseLengthValueFormat": ("%d Löcher", "%d hoyos", "%d holes", "%d trous"),
    "play.golf.setup.ruleset.gldLastDart": ("Letzter Dart zählt", "Cuenta el último dardo", "Laatste dart telt", "La dernière fléchette compte"),
    "play.golf.stroke.double": ("Doppel", "Doble", "Double", "Double"),
    "play.golf.stroke.miss": ("Fehlwurf", "Fallo", "Mis", "Raté"),
    "play.golf.stroke.single": ("Einfach", "Simple", "Single", "Simple"),
    "play.golf.stroke.triple": ("Triple", "Triple", "Triple", "Triple"),
    "play.golf.strokeAccessibilityFormat": ("%d Würfe, %@", "%d lanzamientos, %@", "%d worpen, %@", "%d coups, %@"),
    "play.golf.title": ("Golf", "Golf", "Golf", "Golf"),
    "play.grandNational.announce.finished": (
        "Strecke abgeschlossen",
        "Recorrido completado",
        "Parcours voltooid",
        "Parcours terminé",
    ),
    "play.grandNational.coursePositionAccessibilityFormat": (
        "Hürde %d, Runde %d",
        "Valla %d, vuelta %d",
        "Hindernis %d, ronde %d",
        "Haie %d, tour %d",
    ),
    "play.grandNational.fellAtHurdle": ("An der Hürde gefallen", "Caída en la valla", "Gevallen bij hindernis", "Tombé à la haie"),
    "play.grandNational.hurdleCleared": ("Hürde genommen", "Valla superada", "Hindernis genomen", "Haie franchie"),
    "play.grandNational.hurdleFormat": ("Hürde %d", "Valla %d", "Hindernis %d", "Haie %d"),
    "play.grandNational.lapFormat": ("Runde %d von %d", "Vuelta %d de %d", "Ronde %d van %d", "Tour %d sur %d"),
    "play.grandNational.navTitle": ("Grand National", "Grand National", "Grand National", "Grand National"),
    "play.grandNational.pad.disabledWhileBot": (
        "Warten auf Bot-Wurf",
        "Esperando turno del bot",
        "Wachten op botbeurt",
        "En attente du bot",
    ),
    "play.grandNational.pad.lockedSegmentHint": (
        "Nur Segment %d nimmt diese Hürde",
        "Solo el segmento %d supera esta valla",
        "Alleen segment %d neemt dit hindernis",
        "Seul le segment %d franchit cette haie",
    ),
    "play.grandNational.playerEliminated": (
        "Spieler ausgeschieden",
        "Jugador eliminado",
        "Speler geëlimineerd",
        "Joueur éliminé",
    ),
    "play.grandNational.setup.laps": ("Runden", "Vueltas", "Rondes", "Tours"),
    "play.grandNational.setup.lapsValueFormat": ("%d Runden", "%d vueltas", "%d rondes", "%d tours"),
    "play.grandNational.setup.ruleset": ("Regelwerk", "Reglas", "Regelset", "Règles"),
    "play.grandNational.setup.ruleset.expert": ("Experte", "Experto", "Expert", "Expert"),
    "play.grandNational.setup.ruleset.novice": ("Anfänger", "Novato", "Beginner", "Débutant"),
    "play.grandNational.title": ("Grand National", "Grand National", "Grand National", "Grand National"),
    "play.halveIt.title": ("Halve-It", "Halve-It", "Halve-It", "Halve-It"),
    "play.hareAndHounds.dualTrackAccessibilityFormat": ("Segment %d", "Segmento %d", "Segment %d", "Segment %d"),
    "play.hareAndHounds.navTitle": ("Hare And Hounds", "Hare And Hounds", "Hare And Hounds", "Hare And Hounds"),
    "play.hareAndHounds.pad.disabledWhileBot": (
        "Warten auf Bot-Wurf",
        "Esperando turno del bot",
        "Wachten op botbeurt",
        "En attente du bot",
    ),
    "play.hareAndHounds.pad.lockedSegmentHint": (
        "Nur Segment %d bringt deine Position weiter",
        "Solo el segmento %d avanza tu posición",
        "Alleen segment %d verplaatst je positie",
        "Seul le segment %d fait avancer ta position",
    ),
    "play.hareAndHounds.positionAdvanced": (
        "Position weiter",
        "Posición avanzada",
        "Positie verder",
        "Position avancée",
    ),
    "play.hareAndHounds.segmentAdvance": (
        "Weiter zu Segment %d",
        "Avanzado al segmento %d",
        "Verder naar segment %d",
        "Avancé au segment %d",
    ),
    "play.hareAndHounds.setup.houndStart": ("Hundestart", "Inicio del perro", "Hondstart", "Départ du chien"),
    "play.hareAndHounds.setup.houndStart.segment12": ("Segment 12", "Segmento 12", "Segment 12", "Segment 12"),
    "play.hareAndHounds.setup.houndStart.segment5": ("Segment 5", "Segmento 5", "Segment 5", "Segment 5"),
    "play.hareAndHounds.title": ("Hare And Hounds", "Hare And Hounds", "Hare And Hounds", "Hare And Hounds"),
    "play.hareAndHounds.trackPositionFormat": (
        "%@ auf Segment %d",
        "%@ en segmento %d",
        "%@ op segment %d",
        "%@ sur le segment %d",
    ),
    "play.knockout.announce.beatHigh": (
        "%d Punkte — neuer Höchstwert",
        "%d puntos — nueva marca alta",
        "%d punten — nieuwe hoogste score",
        "%d points — nouveau record",
    ),
    "play.knockout.announce.missedHigh": (
        "%d Punkte — unter dem Höchstwert",
        "%d puntos — por debajo de la marca",
        "%d punten — onder de hoogste score",
        "%d points — sous le record",
    ),
    "play.knockout.currentHighFormat": ("Höchstwert: %d", "Marca alta: %d", "Hoogste score: %d", "Record : %d"),
    "play.knockout.currentHighLabel": ("Aktueller Höchstwert", "Marca alta actual", "Huidige hoogste score", "Record actuel"),
    "play.knockout.eliminated": ("Ausgeschieden", "Eliminado", "Geëlimineerd", "Éliminé"),
    "play.knockout.navTitle": ("Knockout", "Knockout", "Knockout", "Knockout"),
    "play.knockout.playerEliminated": (
        "Spieler ausgeschieden",
        "Jugador eliminado",
        "Speler geëlimineerd",
        "Joueur éliminé",
    ),
    "play.knockout.roundFormat": ("Runde %d", "Ronda %d", "Ronde %d", "Manche %d"),
    "play.knockout.setup.strikesToEliminate": (
        "Strikes bis Eliminierung",
        "Strikes para eliminar",
        "Strikes tot eliminatie",
        "Strikes avant élimination",
    ),
    "play.knockout.setup.strikesValueFormat": ("%d Strikes", "%d strikes", "%d strikes", "%d strikes"),
    "play.knockout.strikeAwarded": ("Strike vergeben", "Strike otorgado", "Strike toegekend", "Strike attribué"),
    "play.knockout.strikesCountFormat": ("%d von %d Strikes", "%d de %d strikes", "%d van %d strikes", "%d strikes sur %d"),
    "play.knockout.strikesRemainingFormat": (
        "%d Strikes übrig",
        "%d strikes restantes",
        "%d strikes over",
        "%d strikes restants",
    ),
    "play.knockout.title": ("Knockout", "Knockout", "Knockout", "Knockout"),
    "play.loop.title": ("Loop", "Loop", "Loop", "Loop"),
    "play.mickeyMouse.announce.targetAdvanced": ("Ziel weiter", "Objetivo avanzado", "Doel verder", "Cible suivante"),
    "play.mickeyMouse.header.currentTargetFormat": ("Ziel %@", "Objetivo %@", "Doel %@", "Cible %@"),
    "play.mickeyMouse.markBoard.activeTarget": ("Aktives Ziel", "Objetivo activo", "Actief doel", "Cible active"),
    "play.mickeyMouse.markBoard.targetHeader": ("Ziele", "Objetivos", "Doelen", "Cibles"),
    "play.mickeyMouse.navTitle": ("Mickey Mouse", "Mickey Mouse", "Mickey Mouse", "Mickey Mouse"),
    "play.mickeyMouse.pad.disabledWhileBot": (
        "Warten auf Bot-Wurf",
        "Esperando turno del bot",
        "Wachten op botbeurt",
        "En attente du bot",
    ),
    "play.mickeyMouse.pad.lockedTargetHint": (
        "Nur %@ zählt in diesem Wurf",
        "Solo %@ puntúa este turno",
        "Alleen %@ telt deze beurt",
        "Seul %@ compte ce tour",
    ),
    "play.mickeyMouse.title": ("Mickey Mouse", "Mickey Mouse", "Mickey Mouse", "Mickey Mouse"),
    "play.mulligan.activeTargetFormat": ("Ziel %@", "Objetivo %@", "Doel %@", "Cible %@"),
    "play.mulligan.announce.turnFormat": (
        "%d Marken auf Ziel",
        "%d marcas en el objetivo",
        "%d markeringen op doel",
        "%d marques sur la cible",
    ),
    "play.mulligan.drawnTargets.listAccessibilityFormat": (
        "Gezogene Ziele: %@",
        "Objetivos sorteados: %@",
        "Getrokken doelen: %@",
        "Cibles tirées : %@",
    ),
    "play.mulligan.drawnTargets.title": ("Gezogene Ziele", "Objetivos sorteados", "Getrokken doelen", "Cibles tirées"),
    "play.mulligan.marksAccessibilityFormat": (
        "%d Marken auf aktivem Ziel",
        "%d marcas en el objetivo activo",
        "%d markeringen op actief doel",
        "%d marques sur la cible active",
    ),
    "play.mulligan.navTitle": ("Mulligan", "Mulligan", "Mulligan", "Mulligan"),
    "play.mulligan.pad.disabledWhileBot": (
        "Warten auf Bot-Wurf",
        "Esperando turno del bot",
        "Wachten op botbeurt",
        "En attente du bot",
    ),
    "play.mulligan.pad.lockedTargetHint": (
        "Nur %@ zählt in diesem Wurf",
        "Solo %@ puntúa este turno",
        "Alleen %@ telt deze beurt",
        "Seul %@ compte ce tour",
    ),
    "play.mulligan.targetAdvanced": ("%@ weiter", "%@ avanzado", "%@ verder", "%@ validé"),
    "play.mulligan.title": ("Mulligan", "Mulligan", "Mulligan", "Mulligan"),
    "play.nineLives.advancedToNext": (
        "Weiter zum nächsten Ziel",
        "Avanzado al siguiente objetivo",
        "Verder naar volgend doel",
        "Passé à la cible suivante",
    ),
    "play.nineLives.completed": ("Abgeschlossen", "Completado", "Voltooid", "Terminé"),
    "play.nineLives.lifeLost": ("Leben verloren", "Vida perdida", "Leven verloren", "Vie perdue"),
    "play.nineLives.livesRemainingFormat": (
        "%d Leben übrig",
        "%d vidas restantes",
        "%d levens over",
        "%d vies restantes",
    ),
    "play.nineLives.navTitle": ("Nine Lives", "Nine Lives", "Nine Lives", "Nine Lives"),
    "play.nineLives.pad.disabledWhileBot": (
        "Warten auf Bot-Wurf",
        "Esperando turno del bot",
        "Wachten op botbeurt",
        "En attente du bot",
    ),
    "play.nineLives.pad.lockedSegmentHint": (
        "Nur Segment %d bringt dein Ziel weiter",
        "Solo el segmento %d avanza tu objetivo",
        "Alleen segment %d verplaatst je doel",
        "Seul le segment %d fait avancer ta cible",
    ),
    "play.nineLives.playerEliminated": (
        "Spieler ausgeschieden",
        "Jugador eliminado",
        "Speler geëlimineerd",
        "Joueur éliminé",
    ),
    "play.nineLives.setup.startingLives": ("Start-Leben", "Vidas iniciales", "Startlevens", "Vies de départ"),
    "play.nineLives.setup.startingLives.nine": ("Neun Leben", "Nueve vidas", "Negen levens", "Neuf vies"),
    "play.nineLives.setup.startingLives.three": ("Drei Leben", "Tres vidas", "Drie levens", "Trois vies"),
    "play.nineLives.targetProgressFormat": ("Ziel %d von %d", "Objetivo %d de %d", "Doel %d van %d", "Cible %d sur %d"),
    "play.nineLives.title": ("Nine Lives", "Nine Lives", "Nine Lives", "Nine Lives"),
    "play.prisoner.title": ("Prisoner", "Prisoner", "Prisoner", "Prisoner"),
    "play.scam.title": ("Scam", "Scam", "Scam", "Scam"),
    "play.snooker.title": ("Snooker", "Snooker", "Snooker", "Snooker"),
    "play.suddenDeath.announce.roundResults": (
        "Runde vorbei: %@",
        "Ronda terminada: %@",
        "Ronde voorbij: %@",
        "Manche terminée : %@",
    ),
    "play.suddenDeath.atRiskAccessibilityLabel": (
        "Niedrigste Punktzahl diese Runde",
        "Puntuación más baja esta ronda",
        "Laagste score deze ronde",
        "Score le plus bas cette manche",
    ),
    "play.suddenDeath.eliminatedLabel": ("Ausgeschieden", "Eliminado", "Geëlimineerd", "Éliminé"),
    "play.suddenDeath.eliminatedThisRound": (
        "Diese Runde ausgeschieden",
        "Eliminado esta ronda",
        "Deze ronde geëlimineerd",
        "Éliminé cette manche",
    ),
    "play.suddenDeath.eliminationRule.eliminateAllTied": (
        "Alle Gleichstände eliminieren",
        "Eliminar todos los empatados",
        "Elimineer alle gelijken",
        "Éliminer tous les ex aequo",
    ),
    "play.suddenDeath.eliminationRule.eliminateOne": (
        "Einen eliminieren",
        "Eliminar uno",
        "Elimineer één",
        "Éliminer un seul",
    ),
    "play.suddenDeath.lowestScoreEliminatedFormat": (
        "%@ mit niedrigster Punktzahl ausgeschieden",
        "%@ eliminado con la puntuación más baja",
        "%@ geëlimineerd met de laagste score",
        "%@ éliminé avec le score le plus bas",
    ),
    "play.suddenDeath.navTitle": ("Sudden Death", "Sudden Death", "Sudden Death", "Sudden Death"),
    "play.suddenDeath.playersRemainingFormat": (
        "%d Spieler übrig",
        "%d jugadores restantes",
        "%d spelers over",
        "%d joueurs restants",
    ),
    "play.suddenDeath.roundFormat": ("Runde %d", "Ronda %d", "Ronde %d", "Manche %d"),
    "play.suddenDeath.setup.eliminateAllTied": (
        "Alle Gleichstände eliminieren",
        "Eliminar todos los empatados",
        "Elimineer alle gelijken",
        "Éliminer tous les ex aequo",
    ),
    "play.suddenDeath.setup.visitsPerRound": ("Würfe pro Runde", "Visitas por ronda", "Beurten per ronde", "Volées par manche"),
    "play.suddenDeath.setup.visitsPerRoundValueFormat": (
        "%d Würfe",
        "%d visitas",
        "%d beurten",
        "%d volées",
    ),
    "play.suddenDeath.thisRoundAccessibilityFormat": (
        "%d Punkte diese Runde",
        "%d puntos esta ronda",
        "%d punten deze ronde",
        "%d points cette manche",
    ),
    "play.suddenDeath.thisRoundFormat": ("+%d", "+%d", "+%d", "+%d"),
    "play.suddenDeath.title": ("Sudden Death", "Sudden Death", "Sudden Death", "Sudden Death"),
    "play.suddenDeath.totalPointsAccessibilityFormat": (
        "%d Punkte gesamt",
        "%d puntos en total",
        "%d punten totaal",
        "%d points au total",
    ),
    "play.ticTacToe.title": ("Tic-Tac-Toe", "Tres en raya", "Boter-kaas-en-eieren", "Morpion"),
}

LOCALE_HEADERS = {
    "de": "/* Gameplay mode strings — German */",
    "es": "/* Gameplay mode strings — Spanish */",
    "nl": "/* Gameplay mode strings — Dutch */",
    "fr": "/* Gameplay mode strings — French */",
    "zh-Hans": "/* Gameplay mode strings — Simplified Chinese */",
}


def parse_strings(path: Path) -> list[tuple[str, str]]:
    text = path.read_text(encoding="utf-8")
    return [(m.group(1), m.group(2)) for m in re.finditer(r'"([^"\\]+)"\s*=\s*"([^"]*)"\s*;', text)]


def write_locale_from_json(locale: str) -> None:
    data_path = ROOT / f"Scripts/locale_data/{locale}_gameplay_modes.json"
    if not data_path.exists():
        raise SystemExit(f"Missing translation data: {data_path}")
    translations = json.loads(data_path.read_text(encoding="utf-8"))

    entries = parse_strings(EN_PATH)
    missing = [key for key, _ in entries if key not in translations]
    if missing:
        raise SystemExit(f"Missing translations for {locale}: {missing[:8]}{'…' if len(missing) > 8 else ''}")

    lines = ["", LOCALE_HEADERS[locale], ""]
    for key, _ in entries:
        lines.append(f'"{key}" = "{translations[key]}";')
    lines.append("")

    out = ROOT / f"Resources/{locale}.lproj/GameplayModes.strings"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {out} ({len(entries)} keys)")


def write_locale(locale: str, index: int) -> None:
    entries = parse_strings(EN_PATH)
    missing = [key for key, _ in entries if key not in TRANSLATIONS]
    if missing:
        raise SystemExit(f"Missing translations for {locale}: {missing}")

    lines = ["", LOCALE_HEADERS[locale], ""]
    for key, _ in entries:
        lines.append(f'"{key}" = "{TRANSLATIONS[key][index]}";')
    lines.append("")

    out = ROOT / f"Resources/{locale}.lproj/GameplayModes.strings"
    out.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {out} ({len(entries)} keys)")


def main() -> None:
    entries = parse_strings(EN_PATH)
    for locale in ("de", "es", "nl", "fr", "zh-Hans"):
        write_locale_from_json(locale)
    # Legacy tuple table retained for reference; JSON is source of truth.
    en_keys = {key for key, _ in entries}
    if TRANSLATIONS:
        extra = set(TRANSLATIONS) - en_keys
        missing = en_keys - set(TRANSLATIONS)
        if extra or missing:
            pass  # JSON files are authoritative; tuple drift is non-fatal.


if __name__ == "__main__":
    main()
