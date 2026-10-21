# Review lanes (Dart Buddy)

Pre-release / pre-TestFlight review orchestration. **Review only** by default — product fixes land from the sprint plan in `ongoing/<version>-review-fixes.md` when you ask for `--fix`.

**Playbook:** this folder · **Prompts:** [`lanes.md`](lanes.md) · **Orchestration:** user skill `review-lanes` (`~/Desktop/personal` / Cursor skills)

## When to run

- Before TestFlight RC cut
- Before App Store submit
- After a large game-mode / polish wave
- When you say *run review lanes*, *release review*, or *review branch before TestFlight*

## Parameters

| Param | Dart Buddy default |
|-------|--------------------|
| `REPO` | this repository root |
| `BRANCH` | named release branch (e.g. `release/1.1.0`) or current feature branch |
| `BASE` | `master` (or tag `1.0.0` for a full slice delta) |
| `VERSION` | `MARKETING_VERSION` in `project.yml` |
| `APP` | Dart Buddy |
| `PLATFORM` | `ios` |

## Prep bundle

```bash
OUT=$(Scripts/review-lanes/prep.sh "$PWD" "$BASE" "$BRANCH")
cat "$OUT/meta.txt"
```

Artifacts land under `/tmp/cursor/review-bundles/` (not in git). Record `$OUT` in `ongoing/<VERSION>-review-fixes.md` → **Review bundle**.

## Lanes

| Lane | Subagent | Skip when |
|------|----------|-----------|
| Bugbot | `bugbot` | — |
| Security | `security-review` | — |
| Accessibility | `generalPurpose` | — |
| Architecture | `generalPurpose` | — |
| UI/UX | `generalPurpose` | — |
| Code smells | `generalPurpose` | — |
| Tests | `generalPurpose` | — |
| Store policy | `generalPurpose` | Non-store |
| Data integrity | `generalPurpose` | No persisted data |

Prompts: [`lanes.md`](lanes.md). Ingest validated findings into `ongoing/<VERSION>-review-fixes.md` (create from [`ongoing/review-fixes-template.md`](../../ongoing/review-fixes-template.md)).

## Verdict words

**Product lanes:** Ready / Ready with nits / Block `{VERSION}`  
**Store lane:** Likely approve / Risk of rejection / Likely reject  
**Tests:** Pass / Pass with gaps / Fail (block `{VERSION}`)

Findings format: `Severity | Location (file:line) | Finding`
