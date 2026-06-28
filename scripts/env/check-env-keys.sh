#!/usr/bin/env bash
# Compare L0 *.example keys against L3 runtime or ~/.config/xiaolinstar files.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

CONFIG_ROOT="${XIAOLINSTAR_CONFIG_ROOT:-$HOME/.config/xiaolinstar}"

usage() {
  cat <<EOF
Usage: $(basename "$0") --project PATH [options]

Options:
  --project PATH     Business repo root (required)
  --name NAME        Project id in env-registry (default: basename of PATH)
  --env ENV          Environment for --local (default: production)
  --local            Compare templates to ~/.config/xiaolinstar/<name>/<env>.env
  --runtime FILE     Compare templates to a specific runtime file (repeatable)
  --strict           Exit 1 if runtime file missing when checking pairs
  --warn-extra       Warn on keys in runtime but not in any template for that target

Examples:
  $(basename "$0") --project ~/AgentProjects/ai-todo
  $(basename "$0") --project ~/AgentProjects/xiaolin-gateway --runtime .env.production
  $(basename "$0") --project ~/AgentProjects/ai-todo --local --env staging
EOF
}

project_path=""
project_name=""
env_name="production"
use_local=0
strict=0
warn_extra=0
declare -a runtime_files=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) project_path=$(cd "$2" && pwd); shift 2 ;;
    --name) project_name=$2; shift 2 ;;
    --env) env_name=$2; shift 2 ;;
    --local) use_local=1; shift ;;
    --runtime) runtime_files+=("$2"); shift 2 ;;
    --strict) strict=1; shift ;;
    --warn-extra) warn_extra=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown arg: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if [[ -z "$project_path" ]]; then
  echo "error: --project required" >&2
  usage >&2
  exit 1
fi

if [[ -z "$project_name" ]]; then
  project_name="$(basename "$project_path")"
fi

errors=0
warnings=0

check_pair() {
  local template=$1
  local runtime=$2
  local label=$3

  if [[ ! -f "$template" ]]; then
    echo "skip: template missing → $template"
    return 0
  fi

  if [[ ! -f "$runtime" ]]; then
    if [[ $strict -eq 1 ]]; then
      echo "FAIL [$label]: runtime missing → $runtime (template has keys)" >&2
      errors=$((errors + 1))
    else
      echo "warn [$label]: runtime missing → $runtime (copy from ${template%.example})"
      warnings=$((warnings + 1))
    fi
    return 0
  fi

  local miss extra
  miss=$(missing_keys "$template" "$runtime" || true)
  if [[ -n "$miss" ]]; then
    echo "FAIL [$label]: runtime missing keys from template:" >&2
    echo "$miss" | sed 's/^/  - /' >&2
    errors=$((errors + 1))
  else
    echo "ok   [$label]: all template keys present in $runtime"
  fi

  if [[ $warn_extra -eq 1 ]]; then
    extra=$(extra_keys "$template" "$runtime" || true)
    if [[ -n "$extra" ]]; then
      echo "warn [$label]: runtime has extra keys not in template:" >&2
      echo "$extra" | sed 's/^/  - /' >&2
      warnings=$((warnings + 1))
    fi
  fi
}

# Discover *.env*.example under project (skip node_modules, .git)
while IFS= read -r template; do
  rel="${template#"$project_path"/}"
  base="${rel%.example}"
  runtime=""

  if [[ $use_local -eq 1 ]]; then
    runtime="$CONFIG_ROOT/$project_name/${env_name}.env"
    check_pair "$template" "$runtime" "local:$env_name ($rel)"
    continue
  fi

  if [[ ${#runtime_files[@]} -gt 0 ]]; then
    for rf in "${runtime_files[@]}"; do
      if [[ "$rf" = /* ]]; then
        rt="$rf"
      else
        rt="$project_path/$rf"
      fi
      check_pair "$template" "$rt" "runtime:$rf ← $rel"
    done
    continue
  fi

  # Default: pair example with sibling runtime file in repo
  runtime="$project_path/$base"
  check_pair "$template" "$runtime" "$base"
done < <(find "$project_path" -type f \( -name '.env.example' -o -name '.env.*.example' \) \
  ! -path '*/node_modules/*' ! -path '*/.git/*' 2>/dev/null | sort)

if [[ $errors -gt 0 ]]; then
  echo "check-env-keys: FAIL ($errors error group(s), $warnings warning(s))" >&2
  exit 1
fi

echo "check-env-keys: ok ($warnings warning(s))"
exit 0
