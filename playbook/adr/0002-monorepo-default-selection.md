---
ID: 0002
Title: Monorepo / 单包默认选型
Status: Accepted
Date: 2026-06-21
Deciders: xingxiaolin
---

## 背景

个人项目数量增加，部分仓库同时包含 API、CLI、小程序等多端产物，需要统一「何时用 monorepo、用什么工具、目录怎么摆」，避免每个新项目重新争论。

已在 [ai-todo](https://github.com/xiaolinstar/ai-todo) 验证 pnpm workspace + `apps/` / `packages/` 布局可行。

## 决策

### 默认：单包仓库

新建项目**默认单包**——根目录即唯一可部署/可发布单元（一个 `package.json` 或一个 `pyproject.toml`）。

### 升级为 monorepo 的触发条件（满足任一）

1. **≥2 个独立可运行产物**（如 API + CLI、Web + 移动端、服务 + SDK）
2. **≥2 个消费者需要共享 TypeScript 类型/客户端**（如 `shared` + `api-client`）
3. **同一 Git 仓库内需要独立版本与发布节奏**（组件 SemVer 不同步）

不满足以上条件时，不要提前建 `apps/` / `packages/` 空壳。

### 工具链

| 选择 | 决定 |
|------|------|
| 包管理 | **pnpm** + `pnpm-workspace.yaml` |
| 任务编排 | 根 `package.json` scripts + `pnpm -r` / `--filter` |
| 构建缓存 | **暂不引入** Turborepo / Nx（包数 <10 且 CI 可接受时） |
| 混合语言 | 各语言留在 `apps/<name>/` 自有工具链（如 Python 用 `.venv` + `pyproject.toml`） |

### 目录约定

```text
<repo>/
├── apps/           # 可部署、可安装、可打开的终端产物
│   ├── api/
│   ├── cli/
│   └── miniapp/
├── packages/       # 被 apps 引用的共享库（不单独对用户交付）
│   ├── shared/
│   └── api-client/
├── scripts/        # CI/运维脚本，可直接 node/python 调用，不经过 pnpm 包装
├── docs/
├── pnpm-workspace.yaml
├── package.json    # private；编排脚本；version 不代表产品版本
└── tsconfig.base.json   # 有 TS 共享包时放根目录
```

- `apps/`：面向用户或运维的边界（服务进程、CLI bin、小程序、未来原生 App）
- `packages/`：库边界（类型、客户端、Agent 协议）；**默认 `private: true`**
- 不放业务代码进根目录 `src/`（单包仓库除外）

### 包命名与依赖

- 内部包：`@<scope>/<short-name>`（如 `@ai-todo/shared`）
- 可公开发布的二进制：`@<publisher>/<product>-<role>`（如 `@xiaolinstar/ai-todo-cli`）
- workspace 依赖：`"workspace:*"`
- 根 `package.json` 必须 `"private": true`，并固定 `packageManager` 字段

### 版本模型（monorepo 内）

采用**组件独立 SemVer**（L1）+ **Git release tag**（L2）双轨，详见 `playbook/monorepo.md`：

- 各 `apps/*`、`packages/*` 维护自己的 `version`
- 根 `package.json` 的 `version` 仅表示仓库工具链，**不代表**产品或 API 版本
- Git tag（如 `v1.2.0`）标识「哪次 commit 被部署」，不强制各组件同号

## 理由

- 单包默认降低新建项目成本，符合 ADR-0001「方案 C 暂缓」
- pnpm workspace 已在 ai-todo 落地，无需第二套工具
- Turborepo/Nx 对个人项目过早；`pnpm -r` 足够
- `apps` / `packages` 语义清晰，与业界惯例一致
- 混合栈（TS + Python）不强行 npm 化 Python 部分

## 后果

- 单包项目复制 monorepo Rule 时，globs 不匹配则无影响
- 需要维护 `pnpm-workspace.yaml` 与根 scripts 作为编排入口
- 跨组件兼容性需文档化（如 `docs/releases/compatibility.md`）

## 备选方案

- **npm/yarn workspaces**：pnpm 安装快、依赖隔离好，已标准化
- **多仓库 + npm 发包**：共享类型需频繁发布，个人项目摩擦大
- **根目录多 `src` 无 workspace**：依赖与版本无法隔离，不采用
- **Turborepo 默认启用**：包数少时配置成本 > 收益
