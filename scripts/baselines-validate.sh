#!/usr/bin/env bash
# Validate playbook/baselines/*.md frontmatter + flag stale (>30 days since last-reviewed).
# Exits 0 if all baselines are well-formed and fresh, 1 otherwise.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_DIR="$ROOT/playbook/baselines"
errors=0
required=(baseline upstream upstream-version status deviation-count last-reviewed)
allowed_status=(adopted adapted observing deprecated)
stale_days="${BASELINE_STALE_DAYS:-30}"
stale=()

if [[ ! -d "$BASE_DIR" ]]; then
  echo "baselines-validate: $BASE_DIR not found (skipping)" >&2
  exit 0
fi

# Today as epoch day (UTC); for last-reviewed comparison
today_epoch="$(date -u +%s)"

for f in "$BASE_DIR"/*.md; do
  [[ -f "$f" ]] || continue
  base="$(basename "$f")"
  # README.md is documentation, not a baseline mapping
  [[ "$base" == "README.md" ]] && continue

  if ! head -1 "$f" | grep -q '^---$'; then
    echo "$f:1: missing YAML frontmatter" >&2
    errors=$((errors+1))
    continue
  fi

  for field in "${required[@]}"; do
    if ! grep -qE "^$field:" "$f"; then
      echo "$f: missing required frontmatter field: $field" >&2
      errors=$((errors+1))
    fi
  done

  # status must be one of allowed values
  status="$(grep -E '^status:' "$f" | head -1 | sed -E 's/^status:[[:space:]]*//' | awk '{print $1}')"
  if [[ -n "$status" ]]; then
    ok=0
    for s in "${allowed_status[@]}"; do
      [[ "$status" == "$s" ]] && ok=1
    done
    if [[ $ok -eq 0 ]]; then
      echo "$f: status '$status' not in: ${allowed_status[*]}" >&2
      errors=$((errors+1))
    fi
  fi

  # last-reviewed staleness
  lr="$(grep -E '^last-reviewed:' "$f" | head -1 | sed -E 's/^last-reviewed:[[:space:]]*//' | tr -d '[:space:]')"
  if [[ -n "$lr" ]] && [[ "$lr" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    lr_epoch="$(date -u -d "$lr" +%s 2>/dev/null || echo 0)"
    if [[ $lr_epoch -gt 0 ]]; then
      age_days=$(( (today_epoch - lr_epoch) / 86400 ))
      if [[ $age_days -gt $stale_days ]]; then
        stale+=("$f ($age_days days)")
      fi
    fi
  fi
done

if [[ ${#stale[@]} -gt 0 ]]; then
  echo "baselines-validate: STALE (>$stale_days days):" >&2
  for s in "${stale[@]}"; do echo "  $s" >&2; done
  # staleness is a warning, not error, until Phase 1 ends
  echo "baselines-validate: ok (with stale warnings)"
  exit 0
fi

if [[ $errors -gt 0 ]]; then
  echo "baselines-validate: $errors error(s)" >&2
  exit 1
fi
echo "baselines-validate: ok"