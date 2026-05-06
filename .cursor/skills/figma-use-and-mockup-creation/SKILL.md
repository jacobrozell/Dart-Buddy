---
name: figma-use-and-mockup-creation
description: Translate Figma designs into implementation-ready specs and create high-quality UI mockup concepts. Use when the user mentions Figma files, frames, design handoff, wireframes, component breakdowns, visual direction, or mockup creation.
---

# Figma Use and Mockup Creation

## Purpose
Turn design intent into clear build guidance and mockup-ready outputs with minimal back-and-forth.

## When to apply
- User asks to work from a Figma file, frame, or design system.
- User wants screen mockups, visual exploration, or UI concept prompts.
- User needs component specs, spacing/token extraction, or handoff notes.

## Workflow
1. Confirm inputs: Figma link/file, target platform, brand/style constraints, and required deliverable.
2. Extract structure: screens, layout hierarchy, key components, and interaction states.
3. Capture design tokens: typography, color, spacing, radius, elevation, and icon style.
4. Produce two outputs when useful:
   - Build-facing spec for implementation.
   - Mockup-facing direction (prompt-ready visual brief).
5. Validate for consistency, accessibility basics, and edge states before finalizing.

## Required clarifications (if missing)
- Primary audience and platform (web, iOS, Android, desktop).
- Screen priority (MVP first vs full flow).
- Brand constraints (strict, partial, or open exploration).
- Visual fidelity target (wireframe, mid-fi, high-fi).

## Build-facing output format
Use this structure:

```markdown
# [Screen or Flow Name]

## Goal
[What this screen/flow must achieve]

## Layout map
- [Region 1]
- [Region 2]
- [Region 3]

## Components
- [Component name]: [role, variants, states]

## Design tokens
- Typography: [scale/weights]
- Colors: [roles + hex/tokens]
- Spacing: [key spacing system]
- Radius/Elevation: [rules]

## Interaction states
- Default:
- Hover/Focus/Pressed:
- Loading/Empty/Error:

## Accessibility checks
- Contrast:
- Touch target / hit area:
- Keyboard/focus behavior:

## Implementation notes
- [Behavior and technical constraints]
```

## Mockup creation format
When generating mockup direction, provide:
- Visual direction summary (2-4 bullets).
- One primary prompt and one alternate prompt.
- Constraints list (must keep / must avoid).
- Optional iteration ideas (up to 3).

Use this prompt pattern:

```text
Create a [fidelity] [platform] UI mockup for [screen purpose].
Style: [brand/style words].
Layout: [core structure].
Components: [must include list].
Color and typography: [token/style guidance].
State: [default/loading/error/etc].
Avoid: [anti-patterns].
```

## Quality bar
- Keep terminology consistent across all sections.
- Separate facts from assumptions; label assumptions clearly.
- Flag missing states or unclear interactions instead of guessing silently.
- Prefer concise, implementation-friendly language over long explanations.
