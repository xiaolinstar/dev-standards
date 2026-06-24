# dev-standards 企业化演进 — Phase 1 设计

- **日期**：2026-06-24
- **范围**：Phase 1（基线对位 + 原则补全）
- **后续阶段**：Phase 2（Skill / Hook 丰备）→ Phase 3（Plugin 化打包）
- **状态**：Approved（待用户最终复核 spec 后进入 writing-plans）

---

## 1. 背景与目标

`dev-standards` 是个人跨项目的开发标准源仓库（CLAUDE.md 已定义边界）。当前形态覆盖了：原则、monorepo 实践、1 个 Skill、1 个 Hook、Cursor adapter、sync 脚本。

本次演进把它从"够用的个人集合"提升为**对位行业基线的企业级个人标准库**。明确**只升个人跨项目这一个目标用户**——不引入多租户 / 角色权限 / 审计等企业 IT 概念。

外部骨架选 **CNCF TAG App Delivery + 12-Factor**——这是与"架构·质量·依赖 / 安全·合规·隐私 / 可观测·可靠性·性能 / 流程·治理·交付"四维全覆盖最贴合的两个开放行业基线。

**Phase 1 的可交付定义**：基线映射就位、原则缺口补齐、关键决策有 ADR 兜底。**不**做 Skill/Hook 重构，**不**做 Plugin 打包。

---

## 2. 范围与非目标

### 2.1 In Scope（Phase 1 必须完成）

- 新建 `playbook/baselines/` 目录，含 README + 2 篇基线映射
- 新建 2 篇主题 playbook：`api-error-codes.md`、`ci-minimum-gate.md`
- 新建 4 篇 ADR（0003–0006）
- 修改 `principles.md` / `INDEX.md` / `README.md` / `CLAUDE.md` / `adapters/cursor/core-principles.mdc`
- 新建/扩 3 个验证脚本（`baselines-validate.sh` / `adr-validate.sh` / `lint.sh`）
- `sync.sh` 加 `validate` 子命令

### 2.2 Out of Scope（明确推迟）

- Skill（`dev-bootstrap`）升级 → Phase 2
- 新增 / 改写 Hook → Phase 2
- Cursor `.mdc` 全量派生同步 → Phase 2（Phase 1 仅加指针）
- 前端 / 小程序目录约定 → 延后到"出现第 2 个前端项目"时启动
- Plugin manifest 打包 / Marketplace 发布 → Phase 3
- GitOps / progressive delivery 等实操配置 → Phase 2/3

### 2.3 不进入本仓库（CLAUDE.md 边界）

- 具体业务项目的 domain 知识（如 ai-todo CLI 细节）
- 个人项目特例的覆盖规则
- 工具版本号统一

---

## 3. 架构与目录

### 3.1 总览

```
dev-standards/
├── CLAUDE.md                                  # 改：加 baselines 引用
├── README.md                                  # 改：更新目录图
├── docs/superpowers/specs/                    # 本 spec 所在
├── playbook/
│   ├── principles.md                          # 改：清 2 项 + 延后 1 项 + 加指针
│   ├── monorepo.md                            # 不动
│   ├── api-error-codes.md                     # 新
│   ├── ci-minimum-gate.md                     # 新
│   ├── INDEX.md                               # 改：加 baselines / 新 ADR
│   ├── adr/
│   │   ├── 0001-…  0002-…                     # 不动
│   │   ├── 0003-12-factor-adaptation.md        # 新
│   │   ├── 0004-cncf-tag-app-delivery-adoption.md  # 新
│   │   ├── 0005-api-error-code-convention.md   # 新
│   │   └── 0006-ci-minimum-gate.md             # 新
│   └── baselines/                             # 新目录
│       ├── README.md                          # 新
│       ├── twelve-factor.md                   # 新
│       └── cncf-tag-app-delivery.md           # 新
├── adapters/cursor/
│   ├── core-principles.mdc                    # 改：底部加指针
│   └── monorepo.mdc                           # 不动
├── skills/dev-bootstrap/                      # Phase 1 不动
├── hooks/                                     # Phase 1 不动
├── scripts/
│   ├── sync.sh                                # 改：加 validate 子命令
│   ├── lint.sh                                # 新
│   ├── adr-validate.sh                        # 新
│   └── baselines-validate.sh                  # 新
└── templates/                                 # 不动
```

### 3.2 层级职责矩阵

