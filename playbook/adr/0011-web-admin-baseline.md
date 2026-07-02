---
ID: 0011
Title: Web 后台基线（PC 优先自适应 + Vant 4 + Tailwind + 品牌色变量）
Status: Accepted
Date: 2026-07-02
Deciders: xingxiaolin
Supersedes: 部分 [ADR-0010](0010-h5-project-baseline.md) §"PC 兼容 ⭐ 沙盒居中容器" 在 admin 场景下的应用方式
---

## 背景

[ADR-0010](0010-h5-project-baseline.md) 给出 H5 通用选型（Vue 3 + Vant 4 + Tailwind + 375 vw 适配），
但对**后台管理**类项目的 PC 兼容策略仅给出"375px~480px 沙盒居中容器"一种方案。

两个真实项目暴露了这条基线在 admin 场景下的**严重分裂**：

- `drink-budget/apps/admin`：Vant 4 + Tailwind，PC 端 375px 手机壳 + 刘海 + 深色阴影；
- `party-helper/apps/admin`：完全不用 Vant 组件，自写 CSS，PC 端 420px 扁平卡片。

同样的"运营后台"，在主题色（`#1989fa` vs `#246bfe`）、按钮、弹窗、列表、Tabbar、字体栈、
断点（640px vs 900px）、PC 沙盒宽度上都不同；用户跨项目使用时**感受不到一致性**。

差异详细对照见本文档末尾附录 A。

## 决策

为 admin 类 Web 项目定义统一基线，作为 [ADR-0010](0010-h5-project-baseline.md) 的 admin 场景细化：

### 1. 一套代码，两端共享：PC 优先自适应

不再以"手机壳预览"作为 PC 兼容方案。改为：

- **小屏（< 768px）**：单列堆叠、底部 tabbar、卡片化列表、触控 ≥44px。
- **中屏（768~1024px）**：双列卡片、抽屉式详情。
- **大屏（≥ 1024px）**：栅格化（grid + 12 列）、顶部水平导航、抽屉变侧栏。
- **大屏容器上限**：`max-width: 1280px`，左右内边距自适应。

**理由**：admin 用户在 PC 浏览器上的诉求是"和 Mac/Windows 上看 dashboard 一样"。
强制他们看手机壳是反直觉的；只有 C 端营销页/小游戏才需要保移动端视觉。

### 2. UI 库统一为 Vant 4 + Tailwind

- **Vant 4** 用于：表单（Field / CellGroup / Form / Radio / Checkbox / Picker / DatePicker）、
  反馈（Popup / Dialog / Toast / Notify / ActionSheet / PullRefresh / List）、
  导航（Tabbar / Tab / NavBar / Grid / Collapse / Empty）。
- **Tailwind utility + CSS 变量** 用于：布局、间距、圆角、阴影、字号、栅格。
- Vant 4 通过 `unplugin-vue-components` + `VantResolver` 自动按需（**严禁**全量 `import 'vant'`）。

**理由**：保留移动端组件的触控一致性是 admin 在手机端可用性的关键；同时让 Vant 组件
在 PC 大屏上也能正常工作（Vant 4 本身已支持桌面断点），不再走自写 CSS 的两条路线。

### 3. 设计 Token 化 + 品牌色变量覆盖

通过 `:root` CSS 变量定义 design tokens，**所有项目共享同一套 token 结构**，
仅通过覆盖 `--project-primary-color` 等变量做品牌色切换：

