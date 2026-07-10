# 双机并存与渐进式迁移设计方案 (VPS Migration & Decoupling Strategy)

> 本文档用于指导如何将生产环境服务从旧服务器（如 `124.222.98.227`）渐进式迁移至新服务器（或 K8s/K3s 集群），并在迁移过渡期实现双机并存、零停机割接。该方案同时考虑了系统（v1 架构与 v2 架构）的**可迁移性**提升。

---

## 1. 核心设计原则

- **数据单一源 (Data Consistency)**：双机并存期间，禁止产生数据割裂（Split-Brain）。主数据库（PostgreSQL）在过渡期保持单一实例，新实例通过网络远程访问主库。
- **渐进式分流 (Canary Routing)**：通过网关（`xiaolin-gateway`）的 upstream 权重控制，实现 10% -> 50% -> 100% 的渐进式流量切换。
- **流水线无损部署 (Decoupled CD)**：GitHub Actions 部署任务应支持向多个主机并发部署，或通过参数化选择目标部署主机。
- **运行期无状态 (Stateless Runtime)**：降低部署对宿主机 Git 环境的依赖，将拉代码、编译等过程完全上移至 CI 端，宿主机只运行容器。

---

## 2. 详细设计与步骤

### 步骤 1：数据共享与安全控制 (Database)

在过渡期内，不迁移数据库本体，只迁移应用层（API）。

1. **数据库网络开放**：
   - 登录旧服务器（`124.222.98.227`），修改 PostgreSQL 的 `pg_hba.conf`，允许新服务器的公网/内网 IP 访问 PostgreSQL 端口（`5432`）。
   - 在旧服务器的云厂商安全组中，**精细化开放** `5432` 端口，**仅限新服务器 IP 访问**，拒绝任何其他外部 IP，确保数据库安全。
2. **配置新实例数据库 URL**：
   - 在新服务器部署 `ai-todo-api` 时，将其环境变量 `AI_TODO_DATABASE_URL` 或 `POSTGRES_HOST` 指向旧服务器的公网 IP `124.222.98.227`。

### 步骤 2：网关流量切换设计 (xiaolin-gateway)

在 `xiaolin-gateway` 项目的 `app/ai-todo/ai-todo.conf` 中，利用 Nginx upstream 进行平滑分流：

```nginx
upstream ai-todo-api {
    # weight 控制分流权重，从旧库 100% 逐步降为 0
    server 124.222.98.227:8082 weight=10; # 旧服务器
    server <新服务器公网IP>:8082 weight=1;   # 新服务器 (接收约 9% 的灰度流量)
}
```

**灰度割接步骤**：

1. **测试验证**：新实例上线后，绑定临时测试域名或直接在网关节点进行探活测试，确保新实例健康检查 `/healthz` 响应正常。
2. **小比例分流 (10:1)**：提交网关变更，让新实例接收约 9% 的流量，监控两端日志及业务接口报错率。
3. **均等分流 (1:1)**：权重调为 1:1，流量对半分。
4. **全量切流 (0:1)**：将旧服务器移除或设为 `down`，所有流量进入新服务器。

---

## 3. 可迁移性改造 (GitHub Actions CD 解耦)

为了让应用更容易被迁移到任意新服务器上（无论是 v1 的 `docker-compose` 还是 v2 的 `K3s`），我们需要解决当前 CD 强耦合单机 IP 的问题。

### 改造 A：GitHub Environments (L2) 级环境拆分

目前 GitHub 只有一个 `production` 环境变量。在迁移期，为了支持对不同服务器独立发布，可在 GitHub 上新增环境：

- `production-vps1` (旧服务器 `124.222.98.227`)
- `production-vps2` (新服务器)

在 GitHub Actions 触发部署时，允许选择目标 Environment，从而完美隔离部署凭据。

### 改造 B：解耦宿主机 Git 依赖（宿主机无状态化）

**当前痛点**：
当前的 `cd.yml` 通过 SSH 登录 VPS 后，在目标主机上执行 `git fetch && git pull`，这要求新服务器上必须手动克隆仓库、配置 Git 凭证、创建特定的目录。这极大地降低了“可迁移性”。

**目标设计（无状态部署）**：

1. **镜像推送 (CI)**：GitHub Actions 编译完 Docker 镜像后，统一推送到 GitHub Container Registry (GHCR)。
2. **拉取与启动 (CD)**：GitHub Actions 不再在 VPS 上跑 `git pull`。
   - CD 脚本只用 scp 把仓库中的 `docker-compose.prod.yml` 拷贝到新服务器的指定目录。
   - 直接执行 `docker compose -f docker-compose.prod.yml pull` 和 `docker compose up -d`。
   - 所有的运行时环境变量（L3）全部通过 GitHub L2 Variables / Secrets 动态生成为 `.env` 文件写入到目标主机。
3. **收益**：新服务器只需要安装有 Docker，Actions 就可以一键完成全部部署，免去了任何手动的机器初始化和 Git 权限配置。

---

## 4. 终极割接与数据库迁移

当 API 100% 切换到新服务器后，我们需要选择一个业务低谷时间段，将数据库物理迁移到新服务器或 K8s 集群中：

1. **服务降级（只读模式）**：
   - 开启 API 的只读限制，或临时将域名指向维护页，防止迁移期间产生新数据。
2. **数据备份 (Backup)**：
   - 在旧服务器上备份 PostgreSQL 数据：

     ```bash
     pg_dump -U ai_todo -d ai_todo -h 127.0.0.1 -F c -b -v -f ai_todo_prod.backup
     ```

3. **数据恢复与网络倒换 (Restore & Cutover)**：
   - 将备份文件拷贝到新服务器并恢复：

     ```bash
     pg_restore -U ai_todo -d ai_todo -h 127.0.0.1 -v ai_todo_prod.backup
     ```

   - 修改新服务器上 API 的数据库连接环境变量，指向本地（或 K8s 集群内）的 PostgreSQL。
   - 彻底关闭旧服务器的数据库网络端口和容器运行。

---

## 5. 迁移矩阵对照表

| 维度           | v1 (docker-compose) 下的迁移方案                        | v2 (K3s/K8s) 下的迁移方案                                                |
| :------------- | :------------------------------------------------------ | :----------------------------------------------------------------------- |
| **应用层复制** | 在新 VPS 上建立 compose 目录，启动 API 容器。           | 在新 K3s 集群中应用 Kustomize 声明（Deployment）。                       |
| **数据库共享** | 远程修改 `pg_hba.conf`，跨 VPS 进行网络连接。           | K8s Pod 跨集群边界直接通过 Service/Endpoint 指向旧 VPS IP。              |
| **域名割接**   | 修改网关的 `upstream` 权重。                            | 修改网关的 `upstream` 权重指向新集群的 Ingress IP。                      |
| **最终割接**   | 停止写操作 -> 导出 SQL -> 新机导入 -> 修改本地 `.env`。 | 停止写操作 -> 导出 SQL -> K8s 内导入 -> 修改 ConfigMap/Secret 重启 Pod。 |
