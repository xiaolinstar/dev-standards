#!/usr/bin/env bash
# DEPRECATED (ADR-0012): do not push ~/.config L3 backups to runtime files.
set -euo pipefail

cat >&2 <<'EOF'
error: env apply-config is deprecated (ADR-0012).

Edit runtime files directly on VPS or local machine:
  apps/api/.env.production  (secrets — VPS / local gitignore only)

For GitHub Actions L2:
  sync.sh env init-github-env --project <name> --environment <env>
  sync.sh env sync-github --project <name> --environment <env>

See: dev-standards/playbook/adr/0012-config-github-l2-only.md
EOF
exit 1
