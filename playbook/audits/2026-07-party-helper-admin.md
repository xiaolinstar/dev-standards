# party-helper/apps/admin 审计报告

> **审计日期**：2026-07-02
> **审计依据**：[web.md](../web.md)、[h5-admin.md](../h5-admin.md)、[ADR-0011](../adr/0011-web-admin-baseline.md)
> **结论摘要**：项目**完全偏离基线** —— 全量 Vant CSS、455 行自写 CSS（30 个 class）、零 design token、
> 零三段式骨架、零 `unplugin-vue-components`。**唯一合规**的部分是 TypeScript strict、Pinia + 持久化、
> Axios + 拦截器骨架、路由守卫的 token 校验。迁移策略是 **"删旧换新"** 而非 "原地 patch"。

## A. 技术栈与配置

- **A1. TypeScript strict**：✅ — `tsconfig.json:7` `strict: true`，target ESNext、moduleResolution bundler、
  isolatedModules 全齐
- **A2. Vant 按需**：✗ — `vite.config.ts:1-23` 无 `unplugin-vue-components` / `VantResolver`；
  `main.ts:4` `import 'vant/lib/index.css'` 全量
- **A3. Tailwind 配置**：⚠ — `tailwind.config.js:5-9` 仅 `colors.primary: '#246bfe'`（裸硬编码），
  未引用 token，未配置 screens/borderRadius/spacing 扩展
- **A4. PostCSS 配置**：✗ — 仍启用 `postcss-px-to-viewport-8-plugin`
- **A5. Vite 配置**：⚠ — 仅 alias + dev server proxy，缺 unplugin-vue-components

## B. Design Tokens 与主题色

- **B1. `:root` CSS 变量**：✗ 完全缺失
- **B2. Vant 主题变量绑定**：✗ 完全缺失
- **B3. 硬编码色值清单**（grep 命中 53 处）：

| 文件 | 行 | 颜色 |
|------|----|------|
| `styles/index.css` | 12, 35, 412 | `#eef2f7` |
| `styles/index.css` | 46, 344 | `#f8fafc` |
| `styles/index.css` | 51, 113, 127, 148, 336 | `#246bfe`（5 处） |
| `styles/index.css` | 74, 184 | `#e5e7eb` |
| `styles/index.css` | 88, 196, 243, 330, 369 | `#64748b`（5 处） |
| `styles/index.css` | 97, 288, 413 | `#334155` |
| `styles/index.css` | 106, 155, 266 | `#cbd5e1` |
| `styles/index.css` | 108, 158, 269, 302, 362 | `#0f172a` |
| `styles/index.css` | 256, 438 | `#475569` |
| `styles/index.css` | 287, 310, 349, 360, 367, 428 | `#f1f5f9`（6 处） |
| `styles/index.css` | 385 | `rgb(15 23 42 / 45%)` |
| `styles/index.css` | 446 | `#dbe3ef` |
| `styles/index.css` | 448 | `rgb(15 23 42 / 18%)` |
| `DashboardView.vue` | 269 | `#4f46e5`（inline style） |
| `UsersView.vue` | 161 | `#ef4444`（`confirmButtonColor`） |
| `UsersView.vue` | 206 | `#4f46e5`（inline style） |
| `UsersView.vue` | 290 | `#cbd5e1`（inline style） |
| `UsersView.vue` | 344, 360, 367 | `#f8fafc` / `#f1f5f9` / `#f1f5f9` |
| `UsersView.vue` | 375, 380 | `#0f172a` / `#94a3b8` |
| `UsersView.vue` | 391, 392 | `#dcfce7` / `#15803d` |
| `UsersView.vue` | 396, 397 | `#fee2e2` / `#b91c1c` |
| `UsersView.vue` | 402, 412 | `#475569` / `#64748b` |
| `UsersView.vue` | 417 | `#e2e8f0` |
| `UsersView.vue` | 440, 441, 445 | `#ef4444` / `#fecaca` / `#fef2f2` |

> 53 处硬编码 + 5 处 inline style + 1 处 `confirmButtonColor` 字面量 —— **完全没走 token**。

## C. 自写 CSS 组件清单（重点）

30 个独立 class，分布 `styles/index.css`（24 个）+ `UsersView.vue` scoped（6 个）：

