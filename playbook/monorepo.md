# Monorepo 实践指南

> 选型见 [ADR-0002](adr/0002-monorepo-default-selection.md)。本文是「怎么做」。

## 快速判断

| 场景 | 推荐 |
|------|------|
| 一个 FastAPI 服务 | 单包，`pyproject.toml` 在根或 `src/` |
| API + CLI + 小程序 | pnpm monorepo |
| 文档站 + 无代码共享 | 单包或 docs 子目录即可，不必 monorepo |
| 10+ TS 包、CI >15min | 评估 Turborepo |

## 最小骨架

### `pnpm-workspace.yaml`

```yaml
packages:
  - "apps/*"
  - "packages/*"
```

按需添加 `allowBuilds`（原生依赖构建白名单）。

### 根 `package.json`

```json
{
  "name": "my-product",
  "version": "0.1.0",
  "private": true,
  "packageManager": "pnpm@11.5.2",
  "scripts": {
    "build": "pnpm -r build",
    "typecheck": "pnpm -r typecheck",
    "lint": "pnpm -r lint",
    "test:api": "cd apps/api && .venv/bin/python -m pytest -q"
  }
}
```

原则：

- 根 scripts **编排**子包，不写业务逻辑
- 跨栈命令（Python pytest、容器构建）可在根 scripts 显式 `cd apps/...`
- 每个子包应有 `build` / `typecheck` / `lint`（或 `test`）之一，保证 `pnpm -r` 可递归

### TypeScript 共享配置

根目录 `tsconfig.base.json` 放 `paths` 与严格编译选项；各子包 `tsconfig.json` 继承：

```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": { "rootDir": "src", "outDir": "dist" },
  "include": ["src"]
}
```

`packages/*` 用 `tsc -b` 产出声明文件；`apps/cli` 等可用 esbuild 打包并 **bundle** workspace 依赖（避免发布中间包）。

### Python 应用（`apps/api`）

- 独立 `pyproject.toml` + `.venv`（不进 git）
- 不注册为 pnpm package；由根 `package.json` scripts 调用
- VS Code：`python.defaultInterpreterPath` 指向 `apps/api/.venv`

## 包边界规则

**放进 `packages/`**

- 跨 app 共享的类型、schema、错误码
- HTTP/gRPC 客户端 SDK
- Agent/MCP 工具协议定义

**放进 `apps/`**

- 进程入口（FastAPI `__main__`、CLI `bin`、小程序）
- 仅本 app 使用的 UI、路由、部署配置

**放进根 `scripts/`**

- GitHub Actions / 部署脚本直接调用的检查工具
- 刻意**不**经过 `pnpm run`，降低 CI 对 monorepo 工具链的依赖

## 依赖方向

```text
apps/*  →  packages/*  →  (npm 外部依赖)
```

禁止：

- `packages/*` 依赖 `apps/*`
- `packages/a` 与 `packages/b` 循环依赖

## 常用命令

```bash
pnpm install                    # 根目录安装全部
pnpm --filter @scope/pkg build  # 单包构建
pnpm -r build                   # 全部构建
pnpm -r --parallel lint         # 并行 lint（包少时）
```

## 版本与发布

### L1：组件版本

每个可发布产物独立 SemVer，源文件：

| 产物 | 版本源 |
|------|--------|
| Node CLI / 小程序 | `apps/*/package.json` |
| Python API | `apps/api/pyproject.toml` |
| 共享库 | `packages/*/package.json` |

递增按**该组件**变更判断 patch/minor/major，不要求与其他组件同号。

### L2：Git release tag

- Annotated tag：`v1.2.0`
- 标识「部署了哪次 commit」，用于 CI/CD
- 与 L1 数字可以不一致

### L3：发布叙事

`docs/releases/vX.Y.Z.md` 写清本批各组件 L1 版本组合与兼容性。

## 新建 monorepo 检查清单

```text
Monorepo Progress:
- [ ] pnpm-workspace.yaml（apps/*, packages/*）
- [ ] 根 package.json：private、packageManager、编排 scripts
- [ ] tsconfig.base.json（有 TS 时）
- [ ] apps/ 与 packages/ 职责清晰，无反向依赖
- [ ] 各子包 name 符合 @scope 约定，内部依赖 workspace:*
- [ ] README 或 developer-guide 说明如何 install / build / test
- [ ] 多组件时：releases/compatibility 或等价兼容矩阵
- [ ] .gitignore：node_modules、dist、.venv
```

## 混合发布（多 artifact 不同节奏）

当 monorepo 内**服务端可 CI/CD 自动部署**、**客户端须人工 gate**（如微信小程序提审）时：

```text
main push → CI 构建全部 artifact + deploy-manifest（指纹）
         → 客户端人工上传/验收（体验版、提审）
         → 手动触发 CD，按 tag 部署服务端
         → post-deploy-verify；失败自动回滚
```

要点：

- 用 **manifest + digest** 关联「同一次 CI 的 API 镜像 + 小程序 dist」，而非「CI 绿了就部署」
- CD **不**默认 main 自动上生产（避免服务端先于客户端上线）
- 兼容矩阵：`docs/releases/compatibility.md` 记录已验证组合

参考实现：ai-todo `docs/ci-cd.md`、`docs/release-runbook.md`。

## 参考实现

- [ai-todo](https://github.com/xiaolinstar/ai-todo)：`apps/api`（Python）+ `apps/cli` + `apps/miniapp` + `packages/shared` 等
- **API 错误码 + traceId**（ADR-0005 Batch 0–6）：
  tag [`api-error-codes-migration-complete`](https://github.com/xiaolinstar/ai-todo/releases/tag/api-error-codes-migration-complete)
  · [api-error-codes.md §参考实现](api-error-codes.md#参考实现ai-todo-batch-06-已闭合)
