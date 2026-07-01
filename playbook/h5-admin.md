# H5 运营管理后台项目标准（Vue 3 + TypeScript + Vant）

> 决策见 [ADR-0010](adr/0010-h5-project-baseline.md)。本文是"怎么用"。
>
> 适用对象：以高频移动端（Mobile H5）访问为主，同时需兼容 PC 浏览器展示的运营管理后台项目。

## 适用范围

- **技术栈**：Vue 3 + Vite + TypeScript + Pinia + Vue Router。
- **UI 组件库**：Vant 4（移动端组件）+ Tailwind CSS（原子类样式及响应式）。
- **场景**：Monorepo 或独立仓库中的 `apps/admin`。

## 立场摘要

| 维度 | 选型 | 理由 |
|---|---|---|
| 语言 | TypeScript `strict: true` | 类型安全，方便在 monorepo 中共享接口类型定义 |
| 核心框架 | Vue 3 (SFC, Composition API) | 模版代码少，开发效率高，适合快速迭代的运营后台 |
| 状态管理 | Pinia | 轻量、天然支持 TS，适合存储 token 及全局配置 |
| 样式系统 | Tailwind CSS + PostCSS Viewport | 快速响应式设计与自动 vw 转换适配 |
| 包管理 | pnpm | 依赖安装快，隔离性强，与 monorepo 标准保持一致 |
| 路由 | Vue Router | 支持动态路由，易于实现基于角色的路由过滤（RBAC） |
| **PC 兼容** ⭐ | **沙盒居中容器（Sandbox Container）** | 在大屏上以 375px~480px 宽度卡片展示，成本最低且保证排版不崩溃 |
| 异步请求 | Axios + 错误拦截 | 熟练的拦截器处理机制，无缝对接 `api-error-codes.md` |

---

## 项目结构

移动端后台应用推荐位于 Monorepo 的 `apps/admin` 目录下：

```text
apps/admin/
├── src/
│   ├── assets/                # 静态资源（图标、图片）
│   ├── components/            # 全局业务组件（如 NavBar, TabBar, PermissionBtn）
│   ├── router/                # 路由配置（静态路由、动态路由及路由守卫）
│   │   ├── index.ts
│   │   └── routes.ts          # 路由表定义
│   ├── stores/                # Pinia Stores
│   │   ├── user.ts            # 用户信息与权限 Store
│   │   └── global.ts
│   ├── styles/  ---

## UI 与设计系统集成（继承 H5 通用规范）

运营后台管理系统（`apps/admin`）的界面设计必须严格遵循 **[H5 项目通用开发规范](h5.md)** 中的尺寸、适配、按钮反馈、输入栏与下拉选择器定义。

在此基础上，针对后台特定的运营场景，追加以下进阶规约：

### 1. 核心业务表格的“移动端平替”

运营后台往往需要展示大量的指标和流水列表。在移动端上，严禁使用 PC 端的横向大表格（会引发排版崩溃或无休止的横向滚动）：

- **卡片式数据单元**：统一将表格行数据平替为圆角卡片列表。每一项包含主标题（加粗）、副信息和醒目的状态标签（如“通过/不通过”）。
- **折叠面板 (Collapse)**：对于信息较多且支持展开查看明细的项，使用 Vant 的 `van-collapse` 列表进行折叠。
- **列表无线滚动加载**：必须采用 `h5.md` 中定义的下拉刷新 + 上拉无限加载的列表交互模式，禁止放置传统的翻页按钮。

### 2. 高危操作的二次确认与风控

由于移动端触控的误触概率极高，管理后台具有修改关键配置、删改任务、扣减项目预算等高特权写操作，必须加入强制安全机制：

- **二次确认**：对所有删除、禁用、或者大额资金变更等有副作用（Side Effects）的操作，必须绑定 `van-dialog` 弹出框进行确认：
  - “确认”动作按钮颜色统一设为 Danger 警示色。
  - 重要的高危操作，在 Dialog 确认框中必须包含一个简易的输入框，强制运营人员**输入操作原因（Reason）**后方可点击确认提交。

```vue
<!-- 高危操作确认交互模版 -->
<script setup lang="ts">
import { showConfirmDialog, showToast } from 'vant';

