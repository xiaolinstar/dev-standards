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

| 层  | 放什么               | **真源**                      | 不放什么                              |
| --- | -------------------- | ----------------------------- | ------------------------------------- |
| L0  | 键名、默认端口       | 仓库 `docs/env/`              | 密码、私钥                            |
| L1  | `NODE_VERSION`       | workflow                      | 生产 DSN                              |
| L2  | `DEPLOY_*`、探活 URL | **GitHub**（由本地 IaC 同步） | 微信 AppSecret、DB 密码               |
| L3  | DB、JWT、微信密钥    | **VPS / 本机 gitignore 文件** | 不应 commit；**不应**备份到 ~/.config |

### 单一受控源原则

- **L3**：只在目标机器维护一份（Compose `.env.production`、K8s overlay `.env.production.secrets`）。**不再** scp 到 `~/.config/xiaolinstar/<project>/production.env`。
- **L2**：本地 `variables.env`（可选）+ `secrets.env` 是 **编写 IaC**；`sync-github` 按文件全量推到 GitHub 后，**CD 只读 GitHub**。
- 避免「config 备份 + VPS 真源」双轨——后者是旧模型，已废弃（ADR-0012）。

### 模板书写规范

- 必须为 `.env.example` 模板中的每个变量提供清晰的注释（例如 `[Required]`，`[Optional]`），说明变量用途及默认值。
- **强制或强烈推荐使用纯英文编写注释**，以避免在多种终端、CI/CD 系统和容器环境中可能引发的字符编码乱码问题。

## ~/.config/xiaolinstar（仅 GitHub L2）

```text
~/.config/xiaolinstar/<project>/github/
├── production/          # application 等
│   ├── variables.env    # → gh variable set
│   └── secrets.env      # → gh secret set
├── tencent-101/         # platform · gateway
│   ├── variables.env
│   └── secrets.env
└── aliyun-121/
    ├── variables.env
    └── secrets.env
```

**仓库级 L2**（content）：

```text
~/.config/xiaolinstar/<project>/github/variables.env
~/.config/xiaolinstar/<project>/github/secrets.env
```

L0 模板：`docs/env/github/<environment>/variables.env.example`（**可选**）与 `secrets.env.example`。
无 GitHub Variables 的项目（如 gateway）不提供 variables 模板；`init-github-env` 会跳过并提示 optional。

### 元数据（约定优于配置）

数据文件只放要同步的键。`project` / `environment` / `repository` / `scope` **不要**写进 `variables.env` 或 `secrets.env`。

| 元数据 | 来源 |
| ------ | ---- |
| project | CLI `--project` |
| environment | CLI `--environment` 或 `--env`（`scope: environment`；省略时 CLI 默认 `production`） |
| repository | profile.`repository`，缺省 `xiaolinstar/<project>`。本阶段**不**支持文件内覆盖 |
| scope | profile.`scope`：`environment` 或 `repository` |
| 目录 | profile.`config_dir`。`environment` scope 再加环境子目录；`repository` scope 用 `github/variables.env` 与 `github/secrets.env`（无子目录，`gh … set` 不带 `--env`） |

`variables.env` 与 `secrets.env` 各自可选，但**至少有一个**。两者皆缺时 `sync-github` 以非零退出，并提示 `init-github-env`。

### 命名对照（ai-todo）

| 名称               | 示例                             | 含义                     |
| ------------------ | -------------------------------- | ------------------------ |
| GitHub Environment | `production-k8s`                 | CD：SSH 到 111、K8s 后端 |
| GitHub Environment | `production`                     | CD：SSH 到 124、Compose  |
| K8s overlay        | `overlays/production`            | 产品档位 infra           |
| 应用 ConfigMap     | `AI_TODO_ENVIRONMENT=production` | API `/v1/health` 等      |

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

### 废弃路径（报错引导，勿再写入）

