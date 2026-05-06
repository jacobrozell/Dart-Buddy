# Design System Specification

## 1. Purpose
Provide a practical, Apple-native design system the team can execute consistently across setup, gameplay, history, players, and settings.

This document defines:
- design principles
- visual and interaction tokens
- reusable components
- screen composition patterns
- quality gates for release

---

## 2. Product UX Direction (iOS)
- **Fast at a glance:** core score state is readable from arm's length.
- **One primary action per screen:** avoid competing CTAs.
- **Low cognitive load in gameplay:** keep in-turn actions near thumb reach and visually stable.
- **Trustworthy state:** users always know whose turn it is, what changed, and how to undo.
- **Native feel over novelty:** prefer SwiftUI platform patterns unless gameplay speed clearly benefits from custom UI.

---

## 3. Design Principles
- Readability first (distance-friendly score views).
- Consistency across game modes and tabs.
- Accessibility as baseline, not add-on.
- Progressive disclosure: advanced settings behind optional controls.
- Clear feedback loops for score entry, busts, checkout, undo, and completion.

---

## 4. Foundations (Tokens)

## 4.1 Spacing
Use an 8pt base scale:
- `space-1 = 4`
- `space-2 = 8`
- `space-3 = 12`
- `space-4 = 16`
- `space-5 = 20`
- `space-6 = 24`
- `space-8 = 32`
- `space-10 = 40`

Rules:
- Screen horizontal padding: `16` (`space-4`).
- Section vertical rhythm: `16` to `24`.
- Dense gameplay clusters: `8` to `12`.

## 4.2 Corner Radius
- `radius-sm = 8`
- `radius-md = 12`
- `radius-lg = 16`
- `radius-xl = 20`
- `radius-pill = 999`

Use:
- Buttons/chips: `12`
- Cards/panels: `16`
- Full-width bottom CTA container: `20`

## 4.3 Elevation and Surface
Prefer layered surfaces over heavy shadows:
- `surface/base`
- `surface/raised`
- `surface/emphasis`

Shadow policy:
- Light, single shadow only on raised cards and sticky CTA container.
- No dramatic shadows in gameplay board.

## 4.4 Typography (Dynamic Type Required)
Map to system styles; do not hardcode point sizes where avoidable.
- Display score: `largeTitle` / custom scaled style
- Section title: `title3`
- Body: `body`
- Secondary metadata: `subheadline` / `footnote`
- Button label: `headline`

Rules:
- Use monospaced digits for scores and timers.
- Ensure score text does not clip at accessibility text sizes.
- Minimum body size equivalent to 16pt at default settings.

## 4.5 Semantic Color Roles
Do not design by hex names in UI code. Use semantic roles:
- `color/backgroundPrimary`
- `color/backgroundSecondary`
- `color/textPrimary`
- `color/textSecondary`
- `color/borderSubtle`
- `color/actionPrimary`
- `color/actionPrimaryPressed`
- `color/actionSecondary`
- `color/success` (checkout/completion)
- `color/warning` (bust/invalid state)
- `color/info` (turn indicator)

Rules:
- Must pass contrast in both light and dark mode.
- Never rely on color alone to indicate open/closed cricket marks or win/loss meaning.

## 4.6 Motion and Haptics
- Default animation: subtle ease-out (150 to 220ms).
- Critical state change (turn switch, checkout): medium haptic + concise animation.
- Error entry (invalid input/bust): warning haptic + non-color cue.
- Respect Reduce Motion.

---

## 5. Interaction Tokens
- Minimum touch target 44x44pt; gameplay controls target 52x52pt.
- Sticky primary CTA height: 52 to 56pt.
- Disabled state opacity: 40% to 50% plus semantic text explanation where useful.
- Confirmation dialogs use destructive emphasis only when truly irreversible.

---

## 6. Core Components

## 6.1 Buttons
- `PrimaryActionButton`
- `SecondaryActionButton`
- `DestructiveActionButton` (rare)

States: default, pressed, disabled, loading.

## 6.2 Information and Status
- `ScoreValueCard`
- `TurnIndicatorBadge`
- `ModeBadge`
- `StatChip`
- `EmptyStateCard`

## 6.3 Identity
- `PlayerAvatarChip`
- `PlayerRowCard`

## 6.4 Input
- `ScoringInputPad`
- `StepperField` (legs/sets)
- `OptionSegment` (mode/check-out)
- `InlineValidationMessage`

## 6.5 Feedback and Recovery
- `UndoBar`
- `ConfirmExitDialog`
- `ErrorBanner`
- `SuccessBanner`

All components must expose accessibility labels/hints and stable identifiers.

---

## 7. Screen Composition Templates

## 7.1 Setup Screen Template
- Top: title + short helper copy.
- Middle: grouped form sections.
- Bottom: sticky `Start Match` CTA.
- Inline validation near field plus summary warning near CTA when blocked.

## 7.2 Active Match Template
- Top region (persistent): players, turn indicator, legs/sets.
- Middle region: mode board (X01/Cricket).
- Bottom region (persistent): scoring input and `Undo`.

Rules:
- Keep top and bottom regions fixed where possible to reduce visual reflow.
- The most frequent action should remain in same physical location each turn.

## 7.3 Match Summary Template
- Winner hero card.
- Match metadata row (duration, mode, participants).
- Key metrics chips.
- Primary CTA: `New Match`.
- Secondary CTA: `View History Detail` (optional).

---

## 8. Copy and Micro-UX Guidelines
- Use direct verbs: `Start Match`, `Undo Turn`, `Resume Match`.
- Error text states fix path: "Select at least 2 players."
- Prefer plain language over darts shorthand in accessibility labels.
- Confirmation copy answers: what action, consequence, and escape route.

---

## 9. Accessibility and Localization Gates
- Follow `specs/AccessibilitySpec.md` (WCAG 2.1 AA).
- Follow `specs/LocalizationSpec.md`.
- No truncation of critical gameplay state in large text modes.
- VoiceOver order must match visual hierarchy.
- Every icon-only control requires label and hint.

---

## 10. Implementation Guidance (SwiftUI)
- Build all reusable views in a `DesignSystem` module/folder.
- Keep components stateless when possible; pass view models/state in from features.
- Define design tokens once (colors, spacing, radius, typography helpers).
- Add preview matrix per component:
  - light/dark
  - Dynamic Type sizes
  - long localized strings
  - enabled/disabled/loading states

---

## 11. Quality Checklist (Before Merge)
- Uses only semantic tokens (no ad hoc spacing/color literals in feature views).
- Includes accessibility labels, hints, and identifiers.
- Tested in light and dark mode.
- Tested at accessibility text sizes.
- Primary action is visually and functionally obvious.
- Gameplay-critical actions are reachable with one hand on common iPhone sizes.

---

## 12. Adoption Plan (Recommended)
1. Implement token layer (`Color`, spacing, radius, typography helpers).
2. Build button, chip, card, and form primitives.
3. Refactor Setup and Active Match screens to templates first.
4. Add preview gallery and lightweight screenshot regression checks.
5. Enforce checklist in PR reviews.

---

## 13. Compliance Links
- Accessibility requirements: `specs/AccessibilitySpec.md`.
- Localization/i18n requirements: `specs/LocalizationSpec.md`.
- Setup flow behavior: `specs/SetupFlowSpec.md`.
- Match flow behavior: `specs/MatchSpec.md`.
