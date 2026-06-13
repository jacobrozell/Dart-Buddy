# Guided Play — Companion (Guide) Specification

## 1. Purpose
Define the **sighted guide / verifier** experience when a partner holds the phone while a blind or low-vision player throws. Mirrors the human caller role from real-world blind darts practice.

**Status:** **WIP / R&D** — companion UI draft; ships only if Guided Practice is pursued.

**Related:**
- [`GuidedPlayAccessibilitySpec.md`](GuidedPlayAccessibilitySpec.md)
- [`GuidedPracticeSpec.md`](game-modes/planned/GuidedPracticeSpec.md)
- [`VoiceDrillUITemplateSpec.md`](game-modes/planned/VoiceDrillUITemplateSpec.md)

---

## 2. Role model

| Role | Location | Sees | Does |
|------|----------|------|------|
| **Thrower** | Oche | Hears only (ideal) | Throws |
| **Guide** | Behind oche / side | Phone UI + board | Confirms outcome, optional detail |

One device, one active match. Guide is **not** a second participant in persistence — role stored in match config only.

---

## 3. Guide screen wireframe

```text
+--------------------------------------------------+
| Guided Practice · Guide          [Pause] [Repeat]|
|--------------------------------------------------|
|  CURRENT TARGET                                   |
|       Double 16                                   |
|  (large — guide may already have called verbally) |
|--------------------------------------------------|
|  Progress: 12 / 50                                |
|--------------------------------------------------|
|  After throw:                                     |
|  [      HIT      ]    [      MISS     ]           |
|--------------------------------------------------|
|  Optional detail (after Miss or tap Add detail):  |
|  [ S10 ] [ S7 ] [ Wide L ] [ Wide R ] [ Wire ]   |
|  [ Skip detail ]                                  |
|--------------------------------------------------|
|  [ Repeat callout for thrower ]                   |
+--------------------------------------------------+
```

### Interaction order
1. App speaks target (thrower hears).
2. Thrower throws.
3. Guide taps Hit or Miss **within ~30s** (no auto-advance).
4. Optional detail chips appear on Miss (or via Add detail).
5. App speaks result to thrower; advances to next target.

**Repeat callout:** Re-triggers TTS without recording a result — for noisy oche or missed audio.

---

## 4. Visual design (guide-facing)

Guide UI is **sighted-optimized** (not VO-primary):

- High contrast Hit (green) / Miss (red-orange) with **icons + text**
- Minimum 56pt button height
- Target typography ≥ 48pt
- No dependency on color alone ([`AccessibilitySpec.md`](AccessibilitySpec.md))

Guide may still use VoiceOver if they are visually impaired — labels must remain complete.

---

## 5. Detail chips

### Contextual adjacency
For target **Double 16**, suggest singles on 16 bed neighbors: S10, S7, S8, S11 (rules engine or static map).

### Generic
| Chip | When |
|------|------|
| Wide left / Wide right | Off-board horizontal |
| Low / High | Vertical miss |
| Wire | Hit wire, no score |
| Bounce out | Left board |
| Skip detail | Miss without nuance |

Max one detail per target in v1. Detail appended to result TTS: *“Miss, double sixteen. Single ten.”*

---

## 6. Thrower feedback path

When guide confirms:

| Channel | Hit | Miss + detail |
|---------|-----|----------------|
| TTS (thrower) | “Hit, double sixteen” | “Miss, double sixteen. Single ten.” |
| Haptics | `.success` long | `.warning` double short |
| VoiceOver | If thrower holds phone: same text posted as announcement |

**Volume:** Respect system volume; Guided Play Settings suggest max volume warning for outdoor oche.

---

## 7. Guide + thrower same person (solo self-report)

Fall back to standard Template J Hit/Miss with VoiceOver-first labels — no detail chips required. Guide layout hidden.

---

## 8. Accessibility (guide)

| Requirement | Implementation |
|-------------|----------------|
| Hit/Miss labels | “Hit, double sixteen” accessibilityLabel |
| Detail chips | Full segment names |
| Repeat | “Repeat callout for thrower” |
| Timeout | No silent auto-advance — guide must confirm |

---

## 9. Analytics

| Event | Metadata |
|-------|----------|
| `guided_companion_hit` | `targetIndex` bucket only |
| `guided_companion_miss` | same |
| `guided_companion_detail` | `detailCategory` enum (adjacent/directional/wire) — **not** raw segment |
| `guided_companion_repeat_callout` | count |

---

## 10. Future improvements
- Guide whispers via earpiece while thrower wears AirPods (routing)
- Custom detail phrase recording
- Second-screen / Watch guide controls
- Guide training onboarding video link in setup

---

## 11. Verification
| Field | Value |
|-------|--------|
| **Status** | WIP / R&D |
