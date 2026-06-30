# Pre-commit 模板（Husky + lint-staged + commitlint + gitleaks）

决策与完整说明见 [`playbook/ci-minimum-gate.md`](../../playbook/ci-minimum-gate.md)。

## 部署

```bash
~/AgentProjects/dev-standards/scripts/sync.sh hooks-precommit /path/to/project
```

写入目标项目：

| 产出 | 说明 |
|---|---|
| `.husky/pre-commit` | gitleaks + lint-staged |
| `.husky/commit-msg` | commitlint |
| `commitlint.config.cjs` | conventional commits |
| `.dev-standards-package.json.snippet` | 合并进根 `package.json` |
| `.dev-standards-precommit-README.md` | 本说明副本 |

若 `.husky/` 已存在，**不覆盖** hook 文件（仅 warning）。

## 安装后

```bash
cd /path/to/project
# 1. 合并 .dev-standards-package.json.snippet 到 package.json
# 2. monorepo 须按 ci-minimum-gate.md §lint-staged 调整路径分流，且 hook glob 与 CI format:check 对齐
pnpm install
pnpm exec husky   # 若 prepare 未自动跑
```

推荐本地安装 gitleaks：`brew install gitleaks`（macOS）。

## 与 Claude hooks 的区别

| 命令 | 目标 | 用途 |
|---|---|---|
| `sync.sh hooks-precommit` | `.husky/` + commitlint | Git commit 前 lint / secret scan |
| `sync.sh hooks` | `.claude/hooks/` | Claude Code PreToolUse 守卫 |
