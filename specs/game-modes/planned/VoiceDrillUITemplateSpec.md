# Voice Drill UI Template (Template J) Specification

## 1. Purpose
Define **Template J — Voice drill**: the shared gameplay shell for honor-scored, callout-driven practice modes. First consumer: Call & Hit ([`CallAndHitGameSpec.md`](CallAndHitGameSpec.md)).

**Status:** Planned — new `GameplayUITemplate` case (`voiceDrill`) when Call & Hit ships.

**Note:** Template G is **phase race** (Football) in [`GameModeCatalog.swift`](../../../Features/Modes/GameModeCatalog.swift). Voice drill is **J**, not G.

**References:**
- [`UIBlueprintSpec.md`](../../UIBlueprintSpec.md) — global chrome contract
- [`DesignSystemSpec.md`](../../DesignSystemSpec.md) — typography, tap targets
- [`CalloutVoicesSpec.md`](../../CalloutVoicesSpec.md) — TTS behavior
- [`docs/full-game-catalog-ui.md`](../../../docs/full-game-catalog-ui.md) §5 Template J

---

## 2. Modes using this template

| Mode | Catalog id | Notes |
|------|--------------|-------|
| Call & Hit | `practice.callAndHit` | Hit/Miss self-report |
| *(future)* Checkout callouts | TBD | Same shell; different target generator |

**Not Template J:** Bob's 27 / Halve-It (Template F — scored solo challenge with dart pad). Around the Clock (Template E — sequence strip + pad).

---

## 3. Fixed chrome contract

Four slots — same discipline as other templates ([`full-game-catalog-ui.md`](../../../docs/full-game-catalog-ui.md) §5):

```text
+--------------------------------------------------+
| [Nav] Call & Hit          [Pause] [Callouts ⌁]   |  ← header
|--------------------------------------------------|
|                                                  |
|              ┌─────────────┐                     |
|              │     16      │                     |  ← hero (target)
|              │  [segment   │                     |
|              │   diagram]  │                     |
|              └─────────────┘                     |
|           12 / 50  ·  streak 4                   |  ← progress row
|           Up to 3 darts                          |  ← attempt hint
|--------------------------------------------------|
|     [        HIT        ] [       MISS       ]   |  ← primary actions
+--------------------------------------------------+
```

### Slot rules
| Slot | Content | Stable across targets? |
|------|---------|------------------------|
| Header | Mode title, pause, callouts toggle | Yes |
| Hero | Current target + optional diagram | Changes per target |
| Progress | `n / total`, streak, darts hint | Updates per target |
| Actions | Hit · Miss (no dart pad) | Fixed position |

**No scoring pad** in v1 — distinguishes Template J from A–F.

---

## 4. Layout — portrait (iPhone)

- Hero target: minimum 64pt dynamic type at default; scales with Dynamic Type to `accessibility3` with scroll if needed
- Hit / Miss: equal width, min height 56pt, 16pt horizontal gap
- Safe area inset: actions pinned above home indicator
- Practice section accent from `GameModeAccent` keyed on `practice.callAndHit`

---

## 5. Layout — landscape

Per [`UIBlueprintSpec.md`](../../UIBlueprintSpec.md) gameplay landscape pattern:

```text
+----------------------------------------------------------+
| Nav · progress                                            |
|----------------------------------------------------------|
|  [ Hero target + diagram ]     |  [ HIT ]               |
|  streak · darts hint           |  [ MISS ]              |
+----------------------------------------------------------+
```

Hit/Miss stack in **trailing column**; hero fills leading region.

---

## 6. Interaction

| Action | Behavior |
|--------|----------|
| Hit | Record hit; haptic light; optional confirm TTS (off by default); advance |
| Miss | Record miss; haptic medium; advance |
| Early Hit | Same as Hit — allowed any time before Miss |
| Undo (toolbar or shake-disabled) | Toolbar **Undo** restores previous target for re-throw |
| Pause | Standard match pause sheet |
| Callouts toggle | Session override; icon state reflects on/off |
| End session | Destructive confirm → abandon match |

**Button enablement:** Hit and Miss always enabled during active target. No "wait for speech to finish" gate (non-blocking TTS).

---

## 7. Target presentation

| Element | Singles | Doubles | Triples | Bull |
|---------|---------|---------|---------|------|
| Primary label | `16` | `D16` | `T16` | `Bull` |
| Secondary | optional word form | "Double 16" | "Triple 16" | — |
| Diagram | single wedge highlight | double ring | triple ring | bull ring |

Diagram is **decorative + a11y** — VoiceOver label must match spoken callout phrase.

**Reduce Motion:** cross-fade or instant swap (no slide-from-off-screen).

---

## 8. Accessibility

| WCAG | Requirement |
|------|-------------|
| 1.1.1 | Target diagram has accessibility label |
| 1.4.3 | Hit/Miss meet contrast; don't rely on green/red alone — icons + labels |
| 2.5.5 | 44×44pt minimum touch targets |
| 4.1.3 | Announce target on appear via `UIAccessibility.post` + optional TTS |

Manual evidence: [`call-and-hit-match.md`](../../../accessibility/wcag-2.1-aa/screens/call-and-hit-match.md)

---

## 9. State → view mapping

| Engine state | UI |
|--------------|-----|
| `readyTarget` | Show target at `currentIndex`, enable Hit/Miss |
| `advancing` | Brief disabled state (<100ms) to prevent double-tap |
| `complete` | Navigate to Match Summary |
| `paused` | Overlay or system pause — target frozen |

---

## 10. Reuse plan

| Component | New? |
|-----------|------|
| `VoiceDrillMatchScreen` | New — parameterized by mode VM |
| `VoiceDrillTargetHeroView` | New |
| `HitMissActionBar` | New — reusable for future honor modes |
| Match pause / summary shell | Reuse existing Play shared |

---

## 11. Verification
| Field | Value |
|-------|--------|
| **Status** | Planned |
