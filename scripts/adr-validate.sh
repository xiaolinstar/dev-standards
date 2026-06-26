#!/usr/bin/env bash
# Validate playbook/adr/*.md: file name pattern + frontmatter completeness.
# Exits 0 if all ADRs are well-formed, 1 otherwise.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADR_DIR="$ROOT/playbook/adr"
errors=0
required=(ID Title Status Date Deciders)

if [[ ! -d "$ADR_DIR" ]]; then
  echo "adr-validate: $ADR_DIR not found" >&2
  exit 0  # no adrs yet is fine
fi

for f in "$ADR_DIR"/*.md; do
  [[ -f "$f" ]] || continue
  base="$(basename "$f")"
  # 1. Filename pattern: NNNN-kebab-case.md
  if ! [[ "$base" =~ ^[0-9]{4}-[a-z0-9-]+\.md$ ]]; then
    echo "$f:1: filename must match NNNN-kebab-case.md (got: $base)" >&2
    errors=$((errors+1))
  fi
  # 2. Frontmatter exists
  if ! head -1 "$f" | grep -q '^---$'; then
    echo "$f:1: missing YAML frontmatter (first line must be ---)" >&2
    errors=$((errors+1))
    continue
  fi
  # 3. Required fields
  for field in "${required[@]}"; do
    if ! grep -qE "^$field:" "$f"; then
      echo "$f: missing required frontmatter field: $field" >&2
      errors=$((errors+1))
    fi
  done
done

if [[ $errors -gt 0 ]]; then
  echo "adr-validate: $errors error(s)" >&2
  exit 1
fi
echo "adr-validate: ok"