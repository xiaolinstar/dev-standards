<template>
  <!-- 三段式骨架：header + sidebar + main（继承 web.md §4.1） -->
  <div class="admin-shell">
    <!-- 顶部水平导航 -->
    <header class="admin-header">
      <div class="admin-header-inner">
        <button class="mobile-menu-btn md:hidden" @click="sidebarOpen = true">
          <van-icon name="bars" size="20" />
        </button>
        <h1 class="admin-brand">{{ projectName }}</h1>
        <nav class="admin-nav hidden md:flex">
          <RouterLink
            v-for="item in navItems"
            :key="item.path"
            :to="item.path"
            class="admin-nav-link"
            active-class="admin-nav-link-active"
          >
            {{ item.label }}
          </RouterLink>
        </nav>
        <div class="admin-user">
          <span class="text-sm text-neutral hidden sm:inline">{{ user?.displayName || 'Admin' }}</span>
          <button class="admin-logout" @click="handleLogout">
            <van-icon name="cross" size="18" />
          </button>
        </div>
      </div>
    </header>

    <!-- 主体：侧栏 + 内容 -->
    <div class="admin-body">
      <aside
        class="admin-sidebar"
        :class="{ 'sidebar-open': sidebarOpen }"
        @click.self="sidebarOpen = false"
      >
        <nav class="admin-sidebar-nav">
          <RouterLink
            v-for="item in navItems"
            :key="item.path"
            :to="item.path"
            class="admin-sidebar-link"
            active-class="admin-sidebar-link-active"
            @click="sidebarOpen = false"
          >
            <van-icon v-if="item.icon" :name="item.icon" size="18" />
            {{ item.label }}
          </RouterLink>
        </nav>
      </aside>

      <main class="admin-main">
        <RouterView v-slot="{ Component }">
          <transition name="fade-slide" mode="out-in">
            <component :is="Component" />
          </transition>
        </RouterView>
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { showConfirmDialog, showToast } from 'vant'

const router = useRouter()
const userStore = useUserStore()

const projectName = computed(() => import.meta.env.VITE_PROJECT_NAME || '运营后台')
const user = computed(() => userStore.userInfo)

const sidebarOpen = ref(false)

// 占位的导航项；项目按需覆盖
const navItems = [
  { path: '/', label: '运营概览', icon: 'home-o' },
  { path: '/products', label: '业务管理', icon: 'apps-o' },
  { path: '/review', label: '审批中心', icon: 'records-o' },
  { path: '/users', label: '账号管理', icon: 'friends-o' },
]

const handleLogout = () => {
  showConfirmDialog({
    title: '确认退出',
    message: '确定要退出当前运营账户吗？',
  }).then(() => {
    userStore.clearUserInfo()
    showToast('已安全退出')
    router.replace({ name: 'Login' })
  }).catch(() => {})
}
</script>

<style scoped>
.admin-shell {
  min-height: 100vh;
  background: #f8fafc;
  color: #0f172a;
}

.admin-header {
  position: sticky;
  top: 0;
  z-index: 30;
  background: #ffffff;
  border-bottom: 1px solid #e2e8f0;
  box-shadow: var(--project-shadow-sm);
}

.admin-header-inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  height: 56px;
  max-width: var(--project-container-max);
  margin: 0 auto;
  padding: 0 16px;
}

.mobile-menu-btn {
  padding: 8px;
  border: 0;
  border-radius: var(--project-radius-sm);
  background: transparent;
  cursor: pointer;
  color: var(--project-neutral-color);
}

.mobile-menu-btn:hover {
  background: #f1f5f9;
}

.admin-brand {
  font-size: var(--project-text-lg);
  font-weight: 700;
  color: var(--project-primary-color);
}

.admin-nav {
  flex: 1;
  margin: 0 24px;
  gap: 4px;
}

.admin-nav-link,
.admin-sidebar-link {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 14px;
  border-radius: var(--project-radius-sm);
  color: var(--project-neutral-color);
  font-size: var(--project-text-base);
  font-weight: 500;
  text-decoration: none;
  transition: all 0.15s ease;
}

.admin-nav-link:hover,
.admin-sidebar-link:hover {
  background: #f1f5f9;
  color: #0f172a;
}

.admin-nav-link-active,
.admin-sidebar-link-active {
  background: rgba(37, 99, 235, 0.08);
  color: var(--project-primary-color);
  font-weight: 600;
}

.admin-user {
  display: flex;
  align-items: center;
  gap: 8px;
}

.admin-logout {
  padding: 8px;
  border: 0;
  border-radius: var(--project-radius-pill);
  background: transparent;
  color: var(--project-neutral-color);
  cursor: pointer;
}

.admin-logout:hover {
  background: #f1f5f9;
  color: var(--project-danger-color);
}

.admin-body {
  display: flex;
  max-width: var(--project-container-max);
  margin: 0 auto;
}

.admin-sidebar {
  position: fixed;
  top: 56px;
  left: 0;
  bottom: 0;
  width: 220px;
  padding: 16px 12px;
  background: #ffffff;
  border-right: 1px solid #e2e8f0;
  transform: translateX(-100%);
  transition: transform 0.25s ease;
  z-index: 20;
}

.admin-sidebar.sidebar-open {
  transform: translateX(0);
}

@media (min-width: 768px) {
  .admin-sidebar {
    position: sticky;
    top: 56px;
    height: calc(100vh - 56px);
    transform: translateX(0);
  }
}

.admin-sidebar-nav {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.admin-sidebar-link {
  width: 100%;
}

.admin-main {
  flex: 1;
  min-width: 0;
  padding: 16px;
}

@media (min-width: 1024px) {
  .admin-main {
    padding: 24px;
  }
}

.fade-slide-enter-active,
.fade-slide-leave-active {
  transition: all 0.2s ease-out;
}

.fade-slide-enter-from {
  opacity: 0;
  transform: translateY(6px);
}

.fade-slide-leave-to {
  opacity: 0;
  transform: translateY(-6px);
}
</style>