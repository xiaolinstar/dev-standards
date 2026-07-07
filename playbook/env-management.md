# 环境变量与密钥治理

> 跨项目 L0–L3 分层、`~/.config/xiaolinstar` **仅承载 GitHub L2 IaC**、运行时密钥**单一真源在 VPS**。
> 结构决策：[ADR-0012](adr/0012-config-github-l2-only.md)。键名索引：[env-registry.yaml](env-registry.yaml)。

## 四层模型（L0–L3）

```text
L0  仓库模板（可 commit）     *.env.example、docs/env/github/
L1  CI workflow              非敏感 env + GITHUB_TOKEN
L2  GitHub Environments      CD、SSH、探活 URL（Actions 运行时读）
L3  业务运行时               VPS .env.production / K8s Secret 文件（仅服务器）
```

| 层 | 放什么 | **真源** | 不放什么 |
|----|--------|----------|----------|
| L0 | 键名、默认端口 | 仓库 `docs/env/` | 密码、私钥 |
| L1 | `NODE_VERSION` | workflow | 生产 DSN |
| L2 | `DEPLOY_*`、探活 URL | **GitHub**（由本地 IaC 同步） | 微信 AppSecret、DB 密码 |
| L3 | DB、JWT、微信密钥 | **VPS / 本机 gitignore 文件** | 不应 commit；**不应**备份到 ~/.config |

### 单一受控源原则

- **L3**：只在目标机器维护一份（Compose `.env.production`、K8s overlay `.env.production.secrets`）。**不再** scp 到 `~/.config/xiaolinstar/<project>/production.env`。
- **L2**：本地 `variables.env` + `secrets.env` 是 **编写 IaC**；`sync-github` 推到 GitHub 后，**CD 只读 GitHub**。
- 避免「config 备份 + VPS 真源」双轨——后者是旧模型，已废弃（ADR-0012）。

## ~/.config/xiaolinstar（仅 GitHub L2）

```text
~/.config/xiaolinstar/<project>/github/
├── production/
│   ├── variables.env    # → gh variable set
│   └── secrets.env      # → gh secret set
├── staging/
│   ├── variables.env
│   └── secrets.env
└── production-k8s/
    ├── variables.env
    └── secrets.env
```

**仓库级 L2**（platform / content）：

```text
~/.config/xiaolinstar/<project>/github/variables.env
~/.config/xiaolinstar/<project>/github/secrets.env
```

L0 模板：`docs/env/github/<environment>/variables.env.example` 与 `secrets.env.example`。

### 命名对照（ai-todo）

| 名称 | 示例 | 含义 |
|------|------|------|
| GitHub Environment | `production-k8s` | CD：SSH 到 111、K8s 后端 |
| GitHub Environment | `production` | CD：SSH 到 124、Compose |
| K8s overlay | `overlays/production` | 产品档位 infra |
| 应用 ConfigMap | `AI_TODO_ENVIRONMENT=production` | API `/v1/health` 等 |

GitHub Environment 描述 **部署面**；应用 `production` 描述 **产品档位**——二者不必同名。

### 初始化

```bash
# 创建 github/ 目录树（不创建 production.env 等 L3 备份）
~/AgentProjects/dev-standards/scripts/sync.sh env init-config

# 从仓库 L0 模板复制到 ~/.config（人工填值）
~/AgentProjects/dev-standards/scripts/sync.sh env init-github-env \
  --project ai-todo --environment production

# 同步到 GitHub
~/AgentProjects/dev-standards/scripts/sync.sh env sync-github \
  --project ai-todo --environment production --dry-run
~/AgentProjects/dev-standards/scripts/sync.sh env sync-github \
  --project ai-todo --environment production-k8s --dry-run
```

### 废弃路径（只读兼容，勿再写入）

