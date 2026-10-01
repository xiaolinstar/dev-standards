# 数据库管理与备份方案

本规范规定了 `xiaolinstar` 旗下项目的数据库选型、备份策略、恢复流程及运维操作标准。
适用于所有使用 PostgreSQL（生产）/ SQLite（本地降级）的项目。

---

## 一、数据库选型与存储分层

### 1. 生产环境：PostgreSQL in-cluster

- **部署方式**：Kubernetes StatefulSet + PVC，不使用云托管数据库（降低复杂度与成本）。
- **版本**：PostgreSQL 16-alpine。
- **连接抽象**：使用 `DATABASE_URL` 环境变量，支持 PostgreSQL 和 SQLite 两种 URL 格式，
  应用层通过 ORM 或驱动自动适配。

### 2. 本地开发：SQLite 或 PostgreSQL 均可

- **SQLite 模式**：零依赖，适合快速原型和离线开发。数据库文件存放在项目根目录（gitignored）。
- **PostgreSQL 模式**：与生产一致，适合需要验证 PostgreSQL 特有功能的场景。
  通过 K8s StatefulSet 或 Docker Compose 运行。

### 3. 存储分层原则

| 数据类型               | 存储位置                          | 说明                |
| ---------------------- | --------------------------------- | ------------------- |
| 结构化业务数据         | PostgreSQL / SQLite               | 用户、订单、配置等  |
| 静态资源（图片、文件） | 对象存储（COS/S3）或本地磁盘      | 数据库只存 key/路径 |
| 数据库备份             | 对象存储（优先）或本地 `.backup/` | 见第二节            |

---

## 二、备份策略

### 1. 备份方式

使用 `pg_dump` 逻辑备份，生成压缩的 `.dump` 文件：

```bash
pg_dump --format=custom --no-owner --no-acl \
  -h <host> -U <user> -d <database> \
  -f <backup-file>.dump
```

**备份内容**：表结构、行数据、序列、索引、约束、迁移版本。

**不备份的内容**：集群角色、密码、Kubernetes Secrets、配置文件、对象存储文件。
这些需要单独管理。

### 2. 备份产物

每次成功备份生成 3 个文件：

| 文件                             | 用途                                           |
| -------------------------------- | ---------------------------------------------- |
| `<timestamp>.dump`               | 压缩归档文件                                   |
| `<timestamp>.dump.sha256`        | SHA-256 校验和                                 |
| `<timestamp>.dump.verified.json` | 完成标记（含恢复验证结果、迁移版本、行数统计） |

### 3. 备份目标：对象存储（优先）

生产环境推荐使用对象存储（腾讯云 COS / AWS S3 / 阿里云 OSS）：

```bash
# 备份并上传到 COS
pg_dump ... | coscmd upload - <remote-path>/<timestamp>.dump
sha256sum <timestamp>.dump > <timestamp>.dump.sha256
coscmd upload <timestamp>.dump.sha256 <remote-path>/
```

**环境变量**：

```env
BACKUP_COS_BUCKET=drinkzen-production-1300240022
BACKUP_COS_REGION=ap-nanjing
BACKUP_COS_PREFIX=backups/production/
BACKUP_RETENTION_DAYS=180
```

### 4. 备份目标：本地降级（无对象存储时）

当对象存储未配置或本地开发时，备份到项目根目录的 `.backup/` 目录：

```bash
# .gitignore
.backup/
```

```bash
# 备份脚本
BACKUP_DIR=".backup/postgres"
mkdir -p "$BACKUP_DIR"
pg_dump --format=custom --no-owner --no-acl \
  -h localhost -U postgres -d drinkzen \
  -f "$BACKUP_DIR/$(date +%Y%m%d-%H%M%S).dump"
```

**本地降级特点**：

- 备份文件在 `.backup/` 下，已 gitignore，不提交到仓库。
- 适合单机开发和测试，不适合生产灾难恢复。
- 项目重建或换机器时备份丢失，需重新备份。

### 5. 备份调度

使用 Kubernetes CronJob 调度（详见 [kubernetes.md](kubernetes.md) §七.3）：

