# API 错误码与 HTTP 状态约定

> 决策见 [ADR-0005](adr/0005-api-error-code-convention.md)。本文是"怎么用"。

## 错误响应体

任何非 2xx 响应必须返回 JSON 体：

```json
{
  "code": "AUTH_INVALID_TOKEN",
  "message": "token 已过期或无效",
  "details": { "reason": "expired" },
  "traceId": "01HXY..."
}
```

字段说明见 ADR-0005 §错误响应体 schema。

## HTTP 状态码

| 状态 | 含义 | 典型场景 |
|---|---|---|
| 400 | 请求格式错误 | JSON 解析失败、必填字段缺失 |
| 401 | 未认证 | token 缺失或无效 |
| 403 | 已认证但无权限 | 角色不足 |
| 404 | 资源不存在 | 路径或 ID 不存在 |
| 409 | 资源冲突 | 重复创建、版本冲突 |
| 422 | 语义错误 | 参数格式正确但值不合法 |
| 500 | 内部错误 | 未捕获异常 |
| 502/503/504 | 上下游故障 | DB / 缓存 / 第三方不可用 |

## 业务错误码

| 前缀 | 含义 |
|---|---|
| `AUTH_*` | 鉴权 / 权限 |
| `VAL_*` | 参数校验 |
| `BIZ_*` | 业务规则 |
| `SYS_*` | 系统 / 依赖 |

示例（来自 ADR-0005 决策）：

| code | HTTP | 含义 |
|---|---|---|
| `AUTH_INVALID_TOKEN` | 401 | token 无效或过期 |
| `AUTH_FORBIDDEN` | 403 | 角色不足 |
| `VAL_REQUIRED_FIELD` | 400 | 必填字段缺失 |
| `VAL_INVALID_FORMAT` | 422 | 格式不合法 |
| `BIZ_DUPLICATE` | 409 | 资源已存在 |
| `BIZ_STATE_CONFLICT` | 409 | 状态机不匹配 |
| `SYS_DB_UNAVAILABLE` | 503 | 数据库不可用 |
| `SYS_UPSTREAM_TIMEOUT` | 504 | 上游超时 |

## 实现位置

- **monorepo 项目**：枚举集中在 `packages/shared/src/errors.ts`（TS matcher）+ 各语言后端等价物（如 Python `app/errors.py`）；**禁止** handler 里硬编码字符串。
- **单包项目**：集中在 `app/errors.py` 或同等位置。

### 参考实现（ai-todo，Batch 0–6 已闭合）

| 项 | 位置 |
| --- | --- |
| Git tag | [`api-error-codes-migration-complete`](https://github.com/xiaolinstar/ai-todo/releases/tag/api-error-codes-migration-complete) |
| Release note | [`docs/releases/api-error-codes-migration.md`](https://github.com/xiaolinstar/ai-todo/blob/main/docs/releases/api-error-codes-migration.md) |
| Python 枚举 | [`apps/api/src/ai_todo_api/errors.py`](https://github.com/xiaolinstar/ai-todo/blob/main/apps/api/src/ai_todo_api/errors.py) |
| TS matcher | [`packages/shared/src/errors.ts`](https://github.com/xiaolinstar/ai-todo/blob/main/packages/shared/src/errors.ts) |
| 关联 ID middleware | [`observability.py`](https://github.com/xiaolinstar/ai-todo/blob/main/apps/api/src/ai_todo_api/observability.py) |
| HTTP 契约文档 | [`docs/api-design.md` §错误码](https://github.com/xiaolinstar/ai-todo/blob/main/docs/api-design.md) |

**不等于默认合规** — 审计仍以 ADR + checklist 为准；见 [audit-feedback-loop.md](audit-feedback-loop.md)。

## Envelope 变体（兼容）

部分已上线 API（如 ai-todo）使用**外层 envelope**，内层仍须遵守 `code` / `message` / 前缀规范：

```json
{
  "ok": false,
  "error": {
    "code": "VAL_REQUIRED_FIELD",
    "message": "title is required",
    "details": { "field": "title" }
  },
  "request_id": "req_abc123"
}
```

| 标准字段 | Envelope 等价 | 说明 |
|---|---|---|
| `code` | `error.code` | wire 须带 `AUTH_*` / `VAL_*` / `BIZ_*` / `SYS_*` 前缀 |
| `message` | `error.message` | 同 |
| `details` | `error.details` | 同 |
| `traceId` | `request_id` 或 `requestId` | 语义等价；header 可用 `X-Request-ID` 或 `X-Trace-Id` |

**新 API** 可继续用 envelope（若全栈已统一 `{ ok, data }`）；**新错误码**必须带前缀并在集中枚举定义。

### 迁移路径（存量项目）

参考 [ai-todo Batch 0–6](https://github.com/xiaolinstar/ai-todo/blob/main/docs/releases/api-error-codes-migration.md)：

1. **Batch 0** — 响应体注入 `requestId` / `traceId`（不改 `error.code`）
2. **Batch 1** — `errors.py`（或等价）+ `LEGACY_ERROR_ALIASES` + guard tests
3. **Batch 2–5** — 按 AUTH → VAL → BIZ → SYS 切换 wire；客户端 `matches*ErrorCode` 保留 legacy 一期
4. **Batch 6** — `api-design.md` / skill / runbook 与实现对齐

原则：**冻结**旧字符串码作 alias；**不要求**改 envelope 外形。

## traceId

`traceId` 是请求进入系统时生成的唯一 ID（推荐 ULID / UUIDv7），必须：

- 出现在错误响应体
- 出现在所有该请求产生的日志条目
- 出现在所有对外 HTTP 调用的 `X-Trace-Id` header
- 由 middleware / interceptor 在请求入口生成

## 实现参考

Middleware 最小示例（FastAPI / Express）见 [snippets/trace-id-middleware.md](snippets/trace-id-middleware.md)。
日志格式见 [snippets/structured-logging.md](snippets/structured-logging.md)。

## 客户端处理建议

- 优先用 `code` 字段判断错误类型（**不要** 解析 `message` 文本）
- 用户提示用 `message`
- 客服/排障用 `traceId`（或 envelope 中的 `request_id` / `requestId`）
