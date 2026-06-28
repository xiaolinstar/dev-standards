# Adapters

> **可选派生层**：把 `playbook/` 转成 Cursor 的 `.mdc`（glob 作用域）。
> 跨工具通用说明用各项目 **AGENTS.md**；Claude 用 **CLAUDE.md**（`@AGENTS.md`）。
> 见 [playbook/agent-config.md](../playbook/agent-config.md)。

## 何时需要 adapter

| 情况 | 做法 |
|------|------|
| 规则全项目通用 | 只写 **AGENTS.md**，不必部署 adapter |
| 改 miniapp 时才加载 wechat 规则 | `sync.sh adapters cursor <project>` |
| 标准库主题更新 | 改 **playbook/** → 再 sync adapter |

**不对** Copilot / Windsurf / Continue 等逐工具维护 adapter。

## 当前 adapter

| Adapter | 目录 | 部署目标 | 命令 |
|---------|------|----------|------|
| Cursor | `adapters/cursor/` | `<project>/.cursor/rules/` | `sync.sh adapters cursor <project>` |

### `.mdc` 与 playbook 对应

| 文件 | 真源 |
|------|------|
| `core-principles.mdc` | `playbook/principles.md` |
| `monorepo.mdc` | `playbook/monorepo.md` |
| `api-error-codes.mdc` | `playbook/api-error-codes.md` |
| `ci-minimum-gate.mdc` | `playbook/ci-minimum-gate.md` |
| `wechat-mp.mdc` | `playbook/wechat-mp.md` |

原则：adapter 内容是派生镜像；**改动先改 playbook**，再 sync。

## 新增 adapter

仅当某 Agent **无法读 AGENTS.md** 且团队主力使用该工具时再考虑。默认不扩展。

若仍要新增：建 `adapters/<name>/` → 在 `sync.sh` 注册 → 更新本表。**不必**新建 ADR。
