#!/usr/bin/env bash
# Report env migration progress for all registered projects.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REGISTRY="$ROOT/playbook/env-registry.yaml"
CONFIG_ROOT="${XIAOLINSTAR_CONFIG_ROOT:-$HOME/.config/xiaolinstar}"
AGENT_PROJECTS="${AGENT_PROJECTS:-$HOME/AgentProjects}"
CHECK="$ROOT/scripts/env/check-env-keys.sh"

projects=(xiaolin-gateway ai-todo party-helper drink-budget xiaolin-docs xiaolin-life)

file_nonempty() {
  [[ -f "$1" ]] && [[ -s "$1" ]]
}

runtime_paths_for() {
  local project=$1
  case "$project" in
    xiaolin-gateway|xiaolin-docs|xiaolin-life)
      echo ".env|.env.local|.env.production|env/production.env"
      ;;
    ai-todo|party-helper|drink-budget)
      echo "apps/api/.env|apps/api/.env.local|apps/api/.env.staging|apps/api/.env.production"
      ;;
  esac
}

echo "env migration status (config_root=$CONFIG_ROOT)"
echo "projects_root=$AGENT_PROJECTS"
echo ""

printf "%-16s %-8s %-10s %-10s %-8s %s\n" "PROJECT" "LOCAL" "CONFIG" "CHECK" "VPS?" "NOTES"
printf "%-16s %-8s %-10s %-10s %-8s %s\n" "-------" "-----" "------" "-----" "----" "-----"

for project in "${projects[@]}"; do
  repo="$AGENT_PROJECTS/$project"
  notes=()
  local_ok="—"
  config_ok="—"
  check_ok="—"
  vps_hint="manual"

  if [[ ! -d "$repo" ]]; then
    printf "%-16s %-8s %-10s %-10s %-8s %s\n" "$project" "skip" "skip" "skip" "?" "repo not found"
    continue
  fi

  # Local runtime files in repo
  local_count=0
  IFS='|' read -ra paths <<< "$(runtime_paths_for "$project")"
  for rel in "${paths[@]}"; do
    if file_nonempty "$repo/$rel"; then
      local_count=$((local_count + 1))
    fi
    if [[ "$rel" == "env/production.env" ]]; then
      notes+=("legacy env/production.env present")
    fi
  done
  if [[ $local_count -gt 0 ]]; then
    local_ok="${local_count} file(s)"
  else
    local_ok="empty"
    notes+=("no runtime .env in repo")
  fi

  # ~/.config/xiaolinstar
  config_count=0
  if [[ -d "$CONFIG_ROOT/$project" ]]; then
    for f in "$CONFIG_ROOT/$project"/*.env; do
      [[ -e "$f" ]] || continue
      if file_nonempty "$f"; then
        config_count=$((config_count + 1))
      fi
    done
  fi
  if [[ $config_count -gt 0 ]]; then
    config_ok="${config_count} filled"
  else
    config_ok="empty"
    notes+=("fill ~/.config/xiaolinstar/$project")
  fi

  # check-env-keys (repo runtime)
  if out=$(bash "$CHECK" --project "$repo" 2>&1); then
    if echo "$out" | grep -q '^FAIL'; then
      check_ok="FAIL"
    elif echo "$out" | grep -q 'warn'; then
      check_ok="warn"
    else
      check_ok="ok"
    fi
  else
    check_ok="FAIL"
  fi

  case "$project" in
    xiaolin-gateway) vps_hint="CD: .env*" ;;
    ai-todo) vps_hint="2 VPS" ;;
    party-helper) vps_hint="8021" ;;
    drink-budget) vps_hint="8020" ;;
    xiaolin-docs) vps_hint="8080" ;;
    xiaolin-life) vps_hint="8081" ;;
  esac

  note_str="${notes[*]:-}"
  printf "%-16s %-8s %-10s %-10s %-8s %s\n" "$project" "$local_ok" "$config_ok" "$check_ok" "$vps_hint" "$note_str"
done

echo ""
echo "Next: playbook/env-migration-runbook.md · import: sync.sh env import-config · apply: sync.sh env apply-config"
