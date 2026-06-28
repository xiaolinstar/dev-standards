# CI 最低门槛

> 决策见 [ADR-0006](adr/0006-ci-minimum-gate.md)。本文是"怎么用"。
> **审计项目时，按 §审计 checklist 走**（漏一项即不合格）。

## 立场

> **"本地 + CI 双段"是底线，不是建议。**
> 本地段：快速反馈，commit 前拦截。
> CI 段：兜底（防 `--no-verify` 绕过、防同事机器没装 hook）。
> **Secret Scan 双段尤其重要**（漏库 = 紧急事件）。

## 必选 4 项（local + CI 双段）

| # | 项 | 本地触发 | CI 触发 | 工具（推荐） |
|---|---|---|---|---|
| 1 | **Lint** | pre-commit（lint-staged） | PR / main push | ESLint / biome / golangci-lint / ruff |
| 2 | **Typecheck or Test** | — | PR / main push | tsc --noEmit / mypy / pytest / go test |
| 3 | **Secret Scan** | pre-commit（gitleaks） | PR / main push（**必跑**） | gitleaks / trufflehog / detect-secrets |
| 4 | **Commit Message Format** | commit-msg（commitlint） | — | commitlint + `@commitlint/config-conventional` |

### 1. Lint

- 静态检查（代码风格 + 潜在 bug）
- 本地：`lint-staged` 对暂存文件跑 `eslint --fix` + `prettier --write`
- CI：`pnpm lint` / `ruff check` 等价命令

### 2. Typecheck or Test

- 类型 / 行为正确性
- 项目无类型系统时降级为 test 套件
- 本地不强制（CI 必跑）

### 3. Secret Scan

- 防止 API key / 私钥 / token 入库
- **本地段：本地未装 gitleaks 时降级**（pre-commit 警告但不阻断，CI 兜底）
- **CI 段：阻断式**（secret 检出 = fail 整个 pipeline）

### 4. Commit Message Format

