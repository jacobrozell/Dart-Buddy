# Game mode specifications

Authoritative specs for each catalog game mode, split by implementation status.

**Promotion path:** [`FutureIdeas/`](../../FutureIdeas/) (assessment only) → [`planned/`](planned/) (rules spec) → [`implemented/`](implemented/) + [`GameModeCatalog.swift`](../../Features/Modes/GameModeCatalog.swift) when the engine ships. Once a mode has a planned spec, do not edit `FutureIdeas/` for rules — link to the spec instead.

| Folder | Status | When to edit here |
|--------|--------|------------------|
| [`implemented/`](implemented/) | Engine + gameplay UI shipped (`GameModeCatalog.status == .shipped`) | Behavior changes, localization, How to Play updates |
| [`planned/`](planned/) | Catalog stub only (`status == .planned`) | Rules design before `MatchType` + engine land |

## Promotion workflow

When a planned mode ships:

1. Move `planned/{Mode}GameSpec.md` → `implemented/` (or `game-modes/implemented/CricketSpec.md` naming for standard modes).
2. Update **Status** / **Shipped in app** rows in the spec; fill **Localization** **Exists** column.
3. Update [`docs/feature-inventory.md`](../../docs/feature-inventory.md) and [`specs/README.md`](../README.md).
4. Register `GameRulesCatalog` + `play.rules.{mode}.*` keys per spec § Localization.
5. If the mode persists setup chips: register reset per [`DeleteAllDataSpec.md`](../DeleteAllDataSpec.md) §6.2 and §7.
6. Set **Estimated release** in [`estimated-releases.json`](../../docs/release/estimated-releases.json) and run `Scripts/sync_estimated_release_tags.py`.
7. **Match forfeit (automatic via shared chrome):** per [`MatchForfeitSpec.md`](../MatchForfeitSpec.md) §6.7 — add `MatchForfeitStandingsRegistry` case, `MatchPlaySessionHost` on ViewModel, `.matchLifecycleChrome` on screen; run `everyShippedMatchTypeHasForfeitStandingsRegistered`.

Catalog source: [`Features/Modes/GameModeCatalog.swift`](../../Features/Modes/GameModeCatalog.swift).

### Cross-mode supplements

| Doc | Covers |
|-----|--------|
| [`CoopPvEModesSpec.md`](../CoopPvEModesSpec.md) | Cross-mode contract + **§13 progress**; UI §7, Learn §8, a11y §9, light/dark §7.5 |
| [`InVisitSequenceProgressionSupplement.md`](InVisitSequenceProgressionSupplement.md) | Multi-target visits (Around the Clock, Nine Lives, Hare and Hounds, Chase the Dragon) — engine + `DartNumberPad` projection |

## Implemented (22)

- [`X01GameSpec.md`](implemented/X01GameSpec.md)
- [`CricketSpec.md`](implemented/CricketSpec.md)
- [`AmericanCricketGameSpec.md`](implemented/AmericanCricketGameSpec.md)
- [`BaseballGameSpec.md`](implemented/BaseballGameSpec.md) · [`BaseballModeDeferredWorkPlan.md`](implemented/BaseballModeDeferredWorkPlan.md)
- [`KillerGameSpec.md`](implemented/KillerGameSpec.md)
- [`ShanghaiGameSpec.md`](implemented/ShanghaiGameSpec.md)
- [`MickeyMouseGameSpec.md`](implemented/MickeyMouseGameSpec.md)
- [`MulliganGameSpec.md`](implemented/MulliganGameSpec.md)
- [`EnglishCricketGameSpec.md`](implemented/EnglishCricketGameSpec.md)
- [`KnockoutGameSpec.md`](implemented/KnockoutGameSpec.md)
- [`SuddenDeathGameSpec.md`](implemented/SuddenDeathGameSpec.md)
- [`FiftyOneByFivesGameSpec.md`](implemented/FiftyOneByFivesGameSpec.md)
- [`GolfGameSpec.md`](implemented/GolfGameSpec.md)
- [`FootballGameSpec.md`](implemented/FootballGameSpec.md)
- [`GrandNationalGameSpec.md`](implemented/GrandNationalGameSpec.md)
- [`HareAndHoundsGameSpec.md`](implemented/HareAndHoundsGameSpec.md)
- [`FleetGameSpec.md`](implemented/FleetGameSpec.md)
- [`RaidGameSpec.md`](implemented/RaidGameSpec.md)
- [`AroundTheClockGameSpec.md`](implemented/AroundTheClockGameSpec.md)
- [`AroundTheClock180GameSpec.md`](implemented/AroundTheClock180GameSpec.md)
- [`ChaseTheDragonGameSpec.md`](implemented/ChaseTheDragonGameSpec.md)
- [`NineLivesGameSpec.md`](implemented/NineLivesGameSpec.md)

## Planned (12 catalog stubs + R&D)

