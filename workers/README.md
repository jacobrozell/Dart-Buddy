# Workers

Serverless/edge code for **release ops and integrations** — not part of the iOS Xcode target.

| Worker | Status | Purpose |
|--------|--------|---------|
| [`dart-buddy-slack/`](dart-buddy-slack/) | Post-1.0 (not deployed) | Slack `/dart-buddy` → GitHub Actions |

Planning doc: [`docs/release/slack-integration.md`](../docs/release/slack-integration.md).

Each subfolder is its own npm + Wrangler project (`package.json`, `wrangler.toml`, `src/`). CI does not build or deploy these; deploy manually when ready.
