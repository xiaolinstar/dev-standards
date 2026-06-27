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

```yaml
name: ci
on: [push, pull_request]
jobs:
  # 必选 3 + 1：scan-secrets → lint/typecheck → test → build
  scan-secrets:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - uses: gitleaks/gitleaks-action@v2

  gate:
    needs: [scan-secrets]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
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

## 不在 CI 范围

- 端到端测试（Playwright / Cypress）→ 单独流水线
- 性能测试 → 单独流水线
- 部署 → 单独流水线（`Continuous Delivery` 子域）

## 与其他文档的关系

- [playbook/principles.md](principles.md) — L1 通用原则
- [playbook/api-error-codes.md](api-error-codes.md) — 错误格式（与 lint 规则联动）
- [playbook/wechat-mp.md](wechat-mp.md) — 小程序主题（含分环境、版本策略）
- [skills/dev-bootstrap/](../skills/dev-bootstrap/SKILL.md) — 项目审计 / 初始化入口
