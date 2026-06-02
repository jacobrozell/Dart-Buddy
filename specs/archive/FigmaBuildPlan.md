# Figma Build Plan

> **Archived (1.0 UI complete):** Historical handoff plan. Active UI contracts: `specs/UIBlueprintSpec.md`, `specs/UIImplementationSpec.md`.

## 1. Purpose
Define exactly how to build and maintain the project Figma file so multiple agents/designers can contribute without visual drift.

This plan is execution-focused and intended for handoff.

Primary references:
- `specs/DesignSystemSpec.md`
- `specs/UIBlueprintSpec.md`
- `specs/UIImplementationSpec.md`
- `specs/UIReviewChecklist.md`
- `specs/AccessibilitySpec.md`

---

## 2. Outcomes Required Before UI Coding
- One shared Figma file with clear page structure.
- Reusable component library with variants and states.
- Full MVP screen set in portrait and landscape.
- Light and dark parity for core flows.
- Annotated handoff frames for engineering.

---

## 3. Figma File Setup

## 3.1 File Name
`DartsScoreboard - Product UI System`

## 3.2 Page Structure (in order)
1. `00 Cover + Changelog`
2. `01 Foundations`
3. `02 Components`
4. `03 Patterns`
5. `04 Screens - Play`
6. `05 Screens - History`
7. `06 Screens - Players`
8. `07 Screens - Settings`
9. `08 Flows + Prototypes`
10. `09 QA Evidence`
11. `99 Archive`

## 3.3 Naming Convention
- Frame: `Screen/<Feature>/<Name>/<Theme>/<Orientation>/<State>`
- Component: `Comp/<Category>/<Name>`
- Variant properties: `theme`, `size`, `state`, `mode`, `icon`, `disabled`

Example:
- `Screen/Play/MatchSetup/Light/Portrait/Invalid`
- `Comp/Button/Primary`

---

## 4. Foundations Build (Page 01)

## 4.1 Variables and Tokens
Create Figma Variables for:
- Color roles (semantic): background, text, action, success, warning, info, border.
- Spacing scale: 4, 8, 12, 16, 20, 24, 32, 40.
- Radius scale: 8, 12, 16, 20, pill.
- Typography roles: display score, title, body, caption, button.

Modes:
- `Light`
- `Dark`

Rules:
- No hardcoded colors in final components/screens.
- Use semantic names aligned to `DesignSystemSpec`.

## 4.2 Typography
Define text styles:
- `Type/DisplayScore`
- `Type/Title`
- `Type/Section`
- `Type/Body`
- `Type/Meta`
- `Type/Button`

Notes:
- Score styles use monospaced digits.
- Include guidance for truncation/wrapping behavior.

## 4.3 Grid and Layout Tokens
- iPhone portrait content width guidance.
- iPhone landscape safe-area guidance.
- Section spacing rhythm examples.

---

## 5. Component Library Build (Page 02)

## 5.1 Priority 1 Components
- `PrimaryActionButton`
- `SecondaryActionButton`
- `DestructiveActionButton`
- `PlayerAvatarChip`
- `ModeBadge`
- `StatChip`
- `ScoreValueCard`
- `InlineValidationMessage`
- `ScoringInputPad` primitives (multiplier button, segment button, turn preview row)

## 5.2 Priority 2 Components
- `TurnIndicatorBadge`
- `UndoBar`
- `ErrorBanner`
- `SuccessBanner`
- `EmptyStateCard`
- `ConfirmDialog`

## 5.3 Required Variants for Each Interactive Component
- `default`
- `pressed`
- `disabled`
- `error` (if applicable)
- `loading` (for primary actions)

## 5.4 Accessibility Annotation per Component
Add a small annotation block near each component:
- Intended accessibility label format
- Min target size
- Non-color status cue requirement

---

## 6. Pattern Library (Page 03)
Create reusable composition patterns:
- Sticky footer CTA pattern
- Top status header pattern (turn + meta)
- Filter chip bar pattern
- List row with trailing metadata pattern
- Detail screen section stack pattern

