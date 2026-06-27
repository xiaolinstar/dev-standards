/**
 * Unified HTTP client — see dev-standards playbook/api-error-codes.md
 * Replace BASE_URL via project CLAUDE.md / runtime config.
 */

const BASE_URL = 'YOUR_API_BASE_URL';

export interface ApiErrorBody {
  code: string;
  message: string;
  details?: Record<string, unknown>;
  traceId?: string;
}

export class ApiError extends Error {
  constructor(public readonly body: ApiErrorBody) {
    super(body.message);
  }
}

interface RequestOpts {
  url: string;
  method?: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
  data?: unknown;
}

export async function http<T>(opts: RequestOpts): Promise<T> {
  const wxp = (globalThis as unknown as { wxp: WechatMiniprogram.Wx }).wxp;
  const token = wx.getStorageSync('token') as string | undefined;
  const res = await wxp.request({
    url: `${BASE_URL.replace(/\/$/, '')}${opts.url}`,
    method: opts.method ?? 'GET',
    data: opts.data,
    header: {
      'content-type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
  });
  if (res.statusCode >= 400) {
    const body = (res.data ?? {}) as ApiErrorBody;
    throw new ApiError({
      code: body.code ?? 'HTTP_ERROR',
      message: body.message ?? `HTTP ${res.statusCode}`,
      details: body.details,
      traceId: body.traceId,
    });
  }
  return res.data as T;
}
