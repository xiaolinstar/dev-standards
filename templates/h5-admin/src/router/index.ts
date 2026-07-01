import { createRouter, createWebHistory, RouteRecordRaw } from 'vue-router';
import { useUserStore } from '@/stores/user';
import { showLoadingToast, closeToast } from 'vant';

const constantRoutes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/login/index.vue'),
    meta: { title: '登录' }
  },
  {
    path: '/403',
    name: '403',
    component: () => import('@/views/error/403.vue'),
    meta: { title: '无权限' }
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'NotFound',
    component: () => import('@/views/error/404.vue'),
    meta: { title: '页面未找到' }
  }
];

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: constantRoutes
});

const whiteList = ['Login', '403', 'NotFound'];

router.beforeEach(async (to, from, next) => {
  const userStore = useUserStore();
  
  if (to.meta?.title) {
    document.title = `${to.meta.title} - 运营后台`;
  }

  if (userStore.token) {
    if (to.name === 'Login') {
      next({ path: '/' });
    } else {
      const hasPermissions = userStore.permissions && userStore.permissions.length > 0;
      if (hasPermissions) {
        next();
      } else {
        try {
          showLoadingToast({ message: '获取权限中...', forbidClick: true });
          await userStore.getUserInfo();
          closeToast();
          await userStore.generateRoutes();
          next({ ...to, replace: true });
        } catch (err) {
          userStore.clearUserInfo();
          closeToast();
          next({ name: 'Login', query: { redirect: to.fullPath } });
        }
      }
    }
  } else {
    if (whiteList.includes(to.name as string)) {
      next();
    } else {
      next({ name: 'Login', query: { redirect: to.fullPath } });
    }
  }
});

export default router;
