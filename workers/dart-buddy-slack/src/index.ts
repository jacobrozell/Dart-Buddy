export interface Env {
  SLACK_SIGNING_SECRET: string;
  GITHUB_TOKEN: string;
  GITHUB_REPO: string;
}

type SlackSlashBody = {
  command: string;
  text: string;
  response_url: string;
  user_name: string;
};

const WORKFLOWS = {
  release: "trigger-testflight.yml",
} as const;

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }

    const bodyText = await request.text();
    if (!(await verifySlackSignature(request, env.SLACK_SIGNING_SECRET, bodyText))) {
      return new Response("Invalid signature", { status: 401 });
    }

    const body = parseForm(bodyText) as SlackSlashBody;
    const args = body.text.trim().split(/\s+/).filter(Boolean);
    const subcommand = args[0]?.toLowerCase() ?? "help";

    try {
      switch (subcommand) {
        case "release":
          return await handleRelease(env, args.slice(1));
        case "status":
          return jsonResponse(await lastCiStatus(env));
        case "coverage":
          return jsonResponse(await latestCoverage(env));
        default:
          return jsonResponse(helpText());
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown error";
      return jsonResponse(`:x: ${message}`);
    }
  },
};

function helpText(): string {
  return [
    "*Dart Buddy commands*",
    "`/dart-buddy release` — start TestFlight build on `main`",
    "`/dart-buddy release branch:feature/foo` — build a branch",
    "`/dart-buddy status` — last CI workflow result",
    "`/dart-buddy coverage` — coverage from last green CI run",
  ].join("\n");
}

async function handleRelease(env: Env, args: string[]): Promise<Response> {
  let branch = "main";
  for (const arg of args) {
    if (arg.startsWith("branch:")) {
      branch = arg.slice("branch:".length);
    }
  }
  if (!branch) {
    return jsonResponse(":x: Branch name is required.");
  }

  await dispatchWorkflow(env, WORKFLOWS.release, {
    ref: "main",
    inputs: { branch },
  });
  return jsonResponse(
    `:rocket: Release build started for \`${branch}\`. Watch #dart-buddy-releases for Xcode Cloud status.`,
  );
}

async function dispatchWorkflow(
  env: Env,
  workflowFile: string,
  payload: { ref: string; inputs?: Record<string, string> },
): Promise<void> {
  const url = `https://api.github.com/repos/${env.GITHUB_REPO}/actions/workflows/${workflowFile}/dispatches`;
  const response = await githubFetch(env, url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const detail = await response.text();
    throw new Error(`GitHub dispatch failed (${response.status}): ${detail}`);
  }
}

async function lastCiStatus(env: Env): Promise<string> {
  const url = `https://api.github.com/repos/${env.GITHUB_REPO}/actions/workflows/ci.yml/runs?per_page=1`;
  const response = await githubFetch(env, url);
  if (!response.ok) {
    throw new Error(`GitHub API error (${response.status})`);
  }

  const payload = (await response.json()) as {
    workflow_runs: Array<{
      conclusion: string | null;
      html_url: string;
      head_branch: string;
      created_at: string;
    }>;
  };

  const run = payload.workflow_runs[0];
  if (!run) {
    return "No CI runs found.";
  }

  const emoji =
    run.conclusion === "success"
      ? ":white_check_mark:"
      : run.conclusion === "failure"
        ? ":x:"
        : ":hourglass_flowing_sand:";

  return `${emoji} Last CI: *${run.conclusion ?? "in progress"}* on \`${run.head_branch}\` — <${run.html_url}|view run>`;
}

async function latestCoverage(env: Env): Promise<string> {
  const runsUrl = `https://api.github.com/repos/${env.GITHUB_REPO}/actions/workflows/ci.yml/runs?status=success&per_page=5`;
  const runsResponse = await githubFetch(env, runsUrl);
  if (!runsResponse.ok) {
    throw new Error(`GitHub API error (${runsResponse.status})`);
  }

  const runsPayload = (await runsResponse.json()) as {
    workflow_runs: Array<{ id: number; html_url: string }>;
  };

  for (const run of runsPayload.workflow_runs) {
    const artifactsUrl = `https://api.github.com/repos/${env.GITHUB_REPO}/actions/runs/${run.id}/artifacts`;
    const artifactsResponse = await githubFetch(env, artifactsUrl);
    if (!artifactsResponse.ok) {
      continue;
    }

    const artifactsPayload = (await artifactsResponse.json()) as {
      artifacts: Array<{ name: string; archive_download_url: string }>;
    };

    const coverageArtifact = artifactsPayload.artifacts.find(
      (artifact) => artifact.name === "coverage-summary",
    );
    if (!coverageArtifact) {
      continue;
    }

    return `:bar_chart: Latest green CI coverage artifact — <${run.html_url}|run ${run.id}> (download \`coverage-summary\` from artifacts)`;
  }

  return "No coverage artifact found on recent green CI runs.";
}

async function githubFetch(
  env: Env,
  url: string,
  init: RequestInit = {},
): Promise<Response> {
  const headers = new Headers(init.headers);
  headers.set("Authorization", `Bearer ${env.GITHUB_TOKEN}`);
  headers.set("Accept", "application/vnd.github+json");
  headers.set("User-Agent", "dart-buddy-slack-worker");
  headers.set("X-GitHub-Api-Version", "2022-11-28");
  return fetch(url, { ...init, headers });
}

function jsonResponse(text: string): Response {
  return new Response(JSON.stringify({ response_type: "ephemeral", text }), {
    headers: { "Content-Type": "application/json" },
  });
}

function parseForm(body: string): Record<string, string> {
  return Object.fromEntries(new URLSearchParams(body));
}

async function verifySlackSignature(
  request: Request,
  signingSecret: string,
  body: string,
): Promise<boolean> {
  const timestamp = request.headers.get("X-Slack-Request-Timestamp") ?? "";
  const signature = request.headers.get("X-Slack-Signature") ?? "";
  if (!timestamp || !signature) {
    return false;
  }

  const age = Math.abs(Date.now() / 1000 - Number(timestamp));
  if (Number.isNaN(age) || age > 60 * 5) {
    return false;
  }

  const base = `v0:${timestamp}:${body}`;
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(signingSecret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const digest = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(base),
  );
  const expected =
    "v0=" +
    [...new Uint8Array(digest)]
      .map((byte) => byte.toString(16).padStart(2, "0"))
      .join("");

  return timingSafeEqual(expected, signature);
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) {
    return false;
  }
  let mismatch = 0;
  for (let i = 0; i < a.length; i += 1) {
    mismatch |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return mismatch === 0;
}
