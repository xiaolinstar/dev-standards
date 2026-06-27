# 网络层与登录态

> 与 [SKILL.md §2-3 网络层 / 登录流程](../SKILL.md) 配套。
> 错误格式遵循 [playbook/api-error-codes.md](../../../playbook/api-error-codes.md)（在 dev-standards 仓库内）。

## http.ts 完整骨架

```ts
// miniprogram/services/http.ts
import { ApiError, type ApiErrorBody } from './errors';

const BASE_URL = {
  dev: 'https://dev-api.example.com',
  trial: 'https://trial-api.example.com',
  release: 'https://api.example.com',
}[__wxConfig.envVersion] ?? 'https://dev-api.example.com';

const TOKEN_KEY = 'token';

interface RequestOpts {
  url: string;
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';
  data?: unknown;
  query?: Record<string, string | number>;
  headers?: Record<string, string>;
  skipAuth?: boolean;  // 登录接口本身
}

function buildUrl(url: string, query?: RequestOpts['query']): string {
  if (!query) return `${BASE_URL}${url}`;
  const qs = Object.entries(query)
    .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`)
    .join('&');
  return `${BASE_URL}${url}?${qs}`;
}

function getToken(): string {
  return wx.getStorageSync(TOKEN_KEY) || '';
}

export async function http<T>(opts: RequestOpts): Promise<T> {
  const headers: Record<string, string> = { ...opts.headers };
  if (!opts.skipAuth) {
    const token = getToken();
    if (token) headers['Authorization'] = `Bearer ${token}`;
  }

  const res = await wxp.request({
    url: buildUrl(opts.url, opts.query),
    method: opts.method ?? 'GET',
    data: opts.data,
    header: headers,
  });

  // 401 → 清 token 跳登录
  if (res.statusCode === 401) {
    wx.removeStorageSync(TOKEN_KEY);
    wxp.reLaunch({ url: '/pages/login/index' });
    throw new ApiError({ code: 'UNAUTHENTICATED', message: '请重新登录', status: 401 });
  }

  if (res.statusCode >= 400) {
    const body = (res.data ?? {}) as ApiErrorBody;
    throw new ApiError(body);
  }

  return res.data as T;
}
```

## 错误类型

```ts
// miniprogram/services/errors.ts
import type { ApiErrorBody } from './types';

export class ApiError extends Error {
  status: number;
  code: string;
  details?: unknown;

  constructor(body: ApiErrorBody) {
    super(body.message ?? 'API Error');
    this.status = body.status ?? 500;
    this.code = body.code ?? 'INTERNAL_ERROR';
    this.details = body.details;
  }
}
```

```ts
// miniprogram/services/types.ts
export interface ApiErrorBody {
  code: string;            // 见 api-error-codes.md
  message: string;
  status?: number;
  details?: unknown;
  requestId?: string;      // 后端生成，便于排查
}
```

## 登录页骨架

```ts
// miniprogram/pages/login/index.ts
Page({
  data: { submitting: false },

  async onSubmit() {
    if (this.data.submitting) return;
    this.setData({ submitting: true });

    try {
      const { code } = await wxp.login();
      const res = await http<{ token: string; userId: string }>({
        url: '/api/auth/wechat-login',
        method: 'POST',
        data: { code },
        skipAuth: true,
      });
      wx.setStorageSync('token', res.token);
      wxp.reLaunch({ url: '/pages/home/index' });
    } catch (e) {
      wx.showToast({ title: '登录失败，请重试', icon: 'none' });
    } finally {
      this.setData({ submitting: false });
    }
  },
});
```

## token 刷新策略

**简单方案**：过期靠 401 兜底，被踢回登录页重新走 wx.login。

**复杂方案**（多 token 体系）：

- `accessToken` 短（如 15min），`refreshToken` 长（7d）
- http.ts 拦截 401 时，**自动**用 refreshToken 换新 accessToken，重放原请求
- refreshToken 也过期 → 跳登录

**推荐**：简单方案足够 3 个项目的体量。复杂方案只在 accessToken 校验代价高时考虑。

## 请求重试

```ts
// 简单重试：只在网络层错误（无 res）时重试，不重试业务错误
async function requestWithRetry<T>(fn: () => Promise<T>, retries = 1): Promise<T> {
  try {
    return await fn();
  } catch (e: any) {
    if (retries > 0 && (!e.status || e.status >= 500)) {
      await new Promise(r => setTimeout(r, 500));
      return requestWithRetry(fn, retries - 1);
    }
    throw e;
  }
}
```

## mock 数据

开发期可让 `BASE_URL` 指向 mock server，或在 `services/` 下加 mock 分支：

```ts
// services/_mock.ts（仅 __DEV__ 时启用）
if (__wxConfig.envVersion === 'develop') {
  // 用 wxp.request 拦截器或直接 mock 部分 url
}
```

**注意**：不要在生产包（envVersion === 'release'）留 mock 代码。用 `__wxConfig.envVersion` 或构建变量剔除。