| 旧路径                                   | 现在                                                         |
| ---------------------------------------- | ------------------------------------------------------------ |
| `<project>/github-*.env`、`github/**/env.env` | **不再加载**。新布局缺失时 `sync-github` 报错并打印期望路径，提示 `init-github-env`。不做静默合并或只读回退 |
| `<project>/production.env`（L3 备份）    | VPS `apps/api/.env.production` **唯一**                      |
| `env import-config` / `env apply-config` | 直接在 VPS 或本机改 runtime                                  |

## 每仓运行时布局（L3）

| `runtime_layout` | 适用            | L3 路径                           |
| ---------------- | --------------- | --------------------------------- |
| `root-dotenv`    | gateway、内容站 | 仓库根 `.env` + `.env.production` |
| `app-scoped`     | API monorepo    | `apps/api/.env` + `.env.<env>`    |

加载顺序：基础 `.env` → 环境覆盖（`.env.local` | `.env.staging` | `.env.production`）。

| 场景     | 配置来源                                            |
| -------- | --------------------------------------------------- |
| 本地开发 | L0 复制为 gitignore runtime                         |
| CI 测试  | job `env` 或假值                                    |
| CD       | GitHub L2 SSH + VPS L3                              |
| K8s      | overlay `secretGenerator` + VPS 上 `.env.*.secrets` |

### K8s Overlay 配置文件命名规范

对于 Kubernetes Kustomize 环境使用的声明式配置文件（不上传 Git，仅在 VPS 运行时存在），全局统一采用以下后缀约束：

- **ConfigMap 配置字典**：后缀统一为 **`.env.<environment>.config`**（单数）。
- **Secret 密钥**：后缀统一为 **`.env.<environment>.secrets`**（复数）。

示例：

- `deploy/k8s/overlays/production/.env.production.config`
- `deploy/k8s/overlays/production/.env.production.secrets`

> **规范理由**：K8s 原生对象为 `ConfigMap` (单数，一个配置字典) 和 `Secret`
> (但习惯称包含多个密钥的文件为 `secrets`)。统一约定该「单一 + 复数」模式，
> 杜绝各项目间出现 `.configs` 与 `.config` 混用的情况
> （例如 `party-helper` 曾使用的 `.configs` 应向此规范看齐）。

## GitHub Environments（L2）

> [ADR-0009](adr/0009-l2-github-env-by-category.md) · `scripts/env/github-sync-profiles.json`

| category    | Environment / 作用域                                                     | 键名前缀   |
| ----------- | ------------------------------------------------------------------------ | ---------- |
| platform    | Environments `tencent-101`、`aliyun-121`（gateway 双机）                 | `SERVER_*` |
| content     | 仓库级（无 Environment）                                                 | `SERVER_*` |
| application | `production`、`staging`；ai-todo 另有 **`production-k8s`**               | `DEPLOY_*` |

### application 标准键

| 类型     | 键                                                         |
| -------- | ---------------------------------------------------------- |
| Variable | `DEPLOY_HOST`、`DEPLOY_USER`、`DEPLOY_PORT`、`DEPLOY_PATH` |
| Secret   | `DEPLOY_PASSWORD`（默认）或 `DEPLOY_SSH_KEY`（备选）       |

**ai-todo L2 扩展**（所有 GitHub Environment **键名相同**，仅值因部署面而异）：
`CD_PUBLIC_API_URL`、`CD_LOCAL_HEALTH_URL`（可选）、`DEPLOY_BACKEND`、`K8S_*`
（`DEPLOY_BACKEND=k8s` 时生效）、`GHCR_*`、`CD_SMOKE_PAT`（可选）。

**不放 L2**：`POSTGRES_PASSWORD`、`AI_TODO_WECHAT_APP_SECRET` 等业务密钥——仅 L3。

### sync-github（文件全量同步）

只读取新布局里**存在**的文件。每个非空 `KEY=value` 原样推送（空值跳过）：

- `variables.env` → `gh variable set KEY --repo <repository> [--env <environment>] --body <value>`
- `secrets.env` → `gh secret set …`（参数相同）

约定：

