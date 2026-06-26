---
ID: 0006
Title: CI 最低门槛
Status: Accepted
Date: 2026-06-24
Deciders: xingxiaolin
---

## 背景

CNCF TAG "CI/CD" 与 12-Factor V 都要求"任何合入都过流水线"。在 solo dev 场景下，完整 CI 平台（GitHub Actions 复杂 workflow / Jenkins / GitLab CI 高级功能）不必要；但**最低**门槛必须定义并强制。

本 ADR 决定 CI 必选项与可选项。

## 决策

### 必选项（3 项）

1. **lint** — 静态检查（代码风格 + 潜在 bug）
2. **typecheck or test** — TypeScript 走 `tsc --noEmit`；Python 走 `mypy` 或 `pytest`；Go 走 `go vet` + `go test`
3. **secret scan** — 防止密钥入库

### 可选项（4 项）

4. test — 完整测试套件
5. build — 编译 / 打包 / 镜像构建
6. dep audit — 依赖漏洞扫描（`pip-audit` / `pnpm audit` / `npm audit`）
7. sbom — 软件物料清单生成

### 工具等价物表（必选项）

| 类别 | 备选 |
|---|---|
| lint (Python) | ruff / flake8 / pylint |
| lint (TS) | eslint / biome |
| lint (Go) | golangci-lint |
| typecheck (TS) | tsc --noEmit |
| typecheck (Python) | mypy / pyright |
| secret scan | gitleaks / trufflehog / detect-secrets |

**不**强制具体工具；项目自选但必须**至少一项**。

## 后果

- `playbook/ci-minimum-gate.md` 据此落地。
- 任何新项目 `dev-bootstrap` 时必须确保 3 项必选 CI 步骤（Phase 2 加 Skill 校验）。
- 等价物表是推荐而非强制；项目可用同类别其他工具。