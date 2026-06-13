# Custom Games — Brainstorm

**Status:** R&D / brainstorm — **not scheduled for implementation.**  
**Purpose:** Capture Dart Buddy–exclusive game ideas that lean on app capabilities other scorekeepers cannot replicate (voice, hidden state, asymmetric roles, adaptive bots, session memory, campaign orchestration).

**Not the same as:** Traditional pub formats indexed in [`additional-game-modes.md`](additional-game-modes.md) (24 planned catalog entries with specs in [`specs/game-modes/planned/`](../specs/game-modes/planned/)). Custom games here are **net-new** product concepts; promote to `specs/game-modes/planned/` only after rules are locked.

**Related foundations:**
- Voice / TTS — [`specs/CalloutVoicesSpec.md`](../specs/CalloutVoicesSpec.md), [`specs/game-modes/planned/CallAndHitGameSpec.md`](../specs/game-modes/planned/CallAndHitGameSpec.md)
- Guided / blind play — [`guided-play-blind-darts.md`](guided-play-blind-darts.md), [`specs/GuidedPlayCompanionSpec.md`](../specs/GuidedPlayCompanionSpec.md)
- Custom bots + Activity history — [`specs/CustomBotSpec.md`](../specs/CustomBotSpec.md), [`specs/HistorySpec.md`](../specs/HistorySpec.md)
- Campaign orchestration — [`campaign-mode.md`](campaign-mode.md), [`specs/CampaignSpec.md`](../specs/CampaignSpec.md)
- UI templates — [`Features/Modes/GameModeCatalog.swift`](../Features/Modes/GameModeCatalog.swift) (`GameplayUITemplate`)
- Visual board input — [`visual-dartboard-input.md`](visual-dartboard-input.md)

---

## Positioning

> **Dart Buddy isn't just more games — it's games that use the phone as a caller, a blindfold, a ghost opponent, and a judge.**

### Moat criteria

A custom game should require at least one capability a chalkboard or generic pad app cannot offer:

| Capability | Example use |
|------------|-------------|
| **Audio / TTS** | Target callouts, hands-free at the oche |
| **Hidden per-player state** | Secret marks, contracts, bluffing |
| **Asymmetric roles** | Caller / thrower / judge on one match |
| **Adaptive opponents** | Ghost bot built from player's own stats |
| **Session memory** | Difficulty ramps from live performance |
| **Multi-engine orchestration** | Remix rounds across existing modes |
| **Campaign scripting** | Multi-leg gauntlets without menu hops |
| **Accessibility** | Companion verifier, VoiceOver-first flows |

---

## Game ideas

### 1. Echo (voice-only duel)

**Authoritative spec:** [`specs/game-modes/planned/EchoGameSpec.md`](../specs/game-modes/planned/EchoGameSpec.md) — **Promoted**; do not edit rules here.

**Hook:** Both players close their eyes (or turn away). The app is the only scoreboard.

| | |
|--|--|
| **Players** | 2+ |
| **Section** | Party |
| **Template** | Voice drill (new) or `livesElimination` variant |

**Rules (sketch):**
- App calls a target via TTS (e.g. "Double 16").
- Player throws; opponent taps **Hit / Miss** on their phone (honor system), or a sighted friend confirms via Guided Play Companion.
- Wrong call costs a life; three lives; last standing wins.

**Why exclusive:** Pairs with Guided Play + Call & Hit engine. No major dart app treats auditory darts as a competitive mode.

**Dependencies:** Callout voices, Companion verifier UI, optional Guided Play profile.

---

### 2. Whisper Cricket

**Authoritative spec:** [`specs/game-modes/planned/WhisperCricketGameSpec.md`](../specs/game-modes/planned/WhisperCricketGameSpec.md) — **Promoted**.

**Hook:** Cricket where **your marks are secret** until someone closes a number.

| | |
|--|--|
| **Players** | 2+ |
| **Section** | Party |
| **Template** | `markBoard` + hidden state layer |

**Rules (sketch):**
- Each player's hits on 20→15 + bull are hidden on their device.
- When you "close" a number, it flips public and points apply normally (standard or Cut Throat).
- Opponents cannot see whether you are stacking marks or ignoring a wedge until closure.

**Why exclusive:** Per-player hidden UI + reveal animation. Impossible on a shared chalkboard.

**Dependencies:** Cricket engine, per-participant visibility model in match state.

---

### 3. Mirror Match (ghost sparring)

**Authoritative spec:** [`specs/game-modes/planned/MirrorMatchGameSpec.md`](../specs/game-modes/planned/MirrorMatchGameSpec.md) — **Promoted**.

**Hook:** Fight **yesterday's you** — not a preset difficulty tier.

| | |
|--|--|
| **Players** | 1 human vs 1 ghost bot |
| **Section** | Practice (or Journey stage) |
| **Template** | `checkoutScore` / `markBoard` (mode-selected) |

**Rules (sketch):**
- App builds a bot from the player's last N X01 or Cricket sessions (average, checkout %, wedge tendencies).
- Win condition: beat your ghost by N legs or reach a margin target.
- Post-match: "You improved checkout % by 4% vs your ghost."

**Why exclusive:** `CustomBotConfiguration`, skill profiles, and Activity history already exist — this is a product feature, not just a ruleset.

**Dependencies:** Stats aggregation, `BotParticipantFactory`, optional Journey integration.

---

### 4. Pressure Ladder (adaptive solo drill)

**Hook:** Difficulty **ramps when you're hot**, eases when you're cold.

| | |
|--|--|
| **Players** | 1 (solo) |
| **Section** | Practice |
| **Template** | `sequenceProgress` or `soloChallenge` |

**Rules (sketch):**
- Start at T20 × 3; hit → next target steps up (bull, then doubles rotation).
- Miss → step down or lose a "rung."
- Session ends at personal best height or time limit.
- Stats: highest rung, time on bull, weak-segment heatmap.

**Why exclusive:** Session analytics + solo practice platform. Most apps offer static Around the Clock only.

**Dependencies:** Solo practice platform ([`specs/SoloPracticeModesSpec.md`](../specs/SoloPracticeModesSpec.md)), new stat kind or extend `sequence`.

---

### 5. Buddy Relay (asymmetric roles)

**Authoritative spec:** [`specs/game-modes/planned/BuddyRelayGameSpec.md`](../specs/game-modes/planned/BuddyRelayGameSpec.md) — **Promoted**.

**Hook:** One **Caller**, one **Thrower**, rest are **Judges** — roles rotate each round.

| | |
|--|--|
| **Players** | 3+ |
| **Section** | Party |
| **Template** | `roleSplit` (new chrome) |

**Rules (sketch):**

| Role | Phone job |
|------|-----------|
| **Caller** | Sees target; speaks it (or TTS for Thrower) |
| **Thrower** | Phone face-down; only hears target |
| **Judges** | Tap segment landed; majority rules |

- Disagreement triggers a "challenge" re-throw.
- Rotate roles each round; first to N successful hits wins.

**Why exclusive:** Multi-role UI on one shared match. Very "Dart Buddy"; not in typical pad scorekeepers.

**Dependencies:** Role assignment in match state, Companion-style tap UI for judges, TTS optional.

---

### 6. Segment Heist

**Hook:** Tic-Tac-Toe on the **real wedge map**.

| | |
|--|--|
| **Players** | 2 |
| **Section** | Party |
| **Template** | `boardState` |

**Rules (sketch):**
- 3×3 overlay on the board (e.g. rows: 20/19/18, 17/16/15, 25/12/11).
- Hit a cell → claim it for your color; block opponents.
- First to three in a row **or** most cells after 12 rounds wins.

**Why exclusive:** `boardState` template + future visual dartboard input. Competitors don't map spatial games onto physical wedge geography.

**Dependencies:** Board-state engine (related to planned Tic-Tac-Toe / Prisoner specs), visual board input (optional polish).

---

### 7. Contract Killer

**Authoritative spec:** [`specs/game-modes/planned/ContractKillerGameSpec.md`](../specs/game-modes/planned/ContractKillerGameSpec.md) — **Promoted**.

**Hook:** Killer with a **secret contract** drawn at game start.

| | |
|--|--|
| **Players** | 3+ |
| **Section** | Party |
| **Template** | `livesElimination` + hidden objectives |

**Rules (sketch):**
- Each player receives a hidden contract (app-dealt). Examples:
  - "Eliminate the player on your left without becoming killer first"
  - "Survive with exactly 1 life when someone else wins"
  - "Hit your own number only with triples"
- Fulfill contract → steal a life or gain immunity.
- Contracts revealed at game end (or on fulfillment).

**Why exclusive:** Hidden objectives + elimination engine. Party apps rarely do structured secret missions.

**Dependencies:** Killer engine, per-player secret payload, reveal UX.

