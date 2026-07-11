# Kubernetes 声明式资源编写规范与最佳实践

本规范规定了 `xiaolinstar` 旗下所有向 Kubernetes (K3s/Docker-Desktop K8s) 演进的云原生应用的声明式资源（YAML）编写标准，以确保配置安全、高可用性、自愈性及无损滚动升级能力。

---

## 一、 命名与标签规范 (Naming & Labels)

### 1. 资源命名标准

- **统一格式**：所有资源的 `metadata.name` 一律使用小写字母、数字及中划线（`kebab-case`），禁止使用下划线或驼峰命名法。
  - _正确_：`ai-todo-api`、`postgres-pvc`、`api-service`
  - _错误_：`ai_todo_api`、`postgresPVC`
- **后缀一致性**：除核心应用资源外，辅助/关联资源命名应当带上清晰的类型后缀：
  - ConfigMap: `[app-name]-config`
  - Secret: `[app-name]-secrets`
  - PersistentVolumeClaim: `[app-name]-pvc`
  - Ingress: `[app-name]-ingress`

### 2. 命名空间 (Namespace) 规范

- **环境无后缀原则**：不要在 `Namespace` 的名称上追加环境后缀（如 `-local`、`-production`）。跨环境的同名项目应保持相同的 `Namespace` 名称（例如统一使用 `ai-todo`）。
- **环境隔离**：不同环境的隔离应当依靠目标部署集群自身（如 Local K3s 与 Production K8s 分离），或通过规范中的 `app.kubernetes.io/instance` 标签进行逻辑区分。

### 3. 元数据标签 (Labels) 标准

应用层核心资源（Deployment、Service、Ingress、StatefulSet）必须包含 Kubernetes 官方推荐 of 系统标签
（`app.kubernetes.io/*`），严禁使用团队自定义的简写标签（如 `app: todo`）。标准标签定义如下：

```yaml
metadata:
  labels:
    app.kubernetes.io/name: ai-todo-api # 应用的英文名称
    app.kubernetes.io/instance: ai-todo-api-prod # 部署的具体实例名（区分环境）
    app.kubernetes.io/part-of: ai-todo # 所属的系统/大项目名称
    app.kubernetes.io/component: backend # 组件角色 (backend / frontend / db)
    app.kubernetes.io/managed-by: kustomize # 配置管理工具
```

---

## 二、 文件划分与目录规范 (File & Directory Structure)

### 1. 单文件单资源原则 (Single Responsibility)

- **规范**：禁止使用单个庞大的 YAML 文件并通过 `---` 拼接所有 Kubernetes 资源。
- 每个独立的资源（如 Deployment、Service、Ingress、PVC 等）必须拥有独立的 YAML 文件，并在 `kustomization.yaml` 的 `resources` 列表中进行声明。
- _原因_：这能保障配置的细粒度追踪，并便于 Kustomize 在 overlays 层进行精准的补丁（Patches）替换。

### 2. Kustomize 多环境结构

项目仓库中的部署声明必须统一组织为 Base 和 Overlays 架构：

```text
deploy/k8s/
├── base/                     # 与环境无关的骨架配置
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── kustomization.yaml
└── overlays/                 # 环境特化配置
    ├── local/                # 本地调试覆盖（IfNotPresent, dummy 变量）
    │   └── kustomization.yaml
    └── production/           # 生产部署覆盖（配置真实证书、多 Replicas）
        └── kustomization.yaml
```

---

## 三、 配置与密钥治理 (Config & Secrets)

### 1. 严禁敏感明文提交

- **规范**：任何明文密钥（如 API Token、数据库密码、微信小程序 Secret 等）严禁写在 `base/` 或任何提交到 Git 仓库的普通 YAML 声明中。
- **最佳实践**：
  - 在 `overlays/local/` 中，可以使用明文 Dummy 值：

    ```yaml
    # overlays/local/kustomization.yaml
    secretGenerator:
      - name: ai-todo-secrets
        literals:
          - POSTGRES_PASSWORD=local_postgres_password_123
    ```

  - 在 `overlays/production/` 中，必须通过挂载被忽略的安全密钥描述文件（如 `.env.production.secrets`）或在 CD 期间利用流水线变量生成 Secret。

### 2. 配置变更滚动升级 (Versioned Configurations)

- 使用 `configMapGenerator` 和 `secretGenerator` 生成配置时，Kustomize 会自动根据其文件内容计算
  **MD5/SHA 哈希并追加为后缀**（例如 `ai-todo-config-88744dt5k6`）。配置更改会导致哈希变化，
  从而迫使 Deployment 升级模板，自动触发优雅的滚动升级。

---

## 四、 容器运行规范 (Container Specs & Security)

### 1. 资源边界限制 (Resources Limits & Requests)

为了避免内存泄漏导致宿主机瘫痪，或者 CPU 资源抢占造成关键网关卡死，**所有的 Deployment 容器必须显示定义资源配额**：

```yaml
resources:
  requests:
    memory: "64Mi" # 容器启动所需最少内存
    cpu: "50m" # 容器启动所需最少 CPU (0.05核)
  limits:
    memory: "256Mi" # 容器最大可用内存（超限会触发 OOMKilled 重启）
    cpu: "500m" # 容器最大可用 CPU (0.5核)
```

### 2. 健康检查探针声明 (Probes)

高可用的容器应用必须同时声明以下三类探针，以支持故障自动恢复与零中断部署：

