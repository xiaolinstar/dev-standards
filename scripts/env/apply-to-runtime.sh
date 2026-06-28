#!/usr/bin/env bash
# Apply ~/.config/xiaolinstar/<project>/*.env to repo runtime paths (human/ops only; Agent must not run).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_ROOT="${XIAOLINSTAR_CONFIG_ROOT:-$HOME/.config/xiaolinstar}"
AGENT_PROJECTS="${AGENT_PROJECTS:-$HOME/AgentProjects}"
FORCE=0
PROJECT=""
ENV_NAME=""

usage() {
  cat <<EOF
Usage: $(basename "$0") --project NAME --env local|staging|production [options]

Write config file to repo runtime path for local dev or VPS rsync prep.
Does NOT deploy to remote server.

Options:
  --force   Overwrite existing runtime file
  --dry-run Print only
EOF
}

DRY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT=$2; shift 2 ;;
    --env) ENV_NAME=$2; shift 2 ;;
    --force) FORCE=1; shift ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown arg $1" >&2; usage >&2; exit 1 ;;
  esac
done

[[ -n "$PROJECT" && -n "$ENV_NAME" ]] || { usage >&2; exit 1; }

src="$CONFIG_ROOT/$PROJECT/${ENV_NAME}.env"
[[ -f "$src" ]] || { echo "error: missing $src" >&2; exit 1; }
[[ -s "$src" ]] || { echo "error: empty $src" >&2; exit 1; }

target=""
case "$PROJECT" in
  xiaolin-gateway|xiaolin-docs|xiaolin-life)
    case "$ENV_NAME" in
      local) target=".env.local" ;;
      production) target=".env.production" ;;
      *) echo "error: env $ENV_NAME not supported for $PROJECT" >&2; exit 1 ;;
    esac
    out="$AGENT_PROJECTS/$PROJECT/$target"
    ;;
  ai-todo|party-helper|drink-budget)
    case "$ENV_NAME" in
      local) target="apps/api/.env.local" ;;
      staging) target="apps/api/.env.staging" ;;
      production) target="apps/api/.env.production" ;;
      *) echo "error: env $ENV_NAME not supported" >&2; exit 1 ;;
    esac
    out="$AGENT_PROJECTS/$PROJECT/$target"
    ;;
  *)
    echo "error: unknown project" >&2
    exit 1
    ;;
esac

if [[ -f "$out" && -s "$out" && $FORCE -eq 0 ]]; then
  echo "error: $out exists (use --force)" >&2
  exit 1
fi

if [[ $DRY -eq 1 ]]; then
  echo "would copy $src → $out"
else
  cp "$src" "$out"
  chmod 600 "$out"
  echo "copied $src → $out"
fi

bash "$ROOT/scripts/env/check-env-keys.sh" --project "$AGENT_PROJECTS/$PROJECT" --strict --runtime "$(basename "$out")" 2>/dev/null || true
