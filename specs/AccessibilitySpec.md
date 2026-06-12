# Accessibility Specification

## 1. Purpose
Define accessibility requirements for MVP and future releases, with WCAG 2.1 AA as the target standard.

---

## 2. Standard and Scope
- Target: `WCAG 2.1 AA`
- Platforms in scope for MVP: iPhone app UI and core flows
- Accessibility is a release gate, not a post-release enhancement
- Supported orientations for MVP: portrait and landscape on iPhone

---

## 3. Core Requirements
- Text contrast must meet WCAG 2.1 AA contrast ratios.
- Interactive controls must be reachable and understandable with VoiceOver.
- Minimum touch target: 44x44 pt (52x52 preferred in gameplay input).
- Do not rely on color alone to convey meaning (use text/icons/pattern).
- Support Dynamic Type up to accessibility sizes without clipping critical score info.
- Respect Reduce Motion and other system accessibility preferences (implementation catalog and gameplay motion rules: [`AnimationSpec.md`](AnimationSpec.md)).
- Light mode and dark mode must both pass contrast and legibility checks.
- Landscape layouts must preserve core task completion without hidden critical controls.

---

## 4. Gameplay-Specific Accessibility
- Scoring input buttons must have explicit labels (e.g., `Triple 20` not `T20` only).
- Turn indicator must be announced with clear context.
- Bust/check-out feedback must include non-visual cues.
- Cricket board closed/open states require non-color indicators.

### Guided Play (planned)
Blind and low-vision practice flows require audio-first design beyond baseline WCAG. See [`GuidedPlayAccessibilitySpec.md`](GuidedPlayAccessibilitySpec.md):
- TTS target callouts and spoken Hit/Miss results
- Optional sighted guide verifier UI
- VoiceOver-first Template J practice loop
- Manual release gate: [`guided-practice-match.md`](../accessibility/wcag-2.1-aa/screens/guided-practice-match.md)

Do not confuse **Guided Play** with the party game Blind Killer (`party.blindKiller`).

---

## 5. Engineering Rules
- Every reusable component in `DesignSystem` must expose accessibility props by default.
- Accessibility labels/hints must be part of component acceptance criteria.
- New screens require an accessibility review checklist before merge.

---

## 6. Testing
- **Compliance tracker:** `accessibility/wcag-2.1-aa/` (per-screen and criterion status; update when implementing or verifying fixes).
- **Long-term plan:** `accessibility/accessibility_todo.md` (phased backlog).
- Manual VoiceOver pass on all critical flows.
- Dynamic Type checks for setup, gameplay, history, and settings.
- Contrast audit for light and dark themes.
- Manual orientation pass (portrait and landscape) for setup, gameplay, history, and settings.
- Automated regression: `Tests/UI/WCAGAccessibilityUITests.swift` (Xcode `performAccessibilityAudit` + identifier contracts on core screens).

---

## 7. Release Gate
- No launch if critical WCAG 2.1 AA failures are open for core gameplay flows.
