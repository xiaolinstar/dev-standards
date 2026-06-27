# 标准库概览

`~/AgentProjects/dev-standards` 是个人跨项目开发标准的**唯一真相来源**。

## 一等公民

| 路径 | 用途 | 消费方式 |
|------|------|----------|
| `playbook/principles.md` | L1 原则（短、稳定） | 人读；Skill/Adapter 引用 |
| `playbook/monorepo.md` | monorepo 目录、版本、命令 | 人读；monorepo 项目必读 |
| `playbook/audit-feedback-loop.md` | 项目审计 → 标准库反馈闭环 | 审计时必读 |
| `playbook/adr/` | 有争议的默认选择 | 版本化决策记录 |
| `playbook/baselines/` | 外部行业基线映射 | 人读；principles / skills 引用 |
| `skills/` | 工作流 Skill 源码 | `sync.sh skills` → `~/.claude/skills/` |
| `hooks/` | Claude hooks 模板 | `sync.sh hooks <project>` |

## 主题 playbook（跨项目技术约定）

| 文档 | ADR | 要点 |
|------|-----|------|
| [api-error-codes.md](../../../playbook/api-error-codes.md) | [0005](../../../playbook/adr/0005-api-error-code-convention.md) | 错误体 schema、`AUTH_*`/`VAL_*`/`BIZ_*`/`SYS_*`、traceId |
| [ci-minimum-gate.md](../../../playbook/ci-minimum-gate.md) | [0006](../../../playbook/adr/0006-ci-minimum-gate.md) | **必选 4 项**（lint / typecheck-or-test / secret scan / commitlint）+ 本地 Husky 双段 |
| [wechat-mp.md](../../../playbook/wechat-mp.md) | [0007](../../../playbook/adr/0007-wechat-miniprogram-baseline.md) | 原生 + TS 小程序目录、CI、MobX 状态 |

索引真源：[playbook/INDEX.md](../../../playbook/INDEX.md)

## Skills

| Skill | 用途 |
|-------|------|
| `dev-bootstrap/` | 新建 / 审计项目；checklist 含 CI 4 项 + 本地 hook |
| `wechat-mp/` | 小程序 domain 模式与坑点；决策以 `wechat-mp.md` 为准 |

## Adapters（派生镜像）

| 路径 | 用途 | 消费方式 |
|------|------|----------|
| `adapters/cursor/` | Cursor Rules（派生自 `playbook/principles.md` / `monorepo.md`） | `sync.sh adapters cursor <project>` |

Phase 2 计划派生更多主题 `.mdc`（api-error-codes、ci-minimum-gate、wechat-mp）。

## 边界

**放进标准库**：跨项目通用原则、工作流、编码底线。

**不放进标准库**：业务 domain（如 ai-todo CLI、SRE 变更流程）→ 留在各业务仓库的 `.claude/skills/`。

## 同步与校验

```bash
~/AgentProjects/dev-standards/scripts/sync.sh skills
~/AgentProjects/dev-standards/scripts/sync.sh adapters cursor /path/to/project
~/AgentProjects/dev-standards/scripts/sync.sh hooks /path/to/project
~/AgentProjects/dev-standards/scripts/sync.sh validate   # lint + ADR + baselines
```

## 沉淀流程

1. 复盘 — 重复 3 次以上的做法
2. 归类 — 原则 → playbook；写法 → adapters/；流程 → skills
3. ADR — 争议默认选择
4. 同步 — `sync.sh`
5. 迭代 — Agent 反复违反某条 → 补 Adapter / 缩短 Skill
6. 基线月扫 — `sync.sh validate`；`baselines/` 的 `last-reviewed` > 30 天需复核上游

审计 dev-standards 本身时，额外跑 validate 并检查 baselines 日期（见 dev-bootstrap §标准库健康检查）。

## 审计入口

- 初始化 / 合规检查 → [dev-bootstrap SKILL.md](../SKILL.md)
- 发现标准缺口 → [audit-feedback-loop.md](../../../playbook/audit-feedback-loop.md)（B/C 类反馈回标准库）
