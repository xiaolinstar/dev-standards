# 微信小程序项目标准（原生 + TypeScript）

> 决策见 [ADR-0007](adr/0007-wechat-miniprogram-baseline.md)。本文是"怎么用"。
>
> 适用对象：3+ 个原生微信小程序项目共享一套工程实践。跨端方案（Taro / uni-app）不在本标准范围。

## 适用范围

- **技术栈**：原生小程序（wxml / wxss / ts）+ TypeScript。
- **CI**：GitHub Actions（`miniprogram-ci`）。
- **场景**：单人 / 团队多项目、已上线需补差。

**不适用**：跨端框架、云开发为主、插件市场、硬件小程序。

## 立场摘要

| 维度            | 选型                                                  | 理由                                                                       |
| --------------- | ----------------------------------------------------- | -------------------------------------------------------------------------- |
| 语言            | TypeScript `strict: true`                             | 与 3 个项目体量匹配，无运行时开销                                          |
| 框架            | 原生（无 Taro/uni-app）                               | 3 项目均不需跨端，原生最轻                                                 |
| 状态管理        | MobX（推荐）/ zustand                                 | 轻量、无 boilerplate；避免 redux 模板                                      |
| 样式            | SCSS + BEM + 设计 token                               | 跨项目复用样式变量                                                         |
| 包管理          | pnpm                                                  | 与仓库 [monorepo.md](monorepo.md) 实践一致                                 |
| Lint            | ESLint + `@umijs/eslint-config` + Prettier            | 微信生态最广覆盖                                                           |
| 测试            | Jest + `miniprogram-automator`                        | automator 是微信官方 UI 自动化方案                                         |
| **提交规范** ⭐ | **conventional commits + commitlint + Husky（必选）** | 见 [ci-minimum-gate.md §必选 4 项](ci-minimum-gate.md)；自动生成 CHANGELOG |
| 异步 API        | `miniprogram-api-promise` 包                          | `wx.request` 原生是 callback，统一 Promise 化                              |
| 发布            | `miniprogram-ci`                                      | 官方 CI 工具，免本地微信开发者工具                                         |

**与基线冲突时**：以 [ADR-0007](adr/0007-wechat-miniprogram-baseline.md) 为准。

