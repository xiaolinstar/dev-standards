# drinkzen 核心仓库审计报告

> **审计日期**：2026-09-27
> **审计依据**：[kubernetes.md](../kubernetes.md)、[ci-minimum-gate.md](../ci-minimum-gate.md)、[env-management.md](../env-management.md)
> **结论摘要**：drinkzen 是 K8s 治理的**标杆项目**，其部署架构已完全符合并超越了 `kubernetes.md` 规范要求，
> 多项创新模式（多组件分层目录、迁移门禁、Job 隔离、NodePort + 外部网关）已被反馈纳入标准库。

---

## 执行摘要

**完全合格**。drinkzen 项目不仅完全遵循了 `kubernetes.md` 的所有规范要求，还在实际落地过程中探索出了
多项最佳实践模式，这些模式已被采纳并更新到标准库中，成为后续项目的参考范本。

---

## 合规评分卡

### 1. 命名与标签规范

- [✅] **资源命名**：所有资源使用 `kebab-case`（`drinkzen-api`、`drinkzen-postgres`）。
- [✅] **Namespace 无后缀**：统一使用 `drinkzen`，不追加 `-local` 或 `-production`。
- [✅] **标准标签**：全部核心资源使用 `app.kubernetes.io/*` 标签体系，包含 `name`、`instance`、`part-of`、
  `component`、`managed-by` 五个标准字段。

### 2. 文件与目录结构

- [✅] **单文件单资源**：每个 Deployment、Service、StatefulSet 独立文件，无 `---` 多文档拼接。
- [✅] **多组件分层目录**：采用 `infrastructure/` + `apps/` + `postgres/` + `jobs/` + `bootstrap/` + `archive/`
  分层结构，职责清晰，组合灵活。
- [✅] **真实 env gitignored**：`.env.*.config` 和 `.env.*.secrets` 不提交，只提交 `.example` 占位文件。

### 3. 配置与密钥治理

- [✅] **无明文密钥**：所有敏感信息通过 `secretGenerator` 从 `.env.*.secrets` 文件加载，base 层不包含任何密钥。
- [✅] **哈希后缀启用**：未禁用 `disableNameSuffixHash`，ConfigMap/Secret 变更自动触发滚动升级。
- [✅] **配置变更滚动**：`configMapGenerator` 和 `secretGenerator` 生成带哈希后缀的资源名称。

### 4. 容器运行规范

- [✅] **资源限额**：所有容器（API、Admin、Postgres、Backup、Migration）均定义了 `resources.requests` 和
  `resources.limits`。
- [✅] **三探针齐全**：API 使用 HTTP `/healthz` 和 `/readyz`，Postgres 使用 `pg_isready` exec 探针，
  全部配置了 `startupProbe`、`livenessProbe`、`readinessProbe`。
- [✅] **Entrypoint 保留**：未覆盖 Dockerfile 的 `command`，自定义参数通过 `args` 传递。
- [✅] **迁移门禁**：API Deployment 使用 `wait-for-migration` init container 作为只读 schema 校验门禁。

### 5. 服务暴露与网关

- [✅] **NodePort + 外部网关**：生产环境使用 NodePort（31011/31012）+ `xiaolin-gateway` 外部 Nginx 网关，
  未使用 K8s Ingress。
- [✅] **JSON Patch 覆盖**：Service 端口覆盖使用 JSON Patch（非 strategic merge），避免端口追加问题。
- [✅] **本地直连**：本地开发通过 `http://api.drinkzen.localhost:31011` 直连 NodePort，无需额外代理。

### 6. 基础设施与运维

- [✅] **StorageClass Retain**：定义 `drinkzen-local-retain` StorageClass，`reclaimPolicy: Retain`。
- [✅] **PVC 保留策略**：StatefulSet 配置 `persistentVolumeClaimRetentionPolicy: whenDeleted: Retain, whenScaled: Retain`。
- [✅] **镜像仓库镜像**：生产使用南大镜像 `ghcr.nju.edu.cn`，CD 动态 patch 为 `sha-<commit>`。
- [✅] **备份 CronJob**：月度备份，默认 `suspend: true`，`concurrencyPolicy: Forbid`，以 postgres 用户运行。
- [✅] **Job 隔离**：`jobs/migrate/production/` 使用 `$patch: delete` 删除 Deployment/Service，只渲染 Job。

