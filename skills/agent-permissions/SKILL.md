---
name: agent-permissions
description: Manage cross-agent shell permission allowlists (Cursor, Claude Code, Codex, OpenCode, Antigravity) from dev-standards permissions/manifest.json. Use when adding, modifying, or removing check/deny rules, syncing permissions.json, or asking how to auto-run typecheck/lint without approval prompts.
---

# Agent Permissions（跨工具生命周期）

真源：`~/AgentProjects/dev-standards/permissions/manifest.json`

分发：`~/AgentProjects/dev-standards/scripts/sync.sh permissions [--user] [--project PATH]`

**只维护 Claude + AGENTS 生态下的执行策略**；不逐工具兼容 Copilot / Windsurf 等。

## 三层

```text
permissions/manifest.json     ← 规则真源（id、tier、status、patterns）
permissions/overlays/*.json   ← 项目特例（可选）
sync.sh permissions           ← 生成并部署到各 Agent
```

## 规则字段（生命周期）

| 字段 | 说明 |
|------|------|
| `id` | 稳定标识，用于修改/删除时引用 |
| `tier` | `check`（只读验证，免审批）或 `deny`（阻断或需审批） |
| `status` | `active` \| `deprecated` \| `removed` |
| `since` | 引入日期 |
| `patterns` | 命令前缀（空格分词，与 shell 实际调用一致） |
| `note` | 人类可读说明 |

### 新增 check 规则

示例条目：

```json
{
  "id": "pnpm-validate",
  "tier": "check",
  "status": "active",
  "since": "2026-06-28",
  "patterns": ["pnpm validate"],
  "note": "Custom validate script"
}
```

1. 编辑 `permissions/manifest.json`，追加条目
2. 预览：`bash ~/AgentProjects/dev-standards/scripts/sync.sh permissions`
3. 部署：`bash ~/AgentProjects/dev-standards/scripts/sync.sh permissions --user`
4. 若有项目 overlay：`permissions/overlays/<repo-name>.json` + `--project PATH`

### 修改规则

- 改 `patterns` 或 `note`：直接编辑 manifest，保持 `id` 不变，重新 sync。
- 废弃：设 `status: "deprecated"`（保留审计，不再部署）。
- 删除：设 `status: "removed"` 或从 manifest 删掉条目；重新 sync 后各工具配置不再包含该 pattern。

### 项目 overlay

`permissions/overlays/ai-todo.json` 示例 — 仅追加本项目 patterns，与全局 manifest **按 id 合并**。

```bash
sync.sh permissions --user --project ~/AgentProjects/ai-todo
```

## 部署目标

| Agent | 全局路径 | 项目路径 |
|-------|----------|----------|
| **Cursor** | `~/.cursor/permissions.json` | `.cursor/permissions.json` |
| **Claude Code** | `~/.claude/settings.json`（合并 `permissions`） | `.claude/settings.json` |
| **Codex** | `~/.codex/rules/dev-standards.rules` | `.codex/rules/dev-standards.rules` |
| **OpenCode** | `~/.config/opencode/opencode.json` | 可手拷 `permission.bash` 段 |
| **Antigravity** | `~/.gemini/policies/dev-standards-check.toml` | 项目级 `.antigravity/settings.json` 手补 |

### 各工具前置条件

| Agent | 还需 |
|-------|------|
| Cursor | Run Mode：Settings → Agents → Approvals → **Auto-review** 或 **Allowlist** |
| Claude Code | `permissions.allow` 中 `Bash(...)` 规则；deny 优先于 allow |
| Codex | 读取 `~/.codex/rules/*.rules`；勿改 `default.rules`（TUI 自动写入） |
| OpenCode | `permission.bash` 中 `*` 默认 `ask`，具体 pattern `allow` |
| Antigravity | 关闭 Strict Mode；规则在 `~/.gemini/policies/` |

## 预览产物

`permissions/generated/` — sync 时更新的本地预览（cursor / claude / codex / opencode / antigravity）。

## 禁止

- ❌ 在各工具配置里手改 allowlist 而不回写 manifest（下一轮 sync 会覆盖或漂移）
- ❌ 用裸 `Bash(*)` 或 `terminalAllowlist: ["pnpm"]` 放行全部子命令
- ❌ 把 manifest 复制进业务仓库（只用 overlay + sync）

## 参考

- [playbook/agent-config.md](../../playbook/agent-config.md)
- [permissions/README.md](../../permissions/README.md)
- Cursor: https://cursor.com/docs/reference/permissions
- Codex rules: https://developers.openai.com/codex/rules
- OpenCode: https://opencode.ai/docs/permissions/