---

### 8. Remix Night (procedural mash-up)

**Authoritative spec:** [`specs/game-modes/planned/RemixNightGameSpec.md`](../specs/game-modes/planned/RemixNightGameSpec.md) — **Promoted** (format preset).  
**Platform:** [`specs/TournamentSpec.md`](../specs/TournamentSpec.md) — brackets, hub, knockout, online (future).

**Hook:** Every session is a **random mini-tour** from the existing catalog — a **leg-win tournament format**, not a knockout bracket (see Tournament spec for full brackets).

| | |
|--|--|
| **Players** | 2+ |
| **Section** | Party |
| **Template** | Meta-mode orchestrator (thin coordinator over existing engines) |

**Rules (sketch):**
- App draws 3 rounds from shipped/planned modes (e.g. Shanghai on 7s → Sudden Death leg → Football to 2 goals).
- Between rounds: TTS rules recap + one-screen cheat sheet.
- Aggregate scoring or "most round wins" determines evening champion.

**Why exclusive:** 29 modes on shared templates — only Dart Buddy can **compose** them into a single evening format.

**Dependencies:** Multi-engine handoff in one match session, round transition UI, mode availability on product surface.

---

### 9. Journey Gauntlet (campaign-native format)

**Hook:** A **match format**, not a new rules engine — scripted multi-mode arc inside Journey.

| | |
|--|--|
| **Players** | 1 human vs bot(s) |
| **Section** | Journey (Campaign) |
| **Template** | Campaign layer on existing engines |

**Rules (sketch):**
- Stage script: "Win leg 1 at 301 DO; leg 2 Cut Throat Cricket; leg 3 beat The Challenger at Shanghai — same roster, no menu between legs."
- Stars for margin, checkout, or no-bust criteria.
- Failure retries unlimited (per Campaign spec).

**Why exclusive:** Campaign + multi-engine handoff. Competitors ship modes in isolation, not scripted arcs.

**Dependencies:** [`specs/CampaignSpec.md`](../specs/CampaignSpec.md) Phase 2+, historical leg state (Phase 3).

---

### 10. Fairway 501 (golf × X01 hybrid)

**Hook:** Each "hole" is a **checkout puzzle**, not a race to zero.

| | |
|--|--|
| **Players** | 1+ |
| **Section** | Practice or Party |
| **Template** | `inningPoints` or `checkoutScore` variant |

**Rules (sketch):**
- 9 holes = 9 checkout numbers (e.g. 40, 57, 121…).
- Par = minimum darts from player's stats cohort (or fixed par table).
- Bogey if you bust or need more than par+1.
- Lowest total strokes wins (multiplayer) or beat par (solo).

**Why exclusive:** Bridges checkout stats + solo/multi templates without being vanilla Golf (segment strokes).

**Dependencies:** Checkout stats, planned Golf spec concepts (par table), X01 engine subset.

---

### 11. Streak Wager

**Hook:** Personal **streak goals** with visible tokens when triggered.

| | |
|--|--|
| **Players** | 2+ |
| **Section** | Party (modifier) or Standard |
| **Template** | Overlay on X01 / Cricket |

**Rules (sketch):**
- Before match, each player sets a personal streak goal ("2-ton visit," "close 20 in one visit"). Goal stays private.
- Hit it during play → gain a **token** (mulligan, force re-throw, steal first throw next leg).
- Tokens visible to everyone once earned.

**Why exclusive:** Ties live match events to per-player UI and history-derived suggested goals.

**Dependencies:** Match event hooks, token economy (simple), optional stats-based goal suggestions.

---

### 12. Dartle (daily puzzle)

**Authoritative spec:** [`specs/game-modes/planned/DartleGameSpec.md`](../specs/game-modes/planned/DartleGameSpec.md) — **Promoted**.

**Hook:** One shared puzzle per day; local leaderboard on device.

| | |
|--|--|
| **Players** | 1+ (async comparison on same device / household) |
| **Section** | Practice |
| **Template** | `sequenceProgress` |

**Rules (sketch):**
- Target sequence of 6 segments (Wordle-style grid).
- Everyone gets the **same** sequence for the calendar day (seeded from date).
- 18 darts total; share card: "Solved in 11 darts, no misses on 4."
- Optional: compare across profiles on one install.

**Why exclusive:** Daily challenge pattern + Activity; local-first daily without online play.

**Dependencies:** [`specs/DailyChallengeSpec.md`](../specs/DailyChallengeSpec.md) (if exists), date-seeded RNG, share card UI.

---

## Sports-inspired games

Design family for **traditional sport metaphors** on the dartboard. Shared feel:

| Pattern | Board expression |
|---------|------------------|
| **Hard to score** | Goals only on doubles, inner bull, or narrow windows — singles advance play but don't reward |
| **Blockers** | Defender nominates a hot segment, guard stones in the house, or closed wedges (Cricket-style) |
| **Alternating aim** | One dart per turn (curling end, shootout, bocce stone) — tension on every throw |
| **Territory** | Progress through segments toward a "try line" or net double |

**Already in catalog (traditional sport):** Baseball (shipped), Football + Golf (planned) — [`GameModeCatalog.swift`](../Features/Modes/GameModeCatalog.swift). Ideas below are **custom** shapes that lean harder on blockers and alternating target play.

**New template candidate:** `territoryAim` — alternating throws, blocker layer, end-of-round scoring (curling / bocce / shootout).

---

### 13. End Sheet (curling)

**Authoritative spec:** [`specs/game-modes/planned/EndSheetGameSpec.md`](../specs/game-modes/planned/EndSheetGameSpec.md) — **Promoted**.

**Hook:** Alternating stones at the **house** (bull). Guards, takeouts, and points only after the end is complete.

| | |
|--|--|
| **Players** | 2 (4-player teams v2) |
| **Section** | Party |
| **Template** | `territoryAim` (new) |

**Rules (sketch):**
- **8 ends** to a match; most points wins.
- Each end: players alternate **one dart** at the house (12 stones total — 6 each).
- **Stone types** (digital — no spatial tracking required):

| Landing | Role |
|---------|------|
| Inner bull | **Shot** — scores in count-back |
| Outer bull | **Shot** — scores, beaten by any opponent inner bull |
| Single 25 | **Guard** — occupies the house, never scores |
| Miss | **Burned** — out of play |

- **Takeout:** Inner bull removes one opponent **outer bull** shot from the end (announced + struck from scoreboard). Optional v2: outer bull removes one opponent guard.
- **Scoring the end:** Player with the closest scoring shot earns **1 point per scoring shot** they have that beats the opponent's best shot (standard curling count). Guards never score but can deny "closest" if opponent has no shot in the house.
- **Hammer:** Player trailing after end 7 throws last in end 8 (optional setup chip).

**Feel:** Quiet tension — every dart is one stone; most ends are 0–1 points; a two-point end feels huge.

**Why exclusive:** End-based UI with stone ledger + takeout animations; pad apps don't do alternating single-dart ends with guard logic.

**Dependencies:** Stone state per end, bull-only pad lock optional (house throws only), haptic "stone placed" feedback.

---

### 14. Slap Shot (hockey)

**Hook:** Puck crawls down the rink toward a **net double**. Goalie sets a blocker every shift.

| | |
|--|--|
| **Players** | 2 |
| **Section** | Party |
| **Template** | `phaseRace` + blocker layer |

**Rules (sketch):**
- **Rink:** Puck starts at **D20** (offensive blue line). Net advances D19 → D18 → … → chosen net double (default **D16**).
- **Shift structure** (alternating roles each shift):

| Phase | Actor | Action |
|-------|-------|--------|
| 1 | Goalie | 1 dart — nominates a **block** segment (any single 1–20). That segment is "clogged" this shift. |
| 2 | Shooter | Up to 3 darts at the **puck double** (current net target). |

- **Resolution:**
  - **Goal** (double/triple on puck segment, not blocked): +1 goal; puck resets to D20.
  - **Save** (shooter hits blocker segment): turnover; no goal.
  - **Advance** (single on puck segment): puck moves one double closer to deep net.
  - **Miss:** turnover.
- First to **5 goals** wins. Overtime: bull shootout (one dart each, inner bull wins).

**Feel:** Low-scoring, save-heavy — goals are earned. Blocker choice is mind-games (clog the obvious line or bait).

**Why exclusive:** Two-phase turn with defender nomination UI; distinct from planned Football (bull kickoff + any double).

**Dependencies:** Segment blocker state per shift, puck position on rink strip UI.

---

### 15. Crease (hockey shootout)

**Authoritative spec:** [`specs/game-modes/planned/CreaseGameSpec.md`](../specs/game-modes/planned/CreaseGameSpec.md) — **Promoted**.

**Hook:** Pure **alternating penalties** — five rounds, keeper picks a different blocked double each round.

