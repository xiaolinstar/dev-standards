# dev-standards 企业化演进 — Phase 3 设计

- **日期**：2026-06-28
- **范围**：Phase 3（Plugin 化 + 脚手架 templates）
- **前置**：Phase 2 完成（tag `phase-2-complete`）
- **状态**：Approved

---

## 1. 背景与目标

Phase 1–2 完成了 playbook 真源、Cursor 派生、pre-commit 模板与 traceId 片段。仍缺：

- `templates/wechat-mp/` — wechat-mp.md 与 ADR-0007 承诺的脚手架
- Claude Code **Plugin 打包** — 技能可安装分发，而非仅 `sync.sh skills`
- Observability 缺口 — baselines 标注 Phase 2/3 的结构化日志参考

**Phase 3 可交付**：`templates/wechat-mp/` 最小可跑 scaffold + `sync.sh template` + `.claude-plugin/plugin.json` + CHANGELOG + 结构化日志 snippet。

**不做的**：发布到 Anthropic 官方 marketplace、完整 ai-todo 业务代码复制、Prometheus/OTel 集中化。

---

## 2. In Scope

1. `templates/wechat-mp/` — 通用最小 scaffold（参考 ai-todo `apps/miniapp` 工程结构，无业务 domain）
2. `scripts/sync.sh template <name> <dest>` — 复制模板
3. `.claude-plugin/plugin.json` + `CHANGELOG.md` + `marketplace.json`（本地/自托管）
4. ADR-0008 — 激活 templates（链 ADR-0001 暂缓决策）
5. `playbook/snippets/structured-logging.md` — 结构化日志 + traceId 联动
6. 文档更新：INDEX、templates/README、dev-bootstrap、wechat-mp.md、ADR-0007

## 3. Out of Scope

- Web 前端 template
- Plugin 提交 claude-community 审核
- Observability 集中化（Prometheus / OTel collector）
- `dev-bootstrap` 自动解析 validate JSON 输出

---

## 4. 验收

- [ ] `bash scripts/sync.sh template wechat-mp /tmp/wmp` 产出完整目录
- [ ] `bash scripts/sync.sh validate` exit 0
- [ ] `.claude-plugin/plugin.json` 存在且 `name: dev-standards`
- [ ] tag `phase-3-complete`