```css
:root {
  /* Design Tokens —— 跨项目统一，禁止各项目自创 */
  --project-primary-color: #2563eb;       /* 主题蓝（drink-budget/party-helper 各自覆盖） */
  --project-success-color: #10b981;
  --project-warning-color: #f59e0b;
  --project-danger-color: #ef4444;
  --project-neutral-color: #64748b;

  /* 尺寸 token */
  --project-radius-sm: 6px;
  --project-radius-md: 12px;
  --project-radius-lg: 20px;
  --project-radius-pill: 999px;

  /* 间距 token（基于 4 倍数） */
  --project-space-1: 4px;
  --project-space-2: 8px;
  --project-space-3: 12px;
  --project-space-4: 16px;
  --project-space-6: 24px;
  --project-space-8: 32px;

  /* 字号 token */
  --project-text-xs: 12px;
  --project-text-sm: 13px;
  --project-text-base: 14px;
  --project-text-md: 16px;
  --project-text-lg: 18px;
  --project-text-xl: 22px;

  /* 断点 token（同步 Tailwind config） */
  --project-bp-sm: 640px;
  --project-bp-md: 768px;
  --project-bp-lg: 1024px;
  --project-bp-xl: 1280px;
}

/* Vant 4 主题变量绑定到项目色 */
:root {
  --van-primary-color: var(--project-primary-color);
  --van-success-color: var(--project-success-color);
  --van-danger-color: var(--project-danger-color);
  --van-warning-color: var(--project-warning-color);
}
```

**理由**：用户要求"颜色或空间上可以有差异"——但差异必须**只发生在 token 层**，
不得扩散到组件使用、间距、圆角等。

### 4. Tailwind config 与 design tokens 对齐

`tailwind.config.js` 通过 `extend.colors` / `extend.spacing` / `extend.borderRadius`
引用同一组 CSS 变量，让 utility class 与 token 系统保持一致：

```js
// tailwind.config.js
export default {
  content: ['./index.html', './src/**/*.{vue,js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: 'var(--project-primary-color)',
        success: 'var(--project-success-color)',
        warning: 'var(--project-warning-color)',
        danger: 'var(--project-danger-color)',
        neutral: 'var(--project-neutral-color)',
      },
      spacing: {
        'safe-top': 'env(safe-area-inset-top)',
        'safe-bottom': 'env(safe-area-inset-bottom)',
      },
    },
  },
  plugins: [],
}
```

### 5. PC 端布局模板（App.vue）

抛弃手机壳装饰，PC 端采用**水平顶栏 + 内容主区 + 抽屉式侧栏**：

```vue
<!-- App.vue -->
<template>
  <div class="admin-shell bg-slate-50 min-h-screen">
    <!-- 顶部导航（PC 端水平 / 移动端压缩为 logo + 菜单按钮） -->
    <header class="admin-header">
      <div class="admin-header-inner">
        <div class="flex items-center gap-3">
          <button class="md:hidden p-2" @click="sidebarOpen = true">
            <van-icon name="bars" size="20" />
          </button>
          <h1 class="text-lg font-bold">{{ projectName }}</h1>
        </div>
        <nav class="hidden md:flex items-center gap-1">
          <RouterLink
            v-for="item in navItems"
            :key="item.path"
            :to="item.path"
            class="nav-link"
            active-class="nav-link-active"
          >
            {{ item.label }}
          </RouterLink>
        </nav>
        <div class="flex items-center gap-2">
          <span class="text-sm text-slate-500 hidden sm:inline">{{ user?.displayName }}</span>
          <button class="p-2 rounded-full hover:bg-slate-100" @click="handleLogout">
            <van-icon name="cross" size="18" />
          </button>
        </div>
      </div>
    </header>

    <div class="admin-body">
      <!-- 侧栏（PC 端常驻 / 移动端抽屉） -->
      <aside
        class="admin-sidebar"
        :class="{ 'sidebar-open': sidebarOpen }"
        @click.self="sidebarOpen = false"
      >
        <nav class="md:hidden p-4 border-b border-slate-100">
          <RouterLink
            v-for="item in navItems"
            :key="item.path"
            :to="item.path"
            class="sidebar-link"
            active-class="sidebar-link-active"
            @click="sidebarOpen = false"
          >
            {{ item.label }}
          </RouterLink>
        </nav>
      </aside>

      <!-- 主内容区 -->
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
```