const handleDangerAction = () => {
  showConfirmDialog({
    title: '高危操作警告',
    message: '确定要废弃此条打卡审批预算吗？此操作无法撤销。',
    confirmButtonColor: '#ef4444' // 使用危险色
  }).then(() => {
    // 调用 API 提交操作
    showToast({ type: 'success', message: '已成功废弃' });
  }).catch(() => {});
};
</script>
```

### 3. 数据可视化图表（Mobile Charts）

运营看板是后台高频组件，图表选型与交互限制如下：

- **图表库选型**：推荐采用 **AntV F2**（阿里开源的轻量级移动端可视化引擎）或 **Apache ECharts（按需打包移动压缩版）**。
- **防止手势冲突**：为避免图表内部手势（如缩放、滑动）与外层沙盒容器、手机系统滑动返回手势产生严重冲突，**禁止在图表内绑定任何复杂的双指缩放（Zoom）和左右滑动拖拽交互**。图表交互仅保留轻触弹出 Tooltip 信息浮动提示。

### 4. 多项目主题色一键换肤

`dev-standards` 支持被 `drink-budget`、`party-helper`、`ai-todo` 等不同品牌风格的项目消费。

- 必须将脚手架中的 `src/styles/variables.css` 的 Vant 样式根变量，关联到当前项目的品牌色：

  ```css
  :root {
    /* 通过品牌色 CSS 变量，使模版具备一键换肤能力 */
    --van-primary-color: var(--project-primary-color, #1989fa);
  }
  ```

### 5. 按钮与操作规范（Buttons）

- **主要/全局操作按钮 (Primary Action Button)**：
  - **场景**：用于登录、新建、保存、提交审批等最终确认行为。
  - **样式**：高度统一为 `44px` (`h-11`)，文字粗细 `font-semibold`，圆角推荐使用 `999px` (`round` 属性) 以产生鲜明的操作导向，或匹配页面卡片用 `12px` (`rounded-xl`)。
- **辅助/内联操作按钮 (Secondary/Inline Action Button)**：
  - **场景**：用于卡片内部的“修改”、“查看详情”、“退回”等次级操作。
  - **样式**：使用 `plain` 朴素模式，高度统一为 `32px` 或 `28px`，圆角固定为 `6px` 或 `8px`。
- **交互手感与微动效**：
  - 可点击元素必须加上按压态缩放动效，使界面拥有“物理反馈弹性”：

    ```html
    <button class="active:scale-[0.97] transition-transform duration-100">...</button>
    ```

  - 所有提交按钮必须绑定 `loading` 属性。在 API 请求开始时开启 Loading，且通过拦截器或 `disabled` 防止重复提交。

### 6. 文本输入栏规范（Text Fields）

表单录入是管理后台高频操作，需兼顾手势触控的容错率：

- **表单容器**：
  - 表单输入框统一包裹在 Vant 的 `van-cell-group inset` 中，自动呈现优雅的浮动圆角卡片样式。
- **布局高度与对齐**：
  - 每一个输入 Field 的最小触控高度不得低于 `48px`。
  - **必填标识**：必填项必须在 Label 左侧或右侧显示红色 `*`（使用 `required` 属性）。
  - **文字对齐**：Label 固定左对齐，占位字宽度合理（一般为 4~5 个中文字符）；输入文本一律采用靠左对齐，但在只读展示单元格中允许右对齐。
- **校验反馈**：
  - 焦点触发时，边框或线条不得出现生硬的颜色闪烁，统一使用 Vant 默认的 Primary 色高亮。
  - 校验失败的错误提示文本统一为 Danger 红色，且字体大小为 `12px`。

---

### 7. 下拉框与选择器规范（Dropdowns & Pickers）

为了保证在所有手机平台（iOS/Android）、所有 App 容器（原生浏览器/微信内置浏览器/钉钉容器）中交互手感的一致性，**禁止使用原生 `<select>` 标签**，统一遵循以下选择器范式：

- **触发态 (Trigger)**：
  - 页面上展示一个只读的 `van-field` 模拟下拉框。配置 `readonly`、`is-link`（右侧显示箭头指示）以及 `click` 事件。
  - 占位符统一使用：`"请选择XXX"`（与输入框的 `"请输入XXX"` 区别开）。
- **弹出选择态 (Popup & Picker)**：
  - 用户点击 Field 后，自底部弹出一个 `van-popup`，Popup 内部嵌套 `van-picker`（单列/多列选择）或 `van-date-picker`（日期选择）或 `van-action-sheet`（快速操作菜单）。
  - Popup 必须具有圆角边缘（设置 `round` 属性，顶部呈现圆角），且提供“取消”与“确认”按钮。

**典型实现代码范式**：

```vue
<template>
  <!-- 触发器 -->
  <van-field
    v-model="selectedValueLabel"
    is-link
    readonly
    label="预算类型"
    placeholder="请选择预算类型"
    @click="showPicker = true"
  />

  <!-- 底部弹窗选择器 -->
  <van-popup v-model:show="showPicker" position="bottom" round>
    <van-picker
      :columns="columns"
      title="请选择预算类型"
      @confirm="onConfirm"
      @cancel="showPicker = false"
    />
  </van-popup>
</template>

<script setup lang="ts">
import { ref } from 'vue';

const showPicker = ref(false);
const selectedValueLabel = ref('');
const columns = [
  { text: '日常餐饮', value: 'food' },
  { text: '交通出行', value: 'transport' },
  { text: '休闲娱乐', value: 'entertainment' }
];

const onConfirm = ({ selectedOptions }: any) => {
  selectedValueLabel.value = selectedOptions[0]?.text || '';
  showPicker.value = false;
};
</script>
```

---

## 核心技术实现规范

### 1. PC 兼容沙盒布局（App.vue）

在 PC 端展示时，网页将以类似手机壳的样式居中卡片展示，背景填充灰色或运营底图。

```vue
<!-- apps/admin/src/App.vue -->
<template>
  <div class="min-h-screen bg-slate-100 flex items-center justify-center p-0 sm:p-4">
    <!-- PC 端留白/背景饰，sm 以上生效 -->
    <div class="hidden lg:block w-80 mr-8 text-slate-500">
      <h1 class="text-2xl font-bold text-slate-800 mb-2">运营管理后台</h1>
      <p class="text-sm">当前已适配移动端高频操作。在 PC 端为您提供沙盒预览模式，所有功能保持一致。</p>
    </div>

    <!-- 手机沙盒容器 -->
    <div class="sandbox-container w-full min-h-screen sm:min-h-[812px] sm:w-[375px] sm:rounded-2xl sm:shadow-2xl bg-white overflow-hidden flex flex-col relative border border-slate-200/50">
      <router-view v-slot="{ Component }">
        <transition name="van-slide-right" mode="out-in">
          <component :is="Component" />
        </transition>
      </router-view>
    </div>
  </div>
</template>

<style>
/* 滚动条美化，仅在 PC 模式下展示 */
.sandbox-container::-webkit-scrollbar {
  width: 4px;
}
.sandbox-container::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 2px;
}
</style>
```

### 2. 移动端 Viewport 适配（postcss.config.js）

为了在开发中直接写 px 而不考虑 Rem 转换，配置 PostCSS 插件：

```javascript
// apps/admin/postcss.config.js
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
    'postcss-px-to-viewport-8-plugin': {
      viewportWidth: 375,          // 设计稿宽度
      viewportUnit: 'vw',          // 希望使用的视口单位
      fontViewportUnit: 'vw',      // 字体使用的视口单位
      selectorBlackList: ['.ignore-vw', '.sandbox-container'], // 忽略的类名（例如沙盒外层容器不转换为 vw）
      minPixelValue: 1,            // 小于或等于 1px 不转换为视口单位
      mediaQuery: false,           // 允许在媒体查询中转换 px
      exclude: [/node_modules/i]   // 排除三方库（Vant 内部已适配或采用自身体系）
    }
  }
}
```

### 3. Axios 请求拦截器与错误处理（services/http.ts）

必须统一拦截 HTTP 状态码并映射到项目错误定义：

```typescript
// apps/admin/src/services/http.ts
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
    // 若后端统一返回 code/data/message 格式
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
```

### 4. 路由拦截与 RBAC 动态鉴权（router/index.ts）

```typescript
// apps/admin/src/router/index.ts
import { createRouter, createWebHistory, RouteRecordRaw } from 'vue-router';
import { useUserStore } from '@/stores/user';
import { showLoadingToast, closeToast } from 'vant';

