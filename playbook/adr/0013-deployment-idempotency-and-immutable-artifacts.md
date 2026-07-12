---
ID: 0013
Title: 部署幂等性与不可变产物规范
Status: Accepted
Date: 2026-07-12
Deciders: xingxiaolin
---

## 背景

当前 `dev-standards` 对 12-Factor App 和 CNCF TAG App Delivery 的落地中，明确暂缓了“自动化 CD 与 GitOps”等高级特性（见 [ADR-0004](0004-cncf-tag-app-delivery-adoption.md)）。
但在手动部署或 CI/CD 演进的过渡阶段，常常会依赖 Shell 脚本来完成部署动作（如下载代码、替换配置、重启进程）。
命令式的 Shell 脚本天生缺乏幂等性，存在“执行一半失败导致环境污染”的严重风险，这与云原生的核心理念背道而驰。

为弥补在未全面采用 Kubernetes/GitOps 之前的部署规范真空，特立此 ADR 以明确过渡期的**产物标准**与**部署方式**。

## 决策

### 1. 不可变基础设施（Immutable Infrastructure）的基线要求

- **构建（Build）与运行（Run）严格隔离**：严禁在生产环境服务器上执行源码编译（如 `npm run build`）或大规模依赖下载（如 `pip install`）。
- **交付物不可变**：CI 阶段必须输出最终可运行的不可变产物（默认要求为 **Docker Image**）。部署过程应当仅仅是“分发产物”和“替换容器进程”。

### 2. 部署操作的幂等性（Idempotency）

任何用于环境准备、代码更新、服务启停的部署脚本或指令，**必须是幂等**的：

- **禁用**：状态不明的就地修改操作（如 `sed -i` 覆写配置、增量 `cp` 覆盖）。
- **首选**：使用 Docker / Docker Compose。对于绝大部分部署，应被简化为 `docker compose pull && docker compose up -d`（该命令原生支持幂等及防中断）。
- **次选**：若必须修改宿主机级配置，推荐使用 Ansible 等声明式配置管理工具。
- **例外（Shell）**：极简场景下若不可避免要编写 Shell 部署脚本，必须：
  - 强制开启严格模式 `set -euo pipefail`。
  - 在执行任何破坏性操作前进行状态检查判断。

### 3. 健康检查与明确的止损回滚策略（Rollback）

在单版本直发（无 Progressive Delivery）的现状下：

- 部署动作完成后，必须包含自动化的可用性/健康检查手段（如针对容器的 Healthcheck，或简单的 `/health` 探针 curl 脚本）。
- 如果健康检查在限定时间内未通过，必须有明确的回滚指令或机制（例如使用前一个 Docker 镜像 tag 执行 `docker compose up -d` 回滚），严禁将“半死不活”的受损状态遗留在生产环境排查。

## 后果

- 在过渡期间（全面迁移到声明式 Kubernetes 前），所有的手动部署文档或自动化脚本必须遵循上述三条原则。
- [playbook/principles.md](../principles.md) 及相关基线映射（`12-factor.md` 的 Build, Release, Run 部分）后续按需据此补充更细节的执行约束。
