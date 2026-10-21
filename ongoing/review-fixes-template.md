# {APP} {VERSION} — Review fixes

**Branch:** `{BRANCH}` vs `{BASE}`  
**Review bundle:** `{OUT}`  
**Created:** {DATE}

## Lane status

| Lane | Verdict | Ingested |
|------|---------|----------|
| Bugbot | | [ ] |
| Security | | [ ] |
| Accessibility | | [ ] |
| Architecture | | [ ] |
| UI/UX | | [ ] |
| Code smells | | [ ] |
| Tests | | [ ] |
| Store policy | | [ ] |
| Data integrity | | [ ] |

## Review bundle

```
{OUT}
files={N}
shortstat={SHORTSTAT}
```

## Sprint order

Block / High first. Link anchors `#rf-N`.

| # | Sev | Lane | Location | Finding | Status |
|---|-----|------|----------|---------|--------|

## Notes

- Trust gate: drop findings whose `file:line` is not in the review bundle (or clear rename).
- Dedupe across lanes before adding sprint rows.