- **不再**用 profile 的 `variables` / `secrets` 白名单过滤。这两个字段已废弃；写在 profile 里也会被忽略。
- 可选 `required_variables` / `required_secrets`：只校验键存在且非空，缺则退出码 1。
- `--dry-run`：打印将推送的 `variable|secret KEY → repo[/env]`，不调用 `gh` 写入。
- 不展开 `DEPLOY_SSH_KEY_FILE`、`DEPLOY_SSH_KEY_B64` 或内联私钥路径。需要私钥时把内容写入 `secrets.env` 里对应的 Secret 名，或自行 `gh secret set`。

**存量文件警告**：`variables.env` 里若还留着 `GITHUB_REPOSITORY`、`GITHUB_ENVIRONMENT` 或其他 `GITHUB_*`，
全量同步会把它们当成普通 Variable 推上 GitHub。同步前删掉这些键，并用 `--dry-run` 核对键名。

```bash
gh variable set DEPLOY_HOST --repo xiaolinstar/ai-todo --env production --body 124.222.98.227

~/AgentProjects/dev-standards/scripts/sync.sh env sync-github --project ai-todo --environment production
~/AgentProjects/dev-standards/scripts/sync.sh env sync-github --project ai-todo --environment production-k8s
~/AgentProjects/dev-standards/scripts/sync.sh env sync-github \
  --project xiaolin-gateway --environment tencent-101
~/AgentProjects/dev-standards/scripts/sync.sh env sync-github \
  --project xiaolin-gateway --environment aliyun-121
```

## 键名校验（check）

```bash
# 仓库 L0 *.example ↔ 本机 runtime（开发者）
~/AgentProjects/dev-standards/scripts/sync.sh env check --project ~/AgentProjects/ai-todo

# L0 github 模板 ↔ ~/.config L2 文件（**仅人类终端**；会读 secrets.env）
~/AgentProjects/dev-standards/scripts/sync.sh env check \
  --project ~/AgentProjects/ai-todo --github --env production
```

**不再**使用 `--local production` 校验 `~/.config/.../production.env`。

## Agent 禁区（`~/.config/xiaolinstar`）

**目标**：降低密钥进入 Agent 上下文的概率；**不是**密码学级保密（见下）。

**禁止 Agent（读与写均禁止）：**

- `~/.config/xiaolinstar/**`（含 `cat` / `less` / Read 工具 / 编辑器打开）
- gitignore 的 `*.env`、`.env.*`（非 `*.example`）
- VPS / 服务器 L3 文件
- 代跑 `env sync-github`、`env init-github-env`、`env check --github`（这些会读 L2 secrets）

**允许 Agent：**

- 仓库内 `docs/env/**/*.example`、`playbook/env-registry.yaml`
- 提示用户在**自己的终端**执行 `init-github-env` / `sync-github`（Agent 只给命令，不执行、不读输出中的密钥）
- 无 `--github` 的 `env check`（仅对照仓库模板与本机 gitignore runtime，若 runtime 也含密钥则仍勿代跑）

**生效方式**：`permissions/manifest.json` + Claude `Read/Edit` deny + Cursor alwaysApply 规则；人类用本机终端维护 L2 并 `sync.sh env sync-github`。

**保密边界（诚实预期）：**

| 能做到 | 做不到 |
|--------|--------|
| 默认不把 L2 明文拉进对话 / 工具输出 | 阻止你本机其它进程、备份、截图读取同一文件 |
| 降低 Agent「顺手打开 secrets.env」 | 你粘贴密钥到聊天、或批准 `all`/绕过规则后的读取 |
| 与「只经 sync.sh 推 GitHub」流程对齐 | 替代磁盘加密、密钥管理器、或 OS 级 ACL |

结论：**适合作为 Agent 隔离策略**；真保密仍依赖文件权限、少拷贝、不把真实值放进仓库/聊天，以及 GitHub Secrets 侧管控。

## 与其它文档

- [ADR-0012](adr/0012-config-github-l2-only.md) — 本次结构重构
- [env-migration-runbook.md](env-migration-runbook.md) — 历史迁移（L3 备份步骤已过时）
- [ci-minimum-gate.md](ci-minimum-gate.md) — CI 四必选
- [agent-config.md](agent-config.md) — Agent 边界
