# 环境变量与密钥治理

> 跨项目 L0–L3 分层、集中配置目录 `~/.config/xiaolinstar`、模板键名校验与 Agent 禁区。
> 键名索引：[env-registry.yaml](env-registry.yaml)。CI 分层见 [ci-minimum-gate.md](ci-minimum-gate.md) §环境密钥。

## 四层模型（L0–L3）

```text
L0  仓库模板（可 commit）     *.env.example、docs/env/
L1  CI workflow              非敏感 env + GITHUB_TOKEN
L2  GitHub Environments      staging / production（CD、SSH、探活 URL）
L3  运行时真实值              VPS 文件 + ~/.config/xiaolinstar/
```

| 层 | 放什么 | 不放什么 |
|----|--------|----------|
| L0 | 键名、默认端口、文档 | 密码、AppSecret、私钥 |
| L1 | `NODE_VERSION`、测试用假 DB | 生产 DSN |
| L2 | `DEPLOY_HOST`、公网 smoke URL | 与 L3 无必要的重复 |
| L3 | DB URL、JWT、微信密钥 | 不应 commit |

## 集中配置：`~/.config/xiaolinstar`

GitHub 组织/用户名为 **xiaolinstar**，本地集中目录统一为：

```text
~/.config/xiaolinstar/
├── README.md                 # 人工维护；Agent 禁止写入
├── xiaolin-gateway/
│   ├── local.env             # L3：VPS runtime 备份
│   ├── production.env
│   └── github-production.env # L2：可选，GitHub Environment 本地清单
├── ai-todo/
│   ├── local.env
│   ├── staging.env
│   ├── production.env
│   └── github-staging.env    # L2 可选
└── …/<project>/<env>.env
```

**L3 与 L2 备份分文件**：`local.env` / `production.env` 对应 VPS 业务运行时；`github-*.env` 仅含 CD/探活等 GitHub Actions 键，**不要**与 DB/JWT 等业务密钥混在同一文件。

初始化（不覆盖已有文件）：

```bash
~/AgentProjects/dev-standards/scripts/sync.sh env init-config
```

### 仓库 runtime ↔ config 备份对照

`~/.config/.../local.env` **不是**仓库里的 `.env.local`，而是 registry 环境档位名 `local` 对应的备份文件名。

| 仓库 runtime（VPS / 本机） | config 备份 | 说明 |
|----------------------------|-------------|------|
| `.env` | `local.env` | 基础层；VPS 生产也备份到此名（易误解但为既定约定） |
| `.env.production` | `production.env` | 生产覆盖层 |
| `.env.staging` | `staging.env` | staging VPS（如 ai-todo） |
| `.env.local` | *无专用槽位* | **仅本机开发**覆盖；VPS CD **不读**；一般不必备份 |

gateway VPS（`101.34.78.2`）示例：

```bash
scp ubuntu@101.34.78.2:~/AgentProjects/xiaolin-gateway/.env \
    ~/.config/xiaolinstar/xiaolin-gateway/local.env
scp ubuntu@101.34.78.2:~/AgentProjects/xiaolin-gateway/.env.production \
    ~/.config/xiaolinstar/xiaolin-gateway/production.env
chmod 600 ~/.config/xiaolinstar/xiaolin-gateway/*.env
```

校验备份（分层模型勿用 `--local --env production` 验 `production.env`，会误报）：

```bash
sync.sh env check --project ~/AgentProjects/xiaolin-gateway --local --env local --strict
```

### 工作流

1. 仓库 PR 只改 `*.example` 与 `docs/env/`（L0）。
2. 你在 `~/.config/xiaolinstar/<project>/` 填真实值（L3）。
3. 部署前跑键名校验（见下）；CD 用 GitHub L2 凭据 SSH，业务密钥留在 VPS L3。

## 每仓运行时布局（二选一）

| `runtime_layout` | 适用 | L3 路径 |
|------------------|------|---------|
| `root-dotenv` | gateway、内容站 | 仓库根 `.env` + `.env.production` |
| `app-scoped` | API monorepo | `<runtime_root>/.env` + `.env.<env>` |

**不要**同一仓库混用 `env/production.env` 与根目录 `.env.production` 两套加载方式。

