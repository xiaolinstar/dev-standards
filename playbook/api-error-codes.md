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

- **monorepo 项目**：枚举集中在 `packages/shared/errors/`；每个错误一个文件，导出一个 `class` 或 `const`。
- **单包项目**：集中在 `app/errors.py` 或同等位置。
- **禁止**：在 controller / handler 里直接写字符串字面量。

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
| `code` | `error.code` | **必须**逐步改为 `AUTH_*` / `VAL_*` / `BIZ_*` / `SYS_*` 前缀 |
| `message` | `error.message` | 同 |
| `details` | `error.details` | 同 |
| `traceId` | `request_id` 或 `requestId` | 语义等价；header 可用 `X-Request-ID` 或 `X-Trace-Id` |

**新 API** 可继续用 envelope（若全栈已统一 `{ ok, data }`）；**新错误码**必须带前缀并在集中枚举定义。

### 迁移路径（存量项目）

1. **冻结**旧字符串码（如 `VALIDATION_ERROR`）— 客户端已依赖则保留 alias
2. **新增**错误只用前缀码；在 `packages/shared/errors/` 或 `app/errors.py` 定义
3. **映射表**（可选）：旧码 → 新码，文档 + 测试各保留一期
4. **不要求**一次性改响应 envelope 形状（避免破坏小程序/CLI）

详见 [audit-feedback-loop.md](audit-feedback-loop.md)。

## traceId

`traceId` 是请求进入系统时生成的唯一 ID（推荐 ULID / UUIDv7），必须：

- 出现在错误响应体
- 出现在所有该请求产生的日志条目
- 出现在所有对外 HTTP 调用的 `X-Trace-Id` header
- 由 middleware / interceptor 在请求入口生成

## 实现参考

Middleware 最小示例（FastAPI / Express）见 [snippets/trace-id-middleware.md](snippets/trace-id-middleware.md)。

## 客户端处理建议

- 优先用 `code` 字段判断错误类型（**不要** 解析 `message` 文本）
- 用户提示用 `message`
- 客服/排障用 `traceId`（或 envelope 中的 `request_id` / `requestId`）
