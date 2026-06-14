# Estimated release registry

Human-readable view of [`estimated-releases.json`](estimated-releases.json). **Edit the JSON first**, then run:

```bash
python3 Scripts/sync_estimated_release_tags.py
```

Policy: [`release-tagging.md`](release-tagging.md) · Train narrative: [`ongoing-release-plan.md`](ongoing-release-plan.md)

**Last reviewed:** 2026-06-13

---

## Game modes (catalog)

| Catalog id | Mode | Code on `dev` | **Estimated release** |
|------------|------|---------------|----------------------|
| `standard.x01` | X01 | Shipped | **1.0** |
| `standard.cricket` | Cricket | Shipped | **1.0** |
| `standard.americanCricket` | American Cricket | Shipped | **1.3** |
| `party.baseball` | Baseball | Shipped | **1.1** |
| `party.killer` | Killer | Shipped | **1.1** |
| `party.shanghai` | Shanghai | Shipped | **1.1** |
| `party.mickeyMouse` | Mickey Mouse | Shipped | **1.3** |
| `party.mulligan` | Mulligan | Shipped | **1.3** |
| `party.englishCricket` | English Cricket | Shipped | **1.3** |
| `party.knockout` | Knockout | Shipped | **1.3** |
| `party.suddenDeath` | Sudden Death | Shipped | **1.3** |
| `party.fiftyOneByFives` | 51 By 5's | Shipped | **1.3** |
| `party.golf` | Golf | Shipped | **1.3** |
| `party.football` | Football | Shipped | **1.3** |
| `party.grandNational` | Grand National | Shipped | **1.3** |
| `party.hareAndHounds` | Hare and Hounds | Shipped | **1.3** |
| `party.fleet` | Fleet | Shipped | **1.4** |
| `coop.raid` | Raid | Shipped | **1.4** |
| `practice.aroundTheClock` | Around the Clock | Shipped | **1.4** |
| `practice.aroundTheClock180` | 180 ATC | Shipped | **1.4** |
| `practice.chaseTheDragon` | Chase the Dragon | Shipped | **1.4** |
| `practice.nineLives` | Nine Lives | Shipped | **1.4** |
| `party.blindKiller` | Blind Killer | Planned | **TBD** |
| `party.followTheLeader` | Follow the Leader | Planned | **TBD** |
| `party.loop` | Loop | Planned | **TBD** |
| `party.prisoner` | Prisoner | Planned | **TBD** |
| `party.scam` | Scam | Planned | **TBD** |
| `party.snooker` | Snooker | Planned | **TBD** |
| `party.ticTacToe` | Tic-Tac-Toe | Planned | **TBD** |
| `coop.cerberus` | Cerberus | Planned | **2.0+** |
| `coop.theVault` | The Vault | Planned | **2.0+** |
| `coop.clearTheBoard` | Clear the Board | Planned | **2.0+** |
| `practice.bobs27` | Bob's 27 | Planned | **TBD** |
| `practice.halveIt` | Halve-It | Planned | **TBD** |

---

## Platform & feature specs

| Spec | **Estimated release** | Notes |
|------|----------------------|-------|
| Play / setup / match core | **1.0** | `PlayHomeSpec`, `SetupFlowSpec`, `MatchSpec`, … |
| Visual dartboard | **1.0** | |
| Preset + custom bots | **1.0** | |
| Training Partner | **1.2** | |
| Player export (DBPE) | **1.2** | |
| Localization (store) | **1.2** | Strings bundled on `dev` now |
| Modes tab | **1.3** | |
| Match forfeit (all modes) | **1.3** | |
| Party Pack II modes | **1.3** | See catalog table |
| Co-op + practice wave | **1.4** | Raid, Fleet, ATC, … |
| App Intents / widgets | **1.4** | |
| Deep links | **dev-only** | Code ships; not marketed until chosen |
| Vision auto-scoring | **dev-only** | Flagged |
| Achievements + badges | **2.0** | Domain on `dev`; UI TBD |
| Campaign / daily challenge / online / Watch | **2.0+** | |

---

## By store release (rollup)

| Release | What users get |
|---------|----------------|
| **1.0** | X01 + Cricket · 4 tabs · preset + custom bots · English listing |
| **1.1** | + Baseball, Killer, Shanghai |
| **1.2** | + Training Partner · export · localized store listings |
| **1.3** | + Modes tab · American Cricket + remaining party modes (device QA) |
| **1.4** | + Raid/Fleet · practice drills · App Intents |
| **2.0** | + Achievements UI (primary growth bet) |

---

## Decision log

| Date | Change | Rationale |
|------|--------|-----------|
| 2026-06-13 | Initial registry | Separate `dev` completeness from store train |

Edit decisions here and in JSON when plans change.
