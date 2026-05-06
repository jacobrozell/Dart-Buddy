# Phase 05 - UI System and Fidelity Lock

## Objective
Lock visual system and interaction consistency across all MVP screens, including accessibility and appearance/orientation parity, using available blueprint + Figma specs.

Note:
- This phase is the formal lock/sign-off point, but manual UI verification against Figma/specs should run continuously during Phases 03-05.

## Specs Anchored
- `specs/DesignSystemSpec.md`
- `specs/FigmaBuildPlan.md`
- `specs/UIBlueprintSpec.md`
- `specs/UIReviewChecklist.md`
- `specs/AccessibilitySpec.md`
- `specs/LocalizationSpec.md`

## Batch Workstreams
- **Design system lane**
  - Implement tokenized foundations (spacing, radius, semantic colors, type).
  - Implement/reconcile component set (buttons/chips/cards/input/feedback).
- **Screen fidelity lane**
  - Align all screens to composition templates and one-primary-CTA rule.
  - Validate implemented screens against Figma mockups/handoff frames where they are complete and correct.
  - Ensure all loading/empty/error/ready states are visually coherent.
- **Accessibility + localization lane**
  - Add VoiceOver labels/hints and non-color cues for all critical controls.
  - Enforce localization-key usage for user-facing text.
- **Figma handoff lane**
  - Build/maintain matrix coverage in available Figma plan pages and linked mockup frames as they are finalized.
  - Maintain frame naming/state parity between Figma and implemented screens for easier QA traceability.
  - Complete or document pending clickable prototype coverage for primary flows (new match, resume, players, history, settings reset).
  - Add engineering handoff annotations (redlines, token refs, interaction notes, accessibility notes) on handoff-ready frames.
  - Capture QA evidence for light/dark and portrait/landscape across core screens.

## Deliverables
- Consistent design-token usage in feature views.
- 4-way orientation/appearance verification for core screens.
- Accessibility pass evidence and unresolved issues list at zero criticals.
- Figma prototype flows and QA evidence page updated where available, with known Figma gaps explicitly tracked.

## Exit Criteria
- `UIReviewChecklist` passes for all changed screens.
- WCAG 2.1 AA release gate passes for core flows.
- No hardcoded user-facing strings in UI views.
- Figma-vs-implementation review is complete for all MVP screens using finalized frames, with unresolved Figma-source gaps documented.
- Handoff-ready Figma frames include required annotations for engineering and QA.