// 基础路由，无需登录和特殊权限
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

// 白名单路由
const whiteList = ['Login', '403', 'NotFound'];

router.beforeEach(async (to, from, next) => {
  const userStore = useUserStore();
  
  // 设置页面 title
  if (to.meta?.title) {
    document.title = `${to.meta.title} - 运营后台`;
  }

  // 1. 检查是否已登录
  if (userStore.token) {
    if (to.name === 'Login') {
      next({ path: '/' });
    } else {
      // 2. 检查路由权限
      const hasPermissions = userStore.permissions && userStore.permissions.length > 0;
      if (hasPermissions) {
        next();
      } else {
        try {
          showLoadingToast({ message: '获取权限中...', forbidClick: true });
          // 获取用户信息及角色/权限列表
          await userStore.getUserInfo();
          closeToast();
          
          // 动态注册有权限的路由（这里由 userStore 内部实现 router.addRoute）
          await userStore.generateRoutes();
          
          // 确保路由注册成功后重新进入
          next({ ...to, replace: true });
        } catch (err) {
          userStore.clearUserInfo();
          closeToast();
          next({ name: 'Login', query: { redirect: to.fullPath } });
        }
      }
    }
  } else {
    // 3. 未登录跳转登录页
    if (whiteList.includes(to.name as string)) {
      next();
    } else {
      next({ name: 'Login', query: { redirect: to.fullPath } });
    }
  }
});

