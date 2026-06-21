# Hooks 模板

可选的 Claude Code PreToolUse 守卫脚本。按项目复制，不在标准库全局强制启用。

## 安装

```bash
~/AgentProjects/dev-standards/scripts/sync.sh hooks /path/to/project
```

## 注册（`.claude/settings.json`）

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

## 包含

| 文件 | 作用 |
|------|------|
| `git-commit-guard.py` | 提交前会话内确认；`CONFIRMED=1` 放行 |

项目专属守卫（发邮件、写周报等）留在各业务仓库，不放进 dev-standards。
