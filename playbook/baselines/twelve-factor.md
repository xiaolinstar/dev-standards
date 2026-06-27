---
baseline: 12-Factor App
upstream: https://12factor.net/
upstream-version: "1.0 (原始版本，长期稳定)"
status: adapted
deviation-count: 4
last-reviewed: 2026-06-24
---

# 12-Factor App

> 本文件为 12-Factor 在本仓的“采用 / 落地 / 缺口”映射。
> **所有偏离必须显式链到 ADR**，且总体立场由 [ADR-0003](../adr/0003-12-factor-adaptation.md) 决定。

## I. Codebase

**采用**：One codebase tracked in revision control, many deploys.

**落地**：默认单包（[principles.md §8](../principles.md)）；≥2 个可运行产物时升 monorepo（[monorepo.md](../monorepo.md)）。

**缺口 / ADR**：无。

## II. Dependencies

**采用**：Explicitly declare and isolate dependencies.

**落地**：显式依赖声明（pyproject.toml / package.json）+
锁文件（uv.lock / pnpm-lock.yaml）；详见 [monorepo.md](../monorepo.md) 包边界规则。

**缺口 / ADR**：无。

## III. Config

**采用**：Store config in the environment.

**落地**：[principles.md §5](../principles.md) 已定义；`.env.example` 文档化变量名（已落实）。

**缺口 / ADR**：无。

## IV. Backing Services

**采用**：Treat backing services as attached resources.

**落地**：DB / cache / queue URL 走环境变量。
**允许**本地 SQLite 与生产 Postgres 并存（schema 相同前提下）；见 [ADR-0003](../adr/0003-12-factor-adaptation.md)。

**缺口 / ADR**：

- “schema 相同”在多 DB 引擎下的强校验 → 待 Phase 2 加 CI 检查。

## V. Build, Release, Run

**采用**：Strict separation between build, release, and run stages.

**落地**：build = 锁文件 + 镜像构建；
release = tag + 环境配置注入；
run = 进程启动。
详见 [ADR-0003](../adr/0003-12-factor-adaptation.md)；
CI 最低门槛见 [ci-minimum-gate.md](../ci-minimum-gate.md)。

**缺口 / ADR**：[ADR-0006](../adr/0006-ci-minimum-gate.md) 决定 CI 必选项。

## VI. Processes

**采用**：Execute the app as one or more stateless processes.

**落地**：进程不持有 session 状态；session 走外部 store。

**缺口 / ADR**：无。

## VII. Port Binding

**采用**：Export services via port binding.

**落地**：FastAPI / Node HTTP server 自包含，
不依赖外部 web 容器（[monorepo.md](../monorepo.md) Python 应用部分）。

**缺口 / ADR**：无。

## VIII. Concurrency

**采用**：Scale out via the process model.

**落地**：[ADR-0003](../adr/0003-12-factor-adaptation.md) 标“**不适用**”；
遇多 worker 场景再启用（gunicorn -w N / PM2）。

**缺口 / ADR**：[ADR-0003](../adr/0003-12-factor-adaptation.md)。

## IX. Disposability

**采用**：Maximize robustness with fast startup and graceful shutdown.

**落地**：<3s 启动目标；kill -9 兼容是底线；优雅关停**建议**非强制（[ADR-0003](../adr/0003-12-factor-adaptation.md)）。

**缺口 / ADR**：[ADR-0003](../adr/0003-12-factor-adaptation.md)。

## X. Dev/Prod Parity

**采用**：Keep development, staging, and production as similar as possible.

**落地**：DB 类型差异**允许**（本地 SQLite、生产 Postgres），schema 必须一致；"dev/prod schema 不同"禁止（[ADR-0003](../adr/0003-12-factor-adaptation.md)）。

**缺口 / ADR**：

- “schema 一致”的强校验（alembic / prisma migrate）→ 待 Phase 2 加 CI 步骤。

## XI. Logs

**采用**：Treat logs as event streams.

**落地**：stdout + 文件双写；
traceId 必填（见 [api-error-codes.md](../api-error-codes.md)）；
集中采集由 Phase 2 hooks 处理。

**缺口 / ADR**：

- 集中采集 / ELK 接入 → Phase 2。

## XII. Admin Processes

**采用**：Run admin/management tasks as one-off processes.

**落地**：`python -m app.admin` 或 `pnpm admin`；不嵌进 web 进程。

**缺口 / ADR**：无。