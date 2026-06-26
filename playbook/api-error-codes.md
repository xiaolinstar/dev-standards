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

## traceId

`traceId` 是请求进入系统时生成的唯一 ID（推荐 ULID / UUIDv7），必须：

- 出现在错误响应体
- 出现在所有该请求产生的日志条目
- 出现在所有对外 HTTP 调用的 `X-Trace-Id` header
- 由 middleware / interceptor 在请求入口生成

## 客户端处理建议

- 优先用 `code` 字段判断错误类型（**不要** 解析 `message` 文本）
- 用户提示用 `message`
- 客服/排障用 `traceId`