| 层级 | 关心什么 | 不关心什么 |
|---|---|---|
| `principles.md` | Agent/流程（最小scope、Agent边界、文档分层…） | 具体技术栈、CI 工具、部署平台 |
| `playbook/*-*.md`（主题） | 跨项目的技术约定（API 错误码、CI 门槛…） | Agent 流程 |
| `baselines/*.md` | 外部行业基线在本仓的"采用 / 落地 / 缺口" | Agent 流程 / 具体技术选型 |
| `adr/` | 关键决策与偏离（含"为什么不全盘照搬"） | 当前已稳定的具体规则 |
| `adapters/cursor/` | 把上面内容**派生**为 Cursor 规则 | 新的源材料 |
| `skills/` / `hooks/` | 流程与守卫 | 原则本身（只引用） |

### 3.3 引用方向（唯一）

```
外部源
  └─→ baselines/  (摘录 + 落地裁剪)
        └─→ adr/  (决策时引用)
              └─→ adapters/cursor/ + skills/ + hooks/  (派生 / 引用)
```

**禁止**：
- Skill / Hook / Adapter **复制** playbook 内容（只引链接）
- Adapter 与 Skill **互相** 复制
- ADR **引用** Skill/Hook 的临时细节（只引 playbook / baselines）

**例外**：Cursor `.mdc` 可做格式裁剪以适配 Cursor 规则语法（alwaysApply / description），但语义内容必须能链回 playbook。

---

## 4. 新增/修改文件规约

### 4.1 `playbook/baselines/README.md`

- 解释 baselines/ 目录的"怎么读、怎么改、与 ADR 的关系"
- 规定每个外部基线文件的三段式结构：**采用** / **落地** / **缺口**
- 与 `principles.md` 的边界（基线 ≠ 流程原则；冲突时走 ADR）
- 引用上游源（CNCF TAG landing、12factor.net），注明版本
- 明确"偏离基线必须在 ADR 中显式说明"

### 4.2 `playbook/baselines/twelve-factor.md`

- Frontmatter：`baseline`、`upstream`、`upstream-version`、`status`、`deviation-count`、`last-reviewed`
- 12 个 section，每条三段式
- 重点裁剪（solo 场景）：
  - Factor II（依赖）→ 落 monorepo.md
  - Factor III（配置）→ 落 principles.md §5
  - Factor IV（backing services）→ ADR-0003
  - Factor V（build/release/run）→ 关联 ADR-0005 / 0006
  - Factor IX（disposability）→ ADR-0003
  - Factor XI（logs）→ Phase 2 实现（标注）
  - Factor XII（admin）→ Phase 2 关联 dev-bootstrap（标注）

### 4.3 `playbook/baselines/cncf-tag-app-delivery.md`

- Frontmatter 同 4.2
- 按 TAG 子域分节：**CI/CD** / **Continuous Delivery** / **GitOps** / **Progressive Delivery** / **Observability**
- 每节三段式（本仓当前 / 关键摘录 / 缺口）
- 与 12-Factor 重叠时（observability vs Factor XI），以 baselines/README 优先级说明为准
- 明确 solo 场景下：CI/CD 浅采用、GitOps 暂不、Progressive Delivery 暂不、Observability Phase 2

### 4.4 新增 4 篇 ADR

| ADR | 标题 | 决策点 |
|---|---|---|
| 0003 | 12-Factor 适配：solo dev 简化 | 哪些因子按字面执行 / 简化 / 不适用；至少覆盖 Factor IV（backing services）、IX（disposability） |
| 0004 | CNCF TAG App Delivery 采用范围 | solo 场景下 5 个子域各属"采用 / 观察 / 不采用"；明示 GitOps 与 Progressive Delivery 暂不 |
| 0005 | API 错误码与 HTTP 状态约定 | 错误响应体 schema `{ code, message, details?, traceId }`；HTTP 状态码语义；业务错误码分层 `AUTH_*` / `BIZ_*` / `SYS_*`；traceId 必填 |
| 0006 | CI 最低门槛 | 必选 3 项（lint / typecheck-or-test / secret scan）+ 可选 4 项（test / build / dep audit / sbom）；不强制具体工具，给等价物表 |

### 4.5 `playbook/api-error-codes.md`（新）

- 内容大纲：
  - 错误响应体 schema
  - HTTP 状态码语义（4xx 客户端、5xx 服务端）
  - 业务错误码分层（`AUTH_*` / `BIZ_*` / `SYS_*`）
  - 与 logging 的联动（traceId 必填）