**审计必查项**（漏一项不合格）：见 [ci-minimum-gate.md §审计 checklist](ci-minimum-gate.md#审计-checklist)。

## Monorepo 嵌套（`apps/miniapp/`）

小程序位于 pnpm monorepo 内时，与本文「独立仓库根目录」结构的差异：

| 独立仓库                           | Monorepo 嵌套                                                  |
| ---------------------------------- | -------------------------------------------------------------- |
| 根 `pnpm lint`                     | 根 `pnpm check:wechat` 或 `pnpm --filter @scope/miniapp check` |
| 根 `.github/workflows/release.yml` | 常合并进 monorepo 根 `ci.yml`；**可不**单独 upload job         |
| `services/http.ts`                 | 可为 `miniprogram/lib/api.ts` 等等价路径                       |
| `scripts/bump-version.ts`          | 可为 `apps/miniapp/scripts/bump-version.mjs`                   |

**CI 上传开发版**（push main → miniprogram-ci）为推荐默认；若改用微信开发者工具手动上传，须在项目 `CLAUDE.md` 登记例外（见 [audit-feedback-loop.md](audit-feedback-loop.md)）。

脚手架未就绪前，可从 [ai-todo `apps/miniapp/`](https://github.com/xiaolinstar/ai-todo/tree/main/apps/miniapp) 复制工程实践，而非空 `templates/wechat-mp/`。

## 项目结构

```text
<project>/
├── miniprogram/                  # 源码（项目配置 project.config.json 指向此处）
│   ├── app.ts                     # App 入口
│   ├── app.json                   # 全局配置（pages / window / tabBar）
│   ├── app.wxss                   # 全局样式
│   ├── sitemap.json               # 索引配置
│   ├── pages/                     # 页面（每个子目录为一页）
│   │   └── <name>/
│   │       ├── <name>.ts
│   │       ├── <name>.wxml
│   │       ├── <name>.wxss
│   │       └── <name>.json
│   ├── components/                # 自定义组件
│   │   └── <name>/
│   ├── services/                  # API 客户端（含统一错误处理）
│   │   ├── http.ts                # wx.request 封装
│   │   └── <domain>/              # 按业务域分目录
│   ├── stores/                    # 全局状态（MobX store / zustand）
│   ├── utils/                     # 工具函数
│   └── types/                     # 跨页面/组件复用的类型
├── tests/
│   ├── unit/                      # Jest 单测
│   └── e2e/                       # automator UI 测试
├── .github/
│   └── workflows/
│       ├── ci.yml                 # lint + typecheck + test
│       └── release.yml            # 触发 miniprogram-ci upload
├── scripts/
│   └── bump-version.ts            # 同步 package.json → project.config.json
├── project.config.json            # 入库（不含 appid / 私钥）
├── project.private.config.json    # 不入库（appid / 私钥 / es6 设置）
├── tsconfig.json
├── .eslintrc.cjs
├── .prettierrc
├── .gitignore
├── CHANGELOG.md
├── CLAUDE.md                      # 项目级 L3：appid、API base URL、负责人
└── README.md
```

**关键约定**：

- `miniprogram/` 是源码根，与 `project.config.json` 的 `miniprogramRoot` 对齐
- `project.private.config.json` **必须**加入 `.gitignore`
- `services/http.ts` 统一走 [api-error-codes.md](api-error-codes.md) 约定的错误格式

## 代码风格

- **命名**：组件 PascalCase（`TodoItem`），页面/目录 kebab-case（`todo-list`），文件与目录同名。
- **样式类名**：BEM（`.todo-item__title--done`）。
- **类型**：所有 `Page({...})` / `Component({...})` 配 `interface IData / IProps`。
- **常量**：`UPPER_SNAKE_CASE`，集中在 `miniprogram/constants.ts`。
- **不引入**：`any`（除非对接原生回调且无类型）；`eval`；`new Function`。

## 分环境部署

| 环境              | 触发方式                                       | 微信后台         | 上传号策略                | 谁来审                 |
| ----------------- | ---------------------------------------------- | ---------------- | ------------------------- | ---------------------- |
| dev（开发版）     | push to `main`                                 | 开发版           | `1.0.${run_number}`       | 仅内部                 |
| trial（体验版）   | push tag `trial-v*` 或手动 `workflow_dispatch` | 体验版           | `1.0.${run_number}`       | 体验成员               |
| release（正式版） | GitHub Release 发布                            | 正式版（待审核） | `x.y.z`（CHANGELOG 同步） | 人工到微信后台提交审核 |

**关键点**：

- 体验版/正式版必须由人工到[微信公众平台](https://mp.weixin.qq.com/)提交审核，CI 只负责"上传"那一步。
- 三个环境的 `appid` 可不同（推荐 dev/trial 用同一 appid，release 用生产 appid）—— 项目级 CLAUDE.md 写明。

## 本地调试与微信工具豁免机制 (Local Debugging & DevTools Whitelist Bypass)

在本地联调时，小程序必须发起网络请求至本地开发环境。为了避开微信开发者工具对非白名单域名的拦截，需遵循以下实践：

1. **利用 `.localhost` 域名享受豁免策略**：
   - 微信开发者工具（基于 Chromium）对本地回环域名有一套特殊的信任规则：所有以 **`.localhost`** 结尾的域名（如 `ai-todo-api.localhost`）都会被强制判定为 loopback 回环地址。
   - 微信安全层对此类域名予以**豁免**。即便在微信开发者工具中**未勾选**「不校验合法域名」，网络请求依然可以畅通无阻，避免开发人员频繁因为该选项被重置而遇到拦截报错。
   - **最佳实践**：本地 API 开发的测试域名一律使用 `[app-name]-api.localhost`。避免使用 `.local` 等其他后缀，以规避微信工具的域名安全校验。

2. **本地 Storage 缓存穿透**：
   - 微信开发者工具对本地缓存（LocalStorage）的清理经常存在滞后。如果在开发过程中修改了代码中的 `LOCAL_API_URL` 变量，小程序在启动初始化时依然可能从 Storage 中读取到残留的历史 API 地址，从而产生“代码改了但依然请求旧地址”的现象。
   - **解决方案**：在代码的 `resolveDevelopApiUrl()` 逻辑中，当检测到为 `isDevtoolsSimulator()`
     模拟器开发环境时，**直接返回内存中的最新 `LOCAL_API_URL` 变量**，穿透并绕过 Storage 缓存读取。
   - **手动清理方式**：若遇到顽固域名不更新，可在开发者工具控制台（Console）执行 `wx.clearStorageSync()` 后重新编译。

## CI/CD（GitHub Actions 模板）

```yaml
# .github/workflows/ci.yml
name: ci
on:
  push:
    branches: [main]
  pull_request:
jobs:
  gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: pnpm/action-setup@v5
      - uses: actions/setup-node@v5
        with: { node-version: 24, cache: pnpm }
      - run: pnpm install --frozen-lockfile
      - run: pnpm lint # eslint
      - run: pnpm typecheck # tsc --noEmit
      - run: pnpm test # jest
      - run: pnpm secret-scan # gitleaks
      - run: pnpm build # tsc → miniprogram/

  upload-dev:
    needs: gate
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - run: npm i -g miniprogram-ci
      - run: miniprogram-ci upload \
          --pp dist/ \
          --pkp private.<APPID>.key \
          --appid ${{ secrets.WECHAT_APPID }} \
          --uv 1.0.${{ github.run_number }}
```

```yaml
# .github/workflows/release.yml
name: release
on:
  release: { types: [published] }
  workflow_dispatch:
jobs:
  upload-trial-or-release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - run: npm i -g miniprogram-ci
      - run: miniprogram-ci upload \
          --pp dist/ \
          --pkp private.<APPID>.key \
          --appid ${{ secrets.WECHAT_APPID }} \
          --uv ${{ github.event.release.tag_name || 'manual' }}
```

**3 个项目复用同一份**：把以上 yml 抽到 `templates/wechat-mp/.github/workflows/`，各项目从模板复制并改 `APPID` / secret 名。

## 版本策略

- **代码版本**（`package.json`）：semver `x.y.z`，由 `release-please`（或 `standard-version`）自动 bump。
- **小程序 versionName**（`project.config.json`）：与代码版本保持一致。
- **上传号**（CI 时传 `--uv`）：
  - dev：`1.0.${run_number}`
  - trial / release：`${tag}` 或 `${release.version}`
- **CHANGELOG**：从 conventional commits 自动生成；commit 规范：`feat: ...` / `fix: ...` / `chore: ...` / `BREAKING CHANGE:`。
- **同步脚本**：`scripts/bump-version.ts` 把 `package.json` 的 version 同步到 `project.config.json` 的 `versionName`，CI 走这一脚本。

## 安全

- **密钥**：`WECHAT_APPID` / `WECHAT_SETTING`（含 `private.<APPID>.key` 的 base64 编码）走 GitHub Secrets。
- **不入库**：`project.private.config.json`、`*.key`、`*.pem`、任何 `.env.local`。
- **pre-commit**：gitleaks（仓库级 hooks，详见 [ci-minimum-gate.md](ci-minimum-gate.md) §3）。
- **登录态**：`wx.login` 拿 `code` → 后端换 `token`；**不**在前端持久化 `session_key`。
- **接口鉴权**：业务 API 用后端签发 token，不直接用微信 `openid` 当唯一凭据（openid 在多 appid 不通用）。

## 缺口 / 已知偏差

| 缺口                                  | 缓解 / 计划                          | 链到                                                     |
| ------------------------------------- | ------------------------------------ | -------------------------------------------------------- |
| 3 个项目历史代码可能与本标准不一致    | `dev-bootstrap` 审计后逐项补差       | [skills/dev-bootstrap](../skills/dev-bootstrap/SKILL.md) |
| Taro / uni-app 项目不在本标准覆盖范围 | 跨端需求出现时新增 ADR               | 待                                                       |
| E2E 测试 automator 在 CI 中稳定性     | 暂不强制，列入可选检查               | 待 Phase 2                                               |
| 小程序码（QR）生成的 CI 自动化        | 当前手动；wxacode.get API 可后续接入 | 待 Phase 2                                               |

## 跑起来检查清单

新项目/补差时，按 [skills/dev-bootstrap](../skills/dev-bootstrap/SKILL.md) 走。**额外检查项**：

- [ ] `project.private.config.json` 在 `.gitignore` 中
- [ ] `scripts/bump-version.{ts,mjs}` 已加且 `pnpm bump-version`（或等价）可用，并同步 `project.config.json` → `versionName`
- [ ] `.github/workflows/ci.yml` 与 `release.yml` 来自 `templates/wechat-mp/`（或等效）
- [ ] `CHANGELOG.md` 由 release-please 维护
- [ ] 项目级 `CLAUDE.md` 含 appid、API base URL（dev/trial/release）、项目负责人
- [ ] 已部署 [wechat-mp domain skill](../skills/wechat-mp/SKILL.md)（仅本仓库内 `skills/` 目录存在时）

## 参考

- [ADR-0007](adr/0007-wechat-miniprogram-baseline.md) — 本标准的决策依据
- [principles.md](principles.md) — 通用原则
- [ci-minimum-gate.md](ci-minimum-gate.md) — CI 必选项
- [api-error-codes.md](api-error-codes.md) — API 错误格式
- [miniprogram-ci 官方文档](https://developers.weixin.qq.com/miniprogram/dev/devtools/ci.html)
- [微信小程序代码规范](https://developers.weixin.qq.com/miniprogram/dev/reference/)