export default router;
```

---

## 最佳实践与性能优化

1. **Vant 按需加载**：不需要手动导入所有 Vant 组件。推荐使用 `unplugin-vue-components` 自动按需引入，减小打包体积。
2. **移动端安全区适配**：在 `App.vue` 或主要的 Layout 布局页面中，合理添加下方底部安全区样式：

   ```html
   <div class="pb-[safe-area-inset-bottom]">...</div>
   ```

3. **Monorepo 类型共享**：通过 pnpm workspace 导入共享的类型包，避免在后台前端代码中手动复制后端的数据模型定义（DTOs）：

   ```json
   "dependencies": {
     "@drink-budget/shared": "workspace:*"
   }
   ```

4. **Toast 延迟与遮罩**：对于有写操作（提交、修改配置）的 API 请求，必须开启遮罩（`forbidClick: true`），防止用户在网络波动时多次点击触发重复请求。

---

## 部署规范

1. **环境区分**：
   - 必须通过 Vite 的 `.env.development`、`.env.production` 区分后端接口 API 基础地址（`VITE_API_BASE_URL`）。
2. **Nginx 部署配置**：
   - 由于采用前端 HTML5 History 模式（createWebHistory），Nginx 端配置必须加 `try_files` 兜底，防止刷新页面报 404 错误：

     ```nginx
     server {
         listen 80;
         server_name admin.drink-budget.com;
         root /usr/share/nginx/html;

         location / {
             try_files $uri $uri/ /index.html;
             index index.html;
         }
     }
     ```

---

## 参考

- [ADR-0010 — H5 运营管理后台技术选型决策](adr/0010-h5-project-baseline.md)
- [api-error-codes.md](api-error-codes.md) — 统一 API 错误处理规范
- [Vant 官方文档](https://vant-ui.github.io/vant/)
