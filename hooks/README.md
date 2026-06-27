# Hooks 模板

两类模板，部署目标不同：

| 类型 | 命令 | 目标路径 | 用途 |
|------|------|----------|------|
| Claude PreToolUse | `sync.sh hooks <project>` | `<project>/.claude/hooks/` | Agent 会话内守卫 |
| Husky pre-commit | `sync.sh hooks-precommit <project>` | `<project>/.husky/` 等 | Git commit 前 lint / secret scan |

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

项目专属守卫（发邮件、写周报等）留在各业务仓库，不放进 dev-standards。
