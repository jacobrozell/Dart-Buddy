# Guided Practice — Match Screen (WCAG 2.1 AA)

**Screen:** Guided Practice active session (thrower + guide layouts)  
**Spec:** [`specs/game-modes/planned/GuidedPracticeSpec.md`](../../../specs/game-modes/planned/GuidedPracticeSpec.md)  
**Platform:** [`specs/GuidedPlayAccessibilitySpec.md`](../../../specs/GuidedPlayAccessibilitySpec.md)  
**Status:** Planned — draft QA checklist for **if/when** Guided Practice is built; not a current release gate.

---

## Scope

Guided Practice match: thrower (VoiceOver + TTS) and guide (sighted verifier) flows. Setup and summary use sibling docs.

---

## Release gate (Guided Play)

Guided Practice must not ship until manual pass complete — **when product commits to the feature.** Not applicable while R&D-only.

---

## Thrower solo path (VoiceOver)

| Step | Expected |
|------|----------|
| Target advance | VO announces target; TTS speaks target |
| Hit focus | “Hit, {target}” |
| Miss focus | “Miss, {target}” |
| Progress | “Target N of M” on focus or announcement |
| Summary | Performance hero fully spoken |

Script: create `evidence/voiceover/guided-practice-solo-core-flow.md` at implementation.

---

## Guide path

| Step | Expected |
|------|----------|
| Hit / Miss | Visible labels; VO optional for guide |
| Detail chips | Full words, not abbreviations |
| Repeat callout | Announces intent clearly |
| Thrower feedback | TTS audible — manual verify with listener at oche distance |

---

## Criteria checklist

| Criterion | Status | Notes |
|-----------|--------|-------|
| 1.1.1 | Pending | Target + diagram labels |
| 2.5.5 | Pending | Hit/Miss ≥ 44pt; guide buttons ≥ 56pt |
| 4.1.3 | Pending | Target change + result announcements |
| 3.2.2 | Pending | No auto-advance without guide confirm |

---

## Client environment

Log `isVoiceOverRunning` at session start for analytics correlation — not a substitute for this manual pass.

---

## Evidence (to add)

- [ ] `evidence/voiceover/guided-practice-solo-core-flow.md`
- [ ] `evidence/voiceover/guided-practice-guide-flow.md`
- [ ] Optional: blind tester session notes (consent, no PII)
