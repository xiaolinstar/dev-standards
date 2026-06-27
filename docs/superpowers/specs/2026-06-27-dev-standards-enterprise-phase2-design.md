# dev-standards 企业化演进 — Phase 2 设计

- **日期**：2026-06-27
- **范围**：Phase 2（Skill / Hook 丰备 + Cursor 派生补全）
- **前置**：Phase 1 已完成（tag `phase-1-complete`）；Phase 1 后有机增量含 wechat-mp、audit-feedback-loop、CI 4 项升级
- **后续阶段**：Phase 3（Plugin 化打包 + 脚手架 templates）
- **状态**：Approved（待用户复核 spec 后进入 writing-plans）

---

## 1. 背景与目标

Phase 1 把 `dev-standards` 的**文档层**对齐到 CNCF TAG + 12-Factor，并建立 validators。Phase 1 后通过 ai-todo 循环审计又沉淀了：

- `playbook/wechat-mp.md` + ADR-0007 + `skills/wechat-mp/`
- `playbook/audit-feedback-loop.md`
- CI 最低门槛从 3 项升级为 **4 项 + 本地 Husky 双段**（ADR-0006 复审）

**缺口**：标准已写在 playbook，但**消费层未跟上**——

| 层 | Phase 1 后状态 | Phase 2 目标 |
|---|---|---|
| Cursor adapter | 仅 `core-principles.mdc` + `monorepo.mdc` | 派生 3 个主题 `.mdc` |
| `dev-bootstrap` | 有 CI/wechat 审计项 | 嵌入 baselines 检查 + `validate` 命令 |
| `hooks/` | 仅 `git-commit-guard.py` | 增加 pre-commit 模板目录 + 部署命令 |
| traceId 实现 | ADR-0005 后果段写「Phase 2 hooks」 | 提供 middleware 参考片段（非强制框架） |

**Phase 2 可交付定义**：Agent/IDE **能执行** Phase 1 写下的标准——Cursor 有对应 Rule、审计 Skill 能查 baselines、新项目能一键部署 pre-commit 模板。**不**做 Plugin 打包、**不**做完整 `templates/wechat-mp/` 脚手架。

---

## 2. 范围与非目标

### 2.1 In Scope

1. **Cursor adapter 主题派生**（3 个新 `.mdc`）
   - `api-error-codes.mdc` — 派生自 `playbook/api-error-codes.md`
   - `ci-minimum-gate.mdc` — 派生自 `playbook/ci-minimum-gate.md`（4 项 + Husky）
   - `wechat-mp.mdc` — 派生自 `playbook/wechat-mp.md`（目录 + CI 要点；细节仍引 Skill）

2. **`dev-bootstrap` 基线检查段**
   - checklist 增加「标准库自身健康」子段：`sync.sh validate`、baselines `last-reviewed`
   - `references/standards-overview.md` 链到 baselines README

3. **`hooks/` pre-commit 模板**
   - 新增 `hooks/pre-commit/` 目录：Husky + lint-staged + commitlint + gitleaks 片段
   - `sync.sh hooks-precommit <project>` 部署到目标项目（复制 `.husky/` + 配置片段 + README 说明）
   - 保留现有 `git-commit-guard.py` 不变

4. **traceId 参考片段**
   - 新增 `playbook/snippets/trace-id-middleware.md`（FastAPI / Express 最小示例）
   - 在 `api-error-codes.md` 与 ADR-0005 后果段链上；**不**新建 ADR

5. **文档与校验**
   - 更新 `playbook/INDEX.md`、`adapters/README.md`、`hooks/README.md`
   - 全部变更后 `bash scripts/sync.sh validate` exit 0

### 2.2 Out of Scope（推迟）

| 项 | 推迟到 | 理由 |
|---|---|---|
| Plugin manifest / Marketplace | Phase 3 | 需版本号与 changelog 策略 |
| `templates/wechat-mp/` 完整脚手架 | Phase 3 | 当前 ai-todo 可作参考实现 |
| Observability 集中化（Prometheus / OTel） | Phase 3 | baselines 缺口已标注 |
| schema 迁移 CI 强校验 | Phase 3 | 12-Factor 缺口项 |
| GitOps / Progressive Delivery | 触发条件满足时 | ADR-0004 已决定不采用 |
| Web 前端目录约定 | 第 2 个 Web 项目出现时 | principles 显式延后 |
| Claude ADR 创建提示 hook | 可选 backlog | 优先级低于 pre-commit 模板 |

