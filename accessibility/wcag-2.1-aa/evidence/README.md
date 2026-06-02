# Evidence storage

Place verification artifacts here or link to repo paths.

## Suggested layout

```text
evidence/
  voiceover/          # Notes or short screen recordings per flow
                      # e.g. x01-ax-spotcheck-2026-06-02.md, cricket-ax-spotcheck-2026-06-02.md
  dynamic-type/       # AXXXL screenshots (or link snapshots/*-axxxl-*)
  contrast/           # Inspector exports or annotated screenshots
  orientation/        # portrait|landscape × light|dark
  reduce-motion/      # Before/after summary screen
```

Existing snapshots under `/snapshots/` may be referenced from screen files, e.g. `snapshots/iphone17-setup-dark-axxxl-fix2.png`.

## Naming convention

`{screen-id}_{check}_{device}_{theme}_{orientation}.{png|md}`

Example: `x01-match_dynamic-type_iphone17_dark_portrait.png`
