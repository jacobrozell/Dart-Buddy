# Campaign Mode — R&D Brief

**Status:** R&D / post-1.0  
**Depends on:** Campaign shell + progression UI; match engines for stage content already largely exist. Detailed brainstorm: [`.cursor/plans/campaign_mode_brainstorm_871d477e.plan.md`](../.cursor/plans/campaign_mode_brainstorm_871d477e.plan.md).

---

## Concept

Single-player (or human vs bot) **ladder**: stages unlock harder bots and new game types. Optional **boss** opponents themed on pro players.

**Already in app (no campaign work):** X01, Cricket (incl. Cut Throat), Baseball, Killer, Shanghai — see [`GameModeCatalog`](../Features/Modes/GameModeCatalog.swift).

**Campaign stages would add over time:**

| Stage content | Doc / spec | Status |
|---------------|------------|--------|
| Killer | [`specs/game-modes/implemented/KillerGameSpec.md`](../specs/game-modes/implemented/KillerGameSpec.md) | Shipped |
| Baseball | [`specs/game-modes/implemented/BaseballGameSpec.md`](../specs/game-modes/implemented/BaseballGameSpec.md) | Shipped |
| Shanghai | `ShanghaiEngine` + play UI | Shipped |
| Bob's 27, Around the Clock | [`party-practice-modes.md`](party-practice-modes.md) | ~3–6 d each |
| Halve-It, Golf | [`party-practice-modes.md`](party-practice-modes.md) | ~6–10 d |
| Blind / vision practice | [`AutoScoringVisionSpec.md`](../specs/AutoScoringVisionSpec.md) | months |
| Talk Mode practice | [`talk-mode.md`](talk-mode.md) | ~1–2 weeks X01 MVP |

---

## Campaign-only extras

| Idea | Notes |
|------|--------|
| **Escalating bots** | Reuse `BotDifficulty`, Training Partner, Custom Bot — map stage index → skill profile. |
| **Boss bots (pro names + stats)** | **Content + legal** risk (likeness, trademarks, data rights). Engineering is "preset bot JSON"; sourcing is the hard part. |
| **Progress persistence** | New SwiftData model: `CampaignProgressRecord` (stage, stars, unlocked modes) — not in schema today. |
| **Mission config** | JSON or plist stages: `matchType`, `config`, `botProfile`, win condition. |

---

## Suggested phases

1. **Ladder shell** — UI map, 5–10 X01-only stages, preset bots, local save.  
2. **Mode mix** — Add Cricket, Killer, Baseball, Shanghai stages as campaign content (engines already ship).  
3. **Boss roster** — Only after legal review and one mode path is fun.  

**Do not** block 1.0 or small releases on full campaign scope.

---

## Index

- Unshipped modes: [`additional-game-modes.md`](additional-game-modes.md)  
- Backlog priority: [`backlog.md`](backlog.md)
