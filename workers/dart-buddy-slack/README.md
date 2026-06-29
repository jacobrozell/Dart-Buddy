# Dart Buddy Slack Worker

> **Status:** Code in repo; **not deployed** for 1.0. Post-release setup checklist: [`docs/release/slack-integration.md`](../../docs/release/slack-integration.md).

Cloudflare Worker backing `/dart-buddy` slash commands. Bridges Slack to GitHub Actions — no App Store Connect credentials in Slack.

## Commands

| Command | GitHub target |
|---------|---------------|
| `/dart-buddy release` | `workflow_dispatch` on `trigger-testflight.yml` (`main`) |
| `/dart-buddy release branch:foo` | Same workflow, custom branch input via dispatch `ref` |
| `/dart-buddy status` | Reads latest `ci.yml` run |
| `/dart-buddy coverage` | Points to latest green CI coverage artifact |

Release completion notifications use Xcode Cloud **Notify** → `#dart-buddy-releases` (not this Worker). See [`docs/release/xcode-cloud.md`](../../docs/release/xcode-cloud.md).

## Prerequisites

1. **Slack app** with `commands` scope and slash command `/dart-buddy`
2. **GitHub fine-grained PAT** on `jacobrozell/Dart-Buddy`: `actions:read`, `actions:write`
3. **Cloudflare account** + Wrangler CLI

## Deploy

```bash
cd workers/dart-buddy-slack
npm install
npx wrangler secret put SLACK_SIGNING_SECRET
npx wrangler secret put GITHUB_TOKEN
npm run deploy
```

Set the Slack slash command Request URL to the deployed Worker URL.

## Local dev

```bash
npm run dev
```

Use Slack's request URL tunnel or `curl` with a signed payload for testing.
