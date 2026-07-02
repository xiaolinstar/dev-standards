# 项目审计报告（Project Audits）

> 本目录归档对真实项目的基线符合度审计结果，用于**沉淀差距 → 驱动标准迭代**。
> 审计依据：[web.md](../web.md) + [h5-admin.md](../h5-admin.md) + [ADR-0011](../adr/0011-web-admin-baseline.md)。
> 审计流程见 [`audit-feedback-loop.md`](../audit-feedback-loop.md)。

## 索引

| 日期 | 项目 | 范围 | 状态 | 报告 |
|------|------|------|------|------|
| 2026-07-02 | drink-budget | `apps/admin` | ✅ 已审计 | [2026-07-drink-budget-admin.md](2026-07-drink-budget-admin.md) |
| 2026-07-02 | party-helper | `apps/admin` | ✅ 已审计 | [2026-07-party-helper-admin.md](2026-07-party-helper-admin.md) |
| 2026-07-02 | （合并） | 两份 admin 的迁移路径 | ✅ 已出 roadmap | [2026-07-admin-migration-roadmap.md](2026-07-admin-migration-roadmap.md) |

## 审计方法论

1. **基线锁定**：先把要审计的项目类型对应的 playbook（web.md / h5-admin.md / ADR-0011）作为唯一标尺。
2. **维度分解**：按 A 配置、B Tokens、C 布局、D 列表表单、E 按钮、F 错误处理、G 守卫、H 视图覆盖、I 部署 9 大维度逐项打分。
3. **证据驱动**：每条结论都引用 `file_path:line`，避免"感觉偏离"式主观判断。
4. **优先级分层**：
   - **P0 必修**：不修就跑偏规范（结构性 / 安全合规）
   - **P1 重要**：影响一致性、可维护性（约定遵守）
   - **P2 建议**：体验优化
5. **可执行**：每条 P0 必须给出具体修改文件 + 行号 + 替换内容，能直接落到 PR review。
6. **工作量估算**：按"删旧换新"和"原地 patch"两种粒度估算人日。

## 与标准库的反馈闭环

审计发现的**反复出现的差距**应回流到 `playbook/`：

- 例如 drink-budget 与 party-helper 都缺 Design Tokens → 强化 web.md §3
- 例如两份都缺 Vant 按需 → 在 web.md §2 标 ⚠️
- 例如两份都缺路由 `meta.title` 注入项目名 → h5-admin.md §4 显式要求

详见 [audit-feedback-loop.md](../audit-feedback-loop.md)。