- 强制 [Conventional Commits](https://www.conventionalcommits.org/) 格式
- 本地段：`commitlint --edit` 在 commit-msg hook 跑
- 必含 type：`feat` / `fix` / `docs` / `style` / `refactor` / `perf` / `test` / `build` / `ci` / `chore` / `revert`
- 格式：`<type>(<scope>): <subject>`，subject ≤ 100 字符
- 配套好处：自动生成 CHANGELOG

## 本地 pre-commit 配置（必选）

所有项目必须配置本地 Git hooks。**首推栈**：Husky 9 + lint-staged + commitlint。

### 文件清单

| 路径 | 作用 |
|---|---|
| `.husky/pre-commit` | gitleaks 暂存区扫描 + lint-staged（eslint --fix + prettier --write） |
| `.husky/commit-msg` | commitlint 编辑校验 |
| `commitlint.config.{js,cjs}` | conventional commits 规则 |
| 根 `package.json` §`lint-staged` | staged 文件处理规则 |
| 根 `package.json` §`scripts.prepare` | `"prepare": "husky"`（pnpm install 时自动初始化） |

### pre-commit hook 模板

```sh
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh" 2>/dev/null || true

# 1. Secret scan (降级：本地未装 gitleaks 不阻断，CI 兜底)
if command -v gitleaks >/dev/null 2>&1; then
  gitleaks protect --staged --redact --no-banner || exit 1
else
  echo "⚠️  gitleaks 未装；CI 兜底（.github/workflows/ci.yml）"
fi

# 2. lint-staged
npx --no -- lint-staged
```

### commit-msg hook 模板

```sh
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh" 2>/dev/null || true
npx --no -- commitlint --edit "$1"
```

### commitlint.config.cjs 模板

```js
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'header-max-length': [2, 'always', 100],
    'type-enum': [2, 'always', [
      'feat', 'fix', 'docs', 'style', 'refactor', 'perf',
      'test', 'build', 'ci', 'chore', 'revert',
    ]],
  },
};
```

### lint-staged 范围（最小集）

**单包仓库**：

```json
{
  "lint-staged": {
    "**/*.{ts,tsx}": ["eslint --fix --max-warnings 0"],
    "**/*.{js,jsx}": ["eslint --fix"],
    "**/*.{json,md,yml,yaml}": ["prettier --write"]
  }
}
```

**pnpm monorepo**（按路径分流；**禁止**根目录无 eslint 配置时扫 `**/*.ts`）：

```json
{
  "lint-staged": {
    "apps/miniapp/**/*.ts": ["pnpm --filter @scope/miniapp exec eslint --fix --max-warnings 0"],
    "apps/cli/**/*.ts": ["pnpm --filter @scope/cli exec tsc -b tsconfig.json --pretty false"],
    "packages/**/*.ts": ["prettier --write"],
    "**/*.{json,md,yml,yaml,cjs}": ["prettier --write"]
  }
}
```

Python（`apps/api`）本地 hook 可选：`"apps/api/**/*.py": ["cd apps/api && python -m ruff check"]`（CI 必跑即可）。

参考实现：[ai-todo](https://github.com/xiaolinstar/ai-todo) 根 `package.json` §`lint-staged`。

**Gitleaks 本地安装**（推荐）：

```bash
# macOS
brew install gitleaks
# Linux
# 见 https://github.com/gitleaks/gitleaks#installation
```

## 可选 4 项

| 项 | 推荐触发 |
|---|---|
| test | CI（与 typecheck 并行） |
| build | CI（PR 阶段） |
| dep audit | CI（每日 / 每周） |
| sbom | release 时 |

## 流水线骨架（GitHub Actions 示例）

> **零告警要求：** 不得出现 `Node.js 20 is deprecated`。须 pin 声明 `node24` 的 action
> （如 `checkout@v6`、`gitleaks-action@v3`）；仅设 `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24` 无法消除告警。

```yaml
name: ci
on: [push, pull_request]
env:
  FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true
  NODE_VERSION: "24"
jobs:
  # 必选 3 + 1：scan-secrets → lint/typecheck → test → build
  scan-secrets:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with: { fetch-depth: 0 }
      - uses: gitleaks/gitleaks-action@v3

  gate:
    needs: [scan-secrets]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-node@v5
        with: { node-version: ${{ env.NODE_VERSION }} }
      - run: <lint>          # 必选 1
      - run: <typecheck-or-test>  # 必选 2
      - run: <test>          # 可选
      - run: <build>         # 可选
```

## 审计 checklist

`dev-bootstrap` 审计时，按此清单逐项检查。**漏一项 = 不合格**。

- [ ] `.husky/pre-commit` 存在，含 gitleaks（降级策略）+ lint-staged
- [ ] `.husky/commit-msg` 存在，含 commitlint
- [ ] `commitlint.config.{js,cjs}` 存在
- [ ] 根 `package.json` 含 `"prepare": "husky"`
- [ ] 根 `package.json` 含 `lint-staged` 配置（monorepo 须路径分流，见 §lint-staged）
- [ ] 根 `package.json` 含 `lint` script（或等价编排入口）
- [ ] 根或各 app 有可发现的 `format` / `format:check` 入口，且 README/CLAUDE.md 写明路径
- [ ] CI workflow 含 **gitleaks / secret-scan** job（阻断式）
- [ ] CI workflow 含 **lint** + **typecheck/test** job
- [ ] 项目最近 5 个 commit message 符合 conventional commits
- [ ] README 或 CLAUDE.md 写明"如何跑 lint / test / hook 初始化"

## 与 monorepo 的关系

- 根 `package.json` 的 `lint` / `typecheck` / `test` script 是上述命令的"编排入口"
- 各子包暴露等价 npm script，`pnpm -r lint` 可递归
- Python 子包（`apps/api`）的 `pytest` 由根 script 显式 `cd apps/api && ...` 触发
- **hook 配置在仓库根**（monorepo 的根目录就是 git 根）

## 三阶段门禁（Hooks → CI → CD）

| 阶段 | 回答的问题 | 阻断？ | dev-standards 模板 |
|------|------------|--------|-------------------|
| **1. 本地 hooks** | 本次 commit 有无 secret / 格式 / 暂存 lint 问题？ | 本地应阻断（gitleaks 可降级） | ✅ `hooks/pre-commit/` → `sync.sh hooks-precommit` |
| **2. CI** | 合并后全仓能否 lint / typecheck / test / build？制品可复现？ | **必须阻断** | ⚠️ 本文 §流水线骨架；复杂 monorepo 参考业务仓 |
| **3. CD** | 是否部署了正确版本？公网是否健康？ | 生产应阻断 | ❌ 无通用模板（domain 差异大） |

**职责边界：**

- Hooks **不跑**全量 typecheck / test（太慢）；CI **必须跑**。
- CI 产出**不可变制品**（镜像 digest、artifact SHA、deploy manifest）；CD **只消费**制品，不重新 build「最新 main」。
- CD 与 CI **分 workflow**；生产 CD 建议 **手动触发**（`workflow_dispatch`），尤其当客户端（小程序 / App）需人工提审时。

部署命令：`sync.sh hooks-precommit <project>`（阶段 1）。阶段 2/3 在业务仓 `.github/workflows/`，审计用 [dev-bootstrap](../skills/dev-bootstrap/SKILL.md)。

## Monorepo CI/CD 布局

### 推荐：workflow 在仓库根，job 按 app/栈拆分

```text
<repo>/
├── .husky/                    # 阶段 1：全仓唯一
├── .github/workflows/
│   ├── ci.yml                 # 阶段 2：一个 CI，内部并行 job
│   ├── cd.yml                 # 阶段 3：一个 CD（可选）
│   └── monitor.yml            # 运维拨测（可选）
├── apps/
│   ├── api/                   # 无 apps/*/.github/
│   ├── miniapp/
│   └── cli/
└── packages/
```

**不要**在每个 `apps/<name>/` 下各放一套 `.github/workflows/`，除非该 app 已完全独立发布且与 monorepo manifest 无关。

### CI job 命名惯例（并行 scan → build → test）

| Job 前缀 | 典型内容 | 对应 app |
|----------|----------|----------|
| `scan-secrets` | gitleaks，阻断后续 | 全仓 |
| `scan-node` | pnpm lint / typecheck | TS 子包 + CLI |
| `scan-api` | ruff / mypy / migration guard | `apps/api` |
| `scan-miniapp` | `check:wechat` 等 | `apps/miniapp` |
| `build-*` | 镜像 / artifact | 各栈 |
| `test-*` | pytest / e2e | 各栈 |
| `publish-manifest` | 仅 main；绑 fingerprint | 全仓 CD 输入 |

根 `package.json` 提供编排入口（如 `pnpm lint`、`pnpm test:api`、`pnpm check:wechat`）；各子包暴露 `lint` / `typecheck` / `build`。

### 何时才拆成多个 workflow

| 场景 | 做法 |
|------|------|
| 某 app 发布节奏完全独立、且不共享 deploy manifest | 可加 `release-<app>.yml` |
| 不同 environment 密钥 | CD job 级 `environment: staging \| production` |
| 移动端需 Xcode / Gradle | 独立 workflow 可以，仍放根 `.github/workflows/` |
| CI > 15min | path filter / Turborepo 缓存，优先于拆仓库 |

参考实现：业务仓 `docs/ci-cd.md` + `.github/workflows/ci.yml`（不在本库复制）。

## 环境、版本与密钥分层

> **环境密钥治理**：[env-management.md](env-management.md)（`~/.config/xiaolinstar`、键名校验、Agent 禁区）。
> 原则见 [principles.md](principles.md) §5、[twelve-factor.md](baselines/twelve-factor.md) §III。

### 四层模型（从提交到运行时）

```text
L0  仓库模板（可 commit）     *.env.example、docs/env/*.example.env
      ↓ 变量名 + 非敏感默认值；禁止真实密钥

L1  CI workflow              env:（非敏感）+ secrets.GITHUB_TOKEN 等
      ↓ 构建/测试用；不写入镜像层（12-Factor：配置进环境，不进镜像）

L2  GitHub Environments      staging / production 的 Variables + Secrets
      ↓ CD、Monitor 等 job 的 environment: 绑定；SSH、webhook、smoke PAT

L3  运行时（VPS / 容器）      apps/<app>/.env + .env.<env>
      ↓ 进程真正读取；DB URL、微信 AppSecret、JWT 等
```

| 层 | 放什么 | 不放什么 |
|----|--------|----------|
| **L0 模板** | 键名、默认端口、feature flag 默认 | 密码、AppSecret、私钥 |
| **L1 CI** | `NODE_VERSION`、`PYTHON_VERSION`、registry 地址 | 生产 DB 密码、部署 SSH 私钥 |
| **L2 GitHub Env** | `DEPLOY_HOST`、`CD_PUBLIC_API_URL`（Variables）；`DEPLOY_SSH_KEY`（Secrets） | 与 L3 重复且无必要的副本 |
| **L3 运行时** | 数据库 DSN、第三方 API 密钥、session 密钥 | 不应回写到 Git |

### 多版本 / 多环境命名

| 概念 | 建议 |
|------|------|
| **Git 版本** | tag `v0.x.y`；CD 输入 `release_tag` 指向 manifest |
| **运行时环境** | `local` / `staging` / `production`（或 `prod`）；与 GitHub Environment 名对齐 |
| **镜像 / 制品** | 不可变 digest（`sha256:…`）；manifest fingerprint 防篡改 |
| **小程序 / 客户端** | 独立 `package.json` version；与服务端 manifest 在发布手册中对齐 |

加载顺序（业务仓常见模式）：`.env`（共享非敏感默认）→ `.env.local` | `.env.staging` | `.env.production`（后者覆盖前者）。

### CI vs CD vs 容器：各用什么

| 场景 | 配置来源 | 示例 |
|------|----------|------|
| CI 构建 API 镜像 | workflow `env` + `secrets.GITHUB_TOKEN` | push GHCR；**不把** DB 密码 build-arg 进镜像 |
| CI 跑 pytest | 测试用 `.env.test` 或 job `env` 固定值 | 内存 DB / testcontainers |
| CD SSH 部署 | GitHub Environment **Secrets** | `DEPLOY_SSH_KEY`、`DEPLOY_PASSWORD` |
| CD 公网验收 | Environment **Variables** | `CD_PUBLIC_API_URL` |
| 容器启动 API | 宿主机 **L3** 文件挂载或 compose `env_file` | `APP_*` 读自 `.env.production` |
| Monitor 拨测 | Environment Variables + 可选 Secrets | `ALERT_*`、`CD_SMOKE_PAT` |

**禁止：** 在 workflow YAML 里写明文密钥；在 Docker 镜像 ENV 层 bake 生产 secret；在日志中打印 secret（gitleaks 双段即为此）。

### 审计 checklist（多环境，追加）

- [ ] 仓库有 `.env.example`（或等价），无真实密钥
- [ ] CI workflow 无 hardcoded secret；secret-scan job 阻断
- [ ] 生产 CD 使用 GitHub Environment（`environment: production`），非 repo 级 secret 混用
- [ ] 运行时密钥只在 L3（服务器文件 / 密钥管理），不在镜像
- [ ] staging / production Variables 分离（URL、阈值等）
- [ ] 文档说明各环境加载顺序与 `gh secret set --env` 示例

详见 [env-management.md](env-management.md) 与 [env-registry.yaml](env-registry.yaml)。业务仓示例：`docs/env/README.md`（ai-todo，**不复制进本库**）。

## 不在 CI 范围

- 端到端测试（Playwright / Cypress）→ 单独流水线
- 性能测试 → 单独流水线
- 部署 → 单独流水线（`Continuous Delivery` 子域）

## 与其他文档的关系

- [playbook/principles.md](principles.md) — L1 通用原则
- [playbook/api-error-codes.md](api-error-codes.md) — 错误格式（与 lint 规则联动）
- [playbook/wechat-mp.md](wechat-mp.md) — 小程序主题（含分环境、版本策略）
- [skills/dev-bootstrap/](../skills/dev-bootstrap/SKILL.md) — 项目审计 / 初始化入口
