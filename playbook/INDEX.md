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
- [环境变量与密钥治理](env-management.md)（L0–L3、L2 IaC 目录 `github/<env>/{variables,secrets}.env`；[ADR-0012](adr/0012-config-github-l2-only.md)）
- [环境变量迁移 Runbook](env-migration-runbook.md)（进度：[env-migration-status.yaml](env-migration-status.yaml) · `sync.sh env status`）
- [双机并存与渐进式迁移设计方案](vps-migration-strategy.md)（解决平滑迁移、可迁移性解耦及网关权重分流）
- [Kubernetes 声明式资源编写规范与最佳实践](kubernetes.md)
- [Phase 3 应用层清单](env-phase3-checklist.md)
- [微信小程序项目标准（原生 + TypeScript）](wechat-mp.md)
- [H5 项目通用开发规范（移动端 vw 适配、UI 交互、WebView 兼容）](h5.md)
- [Web 项目统一规范（PC 优先自适应 + Vant 4 + Tailwind + Design Tokens）](web.md)
- [H5 运营管理后台项目标准（继承 Web 基线，运营后台特有规则）](h5-admin.md)

## 项目审计（差距 → 标准迭代）

- [audits/ — 项目审计报告归档](audits/README.md)
  - [2026-07 drink-budget/apps/admin](audits/2026-07-drink-budget-admin.md)
  - [2026-07 party-helper/apps/admin](audits/2026-07-party-helper-admin.md)
  - [2026-07 Admin 迁移路线图](audits/2026-07-admin-migration-roadmap.md)
  - [2026-07 ai-todo 核心项目](audits/2026-07-ai-todo.md)
  - [2026-07 drink-budget 核心项目](audits/2026-07-drink-budget-repo.md)
  - [2026-07 party-helper 核心项目](audits/2026-07-party-helper-repo.md)

## 实现片段（可复制参考）

- [traceId middleware（FastAPI / Express）](snippets/trace-id-middleware.md)
- [结构化日志（JSON 行 + traceId）](snippets/structured-logging.md)

## 外部基线（行业对位）

- [baselines/ 目录说明](baselines/README.md)
- [CNCF TAG App Delivery 映射](baselines/cncf-tag-app-delivery.md)
- [12-Factor 映射](baselines/twelve-factor.md)

## ADR（Architecture / Standard Decision Records）

仲裁顺序：principles ↔ baselines 冲突时，**ADR 优先**。详见 `baselines/README.md` §与本仓其他文件的关系。

| ID                                                              | 标题                                                           | 状态     |
| --------------------------------------------------------------- | -------------------------------------------------------------- | -------- |
| [0001](adr/0001-standards-repo-structure.md)                    | 标准库仓库结构与 Claude Code 对齐                              | Accepted |
| [0002](adr/0002-monorepo-default-selection.md)                  | Monorepo / 单包默认选型                                        | Accepted |
| [0003](adr/0003-12-factor-adaptation.md)                        | 12-Factor 适配：solo dev 简化                                  | Accepted |
| [0004](adr/0004-cncf-tag-app-delivery-adoption.md)              | CNCF TAG App Delivery 采用范围                                 | Accepted |
| [0005](adr/0005-api-error-code-convention.md)                   | API 错误码与 HTTP 状态约定                                     | Accepted |
| [0006](adr/0006-ci-minimum-gate.md)                             | CI 最低门槛                                                    | Accepted |
| [0007](adr/0007-wechat-miniprogram-baseline.md)                 | 微信小程序项目标准（原生 + TypeScript）                        | Accepted |
| [0008](adr/0008-templates-wechat-mp-scaffold.md)                | 激活 templates/wechat-mp 脚手架（Phase 3）                     | Accepted |
| [0009](adr/0009-l2-github-env-by-category.md)                   | L2 GitHub 配置按项目类别分层（双轨键名）                       | Accepted |
| [0010](adr/0010-h5-project-baseline.md)                         | H5 项目通用标准与技术选型                                      | Accepted |
| [0011](adr/0011-web-admin-baseline.md)                          | Web 后台基线（PC 优先自适应 + Vant 4 + Tailwind + 品牌色变量） | Accepted |
| [0012](adr/0012-devops-v1-archive-and-k8s-migration-roadmap.md) | DevOps v1 归档与云原生 K8s (K3s + Kustomize) 演进路线图        | Accepted |