加载顺序：基础 `.env` → 环境覆盖（`.env.local` | `.env.staging` | `.env.production`），后者覆盖前者。

## 何时需要环境配置

| 场景 | 配置来源 |
|------|----------|
| 本地开发 | L0 复制为 L3 + `~/.config/xiaolinstar` 可选 |
| CI 测试 | job `env` 或 `.env.test`（假值） |
| CD | GitHub Environment + 服务器 L3 |
| 容器启动 | `env_file` / compose 变量，**不进镜像** |

`docker-compose.prod.yml`：仅当 prod 与 dev **服务结构**不同时才拆；否则 env 覆盖即可（见 ADR-0003）。

## GitHub Environments（L2）

### 真源与职责

| 角色 | 位置 | 说明 |
|------|------|------|
| **运行时真源** | GitHub → Settings → Environments → `production` / `staging` | Actions 读 `secrets.*` / `vars.*` |
| **键名文档（L0）** | 各仓 `docs/env/github-environments.md` 或 `*.example.env` | 只列键名与示例，不含真实值 |
| **本地清单（可选）** | `~/.config/xiaolinstar/<project>/github-<env>.env` | 灾难恢复、换机、批量 `gh` 同步 |

命名与运行时对齐：`staging`、`production`。

- **放 L2**：`DEPLOY_HOST`、`DEPLOY_SSH_KEY` / `DEPLOY_PASSWORD`、公网 smoke URL、CI PAT、构建期非敏感变量（如 `DOCKER_BAIDU_ANALYTICS_ID`）。
- **不放 L2**：能只留在 VPS L3 的业务 DB 密码、JWT、微信密钥（减少重复与泄露面）。

### 推荐工作流（你当前设想的模式）

1. 读仓库 L0 文档，确认该 Environment 需要哪些 **Variables** 与 **Secrets**。
2. 在本机填写 `~/.config/xiaolinstar/<project>/github-production.env`（或项目自有路径，见下）。
3. 用 `gh` 推到 GitHub（手动或脚本）；**GitHub 仍是 CI 运行时真源**，本地文件只是备份与可重复同步源。

```bash
# 手动（变量 vs 密钥区分清楚）
gh variable set DEPLOY_HOST --repo xiaolinstar/ai-todo --env production --body 124.222.98.227
gh secret set DEPLOY_SSH_KEY --repo xiaolinstar/ai-todo --env production < ~/.ssh/deploy_key

# 带脚本的仓（优先用仓内脚本，键名与 workflow 已对齐）
cd ~/AgentProjects/party-helper && pnpm sync:github-env -- --dry-run
cd ~/AgentProjects/drink-budget && pnpm sync:github-env -- --dry-run
cd ~/AgentProjects/xiaolin-gateway && bash scripts/cd/sync-github-env.sh --dry-run
cd ~/AgentProjects/xiaolin-docs && pnpm sync:github-env -- --dry-run

# 或从 dev-standards 统一入口（profile 见 scripts/env/github-sync-profiles.json）
~/AgentProjects/dev-standards/scripts/sync.sh env sync-github --project xiaolin-life --dry-run
```

