#!/usr/bin/env bash
# Validate playbook/env-registry.yaml structure and cross-links.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REGISTRY="$ROOT/playbook/env-registry.yaml"
errors=0

if [[ ! -f "$REGISTRY" ]]; then
  echo "env-registry: missing $REGISTRY" >&2
  exit 1
fi

if ! grep -q 'config_root: ~/.config/xiaolinstar' "$REGISTRY"; then
  echo "env-registry: config_root must be ~/.config/xiaolinstar" >&2
  errors=$((errors + 1))
fi

if ! grep -q 'env-management.md' "$ROOT/playbook/INDEX.md"; then
  echo "env-registry: env-management.md not in INDEX.md" >&2
  errors=$((errors + 1))
fi

for cat in platform application content; do
  if ! grep -q "  ${cat}:" "$REGISTRY"; then
    echo "env-registry: missing category → $cat" >&2
    errors=$((errors + 1))
  fi
done

for project in xiaolin-gateway ai-todo party-helper drink-budget xiaolin-docs xiaolin-life; do
  block=$(grep -A20 "^  ${project}:" "$REGISTRY" || true)
  if [[ -z "$block" ]]; then
    echo "env-registry: missing project block → $project" >&2
    errors=$((errors + 1))
    continue
  fi
  if ! echo "$block" | grep -q 'category:'; then
    echo "env-registry: $project missing category" >&2
    errors=$((errors + 1))
  fi
  if ! echo "$block" | grep -q 'path:'; then
    echo "env-registry: $project missing templates.path" >&2
    errors=$((errors + 1))
  fi
done

if [[ $errors -gt 0 ]]; then
  echo "env-registry: FAIL ($errors issue(s))" >&2
  exit 1
fi

echo "env-registry: ok"
