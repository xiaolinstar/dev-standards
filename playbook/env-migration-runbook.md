# 环境变量迁移 Runbook

> 在 **全部项目** 完成本 runbook 前，**暂停** gateway `/healthz` 探活切换与可观测性 probe 扩展。
> 进度文件：[env-migration-status.yaml](env-migration-status.yaml) · 扫描：`sync.sh env status`

## 目标状态

| 层 | 完成标准 |
|----|----------|
| **L0** | 各仓 `*.example` 与 [env-registry.yaml](env-registry.yaml) 一致 |
| **L3 本地备份** | `~/.config/xiaolinstar/<project>/*.env` 已填且 `env check --local --strict` 通过 |
| **L3 VPS** | 运行时文件存在且 CD/部署脚本 `verify-runtime-env` 通过 |
| **L2 GitHub** | CD 用 Secrets 在 Environment `production`（及 `staging`）；清单见各仓 `docs/env/` |

## 迁移顺序（建议）

```text
Phase 1  平台     xiaolin-gateway     （CD 已依赖 .env*，先清 legacy env/production.env）
Phase 2  内容站   xiaolin-docs → xiaolin-life
Phase 3  应用     ai-todo → party-helper → drink-budget
```

每项目固定 **5 步**（Agent 只做 1、5；2–4 人工）：

1. **对齐模板** — 仅改 `*.example` / `docs/env/`（PR）
2. **导入备份** — `sync.sh env import-config --project <name>`（从现有 `.env` 拷到 `~/.config/xiaolinstar`）
3. **人工补键** — 编辑 `~/.config/xiaolinstar/<project>/*.env`，禁止 Agent
4. **应用运行时** — 本地：`sync.sh env apply-config --project <name> --env production`；VPS：SSH 粘贴或 `scp`
5. **验证** — `sync.sh env check --project <repo> --strict`；gateway 再跑 CI/CD

## 通用命令

```bash
# 总览
~/AgentProjects/dev-standards/scripts/sync.sh env status

# 从仓库已有 .env 导入到 ~/.config/xiaolinstar（不覆盖非空）
~/AgentProjects/dev-standards/scripts/sync.sh env import-config --project ai-todo

# 从 config 写回仓库运行时（本地/VPS 准备）
~/AgentProjects/dev-standards/scripts/sync.sh env apply-config \
  --project ai-todo --env production --force

# 严格校验
~/AgentProjects/dev-standards/scripts/sync.sh env check \
  --project ~/AgentProjects/ai-todo --local production --strict
```

## Phase 1 · xiaolin-gateway

| 步骤 | 动作 |
|------|------|
| VPS 清理 | SSH：`cd ~/AgentProjects/xiaolin-gateway`；若存在 `env/production.env`，合并键到 `.env` / `.env.production` 后删除 |
| 模板 | 已有 `.env.example`、`.env.production.example` |
| 导入 | `env import-config --project xiaolin-gateway` |
| VPS 写入 | 将 `production.env` 内容同步到服务器 `.env` + `.env.production` |
| 验证 | 服务器：`bash scripts/cd/verify-runtime-env.sh`；本地：`env check --project . --strict` |
| GitHub | `SERVER_HOST` / `SERVER_USER` / `SERVER_PASSWORD` 保持在 repo Secrets 或迁到 Environment `production` |

文档：[xiaolin-gateway docs/env/README.md](https://github.com/xiaolinstar/xiaolin-gateway/blob/main/docs/env/README.md)

## Phase 2 · 内容站

### xiaolin-docs（与 life 对齐 · COS）

- 共用 Bucket + `~/.cos.yaml`；`.env` 设 `COS_PREFIX=docs`、`MEDIA_CDN_BASE`
- 上传：`pnpm run media:upload`（`docs/public/images` → `docs/` 前缀）
- VPS **无** `.env`；文档：[docs/env/README.md](https://github.com/xiaolinstar/xiaolin-docs/blob/main/docs/env/README.md)

### xiaolin-life（方案 A）

- **COS 凭证在 `~/.cos.yaml`**，不在 `.env`
- `.env` 仅 `COS_PREFIX`、`MEDIA_CDN_BASE` 等；`.env.example` 已去掉 `COS_SECRET_*`
- VPS 8081 无需 `.env`；备份 `local.env` + 单独保管 `~/.cos.yaml`
- 文档：[xiaolin-life docs/env/README.md](https://github.com/xiaolinstar/xiaolin-life/blob/main/docs/env/README.md)

## Phase 3 · 应用

### ai-todo（参考实现）

| 文件 | 用途 |
|------|------|
| `apps/api/.env` | 非密钥默认 |
| `apps/api/.env.local` | 本地 |
| `apps/api/.env.staging` | staging VPS |
| `apps/api/.env.production` | prod VPS |

- 文档：`docs/env/README.md`、`docs/env/github-environments.md`
- staging / production **不同 VPS**（gateway 路由表已登记）

### party-helper

- 模板齐全（含 `.env.staging.example`，staging 可选）
- 参考 [docs/env/README.md](https://github.com/xiaolinstar/party-helper/blob/main/docs/env/README.md)
- 生产：`apps/api/.env` + `.env.production` → port **8021**

### drink-budget

- 生产 VPS **单文件** `apps/api/.env.production`（`--env-file`）
- 模板：`.env.production.example`（密钥）+ `.env.example`（非敏感默认）
- 端口 **8020** · 清单：[env-phase3-checklist.md](env-phase3-checklist.md) §3C

## Phase 3 详细步骤

见 [env-phase3-checklist.md](env-phase3-checklist.md)。

## VPS 通用检查清单

在每台部署机执行：

```bash
test -d ~/AgentProjects/dev-standards
test -f ~/AgentProjects/<project>/.env   # 或 apps/api/.env
bash ~/AgentProjects/dev-standards/scripts/env/check-env-keys.sh \
  --project ~/AgentProjects/<project> --strict --runtime .env --runtime .env.production
```

## 完成后

1. 更新 [env-migration-status.yaml](env-migration-status.yaml) 各项为 `done`
2. 再启动 gateway [healthz 探活迁移](https://github.com/xiaolinstar/xiaolin-gateway/blob/main/docs/healthz-probe-standard.md)
3. 各应用实现 `GET /healthz` 并改 `uptime.yml`

## Agent 边界

- ✅ 改 `*.example`、runbook、registry、`env status`
- ❌ 读/写 `~/.config/xiaolinstar/**`、`.env`、VPS SSH 上的密钥
