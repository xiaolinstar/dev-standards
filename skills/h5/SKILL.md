---
name: h5
description: Mobile H5 web development patterns and pitfalls (Vue 3 + Vant 4 + TypeScript). Use when building H5 mobile web pages — C-end landing pages, in-app webviews, WeChat share pages, or admin dashboards with mobile-first design. Covers viewport (vw) adaptation, mobile UX components (picker/popup/infinite-list), iOS keyboard fixes, WebView compatibility, and performance optimization.
---

# H5 Mobile Web Skill（Vue 3 + Vant 4 + TypeScript）

技术栈 domain 知识。**业务 domain**（具体产品逻辑、营销活动等）不进本 Skill。

## 何时用

- 在 Vue 3 + Vant 4 + TypeScript 项目里开发移动端 H5 页面
- C 端推广页、App 内嵌 WebView、微信分享网页
- 运营管理后台（移动端优先 + PC 沙盒兼容）
- 涉及 viewport 适配、移动端手势交互、微信 JS-SDK
- 处理 iOS WebView 兼容性问题

**不适用**：PC 优先后台管理系统（Element Plus）、React / React Native、原生 App 开发。

## 标准库对齐

本 Skill 是 [playbook/h5.md](../../playbook/h5.md) 和
[playbook/h5-admin.md](../../playbook/h5-admin.md) 的"工具书"。
**决策与基线以 playbook 为准**，本文给具体模式与坑点。

## 核心约定（必读）

### 1. Viewport vw 适配

设计基准 `375px`，使用 `postcss-px-to-viewport-8-plugin` 编译时将 `px` → `vw`。
开发时直接写 px，**不要手算 vw**。

```ts
// postcss.config.js 核心配置
module.exports = {
  plugins: {
    'postcss-px-to-viewport-8-plugin': {
      viewportWidth: 375,
      unitPrecision: 5,
      viewToReplace: 'vw',
      selectorBlackList: ['.sandbox-container'], // PC 沙盒不转换
      minPixelValue: 1,
      mediaQuery: false,
      exclude: [/node_modules/],
    },
  },
};
```

PC 大屏沙盒居中：外层 `.sandbox-container` 限宽 `375px~480px` 居中，内部正常 vw 适配。

详细配置见 → [references/postcss-config.md](references/postcss-config.md)

### 2. 严禁原生 `<select>`

**所有下拉选择统一采用 readonly van-field + van-popup + van-picker 范式**：

```vue
<!-- 触发只读输入框 -->
<van-field
  v-model="selectedLabel"
  is-link
  readonly
  label="分类"
  placeholder="请选择"
  @click="showPicker = true"
/>

<!-- 底部弹出选择器 -->
<van-popup v-model:show="showPicker" position="bottom" round>
  <van-picker
    :columns="columns"
    title="请选择分类"
    @confirm="onConfirm"
    @cancel="showPicker = false"
  />
</van-popup>
```

日期选择同理，用 `van-date-picker` 替代 `<input type="date">`。

### 3. 触控面积 ≥ 44px

移动端按钮和可点击区域最小物理尺寸 `44px × 44px`。
重要交互按钮必须加按压弹性微动效：

```css
.btn-primary {
  min-height: 44px;
  min-width: 44px;
}
.btn-primary:active {
  transform: scale(0.97);
  opacity: 0.9;
  transition: all 100ms ease;
}
```

写操作按钮点击后立即 `loading` / `disabled`，防重提交。

### 4. 上拉无限滚动

**严禁数字翻页按钮**。列表统一用 `van-list` + `van-pull-refresh`：

```vue
<van-pull-refresh v-model="refreshing" @refresh="onRefresh">
  <van-list
    v-model:loading="loading"
    :finished="finished"
    finished-text="没有更多了"
    @load="onLoad"
  >
    <div v-for="item in list" :key="item.id">
      <!-- 列表项 -->
    </div>
  </van-list>
</van-pull-refresh>
```