See [`planned/`](planned/) — 12 catalog stubs (Blind Killer, Follow the Leader, Loop, Prisoner, Scam, Snooker, Tic-Tac-Toe, Cerberus, The Vault, Clear the Board, Bob's 27, Halve-It), Call & Hit, Guided Practice, and **17 custom** modes below.

### Custom / co-op (brainstorm → spec)

| Doc | Covers |
|-----|--------|
| [`FutureIdeas/custom-games-brainstorm.md`](../../FutureIdeas/custom-games-brainstorm.md) | R&D index; trim pass + core roster |
| **Flagship (specced)** | |
| [`RaidGameSpec.md`](implemented/RaidGameSpec.md) | Co-op PvE boss — Shield → Expose → Enrage |
| [`FleetGameSpec.md`](implemented/FleetGameSpec.md) | Battleship — hidden fleet, call-and-throw hunt |
| [`ClearTheBoardGameSpec.md`](planned/ClearTheBoardGameSpec.md) | Ring-cell sweep — co-op + Team vs Team |
| **Tier S — brand** | |
| [`EchoGameSpec.md`](planned/EchoGameSpec.md) | Voice-only duel — Hit/Miss verify, lives |
| [`RemixNightGameSpec.md`](planned/RemixNightGameSpec.md) | Meta-mode — 3 random shipped legs per evening |
| [`TournamentSpec.md`](../TournamentSpec.md) | **Platform** — brackets, hub, formats; Remix = preset |
| **Tier A — next build** | |
| [`TheVaultGameSpec.md`](planned/TheVaultGameSpec.md) | Co-op heist — combo locks + alarm |
| [`WhisperCricketGameSpec.md`](planned/WhisperCricketGameSpec.md) | Cricket with hidden marks until close |
| [`MirrorMatchGameSpec.md`](planned/MirrorMatchGameSpec.md) | Ghost bot from player's own history |
| [`DartleGameSpec.md`](planned/DartleGameSpec.md) | Daily 6-segment puzzle (date-seeded) |
| [`CerberusGameSpec.md`](planned/CerberusGameSpec.md) | Co-op tri-head boss with role assignment |
| [`ColdCallGameSpec.md`](planned/ColdCallGameSpec.md) | Hot/cold TTS — find secret segment |
| **Tier B — sports** | |
| [`EndSheetGameSpec.md`](planned/EndSheetGameSpec.md) | Curling — 8 ends, guards + takeouts at house |
| [`CreaseGameSpec.md`](planned/CreaseGameSpec.md) | Hockey shootout — blocked doubles |
| [`PallinoGameSpec.md`](planned/PallinoGameSpec.md) | Bocce — pallino callout, closest stone |
| **Tier C — party spice** | |
| [`BuddyRelayGameSpec.md`](planned/BuddyRelayGameSpec.md) | Caller / thrower / judges — 3+ roles |
| [`ContractKillerGameSpec.md`](planned/ContractKillerGameSpec.md) | Killer + hidden contracts |
| [`DoubleBluffGameSpec.md`](planned/DoubleBluffGameSpec.md) | Simultaneous commit — match or clash |
| [`PressGameSpec.md`](planned/PressGameSpec.md) | Push-your-luck ladder on one segment |
| [`RollTwentyGameSpec.md`](planned/RollTwentyGameSpec.md) | D20 roll → hit that segment — party dice target |

### Call & Hit spec bundle
| Doc | Covers |
|-----|--------|
| [`CallAndHitGameSpec.md`](planned/CallAndHitGameSpec.md) | Rules, setup presets, engine, history |
| [`VoiceDrillUITemplateSpec.md`](planned/VoiceDrillUITemplateSpec.md) | Template J UI shell |
| [`CallAndHitStatsSupplement.md`](planned/CallAndHitStatsSupplement.md) | `practiceAccuracy` stat kind |
| [`CallAndHitDataSchemaSupplement.md`](planned/CallAndHitDataSchemaSupplement.md) | SwiftData / migration |
| [`CalloutVoicesSpec.md`](../CalloutVoicesSpec.md) | TTS voice catalog |

### Guided Play (accessibility — WIP R&D)
| Doc | Covers |
|-----|--------|
| [`FutureIdeas/guided-play-blind-darts.md`](../FutureIdeas/guided-play-blind-darts.md) | **Start here** — R&D brief, dependencies, deferred decisions |
| [`GuidedPlayAccessibilitySpec.md`](../GuidedPlayAccessibilitySpec.md) | Platform draft |
| [`GuidedPlayCompanionSpec.md`](../GuidedPlayCompanionSpec.md) | Sighted guide verifier UI draft |
| [`GuidedPracticeSpec.md`](planned/GuidedPracticeSpec.md) | Practice mode draft |

### Solo practice platform (shared)
| Doc | Covers |
|-----|--------|
| [`SoloPracticeModesSpec.md`](../SoloPracticeModesSpec.md) | Cross-mode contract for all solo-only drills |
| [`SoloPracticeMatchSummarySupplement.md`](../SoloPracticeMatchSummarySupplement.md) | Summary screen without winner ceremony |
| [`SoloPracticeCatalogStubGuide.md`](planned/SoloPracticeCatalogStubGuide.md) | Catalog row copy-paste + promotion |
