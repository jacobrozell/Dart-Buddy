---
name: Slack Integration
overview: Expand Dart Buddy's Slack notifications from basic CI pass/fail messages into a multi-channel ops surface — richer failure context, coverage, release/Xcode Cloud alerts, GitHub app subscriptions, and interactive slash commands.
todos:
  - id: slack-phase1-rich-notify
    content: "Phase 1 — Extend slack-ci-notify with severity styling, coverage, failure details, and per-workflow webhooks"
    status: completed
  - id: slack-phase2-github-app
    content: "Phase 2 — Install GitHub Slack app for PR reviews, merges, and Dependabot/security alerts"
    status: pending
  - id: slack-phase3-xcode-cloud
    content: "Phase 3 — Xcode Cloud Release workflow with Notify post-action to #dart-buddy-releases (manual ASC setup)"
    status: pending
  - id: slack-phase3-weekly-digest
    content: "Phase 3 — Scheduled weekly digest workflow (pass rate, coverage trend, flaky UI count)"
    status: pending
  - id: slack-phase4-slack-app
    content: "Phase 4 — Deploy workers/dart-buddy-slack for /dart-buddy commands (scaffold done)"
    status: pending
isProject: false
---

# Slack Integration — Ongoing Plan

## Current state

- Composite action: [`.github/actions/slack-ci-notify/action.yml`](../../.github/actions/slack-ci-notify/action.yml)
- Wired into [CI](../../.github/workflows/ci.yml) and [Nightly UI Tests](../../.github/workflows/nightly-ui.yml)
- Posts Block Kit messages via incoming webhook (`SLACK_WEBHOOK_URL` secret)
- Notifies on **every** run (`if: always()`) — intentional; keep always-on visibility
- **Release trigger scaffold:** [`workers/dart-buddy-slack/`](../../workers/dart-buddy-slack/) + [`.github/workflows/trigger-testflight.yml`](../../.github/workflows/trigger-testflight.yml)
- **Release runbook:** [`docs/release/xcode-cloud.md`](../../docs/release/xcode-cloud.md)

## Channel layout (target)

| Channel | Source | Secret |
|---------|--------|--------|
| `#dart-buddy-ci` | GitHub CI workflow | `SLACK_WEBHOOK_CI` |
| `#dart-buddy-nightly` | Nightly UI workflow | `SLACK_WEBHOOK_NIGHTLY` |
| `#dart-buddy-releases` | Xcode Cloud Notify post-action | ASC Slack integration |
| `#dart-buddy-prs` | GitHub Slack app (config only) | — |
| `#dart-buddy-security` | GitHub Slack app / Dependabot | — |

Legacy `SLACK_WEBHOOK_URL` remains a fallback when a workflow-specific secret is unset.

---

## Phase 1 — Richer GitHub notifications ✅ done

**Goal:** Same webhook architecture, better messages and channel routing.

### Deliverables

1. **`workflow_kind` severity styling** — `ci`, `nightly`, `release` control header emoji and failure tone
2. **Coverage field** — parse `coverage-summary.txt` artifact; show Dart Buddy target % in Slack
3. **Failure details** — failed test names + short log excerpt from `xcodebuild-test.log` / `xcodebuild-build.log`
4. **Per-workflow webhooks** — `SLACK_WEBHOOK_CI` / `SLACK_WEBHOOK_NIGHTLY` with fallback to `SLACK_WEBHOOK_URL`
5. **`Scripts/ci/prepare-slack-context.sh`** — artifact → JSON context for the notify action
6. **Build log artifact** — upload `xcodebuild-build.log` on build failure so notify job can include compile errors
7. **Nightly coverage** — run `coverage-summary.sh` in nightly workflow (parity with CI)

---

## Phase 2 — GitHub Slack app (config only)

**Goal:** PR lifecycle and security without custom code.

