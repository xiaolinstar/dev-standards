# 结构化日志参考片段

> 与 [trace-id-middleware.md](trace-id-middleware.md) 配套。
> CNCF / 12-Factor Observability 浅采用：JSON 行 + traceId，**不**强制集中采集。
> 决策背景见 [baselines/cncf-tag-app-delivery.md](../baselines/cncf-tag-app-delivery.md) §Observability。

## 原则

- 一行一条 JSON（stdout）
- 每条含 `level`、`message`、`traceId`、可选 `service`
- 错误日志含 `code`（业务错误码，见 [api-error-codes.md](../api-error-codes.md)）
- **不**解析 `message` 文本做告警；用 `code` / `level`

## Python（stdlib + contextvar traceId）

```python
import json
import logging
from datetime import datetime, timezone

from app.middleware.trace_id import get_trace_id  # see trace-id-middleware.md

class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload = {
            "ts": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname,
            "message": record.getMessage(),
            "traceId": get_trace_id(),
            "logger": record.name,
        }
        if hasattr(record, "code"):
            payload["code"] = record.code
        return json.dumps(payload, ensure_ascii=False)

handler = logging.StreamHandler()
handler.setFormatter(JsonFormatter())
logging.root.handlers = [handler]
logging.root.setLevel(logging.INFO)
```

## Node / TypeScript（pino 风格字段）

```typescript
import pino from 'pino';

export function createLogger(traceId: string) {
  return pino({
    base: { traceId, service: 'api' },
    timestamp: pino.stdTimeFunctions.isoTime,
  });
}

// usage in handler
// logger.info({ code: 'BIZ_DUPLICATE' }, 'resource exists');
```

## 与 Phase 3+ 的关系

- 集中采集（ELK / Loki / CloudWatch）→ 消费 stdout JSON；本片段不绑定供应商
- metrics / tracing 集中化仍延后；见 baselines 缺口段
