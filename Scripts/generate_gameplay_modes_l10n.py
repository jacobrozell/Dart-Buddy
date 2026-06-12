#!/usr/bin/env python3
"""Generate de/es/nl GameplayModes.strings from en.lproj/GameplayModes.strings."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EN_PATH = ROOT / "Resources/en.lproj/GameplayModes.strings"

# key -> (de, es, nl)
TRANSLATIONS: dict[str, tuple[str, str, str]] = {
    "mickeyMouse.targetStrip.bull": ("Bull", "Bull", "Bull"),
    "phase.kickoff": ("Anstoß", "Saque inicial", "Aftrap"),
    "phase.scoring": ("Tore", "Anotación", "Scoren"),
    "role.hare": ("Hase", "Liebre", "Haas"),
    "role.hound": ("Hund", "Perro", "Hond"),
    "play.americanCricket.activeTargetHint": (
        "Nur das aktive Ziel zählt Marken",
        "Solo el objetivo activo suma marcas",
        "Alleen het actieve doel telt markeringen",
    ),
    "play.americanCricket.header.activeTargetFormat": (
        "Ziel %@, %d von %d",
        "Objetivo %@, %d de %d",
        "Doel %@, %d van %d",
    ),
    "play.americanCricket.navTitle": ("American Cricket", "American Cricket", "American Cricket"),
    "play.americanCricket.pad.disabledWhileBot": (
        "Warten auf Bot-Wurf",
        "Esperando turno del bot",
        "Wachten op botbeurt",
    ),
    "play.americanCricket.pointsFormat": ("%d Punkte", "%d puntos", "%d punten"),
    "play.americanCricket.segmentAdvanced": ("Ziel weiter", "Objetivo avanzado", "Doel verder"),
    "play.americanCricket.setup.points": ("Punkte", "Puntos", "Punten"),
    "play.americanCricket.setup.pointsOff": ("Punkte aus", "Puntos apagados", "Punten uit"),
    "play.americanCricket.setup.pointsOn": ("Punkte an", "Puntos encendidos", "Punten aan"),
    "play.americanCricket.title": ("American Cricket", "American Cricket", "American Cricket"),
    "play.aroundTheClock.announce.complete": (
        "Sequenz abgeschlossen",
        "Secuencia completa",
        "Reeks voltooid",
    ),
    "play.aroundTheClock.bullFinishEnabled": (
        "Mit Bull abschließen",
        "Finalizar en bull",
        "Afronden op bull",
    ),
    "play.aroundTheClock.currentTargetFormat": ("Ziel %d", "Objetivo %d", "Doel %d"),
    "play.aroundTheClock.navTitle": ("Around The Clock", "Around The Clock", "Around The Clock"),
    "play.aroundTheClock.pad.disabledWhileBot": (
        "Warten auf Bot-Wurf",
        "Esperando turno del bot",
        "Wachten op botbeurt",
    ),
    "play.aroundTheClock.pad.lockedSegmentHint": (
        "Nur Segment %d bringt dein Ziel weiter",
        "Solo el segmento %d avanza tu objetivo",
        "Alleen segment %d verplaatst je doel",
    ),
    "play.aroundTheClock.progressReset": ("Fortschritt zurückgesetzt", "Progreso reiniciado", "Voortgang gereset"),
    "play.aroundTheClock.sequenceProgressFormat": (
        "%@, %d von %d",
        "%@, %d de %d",
        "%@, %d van %d",
    ),
    "play.aroundTheClock.setup.includeBullFinish": ("Bull-Finish", "Final en bull", "Bull-finish"),
    "play.aroundTheClock.setup.resetPolicy": ("Reset-Regel", "Regla de reinicio", "Resetregel"),
    "play.aroundTheClock.setup.resetPolicy.noReset": ("Kein Reset", "Sin reinicio", "Geen reset"),
    "play.aroundTheClock.setup.resetPolicy.resetEntireSequence": (
        "Ganze Sequenz zurücksetzen",
        "Reiniciar secuencia completa",
        "Hele reeks resetten",
    ),
    "play.aroundTheClock.setup.resetPolicy.resetOnThreeMisses": (
        "Reset nach drei Fehlwürfen",
        "Reiniciar tras tres fallos",
        "Reset na drie missers",
    ),
    "play.aroundTheClock.targetAdvanced": ("Ziel weiter", "Objetivo avanzado", "Doel verder"),
    "play.aroundTheClock.title": ("Around The Clock", "Around The Clock", "Around The Clock"),
    "play.aroundTheClock180.leading": ("Führt", "Liderando", "Leidend"),
    "play.aroundTheClock180.navTitle": (
        "180 Around The Clock",
        "180 Around The Clock",
        "180 Around The Clock",
    ),
    "play.aroundTheClock180.numberIndexFormat": ("Zahl %d von %d", "Número %d de %d", "Nummer %d van %d"),
    "play.aroundTheClock180.numberStrip.accessibilityFormat": (
        "Zahl %d von %d",
        "Número %d de %d",
        "Nummer %d van %d",
    ),
    "play.aroundTheClock180.pad.disabledWhileBot": (
        "Warten auf Bot-Wurf",
        "Esperando turno del bot",
        "Wachten op botbeurt",
    ),
    "play.aroundTheClock180.pad.lockedSegmentHint": (
        "Nur Segment %d zählt auf dieser Zahl",
        "Solo el segmento %d puntúa en este número",
        "Alleen segment %d telt op dit nummer",
    ),
    "play.aroundTheClock180.runningTotalAccessibilityFormat": (
        "%d Punkte gesamt",
        "%d puntos en total",
        "%d punten totaal",
    ),
    "play.aroundTheClock180.runningTotalFormat": ("%d / %d", "%d / %d", "%d / %d"),
    "play.aroundTheClock180.setup.parScore": ("Par %d", "Par %d", "Par %d"),
    "play.aroundTheClock180.setup.parScore.none": ("Kein Par", "Sin par", "Geen par"),
    "play.aroundTheClock180.setup.parScoreValueFormat": ("Par %d", "Par %d", "Par %d"),
    "play.aroundTheClock180.title": (
        "180 Around The Clock",
        "180 Around The Clock",
        "180 Around The Clock",
    ),
    "play.aroundTheClock180.visitPointsFormat": (
        "%d Punkte dieser Wurf, %d gesamt",
        "%d puntos esta visita, %d total",
        "%d punten deze beurt, %d totaal",
    ),
    "play.blindKiller.title": ("Blind Killer", "Blind Killer", "Blind Killer"),
    "play.bobs27.title": ("Bob's 27", "Bob's 27", "Bob's 27"),
    "play.chaseTheDragon.dragonComplete": ("Drache vollendet", "Dragón completo", "Draak voltooid"),
    "play.chaseTheDragon.lapFormat": ("Runde %d von %d", "Vuelta %d de %d", "Ronde %d van %d"),
    "play.chaseTheDragon.leading": ("Führt", "Liderando", "Leidend"),
    "play.chaseTheDragon.navTitle": ("Chase The Dragon", "Chase The Dragon", "Chase The Dragon"),
    "play.chaseTheDragon.pad.disabledWhileBot": (
        "Warten auf Bot-Wurf",
        "Esperando turno del bot",
        "Wachten op botbeurt",
    ),
    "play.chaseTheDragon.sequenceProgressFormat": ("Schritt %d von %d", "Paso %d de %d", "Stap %d van %d"),
    "play.chaseTheDragon.setup.laps": ("Runden", "Vueltas", "Rondes"),
    "play.chaseTheDragon.setup.laps.one": ("Eine Runde", "Una vuelta", "Eén ronde"),
    "play.chaseTheDragon.setup.laps.three": ("Drei Runden", "Tres vueltas", "Drie rondes"),
    "play.chaseTheDragon.step.innerBull": ("Innerer Bull", "Bull interior", "Inner bull"),
    "play.chaseTheDragon.step.outerBull": ("Äußerer Bull", "Bull exterior", "Outer bull"),
    "play.chaseTheDragon.step.trebleFormat": ("Triple %d", "Triple %d", "Triple %d"),
    "play.chaseTheDragon.title": ("Chase The Dragon", "Chase The Dragon", "Chase The Dragon"),
    "play.englishCricket.announce.inningsComplete": (
        "Innings beendet",
        "Entrada completada",
        "Innings voltooid",
    ),
    "play.englishCricket.header.inningsFormat": ("Innings %d", "Entrada %d", "Innings %d"),
    "play.englishCricket.navTitle": ("English Cricket", "English Cricket", "English Cricket"),
    "play.englishCricket.pad.bullOnlyHint": (
        "Werfer wirft nur auf Bull",
        "El lanzador solo apunta al bull",
        "Bowler gooit alleen op bull",
    ),
    "play.englishCricket.pad.fullBoardHint": (
        "Schlagmann kann auf jedem Segment punkten",
        "El bateador puede puntuar en cualquier segmento",
        "Slagman kan op elk segment scoren",
    ),
    "play.englishCricket.role.batter": ("Schlagmann", "Bateador", "Slagman"),
    "play.englishCricket.role.bowler": ("Werfer", "Lanzador", "Bowler"),
    "play.englishCricket.runsFormat": ("%d Runs", "%d carreras", "%d runs"),
    "play.englishCricket.setup.endWhenTargetPassed": (
        "Ende wenn Ziel überschritten",
        "Terminar al superar el objetivo",
        "Einde bij overschrijden doel",
    ),
    "play.englishCricket.setup.wicketsPerInnings": ("Wickets pro Innings", "Wickets por entrada", "Wickets per innings"),
    "play.englishCricket.setup.wicketsValueFormat": ("%d Wickets", "%d wickets", "%d wickets"),
    "play.englishCricket.title": ("English Cricket", "English Cricket", "English Cricket"),
    "play.englishCricket.visitRunsFormat": (
        "%d Runs dieser Wurf",
        "%d carreras esta visita",
        "%d runs deze beurt",
    ),
    "play.englishCricket.wicketsRemainingFormat": (
        "%d Wickets übrig",
        "%d wickets restantes",
        "%d wickets over",
    ),
    "play.fiftyOneByFives.divisibleByFiveReminder": (
        "Punkte müssen durch fünf teilbar sein",
        "La puntuación debe ser divisible por cinco",
        "Score moet deelbaar zijn door vijf",
    ),
    "play.fiftyOneByFives.leading": ("Führt", "Liderando", "Leidend"),
    "play.fiftyOneByFives.navTitle": ("51 By 5's", "51 By 5's", "51 By 5's"),
    "play.fiftyOneByFives.noPointsDivisibleHint": (
        "Nur durch fünf teilbare Punkte zählen",
        "Solo cuentan puntuaciones divisibles por cinco",
        "Alleen scores deelbaar door vijf tellen",
    ),
    "play.fiftyOneByFives.pad.disabledWhileBot": (
        "Warten auf Bot-Wurf",
        "Esperando turno del bot",
        "Wachten op botbeurt",
    ),
    "play.fiftyOneByFives.pointsAwardedFormat": (
        "%d Punkte erzielt, %d gesamt",
        "%d puntos anotados, %d total",
        "%d punten gescoord, %d totaal",
    ),
    "play.fiftyOneByFives.runningScoreFormat": ("Ziel %d", "Objetivo %d", "Doel %d"),
    "play.fiftyOneByFives.setup.mustFinishExact": (
        "Exakt ausspielen",
        "Debe terminar exacto",
        "Moet exact uitspelen",
    ),
    "play.fiftyOneByFives.setup.targetPoints": ("Zielpunkte", "Puntos objetivo", "Doelpuntentotal"),
    "play.fiftyOneByFives.setup.targetPointsValueFormat": ("%d Punkte", "%d puntos", "%d punten"),
    "play.fiftyOneByFives.title": ("51 By 5's", "51 By 5's", "51 By 5's"),
    "play.followTheLeader.title": ("Follow the Leader", "Follow the Leader", "Follow the Leader"),
    "play.football.goalScored": (
        "%d Tor erzielt, %d gesamt",
        "%d gol anotado, %d total",
        "%d doelpunt gescoord, %d totaal",
    ),
    "play.football.goalsFormat": ("%d Tore", "%d goles", "%d doelpunten"),
    "play.football.goalsTotalFormat": ("Erstes zu %d", "Primero en %d", "Eerste tot %d"),
    "play.football.navTitle": ("Football", "Football", "Football"),
    "play.football.pad.bullOnlyHint": (
        "Bull treffen zum Anstoß",
        "Acierta el bull para el saque",
        "Raak bull voor aftrap",
    ),
    "play.football.pad.disabledWhileBot": (
        "Warten auf Bot-Wurf",
        "Esperando turno del bot",
        "Wachten op botbeurt",
    ),
    "play.football.pad.doublesHint": ("Doppelte erzielen Tore", "Los dobles marcan goles", "Doubles scoren doelpunten"),
    "play.football.setup.goalsToWin": ("Tore zum Sieg", "Goles para ganar", "Doelpunten om te winnen"),
    "play.football.setup.goalsValueFormat": ("%d Tore", "%d goles", "%d doelpunten"),
    "play.football.setup.kickoffMode": ("Anstoß-Modus", "Modo de saque", "Aftrapmodus"),
    "play.football.setup.kickoffMode.singleBull": ("Einzelner Bull", "Bull simple", "Enkele bull"),
    "play.football.setup.kickoffMode.twoOuterBulls": (
        "Zwei äußere Bulls",
        "Dos bulls exteriores",
        "Twee outer bulls",
    ),
    "play.football.title": ("Football", "Football", "Football"),
    "play.golf.announce.holeComplete": (
        "Loch in %d Würfen abgeschlossen",
        "Hoyo completado en %d lanzamientos",
        "Hole voltooid in %d worpen",
    ),
    "play.golf.endTurnEarly": ("Wurf früh beenden", "Terminar turno antes", "Beurt vroegtijdig beëindigen"),
    "play.golf.header.holeFormat": ("Loch %d von %d", "Hoyo %d de %d", "Hole %d van %d"),
    "play.golf.holeStrip.accessibilityFormat": ("Loch %d von %d", "Hoyo %d de %d", "Hole %d van %d"),
    "play.golf.lastDartCountsHint": (
        "Letzter Dart zählt auf diesem Loch",
        "El último dardo cuenta en este hoyo",
        "Laatste dart telt op deze hole",
    ),
    "play.golf.leading": ("Führt", "Liderando", "Leidend"),
    "play.golf.navTitle": ("Golf", "Golf", "Golf"),
    "play.golf.pad.disabledWhileBot": (
        "Warten auf Bot-Wurf",
        "Esperando turno del bot",
        "Wachten op botbeurt",
    ),
    "play.golf.pad.lockedHoleHint": (
        "Nur Segment %d zählt auf diesem Loch",
        "Solo el segmento %d puntúa en este hoyo",
        "Alleen segment %d telt op deze hole",
    ),
    "play.golf.scorecard.holeAccessibilityFormat": (
        "Loch %d, %d Würfe",
        "Hoyo %d, %d lanzamientos",
        "Hole %d, %d worpen",
    ),
    "play.golf.scorecard.holeHeader": ("Loch", "Hoyo", "Hole"),
    "play.golf.scorecard.playerHeader": ("Spieler", "Jugador", "Speler"),
    "play.golf.scorecard.totalAccessibilityFormat": (
        "%d Würfe gesamt",
        "%d lanzamientos en total",
        "%d worpen totaal",
    ),
    "play.golf.scorecard.totalFormat": ("%d", "%d", "%d"),
    "play.golf.scorecard.totalHeader": ("Gesamt", "Total", "Totaal"),
    "play.golf.setup.courseLength": ("Platzlänge", "Longitud del recorrido", "Baanlengte"),
    "play.golf.setup.courseLengthValueFormat": ("%d Löcher", "%d hoyos", "%d holes"),
    "play.golf.setup.ruleset.gldLastDart": ("Letzter Dart zählt", "Cuenta el último dardo", "Laatste dart telt"),
    "play.golf.stroke.double": ("Doppel", "Doble", "Double"),
    "play.golf.stroke.miss": ("Fehlwurf", "Fallo", "Mis"),
    "play.golf.stroke.single": ("Einfach", "Simple", "Single"),
    "play.golf.stroke.triple": ("Triple", "Triple", "Triple"),
    "play.golf.strokeAccessibilityFormat": ("%d Würfe, %@", "%d lanzamientos, %@", "%d worpen, %@"),
    "play.golf.title": ("Golf", "Golf", "Golf"),
    "play.grandNational.announce.finished": (
        "Strecke abgeschlossen",
        "Recorrido completado",
        "Parcours voltooid",
    ),
    "play.grandNational.coursePositionAccessibilityFormat": (
        "Hürde %d, Runde %d",
        "Valla %d, vuelta %d",
        "Hindernis %d, ronde %d",
    ),
    "play.grandNational.fellAtHurdle": ("An der Hürde gefallen", "Caída en la valla", "Gevallen bij hindernis"),
    "play.grandNational.hurdleCleared": ("Hürde genommen", "Valla superada", "Hindernis genomen"),
    "play.grandNational.hurdleFormat": ("Hürde %d", "Valla %d", "Hindernis %d"),
    "play.grandNational.lapFormat": ("Runde %d von %d", "Vuelta %d de %d", "Ronde %d van %d"),
    "play.grandNational.navTitle": ("Grand National", "Grand National", "Grand National"),
    "play.grandNational.pad.disabledWhileBot": (
        "Warten auf Bot-Wurf",
        "Esperando turno del bot",
        "Wachten op botbeurt",
    ),
    "play.grandNational.pad.lockedSegmentHint": (
        "Nur Segment %d nimmt diese Hürde",
        "Solo el segmento %d supera esta valla",
        "Alleen segment %d neemt dit hindernis",
    ),
    "play.grandNational.playerEliminated": (
        "Spieler ausgeschieden",
        "Jugador eliminado",
        "Speler geëlimineerd",
    ),
    "play.grandNational.setup.laps": ("Runden", "Vueltas", "Rondes"),
    "play.grandNational.setup.lapsValueFormat": ("%d Runden", "%d vueltas", "%d rondes"),
    "play.grandNational.setup.ruleset": ("Regelwerk", "Reglas", "Regelset"),
    "play.grandNational.setup.ruleset.expert": ("Experte", "Experto", "Expert"),
    "play.grandNational.setup.ruleset.novice": ("Anfänger", "Novato", "Beginner"),
    "play.grandNational.title": ("Grand National", "Grand National", "Grand National"),
    "play.halveIt.title": ("Halve-It", "Halve-It", "Halve-It"),
    "play.hareAndHounds.dualTrackAccessibilityFormat": ("Segment %d", "Segmento %d", "Segment %d"),
    "play.hareAndHounds.navTitle": ("Hare And Hounds", "Hare And Hounds", "Hare And Hounds"),
    "play.hareAndHounds.pad.disabledWhileBot": (
        "Warten auf Bot-Wurf",
        "Esperando turno del bot",
        "Wachten op botbeurt",
    ),
    "play.hareAndHounds.pad.lockedSegmentHint": (
        "Nur Segment %d bringt deine Position weiter",
        "Solo el segmento %d avanza tu posición",
        "Alleen segment %d verplaatst je positie",
    ),
    "play.hareAndHounds.positionAdvanced": (
        "Position weiter",
        "Posición avanzada",
        "Positie verder",
    ),
    "play.hareAndHounds.segmentAdvance": (
        "Weiter zu Segment %d",
        "Avanzado al segmento %d",
        "Verder naar segment %d",
    ),
    "play.hareAndHounds.setup.houndStart": ("Hundestart", "Inicio del perro", "Hondstart"),
    "play.hareAndHounds.setup.houndStart.segment12": ("Segment 12", "Segmento 12", "Segment 12"),
    "play.hareAndHounds.setup.houndStart.segment5": ("Segment 5", "Segmento 5", "Segment 5"),
    "play.hareAndHounds.title": ("Hare And Hounds", "Hare And Hounds", "Hare And Hounds"),
    "play.hareAndHounds.trackPositionFormat": (
        "%@ auf Segment %d",
        "%@ en segmento %d",
        "%@ op segment %d",
    ),
    "play.knockout.announce.beatHigh": (
        "%d Punkte — neuer Höchstwert",
        "%d puntos — nueva marca alta",
        "%d punten — nieuwe hoogste score",
    ),
    "play.knockout.announce.missedHigh": (
        "%d Punkte — unter dem Höchstwert",
        "%d puntos — por debajo de la marca",
        "%d punten — onder de hoogste score",
    ),
    "play.knockout.currentHighFormat": ("Höchstwert: %d", "Marca alta: %d", "Hoogste score: %d"),
    "play.knockout.currentHighLabel": ("Aktueller Höchstwert", "Marca alta actual", "Huidige hoogste score"),
    "play.knockout.eliminated": ("Ausgeschieden", "Eliminado", "Geëlimineerd"),
    "play.knockout.navTitle": ("Knockout", "Knockout", "Knockout"),
    "play.knockout.playerEliminated": (
        "Spieler ausgeschieden",
        "Jugador eliminado",
        "Speler geëlimineerd",
    ),
    "play.knockout.roundFormat": ("Runde %d", "Ronda %d", "Ronde %d"),
    "play.knockout.setup.strikesToEliminate": (
        "Strikes bis Eliminierung",
        "Strikes para eliminar",
        "Strikes tot eliminatie",
    ),
    "play.knockout.setup.strikesValueFormat": ("%d Strikes", "%d strikes", "%d strikes"),
    "play.knockout.strikeAwarded": ("Strike vergeben", "Strike otorgado", "Strike toegekend"),
    "play.knockout.strikesCountFormat": ("%d von %d Strikes", "%d de %d strikes", "%d van %d strikes"),
    "play.knockout.strikesRemainingFormat": (
        "%d Strikes übrig",
        "%d strikes restantes",
        "%d strikes over",
    ),
    "play.knockout.title": ("Knockout", "Knockout", "Knockout"),
    "play.loop.title": ("Loop", "Loop", "Loop"),
    "play.mickeyMouse.announce.targetAdvanced": ("Ziel weiter", "Objetivo avanzado", "Doel verder"),
    "play.mickeyMouse.header.currentTargetFormat": ("Ziel %@", "Objetivo %@", "Doel %@"),
    "play.mickeyMouse.markBoard.activeTarget": ("Aktives Ziel", "Objetivo activo", "Actief doel"),
    "play.mickeyMouse.markBoard.targetHeader": ("Ziele", "Objetivos", "Doelen"),
    "play.mickeyMouse.navTitle": ("Mickey Mouse", "Mickey Mouse", "Mickey Mouse"),
    "play.mickeyMouse.pad.disabledWhileBot": (
        "Warten auf Bot-Wurf",
        "Esperando turno del bot",
        "Wachten op botbeurt",
    ),
    "play.mickeyMouse.pad.lockedTargetHint": (
        "Nur %@ zählt in diesem Wurf",
        "Solo %@ puntúa este turno",
        "Alleen %@ telt deze beurt",
    ),
    "play.mickeyMouse.title": ("Mickey Mouse", "Mickey Mouse", "Mickey Mouse"),
    "play.mulligan.activeTargetFormat": ("Ziel %@", "Objetivo %@", "Doel %@"),
    "play.mulligan.announce.turnFormat": (
        "%d Marken auf Ziel",
        "%d marcas en el objetivo",
        "%d markeringen op doel",
    ),
    "play.mulligan.drawnTargets.listAccessibilityFormat": (
        "Gezogene Ziele: %@",
        "Objetivos sorteados: %@",
        "Getrokken doelen: %@",
    ),
    "play.mulligan.drawnTargets.title": ("Gezogene Ziele", "Objetivos sorteados", "Getrokken doelen"),
    "play.mulligan.marksAccessibilityFormat": (
        "%d Marken auf aktivem Ziel",
        "%d marcas en el objetivo activo",
        "%d markeringen op actief doel",
    ),
    "play.mulligan.navTitle": ("Mulligan", "Mulligan", "Mulligan"),
    "play.mulligan.pad.disabledWhileBot": (
        "Warten auf Bot-Wurf",
        "Esperando turno del bot",
        "Wachten op botbeurt",
    ),
    "play.mulligan.pad.lockedTargetHint": (
        "Nur %@ zählt in diesem Wurf",
        "Solo %@ puntúa este turno",
        "Alleen %@ telt deze beurt",
    ),
    "play.mulligan.targetAdvanced": ("%@ weiter", "%@ avanzado", "%@ verder"),
    "play.mulligan.title": ("Mulligan", "Mulligan", "Mulligan"),
    "play.nineLives.advancedToNext": (
        "Weiter zum nächsten Ziel",
        "Avanzado al siguiente objetivo",
        "Verder naar volgend doel",
    ),
    "play.nineLives.completed": ("Abgeschlossen", "Completado", "Voltooid"),
    "play.nineLives.lifeLost": ("Leben verloren", "Vida perdida", "Leven verloren"),
    "play.nineLives.livesRemainingFormat": (
        "%d Leben übrig",
        "%d vidas restantes",
        "%d levens over",
    ),
    "play.nineLives.navTitle": ("Nine Lives", "Nine Lives", "Nine Lives"),
    "play.nineLives.pad.disabledWhileBot": (
        "Warten auf Bot-Wurf",
        "Esperando turno del bot",
        "Wachten op botbeurt",
    ),
    "play.nineLives.pad.lockedSegmentHint": (
        "Nur Segment %d bringt dein Ziel weiter",
        "Solo el segmento %d avanza tu objetivo",
        "Alleen segment %d verplaatst je doel",
    ),
    "play.nineLives.playerEliminated": (
        "Spieler ausgeschieden",
        "Jugador eliminado",
        "Speler geëlimineerd",
    ),
    "play.nineLives.setup.startingLives": ("Start-Leben", "Vidas iniciales", "Startlevens"),
    "play.nineLives.setup.startingLives.nine": ("Neun Leben", "Nueve vidas", "Negen levens"),
    "play.nineLives.setup.startingLives.three": ("Drei Leben", "Tres vidas", "Drie levens"),
    "play.nineLives.targetProgressFormat": ("Ziel %d von %d", "Objetivo %d de %d", "Doel %d van %d"),
    "play.nineLives.title": ("Nine Lives", "Nine Lives", "Nine Lives"),
    "play.prisoner.title": ("Prisoner", "Prisoner", "Prisoner"),
    "play.scam.title": ("Scam", "Scam", "Scam"),
    "play.snooker.title": ("Snooker", "Snooker", "Snooker"),
    "play.suddenDeath.announce.roundResults": (
        "Runde vorbei: %@",
        "Ronda terminada: %@",
        "Ronde voorbij: %@",
    ),
    "play.suddenDeath.atRiskAccessibilityLabel": (
        "Niedrigste Punktzahl diese Runde",
        "Puntuación más baja esta ronda",
        "Laagste score deze ronde",
    ),
    "play.suddenDeath.eliminatedLabel": ("Ausgeschieden", "Eliminado", "Geëlimineerd"),
    "play.suddenDeath.eliminatedThisRound": (
        "Diese Runde ausgeschieden",
        "Eliminado esta ronda",
        "Deze ronde geëlimineerd",
    ),
    "play.suddenDeath.eliminationRule.eliminateAllTied": (
        "Alle Gleichstände eliminieren",
        "Eliminar todos los empatados",
        "Elimineer alle gelijken",
    ),
    "play.suddenDeath.eliminationRule.eliminateOne": (
        "Einen eliminieren",
        "Eliminar uno",
        "Elimineer één",
    ),
    "play.suddenDeath.lowestScoreEliminatedFormat": (
        "%@ mit niedrigster Punktzahl ausgeschieden",
        "%@ eliminado con la puntuación más baja",
        "%@ geëlimineerd met de laagste score",
    ),
    "play.suddenDeath.navTitle": ("Sudden Death", "Sudden Death", "Sudden Death"),
    "play.suddenDeath.playersRemainingFormat": (
        "%d Spieler übrig",
        "%d jugadores restantes",
        "%d spelers over",
    ),
    "play.suddenDeath.roundFormat": ("Runde %d", "Ronda %d", "Ronde %d"),
    "play.suddenDeath.setup.eliminateAllTied": (
        "Alle Gleichstände eliminieren",
        "Eliminar todos los empatados",
        "Elimineer alle gelijken",
    ),
    "play.suddenDeath.setup.visitsPerRound": ("Würfe pro Runde", "Visitas por ronda", "Beurten per ronde"),
    "play.suddenDeath.setup.visitsPerRoundValueFormat": (
        "%d Würfe",
        "%d visitas",
        "%d beurten",
    ),
    "play.suddenDeath.thisRoundAccessibilityFormat": (
        "%d Punkte diese Runde",
        "%d puntos esta ronda",
        "%d punten deze ronde",
    ),
    "play.suddenDeath.thisRoundFormat": ("+%d", "+%d", "+%d"),
    "play.suddenDeath.title": ("Sudden Death", "Sudden Death", "Sudden Death"),
    "play.suddenDeath.totalPointsAccessibilityFormat": (
        "%d Punkte gesamt",
        "%d puntos en total",
        "%d punten totaal",
    ),
    "play.ticTacToe.title": ("Tic-Tac-Toe", "Tres en raya", "Boter-kaas-en-eieren"),
}

LOCALE_HEADERS = {
    "de": "/* Gameplay mode strings — German */",
    "es": "/* Gameplay mode strings — Spanish */",
    "nl": "/* Gameplay mode strings — Dutch */",
}


def parse_strings(path: Path) -> list[tuple[str, str]]:
    text = path.read_text(encoding="utf-8")
    return [(m.group(1), m.group(2)) for m in re.finditer(r'"([^"\\]+)"\s*=\s*"([^"]*)"\s*;', text)]


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
    en_keys = {key for key, _ in entries}
    extra = set(TRANSLATIONS) - en_keys
    if extra:
        raise SystemExit(f"Unused translation keys: {sorted(extra)}")
    missing = en_keys - set(TRANSLATIONS)
    if missing:
        raise SystemExit(f"Missing translation keys: {sorted(missing)}")

    write_locale("de", 0)
    write_locale("es", 1)
    write_locale("nl", 2)


if __name__ == "__main__":
    main()
