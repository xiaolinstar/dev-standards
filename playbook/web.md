# Web 项目统一规范（PC 优先自适应 + Vant 4 + Tailwind + Design Tokens）

> 决策见 [ADR-0011](adr/0011-web-admin-baseline.md)。本文是"怎么用"。
>
> 适用对象：以 PC 浏览器为主、移动端浏览器为辅的 Web 应用（典型：运营管理后台、数据看板、内部工具）。
> 不适用：以移动端为绝对主战场的产品（继续遵循 [h5.md](h5.md)）。

## 1. 设计原则

| 原则 | 含义 |
|------|------|
| **PC 优先** | 视觉布局、操作密度、信息架构默认按 1280px 宽设计，向下逐级降级 |
| **一套代码，两端共享** | 不做"PC 单独写一份、移动端单独写一份"，靠断点和组件自适应 |
| **设计令牌化** | 所有色值、间距、圆角、字号必须走 CSS 变量，禁止散落硬编码 |
| **差异化收敛到 token** | 项目间允许差异，但只能发生在 `--project-primary-color` 等 token 覆盖处 |

## 2. 技术栈与版本基线

| 维度 | 选型 | 理由 |
|------|------|------|
| 语言 | TypeScript `strict: true` | 与 [h5.md](h5.md) §1 一致 |
| 核心框架 | Vue 3 (SFC, Composition API) | 与 H5 项目共享心智模型 |
| 状态管理 | Pinia + `pinia-plugin-persistedstate` | token 持久化 |
| 路由 | Vue Router (HTML5 history) | RBAC 动态路由 |
| UI 组件库 | **Vant 4** | 保留移动端组件手感，同时支持桌面断点 |
| 样式系统 | **Tailwind CSS** + CSS 变量 | utility-first + design tokens |
| 适配方案 | **响应式断点**（非 vw 沙盒） | PC 优先场景下，vw 已不适用 |
| HTTP | Axios + 拦截器 | 与 [api-error-codes.md](api-error-codes.md) 对齐 |
| 包管理 | pnpm | 与 monorepo 一致 |

> ⚠️ **Vant 必须按需引入**：通过 `unplugin-vue-components` + `VantResolver`，严禁 `import 'vant'`。
> 错误示例：`import { Button } from 'vant'` 在多组件场景下仍会按需；但 `import 'vant/lib/index.css'` 全量引入样式**严禁**。

## 3. Design Tokens（设计令牌）

### 3.1 Token 总览

所有 token 通过 `:root` CSS 变量定义；项目根目录 `src/styles/tokens.css` 统一维护：

```css
/* src/styles/tokens.css —— 跨项目统一，禁止各项目私自新增 token */
:root {
  /* === 色板（仅 5 个语义色，扩展色按需申请） === */
  --project-primary-color: #2563eb;   /* 主色 —— 项目可覆盖 */
  --project-success-color: #10b981;
  --project-warning-color: #f59e0b;
  --project-danger-color: #ef4444;
  --project-neutral-color: #64748b;

  /* === 圆角 === */
  --project-radius-sm: 6px;     /* 按钮、tag、小卡片 */
  --project-radius-md: 12px;    /* 卡片、面板 */
  --project-radius-lg: 20px;    /* 弹窗、抽屉 */
  --project-radius-pill: 999px; /* pill 按钮 */

  /* === 间距（基于 4 倍数） === */
  --project-space-1: 4px;
  --project-space-2: 8px;
  --project-space-3: 12px;
  --project-space-4: 16px;
  --project-space-5: 20px;
  --project-space-6: 24px;
  --project-space-8: 32px;
  --project-space-10: 40px;
  --project-space-12: 48px;

  /* === 字号 === */
  --project-text-xs: 12px;      /* 辅助文字、标签 */
  --project-text-sm: 13px;      /* 表格、表单 */
  --project-text-base: 14px;    /* 正文 */
  --project-text-md: 16px;      /* 二级标题 */
  --project-text-lg: 18px;      /* 一级标题 */
  --project-text-xl: 22px;      /* 页面标题 */
  --project-text-2xl: 28px;     /* 强调标题 */

  /* === 行高 === */
  --project-leading-tight: 1.2;
  --project-leading-normal: 1.5;
  --project-leading-relaxed: 1.7;

  /* === 阴影 === */
  --project-shadow-sm: 0 1px 2px rgba(15, 23, 42, 0.06);
  --project-shadow-md: 0 4px 12px rgba(15, 23, 42, 0.08);
  --project-shadow-lg: 0 12px 32px rgba(15, 23, 42, 0.12);

  /* === 断点（与 Tailwind config 一致） === */
  --project-bp-sm: 640px;
  --project-bp-md: 768px;
  --project-bp-lg: 1024px;
  --project-bp-xl: 1280px;

  /* === 容器最大宽度 === */
  --project-container-max: 1280px;
}

/* === Vant 4 主题变量绑定 === */
:root {
  --van-primary-color: var(--project-primary-color);
  --van-success-color: var(--project-success-color);
  --van-danger-color: var(--project-danger-color);
  --van-warning-color: var(--project-warning-color);
  --van-button-default-height: 36px;
  --van-cell-vertical-padding: 12px;
  --van-cell-horizontal-padding: 16px;
  --van-field-label-color: var(--project-neutral-color);
}
```