```yaml
spec:
  schedule: "30 3 1 * *" # 每月 1 日 03:30
  timeZone: Asia/Shanghai
  suspend: true # 默认暂停，手动验收后启用
  concurrencyPolicy: Forbid # 禁止并发
  backoffLimit: 1
  activeDeadlineSeconds: 1800 # 30 分钟超时
```

**关键原则**：

- **默认暂停**：新部署的 CronJob 必须 `suspend: true`，首次手动执行并验证恢复流程后再启用。
- **禁止并发**：`concurrencyPolicy: Forbid`，防止多个备份同时运行。
- **超时限制**：`activeDeadlineSeconds: 1800`，防止备份卡死。

### 6. 备份保留策略

```bash
# 清理超过 BACKUP_RETENTION_DAYS 的旧备份
find "$BACKUP_DIR" -name "*.dump" -mtime +${BACKUP_RETENTION_DAYS:-180} -delete
find "$BACKUP_DIR" -name "*.sha256" -mtime +${BACKUP_RETENTION_DAYS:-180} -delete
find "$BACKUP_DIR" -name "*.verified.json" -mtime +${BACKUP_RETENTION_DAYS:-180} -delete
```

---

## 三、恢复流程

### 1. 核心原则：永远不直接覆盖生产库

恢复操作必须遵循以下流程：

```text
下载备份 → 校验 SHA-256 → 创建新的空数据库 → pg_restore → 验证 → 切换连接
```

**禁止**：`pg_restore` 直接覆盖正在运行的生产数据库。

### 2. 恢复步骤

```bash
# 1. 下载备份文件（从对象存储或 .backup/）
coscmd download <remote-path>/<timestamp>.dump .
coscmd download <remote-path>/<timestamp>.dump.sha256 .
coscmd download <remote-path>/<timestamp>.dump.verified.json .

# 2. 校验 SHA-256
sha256sum -c <timestamp>.dump.sha256

# 3. 创建新的空数据库（不覆盖生产库）
createdb -h <host> -U <user> drinkzen_restore_<timestamp>

# 4. 恢复数据
pg_restore --exit-on-error --single-transaction \
  -h <host> -U <user> -d drinkzen_restore_<timestamp> \
  < <timestamp>.dump

# 5. 验证迁移版本和行数
psql -d drinkzen_restore_<timestamp> -c "SELECT version FROM schema_migrations;"
psql -d drinkzen_restore_<timestamp> -c "SELECT count(*) FROM products;"
# 与 verified.json 中的预期值对比

# 6. 切换 API 连接到新数据库（验证无误后）
# 更新 K8s Secret 中的 DATABASE_URL，指向新数据库
kubectl patch secret drinkzen-api-secrets \
  -p '{"data":{"DATABASE_URL":"<new-db-url>"}}' \
  -n <namespace>

# 7. 重启 API Pod 使配置生效
kubectl rollout restart deployment/<app>-api -n <namespace>

# 8. 清理旧数据库（确认新库运行正常后）
dropdb -h <host> -U <user> drinkzen_old
```

### 3. 本地恢复（开发环境）

```bash
# 从 .backup/ 恢复到本地 SQLite 或 PostgreSQL
BACKUP_FILE=$(ls -t .backup/postgres/*.dump | head -1)
createdb drinkzen_restore
pg_restore -d drinkzen_restore < "$BACKUP_FILE"

# 验证后切换本地 DATABASE_URL
export DATABASE_URL="postgresql://localhost:5432/drinkzen_restore"
```

---

## 四、数据库迁移

### 1. 迁移工具

使用项目内置的迁移工具（如 Alembic、Prisma Migrate、Knex Migrations）：

```bash
# 执行迁移
python -m app.cli migrate-db
# 或
npx prisma migrate deploy
```

### 2. 迁移模式：独立 Job + 门禁

迁移由独立的 Kubernetes Job 负责，API 启动时通过 init container 做只读校验：

```text
CD 部署 → 创建迁移 Job → Job 执行 schema 变更 → Job 完成
         → API Deployment 启动
           → init container: wait-for-migration（校验 schema 版本）
           → 主容器：API 启动（schema 已就绪）
```

**原则**：

- **职责分离**：迁移 Job 负责 schema 变更，API 只做只读校验。
- **版本匹配**：门禁检查 schema 版本是否与当前代码匹配，不匹配则阻止启动。
- **独立部署**：迁移 Job 可单独 apply，不触发应用滚动升级。

