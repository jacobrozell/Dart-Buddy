#!/usr/bin/env python3
"""Backfill party-mode error/validation strings into locale_data JSON for Localizable.strings."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "Scripts/locale_data"
LOCALES = ("de", "es", "nl", "fr", "zh-Hans", "it")

TRANSLATIONS: dict[str, dict[str, str]] = {
    "de": {
        "error.match.blindKiller.alreadyEliminated": "Dieser Spieler ist bereits ausgeschieden.",
        "error.match.blindKiller.assignmentsMissing": "Geheimzahlen für Blinder Killer konnten nicht zugewiesen werden.",
        "error.match.followTheLeader.alreadyEliminated": "Dieser Spieler ist bereits ausgeschieden.",
        "error.match.followTheLeader.noTarget": "Für diese Aufnahme ist kein Ziel gesetzt.",
        "error.match.followTheLeader.openingRequiresScoringDart": "Der Eröffnungswurf muss die Scheibe treffen.",
        "error.match.followTheLeader.passUnavailable": "Passen ist gerade nicht verfügbar.",
        "error.match.followTheLeader.usePassOrThrow": "Wähle Passen oder Werfen, bevor du Darts eingibst.",
        "error.match.loop.alreadyEliminated": "Dieser Spieler ist bereits ausgeschieden.",
        "error.match.loop.invalidWireTarget": "Dieses Drahtziel passt nicht zum eingegebenen Dart.",
        "error.match.loop.noTarget": "Für diese Aufnahme ist kein Drahtziel gesetzt.",
        "error.match.loop.openingRequiresScoringDart": "Der Eröffnungswurf muss die Scheibe treffen.",
        "error.match.loop.passUnavailable": "Passen ist gerade nicht verfügbar.",
        "error.match.loop.usePassOrThrow": "Wähle Passen oder Werfen, bevor du Darts eingibst.",
        "error.match.mode.blindKillerUnavailable": "Blinder-Killer-Status für diese Partie nicht verfügbar.",
        "error.match.mode.followTheLeaderUnavailable": "Folge-dem-Führenden-Status für diese Partie nicht verfügbar.",
        "error.match.mode.loopUnavailable": "Schleife-Status für diese Partie nicht verfügbar.",
        "error.match.mode.prisonerUnavailable": "Gefangener-Status für diese Partie nicht verfügbar.",
        "error.prisoner.tooManyDarts": "Du kannst nicht mehr Darts werfen, als dein Pool in dieser Aufnahme erlaubt.",
        "setup.validation.blindKillerMinimumPlayers": "Blinder Killer braucht mindestens drei Spieler.",
        "setup.validation.followTheLeaderMinimumPlayers": "Folge dem Führenden braucht mindestens zwei Spieler.",
        "setup.validation.loopMinimumPlayers": "Schleife braucht mindestens zwei Spieler.",
        "setup.validation.prisonerMinimumPlayers": "Gefangener braucht mindestens zwei Spieler.",
    },
    "es": {
        "error.match.blindKiller.alreadyEliminated": "Ese jugador ya ha sido eliminado.",
        "error.match.blindKiller.assignmentsMissing": "No se pudieron asignar los números secretos de Killer ciego.",
        "error.match.followTheLeader.alreadyEliminated": "Ese jugador ya ha sido eliminado.",
        "error.match.followTheLeader.noTarget": "No hay objetivo para esta visita.",
        "error.match.followTheLeader.openingRequiresScoringDart": "El lanzamiento inicial debe impactar en el tablero.",
        "error.match.followTheLeader.passUnavailable": "Pasar no está disponible ahora.",
        "error.match.followTheLeader.usePassOrThrow": "Elige pasar o lanzar antes de introducir dardos.",
        "error.match.loop.alreadyEliminated": "Ese jugador ya ha sido eliminado.",
        "error.match.loop.invalidWireTarget": "Ese alambre no coincide con el dardo introducido.",
        "error.match.loop.noTarget": "No hay alambre objetivo para esta visita.",
        "error.match.loop.openingRequiresScoringDart": "El lanzamiento inicial debe impactar en el tablero.",
        "error.match.loop.passUnavailable": "Pasar no está disponible ahora.",
        "error.match.loop.usePassOrThrow": "Elige pasar o lanzar antes de introducir dardos.",
        "error.match.mode.blindKillerUnavailable": "El estado de Killer ciego no está disponible para esta partida.",
        "error.match.mode.followTheLeaderUnavailable": "El estado de Sigue al líder no está disponible para esta partida.",
        "error.match.mode.loopUnavailable": "El estado de Bucle no está disponible para esta partida.",
        "error.match.mode.prisonerUnavailable": "El estado de Prisionero no está disponible para esta partida.",
        "error.prisoner.tooManyDarts": "No puedes lanzar más dardos de los que permite tu reserva en esta visita.",
        "setup.validation.blindKillerMinimumPlayers": "Killer ciego necesita al menos tres jugadores.",
        "setup.validation.followTheLeaderMinimumPlayers": "Sigue al líder necesita al menos dos jugadores.",
        "setup.validation.loopMinimumPlayers": "Bucle necesita al menos dos jugadores.",
        "setup.validation.prisonerMinimumPlayers": "Prisionero necesita al menos dos jugadores.",
    },
    "nl": {
        "error.match.blindKiller.alreadyEliminated": "Die speler is al geëlimineerd.",
        "error.match.blindKiller.assignmentsMissing": "Geheime nummers voor Blinde killer konden niet worden toegewezen.",
        "error.match.followTheLeader.alreadyEliminated": "Die speler is al geëlimineerd.",
        "error.match.followTheLeader.noTarget": "Geen doel ingesteld voor deze visit.",
        "error.match.followTheLeader.openingRequiresScoringDart": "De openingsworp moet het bord raken.",
        "error.match.followTheLeader.passUnavailable": "Passen is nu niet beschikbaar.",
        "error.match.followTheLeader.usePassOrThrow": "Kies passen of gooien voordat je pijlen invoert.",
        "error.match.loop.alreadyEliminated": "Die speler is al geëlimineerd.",
        "error.match.loop.invalidWireTarget": "Dat drahtdoel komt niet overeen met de ingevoerde pijl.",
        "error.match.loop.noTarget": "Geen drahtdoel ingesteld voor deze visit.",
        "error.match.loop.openingRequiresScoringDart": "De openingsworp moet het bord raken.",
        "error.match.loop.passUnavailable": "Passen is nu niet beschikbaar.",
        "error.match.loop.usePassOrThrow": "Kies passen of gooien voordat je pijlen invoert.",
        "error.match.mode.blindKillerUnavailable": "Blinde-killer-status is niet beschikbaar voor deze wedstrijd.",
        "error.match.mode.followTheLeaderUnavailable": "Volg-de-leider-status is niet beschikbaar voor deze wedstrijd.",
        "error.match.mode.loopUnavailable": "Loop-status is niet beschikbaar voor deze wedstrijd.",
        "error.match.mode.prisonerUnavailable": "Gevangene-status is niet beschikbaar voor deze wedstrijd.",
        "error.prisoner.tooManyDarts": "Je kunt niet meer pijlen gooien dan je pool deze visit toestaat.",
        "setup.validation.blindKillerMinimumPlayers": "Blinde killer heeft minstens drie spelers nodig.",
        "setup.validation.followTheLeaderMinimumPlayers": "Volg de leider heeft minstens twee spelers nodig.",
        "setup.validation.loopMinimumPlayers": "Loop heeft minstens twee spelers nodig.",
        "setup.validation.prisonerMinimumPlayers": "Gevangene heeft minstens twee spelers nodig.",
    },
    "fr": {
        "error.match.blindKiller.alreadyEliminated": "Ce joueur est déjà éliminé.",
        "error.match.blindKiller.assignmentsMissing": "Les numéros secrets de Killer aveugle n'ont pas pu être attribués.",
        "error.match.followTheLeader.alreadyEliminated": "Ce joueur est déjà éliminé.",
        "error.match.followTheLeader.noTarget": "Aucune cible n'est définie pour cette visite.",
        "error.match.followTheLeader.openingRequiresScoringDart": "Le lancer d'ouverture doit toucher la cible.",
        "error.match.followTheLeader.passUnavailable": "Passer n'est pas disponible pour le moment.",
        "error.match.followTheLeader.usePassOrThrow": "Choisissez passer ou lancer avant de saisir les fléchettes.",
        "error.match.loop.alreadyEliminated": "Ce joueur est déjà éliminé.",
        "error.match.loop.invalidWireTarget": "Cette cible fil ne correspond pas à la fléchette saisie.",
        "error.match.loop.noTarget": "Aucune cible fil n'est définie pour cette visite.",
        "error.match.loop.openingRequiresScoringDart": "Le lancer d'ouverture doit toucher la cible.",
        "error.match.loop.passUnavailable": "Passer n'est pas disponible pour le moment.",
        "error.match.loop.usePassOrThrow": "Choisissez passer ou lancer avant de saisir les fléchettes.",
        "error.match.mode.blindKillerUnavailable": "L'état Killer aveugle n'est pas disponible pour cette partie.",
        "error.match.mode.followTheLeaderUnavailable": "L'état Imiter le leader n'est pas disponible pour cette partie.",
        "error.match.mode.loopUnavailable": "L'état Boucle n'est pas disponible pour cette partie.",
        "error.match.mode.prisonerUnavailable": "L'état Prisonnier n'est pas disponible pour cette partie.",
        "error.prisoner.tooManyDarts": "Vous ne pouvez pas lancer plus de fléchettes que votre réserve ne le permet pour cette visite.",
        "setup.validation.blindKillerMinimumPlayers": "Killer aveugle demande au moins trois joueurs.",
        "setup.validation.followTheLeaderMinimumPlayers": "Imiter le leader demande au moins deux joueurs.",
        "setup.validation.loopMinimumPlayers": "Boucle demande au moins deux joueurs.",
        "setup.validation.prisonerMinimumPlayers": "Prisonnier demande au moins deux joueurs.",
    },
    "zh-Hans": {
        "error.match.blindKiller.alreadyEliminated": "该玩家已被淘汰。",
        "error.match.blindKiller.assignmentsMissing": "无法分配盲杀的秘密数字。",
        "error.match.followTheLeader.alreadyEliminated": "该玩家已被淘汰。",
        "error.match.followTheLeader.noTarget": "本回合未设置目标。",
        "error.match.followTheLeader.openingRequiresScoringDart": "开局投掷必须命中镖盘。",
        "error.match.followTheLeader.passUnavailable": "当前无法跳过回合。",
        "error.match.followTheLeader.usePassOrThrow": "录入飞镖前请选择跳过或投掷。",
        "error.match.loop.alreadyEliminated": "该玩家已被淘汰。",
        "error.match.loop.invalidWireTarget": "该线区目标与录入的飞镖不匹配。",
        "error.match.loop.noTarget": "本回合未设置线区目标。",
        "error.match.loop.openingRequiresScoringDart": "开局投掷必须命中镖盘。",
        "error.match.loop.passUnavailable": "当前无法跳过回合。",
        "error.match.loop.usePassOrThrow": "录入飞镖前请选择跳过或投掷。",
        "error.match.mode.blindKillerUnavailable": "此比赛无法加载盲杀状态。",
        "error.match.mode.followTheLeaderUnavailable": "此比赛无法加载跟随领导者状态。",
        "error.match.mode.loopUnavailable": "此比赛无法加载循环状态。",
        "error.match.mode.prisonerUnavailable": "此比赛无法加载囚徒状态。",
        "error.prisoner.tooManyDarts": "本回合投掷数不能超过镖池允许的数量。",
        "setup.validation.blindKillerMinimumPlayers": "盲杀至少需要三名玩家。",
        "setup.validation.followTheLeaderMinimumPlayers": "跟随领导者至少需要两名玩家。",
        "setup.validation.loopMinimumPlayers": "循环至少需要两名玩家。",
        "setup.validation.prisonerMinimumPlayers": "囚徒至少需要两名玩家。",
    },
    "it": {
        "error.match.blindKiller.alreadyEliminated": "Quel giocatore è già stato eliminato.",
        "error.match.blindKiller.assignmentsMissing": "Impossibile assegnare i numeri segreti di Killer cieco.",
        "error.match.followTheLeader.alreadyEliminated": "Quel giocatore è già stato eliminato.",
        "error.match.followTheLeader.noTarget": "Nessun obiettivo impostato per questa visita.",
        "error.match.followTheLeader.openingRequiresScoringDart": "Il lancio iniziale deve colpire il bersaglio.",
        "error.match.followTheLeader.passUnavailable": "Passare non è disponibile in questo momento.",
        "error.match.followTheLeader.usePassOrThrow": "Scegli passare o lanciare prima di inserire le freccette.",
        "error.match.loop.alreadyEliminated": "Quel giocatore è già stato eliminato.",
        "error.match.loop.invalidWireTarget": "Quel filo obiettivo non corrisponde alla freccetta inserita.",
        "error.match.loop.noTarget": "Nessun filo obiettivo impostato per questa visita.",
        "error.match.loop.openingRequiresScoringDart": "Il lancio iniziale deve colpire il bersaglio.",
        "error.match.loop.passUnavailable": "Passare non è disponibile in questo momento.",
        "error.match.loop.usePassOrThrow": "Scegli passare o lanciare prima di inserire le freccette.",
        "error.match.mode.blindKillerUnavailable": "Stato Killer cieco non disponibile per questa partita.",
        "error.match.mode.followTheLeaderUnavailable": "Stato Segui il leader non disponibile per questa partita.",
        "error.match.mode.loopUnavailable": "Stato Anello non disponibile per questa partita.",
        "error.match.mode.prisonerUnavailable": "Stato Prigioniero non disponibile per questa partita.",
        "error.prisoner.tooManyDarts": "Non puoi lanciare più freccette di quanto consente la tua riserva in questa visita.",
        "setup.validation.blindKillerMinimumPlayers": "Killer cieco richiede almeno tre giocatori.",
        "setup.validation.followTheLeaderMinimumPlayers": "Segui il leader richiede almeno due giocatori.",
        "setup.validation.loopMinimumPlayers": "Anello richiede almeno due giocatori.",
        "setup.validation.prisonerMinimumPlayers": "Prigioniero richiede almeno due giocatori.",
    },
}


def merge() -> None:
    for locale in LOCALES:
        path = DATA_DIR / f"{locale}.json"
        data = json.loads(path.read_text(encoding="utf-8"))
        updates = TRANSLATIONS[locale]
        for key, value in updates.items():
            data[key] = value
        path.write_text(json.dumps(dict(sorted(data.items())), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"Updated {path.name} (+{len(updates)} keys)")


def main() -> None:
    merge()
    subprocess.run([sys.executable, str(ROOT / "Scripts/generate_localizable.py")], check=True)


if __name__ == "__main__":
    main()
