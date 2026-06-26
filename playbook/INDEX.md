# Playbook 索引

> 本目录是 `dev-standards` 文档的真源。ADR 是冲突仲裁的最高层。

## 原则（Agent / 流程层）

- [L1 开发原则](principles.md)
- [Monorepo 实践指南](monorepo.md)

## 主题（跨项目技术约定）

- [API 错误码与 HTTP 状态约定](api-error-codes.md)
- [CI 最低门槛](ci-minimum-gate.md)

## 外部基线（行业对位）

- [baselines/ 目录说明](baselines/README.md)
- [CNCF TAG App Delivery 映射](baselines/cncf-tag-app-delivery.md)
- [12-Factor 映射](baselines/twelve-factor.md)

## ADR（Architecture / Standard Decision Records）

仲裁顺序：principles ↔ baselines 冲突时，**ADR 优先**。详见 `baselines/README.md` §与本仓其他文件的关系。

| ID | 标题 | 状态 |
|----|------|------|
| [0001](adr/0001-standards-repo-structure.md) | 标准库仓库结构与 Claude Code 对齐 | Accepted |
| [0002](adr/0002-monorepo-default-selection.md) | Monorepo / 单包默认选型 | Accepted |
| [0003](adr/0003-12-factor-adaptation.md) | 12-Factor 适配：solo dev 简化 | Accepted |
| [0004](adr/0004-cncf-tag-app-delivery-adoption.md) | CNCF TAG App Delivery 采用范围 | Accepted |
| [0005](adr/0005-api-error-code-convention.md) | API 错误码与 HTTP 状态约定 | Accepted |
| [0006](adr/0006-ci-minimum-gate.md) | CI 最低门槛 | Accepted |

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