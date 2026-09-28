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

项目仓库中的部署声明必须统一组织为 Base 和 Overlays 架构。对于包含数据库、定时任务等复杂组件的项目，
推荐采用**多组件分层目录**结构（drinkzen 已验证）：

```text
deploy/k8s/
├── infrastructure/             # 共用基础设施（Namespace、StorageClass）
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   └── storage-class.yaml
├── apps/                       # 应用层（API、Admin 等）
│   ├── base/                   # 与环境无关的骨架配置
│   │   ├── api-deployment.yaml
│   │   ├── api-service.yaml
│   │   ├── admin-deployment.yaml
│   │   ├── admin-service.yaml
│   │   └── kustomization.yaml
│   └── overlays/               # 环境特化配置
│       ├── local/              # 本地调试覆盖（NodePort、dummy 变量）
│       │   ├── kustomization.yaml
│       │   ├── .env.local.config      # 真实配置（gitignored）
│       │   ├── .env.local.secrets     # 真实密钥（gitignored）
│       │   ├── env-config.example     # 示例文件（提交到 Git）
│       │   └── env-secrets.example
│       └── production/         # 生产部署覆盖（镜像仓库、真实配置）
│           ├── kustomization.yaml
│           └── env-*.example
├── postgres/                   # 数据库层（StatefulSet、备份 CronJob）
│   ├── base/
│   │   ├── statefulset.yaml
│   │   ├── service.yaml
│   │   ├── backup-cronjob.yaml
│   │   └── kustomization.yaml
│   └── overlays/
│       ├── local/
│       └── production/
├── jobs/                       # 独立任务（数据库迁移等）
│   └── migrate/
│       ├── local/
│       │   ├── kustomization.yaml
│       │   └── job.yaml
│       └── production/         # 使用 $patch: delete 隔离任务
│           ├── kustomization.yaml
│           └── job.yaml
├── bootstrap/                  # 顶层组合入口（完整初始化）
│   └── local/
│       ├── kustomization.yaml  # 组合 infrastructure + apps + postgres + jobs
│       └── .env.backup-cos     # 备份专用密钥（gitignored）
└── archive/                    # 历史归档（不再使用但保留可渲染）
    └── README.md
```

**关键约定**：

- **单文件单资源**：禁止使用单个庞大的 YAML 文件并通过 `---` 拼接所有 Kubernetes 资源。
  每个独立的资源（如 Deployment、Service、Ingress、PVC 等）必须拥有独立的 YAML 文件，
  并在 `kustomization.yaml` 的 `resources` 列表中进行声明。这能保障配置的细粒度追踪，
  并便于 Kustomize 在 overlays 层进行精准的补丁（Patches）替换。
- **真实 env 文件 gitignored**：`.env.*.config` 和 `.env.*.secrets` 不提交到 Git，
  只提交对应的 `.example` 文件（值使用 `replace-with-*` 占位符）。
- **bootstrap 入口**：对于需要完整初始化的场景（如本地首次部署），提供 `bootstrap/<env>/` 作为顶层组合入口，
  一次性应用所有组件。日常增量部署直接 apply 各组件的 overlay。
- **archive 归档**：历史遗留的 Kustomize 入口移入 `archive/`，保持可渲染但不用于日常部署。

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

### 4. 数据库迁移门禁 (Migration Gate Pattern)

当应用启动依赖数据库 schema 一致性时，使用 **init container 作为只读门禁**，而非在主容器中执行迁移：

```yaml
# api-deployment.yaml
initContainers:
  # 只读门禁：schema 变更由独立的 migration Job 负责
  - name: wait-for-migration
    image: ghcr.io/xiaolinstar/drinkzen-api:latest
    command: [python, -m, app.schema] # 检查 schema 版本是否匹配
    envFrom:
      - configMapRef:
          name: drinkzen-api-config
      - secretRef:
          name: drinkzen-api-secrets
    resources:
      requests:
        cpu: 10m
        memory: 64Mi
      limits:
        cpu: 100m
        memory: 128Mi
containers:
  - name: api
    # ... 主容器定义
```

**原则**：

- **职责分离**：数据库迁移由独立的 `jobs/migrate/` Job 负责，API 启动时只做只读校验。
- **版本匹配**：门禁检查 schema 版本是否与当前代码匹配，不匹配则阻止启动，避免运行时错误。
- **独立部署**：迁移 Job 可单独 apply，不触发应用工作负载的滚动升级。

### 5. 部署策略 (Deployment Strategy)

- **单副本应用**：使用 `strategy.type: Recreate`，避免滚动升级期间出现新旧版本并存（对数据库迁移不友好）。
- **多副本无状态服务**：使用默认的 `RollingUpdate`，配合 `readinessProbe` 实现零中断发布。

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

## 六、 服务暴露与网关策略 (Service Exposure & Gateway Patterns)

### 1. 本地免 Ingress 依赖，直连 Service NodePort

- **规范**：对于不需要外部 Ingress Controller 复杂重定向规则的本地多项目服务调试，**严禁在本地 K8s base 中强行引入 Ingress 声明**。
- **访问地址约定**：只替换主机名，不隐藏端口号。
  - API：`http://api.<project>.localhost:<nodeport>`
  - 运营后台：`http://admin.<project>.localhost:<nodeport>`