```ts
const onLoad = async () => {
  const res = await fetchList(page.value);
  list.value.push(...res.data);
  loading.value = false;
  if (res.data.length < pageSize) finished.value = true;
  page.value++;
};

const onRefresh = async () => {
  page.value = 1;
  list.value = [];
  finished.value = false;
  await onLoad();
  refreshing.value = false;
};
```

### 5. iOS 软键盘 blur 修复

iOS WebView 收起键盘后页面高度不恢复，点击区域错位。
**所有 input/textarea 的 blur 事件必须触发滚动重置**：

```ts
const handleInputBlur = () => {
  // 强制页面微滚动，让 iOS WebView 重新校准高度
  window.scrollTo(0, Math.max(
    document.body.clientHeight,
    document.documentElement.clientHeight
  ));
};
```

```vue
<van-field @blur="handleInputBlur" ... />
```

### 6. 弹窗背景锁定

弹窗打开时锁死 body 滚动，防止底层橡皮筋穿透：

```ts
watch(showPopup, (val) => {
  document.body.style.overflow = val ? 'hidden' : '';
});
```

建议封装为 `useBodyScrollLock(visible: Ref<boolean>)` composable 复用。

### 7. 路由懒加载

除登录页和首页外，所有页面动态 import：

```ts
// router/index.ts
const routes: RouteRecordRaw[] = [
  { path: '/login', component: () => import('@/views/login/index.vue') },
  { path: '/', component: () => import('@/views/home/index.vue') },
  { path: '/detail/:id', component: () => import('@/views/detail/index.vue') },
];
```

Vant 按需引入（**严禁** `main.ts` 全量 import）：

```ts
// vite.config.ts
import Components from 'unplugin-vue-components/vite';
import { VantResolver } from '@vant/auto-import-resolver';

export default defineConfig({
  plugins: [
    Components({ resolvers: [VantResolver()] }),
  ],
});
```

### 8. 图片优化

- 所有装饰/插图优先输出 **WebP**（体积减少 30%~50%）
- 首屏 Banner/Hero 图加 `fetchpriority="high"`
- 非首屏图片加 `loading="lazy"`

```html
<!-- 首屏大图 -->
<img src="banner.webp" fetchpriority="high" alt="Banner" />

<!-- 列表缩略图 -->
<img src="thumb.webp" loading="lazy" alt="Thumb" />
```

### 9. Axios 拦截器

**禁止**在页面/组件里直接 `axios.get/post`。统一过 `services/http.ts`：

- 请求拦截：注入 Bearer token
- 响应拦截：统一处理 401 → 登录页、403 → 403 页、500 → 弹窗

详细实现见 → [references/http-interceptor.md](references/http-interceptor.md)

### 10. 微信 JS-SDK

- OAuth code 必须使用后立即从 URL 清洗，防止刷新/分享导致 code 复用 500
- 分享卡片在 `wx.ready` 回调中配置

```ts
// 清洗 OAuth code
const url = new URL(window.location.href);
if (url.searchParams.has('code')) {
  const code = url.searchParams.get('code')!;
  await loginWithCode(code);
  url.searchParams.delete('code');
  url.searchParams.delete('state');
  window.history.replaceState({}, '', url.toString());
}
```

详细实现见 → [references/wechat-jssdk.md](references/wechat-jssdk.md)

---

## 运营后台专有扩展

适用于 H5 运营管理后台项目（继承上述所有通用约定）。决策基线见 [playbook/h5-admin.md](../../playbook/h5-admin.md)。

### 卡片式数据替代表格

移动端屏幕宽度不足以展示传统表格。数据展示统一用卡片流：

```vue
<div class="card" v-for="item in list" :key="item.id">
  <div class="card-header">{{ item.title }}</div>
  <div class="card-body">
    <span class="label">状态</span>
    <van-tag :type="item.statusType">{{ item.statusText }}</van-tag>
  </div>
</div>
```

### 高危操作二次确认

删除、审核通过/拒绝等高危操作，必须 `van-dialog` 二次确认 + 原因输入：

```ts
import { showDialog } from 'vant';

const handleDelete = async (id: string) => {
  await showDialog({
    title: '确认删除',
    message: '删除后不可恢复，是否继续？',
    showCancelButton: true,
  });
  await deleteItem(id);
};
```

