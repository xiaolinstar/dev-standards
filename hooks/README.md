# Hooks 模板

三类模板，部署目标不同：

| 类型 | 命令 | 目标路径 | 用途 | 适用项目 |
|------|------|----------|------|----------|
| Claude PreToolUse | `sync.sh hooks <project>` | `<project>/.claude/hooks/` | Agent 会话内守卫 | 所有项目 |
| Husky pre-commit | `sync.sh hooks-precommit <project>` | `<project>/.husky/` 等 | Git commit 前 lint / secret scan | Node.js / TS 项目 |
| Python pre-commit | `sync.sh hooks-precommit-python <project>` | `<project>/.pre-commit-config.yaml` | Git commit 前 lint / secret scan | Python 项目 |

## 选型决策

```text
if 项目有 package.json:
    → sync.sh hooks-precommit（Husky + pnpm）
elif 项目有 pyproject.toml:
    → sync.sh hooks-precommit-python（pre-commit + uv）
```

## Claude hooks（PreToolUse）

```bash
~/AgentProjects/dev-standards/scripts/sync.sh hooks /path/to/project
```

### 注册（`.claude/settings.json`）

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "python3 $CLAUDE_PROJECT_DIR/.claude/hooks/git-commit-guard.py",
            "statusMessage": "检查 Git commit..."
          }
        ]
      }
    ]
  }
}
```

### 包含

| 文件 | 作用 |
|------|------|
| `git-commit-guard.py` | 提交前会话内确认；`CONFIRMED=1` 放行 |

## Husky pre-commit 模板

```bash
~/AgentProjects/dev-standards/scripts/sync.sh hooks-precommit /path/to/project
```

模板源码：`hooks/pre-commit/`。安装说明见该目录 `README.md` 与
[`playbook/ci-minimum-gate.md`](../playbook/ci-minimum-gate.md)。

若目标项目已有 `.husky/`，命令会 **warning 且不覆盖** hook 文件。

## Python pre-commit 模板

```bash
~/AgentProjects/dev-standards/scripts/sync.sh hooks-precommit-python /path/to/project
```

模板源码：`hooks/pre-commit-python/`。安装说明见该目录 `README.md` 与
[`playbook/ci-minimum-gate.md`](../playbook/ci-minimum-gate.md)。

若目标项目已有 `.pre-commit-config.yaml`，命令会 **warning 且不覆盖**。

项目专属守卫（发邮件、写周报等）留在各业务仓库，不放进 dev-standards。