### 3.2 项目覆盖示例（品牌色）

```css
/* drink-budget —— 主题色 */
:root {
  --project-primary-color: #1989fa;
}

/* party-helper —— 主题色 */
:root {
  --project-primary-color: #246bfe;
}
```

> ✅ 仅覆盖 `--project-primary-color`（及必要时少量衍生色），其他 token **禁止项目修改**。

### 3.3 Tailwind 与 token 对齐

```js
// tailwind.config.js
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{vue,js,ts,jsx,tsx}'],
  theme: {
    screens: {
      sm: '640px',   // --project-bp-sm
      md: '768px',   // --project-bp-md
      lg: '1024px',  // --project-bp-lg
      xl: '1280px',  // --project-bp-xl
    },
    extend: {
      colors: {
        primary: 'var(--project-primary-color)',
        success: 'var(--project-success-color)',
        warning: 'var(--project-warning-color)',
        danger: 'var(--project-danger-color)',
        neutral: 'var(--project-neutral-color)',
      },
      borderRadius: {
        sm: 'var(--project-radius-sm)',
        md: 'var(--project-radius-md)',
        lg: 'var(--project-radius-lg)',
        pill: 'var(--project-radius-pill)',
      },
      spacing: {
        'safe-top': 'env(safe-area-inset-top)',
        'safe-bottom': 'env(safe-area-inset-bottom)',
      },
      maxWidth: {
        container: 'var(--project-container-max)',
      },
    },
  },
  plugins: [],
}
```

> ⚠️ Tailwind **不引入 `postcss-px-to-viewport` 插件**。PC 优先场景下 px 直写即可，
> 移动端通过 Tailwind 自带响应式断点（`sm: / md: / lg:`）适配。

## 4. 布局与导航

### 4.1 三段式骨架（App.vue）

所有 admin 类项目的根组件统一使用 `header + sidebar + main` 三段式：

```vue
<!-- src/App.vue -->
<template>
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
          <span class="text-sm text-neutral hidden sm:inline">{{ user?.displayName }}</span>
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

<style scoped>
.admin-shell {
  min-height: 100vh;
  background: #f8fafc; /* slate-50 */
  color: #0f172a; /* slate-900 */
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

/* 全局路由过渡 */
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
```

### 4.2 断点行为约定

| 断点 | 宽度 | 行为 |
|------|------|------|
| `< 768px` (mobile) | 单列堆叠、底部 tabbar、卡片化列表、侧栏隐藏为抽屉 | |
| `768~1023px` (tablet) | 双列卡片、抽屉式详情、顶部 nav 出现 | |
| `≥ 1024px` (desktop) | 12 列栅格、侧栏常驻、抽屉变侧栏 | |
| `≥ 1280px` (wide) | 内容容器 `max-width: 1280px` 居中 | |

## 5. 列表 / 表格 / 表单

### 5.1 数据列表（替代 PC 端横向大表格）

**严禁在 admin 中使用宽表格 + 横向滚动**。统一采用卡片化列表：

