---
ID: 0012
Title: ~/.config 仅承载 GitHub L2 IaC；运行时密钥单一真源在 VPS
Status: Accepted
Date: 2026-07-07
Deciders: xingxiaolin
Supersedes: env-management.md §L3 备份至 ~/.config（部分）
---

## 背景

原模型在 `~/.config/xiaolinstar/<project>/` 同时存放：

1. **L2 备份**：`github-*.env`（GitHub Actions Variables / Secrets）
2. **L3 备份**：`production.env`、`staging.env`（VPS 业务运行时副本）

实践中 L3 备份与 VPS 上的 `.env.production` **极易漂移**（改了一处忘另一处），违背单一受控源与云原生运维原则。随着 deploy target 增多（Compose `production`、K8s `production-k8s`），扁平 `github-<env>.env` 文件名也趋于混乱。

## 决策

### 1. 单一真源（按层）

| 层 | 职责 | **唯一真源** | 本地 IaC（可选） |
|----|------|--------------|------------------|
| L0 | 键名文档 | 仓库 `*.example`、`docs/env/` | — |
| L1 | CI job env | workflow `env:` | — |
| L2 | CD / SSH / 探活 | **GitHub Environments**（Actions 运行时读） | `github/<name>/variables.env` + `secrets.env` → `sync-github` 推送 |
| L3 | 业务密钥（DB、微信等） | **VPS / 本机 gitignore 运行时文件** | **不再**备份到 `~/.config` |

L2 工作流：编辑本地 `variables.env` + `secrets.env` → `sync.sh env sync-github` → GitHub。GitHub 是 CD **运行时**真源；本地是 L2 **编写**真源（类似 Terraform 源码 vs 远端 state 的分工，但 L2 无 state 分叉需求时以 GitHub 为准即可）。

L3 工作流：只在 VPS（或开发者本机）维护 `apps/api/.env.production` 等；**禁止** `import-config` / `apply-config` 在 config 与 runtime 间双向复制。

### 2. ~/.config 目录结构（按 GitHub Environment 分目录）

```text
~/.config/xiaolinstar/<project>/github/
├── production/
│   ├── variables.env
│   └── secrets.env
├── staging/
│   ├── variables.env
│   └── secrets.env
└── production-k8s/          # 仅 ai-todo 等需要时
    ├── variables.env
    └── secrets.env
```

**仓库级 L2**（platform / content，`l2_scope: repository`）：

```text
~/.config/xiaolinstar/<project>/github/variables.env
~/.config/xiaolinstar/<project>/github/secrets.env
```

L0 模板：`docs/env/github/<environment>/variables.env.example` 与 `secrets.env.example`。

### 3. GitHub Environment 名 vs 应用运行时名

| 名称 | 示例 | 含义 |
|------|------|------|
| GitHub Environment | `production-k8s` | CD 部署面（主机 + 后端） |
| K8s overlay / 应用 | `production` | 产品档位（`AI_TODO_ENVIRONMENT=production`） |

**不强制** GitHub Environment 名与 `AI_TODO_ENVIRONMENT` 一致。

### 4. 废弃命令

| 命令 | 状态 |
|------|------|
| `env import-config` | **废弃** — 不再把 VPS runtime 导入 ~/.config |
| `env apply-config` | **废弃** — 不再从 ~/.config 写回 runtime |
| `env check --local`（对 `production.env`） | **废弃** — 改用 `env check --github --env <name>` |

保留 `env check --project` 校验仓库 `*.example` 与**同机** runtime 文件（开发者本机）；VPS runtime 不在 CI 中强制校验存在。

### 5. 迁移

- 旧路径 `github-production.env`：`sync-github` 只读兼容，**新文件请用** `github/<env>/variables.env` + `secrets.env`。
- 旧单文件 `env.env`：同上只读兼容，**新文件请用** `variables.env` + `secrets.env`。
- 旧路径 `production.env` 等 L3 备份：可手动删除；不再由 `init-config` 创建。

## 后果

- **正面**：运维边界清晰；L2/L3 不混文件；多 deploy target 可扩展目录。
- **负面**：换机需保留 `~/.config/.../github/` 或从 L0 模板重建；VPS 密钥丢失时不能从 ~/.config 恢复（应走 VPS 备份 / 密钥轮换 runbook）。
- **ai-todo**：新增 GitHub Environment `production-k8s`（111 · K8s），与 Compose `production`（124）并行。

## 参考

- [env-management.md](../env-management.md)
- [ADR-0009](0009-l2-github-env-by-category.md)
