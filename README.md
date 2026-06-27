# dev-standards

个人开发标准库（方案 B）：跨项目的规范、Skills、Hooks、Adapter 的**唯一真相来源**。

**一等公民**：Claude Code（Skills、hooks、CLAUDE.md）。
**Adapter**：Cursor 等其他 Agent/IDE 通过 `adapters/` 镜像兼容。

## 定位

| 层级 | 本仓库 | 消费位置 |
|------|--------|----------|
| 原则与 ADR | `playbook/` | 人读；Skill 引用 |
| 外部基线映射 | `playbook/baselines/` | 人读；principles / skills 引用 |
| 工作流 Skills | `skills/` | `~/.claude/skills/`（个人）或 `<project>/.claude/skills/`（项目） |
| Hooks 模板 | `hooks/` | `<project>/.claude/hooks/` |
| 项目模板（未来 C） | `templates/` | 新建仓库时复制 |
| Adapters | `adapters/<name>/` | `<project>/.cursor/rules/`（Cursor）等 |

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
│   ├── audit-feedback-loop.md  # 项目审计 → 标准反馈闭环
│   ├── api-error-codes.md # 跨项目 API 错误响应约定
│   ├── ci-minimum-gate.md # CI 必选 4 项 + 可选 4 项
│   ├── wechat-mp.md       # 微信小程序（原生 + TS）
│   ├── baselines/         # 外部行业基线映射（CNCF TAG / 12-Factor / …）
│   ├── INDEX.md           # 文档索引（含 ADR 仲裁顺序）
│   └── adr/               # 架构 / 标准决策记录
├── skills/                # Claude Code Skill 源码（一等公民）
│   ├── dev-bootstrap/
│   └── wechat-mp/
├── hooks/                 # Claude hooks 模板（一等公民）
├── adapters/              # 非 Claude Code Agent 的兼容镜像
│   └── cursor/            # Cursor rules（派生自 playbook/）
├── scripts/               # 同步 / 校验脚本
│   ├── sync.sh            # 入口
│   ├── lint.sh            # markdownlint + 链接 + 未决项扫描 + 孤儿
│   ├── adr-validate.sh    # ADR frontmatter
│   └── baselines-validate.sh  # baselines/ frontmatter + 过期
├── .markdownlint.json     # markdownlint 规则（line_length 120 等）
└── templates/             # 方案 C 预留
```

## 快速开始

```bash
# 1. 同步个人 Skills 到 Claude Code
./scripts/sync.sh skills

# 2. 把 Cursor adapter 部署到某个项目（仅当该项目用 Cursor 时）
./scripts/sync.sh adapters cursor /path/to/your-project

# 3. 部署 hooks 模板到某个项目
./scripts/sync.sh hooks /path/to/your-project

# 4. 校验标准库文档
./scripts/sync.sh validate

# 5. 全部
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

## 与 Claude Code 的对应关系

| Claude Code 概念 | 本仓库位置 | 说明 |
|------------------|------------|------|
| Project memory | 各项目 `CLAUDE.md` | 标准库提供模板，不放项目细节 |
| Skills | `skills/*/` | 扁平目录 + `SKILL.md`；复杂内容放 `references/` |
| Hooks | `hooks/` | 可选；敏感操作守卫（如发邮件、commit） |
| Subagents | 未来 `agents/` | 需要时再建 |
| 工具清单 | 各项目 `.claude/TOOLS.md` | 标准库不强制统一工具版本 |

个人级 Skill（跨所有项目）→ sync 到 `~/.claude/skills/`
项目级 Skill（仅某业务域）→ 留在业务仓库的 `.claude/skills/`，**不**放进 dev-standards

## 非 Claude Code Agent

通过 `adapters/<name>/` 镜像。详见 [adapters/README.md](adapters/README.md)。

当前支持的 adapter：Cursor（`adapters/cursor/`）。新增 adapter 步骤见该文件。

## 相关路径

- 个人 Skills（Claude Code）：`~/.claude/skills/`
- 个人 Skills（Cursor）：`~/.cursor/skills/`（与 Claude 可同名，内容需各自维护或脚本双写）
- 工作区示例：`~/AgentProjects/workspace/.claude/`
