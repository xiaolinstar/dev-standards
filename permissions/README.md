# Agent permissions（跨工具真源）

`manifest.json` 定义 check / deny 规则的生命周期；`sync.sh permissions` 分发到各 Agent。

| 工具 | 部署目标 |
|------|----------|
| Cursor | `~/.cursor/permissions.json`、`<project>/.cursor/permissions.json` |
| Claude Code | `~/.claude/settings.json`（合并 `permissions`） |
| Codex | `~/.codex/rules/dev-standards.rules` |
| OpenCode | `~/.config/opencode/opencode.json`（合并 `permission.bash`） |
| Antigravity | `~/.gemini/policies/dev-standards-check.toml` |

项目特例：`overlays/<project>.json`（如 `ai-todo.json`）。

操作入口 Skill：`skills/agent-permissions/SKILL.md`。
