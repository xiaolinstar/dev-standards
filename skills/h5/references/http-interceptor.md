# Axios 请求拦截器参考实现

> 对应 Skill 核心约定 §9「Axios 拦截器」。

## services/http.ts 完整实现

```ts
// src/services/http.ts
import axios, { type AxiosResponse, type InternalAxiosRequestConfig } from 'axios';
import { showDialog } from 'vant';
import { useUserStore } from '@/stores/user';
import router from '@/router';

// ========== 创建实例 ==========
const http = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
  timeout: 15000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// ========== 请求拦截器 ==========
// 自动注入 Bearer token
http.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const userStore = useUserStore();
    const token = userStore.token;

    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`;
    }

    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// ========== 响应拦截器 ==========
// 统一处理业务错误码和 HTTP 状态码
http.interceptors.response.use(
  (response: AxiosResponse) => {
    const { data } = response;

    // 业务层约定：code !== 200 表示业务错误
    // 错误格式遵循 playbook/api-error-codes.md
    if (data.code !== undefined && data.code !== 200) {
      // 业务错误：弹出提示
      showDialog({
        title: '请求失败',
        message: data.message || '未知业务错误',
      });
      return Promise.reject(new Error(data.message || 'Business Error'));
    }

    // 正常返回 data 层（去掉 axios 包装）
    return data;
  },
  (error) => {
    const status = error.response?.status;

    switch (status) {
      case 401:
        // 未登录或 token 过期 → 清空用户态 → 跳转登录页
        handleUnauthorized();
        break;

      case 403:
        // 无权限 → 跳转 403 页面
        router.replace('/403');
        break;

      case 500:
      default:
        // 服务器错误 → 弹窗提示
        showDialog({
          title: '服务器错误',
          message: error.response?.data?.message || '服务器开小差了，请稍后重试',
        });
        break;
    }

    return Promise.reject(error);
  }
);

// ========== 401 处理逻辑 ==========
function handleUnauthorized() {
  const userStore = useUserStore();
  userStore.clearToken();

  // 记录当前页面，登录后跳回
  const currentPath = router.currentRoute.value.fullPath;
  router.replace({
    path: '/login',
    query: { redirect: currentPath },
  });
}

export default http;
```

## 使用方式

```ts
// src/api/todo.ts
import http from '@/services/http';

export interface Todo {
  id: string;
  title: string;
  done: boolean;
}

// GET 请求
export const fetchTodos = (page: number, pageSize: number) =>
  http.get<Todo[]>('/api/todos', { params: { page, pageSize } });

// POST 请求
export const createTodo = (data: Partial<Todo>) =>
  http.post<Todo>('/api/todos', data);

// DELETE 请求
export const deleteTodo = (id: string) =>
  http.delete(`/api/todos/${id}`);
```

## 配套 Pinia userStore

```ts
// src/stores/user.ts
import { defineStore } from 'pinia';
import { ref } from 'vue';

export const useUserStore = defineStore('user', () => {
  const token = ref<string>(localStorage.getItem('token') || '');
  const roles = ref<string[]>([]);
  const permissions = ref<string[]>([]);

  const setToken = (t: string) => {
    token.value = t;
    localStorage.setItem('token', t);
  };

  const clearToken = () => {
    token.value = '';
    localStorage.removeItem('token');
  };

  const hasPermission = (perm: string) => permissions.value.includes(perm);

  return { token, roles, permissions, setToken, clearToken, hasPermission };
});
```

## 环境变量

```bash
# .env.development
VITE_API_BASE_URL=http://localhost:3000

# .env.production
VITE_API_BASE_URL=https://api.yourdomain.com
```

## 相关规范

- 错误格式遵循 [playbook/api-error-codes.md](../../../playbook/api-error-codes.md)
