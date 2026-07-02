# drink-budget/apps/admin 审计报告

> **审计日期**：2026-07-02
> **审计依据**：[web.md](../web.md)、[h5-admin.md](../h5-admin.md)、[ADR-0011](../adr/0011-web-admin-baseline.md)
> **结论摘要**：项目当前 **mobile-first（手机壳沙盒）** 实现，与新基线 **PC 优先自适应** 完全相反；Token / 布局 / PostCSS / Vant 全量引入均偏离规范，需较大改造。

## A. 技术栈与配置

- **A1. TypeScript strict**：✅ — `tsconfig.json:7` `strict: true`
- **A2. Vant 按需**：⚠ — `vite.config.ts:11-15` 已配 `unplugin-vue-components + VantResolver`，但 `src/main.ts:8` 仍 `import 'vant/lib/index.css'`（全量样式）。需删除该行。
- **A3. Tailwind token 对齐**：⚠ — `tailwind.config.js:10` `colors.primary = '#1989fa'`（硬编码）。`screens` / `borderRadius` / `spacing.safe-*` / `maxWidth.container` 全缺失。
- **A4. PostCSS 配置**：✗ — `postcss.config.js:5-13` 仍启用 `postcss-px-to-viewport-8-plugin`（viewportWidth=375）。**必须删除**。
- **A5. Vite 配置**：⚠ — `host 0.0.0.0 / port 3000 / proxy /api → 127.0.0.1:8000` 满足要求；端口未走 `.env`。

## B. Design Tokens

- **B1. CSS 变量定义**：✗ — `src/styles/index.css:6-8` 仅 `--van-primary-color` 一项，无任何 `--project-*` token。
- **B2. Vant 主题变量绑定**：⚠ — 只绑定 `--van-primary-color` 且硬编码 `#1989fa`，缺 success/danger/warning/button-default-height 等。
- **B3. 硬编码色值**：
  - `src/styles/index.css:7` `--van-primary-color: #1989fa;`
  - `src/styles/index.css:13` `body { background-color: #f1f5f9; }`
  - `src/views/products/edit.vue:15` `<van-loading color="#1989fa">`
  - `src/views/products/edit.vue:43/53/63/73` 四个 `<van-radio checked-color>` 全部硬编码 `#64748b/#f59e0b/#10b981/#ef4444`

## C. 布局与导航

- **C1. 三段式骨架**：✗ — `src/App.vue:30-42` 是手机壳沙盒（`.sandbox-container w-[375px] sm:rounded-[36px] sm:shadow-[...]` + 刘海凹槽 :32）。
- **C2. 手机壳伪容器**：✗ 完全保留
  - `App.vue:4-27` PC 端左侧"手机壳预览介绍"
  - `App.vue:30` `sm:w-[375px] sm:rounded-[36px] ...`
  - `App.vue:32` `<div class="hidden sm:block ... bg-slate-800 rounded-b-2xl">`（刘海）
  - `App.vue:65-68` `@media (min-width:640px) { .sandbox-container { width:375px !important; height:812px !important } }`
  - `postcss.config.js:9` `selectorBlackList: ['.ignore-vw', '.sandbox-container']`
- **C3. 路由切换动画**：✅ `<transition name="fade-slide" mode="out-in">`，但方向用 `translateX(20px/-20px)` 而非规范建议的 `translateY(6px)`。
- **C4. 移动端侧栏抽屉**：✗ — 项目无侧栏；`dashboard` 用 `van-tabbar` 移动端 tabbar，无 `header + sidebar + main` 模式。

## D. 列表与表单

- **D1. van-form + van-cell-group + van-field**：✅ — login/users/products/edit/review 均使用此范式
- **D2. 原生 select / input[type="date"]**：✅ 无残留
- **D3. 原生 select → van-popup + van-picker 范式**：✅ — 状态选择通过 `van-dropdown-item`，表单用 `van-radio-group`
- **D4. 列表卡片化 + van-pull-refresh + 无限加载**：⚠ — products/index、review/index、publish/index 均有 `van-pull-refresh`；但 `review/index.vue:23-67` 缺 `van-list` 分页
- **D5. PC 端横向大表格**：✅ — 纯卡片化，无 `<table>`

## E. 按钮与高危操作

- **E1. 使用 van-button**：✅ — 所有写操作均 `van-button`
- **E2. 高危操作二次确认 + 原因输入**：⚠
  - `products/index.vue:243-257`（同步 Seed，高危）只有普通 confirm，无 reason
  - `users/index.vue:148-155`（停用/启用账号）只有普通 confirm，无 reason
  - `users/index.vue:158-162`（`editRole` 直接改角色）**无任何确认** —— 违反 h5-admin.md §3.2
  - `products/edit.vue:315-344`（保存产品改状态为 offline）无 reason
  - `users/index.vue:141-144`（`resetPassword`）无 confirm

