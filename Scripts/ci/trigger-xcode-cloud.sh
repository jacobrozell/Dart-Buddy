#!/usr/bin/env bash
# Trigger an Xcode Cloud workflow via App Store Connect API (ciBuildRuns).
# Used by .github/workflows/trigger-testflight.yml and /dart-buddy release Slack command.
set -euo pipefail

BRANCH="${1:-main}"

for var in APP_STORE_CONNECT_ISSUER_ID APP_STORE_CONNECT_KEY_ID APP_STORE_CONNECT_PRIVATE_KEY XCODE_CLOUD_WORKFLOW_ID; do
  if [[ -z "${!var:-}" ]]; then
    echo "error: $var is not set" >&2
    exit 1
  fi
done

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required" >&2
  exit 1
fi

KEY_FILE="$(mktemp)"
trap 'rm -f "$KEY_FILE"' EXIT
printf '%b' "$APP_STORE_CONNECT_PRIVATE_KEY" > "$KEY_FILE"

generate_jwt() {
  local header payload header_b64 payload_b64 signing_input signature
  local iat exp

  iat="$(date +%s)"
  exp=$((iat + 1200))

  header="$(jq -nc --arg kid "$APP_STORE_CONNECT_KEY_ID" \
    '{alg:"ES256",kid:$kid,typ:"JWT"}')"
  payload="$(jq -nc --arg iss "$APP_STORE_CONNECT_ISSUER_ID" \
    --argjson iat "$iat" --argjson exp "$exp" \
    '{iss:$iss,iat:$iat,exp:$exp,aud:"appstoreconnect-v1"}')"

  header_b64="$(printf '%s' "$header" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')"
  payload_b64="$(printf '%s' "$payload" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')"
  signing_input="${header_b64}.${payload_b64}"
  signature="$(printf '%s' "$signing_input" | openssl dgst -sha256 -sign "$KEY_FILE" \
    | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')"

  printf '%s.%s' "$signing_input" "$signature"
}

asc_get() {
  local path="$1"
  curl -fsS \
    -H "Authorization: Bearer $JWT" \
    -H "Accept: application/json" \
    "https://api.appstoreconnect.apple.com${path}"
}

asc_post() {
  local path="$1"
  local body="$2"
  curl -fsS \
    -X POST \
    -H "Authorization: Bearer $JWT" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d "$body" \
    "https://api.appstoreconnect.apple.com${path}"
}

JWT="$(generate_jwt)"
WORKFLOW_ID="$XCODE_CLOUD_WORKFLOW_ID"

echo "Resolving repository for workflow ${WORKFLOW_ID}..."
workflow_json="$(asc_get "/v1/ciWorkflows/${WORKFLOW_ID}?include=repository")"
repo_id="$(printf '%s' "$workflow_json" | jq -r '.included[] | select(.type == "scmRepositories") | .id' | head -n1)"

if [[ -z "$repo_id" || "$repo_id" == "null" ]]; then
  repo_id="$(printf '%s' "$workflow_json" | jq -r '.data.relationships.repository.data.id')"
fi

if [[ -z "$repo_id" || "$repo_id" == "null" ]]; then
  echo "error: could not resolve SCM repository for workflow" >&2
  exit 1
fi

echo "Looking up git reference for branch '${BRANCH}' in repository ${repo_id}..."
refs_json="$(asc_get "/v1/scmGitReferences?filter[repository]=${repo_id}&filter[name]=${BRANCH}&limit=1")"
ref_id="$(printf '%s' "$refs_json" | jq -r '.data[0].id // empty')"

if [[ -z "$ref_id" ]]; then
  canonical="refs/heads/${BRANCH}"
  refs_json="$(asc_get "/v1/scmGitReferences?filter[repository]=${repo_id}&filter[canonicalName]=${canonical}&limit=1")"
  ref_id="$(printf '%s' "$refs_json" | jq -r '.data[0].id // empty')"
fi

if [[ -z "$ref_id" ]]; then
  echo "error: no scmGitReference found for branch '${BRANCH}'" >&2
  exit 1
fi

echo "Starting Xcode Cloud build (workflow=${WORKFLOW_ID}, ref=${ref_id})..."
request_body="$(jq -nc \
  --arg workflow_id "$WORKFLOW_ID" \
  --arg ref_id "$ref_id" \
  '{
    data: {
      type: "ciBuildRuns",
      attributes: { clean: false },
      relationships: {
        workflow: { data: { type: "ciWorkflows", id: $workflow_id } },
        sourceBranchOrTag: { data: { type: "scmGitReferences", id: $ref_id } }
      }
    }
  }')"

response="$(asc_post "/v1/ciBuildRuns" "$request_body")"
build_run_id="$(printf '%s' "$response" | jq -r '.data.id')"

echo "Xcode Cloud build started: ${build_run_id}"
printf '%s\n' "$response" | jq .
