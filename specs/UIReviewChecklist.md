# UI Review Checklist

## 1. Purpose
Provide a standard UI/UX acceptance gate for all UI-related pull requests.

Use this checklist in every PR that changes:
- UI layout
- styling/tokens
- interaction behavior
- user copy/microcopy
- accessibility

---

## 2. How To Use
- Copy Section 10 into the PR description.
- Mark each item pass/fail.
- Attach evidence links/screenshots where requested.
- Do not merge if any required item is unresolved.

---

## 3. Required References
- `specs/DesignSystemSpec.md`
- `specs/UIBlueprintSpec.md`
- `specs/UIImplementationSpec.md`
- `specs/AccessibilitySpec.md`
- `specs/TestPlanSpec.md`

---

## 4. Visual Consistency Gate (Required)
- [ ] Uses semantic tokens (no ad hoc color/spacing literals in feature views).
- [ ] Matches defined component patterns (button/chip/card/input behavior).
- [ ] One primary CTA per screen.
- [ ] Layout spacing aligns with token scale.
- [ ] No visual regressions in related screens.

Evidence:
- [ ] Before/after screenshots attached for changed screens.

---

## 5. Interaction and Behavior Gate (Required)
- [ ] All expected UI states implemented: loading, empty, error, ready/success.
- [ ] Validation behavior is inline and actionable.
- [ ] Destructive actions require clear confirmation.
- [ ] Navigation routes and back behavior match spec.
- [ ] Gameplay-critical actions (`Submit`, `Undo`, turn context) remain obvious and reachable.

Evidence:
- [ ] Short interaction notes in PR (what changed and why).

---

## 6. Accessibility Gate (WCAG 2.1 AA, Required)
- [ ] Text/background contrast meets WCAG 2.1 AA.
- [ ] Tap targets >= 44x44pt (52x52pt on gameplay controls).
- [ ] VoiceOver labels/hints added for interactive controls.
- [ ] Critical meaning is not color-only.
- [ ] Dynamic Type works at accessibility sizes with no clipping of critical content.
- [ ] Focus order follows visual hierarchy.

Evidence:
- [ ] VoiceOver notes included for changed screens.
- [ ] Dynamic Type screenshot(s) attached.

---

## 7. Appearance and Orientation Gate (Required)
- [ ] Portrait + Light verified.
- [ ] Portrait + Dark verified.
- [ ] Landscape + Light verified.
- [ ] Landscape + Dark verified.
- [ ] In landscape, no critical controls are hidden behind truncation/scroll traps.

Evidence:
- [ ] Four-combination screenshot set attached (or video).

---

## 8. Quality and Test Gate (Required)
- [ ] UI tests added/updated for changed behavior (or justified if deferred).
- [ ] Existing relevant tests pass.
- [ ] No new linter warnings/errors.
- [ ] No conflicting behavior with authoritative specs.

Evidence:
- [ ] Test run summary included.

---

## 9. Copy and Content Gate (Required)
- [ ] Button labels are direct and action-oriented.
- [ ] Error text explains how to recover.
- [ ] Confirmation dialogs explain consequence clearly.
- [ ] Terminology is consistent with existing app language.

---

## 10. PR Template Block (Copy/Paste)
```md
## UI Review Checklist

### Visual Consistency
- [ ] Semantic tokens used
- [ ] Component patterns respected
- [ ] One primary CTA per screen
- [ ] Spacing aligns to token scale
- [ ] Before/after screenshots attached

### Interaction and Behavior
- [ ] Required UI states covered (loading/empty/error/ready)
- [ ] Validation is inline/actionable
- [ ] Destructive actions confirmed
- [ ] Navigation behavior matches spec
- [ ] Gameplay-critical controls remain reachable

### Accessibility (WCAG 2.1 AA)
- [ ] Contrast pass
- [ ] Tap targets pass
- [ ] VoiceOver labels/hints present
- [ ] No color-only critical meaning
- [ ] Dynamic Type (accessibility sizes) pass
- [ ] Focus order pass

### Appearance + Orientation
- [ ] Portrait + Light pass
- [ ] Portrait + Dark pass
- [ ] Landscape + Light pass
- [ ] Landscape + Dark pass

### Quality
- [ ] Relevant tests updated/passing
- [ ] Lints clean
- [ ] Spec alignment confirmed

### Notes / Evidence
- Screenshots:
- Test results:
- Accessibility notes:
```

---

## 11. Merge Rule
If any required section has unchecked items, PR is not merge-ready.