- 来源基础：Google JSON Guide、Microsoft REST API Guidelines、OpenAPI；具体选择由 ADR-0005 拍板

### 4.6 `playbook/ci-minimum-gate.md`（新）

- 内容大纲：
  - 必选 3 项：lint / typecheck(or test) / secret scan
  - 可选 4 项：test / build / dep audit / sbom
  - 不强制具体工具，给"等价物表"（lint = ruff / eslint / golangci-lint；secret scan = gitleaks / trufflehog 等）
- 来源基础：CNCF TAG "CI/CD" 子域 + 12-Factor V

### 4.7 修改的文件

| 文件 | 改什么 |
|---|---|
| `playbook/principles.md` | "待补充"段：API 错误码 → 链到 `api-error-codes.md`；CI 最低 → 链到 `ci-minimum-gate.md`；前端/小程序目录保留但显式标注"延后至第 2 个前端项目" |
| `playbook/INDEX.md` | 加 baselines 段（README + 2 篇基线）+ 4 个新 ADR 链接 + 2 个新主题 playbook 链接 |
| `README.md` | 目录结构图更新；加 baselines 段；沉淀流程段加"基线月扫"动作 |
| `CLAUDE.md` | 加一行"修改基线时先读 baselines/README.md" |
| `adapters/cursor/core-principles.mdc` | 底部加一行指针 → `playbook/baselines/` |
| `scripts/sync.sh` | 加 `validate` 子命令（跑 lint + adr-validate + baselines-validate） |

---

## 5. 维护与冲突处理

### 5.1 冲突仲裁顺序

```
playbook/principles.md        Agent/流程层（本仓自有）
playbook/baselines/*.md       外部基线映射（承认外部权威）
playbook/adr/                 当期决定（覆盖以上两者中需要偏离的地方）
```

| 情况 | 处理 |
|---|---|
| principles.md 与 baselines/<name>.md 不一致 | 看 ADR：若有，ADR 优先；若无，先记 ADR 再执行 |
| baselines/<name>.md 内部两条冲突 | 上游基线本就有的张力 → 在文件"缺口"段显式列出，不在本仓解决 |
| 项目特例与本仓基线冲突 | **不改基线** —— 在消费方仓库（业务项目）覆盖，标准库不动 |
| 上游基线已废弃/重写 | baselines/<name>.md 顶部 `status` 字段改为 Deprecated 或 Superseded，**不删**（历史可追溯） |

### 5.2 基线 frontmatter 字段

```yaml
---
baseline: 12-Factor App
upstream: https://12factor.net/
upstream-version: "1.0 (原始版本，长期稳定)"
status: adopted          # 四选一: adopted | adapted | observing | deprecated
deviation-count: 2       # 整型；数值 = "本文件缺口段中链到的 ADR 篇数"
last-reviewed: 2026-06-24  # YYYY-MM-DD 格式
---
```

`deviation-count > 0` 是强信号：必须打开 ADR 列表确认每条偏离都站得住。

### 5.3 周期性维护

| 频率 | 动作 | 工具 |
|---|---|---|
| 每月 | 扫一次 `last-reviewed` > 30 天的 baselines/ 文件 | `scripts/baselines-validate.sh`（--stale） |
| 每次上游公告 | 评估对基线的影响 | 手动 |
| 每次 Skill/Hook 反复违反某条 | 评估是否补 Rule / 改 Skill | dev-bootstrap（Phase 2） |
| 每次消费方仓库 PR 触发"基线不符" | 评估是否升 ADR | 手动 |

### 5.4 文件级"完成"判据（每新增文件必须满足）

- [ ] 文件内**没有** TODO / TBD / "待定"
- [ ] "缺口"段每条链到具体 ADR（ID + 标题）
- [ ] frontmatter 填齐（baselines/ 文件）
- [ ] 与 INDEX.md 双向链接
- [ ] 至少被 1 个其他文件引用（避免孤儿）

---

## 6. 验证机制

### 6.1 静态检查（必须 + 阻断 commit）

| 项 | 工具 | 触发 | 失败处理 |
|---|---|---|---|
| Markdown 规范 | `markdownlint` | `scripts/lint.sh` | 阻断 |
| 内部链接完整性 | `markdown-link-check` 或自写 | `scripts/lint.sh` | 阻断 |
| ADR 模板完整性 | 自写：`scripts/adr-validate.sh` | `sync.sh validate` | 列出缺字段文件 |
| baselines/ frontmatter | 自写：`scripts/baselines-validate.sh` | `sync.sh validate` | 列出缺字段文件 |
| TODO/TBD/待定 扫描 | 自写（grep） | `scripts/lint.sh` | 列出违例 |
| 孤儿文件检测 | 自写 | `scripts/lint.sh` | 列出孤儿 |