| | |
|--|--|
| **Players** | 2 |
| **Section** | Party |
| **Template** | `territoryAim` |

**Rules (sketch):**
- **5 rounds** (+ sudden death). Each round:
  1. Keeper taps **one double** to block (cannot repeat a double until they've blocked 5 different — forces variety).
  2. Shooter gets **1 dart** at any **other** double for a goal.
- **Goal** = double or triple on an unblocked double. Bull counts as D25 if not blocked.
- Tally goals; tie → sudden-death rounds (keeper block + 1 shot) until broken.

**Feel:** Maximum "hard to score, huge when it lands" — 20% shootout conversion is a good night.

**Why exclusive:** Curated blocker history per match; simpler onboarding than full Slap Shot.

**Dependencies:** Blocked-double set per player, shootout scoreboard UI.

---

### 16. Pallino (bocce / lawn bowls)

**Authoritative spec:** [`specs/game-modes/planned/PallinoGameSpec.md`](../specs/game-modes/planned/PallinoGameSpec.md) — **Promoted**.

**Hook:** A random **pallino** each round; alternate one dart — closest wins the round.

| | |
|--|--|
| **Players** | 2–4 |
| **Section** | Party |
| **Template** | `territoryAim` |

**Rules (sketch):**
- App calls **pallino** each round: e.g. "T18," "S3," "D7" (weighted toward singles for tighter play).
- Players alternate **one dart** until each has thrown 3 (6 stones).
- **Distance proxy** (no mm tracking):

| Landing | Distance score |
|---------|----------------|
| Exact pallino (segment + ring) | 100 |
| Same segment, adjacent ring | 70 |
| Same ring, adjacent segment | 50 |
| Same segment any ring | 40 |
| Miss | 0 |

- Round winner: highest single-stone distance score (not sum — one best stone). Win = 1 point; play to **11**.
- **Blocker / kiss:** Matching opponent's exact pallino **replaces** their stone with yours (last stone wins placement).

**Feel:** Surgical — you're often throwing to **narrow** targets; a round can flip on the final dart.

**Why exclusive:** Random pallino callout + TTS integration; ring-adjacency math is app-side.

**Dependencies:** Callout voices, adjacency table on board graph, per-round stone list.

---

### 17. Full Court Press (basketball)

**Hook:** Alternating possessions — shooter picks a **shot chart** line; defender sets a contest window.

| | |
|--|--|
| **Players** | 2 |
| **Section** | Party |
| **Template** | `roleSplit` |

**Rules (sketch):**
- Game to **21** (win by 2). Alternate possessions.
- **Shot chart** (offense picks one before shooting):

| Shot | Target | Points if make |
|------|--------|----------------|
| Rim | Bull (either) | 2 |
| Mid | Any double except bull | 2 |
| Deep | Any triple | 3 |

- **Contest (defense):** Before offense throws, defender nominates **one segment** (e.g. 17). If offense **hits** that segment on any of 3 darts → **block** (turnover, no points).
- **Make:** Hit shot target without triggering contest.
- **And-1 optional:** Make on third dart + bull on same visit → +1 (setup chip).

**Feel:** Defense is active every possession; triples are tempting but contest risk is real.

**Dependencies:** Possession state, shot-type picker, contest segment UI.

---

### 18. Lineout (rugby)

**Hook:** **Territorial ladder** — inch down 20→15, score tries only on doubles in the zone.

| | |
|--|--|
| **Players** | 2–4 (teams v2) |
| **Section** | Party |
| **Template** | `sequenceProgress` + territory |

**Rules (sketch):**
- Ball starts at **20**. On your turn (3 darts):
  - **Gain ground:** Single on current segment → ball moves to next segment (20→19→…→15).
  - **Knock-on:** Miss all three → turnover at spot.
  - **Try:** Double (or triple) on **current** segment while ball is there → **5 points** (rare); ball resets to 20 on kickoff.
- **Blocker — tackle:** Opponent may spend a **tackle token** (1 per half) to nominate a segment you're not allowed to hit this turn; hit it → turnover.
- Two **20-point** halves (40-a-side flavor); most points wins.

**Feel:** Long drives build tension; tries are explosive and infrequent.

**Dependencies:** Territory marker, tackle token economy, half split UI.

---

### 19. Bunker (golf skins)

**Hook:** Not full Golf — **one hole at a time** with a **sand blocker** segment.

| | |
|--|--|
| **Players** | 2–4 |
| **Section** | Party |
| **Template** | `inningPoints` variant |

**Rules (sketch):**
- App reveals **hole** (segment 1–18) and **bunker** (adjacent segment).
- Each player: 3 darts, **lowest strokes on hole** wins the skin (1 point). Tie carries skin.
- Strokes: double = 1, triple = 2, single = 3, **hit bunker** = 6 and turn ends early.
- **Alternating reveal:** Player who won last skin picks next hole; app draws bunker.

**Feel:** Complements planned [`GolfGameSpec.md`](../specs/game-modes/planned/GolfGameSpec.md) — faster skins format with explicit blocker wedge.

**Dependencies:** Golf stroke table subset, bunker adjacency, skin carry state.

---

### Sports family — quick comparison

| Game | Sport | Alternating? | Blocker | Primary reward |
|------|-------|--------------|---------|----------------|
| End Sheet | Curling | 1 dart / stone | Guards + takeouts | End points (0–3 typical) |
| Slap Shot | Hockey | Shifts | Goalie segment | Goals (doubles on puck) |
| Crease | Hockey SO | 1 dart / round | Blocked double | Rare shootout goals |
| Pallino | Bocce | 1 dart / stone | Stone replacement | Round wins to 11 |
| Full Court Press | Basketball | Possessions | Contest segment | 2s and 3s |
| Lineout | Rugby | 3-dart drives | Tackle token | 5-point tries |
| Bunker | Golf skins | Full visits | Bunker segment | Skins / holes |
| Football _(planned)_ | Soccer | Phases | Phase gate (kickoff) | Doubles = goals |
| Golf _(planned)_ | Golf | Full visits | — | Low stroke count |

### Recommended sports trio

1. **End Sheet** — purest curling feel; best fit for "alternate + blockers + hard to score."
2. **Crease** — fastest MVP (shootout rules only).
3. **Slap Shot** — deeper hockey sim if Crease lands well.

---

## Co-op & team games

Formats where the phone coordinates **shared goals** or **partner turns** — rare in dart apps, strong for pub couples / doubles nights.

---

### 20. The Vault (co-op heist)

**Authoritative spec:** [`specs/game-modes/planned/TheVaultGameSpec.md`](../specs/game-modes/planned/TheVaultGameSpec.md) — **Promoted**.

**Hook:** 2–4 players share one **vault meter** (0→100). No player vs player — beat the board together.

| | |
|--|--|
| **Players** | 2–4 (co-op) |
| **Section** | Party |
| **Template** | `phaseRace` (shared) |

**Rules (sketch):**
- **5 locks** on the vault. Each lock needs a **combo** (e.g. Lock 3 = T20 + D12 + bull).
- Players alternate **one dart**; combo progress is shared and visible.
- Wrong segment on a lock **resets that lock only** (not the whole vault).
- **Alarm:** After 3 lock resets total, "alarm" — next miss ends the run.
- Win: open all 5 locks before darts run out (default **36** team darts). Score = darts remaining as stars.

**Feel:** Table celebrates together; arguments are about order ("save bull for me").

**Why exclusive:** Shared combo state + alarm counter; chalkboards can't run structured co-op missions.

**Dependencies:** Combo chain engine, team dart pool, solo-practice summary variant for co-op stars.

---

### 21. Tag Out (partner relay)

**Hook:** **Pairs** share one X01 leg — but only one player at the oche per dart.

| | |
|--|--|
| **Players** | 4 (2 teams of 2) |
| **Section** | Party |
| **Template** | `checkoutScore` (team) |

**Rules (sketch):**
- Team **A** and **B** each have one shared remaining score (e.g. 501).
- Turn order: A1 → B1 → A2 → B2 → A1… (**one dart each**).
- Partners cannot speak segment hints (honor) — optional "silent mode" timer on phone.
- Checkout must be **team** checkout; either partner may throw the winning dart.
- Leg win: standard double-out on team score.

**Feel:** Volleyball energy at the oche — everyone stays warm, no long waits.

**Why exclusive:** Strict 1-dart rotation UI with team score binding.

**Dependencies:** Team entity in match state, rotation enforcement in turn engine.

---

### 22. Lockpick (escape room)

**Hook:** Solo or co-op — **30 darts** to solve five checkout padlocks.

| | |
|--|--|
| **Players** | 1–4 (co-op) |
| **Section** | Practice / Party |
| **Template** | `soloChallenge` / shared pool |

**Rules (sketch):**
- Five locks with checkout values (40, 57, 81, 98, 121 — configurable difficulty).
- Alternate throws in co-op; solo gets all 30.
- **Pick rule:** On a lock, only hits on that checkout number count; bust = lock jams (skip 2 darts of penalty time in timed mode, or +1 dart cost in untimed).
- **Tools (once per run):** Rewind one dart, or reveal "safe segment" hint for current lock.

**Feel:** Escape-room tension without leaving the pub.

**Dependencies:** X01 checkout subgraph, tool inventory, Journey stage friendly.

---

## Co-op PvE — humans vs boss / shared objective

**Product lane:** Real friends at the oche vs **bots as villains**, **shared meters**, or **mission success** — not PvP. Raid is the flagship ([`RaidGameSpec.md`](../specs/game-modes/planned/RaidGameSpec.md)); this section expands the **PvE co-op** family for Journey nights and pub crews.

### Design pillars

| Pillar | What it means on the phone |
|--------|----------------------------|
| **Shared stakes** | One boss HP bar, one castle, one oxygen tank — the table wins or loses together |
| **Boss as character** | Bot tier = personality + difficulty (`The Challenger`, `The Cutthroat`, `Nightmare`) |
| **Phase drama** | Boss shifts rules mid-fight (Raid Shield → Expose); keeps 15+ min sessions fresh |
| **Role without complexity** | Optional caller / finisher / closer — no MMO skill trees in v1 |
| **Solo-able** | 1 human + boss for practice; scales to 2–4 humans for pub |
| **Co-op summary** | No single winner card; stars for margin, flawless, speed (extend Raid §9) |

### Boss archetypes (reusable content)

| Archetype | Bot behavior (v1) | Visual |
|-----------|---------------------|--------|
| **Bruiser** | High HP, slow phases, enrage hits hard | Heavy frame, red HP |
| **Trickster** | Rotates weak points every round | Mask / shuffle animation |
| **Cutthroat** | Punishes lowest visit (Raid enrage) | Cricket skull motif |
| **Chaser** | Advances toward team goal on team miss | Timer / pursuit bar |
| **Swarm** | Wave counter, not one HP pool | Minion icons per wave |

---

### 34. Siege (wave defense)

**Hook:** Defend **Castle HP** against **waves** of bot minions — each wave is a team objective, not a throwing bot.

| | |
|--|--|
| **Players** | 1–4 humans vs wave script |
| **Section** | Party |
| **Template** | `phaseRace` (shared) |

**Rules (sketch):**
- Castle **20 HP**. **10 waves**; bot tier sets wave difficulty table.
- Each wave reveals objective: *"Close 18 as a team"* / *"2 doubles anywhere"* / *"Visit total ≥ 85"*.
- Players rotate full visits; progress is **shared** (cricket marks team-wide like Raid Shield).
- **Wave fail** (objective incomplete in 2 team rounds): castle **−2 HP**.
- **Wave clear:** small heal +1 castle HP (cap 20).
- Win: survive wave 10 with castle HP > 0. Lose: castle 0.

**Feel:** Horde mode at the pub — loud clears, groans on fail.

**Why exclusive:** Wave script + shared objective validator per round.

---

### 35. The Chaser (co-op race vs bot)

**Hook:** Team shares **501**; bot **Chaser** has 420 and gains **15** every team bust or skipped turn.

| | |
|--|--|
| **Players** | 1–3 humans vs 1 chaser bot |
| **Section** | Party |
| **Template** | `checkoutScore` (team) |

**Rules (sketch):**
- Team score starts 501, standard double-out.
- Chaser bot score ticks down automatically each **team** visit (simulated 3-dart average from tier).
- On team **bust:** chaser **−15** (gets closer).
- Win: team checkouts before chaser hits 0.
- Lose: chaser reaches 0 first.

**Feel:** Escape room chase — panic checkouts with friends yelling "don't bust!"

**Dependencies:** Team X01 entity, bot virtual score timeline (no dart animation required).

---

### 36. Cerberus (multi-head boss)

**Authoritative spec:** [`specs/game-modes/planned/CerberusGameSpec.md`](../specs/game-modes/planned/CerberusGameSpec.md) — **Promoted**.

**Hook:** Boss has **three heads** (segments 20, 16, 12). Each round each human is assigned **one head** — only their darts damage that head.

| | |
|--|--|
| **Players** | 2–3 humans (optimal 3) vs Cerberus |
| **Section** | Party |
| **Template** | `roleSplit` + boss HP |

**Rules (sketch):**
- Each head: **15 HP**. Damage: cricket close on that segment = 5 HP; double on segment = 3; single = 1.
- Round: all humans throw; **unassigned heads take 0**.
- **Snap:** When any head hits 0, Cerberus **bites** — team **shared pool −3** (one team life bar, default 12).
- Win: all three heads 0 before team pool 0.

**Feel:** MMO raid assignments — *"I'm on 16, you take 20!"*

**Why exclusive:** Per-round role assignment UI + tri-bar boss chrome.

---

### 37. Outbreak (stop the spread)

**Hook:** **Infection** spreads across a 1–20 ring each bot turn; team closes segments to **cure** before infection reaches bull.

| | |
|--|--|
| **Players** | 1–4 humans vs spread AI |
| **Section** | Party |
| **Template** | `boardState` (shared) |

**Rules (sketch):**
- Infection starts at random segment. Each **spread tick** (after each full team round): infection jumps to adjacent segment (clockwise default).
- **Cure:** hit infected segment with a double → cured permanently.
- **Team miss round** (no cure attempt landed): extra spread tick.
- Bull infected = **instant loss**.
- Win: cure **8** segments before bull infected. Tier sets start count / spread speed.

**Feel:** Pandemic board on a dartboard — tactical doubles.

---

### 38. Deep Dive (oxygen co-op)

**Hook:** Shared **oxygen** depletes every round; hits on **called depth targets** refill it. Bot "depth pressure" speeds drain at tiers.

| | |
|--|--|
| **Players** | 1–4 humans |
| **Section** | Practice / Party |
| **Template** | `phaseRace` + meter |

**Rules (sketch):**
- Oxygen **100**; lose **8** per team round baseline (+ tier penalty).
- App calls **depth target** each round (segment + min ring): e.g. T18, D12, S5.
- Each success: **+12** oxygen (stack if multiple humans hit in same round? v1: once per round max).
- **Surface** at oxygen ≥ 100 after round 10 = win. Oxygen 0 = blackout loss.

**Feel:** Subnautica tension — caller reads target, team delivers.

**Dependencies:** Callout voices, shared meter UI (Raid-adjacent).

---

### 39. Heist Crew (Vault + guards)

**Hook:** **The Vault** (§20) plus **guard bot** — slow alarm meter when locks fail.

| | |
|--|--|
| **Players** | 2–4 humans vs guard AI |
| **Section** | Party |
| **Template** | `phaseRace` (shared) |

**Rules (sketch):**
- Same combo locks as Vault.
- **Guard meter** 0–100; rises on wrong-segment hits (+10) and lock resets (+20).
- At 100: **lockdown** — lose 3 team darts from pool and reset current lock.
- Optional **distraction** (once): one player "draws guard" — their darts don't progress locks but **−30** guard meter if they hit T20.
- Win: all locks before team dart pool empty.

**Feel:** Ocean's Eleven planning — who distracts vs who cracks the combo.

---

### 40. Hold the Line (combo block)

**Hook:** Boss **attacks** with a segment combo; team must **match or beat** the pattern in one round to block damage.

| | |
|--|--|
| **Players** | 1–4 humans vs attacker bot |
| **Section** | Party |
| **Template** | `sequenceProgress` (team) |

**Rules (sketch):**
- Team **fortitude** 30 HP.
- Boss shows attack line: e.g. S5 → D10 → T15 (icons, not throws).
- Team has 3 darts **per player** across the round (rotate) to **complete** the line in order (any player may contribute next hit).
- **Block:** line complete → boss **stagger** (free damage round next).
- **Fail:** fortitude −5 (−8 on tier Hard+).
- **Stagger round:** doubles anywhere = boss damage (shared HP bar 40).
- Win: boss HP 0. Lose: fortitude 0.

**Feel:** Fighting-game block strings — readable telegraph, team execution.

---

### 41. Last Stand (endless survival)

**Hook:** Infinite **waves**; leaderboard is **rounds survived**; bot tier sets wave budget.

| | |
|--|--|
| **Players** | 1–4 humans |
| **Section** | Party / Practice |
| **Template** | `phaseRace` (orchestrator) |

**Rules (sketch):**
- Wave *n* objective scales: round 1 = hit S1; round 5 = visit ≥ 60; round 10 = close 17 in cricket marks team pool.
- **One team life** per player (3 each); fail wave costs 1 life from **lowest visit** player (Raid enrage rule).
- No win condition — survive until wipe. Record wave # in Activity.
- Daily/weekly: same seed wave script for async household compare (local).

**Feel:** Zombie horde high score — one more round addiction.

---

### 42. Titan (weak-point rotation)

**Hook:** One huge boss HP pool; **only one weak segment** per round accepts damage (Trickster archetype).

| | |
|--|--|
| **Players** | 1–3 humans vs Titan |
| **Section** | Party |
| **Template** | `phaseRace` |

**Rules (sketch):**
- Titan **80 HP**. Each round app reveals **weak point** (random segment 1–20, weighted away from last).
- Damage on weak point: single 1 / double 3 / triple 6. Other segments = 0.
- **Slam round** (every 4th): weak point must be hit with **double+** or Titan **regenerates 5 HP**.
- Miss all weak hits in a round: Titan **stomp** — each human −1 heart (3 hearts each).

**Feel:** Shadow of the Colossus — find the glow spot.

**Lighter than Raid:** no cricket phase; faster onboarding.

---

### 43. Bridge (escort)

**Hook:** Escort a **marker** around the clock 20→1→bull; bot **Saboteur** pulls marker backward on failed team rounds.

| | |
|--|--|
| **Players** | 1–4 humans vs saboteur |
| **Section** | Party |
| **Template** | `sequenceProgress` |

**Rules (sketch):**
- Marker starts 20. Hit current segment (any ring) → advance one step.
- **Team round** = each human throws once (1 dart each, Raid rotation).
- If **no advance** in a full team round: Saboteur **−1 step** (min 20).
- Win: reach bull in ≤ **N** team rounds (default 12). Tier tightens N.

**Feel:** Escort quest — protect the VIP wedge.

---

### 44. Ritual (chain offering)

**Hook:** Team must complete a **5-segment ritual chain** each cycle; bot **Void** fills a darkness meter when chains break.

| | |
|--|--|
| **Players** | 2–4 humans vs Void |
| **Section** | Party |
| **Template** | `sequenceProgress` (shared chain) |

**Rules (sketch):**
- Ritual order dealt face-up: e.g. 12 → 8 → 20 → 5 → bull.
- Players alternate **one dart**; must advance chain in order.
- Complete chain: **Void −15 HP** (pool 60). Break chain: **Darkness +10** (lose at 100).
- Each human has **2 personal candles**; darkness +10 also snuffs one candle (lowest visit). No candles = can't throw until relit (costs team round).

**Feel:** Cult co-op puzzle — planning order ("you take bull").

---

### 45. Bounty Board (legendary bot)

**Hook:** Boss exposes **3 active bounties** (segments) at a time; hitting them deals damage; boss **rotates** bounties when one is "claimed."

| | |
|--|--|
| **Players** | 1–4 humans vs legendary bot |
| **Section** | Party / Journey |
| **Template** | `markBoard` variant |

**Rules (sketch):**
- Boss 50 HP. Bounties: e.g. D16, T19, S7 — change when claimed (hit ≥ single).
- Damage: claimed bounty = 5 HP; off-bounty hits = 0.
- **Retaliation:** after 2 claims in one team round, boss retaliates — **lowest visit −1 heart**.
- Bot tier sets HP and retaliation harshness.

**Feel:** Monster Hunter part breaking — focus fire callouts.

---

### 46. Fire Team (caller + strikers vs boss)

**Hook:** PvE **Buddy Relay** — one **Caller** (phone holder) sees boss weak point; **Strikers** throw blind to callouts only.

| | |
|--|--|
| **Players** | 3–4 humans (1 caller + 2–3 strikers) vs boss |
| **Section** | Party |
| **Template** | `roleSplit` + boss HP |

**Rules (sketch):**
- Caller rotates each boss phase; strikers must throw at **called** segment only (strict).
- Boss 40 HP; damage = ring table from Raid Expose phase.
- **Miscommunication:** striker hits wrong segment → boss **heal 3**.
- TTS optional for blind strikers at oche.

**Feel:** Raid with voice comms — accessibility crossover with Echo.

---

### 47. Gauntlet Squad (Journey co-op format)

**Hook:** Not one engine — **4 scripted stages** in one session, team roster fixed, vs bot guardians.

| | |
|--|--|
| **Players** | 1–3 humans |
| **Section** | Journey / Party |
| **Template** | Orchestrator |

**Rules (sketch):**
- Stage 1: team 301 leg vs Easy bot shadow (both play, team must win leg).
- Stage 2: Raid mini-boss (30 HP, no enrage).
- Stage 3: Vault 2 locks.
- Stage 4: Chaser race (team 201 vs chaser 180).
- **Stars:** complete without losing a stage; speed; no busts on X01 stage.

**Feel:** Destiny raid night — one menu, one crew, one victory screen.

**Dependencies:** [`CampaignSpec.md`](../specs/CampaignSpec.md), Raid + Vault engines.

---

### Co-op PvE — comparison

| Game | Vs | Players | Core loop | Specced |
|------|-----|---------|-----------|---------|
| **Raid** | Boss HP + phases | 1–3 | Cricket then doubles | Yes |
| **Siege** | Wave script | 1–4 | Clear objective / wave | — |
| **The Chaser** | Pursuit bot | 1–3 | Team checkout race | — |
| **Cerberus** | 3-head boss | 2–3 | Assigned targets | — |
| **Outbreak** | Spread AI | 1–4 | Cure doubles | — |
| **Deep Dive** | Pressure meter | 1–4 | Called refills O₂ | — |
| **Heist Crew** | Guard meter | 2–4 | Vault + alarm | — |
| **Hold the Line** | Attack patterns | 1–4 | Block combo strings | — |
| **Last Stand** | Endless waves | 1–4 | Survive + high score | — |
| **Titan** | Weak-point boss | 1–3 | Find glowing segment | — |
| **Bridge** | Saboteur | 1–4 | Escort around clock | — |
| **Ritual** | Void meter | 2–4 | Ordered chain | — |
| **Bounty Board** | Legendary bot | 1–4 | Rotating targets | — |
| **Fire Team** | Boss + roles | 3–4 | Caller / strikers | — |
| **Gauntlet Squad** | Multi-stage | 1–3 | Journey mash | — |
| **Clear the Board** | Optional decay | 1–4 | Close every S/D/T cell | — |
| **The Vault** | Board puzzle | 2–4 | Combo locks | Brainstorm §20 |
| **Lockpick** | Padlocks | 1–4 | Checkout locks | Brainstorm §22 |

### Recommended co-op PvE roadmap

| Phase | Ship | Why |
|-------|------|-----|
| **1** | **Raid** | Spec done; defines boss chrome + co-op summary |
| **2** | **The Vault** or **Titan** | Vault = no bot AI; Titan = simpler boss than Raid |
| **3** | **Siege** or **Cerberus** | Best "crew night" energy at 3–4 players |
| **4** | **Gauntlet Squad** | Journey content pack once 2+ PvE engines exist |

### Shared platform (spec once, reuse everywhere)

| Component | Used by |
|-----------|---------|
| `CoopMatchSummary` (no single winner) | All PvE |
| `TeamDartPool` / shared meters | Vault, Siege, Ritual, Deep Dive |
| `BossParticipant` + phase banner | Raid, Titan, Cerberus, Bounty |
| `WaveScriptJSON` | Siege, Last Stand, Gauntlet |
| `BotPressureTimeline` (virtual score) | Chaser, Saboteur |
| Hero hearts + enrage strike | Raid, Cerberus, Last Stand |

Draft platform spec target: `specs/CoopPvEModesSpec.md` (not written yet) when Raid implementation starts.

---

### 48. Clear the Board (ring-cell sweep)

**Hook:** Close every **segment × ring** cell (T1 ≠ D1 ≠ S1). Team points on first close.

| | |
|--|--|
| **Players** | 1–4 humans |
| **Authoritative spec** | [`specs/game-modes/planned/ClearTheBoardGameSpec.md`](../specs/game-modes/planned/ClearTheBoardGameSpec.md) |

**Locked decisions (v1):**
- Points: **S=1, D=2, T=3** (no triple-5 until post-ship data).
- **Three variants:** **Pure Clear** (co-op) / **Decay** (co-op) / **Team vs Team** (friends vs friends, **no bots**).
- **Team vs Team:** **1v1–4v4** (2–8 humans, even teams), claim model — full board, **points** win, cells tiebreaker.
- **Re-hit closed cell:** configurable **waste** or **−1 team point**.
- **Bull default — Catch-up:** bull **never closes**; outer **2** / inner **3** only when **behind** (pace in Pure, decay≥4 in Decay, trailing score in Team vs Team). **Standard** / **Off** optional.

**Promoted** — do not edit rules here.

---

## Hidden info & mind games

---

### 23. Fleet (battleship)

**Hook:** Each player **hides five segments** on their fleet (app-side). Opponents hunt by throwing.

| | |
|--|--|
| **Players** | 2 |
| **Section** | Party |
| **Template** | `boardState` + hidden grid |
| **Authoritative spec** | [`specs/game-modes/planned/FleetGameSpec.md`](../specs/game-modes/planned/FleetGameSpec.md) |

**Rules (summary):** See spec. 3/5/7 ships, 1- or 3-hit health, optional bull, ring damage (S=1, D=2, T=sink). **Promoted** — do not edit rules here.

---

### 24. Double Bluff

**Authoritative spec:** [`specs/game-modes/planned/DoubleBluffGameSpec.md`](../specs/game-modes/planned/DoubleBluffGameSpec.md) — **Promoted**.

**Hook:** Each round both players **secretly commit** a target segment. Reveal → throw.

| | |
|--|--|
| **Players** | 2 |
| **Section** | Party |
| **Template** | `roleSplit` |

**Rules (sketch):**
- Simultaneous commit (15s timer): pick segment + ring intent (S/D/T).
- Reveal both picks:
  - **Match** (same segment): both throw at it — higher ring wins 2 points.
  - **Clash** (different): each throws at **opponent's** committed segment (mind game).
  - **Bull wildcard:** committing bull lets you copy opponent's segment after reveal.
- First to **11** points.

**Feel:** Poker at the oche — reading opponent's favorite wedges.

**Dependencies:** Simultaneous commit UI, reveal animation, timed lock-in.

---

### 25. Cold Call (hot–cold)

**Authoritative spec:** [`specs/game-modes/planned/ColdCallGameSpec.md`](../specs/game-modes/planned/ColdCallGameSpec.md) — **Promoted**.

**Hook:** App picks a **secret segment**. You get **hotter/colder** voice feedback after each dart.

| | |
|--|--|
| **Players** | 1–2 |
| **Section** | Practice |
| **Template** | Voice drill variant |

**Rules (sketch):**
- Secret target (segment, optionally ring). Unlimited darts or cap at 15.
- After each dart, TTS: "Freezing" / "Cold" / "Warm" / "Hot" / "Burning" based on board-graph distance (segment + ring).
- **Exact hit** ends round; score = darts used (lower better).
- 2-player: alternate darts on **same** secret; first to hit wins round.

**Feel:** Wordle geography on a dartboard — pure phone magic.

**Why exclusive:** Distance graph + TTS; no equivalent offline.

**Dependencies:** Board adjacency metric, callout phrases, optional Companion verify for competitive.

---

## Risk, draft & chaos

---

### 26. Segment Draft

**Hook:** MOBA-style **ban phase** before the match — shape the board together.

| | |
|--|--|
| **Players** | 2+ |
| **Section** | Party (modifier) or standalone |
| **Template** | Overlay → `checkoutScore` or `markBoard` |

**Rules (sketch):**
- Alternating bans: each player bans **2 segments** (4 total at 2p).
- **Banned** segments: hitting them costs **−10** from your score (X01) or gifts opponent marks (Cricket).
- Then play a standard leg with modified incentives.
- Optional: **snake draft** on 3 segments you alone can score on for bonus.

**Feel:** Pre-game strategy minute; wedges become personal.

**Dependencies:** Ban UI in setup, scoring penalty hook in engines.

---

### 27. Press (push your luck)

**Authoritative spec:** [`specs/game-modes/planned/PressGameSpec.md`](../specs/game-modes/planned/PressGameSpec.md) — **Promoted**.

**Hook:** Hit a called segment → **bank** or **press** to a harder ring on the same segment.

| | |
|--|--|
| **Players** | 2+ |
| **Section** | Party |
| **Template** | `soloChallenge` (per turn) |

**Rules (sketch):**
- Round starts with called segment (random or opponent-picked).
- **Ladder on segment:** Single = 1 pt banked → choose Press for Double (3 pts) → Press for Triple (7 pts).
- **Miss at any step:** lose everything banked this round.
- **Bank:** keep points, pass turn. First to **50** wins.

**Feel:** Casino sweat — T20 single becomes "do I press?"

**Dependencies:** Per-turn bank state, opponent target nomination optional.

---

### 28. Wind Shift (environmental)

**Hook:** Each **round** the app rolls board "weather" — one ring buffed, one nerfed.

| | |
|--|--|
| **Players** | 2+ |
| **Section** | Party |
| **Template** | Overlay on any base mode |

**Rules (sketch):**
- Before each round/leg: reveal **tailwind ring** (e.g. triples +1 bonus point) and **headwind ring** (e.g. doubles on 16 count as miss).
- Applies to all players; 3 rounds per match.
- Works as modifier on Cricket, Shanghai, or a simple race-to-21 points.

**Feel:** Same pub, different board every ten minutes.

**Dependencies:** Round modifier payload, weather reveal animation + TTS.

---

## Puzzle & chain games

---

### 29. Circuit (voltage)

**Hook:** Complete **wires** across the board — chained segments without a miss.

| | |
|--|--|
| **Players** | 2 |
| **Section** | Party |
| **Template** | `sequenceProgress` |

**Rules (sketch):**
- App deals **3 circuits** per player per round (e.g. 5→12→9, 18→4→13, 20→1→bull).
- 3 darts to complete **one** circuit in order (any ring on segment counts).
- Complete circuit = **1 point**; miss breaks chain (0 for that circuit).
- Opponent can **sabotage** once per round: nominate one extra required segment inserted mid-circuit.

**Feel:** Sudoku panic with metal in your hand.

**Dependencies:** Circuit generator, sabotage token, chain-break UX.

---

### 30. Order Up (kitchen rush)

**Hook:** Silly party mode — complete **recipes** (segment combos) before the ticket expires.

| | |
|--|--|
| **Players** | 2–6 |
| **Section** | Party |
| **Template** | `inningPoints` |

**Rules (sketch):**
- **Tickets** queue (3 active). Example: "T20 + S5 + bull" = Burger; "Any triple + D8" = Fries.
- On your visit, hits apply to **any** open ticket; first to complete claims it (+points by difficulty).
- **Rush hour:** Every 5th ticket has 30s kitchen timer (phone); expires = −1 point.
- Most points after **12 tickets** wins.

**Feel:** Overcooked energy — chaotic, great for groups, not serious darts.

**Dependencies:** Ticket queue UI, timer, recipe generator from segment pool.

---

### 31. Simon Board (memory)

**Hook:** App plays a **segment sequence**; you throw it back in order.

| | |
|--|--|
| **Players** | 1+ |
| **Section** | Practice / Party |
| **Template** | `sequenceProgress` + voice |

**Rules (sketch):**
- Round 1: one segment (TTS + flash on phone). Player throws 1 dart to match.
- Each success adds one segment to the chain (max 8).
- **Miss** → round over; score = longest chain.
- Multiplayer: same chain for all; longest survives elimination bracket.

**Feel:** Simon Says at the oche — spectators can follow on phone.

**Dependencies:** Callout sequence player, honor or Companion verify, chain display.

---

### 32. Cutthroat Checkout (shared race)

**Hook:** Everyone starts on the **same checkout number** — first to finish wins the leg; busts help opponents.

| | |
|--|--|
| **Players** | 3–8 |
| **Section** | Party |
| **Template** | `checkoutScore` |

**Rules (sketch):**
- All players on **121** (or random checkout 40–170), double-out.
- Full visits in rotation (not 1-dart).
- **Checkout:** you win the leg (+3 standings points).
- **Bust:** add **+5** to every *other* player's remaining (sabotage) — or simpler v1: bust = −1 standings point only.
- Match: best of 5 legs.

**Feel:** N-player checkout chaos — defensive busting is viable strategy.

**Dependencies:** Multi-player shared starting checkout, bust spillover rule toggle.

---

### 33. Raid (boss fight)

**Hook:** Team vs **one super bot** with phase HP and weak points.

| | |
|--|--|
| **Players** | 1–3 humans vs boss bot |
| **Section** | Journey / Party |
| **Template** | `phaseRace` |
| **Authoritative spec** | [`specs/game-modes/planned/RaidGameSpec.md`](../specs/game-modes/planned/RaidGameSpec.md) |

**Rules (summary):** See spec. Shield (team cricket closes on 20–16 → 8 HP) → Expose (doubles/triples) → Enrage overlay (lowest visit loses a heart). **Promoted** — do not edit rules here.

---

### New families — quick comparison

| Game | Family | Players | Phone superpower |
|------|--------|---------|------------------|
| The Vault | Co-op | 2–4 | Shared combo locks + alarm |
| Tag Out | Team | 4 | 1-dart partner rotation |
| Lockpick | Co-op / solo | 1–4 | Tool inventory + checkout chains |
| Fleet | Hidden | 2 | Secret fleet placement |
| Double Bluff | Hidden | 2 | Simultaneous commit + reveal |
| Cold Call | Feedback | 1–2 | Hot/cold TTS from graph distance |
| Segment Draft | Meta | 2+ | Ban phase shapes leg |
| Press | Risk | 2+ | Bank / press ladder |
| Wind Shift | Chaos | 2+ | Per-round ring modifiers |
| Circuit | Puzzle | 2 | Sabotage chains |
| Order Up | Party chaos | 2–6 | Ticket queue + timer |
| Simon Board | Memory | 1+ | Audible sequence |
| Cutthroat Checkout | Race | 3–8 | Shared checkout + bust spillover |
| Raid | Boss | 1–3 | Phase HP + enrage |

### Recommended second wave (after sports + first trio)

1. **Cold Call** — fast to prototype on Call & Hit infrastructure; very "only on phone."
2. **The Vault** — co-op differentiator for App Store story.
3. **Fleet** — hidden-info party game with high replay.

---

## Deduplication & core roster (trim pass)

48 custom ideas + sports + PvE expansion — many share engines. Below: **overlap clusters**, what to **cut/merge**, and a **~15-game core** worth speccing/building.

### Overlap clusters

| Cluster | Games | Problem | Resolution |
|---------|-------|---------|------------|
| **Boss HP + phases** | Raid, Titan, Bounty Board, Hold the Line, Cerberus | Shared meter, weak points, enrage / lowest-visit punish | **Keep Raid** (+ Cerberus for roles). Cut or fold rest into Raid tiers / Journey stages |
| **Heist / combo chains** | The Vault, Heist Crew, Lockpick, Ritual, Circuit | Ordered segment combos + team pool | **Keep The Vault**. Lockpick = Vault checkout-skin variant later. Cut Heist Crew, Ritual, Circuit |
| **Wave / survival** | Siege, Last Stand | Round objectives + team fail | **Keep Siege** only; Last Stand = Siege endless high-score mode flag |
| **Bot chase PvE** | The Chaser, Bridge, Deep Dive | Virtual pressure meters vs bots | **Cut** — conflicts with no-bot direction on Clear the Board; use Decay variant instead |
| **Hockey blockers** | Slap Shot, Crease | Same sport, goalie blocks doubles | **Keep Crease** (tight). Slap Shot = v2 if Crease ships |
| **Territory / escort** | Bridge, Lineout, Pressure Ladder | March around board 20→1 | **Cut** — planned Around the Clock + Journey stages cover this |
| **Golf strokes** | Bunker, Fairway 501 | Skins / par vs planned Golf | **Cut** — ship planned Golf first; Bunker as Golf setup preset |
| **Basketball contest** | Full Court Press | Defender nominates hot segment | **Cut** — same blocker DNA as Crease / Slap Shot goalie |
| **Spatial grid** | Segment Heist, Fleet, Clear the Board, planned Tic-Tac-Toe | Cells on board map | **Keep Fleet + Clear the Board**. Cut Segment Heist (planned Tic-Tac-Toe exists) |
| **Sequence memory** | Simon Board, Dartle, Cold Call | App calls sequence / secret | **Keep Dartle + Cold Call**. Cut Simon Board |
| **Voice / blind roles** | Echo, Buddy Relay, Fire Team | Caller + thrower | **Keep Echo + Buddy Relay**. Fire Team = Raid + Echo mash — cut |
| **Hidden commit** | Double Bluff, Whisper Cricket, Fleet | Secret state | All distinct — **keep all three** (2p bluff / cricket / battleship) |
| **Checkout race** | Cutthroat Checkout, Tag Out, Lockpick | Shared checkout start | **Cut** — close to planned Knockout / standard X01 party |
| **Modifiers** | Segment Draft, Wind Shift, Streak Wager | Not standalone modes | **Keep as overlays** on X01/Cricket — not catalog rows |
| **Journey formats** | Journey Gauntlet, Gauntlet Squad | Orchestrator over existing engines | **Not separate modes** — Campaign JSON only |
| **Orchestrator** | Remix Night | Meta mode | **Keep one** meta mode for party night |

### Also overlaps **planned catalog** (don't double-build)

| Custom idea | Planned mode | Action |
|-------------|--------------|--------|
| Segment Heist | Tic-Tac-Toe | Use planned spec |
| Fairway 501 / Bunker | Golf | Use planned Golf |
| Slap Shot (goals on doubles) | Football | Different flavor but pick one scorer-on-doubles party mode |
| Pressure Ladder | Around the Clock | Practice ladder = ATC variant |
| Contract Killer | Killer | Killer + hidden contracts layer |

---

### Recommended core roster (~15) — **all specced**

Authoritative rules live in `specs/game-modes/planned/{Mode}GameSpec.md` — do not edit rules in this brainstorm.

| Tier | Game | Spec |
|------|------|------|
| **S** | Raid | [`RaidGameSpec.md`](../specs/game-modes/planned/RaidGameSpec.md) |
| **S** | Fleet | [`FleetGameSpec.md`](../specs/game-modes/planned/FleetGameSpec.md) |
| **S** | Clear the Board | [`ClearTheBoardGameSpec.md`](../specs/game-modes/planned/ClearTheBoardGameSpec.md) |
| **S** | Echo | [`EchoGameSpec.md`](../specs/game-modes/planned/EchoGameSpec.md) |
| **S** | Remix Night | [`RemixNightGameSpec.md`](../specs/game-modes/planned/RemixNightGameSpec.md) |
| **A** | The Vault | [`TheVaultGameSpec.md`](../specs/game-modes/planned/TheVaultGameSpec.md) |
| **A** | Whisper Cricket | [`WhisperCricketGameSpec.md`](../specs/game-modes/planned/WhisperCricketGameSpec.md) |
| **A** | Mirror Match | [`MirrorMatchGameSpec.md`](../specs/game-modes/planned/MirrorMatchGameSpec.md) |
| **A** | Dartle | [`DartleGameSpec.md`](../specs/game-modes/planned/DartleGameSpec.md) |
| **A** | Cerberus | [`CerberusGameSpec.md`](../specs/game-modes/planned/CerberusGameSpec.md) |
| **A** | Cold Call | [`ColdCallGameSpec.md`](../specs/game-modes/planned/ColdCallGameSpec.md) |
| **B** | End Sheet | [`EndSheetGameSpec.md`](../specs/game-modes/planned/EndSheetGameSpec.md) |
| **B** | Crease | [`CreaseGameSpec.md`](../specs/game-modes/planned/CreaseGameSpec.md) |
| **B** | Pallino | [`PallinoGameSpec.md`](../specs/game-modes/planned/PallinoGameSpec.md) |
| **C** | Buddy Relay | [`BuddyRelayGameSpec.md`](../specs/game-modes/planned/BuddyRelayGameSpec.md) |
| **C** | Contract Killer | [`ContractKillerGameSpec.md`](../specs/game-modes/planned/ContractKillerGameSpec.md) |
| **C** | Double Bluff | [`DoubleBluffGameSpec.md`](../specs/game-modes/planned/DoubleBluffGameSpec.md) |
| **C** | Press | [`PressGameSpec.md`](../specs/game-modes/planned/PressGameSpec.md) |

**Modifiers (not modes):** Segment Draft · Wind Shift · Streak Wager

**Journey only (not catalog):** Gauntlet Squad / Journey Gauntlet

---

### Cut list (archive — merge later if needed)

| Cut | Merge into / reason |
|-----|---------------------|
| Titan | Raid difficulty preset (single weak-point phase) |
| Bounty Board | Raid Expose phase variant |
| Hold the Line | Siege wave type |
| Fire Team | Echo + Raid stage |
| Heist Crew | Vault + alarm setup chip |
| Lockpick | Vault `checkoutLocks` preset |
| Ritual, Circuit | Vault combo engine |
| Last Stand | Siege `endless` flag |
| The Chaser, Bridge, Deep Dive, Outbreak | Decay / Siege pressure; no extra bots |
| Slap Shot, Full Court Press, Lineout | Crease + End Sheet cover sports blockers |
| Bunker, Fairway 501 | Planned Golf |
| Segment Heist | Planned Tic-Tac-Toe |
| Simon Board | Dartle + Call & Hit |
| Tag Out, Cutthroat Checkout | Standard team / party X01 when ready |
| Order Up | Fun but low uniqueness vs Vault tickets — revisit post-1.0 |
| Siege *if* only one PvE follow-up | Pick **Cerberus** OR **Siege**, not both initially |
| Pressure Ladder | Around the Clock adaptive preset |

---

### Suggested build order (trimmed)

1. **Raid** → **The Vault** → **Clear the Board** (three pillars: boss / co-op puzzle / competitive paint)
2. **Fleet** + **Echo** (hidden + voice brand)
3. **Remix Night** (shows catalog breadth)
4. One sports: **End Sheet** or **Crease**
5. **Mirror Match** + **Dartle** (retention)
6. **Cerberus** *or* **Siege** (second co-op boss shape)
7. Journey **Gauntlet Squad** content (not new engine)

---

## Product tiering

| Tier | Games | Rationale |
|------|-------|-----------|
| **Ship first** | Mirror Match, Pressure Ladder, Remix Night, Dartle, **Crease**, **Bunker**, **Cold Call**, **Press**, **Cutthroat Checkout** | Tight rules; reuse checkout, voice, or elimination chrome |
| **Medium** | Whisper Cricket, Contract Killer, Fairway 501, **End Sheet**, **Pallino**, **Full Court Press**, **Fleet**, **Double Bluff**, **Circuit**, **Simon Board**, **Lockpick**, **Titan**, **Siege**, **The Chaser** | One new mechanic (hidden state, chains, co-op pool, waves) |
| **Flagship** | Echo, Buddy Relay, Journey Gauntlet, **Slap Shot**, **Lineout**, **The Vault**, **Raid**, **Order Up**, **Cerberus**, **Gauntlet Squad**, **Fire Team** | Co-op PvE, boss phases, roles, or accessibility |

### Recommended first trio (maximum differentiation)

1. **Echo** — accessibility flagship; extends Guided Play story.
2. **Mirror Match** — stats moat; uses data competitors don't retain locally.
3. **Remix Night** — party hook; showcases catalog breadth in one session.

### Recommended co-op PvE trio (after Raid)

1. **The Vault** or **Titan** — fast follow; Vault has no bot AI; Titan reuses boss bar with simpler rules.
2. **Siege** — best 4-player pub night; wave variety.
3. **Gauntlet Squad** — Journey pack once 2+ engines ship; marketing trailer material.

---

## Catalog mapping (draft)

| Game | Proposed catalog id | `GameplayUITemplate` | `GameModeSection` |
|------|---------------------|----------------------|-------------------|
| Echo | `party.echo` | voice drill (new) | party |
| Whisper Cricket | `party.whisperCricket` | `markBoard` | party |
| Mirror Match | `practice.mirrorMatch` | `checkoutScore` / `markBoard` | practice |
| Pressure Ladder | `practice.pressureLadder` | `sequenceProgress` | practice |
| Buddy Relay | `party.buddyRelay` | `roleSplit` | party |
| Segment Heist | `party.segmentHeist` | `boardState` | party |
| Contract Killer | `party.contractKiller` | `livesElimination` | party |
| Remix Night | `party.remixNight` | orchestrator (new) | party |
| Tournaments _(platform)_ | _(Play → Tournament)_ | hub + bracket | party |
| Journey Gauntlet | _(campaign content, not catalog row)_ | — | — |
| Fairway 501 | `practice.fairway501` | `inningPoints` | practice |
| Streak Wager | _(modifier overlay)_ | — | — |
| Dartle | `practice.dartle` | `sequenceProgress` | practice |
| End Sheet | `party.endSheet` | `territoryAim` (new) | party |
| Slap Shot | `party.slapShot` | `phaseRace` + blocker | party |
| Crease | `party.crease` | `territoryAim` | party |
| Pallino | `party.pallino` | `territoryAim` | party |
| Full Court Press | `party.fullCourtPress` | `roleSplit` | party |
| Lineout | `party.lineout` | `sequenceProgress` | party |
| Bunker | `party.bunker` | `inningPoints` | party |
| The Vault | `party.theVault` | `phaseRace` (shared) | party |
| Tag Out | `party.tagOut` | `checkoutScore` (team) | party |
| Lockpick | `practice.lockpick` | `soloChallenge` | practice |
| Fleet | `party.fleet` | `boardState` | party |
| Double Bluff | `party.doubleBluff` | `roleSplit` | party |
| Cold Call | `practice.coldCall` | voice drill | practice |
| Segment Draft | _(setup modifier)_ | overlay | — |
| Press | `party.press` | `soloChallenge` | party |
| Wind Shift | _(round modifier)_ | overlay | — |
| Circuit | `party.circuit` | `sequenceProgress` | party |
| Order Up | `party.orderUp` | `inningPoints` | party |
| Simon Board | `practice.simonBoard` | `sequenceProgress` | practice |
| Cutthroat Checkout | `party.cutthroatCheckout` | `checkoutScore` | party |
| Raid | `party.raid` / Journey | `phaseRace` | party |
| Siege | `party.siege` | `phaseRace` (waves) | party |
| The Chaser | `party.chaser` | `checkoutScore` (team) | party |
| Cerberus | `party.cerberus` | `roleSplit` + boss | party |
| Outbreak | `party.outbreak` | `boardState` | party |
| Deep Dive | `party.deepDive` | `phaseRace` + meter | party |
| Heist Crew | `party.heistCrew` | `phaseRace` (shared) | party |
| Hold the Line | `party.holdTheLine` | `sequenceProgress` | party |
| Last Stand | `party.lastStand` | orchestrator | party |
| Titan | `party.titan` | `phaseRace` | party |
| Bridge | `party.bridge` | `sequenceProgress` | party |
| Ritual | `party.ritual` | `sequenceProgress` | party |
| Bounty Board | `party.bountyBoard` | `markBoard` variant | party |
| Fire Team | `party.fireTeam` | `roleSplit` + boss | party |
| Gauntlet Squad | Journey content | orchestrator | — |
| Clear the Board | `party.clearTheBoard` | `boardState` (ring cells) | party |

New templates to spec before promotion:
- **Voice drill** — shares shell with Call & Hit ([`VoiceDrillUITemplateSpec.md`](../specs/game-modes/planned/VoiceDrillUITemplateSpec.md))
- **Orchestrator** — multi-leg coordinator; platform spec: [`TournamentSpec.md`](../specs/TournamentSpec.md)
- **Territory aim** — alternating throws, blocker nomination, end-of-round resolution (curling / bocce / shootout family)
- **Co-op PvE platform** — shared meters, boss chrome, team summary, wave scripts (draft: `specs/CoopPvEModesSpec.md` when Raid ships)

---

## Open questions

1. **Catalog vs Journey-only** — Should Mirror Match and Journey Gauntlet appear in Modes tab, or only inside Journey?
2. **Honor scoring** — Echo and Buddy Relay assume human verification. Is Companion UI required for v1, or is opponent tap sufficient?
3. **Remix Night scope** — Which shipped modes can be composed in v1 (only 5 engines today)?
4. **Streak Wager** — Standalone mode or optional "house rule" toggle on X01/Cricket setup?
5. **Naming** — "Echo," "Dartle," "Segment Heist" are working titles; legal/trademark check before marketing.
6. **Stat kinds** — Several ideas need new `ModeStatKind` values (e.g. `ghostDelta`, `dailyPuzzle`, `contractFulfillment`, `endsWon`, `shootoutConversion`).
7. **Sports vs catalog overlap** — Bunker vs planned Golf; Slap Shot vs planned Football — differentiate in marketing or merge rules.
8. **Spatial fidelity** — Pallino adjacency proxy vs future visual board / camera assist for true "closest stone."
9. **Co-op scoring** — The Vault / Lockpick need a shared summary screen variant (extend [`SoloPracticeMatchSummarySupplement.md`](../specs/SoloPracticeMatchSummarySupplement.md)).
10. **Modifiers vs modes** — Segment Draft and Wind Shift as overlays on existing engines vs standalone catalog rows.
11. **Co-op PvE platform** — Extract shared co-op summary + boss participant from Raid into `CoopPvEModesSpec.md` before second PvE mode.
12. **Hero count cap** — Raid caps at 3 humans; Siege/Cerberus want 4 — unify at 4 for all PvE?

---

## Promotion path

When an idea graduates from brainstorm:

1. Lock rules in a new `specs/game-modes/planned/{Mode}GameSpec.md` (e.g. **Raid** — [`RaidGameSpec.md`](../specs/game-modes/planned/RaidGameSpec.md)).
2. Add catalog row to [`GameModeCatalog.swift`](../Features/Modes/GameModeCatalog.swift) with `status: .planned`.
3. Update [`specs/game-modes/README.md`](../specs/game-modes/README.md) and [`docs/feature-inventory.md`](../docs/feature-inventory.md).
4. Link back to this doc from the spec's **Brainstorm** section; stop duplicating narrative here.

---

## Index

- Traditional modes (24 planned) — [`additional-game-modes.md`](additional-game-modes.md)
- Party / practice assessments — [`party-practice-modes.md`](party-practice-modes.md)
- Backlog — [`backlog.md`](backlog.md)