### 2.3 不进入本仓库（边界不变）

- 业务 domain Skill（ai-todo CLI 等）
- 具体项目的 Husky 定制（路径分流、框架特例）
- 工具版本号统一

---

## 3. 架构

### 3.1 引用方向（延续 Phase 1）

```text
playbook/（真源）
  └─→ adapters/cursor/*.mdc（派生，语义可裁剪）
  └─→ skills/dev-bootstrap/（引用链接，不复制正文）
  └─→ hooks/pre-commit/（可部署片段，引用 ci-minimum-gate.md）
```

**禁止**：adapter 成为真源；Skill 复制整篇 playbook。

### 3.2 新增文件预览

```text
dev-standards/
├── .markdownlint.json              # Phase 2 前 Sprint 已加
├── adapters/cursor/
│   ├── api-error-codes.mdc         # 新
│   ├── ci-minimum-gate.mdc         # 新
│   └── wechat-mp.mdc               # 新
├── hooks/
│   ├── git-commit-guard.py         # 不动
│   └── pre-commit/                 # 新目录
│       ├── README.md
│       ├── husky-pre-commit.sh
│       ├── husky-commit-msg.sh
│       ├── commitlint.config.cjs
│       └── package.json.snippet
├── playbook/
│   └── snippets/
│       └── trace-id-middleware.md  # 新
└── scripts/
    └── sync.sh                     # 改：hooks-precommit 子命令
```

### 3.3 Cursor `.mdc` 派生规约

| 字段 | 规则 |
|---|---|
| `description` | 中文一句话 + 英文关键词 |
| `alwaysApply` | 原则类 true；主题类 false |
| `globs` | 主题类必填（如 `**/*.{ts,py}`、`apps/miniapp/**`） |
| 正文长度 | ≤ 80 行；超出则「详见 playbook/…」 |
| 底部 | 必须含真源路径一行 |

---

## 4. 验收清单

### 4.1 文件

- [ ] `adapters/cursor/api-error-codes.mdc`
- [ ] `adapters/cursor/ci-minimum-gate.mdc`
- [ ] `adapters/cursor/wechat-mp.mdc`
- [ ] `hooks/pre-commit/`（≥4 个模板文件 + README）
- [ ] `playbook/snippets/trace-id-middleware.md`
- [ ] `scripts/sync.sh` 含 `hooks-precommit` 子命令

### 4.2 修改

- [ ] `skills/dev-bootstrap/SKILL.md` — 基线检查子段
- [ ] `playbook/INDEX.md` — snippets 段 + adapter 表更新
- [ ] `playbook/api-error-codes.md` — 链到 traceId snippet
- [ ] `hooks/README.md` — pre-commit 部署说明
- [ ] `adapters/README.md` — 3 个新 `.mdc` 登记

### 4.3 校验

- [ ] `bash scripts/sync.sh validate` exit 0
- [ ] `bash scripts/sync.sh adapters cursor /tmp/smoke-project` 复制 5 个 `.mdc`
- [ ] `bash scripts/sync.sh hooks-precommit /tmp/smoke-project` 复制模板且不覆盖已有 `.husky/` 时给出 warning

---

## 5. 风险与缓解

| 风险 | 缓解 |
|---|---|
| `.mdc` 与 playbook 漂移 | 派生规约要求底部真源链；validate 链检查 |
| pre-commit 模板与项目栈冲突 | 模板为「最小集」；项目 CLAUDE.md 登记例外 |
| traceId 片段框架绑定 | 仅示例；正文声明「复制逻辑，适配框架」 |

---

## 6. Phase 3 衔接

- `templates/wechat-mp/` 从 ai-todo 提取
- Plugin manifest（`plugin.json` / changelog）
- baselines Observability 缺口落地
- `dev-bootstrap` 自动跑 validate 并解析输出
