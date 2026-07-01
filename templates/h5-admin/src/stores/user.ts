import { defineStore } from 'pinia';
import router from '@/router';
import { RouteRecordRaw } from 'vue-router';

// 模拟动态权限路由表
export const asyncRoutes: RouteRecordRaw[] = [
  {
    path: '/',
    name: 'Dashboard',
    component: () => import('@/views/dashboard/index.vue'),
    meta: { title: '数据看板', permissions: ['admin', 'operator'] }
  },
  {
    path: '/operations',
    name: 'Operations',
    component: () => import('@/views/dashboard/index.vue'), // 临时指向同一个
    meta: { title: '运营配置', permissions: ['admin'] }
  }
];

export const useUserStore = defineStore('user', {
  state: () => ({
    token: localStorage.getItem('token') || '',
    username: '',
    avatar: '',
    roles: [] as string[],
    permissions: [] as string[],
  }),
  actions: {
    async login(loginForm: any) {
      // 模拟登录：在实际项目中替换为真实 API 请求
      return new Promise<void>((resolve, reject) => {
        if (loginForm.username && loginForm.password) {
          const mockToken = 'mock-jwt-token-xyz-12345';
          this.token = mockToken;
          localStorage.setItem('token', mockToken);
          resolve();
        } else {
          reject(new Error('请输入用户名和密码'));
        }
      });
    },
    async getUserInfo() {
      // 模拟获取用户信息
      return new Promise<void>((resolve) => {
        // 假装从接口请求回了数据
        this.username = '管理员';
        this.avatar = 'https://fastly.jsdelivr.net/npm/@vant/assets/cat.jpeg';
        this.roles = ['admin'];
        this.permissions = ['admin', 'dashboard_view', 'operations_config'];
        resolve();
      });
    },
    async generateRoutes() {
      // 根据用户角色/权限，动态注册路由
      const accessibleRoutes = asyncRoutes.filter(route => {
        if (!route.meta?.permissions) return true;
        return (route.meta.permissions as string[]).some(p => this.roles.includes(p));
      });

      accessibleRoutes.forEach(route => {
        router.addRoute(route);
      });
    },
    clearUserInfo() {
      this.token = '';
      this.username = '';
      this.avatar = '';
      this.roles = [];
      this.permissions = [];
      localStorage.removeItem('token');
    }
  },
  persist: true // pinia-plugin-persistedstate 会自动将 token 持久化到 localStorage
});
