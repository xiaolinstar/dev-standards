#!/usr/bin/env bash
# Create ~/.config/xiaolinstar layout and README (never overwrites existing *.env).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_ROOT="${XIAOLINSTAR_CONFIG_ROOT:-$HOME/.config/xiaolinstar}"
REGISTRY="$ROOT/playbook/env-registry.yaml"

mkdir -p "$CONFIG_ROOT"

readme="$CONFIG_ROOT/README.md"
if [[ ! -f "$readme" ]]; then
  cat >"$readme" <<'EOF'
# xiaolinstar 集中环境配置（L3）

本目录存放**真实**环境变量与密钥，不在 Git 仓库中。

## 布局

```text
~/.config/xiaolinstar/<project>/<env>.env
```

例如：

- `ai-todo/production.env`
- `xiaolin-gateway/production.env`

## 规则

1. 只改本目录与 VPS 上的运行时文件；仓库内只改 `*.example`。
2. **禁止** Agent 自动编辑本目录；由人工维护。
3. 模板新增键后运行：

```bash
~/AgentProjects/dev-standards/scripts/sync.sh env check --project <repo> --local production
```

4. 索引见 dev-standards `playbook/env-registry.yaml` 与 `playbook/env-management.md`。

EOF
  chmod 600 "$readme"
  echo "→ wrote $readme"
else
  echo "→ keep existing $readme"
fi

while IFS= read -r proj; do
  dir="$CONFIG_ROOT/$proj"
  mkdir -p "$dir"
  block=$(grep -A25 "^  ${proj}:" "$REGISTRY" || true)
  for env in local staging production; do
    if echo "$block" | grep -q "${env}:"; then
      f="$dir/${env}.env"
      if [[ ! -f "$f" ]]; then
        touch "$f"
        chmod 600 "$f"
        echo "→ created $f (empty; fill manually)"
      fi
    fi
  done
done < <(grep -E '^  (xiaolin-gateway|ai-todo|party-helper|drink-budget|xiaolin-docs|xiaolin-life):$' "$REGISTRY" | sed 's/://;s/^  //')

echo "→ config root: $CONFIG_ROOT"
