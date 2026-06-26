---
ID: 0003
Title: 12-Factor 适配：solo dev 简化
Status: Accepted
Date: 2026-06-24
Deciders: xingxiaolin
---

## 背景

12-Factor 是面向云原生 12 要素应用的方法论。在 solo dev 跨项目场景下，全部按字面执行会引入不必要的复杂度（多 deploy 流水线、严格 backing services 解耦、强无状态进程约束等）。

本 ADR 决定本仓对 12 条因子的"按字面 / 简化 / 不适用"立场。

## 决策

| Factor | 立场 | 理由 |
|---|---|---|
| I. Codebase | 按字面 | 一个 repo 一个应用是默认。monorepo 多 app 场景见 monorepo.md。 |
| II. Dependencies | 按字面 | 显式依赖声明（pyproject.toml / package.json）+ 锁文件。 |
| III. Config | 按字面 | 走环境变量，`.env.example` 文档化。 |
| IV. Backing Services | 简化 | 不强求"附加资源"解耦到 DB URL 字符串；本地 SQLite 与生产 Postgres 并存是允许的，但**必须**走环境变量切换。 |
| V. Build, Release, Run | 简化 | 必有 build 与 release；"run" 不强制严格分离（本地 `python -m` 直跑允许），但 release 产物必须可重放（lock 文件 + 镜像 tag）。 |
| VI. Processes | 按字面 | 无状态进程；session 用外部 store（Redis/DB）。 |
| VII. Port Binding | 按字面 | 自包含 HTTP server，不依赖外部 web 容器。 |
| VIII. Concurrency | 不适用 | solo dev 几乎不扩进程；遇到再启用（PM2 / gunicorn workers）。 |
| IX. Disposability | 简化 | 快速启动是底线（<3s 目标）；优雅关停**建议**但不强制——kill -9 兼容即可。 |
| X. Dev/Prod Parity | 简化 | "尽量相似"为原则；DB 类型差异允许（见 Factor IV），但**不**允许"dev 用 SQLite/prod 用 MySQL 但 schema 不同"。 |
| XI. Logs | 简化 | stdout + 文件双写；集中采集由 Phase 2 hooks 处理。**不**强制纯事件流。 |
| XII. Admin Processes | 按字面 | 一次性脚本走 `python -m app.admin` 或 `pnpm admin`，不嵌进 web 进程。 |

## 后果

- 本仓的 `playbook/baselines/twelve-factor.md` 据此落地。
- 任何后续偏离必须新增 ADR 链到本文件（这是 0004 / 0005 / 0006 的前导）。