- **最佳实践**：
  - 在本地覆盖层（如 `overlays/local/`）中，使用 Kustomize **JSON Patch** 将服务类型修改为 `NodePort`，
    直接通过固定节点端口暴露服务。
  - 项目文档中的默认本地入口必须优先写 `.localhost` 语义域名，但端口保持 NodePort，
    例如 `http://api.drinkzen.localhost:31011`。
  - 不为了隐藏端口号而额外引入本地 Nginx/gateway 反向代理；只有项目本身已存在网关或确有多路由分流需求时，
    才允许显式说明后使用。

**JSON Patch 示例**（Service 端口覆盖必须用 JSON Patch，strategic merge 会追加而非覆盖）：

```yaml
# overlays/local/kustomization.yaml
patches:
  - target:
      kind: Service
      name: drinkzen-api
    patch: |-
      - op: replace
        path: /spec/type
        value: NodePort
      - op: replace
        path: /spec/ports
        value:
          - name: http
            port: 8000
            targetPort: http
            nodePort: 31011
```

### 2. 生产 NodePort + 外部网关模式

对于单节点 K3s 部署或已有外部网关（如 `xiaolin-gateway`）的场景，推荐使用 **NodePort + 外部 Nginx 网关**
替代 K8s Ingress：

**架构**：

```text
外部网关 (xiaolin-gateway)
  ↓ HTTPS 终止 + 域名路由
K8s NodePort (31011/31012)
  ↓
Pod (API/Admin)
```

**优势**：

- **统一管理**：所有项目（K8s 和非 K8s）的路由规则集中在外部网关，避免 K8s Ingress 与 Nginx 配置并存。
- **HTTPS 终止**：外部网关统一处理 SSL 证书，K8s 内部无需管理证书 Secret。
- **迁移友好**：从 docker-compose 迁移到 K8s 时，外部网关配置无需改动，只需将 upstream 从 `localhost:port`
  改为 `node-ip:nodeport`。

**CI 校验**：

```bash
# 生产 overlay 禁止 LoadBalancer，只允许固定数量的 NodePort
! grep -q "type: LoadBalancer" rendered-production.yaml
test "$(grep -c "type: NodePort" rendered-production.yaml)" -eq 2
grep -q "nodePort: 31011" rendered-production.yaml
grep -q "nodePort: 31012" rendered-production.yaml
```

### 3. 精确挂载规避 Nginx 配置加载冲突

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

## 七、 基础设施与运维模式 (Infrastructure & Operations Patterns)

### 1. StorageClass 与持久卷保留策略

对于使用 local-path provisioner（K3s 默认 / Docker Desktop）的集群，定义 **Retain 策略的 StorageClass**
防止数据意外删除：

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: drinkzen-local-retain
provisioner: rancher.io/local-path # K3s/Docker Desktop 本地存储
reclaimPolicy: Retain # PVC 删除后 PV 保留，防止数据丢失
volumeBindingMode: WaitForFirstConsumer
```

**StatefulSet PVC 保留策略**：

```yaml
spec:
  persistentVolumeClaimRetentionPolicy:
    whenDeleted: Retain # StatefulSet 删除时保留 PVC
    whenScaled: Retain # 缩容时保留 PVC
```

### 2. 镜像仓库镜像策略 (Registry Mirror)

对于部署在中国大陆的生产环境，使用大学镜像站代理 GHCR/Docker Hub 以规避网络问题：

```yaml
# overlays/production/kustomization.yaml
images:
  - name: ghcr.io/xiaolinstar/drinkzen-api
    newName: ghcr.nju.edu.cn/xiaolinstar/drinkzen-api # 南大镜像
    newTag: latest # CD 流水线动态替换为 sha-<commit>
```

**CD 镜像固定**：CD 流水线在部署时动态 patch `kustomization.yaml`，将 `latest` 替换为精确的 `sha-<commit>`，
确保部署的不可变性。部署单个服务时，先从集群读取另一个服务的当前镜像，避免覆盖。

### 3. 数据库备份 CronJob

生产数据库应配置定时备份 CronJob，遵循以下最佳实践：

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: drinkzen-postgres-backup
spec:
  schedule: "30 3 1 * *" # 每月 1 日 03:30
  timeZone: Asia/Shanghai
  suspend: true # 默认暂停，手动验收后再启用
  concurrencyPolicy: Forbid # 禁止并发执行
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 3
  jobTemplate:
    spec:
      backoffLimit: 1
      activeDeadlineSeconds: 1800 # 30 分钟超时
      template:
        spec:
          securityContext:
            runAsUser: 70 # 以 postgres 用户运行
            runAsGroup: 70
          containers:
            - name: backup
              resources:
                requests:
                  cpu: 25m
                  memory: 256Mi
                limits:
                  cpu: "1"
                  memory: 1Gi
              volumeMounts:
                - name: temporary
                  mountPath: /tmp # 临时 dump 目录
          volumes:
            - name: temporary
              emptyDir:
                sizeLimit: 20Gi # 限制临时空间
```