These patterns reduce drift across screens and accelerate agent output.

---

## 7. Screen Build Plan (Pages 04-07)

Build in this order to unblock engineers quickly:

## 7.1 Play
1. `PlayHome`
2. `MatchSetup`
3. `X01Match`
4. `CricketMatch`
5. `MatchSummary`
6. `MigrationRecovery` (global, can live in Play page)

For each screen, create states:
- `Ready`
- `Loading`
- `Empty` (if applicable)
- `Error`
- `ValidationInvalid` (forms)

## 7.2 History
1. `HistoryList`
2. `HistoryDetail`

States:
- default
- filtered
- empty results
- error

## 7.3 Players
1. `PlayersList`
2. `PlayerDetail`
3. `PlayerEditSheet` (create + edit variants)

## 7.4 Settings
1. `Settings`
2. `Reset confirmation dialog`

---

## 8. Theme and Orientation Matrix (Mandatory)

For each core screen, provide:
- Light + Portrait
- Dark + Portrait
- Light + Landscape
- Dark + Landscape

Core screens for full matrix:
- `MatchSetup`
- `X01Match`
- `CricketMatch`
- `HistoryList`
- `PlayersList`
- `Settings`

If time is constrained, still complete all 4 combinations for X01 and Cricket first.

---

## 9. Prototype Flows (Page 08)
Create clickable prototypes for:
1. New match: PlayHome -> Setup -> Match -> Summary -> New Match
2. Resume match: PlayHome -> Active Match
3. Player management: PlayersList -> PlayerDetail -> EditSheet
4. History lookup: HistoryList -> Detail
5. Settings reset confirmation path

Use consistent transition style and duration; do not over-animate.

---

## 10. Engineering Handoff Requirements

For each finalized screen frame, include:
- Redline callouts (spacing, sizes, radii)
- Token references used
- Interaction notes (tap behavior, disabled logic, validation behavior)
- Accessibility notes (labels, hints, focus order concerns)

Add a handoff tag in frame name suffix:
- `/HandoffReady`

---

## 11. QA Evidence Page (Page 09)
Create QA sections:
- `Contrast checks` (light/dark)
- `Large text checks`
- `Landscape checks`
- `Interaction edge states`
- `Known deviations`

Attach screenshots of approved states from the matrix.

---

## 12. Multi-Agent Work Split (Recommended)

## 12.1 Roles
- **Agent A (Foundations):** variables, typography, spacing, token governance.
- **Agent B (Components):** component library + variants + accessibility notes.
- **Agent C (Play flows):** setup/match/summary/recovery screens.
- **Agent D (Data tabs):** history, players, settings screens.
- **Agent E (QA):** matrix verification, annotations, cleanup, archive.

## 12.2 Merge Protocol
- Components cannot be detached and edited ad hoc in screens.
- Screen builders only consume published components/patterns.
- Any component gap triggers a component update first, then screen update.

---

## 13. Daily Workflow
1. Pull latest specs.
2. Review `UIReviewChecklist`.
3. Build/update assigned frames.
4. Run appearance/orientation matrix checks.
5. Annotate unresolved questions.
6. Move deprecated work to `99 Archive`.
7. Update changelog page.

---

## 14. Definition of Done (Figma Kickoff)
- Foundations page complete and tokenized.
- Core component library complete with required states.
- All MVP screens exist in at least portrait light mode.
- Core flow screens have full 4-way matrix (light/dark x portrait/landscape).
- Clickable prototypes exist for all primary flows.
- Handoff annotations present on engineering-priority screens.
- QA evidence page populated.

---

## 15. Optional: API-Assisted Automation Track
If the team uses Figma API/automation:
- Keep credentials out of repo and agent transcripts.
- Store API key in local environment variables only.
- Use scripts for repetitive tasks only (naming audits, frame inventory, style usage reports).
- Do not auto-generate final visual design decisions without human review.
