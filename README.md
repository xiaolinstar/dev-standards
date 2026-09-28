# dev-standards

个人跨项目开发标准库：规范、Skills、Hooks、Adapter 的**唯一真相来源**（公开仓库，欢迎 fork 与按需裁剪）。

**一等公民**：通用 Agents 规范（`AGENTS.md`、`agents/` Subagents、`agentteams/`）+ Claude 生态（Skills、hooks）。  
**兼容层**：Cursor `.cursor/rules/` 等工具镜像（按需导出，见 [playbook/agent-config.md](playbook/agent-config.md)）。

## 定位

| 层级             | 本仓库                | 消费位置                                                       |
| ---------------- | --------------------- | -------------------------------------------------------------- |
| 原则与 ADR       | `playbook/`           | 人读；Agent 规则引用                                           |
| 外部基线映射     | `playbook/baselines/` | 人读；principles / skills 引用                                 |
| 通用 Agents 规范 | `AGENTS.md`           | 各项目根目录，跨 Agent 通用入口                                |
| 领域 Subagents   | `agents/`             | `~/.agents/` 或各 Agent 引擎，独立子 Agent 角色声明            |
| 多 Agent 协同    | `agentteams/`         | 复杂任务多 Agent (AgentTeam) 组队与工作流定义                  |
| 工作流 Skills    | `skills/`             | `~/.claude/skills/`（个人）或 `<project>/.claude/skills/`      |
| Agent 权限清单   | `permissions/`        | `sync.sh permissions` → 跨 Agent 自动化权限分发                |
| Hooks 模板       | `hooks/`              | `<project>/.claude/hooks/`                                     |
| 项目模板         | `templates/`          | `sync.sh template <name> <dest>`                               |
| Adapters (可选)  | `adapters/<name>/`    | `<project>/.cursor/rules/`（仅当需要 Cursor 特有 glob 规则时） |

**不是**业务代码仓库。各项目在自身 repo 里只保留「通用标准副本 + 项目特例」。

## 目录结构

```text
dev-standards/
├── CLAUDE.md              # Claude Code 入口（本仓库自用）
├── README.md              # 本文件
├── docs/
│   └── superpowers/       # 设计 spec / 实施 plan
├── playbook/
│   ├── principles.md      # L1 原则（Agent / 流程层）
│   ├── monorepo.md        # monorepo 实践
│   ├── agent-config.md    # 通用 AGENTS + Subagents 体系维护
│   ├── audit-feedback-loop.md  # 项目审计 → 标准反馈闭环
│   ├── api-error-codes.md # 跨项目 API 错误响应约定
│   ├── ci-minimum-gate.md # CI 必选 4 项 + 可选 4 项
│   ├── wechat-mp.md       # 微信小程序（原生 + TS）
│   ├── ios.md             # iOS 原生（SwiftUI + Liquid Glass）
│   ├── baselines/         # 外部行业基线映射（CNCF TAG / 12-Factor / …）
│   ├── INDEX.md           # 文档索引（含 ADR 仲裁顺序）
│   └── adr/               # 架构 / 标准决策记录
├── agents/                # 领域 Subagents 角色定义（一等公民）
│   ├── auditor/
│   ├── dev-bootstrap/
│   └── env-ops/
├── agentteams/            # 多 Agent 协同规范 (AgentTeam)
│   ├── project-audit-team.md
│   └── feature-refactor-team.md
├── skills/                # Claude Code / Agent Skill 源码
│   ├── dev-bootstrap/
│   ├── agent-permissions/
│   ├── wechat-mp/
│   ├── h5/
│   └── ios/
├── permissions/           # 跨 Agent check/deny 规则真源
│   ├── manifest.json
│   └── overlays/        # 项目特例（如 ai-todo.json）
├── hooks/                 # Claude hooks 模板
│   ├── git-commit-guard.py
│   └── pre-commit/        # Husky 模板（hooks-precommit 部署）
├── adapters/              # 工具特有兼容镜像（可选）
│   └── cursor/            # 7 个 .mdc（派生自 playbook/）
├── scripts/               # 同步 / 校验脚本
│   ├── sync.sh            # 入口
│   ├── permissions-sync.mjs  # permissions 分发
│   ├── lint.sh            # markdownlint + 链接 + 未决项扫描 + 孤儿
│   ├── adr-validate.sh    # ADR frontmatter
│   └── baselines-validate.sh  # baselines/ frontmatter + 过期
├── .markdownlint.json     # markdownlint 规则（line_length 120 等）
├── .claude-plugin/        # Claude Code plugin manifest（v3.1.0）
├── marketplace.json       # 自托管 plugin marketplace
├── CHANGELOG.md           # Plugin / 标准库版本变更
├── templates/             # 项目脚手架（wechat-mp / h5-admin 已激活）
│   ├── wechat-mp/
│   └── h5-admin/
```

