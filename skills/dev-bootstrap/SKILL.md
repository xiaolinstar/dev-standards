---
name: dev-bootstrap
description: Bootstrap or audit a software project against personal dev standards. Use when creating a new repo, onboarding to an existing project, asking "按我的标准初始化", "项目还缺什么", or setting up CLAUDE.md, CI, .cursor/rules, or directory layout. Make sure to use this whenever the user starts a new project or wants a standards checklist, even if they don't say "bootstrap".
---

# Dev Bootstrap

按个人标准库（`~/AgentProjects/dev-standards`）检查或初始化项目。

## 前置

1. 确认项目类型：Web API / CLI / monorepo / 小程序 / 文档站
2. 读标准库 `playbook/principles.md`（原则）、`playbook/ci-minimum-gate.md`（CI/hook 必选）、`playbook/wechat-mp.md`（小程序主题）
3. 读项目已有 README / CLAUDE.md / AGENTS.md
4. 项目特例写在项目自己的 `CLAUDE.md`，不要复制整个标准库

## 审计 checklist（漏一项 = 不合格）

> **完整版**：[playbook/ci-minimum-gate.md §审计 checklist](../../playbook/ci-minimum-gate.md#审计-checklist)
> 这里是入口摘要；遇到具体项去 ci-minimum-gate.md 查模板。

### 仓库基础

- [ ] README、LICENSE（若开源）、.gitignore
- [ ] `.env.example`，无密钥进库
- [ ] Agent：CLAUDE.md（Claude Code）和/或 AGENTS.md

### Adapter（仅非 Claude Code 项目）

- [ ] 从 dev-standards 部署 `adapters/cursor/`（如适用）

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

## 按项目类型追加

**Monorepo** — 读 [references/monorepo.md](references/monorepo.md)；核对 ADR-0002 触发条件、`pnpm-workspace.yaml`、根编排 scripts、`apps/`/`packages/` 边界、组件独立版本
**Python API** — pyproject.toml、迁移策略、tests/ 布局
**Agent 友好 CLI** — 结构化子命令 + `--json`；domain Skill 放业务仓库
**微信小程序（原生 + TS）** — 读 [playbook/wechat-mp.md](../../playbook/wechat-mp.md) + [skills/wechat-mp/](../../skills/wechat-mp/SKILL.md)

## 初始化

```bash
# 1. 同步个人 Skills 到 Claude Code
~/AgentProjects/dev-standards/scripts/sync.sh skills

# 2. 部署 Cursor adapter 到项目（仅当项目用 Cursor 时）
~/AgentProjects/dev-standards/scripts/sync.sh adapters cursor /path/to/project

# 3. 部署 hooks 模板到项目（手动复制 .husky/ + commitlint.config + package.json 片段）
# 见 ci-minimum-gate.md §本地 pre-commit 配置

# 4. 装依赖并初始化 husky
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
- [../../playbook/wechat-mp.md](../../playbook/wechat-mp.md) — 小程序主题
- [../../playbook/audit-feedback-loop.md](../../playbook/audit-feedback-loop.md) — **循环审计 → 标准反馈**
