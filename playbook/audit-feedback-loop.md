# 循环审计与标准反馈

> 项目按 `dev-standards` 审计 → 确认问题 → **可沉淀的缺口反馈回标准库**。
> 入口 Skill：[skills/dev-bootstrap](../skills/dev-bootstrap/SKILL.md)；CI 清单：[ci-minimum-gate.md](ci-minimum-gate.md)。

## 何时走这条流程

- 对已有项目做合规审计（`dev-bootstrap` 模式）
- 审计发现「项目做法合理但标准未写」或「标准与参考实现冲突」
- ADR 升级后回溯参考实现（如 ai-todo）

## 循环步骤

```text
1. 读标准   → playbook/ + 相关 ADR + dev-bootstrap checklist
2. 审项目   → 按 checklist 逐项；严格模式：漏一项 = 不合格
3. 分类问题 → 见下表（A 本仓库 / B 标准库 / C 双方）
4. 确认     → 与用户或 Decider 确认 B/C 类是否应改标准
5. 双轨修复 → 项目 PR + dev-standards PR（可并行）
6. 闭环     → 更新 ADR 后果段 / 参考实现链接；下一轮审计验证
```

## 问题分类

| 类型 | 含义 | 修复落点 | 示例 |
|------|------|----------|------|
| **A** | 项目不符合已接受标准 | 业务仓库 PR | 缺 gitleaks CI job |
| **B** | 标准缺失、过时或与现实冲突 | `dev-standards` PR | wechat-mp 未写 monorepo 嵌套 |
| **C** | 双方都要动 | 两个 PR | ADR-0005 新前缀 + 项目渐进迁移 |

**B 类必须反馈到标准库**，否则下一轮审计重复报同一「假阳性」。

## 审计输出格式

```markdown
## 执行摘要
[合格 / 部分合格 / 不合格] + 一句话

## 本仓库待修复（A/C）
| # | 问题 | 严重度 | 修复建议 |

## 标准库待反馈（B/C）
| # | 问题 | 建议落点（文件/ADR） | 状态 |

## 合规评分卡
[ checklist 逐项 ✅/⚠️/❌ ]

## 下一步
一条具体动作（项目侧 or 标准侧）
```

## 反馈落点决策树

```text
原则/流程说不清？
  → playbook/principles.md 或 skills/dev-bootstrap/

跨项目技术约定？
  → playbook/<topic>.md（api-error-codes / ci-minimum-gate / wechat-mp / monorepo）

有争议的默认选择？
  → 新建 playbook/adr/NNNN-<slug>.md（Accepted 后改 playbook）

Cursor 写法派生？
  → adapters/cursor/*.mdc（真源仍在 playbook）

仅单项目特例、不上升通用标准？
  → 项目 CLAUDE.md + 可选「项目例外 ADR」链在 wechat-mp §已登记例外
```

## 参考实现与标准

| 角色 | 谁 | 注意 |
|------|-----|------|
| 参考实现 | [ai-todo](https://github.com/xiaolinstar/ai-todo)（monorepo + 混合发布） | **不等于**默认合规；审计以 ADR + checklist 为准 |
| 标准真源 | `dev-standards/playbook/` + `adr/` | ADR 优先于 playbook  prose |

**禁止**在 ADR 后果段写「项目已修复」除非对应 commit **已合入主分支**。应写「待合并 PR / 审计 checklist §N」。

## 已登记主题（由循环审计沉淀）

| 主题 | 文档 |
|------|------|
| API envelope 变体 + 迁移 | [api-error-codes.md §Envelope 变体](api-error-codes.md#envelope-变体兼容) |
| Monorepo 内嵌小程序 | [wechat-mp.md §Monorepo 嵌套](wechat-mp.md#monorepo-嵌套appsminiapp) |
| 混合发布（API CD + 客户端人工） | [monorepo.md §混合发布](monorepo.md#混合发布多-artifact-不同节奏) |
| lint-staged 路径分流 | [ci-minimum-gate.md §lint-staged](ci-minimum-gate.md#lint-staged-范围最小集) |

## 例外 ADR 最小模板

当项目**有意长期偏离**某主题标准（非补差 backlog）时，在项目或标准库登记：

```markdown
---
ID: NNNN（项目内可用 docs/tech-decisions.md 小节代替）
Title: <项目> 对 <标准> 的例外
Status: Accepted
Date: YYYY-MM-DD
---

## 偏离项
| 标准条款 | 项目做法 | 理由 |

## 复审
- 触发条件：…
- 下次复审日期：…
```

ai-todo 小程序上传方式等见 `apps/miniapp/CLAUDE.md` §与 wechat-mp.md 标准库的偏差。
