#!/usr/bin/env bash
# DEPRECATED (ADR-0012): L3 runtime is sole source on VPS; do not import into ~/.config.
set -euo pipefail

cat >&2 <<'EOF'
error: env import-config is deprecated (ADR-0012).

~/.config/xiaolinstar now stores GitHub L2 IaC only (github/<env>/{variables,secrets}.env).
Business secrets (.env.production, etc.) live only on VPS or local gitignore files.

Use instead:
  sync.sh env init-github-env --project <name> --environment <env>
  sync.sh env sync-github --project <name> --environment <env>

See: dev-standards/playbook/adr/0012-config-github-l2-only.md
EOF
exit 1
