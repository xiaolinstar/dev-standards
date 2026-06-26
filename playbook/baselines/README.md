# 外部基线映射

> 本目录收录本仓**承认**的外部行业基线（CNCF TAG、12-Factor、OWASP 等），以及它们在本仓的"采用 / 落地 / 缺口"。

## 怎么读

每篇基线文件顶部是 YAML frontmatter，6 个字段：

| 字段 | 含义 |
|---|---|
| `baseline` | 基线名（如 `12-Factor App`） |
| `upstream` | 上游权威链接 |
| `upstream-version` | 上游版本号或"长期稳定" |
| `status` | `adopted`（直接采用）/ `adapted`（裁剪后采用）/ `observing`（仅观察）/ `deprecated`（弃用） |
| `deviation-count` | 本文件"缺口"段中链到的 ADR 数量（整型） |
| `last-reviewed` | 上次复核日期，格式 `YYYY-MM-DD` |

## 怎么改

1. **新增基线**：复制 `twelve-factor.md` 或 `cncf-tag-app-delivery.md` 作为骨架，按三段式填充；状态从 `observing` 起步，落地后再升 `adopted`/`adapted`。
2. **偏离基线**：在"缺口"段显式列出，写明理由；**必须**新建一篇 ADR 并在"缺口"段链上（ID + 标题），否则不算完成。
3. **基线变更**：上游公告或版本变化 → 评估影响 → 改 frontmatter / 缺口段；产出新 ADR。

## 与本仓其他文件的关系

| 文件 | 关系 |
|---|---|
| `../principles.md` | **正交**——principles 是 Agent/流程层；baselines 是行业基线层。冲突时由 ADR 仲裁。 |
| `../adr/` | baselines 的"缺口"段每条必须链到 ADR；ADR 引用 baselines 作为决策依据。 |
| `../../adapters/cursor/` | Cursor 规则**派生**自 principles + baselines；不允许反哺。 |
| `../../skills/` / `../../hooks/` | 流程层只**引用** baselines 链接，不复制内容。 |

## 复用模板（每条基线项的三段式）

```markdown
### [编号 / 标题]

**采用**：原文一条（或简短摘录）。

**落地**：本仓已用什么约定承接（链到 `playbook/<file>.md` 或 `principles.md §N`）。

**缺口 / ADR**：
- 偏离合规的地方 → ADR-NNNN（标题）
- 待 Phase N 实现的项 → [Phase N 计划链接]
```
