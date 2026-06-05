# Campaign Mode — R&D Brief

**Status:** R&D / post-1.0  
**Depends on:** Multiple game engines + bot ladder; not a single feature PR.

---

## Concept

Single-player (or human vs bot) **ladder**: stages unlock harder bots and new game types. Optional **boss** opponents themed on pro players.

**Already in app (no campaign work):** X01, Cricket standard, Cricket Cut Throat.

**Campaign stages would add over time:**

| Stage content | R&D doc | Rough effort |
|---------------|---------|--------------|
| Killer | [`killer-darts.md`](killer-darts.md) | ~1–2 weeks |
| Baseball | [`baseball-darts.md`](baseball-darts.md) | ~1–2 weeks |
| Bob's 27, Around the Clock | [`party-practice-modes.md`](party-practice-modes.md) | ~3–6 d each |
| Shanghai, Halve-It | [`party-practice-modes.md`](party-practice-modes.md) | ~6–10 d |
| Blind / vision practice | [`AutoScoringVisionSpec.md`](../specs/AutoScoringVisionSpec.md) | months |
| Talk Mode practice | [`talk-mode.md`](talk-mode.md) | ~1–2 weeks X01 MVP |

---

## Campaign-only extras

| Idea | Notes |
|------|--------|
| **Escalating bots** | Reuse `BotDifficulty`, Training Partner, Custom Bot — map stage index → skill profile. |
| **Boss bots (pro names + stats)** | **Content + legal** risk (likeness, trademarks, data rights). Engineering is “preset bot JSON”; sourcing is the hard part. |
| **Progress persistence** | New SwiftData model: `CampaignProgressRecord` (stage, stars, unlocked modes) — not in schema today. |
| **Mission config** | JSON or plist stages: `matchType`, `config`, `botProfile`, win condition. |

---

## Suggested phases

1. **Ladder shell** — UI map, 5–10 X01-only stages, preset bots, local save.  
2. **Mode mix** — Add Cricket, then Killer/Baseball as those engines ship.  
3. **Boss roster** — Only after legal review and one mode path is fun.  

**Do not** block 1.0 or small releases on full campaign scope.

---

## Index

- Mode platform: [`additional-game-modes.md`](additional-game-modes.md)  
- Backlog priority: [`backlog.md`](backlog.md)
