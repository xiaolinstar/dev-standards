# 标准库概览

`~/AgentProjects/dev-standards` 是个人跨项目开发标准的**唯一真相来源**。

## 一等公民

| 路径 | 用途 | 消费方式 |
|------|------|----------|
| `playbook/principles.md` | L1 原则（短、稳定） | 人读；Skill/Adapter 引用 |
| `playbook/monorepo.md` | monorepo 目录、版本、命令 | 人读；monorepo 项目必读 |
| `playbook/adr/` | 有争议的默认选择 | 版本化决策记录 |
| `skills/` | 工作流 Skill 源码 | `sync.sh skills` → `~/.claude/skills/` |
| `hooks/` | Claude hooks 模板 | `sync.sh hooks <project>` |

## Adapters（派生镜像）

| 路径 | 用途 | 消费方式 |
|------|------|----------|
| `adapters/cursor/` | Cursor Rules（派生自 `playbook/`） | `sync.sh adapters cursor <project>` |

未来新增的 adapter（Codex、Continue 等）放在 `adapters/<name>/`，命令同款 `sync.sh adapters <name> <project>`。

## 边界

**放进标准库**：跨项目通用原则、工作流、编码底线。

**不放进标准库**：业务 domain（如 ai-todo CLI、SRE 变更流程）→ 留在各业务仓库的 `.claude/skills/`。

## 同步命令

```bash
~/AgentProjects/dev-standards/scripts/sync.sh skills
~/AgentProjects/dev-standards/scripts/sync.sh adapters cursor /path/to/project
~/AgentProjects/dev-standards/scripts/sync.sh hooks /path/to/project
```

## 沉淀流程

1. 复盘 — 重复 3 次以上的做法
2. 归类 — 原则 → playbook；写法 → adapters/；流程 → skills
3. ADR — 争议默认选择
4. 同步 — `sync.sh`
5. 迭代 — Agent 反复违反某条 → 补 Adapter / 缩短 Skill