- **Startup Probe (启动探针)**：在容器刚刚启动时进行探活（如 API 启动进行 alembic 迁移时）。只要启动探针没有通过，K8s 就不会判定容器失败，也不会触发其他探针。
- **Liveness Probe (存活探针)**：周期性检测容器是否仍处于活跃状态。如果探针失败，K8s 会立即**杀死并重启该 Pod** 实现故障自愈。
- **Readiness Probe (就绪探针)**：周期性检测服务是否已具备服务能力（如数据库已接通）。若就绪检测失败，Ingress 会**立刻停止向该 Pod 分发请求流量**，直至重新就绪，避免用户看到 502/504 错误。

示例模板：

```yaml
startupProbe:
  httpGet:
    path: /v1/health
    port: 3100
  failureThreshold: 30
  periodSeconds: 2
livenessProbe:
  httpGet:
    path: /v1/health
    port: 3100
  periodSeconds: 10
readinessProbe:
  httpGet:
    path: /v1/health
    port: 3100
  periodSeconds: 5
```

### 3. Entrypoint 入口保留

- 在 Deployment 的容器定义中，**除非调试需要，否则不要覆盖 `command` 属性**。
- 覆盖 `command` 会跳过 Dockerfile 原生的 `ENTRYPOINT`，导致脚本内的依赖探活、变量预拼接和初始化流程失效。
- _标准规范_：如有需要，应将自定义命令写在 `args` 中传给原生的 entrypoint 脚本执行。

---

## 五、 兼容性与向前预防

### 1. 消除已废弃 API 版本警告

- 当新版 Kubernetes 出现 API 版本淘汰（如 v1 Endpoints 废弃提示）时，应及时查阅官方迁移指南更新声明。
- Ingress 资源在 Kubernetes 1.19 之后必须统一采用正式的 `networking.k8s.io/v1`，禁用旧版的 `extensions/v1beta1` 等废弃版本。

### 2. Ingress 强制匹配 IngressClass

- 在集群内部多 Ingress 控制器共存（如 Traefik + Nginx）的环境下，必须显式定义 Ingress Class：

  ```yaml
  spec:
    ingressClassName: nginx # 显式声明关联的 IngressClass
  ```

---

## 六、 本地网关与 K8s 服务混合调试规范 (Local Gateway & K8s Port-Forwarding Strategy)

在单机本地开发环境下，当网关（Docker Compose）与被测试业务（Kubernetes 部署）混合共存时，必须遵循以下网络与文件系统挂载规划以避免端口和配置加载冲突：

### 1. 本地免 Ingress 依赖，直连 Service LoadBalancer

- **规范**：对于不需要外部 Ingress Controller 复杂重定向规则的本地多项目服务调试，**严禁在本地 K8s base 中强行引入 Ingress 声明**。
- **最佳实践**：
  - 在本地覆盖层（如 `overlays/local/`）中，使用 Kustomize Patch 将后端 API 的 Service 类型修改为 `LoadBalancer`，
    直接将端口暴露到宿主机（例如 `:8082`）。
  - 在本地网关配置文件中，直接将 upstream 指向 `host.docker.internal:8082`，
    绕过 Ingress 代理，实现网关与 K8s Pod 之间最轻量、最稳定的直连通道。

### 2. 精确挂载规避 Nginx 配置加载冲突

- **冲突背景**：由于本地网关配置了 `include /etc/nginx/app/*/*.conf;` 通配符规则，
  若在 Docker Compose 中把包含生产配置（`*.conf`）和本地配置（`*.local.conf`）的宿主机大目录整体挂载进容器，
  会导致 Nginx 同时加载两份冲突的 server/upstream 定义，导致启动崩溃。
- **最佳实践**：在本地 `docker-compose.local.yml` 的 `volumes` 覆盖声明中，**严禁整体挂载 `app/` 目录**。必须采用“单文件精确映射覆盖”的形式，仅挂载本地专属配置文件覆盖容器内对应的生产配置文件：

  ```yaml
  volumes:
    - ./app/gateway.conf:/etc/nginx/conf.d/default.conf:ro
    # 精确挂载覆盖生产配置，容器内不存在 local 物理文件，从根本上避开通配符多重扫描冲突
    - ./app/ai-todo/ai-todo.local.overlay:/etc/nginx/app/ai-todo/ai-todo.conf:ro
  ```

---

## 七、 基础设施即代码 (IaC) 的 CI 门禁

由于 Kubernetes 声明式资源（YAML）本质上也是代码（Infrastructure as Code），它们必须像源码一样受到严格的 CI（Continuous Integration）校验。严禁未经自动校验的配置合入主干。

### 1. 强制的 Kustomize 渲染检查

- **规范**：在代码仓库中必须配置专属的 `k8s-ci.yml`（或在主 CI 中隔离 Job），在 Pull Request 及 Push 阶段使用 `kubectl kustomize` 尝试渲染所有环境和资源变体。
- **目的**：拦截因缩进错误、拼写错误（如 `imagePulPolicy`）、或 base/overlay 层级引用断裂导致的致命语法错误。如果渲染失败，绝对不允许合入代码。

### 2. 进阶 Schema 及安全合规检查（可选推荐）

- 推荐使用 `kubeval` 或 `kubeconform` 在 CI 流程中检查渲染后的资源是否符合目标版本 Kubernetes 的 OpenAPI Schema 规范，防止使用已废弃的 API 字段。
- 推荐使用 `checkov` 或 `trivy` 扫描特权容器逃逸、过大权限暴露（如未经限制的 Root 用户运行）等云原生安全漏洞。

**底线原则**：把错误拦在 CI 大门外，绝不能让配置错误渗透至线上引发 CD（kubectl apply）中断或部分资源处于悬挂的错误状态。
