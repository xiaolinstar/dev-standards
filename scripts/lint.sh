#!/usr/bin/env bash
# Aggregate lint: markdownlint (if installed) + internal link check + TODO scan + orphan detection.
# Exits 0 only when all checks pass.
#
# Note: `docs/superpowers/` holds design specs and implementation plans. Those are
# forward-looking and may reference files that don't exist yet, so they're excluded
# from the link check, TODO scan, and markdownlint error-pattern detection.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
errors=0

# 1. markdownlint (optional) — only scan the standard, not the design specs/plans
if command -v pnpm >/dev/null 2>&1; then
  echo "lint: running markdownlint via pnpm dlx"
  if ! (cd "$ROOT" && pnpm dlx markdownlint-cli@0.45.0 '**/*.md' \
        --ignore node_modules --ignore docs/superpowers 2>&1 | tee /tmp/mdl.out); then
    if grep -qE "ERR|error" /tmp/mdl.out 2>/dev/null; then
      errors=$((errors+1))
    fi
  fi
elif command -v markdownlint >/dev/null 2>&1; then
  echo "lint: running markdownlint"
  if ! markdownlint '**/*.md' --ignore node_modules --ignore docs/superpowers; then
    errors=$((errors+1))
  fi
else
  echo "lint: markdownlint not installed (skipping; install with: pnpm add -D markdownlint-cli)"
fi

# 2. TODO / TBD / 待定 scan
echo "lint: scanning for TODO / TBD / 待定"
todo_hits="$(grep -rnE '(TODO|TBD|待定)' "$ROOT" --include='*.md' \
             --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=superpowers || true)"
if [[ -n "$todo_hits" ]]; then
  # Whitelist: this very file mentions TODO/TBD in its own comments and the spec says it's ok
  todo_hits="$(echo "$todo_hits" | grep -v '^scripts/lint.sh:' || true)"
  if [[ -n "$todo_hits" ]]; then
    echo "$todo_hits" >&2
    echo "lint: TODO/TBD/待定 hits above" >&2
    errors=$((errors+1))
  fi
fi

# 3. Internal link check: every .md reference like ](path.md) must resolve
echo "lint: checking internal .md links"
link_errors=0
while IFS= read -r match; do
  file="$(echo "$match" | cut -d: -f1)"
  target="$(echo "$match" | sed -E 's/.*\]\(([^)]+)\).*/\1/' | sed 's/#.*//')"
  [[ -z "$target" ]] && continue
  [[ "$target" =~ ^https?:// ]] && continue
  [[ "$target" =~ ^mailto: ]] && continue
  base_dir="$(dirname "$file")"
  resolved="$base_dir/$target"
  if [[ ! -e "$resolved" ]]; then
    echo "$file: broken internal link → $target" >&2
    link_errors=$((link_errors+1))
  fi
done < <(grep -rEn '\]\([^)]+\.md' "$ROOT" --include='*.md' \
         --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=superpowers || true)
if [[ $link_errors -gt 0 ]]; then
  echo "lint: $link_errors broken internal link(s)" >&2
  errors=$((errors+1))
fi

# 4. Orphan detection: .md files in playbook/ not linked from INDEX.md
echo "lint: checking for orphan playbook/ files"
orphans=0
for f in "$ROOT"/playbook/*.md; do
  [[ -f "$f" ]] || continue
  base="$(basename "$f")"
  [[ "$base" == "INDEX.md" ]] && continue
  if ! grep -q "$base" "$ROOT/playbook/INDEX.md"; then
    echo "playbook/ orphan: $base not referenced in INDEX.md" >&2
    orphans=$((orphans+1))
  fi
done
if [[ $orphans -gt 0 ]]; then
  echo "lint: $orphans orphan file(s) in playbook/" >&2
  errors=$((errors+1))
fi

if [[ $errors -gt 0 ]]; then
  echo "lint: FAIL ($errors issue groups)" >&2
  exit 1
fi
echo "lint: ok"