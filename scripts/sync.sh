#!/usr/bin/env bash
# Sync dev-standards artifacts to local Claude Code paths and project adapter targets.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_SKILLS="${HOME}/.claude/skills"
CURSOR_SKILLS="${HOME}/.cursor/skills"

usage() {
  cat <<EOF
Usage: $(basename "$0") <command> [args]

Commands:
  skills              Sync skills/ → ~/.claude/skills/
  skills --cursor     Also sync skills/ → ~/.cursor/skills/
  adapters <name> <project>   Copy adapters/<name>/ → target path under <project>/
                              (e.g. 'adapters cursor <project>' → <project>/.cursor/rules/)
  hooks <project>     Copy hooks/ → <project>/.claude/hooks/
  all [project]       skills + print adapters/hooks usage (optional project path for adapters cursor)
  validate            Run all validators (lint + adr + baselines)
  help                Show this message

Examples:
  $(basename "$0") skills
  $(basename "$0") adapters cursor ~/AgentProjects/my-app
  $(basename "$0") all ~/AgentProjects/my-app
EOF
}

sync_skills() {
  local target="$1"
  local name
  mkdir -p "$target"
  for dir in "$ROOT"/skills/*/; do
    [[ -d "$dir" ]] || continue
    name="$(basename "$dir")"
    rsync -a --delete "$dir" "$target/$name/"
    echo "  synced: $name → $target/$name/"
  done
}

# Map adapter name → destination directory under the project root.
# Extend this when adding new adapters (see adapters/README.md).
adapter_dest() {
  case "$1" in
    cursor) echo ".cursor/rules" ;;
    *) echo "error: unknown adapter: $1" >&2
       echo "  known adapters: cursor" >&2
       return 1 ;;
  esac
}

cmd_skills() {
  echo "→ Claude Code skills: $CLAUDE_SKILLS"
  sync_skills "$CLAUDE_SKILLS"
  if [[ "${1:-}" == "--cursor" ]]; then
    echo "→ Cursor skills: $CURSOR_SKILLS"
    sync_skills "$CURSOR_SKILLS"
  fi
}

cmd_adapters() {
  local name="${1:-}"
  local project="${2:-}"
  if [[ -z "$name" ]] || [[ -z "$project" ]]; then
    echo "error: usage: $0 adapters <name> <project>" >&2
    usage >&2
    exit 1
  fi
  local src="$ROOT/adapters/$name"
  if [[ ! -d "$src" ]]; then
    echo "error: adapter source not found: $src" >&2
    exit 1
  fi
  local rel dest
  rel="$(adapter_dest "$name")"
  project="$(cd "$project" && pwd)"
  dest="$project/$rel"
  mkdir -p "$dest"
  rsync -a "$src/" "$dest/"
  echo "→ adapter '$name' copied to $dest"
}

cmd_hooks() {
  local project="${1:-}"
  if [[ -z "$project" ]]; then
    echo "error: project path required" >&2
    usage >&2
    exit 1
  fi
  project="$(cd "$project" && pwd)"
  local dest="$project/.claude/hooks"
  mkdir -p "$dest"
  if [[ ! -d "$ROOT/hooks" ]] || [[ -z "$(ls -A "$ROOT/hooks" 2>/dev/null)" ]]; then
    echo "warning: no hooks in $ROOT/hooks" >&2
    exit 0
  fi
  # Skip README when copying hook scripts
  rsync -a --exclude='README.md' "$ROOT/hooks/" "$dest/"
  echo "→ hooks copied to $dest"
  echo "  remember to wire hooks in .claude/settings.json (see hooks/README.md)"
}

cmd_all() {
  cmd_skills
  echo
  echo "Adapters:  $0 adapters <name> <project>   (e.g. 'adapters cursor <project>')"
  echo "Hooks:     $0 hooks <project>"
  if [[ -n "${1:-}" ]]; then
    echo
    cmd_adapters cursor "$1"
  fi
}

cmd_validate() {
  local script failed=0
  for script in lint.sh adr-validate.sh baselines-validate.sh; do
    if [[ -x "$ROOT/scripts/$script" ]]; then
      echo "→ $script"
      if ! bash "$ROOT/scripts/$script"; then
        failed=1
      fi
    else
      echo "warning: $ROOT/scripts/$script not found or not executable" >&2
    fi
  done
  return $failed
}

main() {
  local cmd="${1:-help}"
  shift || true
  case "$cmd" in
    skills)   cmd_skills "$@" ;;
    adapters) cmd_adapters "$@" ;;
    hooks)    cmd_hooks "$@" ;;
    all)      cmd_all "$@" ;;
    validate) cmd_validate ;;
    help|-h|--help) usage ;;
    *)
      echo "error: unknown command: $cmd" >&2
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