- **PC 端**：12 列栅格，每行 1~3 张卡片
- **移动端**：单列堆叠
- **加载方式**：下拉刷新 + 滚动到底部无限加载（继承 [h5.md §2.4](h5.md#24-大列表加载规范list-pagination)）

```vue
<!-- 列表卡片骨架（Tailwind） -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  <article
    v-for="item in items"
    :key="item.id"
    class="bg-white rounded-md border border-slate-200 p-4 shadow-sm hover:shadow-md transition-shadow cursor-pointer"
  >
    <div class="flex items-start justify-between gap-3">
      <div class="min-w-0">
        <h3 class="text-base font-semibold text-slate-900 truncate">{{ item.title }}</h3>
        <p class="text-sm text-neutral mt-1 line-clamp-2">{{ item.summary }}</p>
      </div>
      <van-tag :type="statusType(item.status)">{{ statusText(item.status) }}</van-tag>
    </div>
    <div class="flex items-center justify-between mt-3 pt-3 border-t border-slate-100 text-xs text-neutral">
      <span>{{ formatDate(item.updatedAt) }}</span>
      <van-button size="mini" plain type="primary" @click="onEdit(item)">编辑</van-button>
    </div>
  </article>
</div>
```

### 5.2 表单

表单统一使用 Vant 4 的 `van-form` + `van-cell-group` + `van-field`：

```vue
<van-form @submit="onSubmit" class="bg-white rounded-md border border-slate-200 p-4">
  <van-cell-group inset>
    <van-field
      v-model="form.title"
      name="title"
      label="标题"
      placeholder="请输入标题"
      :rules="[{ required: true, message: '请填写标题' }]"
      @blur="handleInputBlur"
    />
    <van-field name="status" label="状态">
      <template #input>
        <van-radio-group v-model="form.status" direction="horizontal">
          <van-radio name="active">启用</van-radio>
          <van-radio name="disabled">停用</van-radio>
        </van-radio-group>
      </template>
    </van-field>
  </van-cell-group>
  <div class="flex gap-3 mt-6">
    <van-button type="default" block native-type="button" @click="onCancel">取消</van-button>
    <van-button block type="primary" native-type="submit" :loading="saving">保存</van-button>
  </div>
</van-form>
```

- **必填标识**：使用 Vant `required` 属性（Label 右侧显示 `*`）。
- **校验反馈**：错误提示统一为 Danger 色、12px。
- **输入框失焦**：必须绑定 `handleInputBlur`（[h5.md §4.1](h5.md#41-ios-软键盘遮挡与点击错位关键修复)）。

### 5.3 选择器

**禁止使用原生 `<select>`**。统一为：

- **触发**：`readonly` 的 `van-field` + `is-link`
- **弹出**：`van-popup position=bottom round` + `van-picker` / `van-date-picker` / `van-action-sheet`

详细代码范式见 [h5.md §2.3](h5.md#23-下拉框与选择器规范dropdowns--pickers)。

## 6. 按钮规范

| 场景 | 组件 / 类 | 高度 | 圆角 | 字体 |
|------|-----------|------|------|------|
| 主要操作（提交/保存/确认） | `van-button type="primary"` | 40px | `var(--project-radius-sm)` | `text-base font-semibold` |
| 次要操作（取消/返回） | `van-button type="default"` | 40px | `var(--project-radius-sm)` | `text-base` |
| 卡片内联操作 | `van-button size="small" plain` | 28px | `var(--project-radius-sm)` | `text-xs` |
| 高危操作（删除/禁用） | `van-button type="danger" + showConfirmDialog` | 40px | `var(--project-radius-sm)` | `text-base font-semibold` |
| 文字链接 | `RouterLink` 自定义样式 | - | - | `text-sm text-primary` |

- **按压反馈**：Vant 按钮默认带 `active` 状态，**严禁**额外覆盖。
- **防重提交**：所有写操作按钮绑定 `:loading="saving"`，通过 `disabled` 防止重复点击。
- **高危操作**：必须二次确认（`showConfirmDialog`）；涉及资金、删除等写操作时，Dialog 内嵌输入框强制填写**操作原因**。

## 7. 状态反馈

| 反馈类型 | Vant 组件 | 何时使用 |
|----------|-----------|----------|
| 轻提示（成功/失败/警告） | `showToast({ type, message })` | 操作结果的瞬时反馈，2 秒自动消失 |
| 重提示（需要用户确认） | `showConfirmDialog` | 二次确认、删除、停用 |
| 阻塞提示（强提示） | `showDialog` | 系统错误、强制公告 |
| 加载中 | `showLoadingToast({ forbidClick: true })` | 写操作期间遮罩 |
| 空状态 | `van-empty description="..."` | 列表为空 |
| 长操作进度 | `van-circle` 或自定义进度条 | 批量导入/导出 |

### 7.1 错误码统一处理

axios 拦截器必须实现 [api-error-codes.md](api-error-codes.md) 的约定：

```typescript
// services/http.ts
import axios, { AxiosError, InternalAxiosRequestConfig } from 'axios';
import { showToast, showDialog } from 'vant';
import { useUserStore } from '@/stores/user';
import router from '@/router';

http.interceptors.response.use(
  (response) => response.data,
  (error: AxiosError) => {
    const status = error.response?.status;
    const data = error.response?.data as { code?: string; message?: string };
    const userStore = useUserStore();

    switch (status) {
      case 401:
        showToast('登录状态过期，请重新登录');
        userStore.clearAuth();
        router.replace({ name: 'Login', query: { redirect: router.currentRoute.value.fullPath } });
        break;
      case 403:
        showToast('权限不足');
        router.replace({ name: '403' });
        break;
      case 422:
        showToast(data?.message || '输入校验失败');
        break;
      case 500:
        showDialog({ title: '系统错误', message: '服务异常，请稍后重试' });
        break;
      default:
        showToast(data?.message || error.message || '网络错误');
    }
    return Promise.reject(error);
  },
);
```

## 8. 路由与 RBAC

- **基础路由**：`/login`、`/403`、`/404` 不需要权限。
- **受保护路由**：通过 `meta.permission` 声明权限点；路由守卫在 token 校验后比对。
- **白名单**：`['Login', '403', 'NotFound']`。
- **标题**：每个路由 `meta.title`；守卫中拼接项目名。

```typescript
router.beforeEach(async (to) => {
  document.title = `${String(to.meta.title || '')} - ${import.meta.env.VITE_PROJECT_NAME}`

  const auth = useAuthStore()
  if (auth.token && !auth.user) {
    try {
      const result = await getCurrentUser()
      auth.setUser(result.user)
    } catch {
      auth.clearAuth()
    }
  }

  if (to.name !== 'login' && !auth.token) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }
  if (to.name === 'login' && auth.token) {
    return { name: 'dashboard' }
  }

  const needPermission = to.meta?.permission as string | undefined
  if (needPermission && !auth.user?.permissions.includes(needPermission)) {
    return { name: '403' }
  }

  return true
})
```

## 9. 性能与最佳实践

1. **路由懒加载**：除登录页、Dashboard 外，所有页面使用 `() => import('@/views/...')`。
2. **Vant 按需**：必须使用 `unplugin-vue-components` + `VantResolver`，详见 §2。
3. **图片**：列表缩略图 `loading="lazy"`；首屏大图 `fetchpriority="high"`；格式优先 WebP（继承 [h5.md §3.3](h5.md#33-图片优化规范)）。
4. **字体**：使用系统字体栈（`Inter, -apple-system, BlinkMacSystemFont, "Helvetica Neue", "PingFang SC", "Microsoft YaHei", sans-serif`），**禁止**打包中文字体。
5. **打包分析**：构建产物 > 1MB 时，使用 `rollup-plugin-visualizer` 分析并优化。

## 10. 部署规范

1. **环境区分**：通过 `.env.development` / `.env.production` 注入 `VITE_API_BASE_URL`、`VITE_PROJECT_NAME`、`VITE_PRIMARY_COLOR`（可选）。
2. **Nginx 配置**：HTML5 history 模式需要 `try_files` 兜底：

   ```nginx
   server {
       listen 80;
       server_name admin.example.com;
       root /usr/share/nginx/html;
       location / { try_files $uri $uri/ /index.html; }
   }
   ```

3. **CI**：参照 [ci-minimum-gate.md](ci-minimum-gate.md) §"Web 前端"段；最低包含 typecheck + lint + build。

## 11. 迁移指引（从 drink-budget / party-helper admin）

| 来源 | 替换动作 |
|------|----------|
| `App.vue` 中的手机壳样式 | 删除，替换为 §4.1 的 `header + sidebar + main` 骨架 |
| `styles/index.css` 中的硬编码色值 | 替换为 design tokens（§3.1） |
| `tailwind.config.js` 中的 `primary: '#1989fa'` | 替换为 `primary: 'var(--project-primary-color)'` |
| `postcss.config.js` 中的 `postcss-px-to-viewport-8-plugin` | **删除**（PC 优先场景不需要 vw 适配） |
| 自写 CSS 组件（`.login-panel`、`.panel`、`.feedback-card` 等） | 替换为 Vant 4 组件 + Tailwind utility |
| 原生 `<input>` / `<select>` | 替换为 `van-field` + `van-popup + van-picker` |

## 12. 参考

- [ADR-0011](adr/0011-web-admin-baseline.md) — 决策基线
- [ADR-0010](adr/0010-h5-project-baseline.md) — H5 通用基线（向下兼容）
- [h5.md](h5.md) — H5 通用规范（移动端组件、UX 手感、容器兼容）
- [h5-admin.md](h5-admin.md) — 后台管理项目（继承本文档）
- [api-error-codes.md](api-error-codes.md) — API 错误处理
- [monorepo.md](monorepo.md) — Monorepo 实践
- [Vant 官方文档](https://vant-ui.github.io/vant/) — 组件 API
