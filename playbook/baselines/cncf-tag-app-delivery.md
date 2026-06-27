---
baseline: CNCF TAG App Delivery
upstream: https://github.com/cncf/toc/blob/main/tags/app-delivery.md
upstream-version: "current (无版本号，跟踪 toc 仓库 main 分支)"
status: adapted
deviation-count: 1
last-reviewed: 2026-06-24
---

# CNCF TAG App Delivery

> 本文件为 CNCF TAG App Delivery 在本仓的“采用 / 落地 / 缺口”映射。
> 总体立场由 [ADR-0004](../adr/0004-cncf-tag-app-delivery-adoption.md) 决定。
>
> 与 [12-Factor XI. Logs](twelve-factor.md) 重叠时，observability 段以本文件为准，logs 段以 12-Factor 为准。

## CI/CD

**采用**：任何合入主干的代码必须经过自动化 build/test 流水线；流水线产物可复现。

**落地**：[ci-minimum-gate.md](../ci-minimum-gate.md) 定义最低门槛，包含：

- lint
- typecheck-or-test
- secret scan

等价物表允许不同工具栈。

**缺口 / ADR**：[ADR-0006](../adr/0006-ci-minimum-gate.md)。

## Continuous Delivery

**采用**：流水线产出的 artifact 可一键部署到任意环境；部署自动化、可审计。

**落地**：当前**无**自动 CD；走 `git tag vX.Y.Z` + 手动触发部署
（[monorepo.md](../monorepo.md) §版本与发布）。

**缺口 / ADR**：

- 自动 CD 流水线 → 出现第 2 个生产项目时启动（[ADR-0004](../adr/0004-cncf-tag-app-delivery-adoption.md)）。

## GitOps

**采用**：环境配置以 Git 为唯一真相；环境差异 = Git 仓库差异。

**落地**：当前**无**；配置走环境变量 + `.env.example`
（[principles.md §5](../principles.md)），不引入 Argo CD / Flux。

**缺口 / ADR**：[ADR-0004](../adr/0004-cncf-tag-app-delivery-adoption.md) 决定不采用。

## Progressive Delivery

**采用**：新版本以受控方式（金丝雀 / 蓝绿 / 特性开关）逐步放量。

**落地**：当前**无**；单版本直发。

**缺口 / ADR**：[ADR-0004](../adr/0004-cncf-tag-app-delivery-adoption.md) 决定不采用；
触发条件 = 出现第 2 个线上用户项目。

## Observability

**采用**：应用行为可被外部系统观测（metrics / logs / traces）。

**落地**：结构化日志（JSON 行）+ traceId 必填（[api-error-codes.md](../api-error-codes.md)）；
指标与链路追踪集中化推到 Phase 2。

**缺口 / ADR**：

- metrics / tracing 集中化（Prometheus / OpenTelemetry）→ Phase 2。
