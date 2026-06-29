---
name: dev-bootstrap
description: Bootstrap or audit a software project against personal dev standards. Use when creating a new repo, onboarding to an existing project, asking "按我的标准初始化", "项目还缺什么", or setting up CLAUDE.md, CI, .cursor/rules, or directory layout. Make sure to use this whenever the user starts a new project or wants a standards checklist, even if they don't say "bootstrap".
---

# Dev Bootstrap

按个人标准库（`~/AgentProjects/dev-standards`）检查或初始化项目。

## 前置

1. 确认项目类型：Web API / CLI / monorepo / 小程序 / 文档站
2. 读标准库 `playbook/principles.md`（原则）、`playbook/ci-minimum-gate.md`（CI/hook 必选）、`playbook/env-management.md`（L0–L3）、`playbook/wechat-mp.md`（小程序主题）
3. 读项目已有 README / **AGENTS.md** / CLAUDE.md
4. 项目特例写在 **AGENTS.md**；CLAUDE.md 仅 `@AGENTS.md` + Claude 专有段

## 审计 checklist（漏一项 = 不合格）

> **完整版**：[playbook/ci-minimum-gate.md §审计 checklist](../../playbook/ci-minimum-gate.md#审计-checklist)
> 这里是入口摘要；遇到具体项去 ci-minimum-gate.md 查模板。

### 标准库健康检查（审计 dev-standards 本身时）

- [ ] `bash ~/AgentProjects/dev-standards/scripts/sync.sh validate` exit 0
- [ ] `playbook/baselines/` 各文件 `last-reviewed` ≤ 30 天（过期则标 ⚠️ 并复核上游）

B 类反馈落点含 `playbook/baselines/`、`playbook/adr/` — 见
[audit-feedback-loop.md §反馈落点决策树](../../playbook/audit-feedback-loop.md#反馈落点决策树)。

### 仓库基础

- [ ] README、LICENSE（若开源）、.gitignore
- [ ] `.env.example`，无密钥进库
- [ ] Agent：**AGENTS.md**（跨工具）+ **CLAUDE.md**（`@AGENTS.md` + Claude 补充）

### Cursor 作用域规则（可选）

- [ ] 需要 glob 触发时：`sync.sh adapters cursor <project>`（见 [agent-config.md](../../playbook/agent-config.md)）

### 工具（本地可跑）

- [ ] `pnpm lint` / `pnpm format` / `pnpm test` 可本地运行
- [ ] `pnpm typecheck`（如适用）

### 本地 Git hooks（必选，对应 [ci-minimum-gate.md §本地 pre-commit 配置](../../playbook/ci-minimum-gate.md#本地-pre-commit-配置必选)）

- [ ] `.husky/pre-commit` 存在，含 gitleaks（降级策略）+ lint-staged
- [ ] `.husky/commit-msg` 存在，含 commitlint
- [ ] `commitlint.config.{js,cjs}` 存在
- [ ] 根 `package.json` 含 `"prepare": "husky"`
- [ ] 根 `package.json` 含 `lint-staged` 配置

### CI（必选 4 项，对应 [ci-minimum-gate.md §必选 4 项](../../playbook/ci-minimum-gate.md#必选-4-项local--ci-双段)）

- [ ] **gitleaks / secret-scan** job（阻断式，必跑）
- [ ] **lint** job
- [ ] **typecheck** 或 **test** job
- [ ] **commit message format** 校验（commitlint CI job 或依赖 husky 本地段）

### 文档

- [ ] developer-guide 或等价「如何跑起来」
- [ ] README 或 CLAUDE.md 写明"如何跑 lint / test / hook 初始化"

### 发布

- [ ] 版本号策略 / CHANGELOG / releases/（若有对外发布）
- [ ] `scripts/bump-version.{ts,mjs}`（如适用，自动同步版本到 manifest）

### L2 GitHub 环境（[ADR-0009](../../playbook/adr/0009-l2-github-env-by-category.md)）

对有 CD / GitHub Secrets 的仓库必查。先读 `playbook/env-registry.yaml` 中该项目的 `l2_category` / `l2_scope`。

| category | 典型项目 | L2 作用域 | 键名前缀 |
|----------|----------|-----------|----------|
| platform | xiaolin-gateway | 仓库 Secrets | `SERVER_*` |
| content | xiaolin-docs、xiaolin-life | 仓库 Secrets / Variables | `SERVER_*` |
| application | ai-todo、party-helper、drink-budget | GitHub Environment | `DEPLOY_*` |

**Checklist（漏一项 = L2 不合格）：**

- [ ] `env-registry.yaml` 存在该项目，`l2_category` 与 `category` 一致
- [ ] 存在 `docs/env/github-environments.example.env` 或等效 L0 清单（如 `github-environments.md`）
- [ ] 本地 `github-*.env` 模板键名 ⊆ registry 声明；无未文档化的 Secrets
- [ ] **application** 仓：GitHub 上存在 `production` Environment；ai-todo 另有 `staging`
- [ ] **content / platform** 仓：CD 密钥在**仓库级** Secrets，**未**误放进 Environment（除非 ADR 偏离）
- [ ] **content** 仓：workflow **无** `MAIL_*` / `action-send-mail`；CD 通知靠 GitHub 账户通知
- [ ] L3 业务密钥（DB、JWT、`ADMIN_TOKEN` 等）**不在** L2
- [ ] （可选）`~/.config/xiaolinstar/<project>/github-*.env` + `sync.sh env sync-github --dry-run` 可推

偏离双轨键名或 category 表 → 新建 ADR 或在审计报告「标准库待反馈」段说明。

## 按项目类型追加

**Monorepo** — 读 [references/monorepo.md](references/monorepo.md)；
核对 ADR-0002 触发条件、`pnpm-workspace.yaml`、根编排 scripts、
`apps/`/`packages/` 边界、组件独立版本
**Python API** — pyproject.toml、迁移策略、tests/ 布局
**Agent 友好 CLI** — 结构化子命令 + `--json`；domain Skill 放业务仓库
**微信小程序（原生 + TS）** — 读 [playbook/wechat-mp.md](../../playbook/wechat-mp.md) +
[skills/wechat-mp/](../../skills/wechat-mp/SKILL.md)；新建项目：
`sync.sh template wechat-mp <dest>`

## 初始化

```bash
# 1. 同步个人 Skills 到 Claude Code
~/AgentProjects/dev-standards/scripts/sync.sh skills

# 1b. （可选）以 Plugin 安装：claude plugin marketplace add ./marketplace.json
#     然后 claude plugin install dev-standards@dev-standards

# 2. （可选）Cursor glob 规则：sync.sh adapters cursor /path/to/project
# 3. 部署 pre-commit 模板（Husky + lint-staged + commitlint）
~/AgentProjects/dev-standards/scripts/sync.sh hooks-precommit /path/to/project
# 合并 .dev-standards-package.json.snippet → package.json；见 ci-minimum-gate.md

# 4. 部署 Claude hooks（可选）
~/AgentProjects/dev-standards/scripts/sync.sh hooks /path/to/project

# 5. 装依赖并初始化 husky
pnpm install --frozen-lockfile
# pnpm install 会自动触发 husky prepare
```

## 循环审计（项目 → 标准库）

对已有仓库做合规审计时，除下方 checklist 外，按 [audit-feedback-loop.md](../../playbook/audit-feedback-loop.md) 输出：

1. **本仓库待修复（A/C）**
2. **标准库待反馈（B/C）** — 确认后开 dev-standards PR
3. 合规评分卡 + 一条下一步

**禁止**在标准库 ADR 中写「某项目已修复」，除非对应 commit 已合入该项目 main。

## 输出

完成后报告：已有项、缺失项（按优先级）、一条下一步建议。

## 参考

- [references/standards-overview.md](references/standards-overview.md)
- [references/monorepo.md](references/monorepo.md)
- [../../playbook/ci-minimum-gate.md](../../playbook/ci-minimum-gate.md) — **审计必读**
- [../../playbook/env-management.md](../../playbook/env-management.md) — L0–L3 分层
- [../../playbook/adr/0009-l2-github-env-by-category.md](../../playbook/adr/0009-l2-github-env-by-category.md)
  — **L2 按 category 审计**
- [../../playbook/wechat-mp.md](../../playbook/wechat-mp.md) — 小程序主题
- [../../playbook/agent-config.md](../../playbook/agent-config.md) — **Agent 配置最小维护**
- [../../playbook/audit-feedback-loop.md](../../playbook/audit-feedback-loop.md) — **循环审计 → 标准反馈**
