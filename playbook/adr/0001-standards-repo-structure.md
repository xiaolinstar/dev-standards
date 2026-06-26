---
ID: 0001
Title: 标准库仓库结构与 Claude Code 对齐
Status: Accepted
Date: 2026-06-21
Deciders: xingxiaolin
---

## 背景

同时维护多个个人/工作项目，需要把重复经验沉淀为可版本管理的标准，并优先融入 Claude Code 生态（Skills、hooks、CLAUDE.md），同时兼容 Cursor Rules。

## 决策

1. 在 `~/AgentProjects/dev-standards` 建立独立 Git 仓库（方案 B）
2. Skills 源码放在 `skills/`，通过脚本同步到 `~/.claude/skills/`（一等公民）
3. Hooks 模板放在 `hooks/`，按项目部署到 `<project>/.claude/hooks/`（一等公民）
4. 非 Claude Code 兼容层放在 `adapters/<name>/`（如 `adapters/cursor/`）；每个 adapter 是其他 Agent / IDE 的派生镜像，与未来新增的 adapter（Codex、Continue 等）平等并列
5. 项目模板（方案 C）暂缓，仅保留 `templates/` 占位
6. 项目专属 domain Skill（如 ai-todo）留在各业务仓库，不迁入标准库

## 理由

- Claude Code 的 Skill 机制已在本机 workspace 项目验证可行
- 标准库与业务解耦，避免把 SRE/邮件等工作域标准与个人编码标准混在一个 repo
- B 方案成本低于 template monorepo，仍保留演进为 C 的路径

## 后果

- 目录结构明确分层：**一等公民**（`playbook/`、`skills/`、`hooks/`、`templates/`）+ **adapters**（`adapters/<name>/`，派生镜像）
- 需要运行 `scripts/sync.sh` 或手动 symlink 才能在本机生效
- Cursor 与 Claude 的 Skill 路径不同，短期可能双份维护；长期可用 sync 脚本统一
- 新增非 Claude Code 工具时（如 Codex）只需建 `adapters/<name>/` 子目录，不动 `playbook/`、`skills/`

## 备选方案

- **仅 User Rules**：无法版本化、无法按技术栈 globs
- **每个项目 copy 一份**： drift 严重
- **直接方案 C template repo**：新建项目频率尚不足以 justify
