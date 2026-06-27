# traceId Middleware 参考片段

> 决策见 [ADR-0005](../adr/0005-api-error-code-convention.md)。
> 用法见 [api-error-codes.md §traceId](../api-error-codes.md#traceid)。
> **复制逻辑，适配框架** — 非强制依赖库。

## FastAPI（Python）

```python
# app/middleware/trace_id.py
import uuid
from contextvars import ContextVar
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

trace_id_var: ContextVar[str] = ContextVar("trace_id", default="")

def get_trace_id() -> str:
    return trace_id_var.get()

class TraceIdMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        incoming = request.headers.get("x-trace-id")
        trace_id = incoming or uuid.uuid4().hex
        token = trace_id_var.set(trace_id)
        try:
            response = await call_next(request)
            response.headers["X-Trace-Id"] = trace_id
            return response
        finally:
            trace_id_var.reset(token)
```

注册：`app.add_middleware(TraceIdMiddleware)`。日志 formatter 读 `get_trace_id()`。

错误响应示例：

```python
from fastapi.responses import JSONResponse

def error_response(code: str, message: str, status: int, details=None):
    return JSONResponse(
        status_code=status,
        content={
            "code": code,
            "message": message,
            "details": details,
            "traceId": get_trace_id(),
        },
    )
```

## Express（Node / TypeScript）

```typescript
// src/middleware/traceId.ts
import { randomUUID } from 'node:crypto';
import type { Request, Response, NextFunction } from 'express';

declare global {
  namespace Express {
    interface Request {
      traceId: string;
    }
  }
}

export function traceIdMiddleware(req: Request, res: Response, next: NextFunction) {
  const traceId = (req.header('x-trace-id') as string) || randomUUID();
  req.traceId = traceId;
  res.setHeader('X-Trace-Id', traceId);
  next();
}
```

```typescript
// src/errors.ts
import type { Response } from 'express';

export function sendError(
  res: Response,
  status: number,
  code: string,
  message: string,
  traceId: string,
  details?: Record<string, unknown>,
) {
  res.status(status).json({ code, message, details, traceId });
}
```

## 出站 HTTP 调用

转发当前 traceId：

```typescript
headers: { 'X-Trace-Id': req.traceId }
```

```python
headers={"X-Trace-Id": get_trace_id()}
```
