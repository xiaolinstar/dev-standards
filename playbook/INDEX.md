# Playbook 索引

## 原则

- [L1 开发原则](principles.md)
- [Monorepo 实践指南](monorepo.md)

## 主题（跨项目技术约定）

- [API 错误码与 HTTP 状态约定](api-error-codes.md)

## ADR（Architecture / Standard Decision Records）

| ID | 标题 | 状态 |
|----|------|------|
| [0001](adr/0001-standards-repo-structure.md) | 标准库仓库结构与 Claude Code 对齐 | 已接受 |
| [0002](adr/0002-monorepo-default-selection.md) | Monorepo / 单包默认选型 | 已接受 |

## Skills（一等公民，源码在 `../skills/`）

| Skill | 用途 |
|-------|------|
| dev-bootstrap | 新建或整理项目时的检查清单 |

## Hooks（一等公民，源码在 `../hooks/`）

PreToolUse 守卫模板（如提交前确认）。按项目部署，非全局强制。

## Adapters（派生镜像，源码在 `../adapters/`）

| Adapter | 用途 | 部署目标 |
|---------|------|----------|
| [cursor](../adapters/cursor/) | Cursor Rules（派生自 principles.md / monorepo.md） | `<project>/.cursor/rules/` |

## Templates（方案 C 预留，源码在 `../templates/`）

未来用于项目脚手架，当前为空。
