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
  hooks <project>     Copy Claude hooks → <project>/.claude/hooks/
  hooks-precommit <project>
                      Install Husky pre-commit templates (see hooks/pre-commit/)
  permissions [--user] [--project PATH]
                      Sync permissions/manifest.json → Cursor / Claude / Codex / OpenCode / Antigravity
  template <name> <dest>
                      Copy templates/<name>/ → <dest>/ (e.g. template wechat-mp ./my-app)
  all [project]       skills + print adapters/hooks usage (optional project path for adapters cursor)
  validate            Run all validators (lint + adr + baselines + env registry)
  env init-config     Create ~/.config/xiaolinstar layout (never overwrites values)
  env check           Compare *.example keys vs runtime (see scripts/env/check-env-keys.sh)
  help                Show this message

Examples:
  $(basename "$0") skills
  $(basename "$0") adapters cursor ~/AgentProjects/my-app
  $(basename "$0") hooks-precommit ~/AgentProjects/my-app
  $(basename "$0") template wechat-mp ~/AgentProjects/my-miniapp
  $(basename "$0") permissions --user
  $(basename "$0") permissions --user --project ~/AgentProjects/ai-todo
  $(basename "$0") env init-config
  $(basename "$0") env check --project ~/AgentProjects/ai-todo --local production
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
  # Skip README and pre-commit templates (deployed via hooks-precommit)
  rsync -a --exclude='README.md' --exclude='pre-commit/' "$ROOT/hooks/" "$dest/"
  echo "→ hooks copied to $dest"
  echo "  remember to wire hooks in .claude/settings.json (see hooks/README.md)"
}

cmd_hooks_precommit() {
  local project="${1:-}"
  if [[ -z "$project" ]]; then
    echo "error: project path required" >&2
    usage >&2
    exit 1
  fi
  local src="$ROOT/hooks/pre-commit"
  if [[ ! -d "$src" ]]; then
    echo "error: template dir not found: $src" >&2
    exit 1
  fi
  project="$(cd "$project" && pwd)"

  if [[ -d "$project/.husky" ]]; then
    echo "warning: $project/.husky already exists; skipping hook install (no overwrite)" >&2
  else
    mkdir -p "$project/.husky"
    install -m 755 "$src/husky-pre-commit.sh" "$project/.husky/pre-commit"
    install -m 755 "$src/husky-commit-msg.sh" "$project/.husky/commit-msg"
    echo "→ installed .husky/pre-commit and .husky/commit-msg"
  fi

  if [[ -f "$project/commitlint.config.cjs" ]] || [[ -f "$project/commitlint.config.js" ]]; then
    echo "warning: commitlint config already exists; skipping commitlint.config.cjs" >&2
  else
    cp "$src/commitlint.config.cjs" "$project/commitlint.config.cjs"
    echo "→ installed commitlint.config.cjs"
  fi

  cp "$src/package.json.snippet" "$project/.dev-standards-package.json.snippet"
  cp "$src/README.md" "$project/.dev-standards-precommit-README.md"
  echo "→ wrote .dev-standards-precommit-README.md and .dev-standards-package.json.snippet"
  echo "  merge snippet into package.json, then: pnpm install && pnpm exec husky"
  echo "  full guide: $ROOT/playbook/ci-minimum-gate.md"
}

cmd_template() {
  local name="${1:-}"
  local dest="${2:-}"
  if [[ -z "$name" ]] || [[ -z "$dest" ]]; then
    echo "error: usage: $0 template <name> <dest>" >&2
    usage >&2
    exit 1
  fi
  local src="$ROOT/templates/$name"
  if [[ ! -d "$src" ]]; then
    echo "error: template not found: $src" >&2
    echo "  available: $(find "$ROOT/templates" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | tr '\n' ' ')" >&2
    exit 1
  fi
  mkdir -p "$dest"
  dest="$(cd "$dest" && pwd)"
  rsync -a "$src/" "$dest/"
  echo "→ template '$name' copied to $dest"
  if [[ -f "$src/README.md" ]]; then
    echo "  next: read $dest/README.md (replace YOUR_* placeholders)"
  fi
}

cmd_all() {
  cmd_skills
  echo
  echo "Adapters:  $0 adapters <name> <project>   (e.g. 'adapters cursor <project>')"
  echo "Hooks:     $0 hooks <project>   (Claude PreToolUse guard)"
  echo "Pre-commit: $0 hooks-precommit <project>   (Husky + lint-staged + commitlint)"
  echo "Template:   $0 template <name> <dest>   (e.g. template wechat-mp ./my-app)"
  if [[ -n "${1:-}" ]]; then
    echo
    cmd_adapters cursor "$1"
  fi
}

cmd_permissions() {
  node "$ROOT/scripts/permissions-sync.mjs" "$@"
}

cmd_env() {
  local sub="${1:-help}"
  shift || true
  case "$sub" in
    init-config) bash "$ROOT/scripts/env/init-config.sh" "$@" ;;
    check) bash "$ROOT/scripts/env/check-env-keys.sh" "$@" ;;
    *)
      echo "Usage: $0 env {init-config|check} [args]" >&2
      echo "  init-config   → ~/.config/xiaolinstar/" >&2
      echo "  check         → scripts/env/check-env-keys.sh --help" >&2
      exit 1
      ;;
  esac
}

cmd_validate() {
  local script failed=0
  for script in lint.sh adr-validate.sh baselines-validate.sh env/validate-registry.sh; do
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
    hooks-precommit) cmd_hooks_precommit "$@" ;;
    permissions) cmd_permissions "$@" ;;
    env) cmd_env "$@" ;;
    template) cmd_template "$@" ;;
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
