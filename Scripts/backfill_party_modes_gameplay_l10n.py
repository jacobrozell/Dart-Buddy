#!/usr/bin/env python3
"""Backfill party-mode gameplay + rules strings into locale_data JSON, then regenerate .strings."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "Scripts/locale_data"
LOCALES = ("de", "es", "nl", "fr", "zh-Hans")

# Shared short strings reused across modes.
COMMON: dict[str, dict[str, str]] = {
    "de": {
        "throwFormat": "%@ wirft",
        "openingThrowTarget": "%@ setzt das Eröffnungsziel",
        "openingThrowWire": "%@ setzt das Eröffnungs-Drahtziel",
        "passOrThrow": "%@ — passen oder werfen",
        "passTurn": "Zug passen",
        "out": "Aus",
        "lifeLost": "Leben verloren",
        "livesRemaining": "%d Leben übrig",
        "targetMatched": "Ziel getroffen",
        "wireTargetMatched": "Drahtziel getroffen",
        "disabledWhileBot": "Warten auf Bot-Wurf",
        "sessionMissing": "Partie-Sitzung nicht gefunden.",
        "invalidRecord": "Dieser Wurf konnte nicht gespeichert werden.",
        "passed": "%@ hat gepasst",
        "matched": "Getroffen",
        "missed": "Verfehlt",
        "overviewTitle": "Überblick",
        "currentTarget": "Aktuelles Ziel",
        "openingTarget": "Ziel setzen",
        "currentWireTarget": "Aktuelles Drahtziel",
        "setWireTarget": "Drahtziel setzen",
        "single": "Einfach",
        "double": "Doppel",
        "triple": "Triple",
        "outerBull": "Äußeres Bull",
        "innerBull": "Inneres Bull",
        "bull": "Bull",
        "finished": "Fertig",
        "standard": "Standard",
        "lowerLoop": "Untere Schleife",
        "upperLoop": "Obere Schleife",
        "split": "Split",
    },
    "es": {
        "throwFormat": "%@ lanza",
        "openingThrowTarget": "%@ fija el objetivo inicial",
        "openingThrowWire": "%@ fija el objetivo de alambre inicial",
        "passOrThrow": "%@ — pasar o lanzar",
        "passTurn": "Pasar turno",
        "out": "Fuera",
        "lifeLost": "Vida perdida",
        "livesRemaining": "%d vidas restantes",
        "targetMatched": "Objetivo acertado",
        "wireTargetMatched": "Alambre acertado",
        "disabledWhileBot": "Esperando turno del bot",
        "sessionMissing": "Sesión de partida no encontrada.",
        "invalidRecord": "No se pudo registrar esa visita.",
        "passed": "%@ pasó",
        "matched": "Acertado",
        "missed": "Fallado",
        "overviewTitle": "Resumen",
        "currentTarget": "Objetivo actual",
        "openingTarget": "Fijar objetivo",
        "currentWireTarget": "Alambre actual",
        "setWireTarget": "Fijar alambre",
        "single": "Sencillo",
        "double": "Doble",
        "triple": "Triple",
        "outerBull": "Bull exterior",
        "innerBull": "Bull interior",
        "bull": "Bull",
        "finished": "Terminado",
        "standard": "Estándar",
        "lowerLoop": "Bucle inferior",
        "upperLoop": "Bucle superior",
        "split": "Split",
    },
    "nl": {
        "throwFormat": "%@ gooit",
        "openingThrowTarget": "%@ zet het openingsdoel",
        "openingThrowWire": "%@ zet het openingsdrahtdoel",
        "passOrThrow": "%@ — passen of gooien",
        "passTurn": "Beurt passen",
        "out": "Uit",
        "lifeLost": "Leven verloren",
        "livesRemaining": "%d levens over",
        "targetMatched": "Doel geraakt",
        "wireTargetMatched": "Drahtdoel geraakt",
        "disabledWhileBot": "Wachten op botbeurt",
        "sessionMissing": "Wedstrijdsessie niet gevonden.",
        "invalidRecord": "Kon die visit niet registreren.",
        "passed": "%@ paste",
        "matched": "Geraakt",
        "missed": "Gemist",
        "overviewTitle": "Overzicht",
        "currentTarget": "Huidig doel",
        "openingTarget": "Doel zetten",
        "currentWireTarget": "Huidig drahtdoel",
        "setWireTarget": "Drahtdoel zetten",
        "single": "Single",
        "double": "Double",
        "triple": "Triple",
        "outerBull": "Outer bull",
        "innerBull": "Inner bull",
        "bull": "Bull",
        "finished": "Klaar",
        "standard": "Standaard",
        "lowerLoop": "Lage lus",
        "upperLoop": "Hoge lus",
        "split": "Split",
    },
    "fr": {
        "throwFormat": "%@ lance",
        "openingThrowTarget": "%@ fixe la cible d'ouverture",
        "openingThrowWire": "%@ fixe la cible fil d'ouverture",
        "passOrThrow": "%@ — passer ou lancer",
        "passTurn": "Passer le tour",
        "out": "Éliminé",
        "lifeLost": "Vie perdue",
        "livesRemaining": "%d vies restantes",
        "targetMatched": "Cible touchée",
        "wireTargetMatched": "Fil touché",
        "disabledWhileBot": "En attente du bot",
        "sessionMissing": "Session de partie introuvable.",
        "invalidRecord": "Impossible d'enregistrer cette visite.",
        "passed": "%@ a passé",
        "matched": "Touché",
        "missed": "Manqué",
        "overviewTitle": "Aperçu",
        "currentTarget": "Cible actuelle",
        "openingTarget": "Fixer la cible",
        "currentWireTarget": "Fil actuel",
        "setWireTarget": "Fixer le fil",
        "single": "Simple",
        "double": "Double",
        "triple": "Triple",
        "outerBull": "Bull extérieur",
        "innerBull": "Bull intérieur",
        "bull": "Bull",
        "finished": "Terminé",
        "standard": "Standard",
        "lowerLoop": "Boucle basse",
        "upperLoop": "Boucle haute",
        "split": "Split",
    },
    "zh-Hans": {
        "throwFormat": "%@ 投掷",
        "openingThrowTarget": "%@ 设定开局目标",
        "openingThrowWire": "%@ 设定开局线靶",
        "passOrThrow": "%@ — 跳过或投掷",
        "passTurn": "跳过回合",
        "out": "出局",
        "lifeLost": "失去一条命",
        "livesRemaining": "剩余 %d 条命",
        "targetMatched": "命中目标",
        "wireTargetMatched": "命中线靶",
        "disabledWhileBot": "等待机器人回合",
        "sessionMissing": "未找到比赛会话。",
        "invalidRecord": "无法记录该回合。",
        "passed": "%@ 跳过",
        "matched": "命中",
        "missed": "未中",
        "overviewTitle": "概述",
        "currentTarget": "当前目标",
        "openingTarget": "设定目标",
        "currentWireTarget": "当前线靶",
        "setWireTarget": "设定线靶",
        "single": "单倍",
        "double": "双倍",
        "triple": "三倍",
        "outerBull": "外牛眼",
        "innerBull": "内牛眼",
        "bull": "牛眼",
        "finished": "完成",
        "standard": "标准",
        "lowerLoop": "下线环",
        "upperLoop": "上线环",
        "split": "分线",
    },
}

# key -> {locale: value} for strings that differ per locale (including rules bodies).
SPECIFIC: dict[str, dict[str, str]] = {}

def add(key: str, de: str, es: str, nl: str, fr: str, zh: str) -> None:
    SPECIFIC[key] = {"de": de, "es": es, "nl": nl, "fr": fr, "zh-Hans": zh}


def c(locale: str, name: str) -> str:
    return COMMON[locale][name]


def build_specific() -> None:
    # Blind Killer
    add("play.blindKiller.navTitle", "Blinder Killer", "Blind Killer", "Blind Killer", "Blind Killer", "盲杀")
    add("play.blindKiller.throwFormat", c("de", "throwFormat"), c("es", "throwFormat"), c("nl", "throwFormat"), c("fr", "throwFormat"), c("zh-Hans", "throwFormat"))
    add("play.blindKiller.yourSecretNumberFormat", "Deine Geheimzahl: %d", "Tu número secreto: %d", "Je geheime nummer: %d", "Ton numéro secret : %d", "你的秘密数字：%d")
    add("play.blindKiller.playerEliminated", c("de", "out"), c("es", "out"), c("nl", "out"), c("fr", "out"), c("zh-Hans", "out"))
    add("play.blindKiller.doubleHitRecorded", "Doppel-Treffer gezählt", "Doble registrado", "Double geregistreerd", "Double enregistré", "记录双倍命中")
    add("play.blindKiller.eliminationRecorded", "Spieler ausgeschieden", "Jugador eliminado", "Speler geëlimineerd", "Joueur éliminé", "玩家出局")
    add("play.blindKiller.anonymousTallyAccessibilityFormat", "Segment %d, %d von %d Doppel-Treffern", "Segmento %d, %d de %d dobles", "Segment %d, %d van %d doubles", "Segment %d, %d sur %d doubles", "分区 %d，%d / %d 次双倍")
    add("play.blindKiller.pad.hint", "Doppel auf Segmenten 1 bis 20 zählen", "Cuentan los dobles en segmentos del 1 al 20", "Doubles op segmenten 1–20 tellen", "Les doubles sur les segments 1 à 20 comptent", "1–20 分区的双倍计分")
    add("play.blindKiller.pad.disabledWhileBot", c("de", "disabledWhileBot"), c("es", "disabledWhileBot"), c("nl", "disabledWhileBot"), c("fr", "disabledWhileBot"), c("zh-Hans", "disabledWhileBot"))
    add("play.rules.blindKiller.overview.title", c("de", "overviewTitle"), c("es", "overviewTitle"), c("nl", "overviewTitle"), c("fr", "overviewTitle"), c("zh-Hans", "overviewTitle"))
    add("play.rules.blindKiller.overview.body",
        "Jeder erhält eine Geheimzahl von 1 bis 20. Wirf auf Doppel — jeder Doppel-Treffer zählt auf dem Segment. Bei drei Doppel-Treffern auf einem Segment scheidet der Inhaber aus. Letzter Spieler gewinnt.",
        "A cada uno se le asigna un número secreto del 1 al 20. Lanza a dobles: cada doble suma en ese segmento. Con tres dobles en un segmento, quien tenga ese número queda fuera. Gana el último.",
        "Iedereen krijgt een geheim nummer van 1 tot 20. Gooi op doubles — elke double telt op dat segment. Bij drie doubles op een segment is de eigenaar uit. Laatste speler wint.",
        "Chacun reçoit un numéro secret de 1 à 20. Vise les doubles — chaque double compte sur ce segment. À trois doubles sur un segment, le détenteur est éliminé. Dernier joueur gagnant.",
        "每人分配 1–20 的秘密数字。投双倍区——每个双倍命中计入该分区。某分区累计三次双倍命中时，持有该数字者出局。最后一名获胜。")
    add("play.rules.blindKiller.secret.title", "Deine Geheimzahl", "Tu número secreto", "Je geheime nummer", "Ton numéro secret", "你的秘密数字")
    add("play.rules.blindKiller.secret.body",
        "Nur du siehst deine Zahl auf deinem Gerät. Gegner sehen Treffer auf Segmenten, nicht wer welche Zahl hat.",
        "Solo tú ves tu número en tu dispositivo. Los rivales ven los segmentos con impactos, no quién los tiene.",
        "Alleen jij ziet je nummer op je apparaat. Tegenstanders zien welke segmenten hits hebben, niet wie welk nummer heeft.",
        "Seul toi vois ton numéro sur ton appareil. Les adversaires voient les segments touchés, pas qui possède quel numéro.",
        "只有你在本机看到自己的数字。对手只能看到哪些分区有命中，看不到归属。")
    add("play.rules.blindKiller.throwing.title", "Werfen", "Lanzar", "Gooien", "Lancer", "投掷")
    add("play.rules.blindKiller.throwing.body",
        "Pro Zug wirfst du drei Darts. Jedes Doppel zählt auf dem Segment. Einfach und Triple zählen nicht.",
        "Cada turno lanzas tres dardos. Cualquier doble suma en ese segmento. Sencillos y triples no cuentan.",
        "Per beurt gooi je drie pijlen. Elke double telt op het segment. Singles en triples tellen niet.",
        "À chaque tour tu lances trois fléchettes. Tout double compte sur le segment. Simples et triples ne comptent pas.",
        "每回合投三支镖。任意双倍计入该分区。单倍和三倍不计。")
    add("play.rules.blindKiller.elimination.title", "Ausscheidung", "Eliminación", "Eliminatie", "Élimination", "出局")
    add("play.rules.blindKiller.elimination.body",
        "Erreicht ein Segment drei Doppel-Treffer, scheidet der Spieler mit dieser Geheimzahl sofort aus.",
        "Cuando un segmento llega a tres dobles, el jugador con ese número secreto queda eliminado al instante.",
        "Bij drie doubles op een segment wordt de speler met dat geheime nummer meteen geëlimineerd.",
        "Quand un segment atteint trois doubles, le joueur avec ce numéro secret est éliminé immédiatement.",
        "某分区双倍命中达到三次时，持有该秘密数字的玩家立即出局。")
    add("history.timeline.blindKillerTurnFormat", "%@ warf — %d Doppel-Treffer", "%@ lanzó — %d dobles", "%@ gooide — %d doubles", "%@ a lancé — %d doubles", "%@ 投掷 — %d 次双倍")
    add("blindKiller.error.sessionMissing", c("de", "sessionMissing"), c("es", "sessionMissing"), c("nl", "sessionMissing"), c("fr", "sessionMissing"), c("zh-Hans", "sessionMissing"))
    add("blindKiller.error.invalidTurn", c("de", "invalidRecord"), c("es", "invalidRecord"), c("nl", "invalidRecord"), c("fr", "invalidRecord"), c("zh-Hans", "invalidRecord"))

    # Follow the Leader
    add("play.followTheLeader.title", "Folge dem Führenden", "Sigue al líder", "Volg de leider", "Imiter le leader", "跟随领导者")
    add("play.followTheLeader.navTitle", "Folge dem Führenden", "Sigue al líder", "Volg de leider", "Imiter le leader", "跟随领导者")
    add("play.followTheLeader.throwFormat", c("de", "throwFormat"), c("es", "throwFormat"), c("nl", "throwFormat"), c("fr", "throwFormat"), c("zh-Hans", "throwFormat"))
    add("play.followTheLeader.openingThrowFormat", c("de", "openingThrowTarget"), c("es", "openingThrowTarget"), c("nl", "openingThrowTarget"), c("fr", "openingThrowTarget"), c("zh-Hans", "openingThrowTarget"))
    add("play.followTheLeader.passTurnFormat", c("de", "passOrThrow"), c("es", "passOrThrow"), c("nl", "passOrThrow"), c("fr", "passOrThrow"), c("zh-Hans", "passOrThrow"))
    add("play.followTheLeader.passTurn", c("de", "passTurn"), c("es", "passTurn"), c("nl", "passTurn"), c("fr", "passTurn"), c("zh-Hans", "passTurn"))
    add("play.followTheLeader.openingTargetTitle", c("de", "openingTarget"), c("es", "openingTarget"), c("nl", "openingTarget"), c("fr", "openingTarget"), c("zh-Hans", "openingTarget"))
    add("play.followTheLeader.currentTargetTitle", c("de", "currentTarget"), c("es", "currentTarget"), c("nl", "currentTarget"), c("fr", "currentTarget"), c("zh-Hans", "currentTarget"))
    add("play.followTheLeader.currentTargetFormat", "%1$d %2$@", "%1$d %2$@", "%1$d %2$@", "%1$d %2$@", "%1$d %2$@")
    add("play.followTheLeader.targetArea.single", c("de", "single"), c("es", "single"), c("nl", "single"), c("fr", "single"), c("zh-Hans", "single"))
    add("play.followTheLeader.targetArea.double", c("de", "double"), c("es", "double"), c("nl", "double"), c("fr", "double"), c("zh-Hans", "double"))
    add("play.followTheLeader.targetArea.triple", c("de", "triple"), c("es", "triple"), c("nl", "triple"), c("fr", "triple"), c("zh-Hans", "triple"))
    add("play.followTheLeader.targetArea.outerBull", c("de", "outerBull"), c("es", "outerBull"), c("nl", "outerBull"), c("fr", "outerBull"), c("zh-Hans", "outerBull"))
    add("play.followTheLeader.targetArea.innerBull", c("de", "innerBull"), c("es", "innerBull"), c("nl", "innerBull"), c("fr", "innerBull"), c("zh-Hans", "innerBull"))
    add("play.followTheLeader.livesRemainingFormat", c("de", "livesRemaining"), c("es", "livesRemaining"), c("nl", "livesRemaining"), c("fr", "livesRemaining"), c("zh-Hans", "livesRemaining"))
    add("play.followTheLeader.playerEliminated", c("de", "out"), c("es", "out"), c("nl", "out"), c("fr", "out"), c("zh-Hans", "out"))
    add("play.followTheLeader.nonDominantPickReminder",
        "Letzter Treffer-Dart setzt das nächste Ziel",
        "El último dardo que puntúa fija el siguiente objetivo",
        "Laatste scorende dart zet het volgende doel",
        "La dernière fléchette qui marque fixe la prochaine cible",
        "最后一次得分镖设定下一目标")
    add("play.followTheLeader.announce.targetMatched", c("de", "targetMatched"), c("es", "targetMatched"), c("nl", "targetMatched"), c("fr", "targetMatched"), c("zh-Hans", "targetMatched"))
    add("play.followTheLeader.lifeLost", c("de", "lifeLost"), c("es", "lifeLost"), c("nl", "lifeLost"), c("fr", "lifeLost"), c("zh-Hans", "lifeLost"))
    add("play.followTheLeader.pad.hint",
        "Triff das Ziel in drei Darts oder verliere ein Leben",
        "Acerta el objetivo en tres dardos o pierde una vida",
        "Raak het doel in drie pijlen of verlies een leven",
        "Touche la cible en trois fléchettes ou perds une vie",
        "三镖内命中目标，否则失去一条命")
    add("play.followTheLeader.pad.passOrThrowHint",
        "Alle verfehlt — passen oder erneut werfen",
        "Todos fallaron — pasar el turno o lanzar de nuevo",
        "Iedereen miste — pas de beurt of gooi opnieuw",
        "Tous ont manqué — passer le tour ou relancer",
        "全员未中——跳过回合或再投")
    add("play.followTheLeader.pad.disabledWhileBot", c("de", "disabledWhileBot"), c("es", "disabledWhileBot"), c("nl", "disabledWhileBot"), c("fr", "disabledWhileBot"), c("zh-Hans", "disabledWhileBot"))
    add("play.rules.followTheLeader.overview.title", c("de", "overviewTitle"), c("es", "overviewTitle"), c("nl", "overviewTitle"), c("fr", "overviewTitle"), c("zh-Hans", "overviewTitle"))
    add("play.rules.followTheLeader.overview.body",
        "Spieler wechseln sich ab, ein gemeinsames Ziel zu treffen. Verfehlst du in drei Darts, verlierst du ein Leben. Letzter mit Leben gewinnt.",
        "Los jugadores se turnan para igualar un objetivo común. Si fallas en tres dardos, pierdes una vida. Gana quien conserve vidas.",
        "Spelers beurten om een gedeeld doel te raken. Mis je in drie pijlen, verlies je een leven. Laatste met levens wint.",
        "Les joueurs visent à tour de rôle une cible commune. Manqué en trois fléchettes : une vie perdue. Dernier avec des vies gagne.",
        "玩家轮流命中共同目标。三镖未中则失去一条命。最后仍有生命者胜。")
    add("play.rules.followTheLeader.target.title", "Ziel setzen", "Fijar objetivo", "Doel zetten", "Fixer la cible", "设定目标")
    add("play.rules.followTheLeader.target.body",
        "Der Erste wirft einen Dart fürs Eröffnungsziel. Triffst du mit Restdarts, kann der letzte Treffer ein neues Ziel setzen.",
        "El primero lanza un dardo para abrir. Si aciertas con dardos sobrantes, el último que puntúe puede fijar un nuevo objetivo.",
        "De eerste gooit één pijl voor het openingdoel. Raak je met resterende pijlen, kan de laatste score het doel vernieuwen.",
        "Le premier lance une fléchette pour ouvrir. Si tu touches avec des fléchettes restantes, la dernière qui marque fixe une nouvelle cible.",
        "首名玩家以一镖设定开局目标。若命中后还有剩余镖，最后一次得分可设定新目标。")
    add("play.rules.followTheLeader.match.title", "Treffen", "Igualar", "Raken", "Toucher", "命中")
    add("play.rules.followTheLeader.match.body",
        "Triff in bis zu drei Darts exakt Segment und Ring. Einfach, Doppel, Triple und Bull sind verschiedene Ziele.",
        "En hasta tres dardos, iguala segmento y anillo exactos. Sencillo, doble, triple y bull son objetivos distintos.",
        "Raak in maximaal drie pijlen exact segment en ring. Single, double, triple en bull zijn verschillende doelen.",
        "En jusqu'à trois fléchettes, touche le segment et l'anneau exacts. Simple, double, triple et bull sont distincts.",
        "最多三镖内命中相同分区和环区。单倍、双倍、三倍和牛眼是不同的目标。")
    add("play.rules.followTheLeader.pass.title", "Passen oder nachwerfen", "Pasar o relanzar", "Passen of opnieuw", "Passer ou relancer", "跳过或再投")
    add("play.rules.followTheLeader.pass.body",
        "Verfehlen alle aktiven Spieler das Ziel, darf der Setzer passen oder erneut werfen.",
        "Si todos los activos fallan el objetivo, quien lo fijó puede pasar o lanzar otra vez.",
        "Als alle actieve spelers missen, mag de zetter passen of opnieuw gooien.",
        "Si tous les joueurs actifs manquent, celui qui a fixé la cible peut passer ou relancer.",
        "若所有在场玩家均未命中，设定者可跳过或再投。")
    add("history.timeline.followTheLeaderVisitFormat", "%@ — %@", "%@ — %@", "%@ — %@", "%@ — %@", "%@ — %@")
    add("history.timeline.followTheLeaderMatched", c("de", "matched"), c("es", "matched"), c("nl", "matched"), c("fr", "matched"), c("zh-Hans", "matched"))
    add("history.timeline.followTheLeaderMissed", c("de", "missed"), c("es", "missed"), c("nl", "missed"), c("fr", "missed"), c("zh-Hans", "missed"))
    add("history.timeline.followTheLeaderPassFormat", c("de", "passed"), c("es", "passed"), c("nl", "passed"), c("fr", "passed"), c("zh-Hans", "passed"))
    add("followTheLeader.error.sessionMissing", c("de", "sessionMissing"), c("es", "sessionMissing"), c("nl", "sessionMissing"), c("fr", "sessionMissing"), c("zh-Hans", "sessionMissing"))
    add("followTheLeader.error.invalidVisit", c("de", "invalidRecord"), c("es", "invalidRecord"), c("nl", "invalidRecord"), c("fr", "invalidRecord"), c("zh-Hans", "invalidRecord"))

    # Loop
    add("play.loop.title", "Schleife", "Bucle", "Loop", "Boucle", "循环")
    add("play.loop.navTitle", "Schleife", "Bucle", "Loop", "Boucle", "循环")
    add("play.loop.throwFormat", c("de", "throwFormat"), c("es", "throwFormat"), c("nl", "throwFormat"), c("fr", "throwFormat"), c("zh-Hans", "throwFormat"))
    add("play.loop.openingThrowFormat", c("de", "openingThrowWire"), c("es", "openingThrowWire"), c("nl", "openingThrowWire"), c("fr", "openingThrowWire"), c("zh-Hans", "openingThrowWire"))
    add("play.loop.passTurnFormat", c("de", "passOrThrow"), c("es", "passOrThrow"), c("nl", "passOrThrow"), c("fr", "passOrThrow"), c("zh-Hans", "passOrThrow"))
    add("play.loop.passTurn", c("de", "passTurn"), c("es", "passTurn"), c("nl", "passTurn"), c("fr", "passTurn"), c("zh-Hans", "passTurn"))
    add("play.loop.openingTargetTitle", c("de", "setWireTarget"), c("es", "setWireTarget"), c("nl", "setWireTarget"), c("fr", "setWireTarget"), c("zh-Hans", "setWireTarget"))
    add("play.loop.currentTargetTitle", c("de", "currentWireTarget"), c("es", "currentWireTarget"), c("nl", "currentWireTarget"), c("fr", "currentWireTarget"), c("zh-Hans", "currentWireTarget"))
    add("play.loop.currentTargetFormat", "%1$d %2$@", "%1$d %2$@", "%1$d %2$@", "%1$d %2$@", "%1$d %2$@")
    add("play.loop.currentWireTargetAccessibilityFormat", "Aktuelles Ziel: %@", "Objetivo actual: %@", "Huidig doel: %@", "Cible actuelle : %@", "当前目标：%@")
    add("play.loop.wireTarget.standard", c("de", "standard"), c("es", "standard"), c("nl", "standard"), c("fr", "standard"), c("zh-Hans", "standard"))
    add("play.loop.wireTarget.lowerLoop", c("de", "lowerLoop"), c("es", "lowerLoop"), c("nl", "lowerLoop"), c("fr", "lowerLoop"), c("zh-Hans", "lowerLoop"))
    add("play.loop.wireTarget.upperLoop", c("de", "upperLoop"), c("es", "upperLoop"), c("nl", "upperLoop"), c("fr", "upperLoop"), c("zh-Hans", "upperLoop"))
    add("play.loop.wireTarget.split", c("de", "split"), c("es", "split"), c("nl", "split"), c("fr", "split"), c("zh-Hans", "split"))
    add("play.loop.wireTarget.loopFormat", "%1$d %2$@", "%1$d %2$@", "%1$d %2$@", "%1$d %2$@", "%1$d %2$@")
    add("play.loop.wireTarget.splitFormat", "Split %d", "Split %d", "Split %d", "Split %d", "分线 %d")
    add("play.loop.wireTargetPicker.title", "Welchen Draht hast du getroffen?", "¿Qué alambre acertaste?", "Welke draad heb je geraakt?", "Quel fil as-tu touché ?", "你命中哪条线？")
    add("play.loop.wireTargetPicker.accessibility", "Drahtziel wählen", "Elegir alambre", "Kies drahtdoel", "Choisir le fil", "选择线靶")
    add("play.loop.livesRemainingFormat", c("de", "livesRemaining"), c("es", "livesRemaining"), c("nl", "livesRemaining"), c("fr", "livesRemaining"), c("zh-Hans", "livesRemaining"))
    add("play.loop.playerEliminated", c("de", "out"), c("es", "out"), c("nl", "out"), c("fr", "out"), c("zh-Hans", "out"))
    add("play.loop.nonDominantPickReminder",
        "Wähle die exakte Drahtfläche, die du getroffen hast",
        "Elige el área de alambre exacta que acertaste",
        "Kies het exacte drahtgebied dat je raakte",
        "Choisis la zone de fil exacte touchée",
        "选择你命中的精确线区")
    add("play.loop.announce.targetMatched", c("de", "wireTargetMatched"), c("es", "wireTargetMatched"), c("nl", "wireTargetMatched"), c("fr", "wireTargetMatched"), c("zh-Hans", "wireTargetMatched"))
    add("play.loop.lifeLost", c("de", "lifeLost"), c("es", "lifeLost"), c("nl", "lifeLost"), c("fr", "lifeLost"), c("zh-Hans", "lifeLost"))
    add("play.loop.pad.hint",
        "Triff das Drahtziel in drei Darts oder verliere ein Leben",
        "Acerta el alambre en tres dardos o pierde una vida",
        "Raak het drahtdoel in drie pijlen of verlies een leven",
        "Touche le fil en trois fléchettes ou perds une vie",
        "三镖内命中线靶，否则失去一条命")
    add("play.loop.pad.passOrThrowHint",
        "Alle verfehlt — passen oder erneut werfen",
        "Todos fallaron — pasar el turno o lanzar de nuevo",
        "Iedereen miste — pas de beurt of gooi opnieuw",
        "Tous ont manqué — passer le tour ou relancer",
        "全员未中——跳过回合或再投")
    add("play.loop.pad.disabledWhileBot", c("de", "disabledWhileBot"), c("es", "disabledWhileBot"), c("nl", "disabledWhileBot"), c("fr", "disabledWhileBot"), c("zh-Hans", "disabledWhileBot"))
    add("play.rules.loop.overview.title", c("de", "overviewTitle"), c("es", "overviewTitle"), c("nl", "overviewTitle"), c("fr", "overviewTitle"), c("zh-Hans", "overviewTitle"))
    add("play.rules.loop.overview.body",
        "Loop ist Follow the Leader auf den Drahtverläufen. Triff das Drahtziel — Schleifen, Splits und Standardringe — oder verliere ein Leben. Letzter mit Leben gewinnt.",
        "Loop es Follow the Leader en el cableado del tablero. Iguala el alambre — bucles, splits y anillos — o pierde una vida. Gana quien conserve vidas.",
        "Loop is Follow the Leader op de bedrading. Raak het drahtdoel — lussen, splits en standaardringen — of verlies een leven. Laatste met levens wint.",
        "Loop est Follow the Leader sur le câblage. Touche le fil — boucles, splits et anneaux — ou perds une vie. Dernier avec des vies gagne.",
        "循环是跟随领导者在盘面线靶上的玩法。命中线靶——线环、分线和标准环——否则失去一条命。最后仍有生命者胜。")
    add("play.rules.loop.targets.title", "Gültige Ziele", "Objetivos válidos", "Geldige doelen", "Cibles valides", "有效目标")
    add("play.rules.loop.targets.body",
        "Ein Ziel kann ein normales Feld, eine Drahtschleife (z. B. 6 oder 20) oder ein Split bei 11 sein. Obere und untere Schleife auf derselben Zahl sind verschieden.",
        "Un objetivo puede ser una cuña normal, un bucle de alambre (p. ej. 6 o 20) o un split en el 11. Bucles superior e inferior en el mismo número son distintos.",
        "Een doel kan een normale wedge, een draadlus (bijv. 6 of 20) of een split op 11 zijn. Hoge en lage lus op hetzelfde nummer verschillen.",
        "Une cible peut être une wedge normale, une boucle fil (ex. 6 ou 20) ou un split sur 11. Boucles haute et basse sur le même chiffre diffèrent.",
        "目标可以是普通楔形区、线环（如 6 或 20）或 11 的分线。同一数字的上线环和下线环是不同的目标。")
    add("play.rules.loop.play.title", "Spiel", "Juego", "Spel", "Partie", "玩法")
    add("play.rules.loop.play.body",
        "Der erste Dart setzt das Ziel. Folgende müssen die exakte Drahtfläche in bis zu drei Darts treffen oder verlieren ein Leben. Frühes Treffen erlaubt ein neues Ziel.",
        "El primer dardo fija el objetivo. Los demás deben acertar esa área en hasta tres dardos o pierden una vida. Acertar pronto permite un nuevo objetivo.",
        "De eerste pijl zet het doel. Volgers moeten het exacte drahtgebied in maximaal drie pijlen raken of verliezen een leven. Vroeg raken kan een nieuw doel zetten.",
        "La première fléchette fixe la cible. Les suivants doivent toucher la zone fil exacte en trois fléchettes max ou perdent une vie. Toucher tôt peut fixer une nouvelle cible.",
        "首镖设定目标。跟随者须在三镖内命中相同线区，否则失去一条命。提前命中可用剩余镖设定新目标。")
    add("play.rules.loop.wires.title", "Schleifen und Splits", "Bucles y splits", "Lussen en splits", "Boucles et splits", "线环与分线")
    add("play.rules.loop.wires.body",
        "Ist ein Dart mehrdeutig, fragt die App nach. Ein Dart in der Schleife der 6 ist nicht dasselbe wie die große Einfach-6.",
        "Si un dardo puede significar más de un alambre, la app pide confirmación. Un dardo en el bucle del 6 no es lo mismo que el sencillo grande del 6.",
        "Als een pijl meerdere drahtgebieden kan betekenen, vraagt de app om bevestiging. Een pijl in de lus van 6 is niet hetzelfde als grote single 6.",
        "Si une fléchette peut viser plusieurs zones fil, l'app demande confirmation. Une fléchette dans la boucle du 6 n'est pas le grand simple 6.",
        "若一镖可能对应多个线区，应用会请你确认。6 的线环与大单 6 不是同一目标。")
    add("history.timeline.loopVisitFormat", "%@ — %@", "%@ — %@", "%@ — %@", "%@ — %@", "%@ — %@")
    add("history.timeline.loopPassFormat", c("de", "passed"), c("es", "passed"), c("nl", "passed"), c("fr", "passed"), c("zh-Hans", "passed"))
    add("loop.error.sessionMissing", c("de", "sessionMissing"), c("es", "sessionMissing"), c("nl", "sessionMissing"), c("fr", "sessionMissing"), c("zh-Hans", "sessionMissing"))
    add("loop.error.invalidVisit", c("de", "invalidRecord"), c("es", "invalidRecord"), c("nl", "invalidRecord"), c("fr", "invalidRecord"), c("zh-Hans", "invalidRecord"))

    # Prisoner
    add("play.prisoner.title", "Gefangener", "Prisionero", "Gevangene", "Prisonnier", "囚徒")
    add("play.prisoner.navTitle", "Gefangener", "Prisionero", "Gevangene", "Prisonnier", "囚徒")
    add("play.prisoner.throwFormat", c("de", "throwFormat"), c("es", "throwFormat"), c("nl", "throwFormat"), c("fr", "throwFormat"), c("zh-Hans", "throwFormat"))
    add("play.prisoner.currentTargetTitle", c("de", "currentTarget"), c("es", "currentTarget"), c("nl", "currentTarget"), c("fr", "currentTarget"), c("zh-Hans", "currentTarget"))
    add("play.prisoner.progressSegmentFormat", "Segment %d", "Segmento %d", "Segment %d", "Segment %d", "分区 %d")
    add("play.prisoner.dartPoolFormat", "%d Darts", "%d dardos", "%d pijlen", "%d fléchettes", "%d 支镖")
    add("play.prisoner.stuckDartsFormat", "%d stecken auf der Scheibe", "%d clavados en el tablero", "%d vast op het bord", "%d coincées sur la cible", "%d 支镖卡在板上")
    add("play.prisoner.targetProgressFormat", "%1$d von %2$d", "%1$d de %2$d", "%1$d van %2$d", "%1$d sur %2$d", "%1$d / %2$d")
    add("play.prisoner.completed", c("de", "finished"), c("es", "finished"), c("nl", "finished"), c("fr", "finished"), c("zh-Hans", "finished"))
    add("play.prisoner.prisonersOnBoardTitle", "Gefangene auf der Scheibe", "Prisioneros en el tablero", "Gevangenen op het bord", "Prisonniers sur la cible", "板上的囚镖")
    add("play.prisoner.noPrisoners", "Keine Gefangenen auf der Scheibe", "No hay prisioneros en el tablero", "Geen gevangenen op het bord", "Aucun prisonnier sur la cible", "板上没有囚镖")
    add("play.prisoner.prisonerOnBoardFormat", "%1$@ — %2$@", "%1$@ — %2$@", "%1$@ — %2$@", "%1$@ — %2$@", "%1$@ — %2$@")
    add("play.prisoner.prisonerCaptured", "Gefangener erobert", "Prisionero capturado", "Gevangene bevrijd", "Prisonnier capturé", "捕获囚镖")
    add("play.prisoner.prisonerOnBoard", "Dart gefangen", "Dardo prisionero", "Pijl gevangen", "Fléchette emprisonnée", "镖被囚禁")
    add("play.prisoner.dartLostOneTurn", "Dart steckt außerhalb der Doppel", "Dardo fuera de los dobles", "Pijl buiten de doubles", "Fléchette coincée hors doubles", "镖卡在双倍区外")
    add("play.prisoner.playableRingHint",
        "Triple, äußere Einfach und Doppel zählen fürs Ziel",
        "Triple, sencillo exterior y doble cuentan para el objetivo",
        "Triple, buiten-single en double tellen voor je doel",
        "Triple, simple extérieur et double comptent pour la cible",
        "三倍、外单和双倍计入目标")
    add("play.prisoner.boardOverlayAccessibilityFormat", "Gefangene auf der Scheibe: %@", "Prisioneros en el tablero: %@", "Gevangenen op het bord: %@", "Prisonniers sur la cible : %@", "板上囚镖：%@")
    add("play.prisoner.bullSegmentLabel", c("de", "bull"), c("es", "bull"), c("nl", "bull"), c("fr", "bull"), c("zh-Hans", "bull"))
    add("play.prisoner.ringPicker.title", "Welchen Ring hast du getroffen?", "¿Qué anillo acertaste?", "Welke ring heb je geraakt?", "Quel anneau as-tu touché ?", "你命中哪个环区？")
    add("play.prisoner.ringPicker.accessibility", "Wertungsring wählen", "Elegir anillo", "Kies scoringsring", "Choisir l'anneau", "选择计分环")
    add("play.prisoner.ringPicker.playableFormat", "Äußeres Einfach, Doppel oder Triple auf %d", "Sencillo exterior, doble o triple en %d", "Buiten-single, dubbel of triple op %d", "Simple extérieur, double ou triple sur %d", "在 %d 上：外单、双倍或三倍")
    add("play.prisoner.ringPicker.innerSingleFormat", "Inneres Einfach auf %d", "Sencillo interior en %d", "Inner single op %d", "Simple intérieur sur %d", "%d 的内单")
    add("play.prisoner.pad.hint",
        "Triff dein Ziel im spielbaren Ring oder verwalte Gefangene",
        "Acerta tu objetivo en el anillo jugable o gestiona prisioneros",
        "Raak je doel in de speelbare ring of beheer gevangenen",
        "Touche ta cible dans l'anneau jouable ou gère les prisonniers",
        "在可计分环区命中目标，或处理囚镖")
    add("play.prisoner.pad.disabledWhileBot", c("de", "disabledWhileBot"), c("es", "disabledWhileBot"), c("nl", "disabledWhileBot"), c("fr", "disabledWhileBot"), c("zh-Hans", "disabledWhileBot"))
    add("play.rules.prisoner.overview.title", c("de", "overviewTitle"), c("es", "overviewTitle"), c("nl", "overviewTitle"), c("fr", "overviewTitle"), c("zh-Hans", "overviewTitle"))
    add("play.rules.prisoner.overview.body",
        "Renn im Uhrzeigersinn von 1 bis 20 durch den äußeren Ring. Wer zuerst fertig ist, gewinnt — verfehlte Darts können Gefangene werden, die andere erobern.",
        "Carrera en sentido horario del 1 al 20 por el anillo exterior. Gana quien termine primero; dardos fallados pueden ser prisioneros que otros capturan.",
        "Race met de klok mee van 1 naar 20 door de buitenste ring. Eerste finisher wint — gemiste pijlen kunnen gevangenen worden die anderen bevrijden.",
        "Course horaire de 1 à 20 dans l'anneau extérieur. Premier fini gagne — les fléchettes manquées peuvent devenir des prisonniers capturables.",
        "顺时针从 1 赛到 20，走外圈计分区。最先完成者胜——未中的镖可能成为可被捕获的囚镖。")
    add("play.rules.prisoner.progress.title", "Fortschritt", "Progreso", "Voortgang", "Progression", "进度")
    add("play.rules.prisoner.progress.body",
        "Nach 1 kommen 18, 4, 13 usw. im Uhrzeigersinn. Nur Treffer im spielbaren Ring (Triple bis Doppel) bringen dich weiter.",
        "Tras el 1 vienen 18, 4, 13, etc. en sentido horario. Solo aciertos en el anillo jugable (triple a doble) avanzan.",
        "Na 1 komt 18, 4, 13 enz. met de klok mee. Alleen hits in de speelbare ring (triple t/m double) tellen.",
        "Après 1 viennent 18, 4, 13, etc. dans le sens horaire. Seuls les hits dans l'anneau jouable (triple au double) avancent.",
        "1 之后顺时针为 18、4、13 等。只有可计分环区（三倍至双倍）的命中才能推进。")
    add("play.rules.prisoner.lost.title", "Verlorene Darts", "Dardos perdidos", "Verloren pijlen", "Fléchettes perdues", "丢失的镖")
    add("play.rules.prisoner.lost.body",
        "Verfehlst du außerhalb der Doppel oder prallst ab, bleibt der Dart eine Runde stecken — nächste Aufnahme weniger Darts, danach zurück.",
        "Si fallas fuera de los dobles o rebota, el dardo queda una ronda — menos dardos la próxima visita, luego lo recuperas.",
        "Mis je buiten de doubles of stuiter je weg, blijft de pijl een ronde vast — volgende visit minder pijlen, daarna terug.",
        "Manqué hors doubles ou rebond : la fléchette reste une visite — moins de fléchettes au tour suivant, puis récupérée.",
        "投在双倍区外或弹飞，该镖会卡板一回合——下回合少投一镖，之后收回。")
    add("play.rules.prisoner.capture.title", "Gefangene", "Prisioneros", "Gevangenen", "Prisonniers", "囚镖")
    add("play.rules.prisoner.capture.body",
        "Triffst du das Innenbrett, wird der Dart Gefangener. Trifft später jemand den spielbaren Bereich derselben Zahl, erhält er ihn in seinen Pool.",
        "Si aciertas el tablero interior, el dardo queda prisionero. Quien luego acierte el anillo jugable de ese número lo captura para su pool.",
        "Raak je het binnenveld, wordt de pijl gevangene. Wie later het speelbare gebied van dat nummer raakt, voegt hem toe aan de pool.",
        "Toucher la zone intérieure emprisonne la fléchette. Celui qui touche ensuite la zone jouable de ce numéro la capture.",
        "命中内圈时该镖成为囚镖。之后任何人在该数字的可计分区命中即可捕获并加入镖池。")
    add("history.timeline.prisonerVisitFormat", "%@ — %d Darts", "%@ — %d dardos", "%@ — %d pijlen", "%@ — %d fléchettes", "%@ — %d 支镖")
    add("prisoner.error.sessionMissing", c("de", "sessionMissing"), c("es", "sessionMissing"), c("nl", "sessionMissing"), c("fr", "sessionMissing"), c("zh-Hans", "sessionMissing"))
    add("prisoner.error.invalidVisit", c("de", "invalidRecord"), c("es", "invalidRecord"), c("nl", "invalidRecord"), c("fr", "invalidRecord"), c("zh-Hans", "invalidRecord"))

    # Fix English placeholders still in locale JSON (snooker + tic-tac-toe rules/errors)
    add("play.rules.snooker.breaks.title", "Serien", "Series", "Series", "Séries", "单杆")
    add("play.rules.snooker.breaks.body",
        "Wechsle Rot und Farbe, bis du verfehlst oder alle Roten weg sind. Dein Break endet bei Fehlwurf; Gegner bricht an.",
        "Alterna rojo y color hasta fallar o acabar los rojos. Tu break termina al fallar; el rival entra.",
        "Wissel rood en kleur af tot je mist of roden op zijn. Je break eindigt bij een miss; tegenstander breekt.",
        "Alterne rouge et couleur jusqu'à manquer ou plus de rouges. Ton break s'arrête au miss ; l'adversaire casse.",
        "交替打红和彩球，直到失误或红球打完。失误结束单杆，对手开球。")
    add("play.rules.snooker.colours.title", "Farben", "Colores", "Kleuren", "Couleurs", "彩球")
    add("play.rules.snooker.colours.body",
        "Nach Rot Farbe nominieren und für 2–7 Punkte lochen. Farben kommen zurück; Roten nicht.",
        "Tras un rojo, nombra y emboca un color por 2–7 puntos. Los colores vuelven; los rojos no.",
        "Na rood een kleur nomineren en potten voor 2–7 punten. Kleuren keren terug; roden niet.",
        "Après un rouge, nomme et empoche une couleur pour 2–7 points. Les couleurs reviennent ; pas les rouges.",
        "进红后指定并打进彩球得 2–7 分。彩球会复位；红球不会。")
    add("play.rules.snooker.overview.title", c("de", "overviewTitle"), c("es", "overviewTitle"), c("nl", "overviewTitle"), c("fr", "overviewTitle"), c("zh-Hans", "overviewTitle"))
    add("play.rules.snooker.overview.body",
        "Roten sind Segmente 1–15 (je 1 Punkt). Nach Rot eine Farbe nominieren: 16 Gelb bis Bull Schwarz. Höchste Frame-Punktzahl gewinnt.",
        "Los rojos son segmentos 1–15 (1 punto). Tras un rojo, nombra color: 16 amarillo hasta bull negro. Gana el frame más alto.",
        "Rood is segment 1–15 (1 punt). Na rood een kleur nomineren: 16 geel t/m bull zwart. Hoogste frame wint.",
        "Les rouges sont segments 1–15 (1 point). Après un rouge, nomme une couleur : 16 jaune au bull noir. Meilleur frame gagne.",
        "红球为 1–15 分区（各 1 分）。进红后指定彩球：16 黄至牛眼黑。帧分最高者胜。")
    add("play.rules.snooker.reds.title", "Roten", "Rojos", "Rood", "Rouges", "红球")
    add("play.rules.snooker.reds.body",
        "Loche ein verfügbares Rot für 1 Punkt und nominiere eine Farbe. Eingelochtes Rot bleibt weg.",
        "Emboca un rojo disponible por 1 punto y nombra un color. Ese rojo no vuelve.",
        "Pot een beschikbaar rood voor 1 punt en nomineer een kleur. Gepot rood blijft weg.",
        "Empoche un rouge disponible pour 1 point et nomme une couleur. Ce rouge ne revient pas.",
        "打进任意可用红球得 1 分并指定彩球。入袋后该红球不再上台。")
    add("play.rules.ticTacToe.overview.title", c("de", "overviewTitle"), c("es", "overviewTitle"), c("nl", "overviewTitle"), c("fr", "overviewTitle"), c("zh-Hans", "overviewTitle"))
    add("play.rules.ticTacToe.overview.body",
        "Drei gewinnt auf einem 3×3-Raster aus Zielen. Triff eine Zelle, um sie zu beanspruchen. Drei in einer Reihe gewinnen.",
        "Tres en raya en una cuadrícula 3×3 de objetivos. Acerta una celda para reclamarla. Tres en línea ganan.",
        "Boter-kaas-en-eieren op een 3×3-raster. Raak een cel om te claimen. Drie op een rij wint.",
        "Morpion sur une grille 3×3 de cibles. Touche une case pour la prendre. Trois alignés gagnent.",
        "在 3×3 靶格上玩井字棋。命中格子即可占领。三连成线者胜。")
    add("play.rules.ticTacToe.grid.title", "Das Raster", "La cuadrícula", "Het raster", "La grille", "棋盘")
    add("play.rules.ticTacToe.grid.body",
        "Neun Felder: Mitte ist Bull, die anderen acht sind feste Segmente. Das Raster siehst du im Spiel.",
        "Nueve casillas: el centro es bull; las otras ocho son segmentos fijos. La cuadrícula se muestra al jugar.",
        "Negen vakken: midden is bull; de andere acht zijn vaste segmenten. Het raster staat tijdens het spel.",
        "Neuf cases : le centre est bull ; les huit autres sont des segments fixes. La grille s'affiche en jeu.",
        "九格：中心为牛眼；其余八格为固定分区。对局时显示具体棋盘。")
    add("play.rules.ticTacToe.turns.title", "Züge", "Turnos", "Beurten", "Tours", "回合")
    add("play.rules.ticTacToe.turns.body",
        "Spieler wechseln sich mit drei Darts ab. Erster Treffer auf freier Zelle beansprucht sie. Belegte Zellen zählen nicht.",
        "Turnos alternos de tres dardos. El primer acierto en celda libre la reclama. Celdas tomadas no cuentan.",
        "Spelers wisselen beurten van drie pijlen. Eerste hit op open cel claimt hem. Bezette cellen doen niets.",
        "Tours alternés de trois fléchettes. Premier hit sur case libre la prend. Cases prises ne comptent pas.",
        "玩家交替三镖回合。首次命中空格子即占领。已占格子无效。")
    add("play.rules.ticTacToe.winning.title", "Sieg", "Victoria", "Winnen", "Victoire", "获胜")
    add("play.rules.ticTacToe.winning.body",
        "Drei beanspruchte Felder in einer Reihe — waagerecht, senkrecht oder diagonal — gewinnen. Volles Raster ohne Linie ist Remis.",
        "Tres celdas en línea — horizontal, vertical o diagonal — ganan. Tablero lleno sin línea es empate.",
        "Drie geclaimde cellen op een rij — horizontaal, verticaal of diagonaal — winnen. Vol bord zonder lijn is gelijkspel.",
        "Trois cases alignées — horizontal, vertical ou diagonal — gagnent. Grille pleine sans ligne : nul.",
        "三个占领格连成一线——横、竖或斜——即胜。九格满而无线则为平局。")
    add("play.ticTacToe.cellOpenAccessibilityFormat",
        "Feld %d, frei, Ziel %@",
        "Celda %d, libre, objetivo %@",
        "Cel %d, open, doel %@",
        "Case %d, libre, cible %@",
        "格子 %d，空，目标 %@")
    add("play.ticTacToe.cellClaimedAccessibilityFormat",
        "Feld %d, Ziel %@, beansprucht von %@",
        "Celda %d, objetivo %@, reclamada por %@",
        "Cel %d, doel %@, geclaimd door %@",
        "Case %d, cible %@, prise par %@",
        "格子 %d，目标 %@，由 %@ 占领")
    add("ticTacToe.error.sessionMissing", c("de", "sessionMissing"), c("es", "sessionMissing"), c("nl", "sessionMissing"), c("fr", "sessionMissing"), c("zh-Hans", "sessionMissing"))
    add("ticTacToe.error.invalidTurn", c("de", "invalidRecord"), c("es", "invalidRecord"), c("nl", "invalidRecord"), c("fr", "invalidRecord"), c("zh-Hans", "invalidRecord"))
    add("snooker.error.sessionMissing", c("de", "sessionMissing"), c("es", "sessionMissing"), c("nl", "sessionMissing"), c("fr", "sessionMissing"), c("zh-Hans", "sessionMissing"))
    add("snooker.error.invalidDart",
        "Dieser Dart konnte nicht gespeichert werden.",
        "No se pudo registrar ese dardo.",
        "Kon die pijl niet registreren.",
        "Impossible d'enregistrer cette fléchette.",
        "无法记录该镖。")
    add("play.snooker.pad.lockedSegmentHint",
        "Nur Segment %d zählt",
        "Solo el segmento %d puntúa",
        "Alleen segment %d telt",
        "Seul le segment %d compte",
        "只有 %d 分区计分")
    add("play.snooker.pad.nominationHint",
        "Farbe wählen, dann werfen",
        "Elige un color y lanza",
        "Kies een kleur en gooi",
        "Choisis une couleur, puis lance",
        "选择彩球后投掷")
    add("play.snooker.pad.redHint",
        "Verfügbares Rot treffen (1–15)",
        "Acerta un rojo disponible (1–15)",
        "Raak een beschikbaar rood (1–15)",
        "Touche un rouge disponible (1–15)",
        "命中可用红球（1–15）")


def merge_into_locale_data() -> None:
    build_specific()
    for locale in LOCALES:
        target = DATA_DIR / f"{locale}_gameplay_modes.json"
        data = json.loads(target.read_text(encoding="utf-8"))
        merged = 0
        for key, by_locale in SPECIFIC.items():
            if locale in by_locale:
                data[key] = by_locale[locale]
                merged += 1
        data = dict(sorted(data.items()))
        target.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"Updated {target.name} (+{merged} keys, {len(data)} total)")


def verify_complete() -> None:
    import re

    en_path = ROOT / "Resources/en.lproj/GameplayModes.strings"
    text = en_path.read_text(encoding="utf-8")
    entries = [(m.group(1), m.group(2)) for m in re.finditer(r'"([^"\\]+)"\s*=\s*"([^"]*)"\s*;', text)]
    for locale in LOCALES:
        data = json.loads((DATA_DIR / f"{locale}_gameplay_modes.json").read_text())
        missing = [key for key, _ in entries if key not in data]
        if missing:
            raise SystemExit(f"{locale} still missing {len(missing)} keys: {missing[:5]}…")


def main() -> None:
    merge_into_locale_data()
    verify_complete()
    subprocess.run([sys.executable, str(ROOT / "Scripts/generate_gameplay_modes_l10n.py")], check=True)


if __name__ == "__main__":
    main()
