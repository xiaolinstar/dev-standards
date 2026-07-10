# party-helper 核心仓库审计报告

> **审计日期**：2026-07-08
> **审计依据**：[ci-minimum-gate.md](../ci-minimum-gate.md)、[env-management.md](../env-management.md)、[wechat-mp.md](../wechat-mp.md)
> **结论摘要**：项目整体提交规范（Conventional Commits）和 CD 部署机制合规，
> 但在本地静态检查与 linter 门禁配置上存在多项重大偏离（缺失全局 ESLint 脚本、小程序 Git hook 中无 eslint 校验、
> 存在冗余的根目录微信配置文件、CLAUDE.md 缺失元数据等），需进行合规优化。

---

## 执行摘要

**部分合格**。Git 提交信息合规、CD 自动化部署支持正常。但在前端与小程序代码的规范校验上存在“宽门禁”偏离，亟需补齐全局 linter、小程序 hooks 中的 eslint 校验，并清理冗余的临时配置文件。

---

## 本仓库待修复（A/C）

| #     | 问题                                                                                 | 严重度      | 修复建议                                                                                                                                          |
| ----- | ------------------------------------------------------------------------------------ | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1** | **缺失全局/代码库级的 ESLint 脚本**<br>(根 `package.json` 的 `lint` 只跑了 prettier) | **P0 (高)** | 将根 `package.json` 中的 `"lint"` 修改为对整个代码库进行规范检查的脚本（例如 `eslint . --ext .ts,.tsx,.js,.jsx` 或 `pnpm -r lint`）。             |
| **2** | **小程序 hooks 缺失 `eslint` 校验**<br>(`lint-staged` 对小程序 ts 仅跑 prettier)     | **P0 (高)** | 在根 `package.json` 的 `lint-staged` 中，为 `apps/miniapp/` 补齐 ESLint 执行规则，且必须按照 monorepo 相对路径分流规则执行（与 `ai-todo` 对齐）。 |
| **3** | **冗余的根目录微信配置文件**<br>(根目录下存在 `project.config.json` 等)              | **P1 (中)** | 删除根目录下的 `project.config.json` 和 `project.private.config.json`，只保留 `apps/miniapp/` 下的主配置文件，防止 IDE 重复导入和冲突。           |
| **4** | **`CLAUDE.md` 项目元数据严重缺失**<br>(仅有 15 行，无 AppID、API URL等)              | **P1 (中)** | 按照 L3 基准，为根目录下 `CLAUDE.md` 补齐项目元数据（包含项目负责人、小程序 AppID、以及 dev/trial/release 各环境的 API 基础 URL 地址）。          |

---

## 合规评分卡

### 1. 本地 Hooks 与 Git 规范

- [✅] `.husky/pre-commit` 正常挂载。
- [✅] `.husky/commit-msg` 正常挂载。
- [✅] `commitlint.config.cjs` 存在于根目录。
- [✅] 根 `package.json` 包含 `"prepare": "husky"` 自启动脚本。
- [❌] **Linter 全局校验缺失**：`lint` 脚本仅校验 prettier 格式而不校验 eslint。
- [❌] **小程序 hook 缺失 eslint**：`lint-staged` 对小程序代码无 ESLint 门禁阻断。
- [✅] 最近 5 个 commit messages 均符合 Conventional Commits 规范。

### 2. CI/CD 流水线规范 (`ci.yml` / `cd.yml`)

- [✅] 包含阻塞式 `scan-secrets` (gitleaks-action) 阶段，且位于 Phase 0。
- [✅] 包含 `lint` 与 `typecheck` 等编译检测阶段。

### 3. 环境配置与密钥管理 (L0 - L3)

- [✅] 包含完整的 `.env.*.example` 环境变量定义。
- [✅] 运行时密钥均只保存在本地 L3 环境，未打包进 Docker 镜像层。

---

## 下一步

1. **修复根 `package.json` 的 `lint` 与 `lint-staged`**，补齐全局 linter 和小程序 ESLint 拦截。
2. **清理根目录下残留的 `project.*.json` 微信配置文件**。
3. **补全根目录 `CLAUDE.md` 项目元数据**。
