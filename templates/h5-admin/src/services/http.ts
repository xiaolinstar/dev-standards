import axios, { AxiosError, InternalAxiosRequestConfig } from 'axios';
import { showToast, showDialog } from 'vant';
import { useUserStore } from '@/stores/user';
import router from '@/router';

const http = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  }
});

// 请求拦截器：自动注入 Authorization Token
http.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const userStore = useUserStore();
    if (userStore.token && config.headers) {
      config.headers['Authorization'] = `Bearer ${userStore.token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// 响应拦截器：错误统一处理
http.interceptors.response.use(
  (response) => {
    const res = response.data;
    if (res.code && res.code !== 200) {
      showToast(res.message || '业务操作失败');
      return Promise.reject(new Error(res.message || 'Error'));
    }
    return res;
  },
  (error: AxiosError) => {
    const status = error.response?.status;
    const data = error.response?.data as any;
    const userStore = useUserStore();

    switch (status) {
      case 401:
        showToast('登录状态过期，请重新登录');
        userStore.clearUserInfo();
        router.replace({ name: 'Login', query: { redirect: router.currentRoute.value.fullPath } });
        break;
      case 403:
        showToast('权限不足，拒绝访问');
        router.replace({ name: '403' });
        break;
      case 422:
        showToast(data?.message || '输入校验失败');
        break;
      case 500:
        showDialog({
          title: '系统错误',
          message: '后端服务异常，请稍后重试',
        });
        break;
      default:
        showToast(data?.message || error.message || '未知网络错误');
    }
    return Promise.reject(error);
  }
);

export default http;
