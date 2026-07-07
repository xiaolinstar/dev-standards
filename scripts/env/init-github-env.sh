#!/usr/bin/env bash
# Copy L0 GitHub Actions templates (variables.env + secrets.env) to ~/.config
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_ROOT="${XIAOLINSTAR_CONFIG_ROOT:-$HOME/.config/xiaolinstar}"
AGENT_PROJECTS="${AGENT_PROJECTS:-$HOME/AgentProjects}"
PROJECT=""
ENV_NAME=""
FORCE=0
DRY=0

usage() {
  cat <<EOF
Usage: $(basename "$0") --project NAME --environment ENV [options]

Copy docs/env/github/<ENV>/variables.env.example and secrets.env.example to
~/.config/xiaolinstar/<project>/github/<ENV>/

Options:
  --force     Overwrite non-empty destination files
  --dry-run   Print only
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT=$2; shift 2 ;;
    --environment|--env) ENV_NAME=$2; shift 2 ;;
    --force) FORCE=1; shift ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown arg $1" >&2; usage >&2; exit 1 ;;
  esac
done

[[ -n "$PROJECT" && -n "$ENV_NAME" ]] || { usage >&2; exit 1; }

repo="$AGENT_PROJECTS/$PROJECT"
dest_dir="$CONFIG_ROOT/$PROJECT/github/$ENV_NAME"
registry_block=$(grep -A80 "^  ${PROJECT}:" "$ROOT/playbook/env-registry.yaml" || true)

resolve_template() {
  local kind=$1
  local rel=""
  if [[ -n "$registry_block" ]]; then
    rel=$(echo "$registry_block" | awk -v env="$ENV_NAME" -v kind="$kind" '
      $0 ~ "- name: " env { found=1; next }
      found && $0 ~ "l0_" kind ":" { print $2; exit }
    ')
  fi
  if [[ -n "$rel" && -f "$repo/$rel" ]]; then
    echo "$repo/$rel"
    return
  fi
  local candidate="$repo/docs/env/github/$ENV_NAME/${kind}.env.example"
  if [[ -f "$candidate" ]]; then
    echo "$candidate"
    return
  fi
  echo ""
}

copy_one() {
  local kind=$1
  local template
  template=$(resolve_template "$kind")
  local dest="$dest_dir/${kind}.env"
  if [[ -z "$template" ]]; then
    echo "error: L0 template missing for $PROJECT / $ENV_NAME / $kind" >&2
    exit 1
  fi
  if [[ -f "$dest" && -s "$dest" && $FORCE -eq 0 ]]; then
    echo "error: $dest exists (use --force)" >&2
    exit 1
  fi
  if [[ $DRY -eq 1 ]]; then
    echo "would copy $template → $dest"
  else
    mkdir -p "$dest_dir"
    cp "$template" "$dest"
    chmod 600 "$dest"
    echo "copied $template → $dest"
  fi
}

copy_one variables
copy_one secrets
echo "→ next: sync.sh env sync-github --project $PROJECT --environment $ENV_NAME --dry-run"
