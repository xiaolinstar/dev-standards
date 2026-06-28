# Phase 3 · 应用层 env 迁移清单

> 前置：Phase 1 gateway、Phase 2 内容站已完成。
> 扫描：`sync.sh env status` · 总 runbook：[env-migration-runbook.md](env-migration-runbook.md)

## 顺序

```text
3A  ai-todo        staging (121.199.175.147) + production (124.222.98.227:8082)
3B  party-helper   production (124.222.98.227:8021)
3C  drink-budget   production (124.222.98.227:8020，单文件 .env.production)
```

## 通用：config 备份对照（app monorepo）

| VPS / 本机 runtime | `~/.config/xiaolinstar/<project>/` |
|--------------------|-------------------------------------|
| `apps/api/.env` | `local.env`（基础层备份） |
| `apps/api/.env.local` | 合并进 `local.env` 或仅本机 repo |
| `apps/api/.env.staging` | `staging.env` |
| `apps/api/.env.production` | `production.env` |

```bash
~/AgentProjects/dev-standards/scripts/sync.sh env check \
  --project ~/AgentProjects/<project> --strict
```

---

## 3A · ai-todo

| 主机 | 文件 | 端口 |
|------|------|------|
| **121.199.175.147** staging | `.env` + `.env.staging` | 8083 |
| **124.222.98.227** production | `.env` + `.env.production` | 8082 |

VPS 检查：

```bash
cd ~/AgentProjects/ai-todo/apps/api
ls -la .env .env.staging .env.production 2>&1
bash ~/AgentProjects/dev-standards/scripts/env/check-env-keys.sh \
  --project ~/AgentProjects/ai-todo --strict \
  --runtime apps/api/.env --runtime apps/api/.env.production
# staging 机再加 --runtime apps/api/.env.staging
```

本机备份：

```bash
scp ubuntu@124.222.98.227:~/AgentProjects/ai-todo/apps/api/.env.production \
  ~/.config/xiaolinstar/ai-todo/production.env
scp ubuntu@121.199.175.147:~/AgentProjects/ai-todo/apps/api/.env.staging \
  ~/.config/xiaolinstar/ai-todo/staging.env
```

文档：[ai-todo docs/env/README.md](https://github.com/xiaolinstar/ai-todo/blob/main/docs/env/README.md)

---

## 3B · party-helper

| 主机 | 文件 | 端口 |
|------|------|------|
| **124.222.98.227** | `.env` + `.env.production` | 8021 |

```bash
cd ~/AgentProjects/party-helper/apps/api
ls -la .env .env.production
~/AgentProjects/dev-standards/scripts/env/check-env-keys.sh \
  --project ~/AgentProjects/party-helper --strict \
  --runtime apps/api/.env --runtime apps/api/.env.production
```

备份 → `~/.config/xiaolinstar/party-helper/production.env`（及 `.env` → `local.env` 可选）。

文档：[party-helper docs/env/README.md](https://github.com/xiaolinstar/party-helper/blob/main/docs/env/README.md)

---

## 3C · drink-budget

| 主机 | 文件 | 端口 |
|------|------|------|
| **124.222.98.227** | **仅** `.env.production` | 8020 |

```bash
cd ~/AgentProjects/drink-budget/apps/api
test -f .env.production
docker compose --env-file .env.production -f docker-compose.yml config >/dev/null
~/AgentProjects/dev-standards/scripts/env/check-env-keys.sh \
  --project ~/AgentProjects/drink-budget --strict \
  --runtime apps/api/.env.production
```

备份 → `~/.config/xiaolinstar/drink-budget/production.env`

文档：[drink-budget docs/env/README.md](https://github.com/xiaolinstar/drink-budget/blob/main/docs/env/README.md)

---

## Phase 3 完成标准

- [x] prod VPS 124.222.98.227：ai-todo / party-helper / drink-budget `check-env-keys --strict` 通过
- [x] staging VPS 121.199.175.147：ai-todo `.env` + `.env.staging` 通过
- [x] `~/.config/xiaolinstar/{ai-todo,party-helper,drink-budget}/` 已填
- [x] `env-migration-status.yaml` 应用项 `local_config` + `vps_runtime` → `done`
- [x] 启动 probe / healthz 统一（见 gateway healthz-probe-standard.md；uptime.yml 已全部 /healthz）

## VPS 前置

应用机 **124.222.98.227** 需 clone dev-standards 后才能跑 `check-env-keys.sh`：

```bash
test -d ~/AgentProjects/dev-standards || \
  git clone git@github.com:xiaolinstar/dev-standards.git ~/AgentProjects/dev-standards
```

2026-06-28 探测：prod 上三项目 runtime 已存在；`dev-standards` 尚未 clone。staging **121.199.175.147** 需单独 SSH 凭据。
