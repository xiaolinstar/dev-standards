# L1 开发原则

> 短、稳定、跨项目。真源就是本文；Cursor 写法派生见 `adapters/cursor/`（adapter 镜像），流程见 `skills/`。

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

## 待补充（从项目中提取）

- [ ]  API 错误码与 HTTP 状态约定
- [ ]  前端/小程序目录约定
- [ ]  CI 最低门槛（lint / test / secret scan）
