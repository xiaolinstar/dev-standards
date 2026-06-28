#!/usr/bin/env bash
# Copy existing runtime env files into ~/.config/xiaolinstar/<project>/ (never overwrite non-empty without --force).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_ROOT="${XIAOLINSTAR_CONFIG_ROOT:-$HOME/.config/xiaolinstar}"
AGENT_PROJECTS="${AGENT_PROJECTS:-$HOME/AgentProjects}"
FORCE=0
PROJECT=""

usage() {
  cat <<EOF
Usage: $(basename "$0") --project NAME [options]

Import runtime env from repo (and legacy paths) into ~/.config/xiaolinstar/<project>/.

Options:
  --project NAME   e.g. ai-todo, xiaolin-gateway
  --force          Overwrite non-empty config files
  --dry-run        Print actions only

Mapping:
  gateway/docs/life:  .env → local.env (if no .env.local), .env.production → production.env
  app monorepos:        apps/api/.env* → local|staging|production.env
  legacy:             env/production.env → production.env (gateway only)
EOF
}

DRY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT=$2; shift 2 ;;
    --force) FORCE=1; shift ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown arg $1" >&2; usage >&2; exit 1 ;;
  esac
done

[[ -n "$PROJECT" ]] || { usage >&2; exit 1; }

repo="$AGENT_PROJECTS/$PROJECT"
dest="$CONFIG_ROOT/$PROJECT"
mkdir -p "$dest"

copy_one() {
  local src=$1
  local out=$2
  [[ -f "$src" ]] || return 0
  if [[ -s "$out" && $FORCE -eq 0 ]]; then
    echo "skip (non-empty): $out"
    return 0
  fi
  if [[ $DRY -eq 1 ]]; then
    echo "would copy $src → $out"
  else
    cp "$src" "$out"
    chmod 600 "$out"
    echo "copied $src → $out"
  fi
}

case "$PROJECT" in
  xiaolin-gateway|xiaolin-docs|xiaolin-life)
    copy_one "$repo/.env.local" "$dest/local.env"
    copy_one "$repo/.env" "$dest/local.env"
    copy_one "$repo/.env.production" "$dest/production.env"
    copy_one "$repo/env/production.env" "$dest/production.env"
    ;;
  ai-todo|party-helper|drink-budget)
    api="$repo/apps/api"
    copy_one "$api/.env.local" "$dest/local.env"
    copy_one "$api/.env" "$dest/local.env"
    copy_one "$api/.env.staging" "$dest/staging.env"
    copy_one "$api/.env.production" "$dest/production.env"
    ;;
  *)
    echo "error: unknown project $PROJECT (not in import map)" >&2
    exit 1
    ;;
esac

echo "→ config: $dest"
echo "verify: bash $ROOT/scripts/env/check-env-keys.sh --project $repo --local production"
