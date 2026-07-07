# Agent 配置：最小维护（Claude + AGENTS 双体系）

> 立场：**只维护 Claude Code 生态 + AGENTS.md 通用层**，不对 Copilot / Windsurf / Continue 等逐一适配。

## 三层结构

```text
playbook/                    ← 真源（人读 + 审计基准）
    │
    ├─ AGENTS.md             ← 各项目：跨 Agent 通用说明（Cursor / Codex / Copilot 等读）
    │
    ├─ CLAUDE.md             ← 各项目：@AGENTS.md + Claude 专有补充（hooks、子目录 CLAUDE.md）
    │
    └─ .cursor/rules/*.mdc   ← 可选：仅 glob 作用域规则（sync.sh 从 playbook 派生）
```

| 层 | 谁读 | 维护什么 |
|----|------|----------|
| **playbook/** | 人 + 审计 | 原则、ADR、主题 playbook |
| **AGENTS.md** | Cursor、Codex、Copilot… | 项目结构、命令、约束、文档入口 |
| **CLAUDE.md** | Claude Code | 首行 `@AGENTS.md`；hooks、Skills、子模块 CLAUDE.md 指针 |
| **.cursor/rules/** | Cursor Agent | 需要 `globs` / `alwaysApply` 时才部署；`sync.sh adapters cursor` |

**不维护**：`.windsurfrules`、`.github/copilot-instructions.md` 等逐工具副本。

## 不扫描的目录

| 路径 | 归属 | Cursor 是否加载 |
|------|------|-----------------|
| `.claude/skills/` | Claude Code 项目/个人 Skill | ❌ |
| `.claude/hooks/` | Claude PreToolUse 等 | ❌ |
| `.agents/` | 技能市场缓存等 | ❌ |
| `~/.claude/skills/` | 个人 Skill | ❌ |

Cursor **不会**自动读 `.claude/`、`.agents/`。跨工具共享内容放 **AGENTS.md**，不要指望目录扫描替代。

## 新项目 checklist

1. 写根 **AGENTS.md**（结构、命令、禁止项、docs 入口）
2. 写 **CLAUDE.md**：`@AGENTS.md` + Claude 专有段（如有）
3. 若用 Cursor 且需要路径触发规则：`sync.sh adapters cursor <project>`
4. 子模块（如 `apps/miniapp/`）可嵌套 **AGENTS.md** 或 **CLAUDE.md**，不重复根目录长文

## 变更流程

1. 改 **playbook/**（标准变更）
2. 各项目 **AGENTS.md** 只更新项目特例摘要
3. 需要 Cursor glob 规则时：`sync.sh adapters cursor <project>`
4. **禁止**在 AGENTS.md 与 CLAUDE.md 各写一份完整 playbook 副本
5. **环境变量**：L0 在 `docs/env/github/`（`variables.env.example` + `secrets.env.example`）；L2 IaC 在 `~/.config/.../github/<env>/`；L3 仅在 VPS

## Cursor：check 命令免审批

见 Skill **`agent-permissions`** 与 `permissions/manifest.json`（真源）。

1. 编辑 manifest → `sync.sh permissions --user`（全局）或加 `--project PATH`（含 overlay）
2. Cursor 另需 Run Mode：**Auto-review** 或 **Allowlist**（Settings → Agents → Approvals）

旧说明（单文件手维护）仍可用 `~/.cursor/permissions.json`，但**推荐改 manifest + sync** 以同步 Claude / Codex / OpenCode / Antigravity。

## 与 adapters 的关系

`adapters/cursor/` 是 playbook 的**派生镜像**，不是第三套真源。仅 Cursor 的 `.mdc` frontmatter（globs）无法由 AGENTS.md 表达时才部署。

详见 [adapters/README.md](../adapters/README.md)。
