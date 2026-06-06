---
name: TestFlight Xcode Cloud
overview: Add Xcode Cloud release automation (archive + TestFlight) with repo-side ci_scripts for XcodeGen/Firebase, a GitHub Actions dispatcher for manual/API triggers, and a Slack `/dart-buddy release` command that kicks off the pipeline on demand.
todos:
  - id: ci-scripts
    content: Create ci_scripts/ci_post_clone.sh (xcodegen + Firebase plist from secret); chmod +x
    status: completed
  - id: trigger-script
    content: Create Scripts/ci/trigger-xcode-cloud.sh — JWT + scmGitReference lookup + ciBuildRuns POST
    status: completed
  - id: gha-workflow
    content: Create .github/workflows/trigger-testflight.yml with workflow_dispatch calling trigger script
    status: completed
  - id: runbook
    content: Write docs/release/xcode-cloud.md — ASC/Xcode setup, secrets, triggers, troubleshooting
    status: completed
  - id: doc-links
    content: Update docs/release/README.md, release_checklist.md, README.md CI section
    status: completed
  - id: slack-worker
    content: Scaffold workers/dart-buddy-slack with /dart-buddy release (+ status, nightly, coverage)
    status: completed
  - id: asc-setup
    content: "Manual: Create Xcode Cloud Release workflow, disable auto-triggers, configure TestFlight + Slack Notify + secrets"
    status: pending
  - id: slack-deploy
    content: "Manual: Deploy Cloudflare Worker, configure Slack app slash command URL + secrets"
    status: pending
isProject: false
---

# TestFlight Automation via Xcode Cloud

## Goal

Automate **signed Release archive → TestFlight internal testing** using **Xcode Cloud** (25 free compute hours/month with Apple Developer Program). Keep existing [`.github/workflows/ci.yml`](.github/workflows/ci.yml) and [`.github/workflows/nightly-ui.yml`](.github/workflows/nightly-ui.yml) unchanged for verification.

**Trigger model (per your preference):** no automatic builds on push/tag. Start builds via:
1. **Slack** `/dart-buddy release` (primary)
2. **GitHub Actions** `workflow_dispatch` (fallback / debugging)
3. **App Store Connect / Xcode** Start Build button (escape hatch)

```mermaid
flowchart LR
    subgraph triggers [Triggers]
        Slack["/dart-buddy release"]
        GHA["workflow_dispatch"]
        ASC["ASC Start Build"]
    end

    subgraph github [GitHub Actions]
        Dispatch[trigger-testflight.yml]
    end

    subgraph apple [Apple]
        XC[Xcode Cloud Release workflow]
        TF[TestFlight Internal]
    end

    Slack --> Dispatch
    GHA --> Dispatch
    Dispatch -->|"ASC API ciBuildRuns"| XC
    ASC --> XC
    XC --> TF
    TF --> SlackRel["#dart-buddy-releases"]
```

---

## Architecture decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Release platform | Xcode Cloud | Included with $99/yr membership; native signing + TestFlight |
| PR/nightly CI | GitHub Actions | Already working; avoid duplicate compute |
| Xcode Cloud auto-triggers | **Off** | Manual/Slack-only; saves compute hours |
| Archive scheme | `DartBuddy` (Release) | Full app target; not `DartBuddyCI` (tests-only scheme) |
| Firebase plist | Xcode Cloud **secret** env var | [`Resources/GoogleService-Info.plist`](Resources/GoogleService-Info.plist) is gitignored |
| Project generation | `ci_post_clone.sh` | [`DartBuddy.xcodeproj`](DartBuddy.xcodeproj) is gitignored; mirror GHA `xcodegen generate` |
| Build number | Xcode Cloud auto-versioning | Enable in workflow settings; increments from latest TestFlight build |
| Slack release notify | ASC native **Notify** post-action | Zero code per [`.cursor/plans/slack_integration.plan.md`](.cursor/plans/slack_integration.plan.md) Phase 3 |
| Slack trigger | GHA mediator + Cloudflare Worker | Worker holds GitHub PAT, not ASC JWT |

---

## Repo artifacts (implemented)

| File | Status |
|------|--------|
| [`ci_scripts/ci_post_clone.sh`](ci_scripts/ci_post_clone.sh) | Done |
| [`Scripts/ci/trigger-xcode-cloud.sh`](Scripts/ci/trigger-xcode-cloud.sh) | Done |
| [`.github/workflows/trigger-testflight.yml`](.github/workflows/trigger-testflight.yml) | Done |
| [`docs/release/xcode-cloud.md`](docs/release/xcode-cloud.md) | Done |
| [`workers/dart-buddy-slack/`](workers/dart-buddy-slack/) | Done (deploy pending) |

---

## Manual setup remaining

See [`docs/release/xcode-cloud.md`](docs/release/xcode-cloud.md):

1. App Store Connect API key → GitHub secrets
2. Xcode Cloud **Release** workflow (auto-builds off, TestFlight + Notify)
3. `GOOGLE_SERVICE_INFO_PLIST_BASE64` in Xcode Cloud environment
4. Deploy Slack Worker + configure `/dart-buddy` slash command

**GitHub secrets:** `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_PRIVATE_KEY`, `XCODE_CLOUD_WORKFLOW_ID`

---

## Combined with Slack integration

- Phase 3 release notify: ASC **Notify** → `#dart-buddy-releases`
- Phase 4 trigger: [`workers/dart-buddy-slack/`](workers/dart-buddy-slack/) → `trigger-testflight.yml`
- Full Slack plan: [`.cursor/plans/slack_integration.plan.md`](.cursor/plans/slack_integration.plan.md)