**原则**：

- **默认暂停**：首次部署后手动执行一次备份并验证恢复流程，确认无误后再设置 `suspend: false`。
- **独立存储**：备份使用独立的 COS/S3 bucket，与应用文件存储分离。
- **非 root 运行**：备份容器以数据库用户（如 postgres UID 70）运行，最小化权限。
- **资源限制**：备份 Job 可能消耗大量 CPU/内存，必须定义 resources limits。

### 4. Job 隔离与 $patch: delete

当需要单独部署某个 Job（如数据库迁移）而不触发应用工作负载时，使用 Kustomize 的 `$patch: delete` 指令
删除不需要的资源：

```yaml
# jobs/migrate/production/kustomization.yaml
resources:
  - ../../../apps/overlays/production # 引用应用 overlay 获取 ConfigMap/Secret
  - job.yaml # 迁移 Job

patches:
  - target:
      kind: Deployment
    patch: |-
      $patch: delete
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: unused
  - target:
      kind: Service
    patch: |-
      $patch: delete
      apiVersion: v1
      kind: Service
      metadata:
        name: unused
```

**效果**：渲染结果只包含 Job 和它依赖的 ConfigMap/Secret，不包含 Deployment、Service 等工作负载。
这样可以确保迁移 Job 使用与应用相同的环境配置，但不会触发应用滚动升级。

---

## 八、 基础设施即代码 (IaC) 的 CI 门禁

由于 Kubernetes 声明式资源（YAML）本质上也是代码（Infrastructure as Code），它们必须像源码一样受到严格的 CI（Continuous Integration）校验。严禁未经自动校验的配置合入主干。

### 1. 强制的 Kustomize 渲染检查

- **规范**：在代码仓库中必须配置专属的 `k8s-ci.yml`（或在主 CI 中隔离 Job），在 Pull Request 及 Push 阶段使用 `kubectl kustomize` 尝试渲染所有环境和资源变体。
- **目的**：拦截因缩进错误、拼写错误（如 `imagePulPolicy`）、或 base/overlay 层级引用断裂导致的致命语法错误。如果渲染失败，绝对不允许合入代码。
- **安全隔离**：CI 校验脚本必须使用 `.example` 占位文件替代真实 `.env` 文件，在临时目录中渲染，绝不读取真实密钥。

### 2. 结构不变量断言 (Structural Assertions)

除了渲染成功，CI 还必须验证渲染结果的**结构不变量**，防止架构漂移：

```bash
#!/usr/bin/env sh
# scripts/ci/validate-k8s.sh 示例

# 1. 生产环境禁止 LoadBalancer，只允许固定数量的 NodePort
if grep -q "type: LoadBalancer" rendered-production.yaml; then
  echo "Production overlay must not expose LoadBalancer Services." >&2
  exit 1
fi
test "$(grep -c "type: NodePort" rendered-production.yaml)" -eq 2

# 2. 无状态 API 服务禁止挂载 PVC
if grep -q 'persistentVolumeClaim:' rendered-api.yaml; then
  echo "Stateless API must not mount a PVC." >&2
  exit 1
fi

# 3. 迁移入口只渲染 Job，不包含工作负载
if grep -Eq '^kind: (Deployment|Service|StatefulSet|Namespace)$' rendered-migrate.yaml; then
  echo "Migration entry must only render its Job and API configuration." >&2
  exit 1
fi

# 4. Bootstrap 入口只创建一个 Namespace
test "$(grep -c '^kind: Namespace$' rendered-bootstrap.yaml)" -eq 1

# 5. 迁移门禁 init container 必须存在
grep -q 'name: wait-for-migration' rendered-api.yaml

# 6. 就绪探针必须区分健康检查端点
grep -q 'path: /readyz' rendered-api.yaml
```

**常见不变量**：

| 不变量                        | 目的                          |
| ----------------------------- | ----------------------------- |
| 生产无 LoadBalancer           | 强制使用 NodePort + 外部网关  |
| NodePort 数量固定             | 防止意外暴露额外服务          |
| API 无 PVC                    | 确保应用无状态，可水平扩展    |
| 迁移入口无 Deployment/Service | 确保迁移 Job 独立部署         |
| Bootstrap 单 Namespace        | 防止重复创建命名空间          |
| 迁移门禁存在                  | 确保 API 启动前 schema 已就绪 |
| readinessProbe 使用 /readyz   | 区分存活检查和就绪检查        |

### 3. 进阶 Schema 及安全合规检查（可选推荐）

- 推荐使用 `kubeval` 或 `kubeconform` 在 CI 流程中检查渲染后的资源是否符合目标版本 Kubernetes 的 OpenAPI Schema 规范，防止使用已废弃的 API 字段。
- 推荐使用 `checkov` 或 `trivy` 扫描特权容器逃逸、过大权限暴露（如未经限制的 Root 用户运行）等云原生安全漏洞。

**底线原则**：把错误拦在 CI 大门外，绝不能让配置错误渗透至线上引发 CD（kubectl apply）中断或部分资源处于悬挂的错误状态。
