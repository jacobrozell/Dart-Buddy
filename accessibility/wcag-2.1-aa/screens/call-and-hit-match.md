# Call & Hit — Match Screen (WCAG 2.1 AA)

**Screen:** `VoiceDrillMatchScreen` / Call & Hit active session  
**Spec:** [`specs/game-modes/planned/CallAndHitGameSpec.md`](../../../specs/game-modes/planned/CallAndHitGameSpec.md)  
**Template:** [`VoiceDrillUITemplateSpec.md`](../../../specs/game-modes/planned/VoiceDrillUITemplateSpec.md)  
**Status:** Planned — fill evidence at implementation

---

## Scope

Active Call & Hit session: target display, progress, Hit/Miss actions, pause, callouts toggle. Excludes setup and summary (use match-setup / match-summary docs).

---

## Criteria checklist

| Criterion | Status | Notes | Evidence |
|-----------|--------|-------|----------|
| 1.1.1 Non-text content | Pending | Segment diagram needs AX label matching callout | |
| 1.3.1 Info and relationships | Pending | Progress `12 of 50` programmatically linked | |
| 1.4.3 Contrast | Pending | Hit/Miss buttons + target text | |
| 1.4.4 Resize text | Pending | Dynamic Type to `accessibility3` | |
| 2.1.1 Keyboard | N/A | Touch-first | |
| 2.4.3 Focus order | Pending | Target → progress → Hit → Miss → toolbar | |
| 2.5.5 Target size | Pending | Hit/Miss ≥ 44pt | |
| 4.1.2 Name, role, value | Pending | `play.callAndHit.hit` / `.miss` identifiers | |
| 4.1.3 Status messages | Pending | Target change announced when callouts off | |

---

## VoiceOver script (manual)

1. Launch Call & Hit with callouts **off** — verify target announced on each advance.
2. Focus Hit — label includes target context if feasible ("Hit, sixteen").
3. Focus Miss — same pattern.
4. Complete one target — progress updates announced.
5. Rotate landscape — focus order trailing column (Hit/Miss) still reachable.

---

## Callouts on vs off

| Mode | Requirement |
|------|-------------|
| Callouts on | Visual target still present; TTS does not replace AX announcement |
| Callouts off | `UIAccessibility.post` on every target change |

---

## Reduce Motion

Target transition must not depend on motion-only cue.

---

## Evidence (to add)

- [ ] `evidence/voiceover/call-and-hit-ax-spotcheck-YYYY-MM-DD.md`
- [ ] `evidence/contrast/call-and-hit-hit-miss-YYYY-MM-DD.png` (optional)