样式约定见 [web.md §布局](../web.md#布局与导航)。

### 6. 范围

- admin 类项目（含 drink-budget、party-helper、ai-todo 等）`apps/admin/`
- 不覆盖：C 端营销页、移动端小游戏（继续遵循 [h5.md](../h5.md) 的 vw + 沙盒模式）

### 7. 不覆盖

- Web 项目基础设施（CI、env、目录）→ 见 [monorepo.md](../monorepo.md) / [ci-minimum-gate.md](../ci-minimum-gate.md)
- 后端 API → 不在本 ADR

## 后果

**正面**：

- drink-budget / party-helper admin 在视觉上具备一致骨架，差异化收敛到品牌色。
- PC 浏览器用户不再看到"手机壳"，操作效率与原生后台系统对齐。
- 移动端用户仍可使用 Vant 组件的触控体验。

**负面 / 落地成本**：

- `drink-budget/apps/admin`：删除 `App.vue` 的手机壳装饰、删除 `--van-primary-color` 单独设置、
  接入 CSS 变量体系。
- `party-helper/apps/admin`：删除自写 CSS 组件（`.login-panel`、`.panel`、`.feedback-card` 等），
  改用 Vant 4 + Tailwind + design tokens。
- 模板 `templates/h5-admin/` 同步升级。

## 落地

- [playbook/web.md](../web.md) — Web 后台项目统一规范（PC 优先自适应 + Vant 4 + Tailwind + token）
- [playbook/h5-admin.md](../h5-admin.md) — 继承 H5 通用规范，**App.vue 与 PC 兼容段落更新引用 web.md**
- [templates/h5-admin](../../templates/h5-admin/) — 同步升级
- [playbook/INDEX.md](../INDEX.md) — 注册 web.md + ADR-0011

---

## 附录 A：现有两份 admin 差异对照（迁移基线）

| 维度 | drink-budget/admin | party-helper/admin | 统一目标 |
|------|---------------------|---------------------|----------|
| 主题色 | `#1989fa` | `#246bfe` | 通过 `--project-primary-color` 覆盖 |
| UI 库 | Vant 4 + Tailwind | 自写 CSS（不用 Vant 组件） | Vant 4 + Tailwind |
| Vant 按需 | ✅ `unplugin-vue-components` | ❌ 全量 `import 'vant/lib/index.css'` | ✅ 强制按需 |
| 按钮 | `van-button` (round/plain) | `.primary-action` 等 class | Vant `van-button` |
| 弹窗 | `van-popup position=bottom` | `.detail-mask + .detail-panel` | `van-popup` |
| 表单 | `van-cell-group inset + van-field` | 原生 `<input>` + 自写 CSS | `van-cell-group + van-field` |
| 列表 | 卡片 + `van-grid` + `van-pull-refresh` | `.list-row` + `.feedback-card` | 卡片 + `van-pull-refresh` |
| 顶部导航 | sticky 自写 + `van-icon` | `.page-header` flex | 统一顶部 nav |
| 底部导航 | `van-tabbar` | 无（用文字链接） | 仅小屏 tabbar |
| 字体 | 系统默认 fallback | Inter + 系统栈 | `Inter, -apple-system, ...` |
| PC 沙盒宽度 | 375px（手机壳） | 420px（扁平卡片） | **不再沙盒，PC 优先自适应** |
| PC 断点 | 640px (sm) | 900px | 768 / 1024 / 1280 三档 |
| PC 装饰 | 详细左侧介绍 + 手机刘海 | 简洁 `.desktop-copy` | 顶部 nav + 侧栏 |
| Dashboard 风格 | 渐变 banner + 浮动统计卡 + 9 宫格 + tabbar | page-header + metric-grid + panel | 顶部 nav + content；dashboard 自定 |
| 路由守卫 | async `showLoadingToast` 模式 | 简化版 | 统一 async + token 校验 |
| API 错误处理 | axios 拦截器 | axios 拦截器 | 保持 [api-error-codes.md](../api-error-codes.md) |