## F. 错误处理与路由守卫

- **F1. Axios 拦截器**：✅ — `src/services/http.ts:23-50` 实现 401/403/422/500 四分支 + `data.detail`/`data.message` 双取值 + 业务 `res.code !== 200` 分支
- **F2. 路由守卫**：⚠ — 实现白名单 + token 校验 + `meta.permission`；但 `:93` 二次拉用户信息后未比对权限即放行
- **F3. 路由 meta.title 拼接项目名**：✗ — `router/index.ts:73` 硬编码"运营后台"，未用 `VITE_PROJECT_NAME`

## G. 视图页面覆盖度

| 文件 | 状态 |
|------|------|
| `dashboard/index.vue` | ⚠ — 渐变 banner + 浮动统计卡 + 9 宫格 `van-grid` + `van-tabbar`，mobile-first |
| `login/index.vue` | ✅ — `van-form + van-cell-group inset + van-field` + `van-popup` 初始化 owner |
| `error/403.vue` | ✅ — 极简 |
| `error/404.vue` | ✅ — 极简 |
| `users/index.vue` | ⚠ — 卡片列表正确；但 `editRole` 跳过 confirmDialog，`resetPassword` 无 confirm |
| `products/index.vue` | ⚠ — `van-pull-refresh + van-list` 正确；但 `handleSyncSeed` 高危无 reason |
| `products/edit.vue` | ✗ — `:15/43/53/63/73` 五处硬编码颜色；opStatus 切换无 confirm |
| `review/index.vue` | ⚠ — 缺 `van-list` 分页；`handleSubmitUpdate` 无 confirmDialog |
| `publish/index.vue` | ⚠ — 品牌枚举写死 chagee/alittle/heytea |

## H. 部署与 CI

- **H1. .env.example**：✗ — 只有 `VITE_API_BASE_URL=/api`，缺 `VITE_PROJECT_NAME` / `VITE_PRIMARY_COLOR`
- **H2. Nginx try_files 兜底**：✅ — `nginx.conf:6-9` 正确
- **H3. Dockerfile build**：✅ — `Dockerfile:18-19` `pnpm -F @drink-budget/admin build` 显式 build；多阶段 build

## 差距汇总（按优先级）

### P0 必修
1. 删除手机壳沙盒（`App.vue:1-71` + `postcss.config.js:5-13` + `package.json:36`）
2. 替换为三段式骨架（按 web.md §4.1）
3. 建立完整 design tokens（重写 `styles/index.css`，新增 `tokens.css` / `brand.css`）
4. Tailwind 与 token 对齐（`tailwind.config.js` 颜色用 var，新增 screens/borderRadius/spacing/maxWidth）
5. 修复 Vant 全量样式引入（删除 `main.ts:8`）
6. 修复路由 meta.title（拼接 `VITE_PROJECT_NAME`）

### P1 重要
1. 路由守卫权限漏洞（`router/index.ts:91-100` 在 `getUserInfo()` 后必须先比对 `meta.permission`）
2. 补齐高危操作 reason 输入（8 处 view）
3. 消除组件内硬编码色值（`products/edit.vue` 五处）
4. `review/index.vue` 补 `van-list` 分页
5. 品牌枚举改动态（`review/index.vue:203-208`、`publish/index.vue:130-135`）

### P2 建议
1. 路由过渡动效方向改为 `translateY(6px)`
2. 图标统一抽组件
3. 路由懒加载拆 static/dynamic
4. HTTP 拦截器 401 后清理 auth
5. Dashboard 风格调整（去掉 mobile-only 渐变 banner）
6. 登录页 Owner Bootstrap 入口生产环境隐藏

## 迁移工作量估算

| 工作项 | 估时 |
|---|---|
| P0（手机壳删除 + 三段式 + tokens + Tailwind + PostCSS/Vant 清理） | 1.5 ~ 2 人日 |
| P1（路由守卫 + 高危 reason × 8 处 + 硬编码色 + review 分页 + 品牌动态化） | 1 ~ 1.5 人日 |
| P2（图标/动效/Dashboard/环境变量收口） | 0.5 人日 |
| **合计** | **3 ~ 4 人日** |

## 整体评价

drink-budget/apps/admin 当前是**彻底的 mobile-first / 手机壳沙盒优先**实现，与 ADR-0011 决策的 **PC 优先自适应** 完全相反；`App.vue` 的手机壳装饰、`postcss-px-to-viewport-8-plugin`、`#1989fa` 硬编码、全量 Vant CSS 引入是四块"硬伤"。组件层（`van-form/cell-group/field/pull-refresh/list/radio/popup`）的范式基本到位，业务代码质量尚可——主要工作是 **布局重构 + Token 体系重建 + 守卫/高危操作规范化**，而非业务重写。