业务仓 L0 参考：ai-todo
[github-environments.md](https://github.com/xiaolinstar/ai-todo/blob/main/docs/env/github-environments.md)；
party-helper / drink-budget 有 `github-*.env.example` + 同步脚本。

### 本地路径的两种约定（收敛中）

| 约定 | 路径 | 项目 |
|------|------|------|
| **xiaolinstar 统一** | `~/.config/xiaolinstar/<project>/github-<env>.env` | 新备份建议用此 |
| **项目自有（迁移中）** | `~/.config/party-helper/env/` | party-helper 仍兼容旧路径；drink-budget 已统一到 xiaolinstar |

不必立刻迁移旧路径；新增 L2 备份时优先放进 `xiaolinstar/<project>/`，并在该仓 `docs/env/README.md` 写清文件名。

### 与 Actions Secrets/Variables 方案的关系

**是的，这就是当前方案**：GitHub Environments 的 **Environment secrets** + **Environment variables**，
由 workflow 的 `environment: production` 注入 job。
`gh secret set --env` / `gh variable set --env` 正是官方 CLI，适合单人本地集中管理后推送到指定仓库。

**是否需要更好方案？** 对你当前规模（单人、多仓、已有 VPS L3）：

| 方案 | 适用 | 说明 |
|------|------|------|
| **现状 + 本地 `github-*.env` + `gh`** | ✅ 推荐继续 | 简单、与 Actions 原生集成、无额外服务 |
| Organization secrets | 多仓共享同一 GHCR token 等 | 仅真正跨仓重复的键才上 org 级 |
| SOPS + age 加密本地备份 | 担心本机磁盘泄露 | 可选；GitHub 侧仍用 Environments |
| Vault / Infisical / Doppler | 多人轮换、审计 | 过重；等团队协作再评估 |

**不要**把 L2 SSH 与 L3 Grafana/DB 写进同一个 `.env` 文件；L2 变更（换 deploy 密钥）也不应触发 VPS runtime 备份 diff。

## 模板与运行时键名同步（check）

L0 新增键后，L3 容易漏改。校验**只比键名，不比值**：

```bash
# 校验某业务仓模板是否自洽 + 运行时是否缺键
~/AgentProjects/dev-standards/scripts/sync.sh env check --project ~/AgentProjects/ai-todo

# 对比 ~/.config/xiaolinstar 与模板
~/AgentProjects/dev-standards/scripts/sync.sh env check --project ~/AgentProjects/ai-todo --local production

# 指定运行时文件
~/AgentProjects/dev-standards/scripts/sync.sh env check \
  --project ~/AgentProjects/xiaolin-gateway --runtime .env.production
```

建议在业务仓 CI 增加 job：`bash …/check-env-keys.sh --project .`（模板存在则检查；缺 L3 不失败）。

注册表结构校验（本库 `validate` 已包含）：

```bash
bash scripts/env/validate-registry.sh
```

## Agent 禁区

**禁止 Agent 自动修改：**

- 任何已 gitignore 的 `*.env`、`.env.*`（**非** `*.example`）
- `~/.config/xiaolinstar/**`
- `observability/secrets/`、证书目录、服务器上的 L3 文件

**允许 Agent：**

- 编辑 `*.example`、`docs/env/`、`playbook/env-registry.yaml`
- 运行 `sync.sh env check`（只读校验）
- 提示用户：「请在 `~/.config/xiaolinstar/<project>/production.env` 手动添加 `KEY=`」

## 集中式密钥中心（演进）

| 阶段 | 方案 |
|------|------|
| **现在** | `~/.config/xiaolinstar` + [env-registry.yaml](env-registry.yaml) + `check-env-keys.sh` |
| 下一步 | 可选 CLI `xiaolin-env export <project> <env>`（读写 config 目录，无 daemon） |
| 以后 | SOPS + age 或 Infisical 自建（多人/轮换时再上） |

## 三类站点速查

| 类 | 项目 | L3 要点 |
|----|------|---------|
| 平台 | xiaolin-gateway | 根 `.env*`；监控/Alertmanager 路径 |
| 应用 | ai-todo 等 | `apps/api/.env*`；GitHub staging+production |
| 内容 | xiaolin-docs / life | 本机 `.env`（构建/媒体脚本）；**VPS compose 通常不读 `.env`**；life 的 COS 凭证在 `~/.cos.yaml` |

内容站详见各仓 `docs/env/README.md`。

路由与域名见 [xiaolin-gateway routing-registry](https://github.com/xiaolinstar/xiaolin-gateway/blob/main/docs/routing-registry.md)。

## 与其它文档

- [env-migration-runbook.md](env-migration-runbook.md) — 全项目 env 迁移与 healthz 探活（gateway 真源）
- [env-migration-status.yaml](env-migration-status.yaml) — 人工进度跟踪
- [ci-minimum-gate.md](ci-minimum-gate.md) — CI 四必选 + L0–L3 摘要
- [env-registry.yaml](env-registry.yaml) — 项目键名与路径索引
- [agent-config.md](agent-config.md) — Agent 配置边界
- [audit-feedback-loop.md](audit-feedback-loop.md) — 环境缺口反馈回标准库
