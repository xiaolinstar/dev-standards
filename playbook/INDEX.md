# Playbook 索引

> 本目录是 `dev-standards` 文档的真源。ADR 是冲突仲裁的最高层。

## 原则（Agent / 流程层）

- [L1 开发原则](principles.md)
- [Monorepo 实践指南](monorepo.md)
- [Agent 配置最小维护（Claude + AGENTS）](agent-config.md)
- [循环审计与标准反馈](audit-feedback-loop.md)

## 主题（跨项目技术约定）

- [API 错误码与 HTTP 状态约定](api-error-codes.md)
- [CI 最低门槛](ci-minimum-gate.md)（含 Hooks/CI/CD 三阶段、Monorepo 布局、环境密钥分层）
- [环境变量与密钥治理](env-management.md)（L0–L3、`~/.config/xiaolinstar`、键名校验）
- [环境变量迁移 Runbook](env-migration-runbook.md)（进度：[env-migration-status.yaml](env-migration-status.yaml) · `sync.sh env status`）
- [微信小程序项目标准（原生 + TypeScript）](wechat-mp.md)

## 实现片段（可复制参考）

- [traceId middleware（FastAPI / Express）](snippets/trace-id-middleware.md)
- [结构化日志（JSON 行 + traceId）](snippets/structured-logging.md)

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
| [0007](adr/0007-wechat-miniprogram-baseline.md) | 微信小程序项目标准（原生 + TypeScript） | Accepted |
| [0008](adr/0008-templates-wechat-mp-scaffold.md) | 激活 templates/wechat-mp 脚手架（Phase 3） | Accepted |

## Skills（一等公民，源码在 `../skills/`）

| Skill | 用途 |
|-------|------|
| dev-bootstrap | 新建或整理项目时的检查清单 |
| agent-permissions | 跨 Agent check/deny 规则生命周期（manifest → sync） |
| wechat-mp | 原生 + TS 微信小程序开发模式与坑点 |

## Hooks（一等公民，源码在 `../hooks/`）

| 类型 | 部署命令 | 用途 |
|------|----------|------|
| Claude PreToolUse | `sync.sh hooks <project>` | `git-commit-guard.py` 等 |
| Husky pre-commit | `sync.sh hooks-precommit <project>` | lint-staged + gitleaks + commitlint |

## Adapters（派生镜像，源码在 `../adapters/`）

| Adapter | 用途 | 部署目标 |
|---------|------|----------|
| [cursor](../adapters/cursor/) | Cursor Rules（5 个 `.mdc`，派生自 playbook/） | `<project>/.cursor/rules/` |

## Templates（方案 C，源码在 `../templates/`）

| 模板 | 部署 |
|------|------|
| [wechat-mp](../templates/wechat-mp/) | `sync.sh template wechat-mp <dest>` |

## Plugin（Claude Code 打包）

| 文件 | 用途 |
|------|------|
| [.claude-plugin/plugin.json](../.claude-plugin/plugin.json) | Plugin 元数据 v3.0.0 |
| [marketplace.json](../marketplace.json) | 自托管 marketplace 入口 |
| [CHANGELOG.md](../CHANGELOG.md) | 版本变更记录 |
