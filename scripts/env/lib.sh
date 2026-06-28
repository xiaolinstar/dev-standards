#!/usr/bin/env bash
# Extract KEY names from dotenv-style files (comments and blank lines ignored).
set -euo pipefail

env_file_keys() {
  local file=$1
  [[ -f "$file" ]] || return 1
  grep -E '^[A-Za-z_][A-Za-z0-9_]*=' "$file" | cut -d= -f1 | sort -u
}

missing_keys() {
  local template=$1
  local runtime=$2
  comm -23 <(env_file_keys "$template") <(env_file_keys "$runtime" 2>/dev/null || true)
}

extra_keys() {
  local template=$1
  local runtime=$2
  comm -13 <(env_file_keys "$template") <(env_file_keys "$runtime" 2>/dev/null || true)
}