### 7. CI/CD 流水线

- [✅] **Kustomize 渲染检查**：`scripts/ci/validate-k8s.sh` 在临时目录中使用 `.example` 文件渲染所有 overlay。
- [✅] **结构不变量断言**：CI 脚本验证 NodePort 数量、禁止 LoadBalancer、禁止 API PVC、迁移入口无工作负载等。
- [✅] **密钥隔离**：CI 脚本从不读取真实 `.env` 文件，只使用 `.example` 占位值。
- [✅] **CD 镜像固定**：CD 流水线动态 patch `kustomization.yaml` 将 `latest` 替换为 `sha-<commit>`。
- [✅] **CD 镜像保护**：部署单个服务时，先从集群读取另一个服务的当前镜像，避免覆盖。

---

## 标杆模式（已反馈到标准库）

drinkzen 项目探索出的以下模式已被纳入 `kubernetes.md` 规范，成为后续项目的参考：

### 1. 多组件分层目录结构

**模式**：将 K8s 资源按职责分层为 `infrastructure/`、`apps/`、`postgres/`、`jobs/`、`bootstrap/`、`archive/`，
而非简单的 `base/` + `overlays/`。

**优势**：

- 数据库、备份、迁移等组件可独立部署和升级，不触发应用滚动。
- `bootstrap/` 提供完整初始化入口，`archive/` 保留历史可渲染配置。
- 职责清晰，便于团队协作和权限控制。

### 2. 迁移门禁模式 (Migration Gate)

**模式**：API Deployment 使用 `wait-for-migration` init container 作为只读 schema 校验门禁，
数据库变更由独立的 `jobs/migrate/` Job 负责。

**优势**：

- 职责分离：迁移 Job 可单独 apply，不触发应用滚动升级。
- 版本匹配：门禁检查 schema 版本是否与当前代码匹配，不匹配则阻止启动。
- 安全可靠：避免主容器在启动时执行迁移导致的竞态条件。

### 3. Job 隔离与 $patch: delete

**模式**：使用 Kustomize 的 `$patch: delete` 指令从应用 overlay 中删除 Deployment/Service，
只保留 Job 和它依赖的 ConfigMap/Secret。

**优势**：

- 迁移 Job 使用与应用相同的环境配置，但不会触发应用工作负载。
- 避免重复定义 ConfigMap/Secret，保持单一数据源。

### 4. NodePort + 外部网关

**模式**：生产环境使用 NodePort + 外部 Nginx 网关（`xiaolin-gateway`）替代 K8s Ingress。

**优势**：

- 统一管理：所有项目（K8s 和非 K8s）的路由规则集中在外部网关。
- HTTPS 终止：外部网关统一处理 SSL 证书，K8s 内部无需管理证书 Secret。
- 迁移友好：从 docker-compose 迁移到 K8s 时，外部网关配置无需改动。

### 5. CI 结构不变量断言

**模式**：CI 脚本不仅验证 Kustomize 渲染成功，还断言渲染结果的结构不变量（如 NodePort 数量、禁止 LoadBalancer、
禁止 API PVC 等）。

**优势**：

- 防止架构漂移：确保生产环境不会意外暴露 LoadBalancer 或挂载 PVC。
- 自动化合规：无需人工审查即可保证关键架构约束。

---

## 标准库待反馈（无）

drinkzen 项目的所有创新模式已被采纳并更新到 `kubernetes.md`，无待反馈项。

---

## 下一步

drinkzen 已成为 K8s 治理的标杆项目，建议：

1. **其他项目参考**：`ai-todo`、`party-helper` 等项目在 K8s 迁移时应参考 drinkzen 的多组件分层目录结构。
2. **审计对照**：后续项目的 K8s 审计应以 drinkzen 为标杆，检查是否存在偏离。
3. **持续迭代**：随着更多项目落地 K8s，新的最佳实践应继续反馈到 `kubernetes.md`。
