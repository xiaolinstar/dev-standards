# L1 开发原则

> 短、稳定、跨项目。真源就是本文；Cursor 写法派生见 `adapters/cursor/`（adapter 镜像），流程见 `skills/`。
> 行业基线对齐见 [baselines/](baselines/README.md)；决策走 [ADR](adr/)。

## 1. 最小 scope

只做请求范围内的事。不顺手重构、不扩功能、不为假想边界加代码。

## 2. 复用现有约定

改代码前先读周边文件。命名、目录、错误处理、测试风格与项目保持一致。

## 3. Agent 边界清晰

- **业务逻辑在应用里** — 结构化 API/CLI；不在服务端堆 NL 解析（见 ai-todo 决策）
- **Agent 负责理解与编排** — 自然语言 → 结构化调用
- **Skill 管流程，Rule 管写法**

## 4. 可验证

- 行为变更应有测试或明确的验证步骤
- 不测显而易见的事；测真实行为和回归点

## 5. 配置与密钥

- 密钥不进仓库；用 `.env.example` 文档化变量名
- 12-Factor：配置走环境，不硬编码环境差异

## 6. Git 与发布

- Conventional Commits 风格（与现有 user rules 一致）
- 任何项目在开发前以及推送前，必须执行 `git pull`（优先 `--rebase`）提前同步远程最新修改，最大程度预防和解决潜在的代码冲突
- 严禁使用 `--no-verify` 绕过本地 Git hooks。本地拦截的质量标准在 CI 阶段同样会被阻断，绕过本地检查只会浪费 CI 资源并产生无效的构建失败记录
- 不主动 commit/push，除非明确要求
- 发布与兼容性变更写 release note 或 ADR

## 7. 文档分层

| 类型 | 放哪 |
|------|------|
| 为什么这样选 | ADR |
| 怎么用 | 项目 README / developer-guide |
| Agent 怎么执行 | Skill（Claude Code） |
| 代码默认怎么写 | `adapters/cursor/`（Cursor）或项目自身 CLAUDE.md / 现有约定 |

## 8. 仓库形态

- **默认单包**；≥2 个可运行产物或需共享 TS 库时再上 monorepo
- **pnpm workspaces** + `apps/` / `packages/`；详见 [monorepo.md](monorepo.md) 与 [ADR-0002](adr/0002-monorepo-default-selection.md)

## 已落地的补全

- API 错误码与 HTTP 状态约定 → 详见 [api-error-codes.md](api-error-codes.md) / [ADR-0005](adr/0005-api-error-code-convention.md)
- CI 最低门槛 → 详见 [ci-minimum-gate.md](ci-minimum-gate.md) / [ADR-0006](adr/0006-ci-minimum-gate.md)
- 微信小程序项目标准（原生 + TypeScript）→ 详见 [wechat-mp.md](wechat-mp.md) / [ADR-0007](adr/0007-wechat-miniprogram-baseline.md)

## 显式延后

- **Web 前端目录约定**（React / Next.js / SPA 等）— 不在本阶段覆盖。
  触发条件：出现第 2 个 Web 前端项目时启动。
  理由：单项目特例不上升为通用标准；见 [ADR-0004](adr/0004-cncf-tag-app-delivery-adoption.md) 末尾说明。

## 外部基线

行业基线对齐见 [baselines/](baselines/README.md)（CNCF TAG App Delivery、12-Factor）。冲突时按 [INDEX.md](INDEX.md) §ADR 仲裁顺序处理。