审核拒绝时必须强制填写拒绝原因（`van-field` 内嵌 dialog）。

### 移动端图表

轻量图表用 AntV F2（移动端优先）或 ECharts 移动模式：

```ts
import F2 from '@antv/f2';

const chart = new F2.Chart({
  id: 'chartCanvas',
  pixelRatio: window.devicePixelRatio,
});
```

### RBAC 动态路由

基于角色的路由过滤，搭配 Pinia `userStore`：

```ts
// stores/user.ts
export const useUserStore = defineStore('user', () => {
  const roles = ref<string[]>([]);
  const permissions = ref<string[]>([]);

  const hasPermission = (perm: string) => permissions.value.includes(perm);

  return { roles, permissions, hasPermission };
});
```

```ts
// router/guard.ts — 动态添加路由
router.beforeEach(async (to) => {
  const userStore = useUserStore();
  if (!userStore.roles.length) {
    const { roles, routes } = await fetchUserInfo();
    userStore.roles = roles;
    routes.forEach((r) => router.addRoute(r));
    return to.fullPath; // 重新导航
  }
});
```

### PC 沙盒布局

`App.vue` 外层包裹 `.sandbox-container`，PC 大屏居中限宽：

```vue
<!-- App.vue -->
<template>
  <div class="sandbox-container">
    <router-view />
  </div>
</template>

<style>
.sandbox-container {
  max-width: 480px;
  min-width: 375px;
  margin: 0 auto;
  min-height: 100vh;
  background: #f5f5f5;
  box-shadow: 0 0 20px rgba(0, 0, 0, 0.1);
}
</style>
```

注意 `.sandbox-container` 需加入 postcss 的 `selectorBlackList`，不参与 vw 转换。

---

## 关键限制（3 个最容易踩）

### 首屏加载 3 秒定律

移动端首屏加载超 3 秒用户流失率骤增。必须：

- 路由懒加载 + Vant 按需引入
- 首屏图片 WebP + fetchpriority
- 关键 CSS 内联或预加载

### 中文字体禁止首屏加载

中文字体包动辄数兆，**严禁**首屏引入。统一用系统 fallback 栈：

```css
font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue",
  "PingFang SC", "Microsoft YaHei", sans-serif;
```

### 微信 WebView OAuth code 必须清洗

微信 OAuth 授权返回的 `code` 是一次性的。如果不从 URL 中移除：

- 用户刷新页面 → code 复用 → 后端返回 500
- 用户分享链接 → 他人打开带过期 code 的 URL → 500

**必须**在使用后立即 `history.replaceState` 清洗。

---

## 跑起来检查

新页面/新组件前先扫：

- [ ] viewport meta 包含 `viewport-fit=cover`
- [ ] `postcss.config.js` 配置 `px-to-viewport`（375 基准）
- [ ] 无原生 `<select>` 标签（全部用 van-field + van-popup + van-picker）
- [ ] 按钮触控面积 ≥ 44px
- [ ] 列表用 `van-list` 无限滚动，无数字翻页
- [ ] input blur 有 iOS 软键盘修复
- [ ] 路由按需懒加载（动态 import）
- [ ] Vant 按需引入（`unplugin-vue-components`）
- [ ] 图片用 WebP 格式

## 参考（按需查）

- [references/postcss-config.md](references/postcss-config.md) — PostCSS px-to-viewport 完整配置
- [references/http-interceptor.md](references/http-interceptor.md) — Axios 请求拦截器参考实现
- [references/wechat-jssdk.md](references/wechat-jssdk.md) — 微信 JS-SDK 分享与授权参考

## 外部权威

- [Vant 4 官方文档](https://vant-ui.github.io/vant/)
- [postcss-px-to-viewport-8-plugin](https://github.com/nicolo-ribaudo/postcss-px-to-viewport-8-plugin)
- [Google Web Vitals](https://web.dev/vitals/)
- [微信 JS-SDK 文档](https://developers.weixin.qq.com/doc/offiaccount/OA_Web_Apps/JS-SDK.html)