详见 [kubernetes.md](kubernetes.md) §四.4。

### 3. 迁移文件管理

- 迁移文件（如 `migrations/20260906_0028_add_products.py`）必须提交到 Git。
- 迁移一旦合并到 main，禁止修改或删除（保证幂等性）。
- 如需回滚，创建新的反向迁移（如 `20260907_0029_remove_products.py`）。

---

## 五、运维 Runbook

### 1. 启动顺序

K8s 集群重启后，按以下顺序启动服务：

```text
1. PostgreSQL StatefulSet（等待 pg_isready 通过）
2. 迁移 Job（等待完成）
3. API Deployment（等待 readinessProbe 通过）
4. Admin Deployment（等待 readinessProbe 通过）
5. 备份 CronJob（解除暂停，如已验收）
```

### 2. 手动备份

```bash
# K8s 环境：通过 kubectl exec 执行备份
kubectl exec -it <postgres-pod> -n <namespace> -- \
  pg_dump --format=custom --no-owner --no-acl \
  -U <user> -d <database> \
  > backup-$(date +%Y%m%d-%H%M%S).dump

# 本地环境：直接执行
pg_dump --format=custom --no-owner --no-acl \
  -h localhost -U postgres -d drinkzen \
  -f .backup/postgres/manual-$(date +%Y%m%d-%H%M%S).dump
```

### 3. 健康检查

```bash
# 检查 PostgreSQL 是否就绪
kubectl exec -it <postgres-pod> -n <namespace> -- pg_isready -U <user> -d <database>

# 检查最近一次备份是否成功
kubectl get jobs -n <namespace> | grep backup
kubectl logs job/<backup-job-name> -n <namespace>

# 检查备份健康（距上次成功备份 > 35 天则告警）
python -m app.cli backup-check --threshold-days 35
```

### 4. PVC 与数据保留

所有 PVC 使用 `Retain` 策略（详见 [kubernetes.md](kubernetes.md) §七.1）：

```yaml
spec:
  persistentVolumeClaimRetentionPolicy:
    whenDeleted: Retain # StatefulSet 删除时保留 PVC
    whenScaled: Retain # 缩容时保留 PVC
```

**注意**：删除 Namespace 不会保护 PVC 数据。节点磁盘损坏会导致数据丢失，
因此对象存储备份是生产环境的必要保障。

### 5. 回滚方案

**数据库回滚**：

1. 停止 API（scale to 0）。
2. 恢复旧备份到新数据库（见第三节）。
3. 切换 API 连接到旧数据库。
4. 重启 API。

**代码回滚**：

1. `kubectl rollout undo deployment/<app>-api`。
2. 等待滚动升级完成。
3. 验证健康检查。

---

## 六、安全与合规

### 1. 密钥管理

- 数据库密码通过 Kubernetes Secret 注入，不硬编码在代码或配置文件中。
- 备份脚本使用独立的 Secret（如 `drinkzen-postgres-backup-cos`），与应用 Secret 分离。
- 备份文件包含敏感数据，必须设置私有 ACL（对象存储）或文件权限（本地）。

### 2. 备份加密

- 对象存储启用服务端加密（如 COS SSE-COS AES256）。
- 本地备份文件权限设置为 `600`（仅所有者可读写）。

### 3. 审计日志

- 备份 Job 的日志保留在 Kubernetes 中（可通过 `kubectl logs` 查看）。
- 对象存储开启访问日志（可选）。

---

## 七、项目接入清单

新项目接入本规范时，需完成以下检查：

- [ ] `DATABASE_URL` 环境变量已定义，支持 PostgreSQL 和 SQLite 两种格式。
- [ ] 备份脚本已实现（支持对象存储和本地 `.backup/` 两种目标）。
- [ ] `.backup/` 已添加到 `.gitignore`。
- [ ] 备份 CronJob 已配置（`suspend: true`）。
- [ ] 恢复流程已在本地验证通过。
- [ ] 迁移工具已集成，迁移文件提交到 Git。
- [ ] API 启动门禁（wait-for-migration）已实现。
- [ ] PVC Retain 策略已配置。
