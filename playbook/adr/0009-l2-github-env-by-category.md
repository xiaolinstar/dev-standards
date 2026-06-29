---
ID: 0009
Title: L2 GitHub 配置按项目类别分层（双轨键名）
Status: Accepted
Date: 2026-06-28
Deciders: xingxiaolin
---

## 背景

xiaolinstar 旗下项目在 GitHub Actions L2（CD 用 Secrets / Variables）上存在三类不一致：

1. **作用域**：内容站 / 平台用**仓库级** Secrets（`SERVER_*`）；应用 API 用 **GitHub Environment**（`DEPLOY_*`）。
2. **键名与数量**：各仓 `github-*.env` 模板、文档、`github-sync-profiles.json` 字段不对齐。
3. **通知**：xiaolin-docs CD 仍配置 QQ 邮件 Secrets，而 workflow 失败时 GitHub 已向仓库/watch 用户推送通知，邮件重复且增加密钥面。

需要在**不强制改写全部 workflow** 的前提下，建立可审计的标准，供 `dev-bootstrap` 与未来项目对照。

## 决策

### 1. 按 category 采用双轨 L2（维持现状键名，文档统一）

| category | 项目 | `l2_scope` | 键名前缀 | Environment 名 |
|----------|------|------------|----------|----------------|
| **platform** | xiaolin-gateway | `repository` | `SERVER_*` | 无（CD 不挂 `environment:`） |
| **content** | xiaolin-docs、xiaolin-life | `repository` | `SERVER_*` | 无 |
| **application** | ai-todo、party-helper、drink-budget | `environment` | `DEPLOY_*` | `production`；ai-todo 另有 `staging` |

**不**在本 ADR 阶段将 `SERVER_*` 批量重命名为 `DEPLOY_*`，也不强制内容站迁入 GitHub Environment。新仓默认：

- 仅 SSH + 镜像拉取 + compose → **content / platform 轨**
- 需要 staging Environment、manifest 部署、公网 smoke URL → **application 轨**

### 2. 各类别标准键清单（L0 文档 + 本地 `github-*.env` 真源）

#### A. platform / content（仓库级）

| 类型 | 键 | 必填 |
|------|-----|------|
| Secret | `SERVER_HOST` | ✅ |
| Secret | `SERVER_USER` | ✅ |
| Secret | `SERVER_PASSWORD` 或 SSH key* | ✅ 二选一 |

\* 若改用 SSH key，Secret 名 `SERVER_SSH_KEY`（待 workflow 支持时再实现；当前 workflow 仅 `SERVER_PASSWORD`）。

**content · xiaolin-docs 额外 Variables（仅 docs）：**

| 类型 | 键 | 必填 |
|------|-----|------|
| Variable | `DOCKER_BAIDU_ANALYTICS_ID` | 可选 |
| Variable | `PAGES_BAIDU_ANALYTICS_ID` | 可选 |

**content · 不再使用邮件 Secrets（见 §3）。**

#### B. application（Environment `production` / `staging`）

| 类型 | 键 | 必填 |
|------|-----|------|
| Variable | `DEPLOY_HOST` | ✅ |
| Variable | `DEPLOY_USER` | ✅ |
| Variable | `DEPLOY_PORT` | 可选（默认 22） |
| Variable | `DEPLOY_PATH` | 可选 |
| Variable | `GHCR_DEPLOY_USER` | 可选 |
| Secret | `DEPLOY_SSH_KEY` 或 `DEPLOY_PASSWORD` | ✅ 二选一 |
| Secret | `GHCR_DEPLOY_TOKEN` | 可选 |

**按项目可选扩展（不得省略上表核心键）：**

| 项目 | 额外 Variable | 额外 Secret |
|------|---------------|-------------|
| ai-todo | `CD_PUBLIC_API_URL` | `CD_SMOKE_PAT`；monitor 可选 `ALERT_*` |
| drink-budget | `CD_PUBLIC_SERVER_URL` | — |
| party-helper | —（公网 URL 有 workflow 默认） | — |

### 3. 内容站 CD 邮件：废弃

- **决策**：内容站 CD **不再**要求配置 `MAIL_USERNAME` / `MAIL_PASSWORD`。
- **理由**：GitHub Actions 失败/成功通知已发往绑定账户；额外 SMTP 增加密钥维护与失败面。
- **文档**：从 L2 模板、`env-registry`、`github-sync-profiles` 移除邮件键。
- **实现**：xiaolin-docs `cd-ghcr.yml` / `ci-ghcr.yml` 已移除 `action-send-mail` 与 `MAIL_*` 引用

### 4. 集中治理工件

| 工件 | 用途 |
|------|------|
| [env-registry.yaml](../env-registry.yaml) | 每项目 `l2_category`、`l2_scope`、键名列表 |
| [env-management.md](../env-management.md) §L2 按类别 | 人类可读 + gh 示例 |
| [scripts/env/github-sync-profiles.json](../../scripts/env/github-sync-profiles.json) | `sync.sh env sync-github` 机器 profile |
| 各仓 `docs/env/github-*.env` | L0 本地清单模板（顶部注释 category） |

审计新项目时：对照上表 + registry 条目；偏离须新建 ADR 或在缺口段说明。

### 5. 审计 checklist（dev-bootstrap / 人工）

- [ ] `env-registry.yaml` 存在该项目，`l2_category` 与 category 一致
- [ ] 存在 `docs/env/github-environments.example.env` 或等效 L0 清单
- [ ] 本地模板键名 ⊆ registry 声明；无未文档化的 Secrets
- [ ] application 仓：GitHub 上存在 `production` Environment；ai-todo 另有 `staging`
- [ ] content/platform 仓：**未**误把 CD 密钥放进 Environment（除非 ADR 偏离）
- [ ] content 仓：**无** `MAIL_*` L2 配置
- [ ] L3 业务密钥（DB、JWT、ADMIN_TOKEN）**不在** L2

## 后果

- 更新 `env-management.md`、`env-registry.yaml`、`github-sync-profiles.json` 与各仓 L0 模板
- `dev-bootstrap` 已引用本 ADR checklist 做 L2 段审计
- xiaolin-docs workflow 已删 CI/CD 邮件 job（2026-06-28）
- 未来若统一为 Environment + `DEPLOY_*`，须新 ADR  supersede 本决策 §1 双轨约定

## 参考

- [env-management.md](../env-management.md)
- [ci-minimum-gate.md](../ci-minimum-gate.md) §环境密钥
- [ADR-0003](0003-12-factor-adaptation.md) Config 分层