## 快速开始

```bash
# 1. 同步个人 Skills 到 Claude Code
./scripts/sync.sh skills

# 2. 同步跨 Agent 权限清单（check/deny 免审批规则）
./scripts/sync.sh permissions --user

# 3. 把 Cursor adapter 部署到某个项目（仅当该项目用 Cursor 时）
./scripts/sync.sh adapters cursor /path/to/your-project

# 4. 部署 hooks 模板到某个项目
./scripts/sync.sh hooks-precommit /path/to/your-project
./scripts/sync.sh hooks /path/to/your-project   # Claude PreToolUse（可选）

# 5. 从模板新建小程序项目
./scripts/sync.sh template wechat-mp /path/to/your-miniapp

# 6. 校验标准库文档
./scripts/sync.sh validate

# 7. 全部
./scripts/sync.sh all /path/to/your-project
```

## 沉淀流程

1. **复盘** — 从最近项目提取重复 3 次以上的做法
2. **归类** — 原则 → `playbook/`；编码约定 → `adapters/cursor/`（仅 Cursor）；流程 → `skills/`
3. **ADR** — 有争议的默认选择写 `playbook/adr/NNNN-*.md`
4. **同步** — `./scripts/sync.sh` 推到本机；业务项目按需部署 adapter / hooks
5. **迭代** — 每月扫一遍：Agent 是否反复违反某条？→ 补 Rule 或缩短 Skill
6. **基线月扫** — 每月跑 `bash scripts/sync.sh validate`；`last-reviewed` > 30 天的 baselines/ 文件要重读上游并复核

## 外部基线

行业基线对齐见 [`playbook/baselines/`](playbook/baselines/README.md)。当前覆盖：

- [CNCF TAG App Delivery](playbook/baselines/cncf-tag-app-delivery.md) — CI/CD、Continuous Delivery、GitOps、Progressive Delivery、Observability
- [12-Factor](playbook/baselines/twelve-factor.md) — Codebase / Dependencies / Config / …

新增基线流程见 `playbook/baselines/README.md` §怎么改。

## 与 Agents 规范的对应关系

| Agent 规范概念      | 本仓库位置         | 说明                                         |
| ------------------- | ------------------ | -------------------------------------------- |
| **Project Context** | 各项目 `AGENTS.md` | 跨 Agent 通用说明与规范入口                  |
| **Claude Entry**    | 各项目 `CLAUDE.md` | 首行 `@AGENTS.md` + Claude 专有补充          |
| **Subagents**       | `agents/*/`        | 领域子 Agent 角色声明与 Prompt Specification |
| **AgentTeam**       | `agentteams/*/`    | 多 Agent 协同工作流与组队策略                |
| **Skills**          | `skills/*/`        | 工作流能力包（`SKILL.md` 规范）              |
| **Hooks**           | `hooks/`           | PreToolUse 守卫与 Git Hooks 模板             |
| **Permissions**     | `permissions/`     | 跨 Agent shell 命令免审批 Allowlist 真源     |

个人级 Skill（跨所有项目）→ sync 到 `~/.claude/skills/`
项目级 Skill（仅某业务域）→ 留在业务仓库的 `.claude/skills/`，**不**放进 dev-standards

## 非 Claude Code Agent

通过 `adapters/<name>/` 镜像。详见 [adapters/README.md](adapters/README.md)。

当前支持的 adapter：Cursor（`adapters/cursor/`）。新增 adapter 步骤见该文件。

## 相关路径

- 个人 Skills（Claude Code）：`~/.claude/skills/`
- 个人 Skills（Cursor）：`~/.cursor/skills/`（与 Claude 可同名，内容需各自维护或脚本双写）
- 工作区示例：`~/AgentProjects/workspace/.claude/`
