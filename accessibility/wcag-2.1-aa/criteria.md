# WCAG 2.1 AA criteria map (Dart Buddy)

Success criteria in scope for the iPhone MVP. **Required** = release gate for core flows. **Recommended** = track; fix before GA if feasible.

Dart Buddy extensions (**DBX-***) come from `specs/AccessibilitySpec.md` and `specs/UIReviewChecklist.md`, not from WCAG alone.

---

## Perceivable

| ID | WCAG SC | Level | Required | iOS / app check | Global status | Notes |
|----|---------|-------|----------|-----------------|---------------|-------|
| P-1.1.1 | 1.1.1 Non-text Content | A | Yes | SF Symbols and charts have text alternatives; decorative icons hidden or ignored | Partial | X01 pad keys labeled; charts + Cricket pad still partial |
| P-1.3.1 | 1.3.1 Info and Relationships | A | Yes | Headings, lists, and grouped controls expose structure to VoiceOver | Partial | Forms/lists OK; gameplay cards fragmented |
| P-1.3.2 | 1.3.2 Meaningful Sequence | A | Yes | VoiceOver order matches visual priority (score → input → actions) | Untested | Manual VO pass per screen |
| P-1.3.4 | 1.3.4 Orientation | AA | Yes | Portrait and landscape complete core tasks | Untested | `todo.md`: iPad/landscape layouts open |
| P-1.4.1 | 1.4.1 Use of Color | A | Yes | State not conveyed by color alone (icons, text, patterns) | Partial | Cricket marks strong; X01 active bar + color |
| P-1.4.3 | 1.4.3 Contrast (Minimum) | AA | Yes | 4.5:1 normal text, 3:1 large text on backgrounds | Partial | `evidence/contrast/brand-token-samples-2026-06-02.md` |
| P-1.4.4 | 1.4.4 Resize Text | AA | Yes | Dynamic Type through accessibility sizes; critical scores legible | Partial | Fixed `.system(size:)` on pad and score cards |
| P-1.4.10 | 1.4.10 Reflow | AA | Yes | No horizontal scroll for content at 320px width equivalent | Untested | Landscape gameplay layout |
| P-1.4.11 | 1.4.11 Non-text Contrast | AA | Yes | UI control boundaries vs adjacent colors ≥ 3:1 | Untested | Pad keys, chips, toggles |
| DBX-CONTRAST-MODES | — | — | Yes | Light and dark both pass P-1.4.3 on primary surfaces | Partial | Token audit + orientation matrix; CTA uses large type |

---

## Operable

| ID | WCAG SC | Level | Required | iOS / app check | Global status | Notes |
|----|---------|-------|----------|-----------------|---------------|-------|
| O-2.1.1 | 2.1.1 Keyboard | A | N/A* | External keyboard can reach controls | N/A | Touch-first; verify if iPad pointer/keyboard tested |
| O-2.4.3 | 2.4.3 Focus Order | A | Yes | VoiceOver focus order logical | Untested | |
| O-2.4.4 | 2.4.4 Link Purpose (In Context) | A | Yes | Buttons/links describe action in label | Partial | Some icon-only toolbar buttons labeled |
| O-2.5.1 | 2.5.1 Pointer Gestures | A | Yes | No path-only gestures for essential actions | Pass | Tap-only scoring |
| O-2.5.2 | 2.5.2 Pointer Cancellation | A | Yes | Up-event activates; destructive confirm | Partial | Match exit confirm present |
| O-2.5.3 | 2.5.3 Label in Name | A | Yes | Visible label matches accessible name | Partial | X01 pad VO uses full dart names; Cricket pad still open |
| O-2.5.4 | 2.5.4 Motion Actuation | A | Yes | No shake/tilt-only actions | Pass | |
| DBX-TARGET-44 | — | — | Yes | Interactive targets ≥ 44×44 pt (52×52 gameplay) | Partial | Pad 52pt; verify chips and cricket cells |
| DBX-REDUCE-MOTION | — | — | Yes | Respect Reduce Motion for non-essential animation | Partial | `MatchSummaryScreen` gates celebration; manual evidence pending |

---

## Understandable

| ID | WCAG SC | Level | Required | iOS / app check | Global status | Notes |
|----|---------|-------|----------|-----------------|---------------|-------|
| U-3.1.1 | 3.1.1 Language of Page | A | Yes | App language matches `Localizable.strings` | Partial | English strings remain on several screens |
| U-3.2.1 | 3.2.1 On Focus | A | Yes | Focus does not auto-change context unexpectedly | Pass | |
| U-3.2.2 | 3.2.2 On Input | A | Yes | Input does not auto-submit without expectation | Pass | X01 auto-submit after 3 darts is expected gameplay |
| U-3.3.1 | 3.3.1 Error Identification | A | Yes | Errors described in text | Partial | Bust banner; some keys localized |
| U-3.3.2 | 3.3.2 Labels or Instructions | A | Yes | Inputs have visible + accessible labels | Partial | Setup chips; pad multiplier state |

---

## Robust

| ID | WCAG SC | Level | Required | iOS / app check | Global status | Notes |
|----|---------|-------|----------|-----------------|---------------|-------|
| R-4.1.2 | 4.1.2 Name, Role, Value | A | Yes | Controls expose name, role, state, value | Partial | X01 pad + score card labeled; Cricket pad + DS primitives open |
| DBX-A11Y-IDS | — | — | Recommended | Stable `accessibilityIdentifier` for automation | Partial | Setup, history, X01; not universal |
| DBX-DESIGN-SYSTEM | — | — | Yes | Reusable components expose default a11y props | Fail | `DesignSystemSpec` not fully implemented |

---

## Core flow definition

Screens on the **release-critical path**:

`play-home` → `match-setup` → (`x01-match` | `cricket-match`) → `match-summary`

Plus tab sustainability: `history-list`, `history-detail`, `players-list`, `settings`, `migration-recovery`, `statistics`.

---

## Verification methods

| Method | Tool / action | Evidence location |
|--------|---------------|---------------------|
| VoiceOver | Device or Simulator + VO on | `evidence/voiceover/` |
| Automated XCTest | `WCAGAccessibilityUITests` audits + identifier contracts on core screens | CI |
| Dynamic Type | Settings → Display → Larger Text → AXXXL | `evidence/dynamic-type/` or `snapshots/*-axxxl-*` |
| Contrast | Accessibility Inspector → Color Contrast | `evidence/contrast/` |
| Orientation | Portrait + landscape × light + dark | `evidence/orientation/` |
| Reduce Motion | Settings → Accessibility → Motion | `evidence/reduce-motion/` |
