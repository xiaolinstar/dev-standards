---
ID: 0006
Title: CI 最低门槛
Status: Accepted
Date: 2026-06-24
Supersedes: 3-项必选（2026-06-27 升级为 4-项 + 本地 pre-commit 必选）
Deciders: xingxiaolin
---

## 背景

CNCF TAG "CI/CD" 与 12-Factor V 都要求"任何合入都过流水线"。在 solo dev 场景下，完整 CI 平台（GitHub Actions 复杂 workflow / Jenkins / GitLab CI 高级功能）不必要；但**最低**门槛必须定义并强制。

2026-06-27 复审：审计 ai-todo 时发现，本 ADR 之前只规定 CI 段（3 项必选），未把"本地 pre-commit 配置"和"commit message 格式"列为必选，导致**项目可在 CI 表面合规、本地零防护**。

## 决策

### 必选项（4 项，**本地 + CI 双段**）

1. **lint** — 静态检查（代码风格 + 潜在 bug）
2. **typecheck or test** — TypeScript 走 `tsc --noEmit`；Python 走 `mypy` 或 `pytest`；Go 走 `go vet` + `go test`
3. **secret scan** — 防止密钥入库（**本段不允许只有 CI 段**）
4. **commit message format** — conventional commits（commitlint 强制）

### 必选：本地 pre-commit 配置

- 工具栈：**Husky 9 + lint-staged + commitlint**
- pre-commit hook：gitleaks 暂存区扫描 + lint-staged（eslint --fix + prettier --write）
- commit-msg hook：commitlint 编辑校验
- gitleaks 本地未装时**降级不阻断**（CI 兜底）
- 详见 [ci-minimum-gate.md §本地 pre-commit 配置](../ci-minimum-gate.md)

### 可选项（4 项）

1. test — 完整测试套件
2. build — 编译 / 打包 / 镜像构建
3. dep audit — 依赖漏洞扫描（`pip-audit` / `pnpm audit` / `npm audit`）
4. sbom — 软件物料清单生成

### 工具等价物表（必选项）

| 类别 | 备选 |
|---|---|
| lint (Python) | ruff / flake8 / pylint |
| lint (TS) | eslint / biome |
| lint (Go) | golangci-lint |
| typecheck (TS) | tsc --noEmit |
| typecheck (Python) | mypy / pyright |
| secret scan | gitleaks / trufflehog / detect-secrets |
| commit message | commitlint + @commitlint/config-conventional |
| hook 框架 | husky 9 / simple-git-hooks / lefthook |
| staged 处理 | lint-staged |

**不**强制具体工具；项目自选但必须**至少一项**。

## 升级历史

### 2026-06-27 升级

- 3 项 → **4 项**：新增 `commit message format`
- 新增必选 §"本地 pre-commit 配置"（Husky + lint-staged + commitlint）
- secret scan 从"建议本地+CI"升级为"**本段不允许只有 CI**"
- 新增 §审计 checklist（10 项），用于 `dev-bootstrap` 审计

**升级理由**：
- audit ai-todo 时发现项目零 pre-commit / commitlint / 本地 gitleaks，但 CI 表面满足 3 项必选 → 标准的"通过"判定有盲区
- commit message 不强制 → 无法自动生成 CHANGELOG，违反 §版本策略
- ai-todo 作为触发参考：补差项见 [audit-feedback-loop.md](../audit-feedback-loop.md)；**以项目 main 上 checklist 10 项为准**，不在 ADR 中声明「已修复」

## 后果

- `playbook/ci-minimum-gate.md` 据此落地（含本地 pre-commit 模板 + 审计清单）
- [skills/dev-bootstrap](../../skills/dev-bootstrap/SKILL.md) 审计清单同步升级
- 任何新项目 `dev-bootstrap` 时必须确保 4 项必选 + 本地 hook 装备（10 项审计清单）
- 等价物表是推荐而非强制；项目可用同类别其他工具
- **未来扩展**：5/6 项待 Phase N 评估（候选：依赖审计 SBOM、镜像扫描、E2E gate）
