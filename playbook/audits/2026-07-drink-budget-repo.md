# drink-budget 核心仓库审计报告

> **审计日期**：2026-07-08
> **审计依据**：[ci-minimum-gate.md](../ci-minimum-gate.md)、[env-management.md](../env-management.md)、[wechat-mp.md](../wechat-mp.md)
> **结论摘要**：项目整体合规度很高，本地 Git Hooks、提交规范（Conventional Commits）、CI/CD 扫描机制健全。
> 存在少数需要微调与优化的偏离项（主要是 `lint-staged` 未进行 monorepo 相对路径分流）。

---

## 执行摘要

**基本合格**。本地与 CI 流水线的提交规范校验、敏感词扫描（Gitleaks）运行正常，版本策略对齐基本符合标准。需要对 `lint-staged` 进行相对化分流优化以避免子模块 ESLint 上下文污染。

---

## 本仓库待修复（A/C）

| #     | 问题                                                      | 严重度      | 修复建议                                                                                                                                                                                     |
| ----- | --------------------------------------------------------- | ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1** | **`lint-staged` 路径未分流**<br>(在根目录全局调用 eslint) | **P1 (中)** | 重构根 `package.json` 中的 `lint-staged` 配置，采用类似 `ai-todo` 的 `bash -c 'cd apps/... && files=...; pnpm exec eslint ...'` 形式进行子应用路径剥离与分流，以保证 ESLint 规则环境的隔离。 |

---

## 合规评分卡

### 1. 本地 Hooks 与 Git 规范

- [✅] `.husky/pre-commit` 存在，并包含了 gitleaks 扫描与 lint-staged 执行。
- [✅] `.husky/commit-msg` 存在，并正确集成了 commitlint。
- [✅] `commitlint.config.cjs` 存在于根目录且配置正确。
- [✅] 根 `package.json` 包含 `"prepare": "husky"` 自启动脚本。
- [⚠️] `lint-staged` 配置缺乏 monorepo 的子模块路径隔离。
- [✅] 最近 5 个 commit messages 均符合 Conventional Commits 规范。

### 2. CI/CD 流水线规范 (`ci.yml` / `api-ci.yml`)

- [✅] 包含阻塞式的 `Scan secrets` (gitleaks-action) 步骤。
- [✅] 包含并行的 ESLint、Prettier 静态检查与 tsc 编译检查。
- [✅] 包含 pytest 和 vitest 单元测试运行阶段。

### 3. 环境配置与密钥管理 (L0 - L3)

- [✅] 拥有完整的 `.env.example` 环境变量定义，且无敏感数据泄露。
- [✅] 运行时密钥均只保存在本地 L3 环境，未打包进 Docker 镜像层。

---

## 下一步

1. **重构根 `package.json` 的 `lint-staged` 配置**：为 `apps/miniapp/` 和 `apps/admin/` 等子应用建立相对路径剥离的 linter 执行规则。