| class | 去向 |
|-------|------|
| `.app-shell` `.admin-container` `.sandbox-container` | **删除** —— 改 web.md §4.1 三段式 |
| `.desktop-copy` | **删除** —— 反基线 |
| `.login-page` `.login-panel` | 替换为 `van-cell-group inset` + Tailwind |
| `.eyebrow` `.muted` `.empty` | 替换为 Tailwind utility |
| `.field` | 替换为 `van-field` |
| `.primary-action` `.secondary-action` `.text-action` | 替换为 `van-button` |
| `.page-header` | 替换为 Tailwind flex utility |
| `.metric-grid` `.metric-card` | 替换为 `grid grid-cols-1 md:grid-cols-3` |
| `.panel` `.panel-heading` | 替换为 Tailwind 或 `van-cell-group` |
| `.dashboard-grid` `.operations-grid` | 替换为 `grid gap-3 lg:grid-cols-2` |
| `.filter-grid` 及其内 input/select | 替换为 `van-cell-group inset` + `van-field` |
| `.action-row` `.status-actions` | 替换为 Tailwind flex |
| `.list-row` | 替换为 `van-cell` 或 grid card |
| `.feedback-card` | 替换为 web.md §5.1 卡片模板 |
| `.audit-row` | 替换为 `van-cell` 或卡片化行 |
| `.detail-mask` `.detail-panel` `.close-action` | 替换为 `van-popup position="bottom" round` |
| `.users-page` `.users-list` `.user-card` | 替换为卡片化列表 + Tailwind |
| `.status-badge` `.badge-active` `.badge-inactive` | 替换为 `van-tag` |
| `.user-header` `.user-meta` `.user-body` `.info-row` `.role-select` `.user-actions` | 替换为 Tailwind |
| `.secondary-action.compact.danger` | 替换为 `van-button size="small" plain type="danger"` |

## D. 布局与导航

- **D1. 三段式骨架**：✗ 完全缺失 —— `App.vue:1-13`
  仅 `<aside class="desktop-copy">` + `<main class="sandbox-container admin-container">` 两段
- **D2. PC 端处理**：✗ —— `index.css:417-455` `@media (min-width:900px)` flex 左右两栏 + 420px 中间卡片 + 阴影 + 圆角；无侧栏、顶部 nav、用户菜单
- **D3. 移动端处理**：⚠ —— 无侧栏抽屉、无底部 `van-tabbar`；nav 用文字链接不规范
- **D4. 路由切换动画**：✗ —— `App.vue:9` 裸 `<RouterView />`

## E. 列表与表单

- **E1. 原生 HTML 表单**（7 处 `<input>`）：LoginView:85, 96 / DashboardView:303, 307 / UsersView:276, 281, 324
- **E2. 原生 `<select>`**（4 处）：DashboardView:311-316（筛选游戏）、DashboardView:319-324（复核状态）、UsersView:240-244（改角色）、UsersView:286-300（新增弹窗的角色）
- **E3. 列表**：`.list-row` × 22、`.feedback-card` × 1 块、`.audit-row` × 1 块；**全部非卡片化**；**没有** `van-pull-refresh` / `van-list`
- **E4. PC 端横向大表格**：✅ 无 `<table>`，但代价是没有 PC 端栅格卡片化

## F. 按钮与高危操作

- **F1. 自定义按钮 class vs van-button**：✗ — 14 处 `<button class="primary-action|secondary-action|text-action">`
- **F2. 高危操作确认**：
  - `UsersView.vue:101-104` 切换启用/禁用：`showConfirmDialog`，但**没**强制 reason
  - `UsersView.vue:158-162` 删除：`showConfirmDialog + confirmButtonColor: '#ef4444'`（硬编码），**没**强制 reason
  - 按 h5-admin.md §3.2 —— 删除/写操作应当二次弹窗强制 reason

## G. 错误处理与路由守卫

- **G1. Axios 拦截器**：⚠ — `services/http.ts:22-35` 仅 401 + fallback toast，
  **缺** 403/422/500 分支，**缺** `router.replace({ name: '403' })`