| 旧路径 | 替代 |
|--------|------|
| `<project>/github-production.env` | `github/production/{variables,secrets}.env` |
| `<project>/production.env`（L3 备份） | VPS `apps/api/.env.production` **唯一** |
| `env import-config` / `env apply-config` | 直接在 VPS 或本机改 runtime |

## 每仓运行时布局（L3）

| `runtime_layout` | 适用 | L3 路径 |
|------------------|------|---------|
| `root-dotenv` | gateway、内容站 | 仓库根 `.env` + `.env.production` |
| `app-scoped` | API monorepo | `apps/api/.env` + `.env.<env>` |

加载顺序：基础 `.env` → 环境覆盖（`.env.local` | `.env.staging` | `.env.production`）。

| 场景 | 配置来源 |
|------|----------|
| 本地开发 | L0 复制为 gitignore runtime |
| CI 测试 | job `env` 或假值 |
| CD | GitHub L2 SSH + VPS L3 |
| K8s | overlay `secretGenerator` + VPS 上 `.env.*.secrets` |

## GitHub Environments（L2）

> [ADR-0009](adr/0009-l2-github-env-by-category.md) · `scripts/env/github-sync-profiles.json`

| category | Environment | 键名前缀 |
|----------|-------------|----------|
| platform / content | 无（仓库级） | `SERVER_*` |
| application | `production`、`staging`；ai-todo 另有 **`production-k8s`** | `DEPLOY_*` |

### application 标准键

| 类型 | 键 |
|------|-----|
| Variable | `DEPLOY_HOST`、`DEPLOY_USER`、`DEPLOY_PORT`、`DEPLOY_PATH` |
| Secret | `DEPLOY_PASSWORD`（默认）或 `DEPLOY_SSH_KEY`（备选） |

**ai-todo L2 扩展**（所有 GitHub Environment **键名相同**，仅值因部署面而异）：`CD_PUBLIC_API_URL`、`CD_LOCAL_HEALTH_URL`（可选）、`DEPLOY_BACKEND`、`K8S_*`（`DEPLOY_BACKEND=k8s` 时生效）、`GHCR_*`、`CD_SMOKE_PAT`（可选）。

**不放 L2**：`POSTGRES_PASSWORD`、`AI_TODO_WECHAT_APP_SECRET` 等业务密钥——仅 L3。

### sync-github 示例

```bash
gh variable set DEPLOY_HOST --repo xiaolinstar/ai-todo --env production --body 124.222.98.227

~/AgentProjects/dev-standards/scripts/sync.sh env sync-github --project ai-todo --environment production
~/AgentProjects/dev-standards/scripts/sync.sh env sync-github --project ai-todo --environment production-k8s
~/AgentProjects/dev-standards/scripts/sync.sh env sync-github --project xiaolin-gateway
```

## 键名校验（check）

```bash
# 仓库 L0 *.example ↔ 本机 runtime（开发者）
~/AgentProjects/dev-standards/scripts/sync.sh env check --project ~/AgentProjects/ai-todo

# L0 github 模板 ↔ ~/.config L2 文件
~/AgentProjects/dev-standards/scripts/sync.sh env check \
  --project ~/AgentProjects/ai-todo --github --env production
```

**不再**使用 `--local production` 校验 `~/.config/.../production.env`。

## Agent 禁区

**禁止 Agent 修改：**

- gitignore 的 `*.env`、`.env.*`（非 `*.example`）
- `~/.config/xiaolinstar/**`
- VPS / 服务器 L3 文件

**允许 Agent：**

- `docs/env/`、`*.example`、`playbook/env-registry.yaml`
- 运行 `env check`（只读）

## 与其它文档

- [ADR-0012](adr/0012-config-github-l2-only.md) — 本次结构重构
- [env-migration-runbook.md](env-migration-runbook.md) — 历史迁移（L3 备份步骤已过时）
- [ci-minimum-gate.md](ci-minimum-gate.md) — CI 四必选
- [agent-config.md](agent-config.md) — Agent 边界
