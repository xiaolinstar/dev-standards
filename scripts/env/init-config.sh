#!/usr/bin/env bash
# Create ~/.config/xiaolinstar github/ layout (GitHub Actions Variables + Secrets IaC only).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_ROOT="${XIAOLINSTAR_CONFIG_ROOT:-$HOME/.config/xiaolinstar}"
REGISTRY="$ROOT/playbook/env-registry.yaml"
PROFILES="$ROOT/scripts/env/github-sync-profiles.json"

mkdir -p "$CONFIG_ROOT"

readme="$CONFIG_ROOT/README.md"
cat >"$readme" <<'EOF'
# xiaolinstar · GitHub Actions L2 IaC

本目录**仅**存放 GitHub Actions **Variables** 与 **Secrets** 的本地编写源，**不**备份 VPS 业务运行时。

## 布局

```text
~/.config/xiaolinstar/<project>/github/<environment>/
├── variables.env    # → gh variable set
└── secrets.env      # → gh secret set
```

仓库级（platform / content）：

```text
~/.config/xiaolinstar/<project>/github/variables.env
~/.config/xiaolinstar/<project>/github/secrets.env
```

## 工作流

1. `sync.sh env init-github-env --project <name> --environment <env>`
2. 编辑 variables.env / secrets.env
3. `sync.sh env sync-github --project <name> --environment <env>`

L3 业务密钥只在 VPS。见 ADR-0012。

EOF
chmod 600 "$readme"
echo "→ wrote $readme"

touch_pair() {
  local dir=$1
  local hint=$2
  mkdir -p "$dir"
  for f in variables.env secrets.env; do
    local path="$dir/$f"
    if [[ ! -f "$path" ]]; then
      touch "$path"
      chmod 600 "$path"
      echo "→ created $path ($hint)"
    fi
  done
}

if command -v node >/dev/null 2>&1 && [[ -f "$PROFILES" ]]; then
  while IFS= read -r proj; do
    scope=$(node -e "const p=require('$PROFILES'); console.log(p['$proj'].scope||'repository')")
    dir="$CONFIG_ROOT/$proj/github"
    if [[ "$scope" == "environment" ]]; then
      block=$(grep -A80 "^  ${proj}:" "$REGISTRY" || true)
      if echo "$block" | grep -q 'github_environments:'; then
        while IFS= read -r env_name; do
          [[ -n "$env_name" ]] || continue
          touch_pair "$dir/$env_name" "copy from docs/env/github/$env_name/*.env.example"
        done < <(echo "$block" | grep 'name:' | sed 's/.*name: //')
      else
        for env_name in staging production; do
          touch_pair "$dir/$env_name" "fill manually"
        done
      fi
    else
      touch_pair "$dir" "repository-scoped L2"
    fi
  done < <(node -e "const p=require('$PROFILES'); console.log(Object.keys(p).join('\n'))")
fi

echo "→ config root: $CONFIG_ROOT"
