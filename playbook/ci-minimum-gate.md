# CI 最低门槛

> 决策见 [ADR-0006](adr/0006-ci-minimum-gate.md)。本文是"怎么用"。

## 必选 3 项

任何合入主干的操作必须触发以下三项检查，**全部通过**才允许 merge：

### 1. Lint

- **目的**：风格统一 + 潜在 bug 捕获
- **触发**：pre-commit + CI
- **工具**：见 ADR-0006 §工具等价物表

### 2. Typecheck or Test

- **目的**：类型 / 行为正确性
- **触发**：CI
- **降级**：项目无类型系统时降级为 test 套件

### 3. Secret Scan

- **目的**：防止 API key / 私钥 / token 入库
- **触发**：pre-commit + CI
- **工具**：gitleaks（推荐）/ trufflehog / detect-secrets

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
  gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4  # 或 setup-python / setup-go
        with: { ... }
      - run: <lint>          # 必选
      - run: <typecheck-or-test>  # 必选
      - run: <secret-scan>   # 必选
      - run: <test>          # 可选
      - run: <build>         # 可选
```

## 与 monorepo 的关系

- 根 `package.json` 的 `lint` / `typecheck` / `test` script 是上述命令的"编排入口"
- 各子包暴露等价 npm script，`pnpm -r lint` 可递归
- Python 子包（`apps/api`）的 `pytest` 由根 script 显式 `cd apps/api && ...` 触发

## 不在 CI 范围

- 端到端测试（Playwright / Cypress）→ 单独流水线
- 性能测试 → 单独流水线
- 部署 → 单独流水线（`Continuous Delivery` 子域）