---
ID: 0005
Title: API 错误码与 HTTP 状态约定
Status: Accepted
Date: 2026-06-24
Deciders: xingxiaolin
---

## 背景

跨项目 API 错误响应此前无统一约定。本 ADR 决定错误响应体 schema、HTTP 状态码语义、业务错误码分层。

## 决策

### 错误响应体 schema

```json
{
  "code": "AUTH_INVALID_TOKEN",
  "message": "token 已过期或无效",
  "details": { "reason": "expired" },
  "traceId": "01HXY..."
}
```

| 字段 | 必填 | 含义 |
|---|---|---|
| `code` | 是 | 业务错误码（见下） |
| `message` | 是 | 用户可读的中文/英文提示 |
| `details` | 否 | 结构化补充信息（如校验失败的具体字段） |
| `traceId` | 是 | 与日志关联的请求 ID（用于客服 / 排障） |

### HTTP 状态码语义

| 范围 | 语义 |
|---|---|
| 4xx | 客户端错误（请求格式 / 鉴权 / 业务规则不满足） |
| 5xx | 服务端错误（实现 bug / 依赖故障 / 资源耗尽） |

`code` 与 HTTP 状态码**正交**：HTTP 表达"哪一类失败"，`code` 表达"具体原因"。

### 业务错误码分层

| 前缀 | 含义 | HTTP 状态 |
|---|---|---|
| `AUTH_*` | 鉴权 / 权限 | 401 / 403 |
| `VAL_*` | 参数校验 | 400 / 422 |
| `BIZ_*` | 业务规则 | 400 / 409 / 422 |
| `SYS_*` | 系统 / 依赖 | 500 / 502 / 503 / 504 |

错误码大写、下划线分隔；枚举值集中在 `packages/shared/errors`（monorepo 项目）或 `app/errors.py`（单包项目），**禁止**散落。

## 后果

- `playbook/api-error-codes.md` 据此落地。
- 任何新错误码必须先在枚举文件中定义，**禁止**直接硬编码字符串。
- traceId 与 logging 系统的关联实现由 Phase 2 hooks 处理。