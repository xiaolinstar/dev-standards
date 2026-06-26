---
ID: 0004
Title: CNCF TAG App Delivery 采用范围
Status: Accepted
Date: 2026-06-24
Deciders: xingxiaolin
---

## 背景

CNCF TAG App Delivery 包含 5 个子域：CI/CD、Continuous Delivery、GitOps、Progressive Delivery、Observability。在 solo dev 场景下全部深入投入不现实。

本 ADR 决定本仓对 5 个子域的"采用 / 观察 / 不采用"立场。

## 决策

| 子域 | 立场 | 理由 |
|---|---|---|
| CI/CD | 采用（浅） | lint + test + secret scan 必走（见 [ADR-0006](0006-ci-minimum-gate.md)）；多 runner / 复杂 pipeline 不引入。 |
| Continuous Delivery | 观察 | 当前无 CD 流水线；走手动 release tag + 镜像构建。出现第 2 个生产项目时再升"采用"。 |
| GitOps | 不采用 | solo dev 单环境运行；Argo CD / Flux 投入产出比不划算。 |
| Progressive Delivery | 不采用 | 无多版本路由需求（canary / blue-green）；出现第 2 个线上用户项目时再评估。 |
| Observability | 采用（浅） | 结构化日志 + traceId 是底线（[ADR-0005](0005-api-error-code-convention.md)）；metrics / tracing 集中化推到 Phase 2。 |

## 后果

- `playbook/baselines/cncf-tag-app-delivery.md` 据此落地。
- Continuous Delivery / GitOps / Progressive Delivery 三个子域若未来被采用，必须新开 ADR 链接到本文件。
- 前端/小程序目录约定（principles.md 待补项 2）不在本基线覆盖范围；显式延后到"出现第 2 个前端项目"时启动。