1. Install [GitHub's Slack integration](https://github.com/integrations/slack) on the workspace
2. Subscribe `#dart-buddy-prs` to: `pull_requests`, `reviews`, `commits` for `Dart-Buddy`
3. Subscribe `#dart-buddy-security` to: Dependabot alerts, code scanning alerts

**Effort:** ~15 minutes. No repo changes required.

---

## Phase 3 — Release & digest

### Xcode Cloud → Slack (repo ready; ASC setup pending)

Apple native **Notify** post-action on the **Release** archive workflow:

1. App Store Connect → Xcode Cloud → **Release** workflow → Post-Actions → Notify → connect Slack
2. Route to `#dart-buddy-releases`
3. **Disable automatic builds** — triggers are Slack `/dart-buddy release`, GHA `trigger-testflight.yml`, or ASC Start Build

| Workflow | Trigger | Notify channel |
|----------|---------|----------------|
| `Release` | Manual / Slack / GHA API | `#dart-buddy-releases` |
| `PR Build` | Pull request | Skip (GitHub CI covers) |

Optional later: `ci_scripts/ci_post_actions.sh` + `SLACK_WEBHOOK_RELEASE` for Block Kit parity with GitHub CI style.

### Weekly coverage digest

New scheduled workflow (e.g. Monday 09:00 ET):

- Aggregate last 7 days of CI `coverage-summary.txt` artifacts
- Post rollup: pass rate, coverage delta, nightly UI failure count
- Webhook: `SLACK_WEBHOOK_CI` or dedicated `SLACK_WEBHOOK_DIGEST`

---

## Phase 4 — Interactive Slack app (scaffold done; deploy pending)

**Worker:** [`workers/dart-buddy-slack/`](../../workers/dart-buddy-slack/)

### Slash commands

```
/dart-buddy release              → workflow_dispatch on trigger-testflight.yml (main)
/dart-buddy release branch:foo   → same, custom branch input
/dart-buddy status               → last CI result via GitHub API
/dart-buddy nightly              → workflow_dispatch on nightly-ui.yml
/dart-buddy coverage             → latest coverage from last green CI run
```

### Interactive buttons (future)

- **View run** — URL button (no backend)
- **Re-run failed jobs** — `POST .../actions/runs/{id}/rerun-failed-jobs`

### Prerequisites

| Piece | Purpose |
|-------|---------|
| Slack app | `chat:write`, `commands`, interactivity |
| Cloudflare Worker | Verify Slack signing secret; call GitHub API |
| GitHub PAT | `actions:read`, `actions:write` (fine-grained, repo-scoped) |

**Deploy:** see [`workers/dart-buddy-slack/README.md`](../../workers/dart-buddy-slack/README.md)

---

## Architecture

```mermaid
flowchart TB
    subgraph phase1 [Phase 1 - GitHub Actions]
        CI[ci.yml]
        Nightly[nightly-ui.yml]
        Prep[prepare-slack-context.sh]
        Action[slack-ci-notify]
        CI --> Prep
        Nightly --> Prep
        Prep --> Action
        Action --> WH_CI[SLACK_WEBHOOK_CI]
        Action --> WH_Nightly[SLACK_WEBHOOK_NIGHTLY]
    end

    subgraph phase2 [Phase 2 - GitHub App]
        GHApp[GitHub Slack App]
        GHApp --> PRs[#dart-buddy-prs]
        GHApp --> Sec[#dart-buddy-security]
    end

    subgraph phase3 [Phase 3 - Xcode Cloud]
        XC[Xcode Cloud Notify]
        XC --> Releases[#dart-buddy-releases]
    end

    subgraph phase4 [Phase 4 - Slack App]
        Worker[dart-buddy-slack Worker]
        Slash[/dart-buddy commands]
        Trigger[trigger-testflight.yml]
        Slash --> Worker
        Worker --> Trigger
        Trigger --> XC
    end
```

---

## Decision log

| Decision | Rationale |
|----------|-----------|
| Always notify (pass + fail) | Team preference — visibility over noise reduction |
| Webhooks before Slack app | Simpler; covers 80% of value; app needed only for interactivity |
| Separate CI / nightly / release channels | Different audiences and urgency |
| Xcode Cloud native Notify first | Zero code; custom post-actions only if Block Kit parity needed |
| GHA mediates Slack → Xcode Cloud | Worker holds GitHub PAT; ASC JWT stays in GHA secrets only |

---

## Changelog

| Date | Change |
|------|--------|
| 2026-06-06 | Plan created; Phase 1 implemented (rich notify, dual webhooks, coverage, failure context) |
| 2026-06-06 | Combined with TestFlight plan: trigger script, GHA workflow, xcode-cloud runbook, Worker scaffold |
