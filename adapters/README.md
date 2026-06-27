# Adapters

> 兼容层：把 dev-standards 的内容镜像到**非 Claude Code** 的 Agent / IDE 体系。
> 一等公民仍是 `playbook/`、`skills/`、`hooks/`；本目录里的内容是这些源文件的派生/转写，不应反向成为真源。

## 概念

dev-standards 优先服务 Claude Code（Skills、hooks、CLAUDE.md）。
当某个项目的开发者主要使用其他 Agent（Cursor、Codex、Continue 等）时，
adapters 目录负责**一次性把标准转写成对方能消费的格式**，
并通过 `scripts/sync.sh adapters <name> <project>` 部署到目标项目。

原则：

- 派生而非独立 — adapter 内容是 `playbook/principles.md` 等真源的转写；改动 adapter 前先确认真源
- 平等并列 — 每个 adapter 互不依赖，新增时建子目录即可
- 不强求覆盖 — 真源中如有条款在目标 Agent 里没有等价机制（如 hooks vs Cursor 事件），不强写

## 当前 adapter

| Adapter | 目录 | 目标项目路径 | 部署命令 |
|---------|------|--------------|----------|
| Cursor | `adapters/cursor/` | `<project>/.cursor/rules/` | `./scripts/sync.sh adapters cursor <project>` |

### Cursor `.mdc` 文件（派生自 playbook/）

| 文件 | 真源 |
|------|------|
| `core-principles.mdc` | `playbook/principles.md` |
| `monorepo.mdc` | `playbook/monorepo.md` |
| `api-error-codes.mdc` | `playbook/api-error-codes.md` |
| `ci-minimum-gate.mdc` | `playbook/ci-minimum-gate.md` |
| `wechat-mp.mdc` | `playbook/wechat-mp.md` |

## 新增一个 adapter

以 `codex` 为例（占位，未实现）：

1. 建目录 `adapters/codex/`，按目标 Agent 的格式放配置文件或规则文件
2. 在 `scripts/sync.sh` 的 `cmd_adapters` 中确认部署目标路径（默认约定 `<project>/.codex/...`，可在函数内分支）
3. 在本 README 的「当前 adapter」表中加一行
4. 跑 `./scripts/sync.sh help` 自检命令可被发现

不需要改 `playbook/`、不需要新建 ADR——adapter 是部署细节，不是决策。
