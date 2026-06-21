---
name: dev-bootstrap
description: Bootstrap or audit a software project against personal dev standards. Use when creating a new repo, onboarding to an existing project, asking "按我的标准初始化", "项目还缺什么", or setting up CLAUDE.md, CI, .cursor/rules, or directory layout. Make sure to use this whenever the user starts a new project or wants a standards checklist, even if they don't say "bootstrap".
---

# Dev Bootstrap

按个人标准库（`~/AgentProjects/dev-standards`）检查或初始化项目。

## 前置

1. 确认项目类型：Web API / CLI / monorepo / 小程序 / 文档站
2. 读标准库 `playbook/principles.md`（原则）和项目已有 README
3. 项目特例写在项目自己的 `CLAUDE.md`，不要复制整个标准库

## 检查清单

```
Bootstrap Progress:
- [ ] 仓库：README、LICENSE（若开源）、.gitignore
- [ ] 配置：.env.example，无密钥进库
- [ ] Agent：CLAUDE.md（Claude Code）和/或 AGENTS.md
- [ ] Adapter（仅非 Claude Code 项目）：从 dev-standards 部署 `adapters/cursor/`（如适用）
- [ ] 工具：lint/format/test 可本地运行
- [ ] CI：至少 lint + test（或说明为何跳过）
- [ ] 文档：developer-guide 或等价「如何跑起来」
- [ ] 发布：版本号策略 / CHANGELOG 或 releases/（若有对外发布）
```

## 按项目类型追加

**Monorepo** — 读 [references/monorepo.md](references/monorepo.md)；核对 ADR-0002 触发条件、`pnpm-workspace.yaml`、根编排 scripts、`apps/`/`packages/` 边界、组件独立版本  
**Python API** — pyproject.toml、迁移策略、tests/ 布局  
**Agent 友好 CLI** — 结构化子命令 + `--json`；domain Skill 放业务仓库

## 初始化

```bash
# 同步个人 Skills 到 Claude Code
~/AgentProjects/dev-standards/scripts/sync.sh skills

# 部署 Cursor adapter 到项目（仅当项目用 Cursor 时）
~/AgentProjects/dev-standards/scripts/sync.sh adapters cursor /path/to/project

# 部署 hooks 模板到项目
~/AgentProjects/dev-standards/scripts/sync.sh hooks /path/to/project
```

## 输出

完成后报告：已有项、缺失项（按优先级）、一条下一步建议。

## 参考

- [references/standards-overview.md](references/standards-overview.md)
- [references/monorepo.md](references/monorepo.md)