- **G2. 路由守卫**：⚠ — `router/index.ts:22-54` 有 token/login/users 权限校验；
  **缺**白名单数组、**缺** `/403` `/404` 路由（直接 redirect），**缺** `meta.permission`
- **G3. 路由 meta.title 拼接项目名**：⚠ — `router/index.ts:23` 硬编码"Party Helper"，未用 `VITE_PROJECT_NAME`

## H. 视图页面覆盖度

| view | 行数 | 评估 |
|------|------|------|
| `LoginView.vue` | 112 | ✗ — 自写 login-panel / 原生 input / 自写按钮 |
| `DashboardView.vue` | 500 | ✗ — 自写 panel/grid/list-row/feedback-card/detail-mask，原生 select × 2 |
| `UsersView.vue` | 447 | ✗ — scoped CSS 107 行、scoped 徽章、自写 .role-select、原生 select × 2 + input × 2 |

## I. 部署与 CI

- **I1. .env**：⚠ — 仅有 `VITE_API_BASE_URL`；缺 `VITE_PROJECT_NAME` / `VITE_PRIMARY_COLOR` / `.env.development` / `.env.production`
- **I2. Nginx / Dockerfile**：⚠ — admin 无独立 Nginx / Dockerfile；admin 静态产物部署指引缺失

## 差距汇总（按优先级）

### P0 必修

1. Vant 全量 CSS 引入（删除 `main.ts:4` + vite.config 加 unplugin-vue-components）
2. Design Tokens 缺失（新建 `tokens.css` + `brand.css`）
3. Tailwind token 化（`tailwind.config.js` 5 个语义色 + screens/borderRadius/spacing/maxWidth）
4. 删除 `postcss-px-to-viewport-8-plugin`
5. App.vue 改三段式
6. 删除 `.sandbox-container` / `.desktop-copy` / `.admin-container`
7. 原生 input/select 全替换（7 + 4 = 11 处）
8. 按钮全替换（14 处）

### P1 重要

1. 列表卡片化
2. 弹窗 `van-popup` 化
3. 删除 `UsersView.vue` scoped CSS 107 行
4. 高危操作强制 reason
5. Axios 拦截器补全（403/422/500）
6. 路由守卫补全（白名单 + meta.permission + /403 /404）
7. 环境变量补全
8. dashboard 卡片化重排
9. PullRefresh + List 加载
10. 视图扩展（error/403.vue + error/404.vue）
11. 路由懒加载

### P2 建议

1. 路由切换动画
2. iOS 输入回弹统一为指令
3. 构建产物分析（rollup-plugin-visualizer）
4. CI 门槛
5. 字体栈统一
6. README 同步
7. 安全区工具类

## 迁移工作量估算

| 项 | 数量 |
|----|------|
| 需改写 .vue | 3（LoginView / DashboardView / UsersView）+ App.vue 整体重写 |
| 需新增 .vue | 3（error/403.vue、error/404.vue、components/AdminShell.vue 可选） |
| 需删/重写 .css | `styles/index.css` 455 行**全删** → `tokens.css`（~100 行）+ `brand.css`（~10 行） |
| scoped CSS | `UsersView.vue:341-447` 共 107 行删除 |
| 自写 composable | `useBodyScrollLock.ts` 19 行可丢 |
| 硬编码色值清理 | **53 处** + 3 inline style + 1 `confirmButtonColor` |
| Vant 组件新增引用 | ~40~50 处 |
| vite.config 改造 | ~15 行 |
| PostCSS 改造 | ~10 行删除 |
| 拦截器改造 | 5~10 行 |
| 路由守卫改造 | 10~15 行 + 2 错误页 |
| **估时** | **2~3 人日**（比 drink-budget 看似量大，但全是"删旧换新"） |

## 整体评价

party-helper/apps/admin 是**当前两套 admin 中最偏离基线的一个**：全量 `import 'vant/lib/index.css'`、
455 行自写 CSS（30 个 class）、零 design token、零三段式骨架、零 `unplugin-vue-components`，
并且还在跑 `postcss-px-to-viewport-8-plugin`。**唯一合规的部分**是 TypeScript strict、Pinia + 持久化、
Axios + 拦截器骨架、路由守卫的 token 校验。迁移应**先重写 App.vue + styles/index.css，再迁移 3 个 view**，
而不是逐 class 替换。