### 6.2 验收清单（Phase 1 完成判据）

**文件齐全**：

- [ ] `playbook/baselines/README.md`
- [ ] `playbook/baselines/twelve-factor.md`
- [ ] `playbook/baselines/cncf-tag-app-delivery.md`
- [ ] `playbook/api-error-codes.md`
- [ ] `playbook/ci-minimum-gate.md`
- [ ] `playbook/adr/0003-12-factor-adaptation.md`
- [ ] `playbook/adr/0004-cncf-tag-app-delivery-adoption.md`
- [ ] `playbook/adr/0005-api-error-code-convention.md`
- [ ] `playbook/adr/0006-ci-minimum-gate.md`

**文件修改**：

- [ ] `principles.md` "待补充"清 2 项、保留 1 项并标延后
- [ ] `INDEX.md` 加 baselines + 4 个新 ADR 链接
- [ ] `README.md` 目录图更新
- [ ] `CLAUDE.md` 加基线指针
- [ ] `adapters/cursor/core-principles.mdc` 加指针

**脚本**：

- [ ] `scripts/baselines-validate.sh`（frontmatter + 过期扫描）
- [ ] `scripts/adr-validate.sh`（必填字段）
- [ ] `scripts/lint.sh`（串联 markdownlint + 链接检查）
- [ ] `scripts/sync.sh` 加 `validate` 子命令

**校验跑通**：

- [ ] `scripts/lint.sh` 0 违例
- [ ] `scripts/sync.sh validate` 0 违例
- [ ] 至少 1 个消费方能跑 `sync.sh` 拉取最新 Cursor 派生不报错

**ADR 数量**：

- 4 篇新 ADR 状态 ∈ {Accepted, Proposed}，**无 Draft 遗留**

### 6.3 风险与缓解

| 风险 | 缓解 |
|---|---|
| 写"摘抄拼贴"——基线文件沦为转载 | 强制三段式 + "落地"段必须链到本仓具体文件 |
| ADR 越写越多变成负担 | deviation-count 字段做信号；定期清理已被项目接受的稳定项（移入主题 playbook） |
| `principles.md` 与基线长期漂移 | 冲突仲裁规则 + 月扫 + 每次消费方 PR 触发评估 |
| 基线文件膨胀 | 限制每篇 < 200 行；超出即拆分子节或独立主题 playbook |

---

## 7. 引用与关系

### 7.1 上游来源

- CNCF TAG App Delivery: https://github.com/cncf/toc/blob/main/tags/app-delivery.md
- 12-Factor App: https://12factor.net/
- Google JSON Guide: https://cloud.google.com/apis/design/errors
- Microsoft REST API Guidelines: https://github.com/microsoft/api-guidelines
- OpenAPI Specification: https://spec.openapis.org/oas/latest

### 7.2 本仓内依赖

- 现有：`principles.md` / `monorepo.md` / `playbook/INDEX.md` / `playbook/adr/0001-…` / `playbook/adr/0002-…` / `skills/dev-bootstrap/` / `hooks/git-commit-guard.py` / `adapters/cursor/` / `scripts/sync.sh`
- 新增：见 §3.1 与 §6.2

### 7.3 后续阶段衔接

- **Phase 2**（Skill / Hook 丰备）：扩 `dev-bootstrap` 含基线检查；新增 hook 模板（secret scan pre-commit、ADR 创建提示）；Cursor `.mdc` 全量派生
- **Phase 3**（Plugin 化）：在 `playbook/baselines/` 之上加 plugin manifest（`marketplace.json` / `plugin.json`）；考虑 changelog 与版本号

---

## 8. 已确认决策

| 决策点 | 选择 | 备注 |
|---|---|---|
| 基线含义 | 外部行业基线 | — |
| 覆盖维度 | 架构·质量·依赖 / 安全·合规·隐私 / 可观测·可靠性·性能 / 流程·治理·交付 | 四维全覆盖 |
| 基线选择 | CNCF TAG App Delivery + 12-Factor | — |
| 目标用户 | 个人跨项目（不变） | 不引入多租户 |
| 推进节奏 | 第一阶段：基线对位 + 原则补全 | Phase 1 = 本 spec |
| 路径方案 | B：分层目录 + 双基线分文件 | 见 §3 |
