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
            v-for="item in menuConfig"
            :key="item.key"
            :to="item.children[0]?.path || '/'"
            class="admin-nav-link"
            :class="{ 'admin-nav-link-active': activeTopKey === item.key }"
          >
            {{ item.label }}
          </RouterLink>
        </nav>
        <div class="admin-user">
          <span class="text-sm text-neutral hidden sm:inline">{{ username }}</span>
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
        <!-- PC 侧栏导航：展示当前主导航下的子导航 -->
        <nav class="admin-sidebar-nav hidden md:flex">
          <RouterLink
            v-for="item in sidebarItems"
            :key="item.path"
            :to="item.path"
            class="admin-sidebar-link"
            active-class="admin-sidebar-link-active"
          >
            <van-icon v-if="item.icon" :name="item.icon" size="18" />
            {{ item.label }}
          </RouterLink>
        </nav>

        <!-- 移动端侧栏导航：展示完整的分组菜单 -->
        <nav class="admin-sidebar-nav flex md:hidden">
          <div v-for="group in menuConfig" :key="group.key" class="menu-group">
            <div class="menu-group-title">{{ group.label }}</div>
            <RouterLink
              v-for="item in group.children"
              :key="item.path"
              :to="item.path"
              class="admin-sidebar-link"
              active-class="admin-sidebar-link-active"
              @click="sidebarOpen = false"
            >
              <van-icon v-if="item.icon" :name="item.icon" size="18" />
              {{ item.label }}
            </RouterLink>
          </div>
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
import { useRouter, useRoute } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { showConfirmDialog, showToast } from 'vant'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

const projectName = computed(() => import.meta.env.VITE_PROJECT_NAME || '运营后台')
const username = computed(() => userStore.username || 'Admin')

const sidebarOpen = ref(false)

interface MenuItem {
  path: string
  label: string
  icon?: string
}

interface TopNavItem {
  key: string
  label: string
  icon?: string
  children: MenuItem[]
}

// 占位的两级导航项；项目按需覆盖
const menuConfig: TopNavItem[] = [
  {
    key: 'overview',
    label: '运营概览',
    children: [
      { path: '/', label: '数据看板', icon: 'chart-trending-o' },
      { path: '/workbench', label: '工作台', icon: 'todo-list-o' }
    ]
  },
  {
    key: 'business',
    label: '业务管理',
    children: [
      { path: '/products', label: '商品列表', icon: 'goods-collect-o' },
      { path: '/review', label: '审批中心', icon: 'records-o' }
    ]
  },
  {
    key: 'system',
    label: '系统管理',
    children: [
      { path: '/users', label: '账号管理', icon: 'friends-o' },
      { path: '/operations', label: '运营配置', icon: 'setting-o' }
    ]
  }
]

const activeTopKey = computed(() => {
  const currentPath = route.path
  const match = menuConfig.find((item) =>
    item.children.some((child) => child.path === currentPath)
  )
  return match ? match.key : 'overview'
})

const sidebarItems = computed(() => {
  const match = menuConfig.find((item) => item.key === activeTopKey.value)
  return match ? match.children : []
})

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
  width: 100%;
}

.admin-sidebar-link {
  width: 100%;
}

.menu-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
  margin-bottom: 16px;
  width: 100%;
}

.menu-group-title {
  padding: 6px 12px;
  font-size: 12px;
  font-weight: 600;
  color: #94a3b8; /* slate-400 */
  text-transform: uppercase;
  letter-spacing: 0.05em;
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