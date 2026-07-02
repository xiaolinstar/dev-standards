# Admin 迁移路线图（drink-budget + party-helper）

> **日期**：2026-07-02
> **范围**：drink-budget/apps/admin + party-helper/apps/admin
> **目标**：对齐 [web.md](../web.md) + [h5-admin.md](../h5-admin.md) + [ADR-0011](../adr/0011-web-admin-baseline.md)
> **配套原报告**：[drink-budget](2026-07-drink-budget-admin.md) · [party-helper](2026-07-party-helper-admin.md)

## 一、整体定性

| 项目 | 严重度 | 偏离方向 | 工作量 |
|---|---|---|---|
| **drink-budget** | ⚠️ 中 | "mobile-first + 手机壳沙盒" → 反基线 | 3~4 人日 |
| **party-helper** | ✗ 重 | "全自写 CSS + 全量 Vant" → 反基线 | 2~3 人日 |

- drink-budget 用 Vant + Tailwind 做了一套精致的手机壳
- party-helper 完全放弃 Vant 组件，自写 30 个 CSS class + 455 行 index.css

## 二、共同 P0（两份都必须改）

| 项 | 规范出处 |
|---|---|
| 删除手机壳 / 沙盒布局 → 三段式骨架 | [web.md §4.1](../web.md#41-三段式骨架appvue) |
| 建立 Design Tokens | [web.md §3](../web.md#3-design-tokens设计令牌) |
| Tailwind 与 token 对齐（颜色用 `var(--project-*)`、新增 screens/borderRadius/spacing/maxWidth） | [web.md §3.3](../web.md#33-tailwind-与-token-对齐) |
| 删除 `postcss-px-to-viewport-8-plugin` | [ADR-0011 §决策 1](../adr/0011-web-admin-baseline.md) |
| Vant 样式按需（移除 `import 'vant/lib/index.css'`，启用 `VantResolver`） | [web.md §2](../web.md#2-技术栈与版本基线) |
| `VITE_PROJECT_NAME` 注入 + 路由 meta.title 拼接项目名 | [web.md §10](../web.md#10-部署规范) / [§8](../web.md#8-路由与-rbac) |

## 三、各自 P0（项目特有问题）

### drink-budget 独有
- products/edit.vue 4 个 `van-radio checked-color` 硬编码（:43/53/63/73）
- products/edit.vue `<van-loading color="#1989fa">`（:15）
- editRole 直接写无确认（users/index.vue:158-162）
- resetPassword 无确认（users/index.vue:141-144）
- 路由守卫权限漏洞（router/index.ts:91-100）
- review 缺 `van-list` 分页（review/index.vue:23-67）
- 品牌枚举写死（review:203-208、publish:130-135）

### party-helper 独有（量更大）
- 30 个自写 CSS class（455 + 107 = **562 行 CSS**）
- 7 处原生 `<input>`
- **4 处原生 `<select>`**（违反 web.md §5.3）
- 14 处自写按钮 class
- 自写弹窗（`.detail-mask` / `.detail-panel` / `.close-action`）
- `.eyebrow` `.muted` `.empty` 自写小标
- 2 处 inline `style="color:..."`
- 无 `/403` `/404` 路由
- 路由懒加载缺失

## 四、共同 P1

- 高危操作缺 reason 必填（[h5-admin.md §3.2](../h5-admin.md#32-高危操作的二次确认与风控)）
- HTTP 拦截器 403/422/500 分支补全
- 路由守卫白名单 + `meta.permission`
- 路由切换动画

## 五、迁移执行计划（5 个 Phase）

### Phase 1 — 基建升级（半天 / 项目）
基础设施就位，不改 view。

- 1.1 `package.json`：移除 `postcss-px-to-viewport-8-plugin`；加 `unplugin-vue-components`
- 1.2 `vite.config.ts`：unplugin-vue-components + VantResolver
- 1.3 `postcss.config.js`：移除 vw 适配
- 1.4 `main.ts`：移除 `import 'vant/lib/index.css'`
- 1.5 `src/styles/tokens.css`：完整 token 体系
- 1.6 `src/styles/brand.css`：仅 `--project-primary-color` 覆盖
- 1.7 `src/styles/index.css`：清空硬编码色，引用 tokens
- 1.8 `tailwind.config.js`：colors/screens/borderRadius/spacing/maxWidth 对齐 token
- 1.9 `.env.example`：补 `VITE_PROJECT_NAME` / `VITE_PRIMARY_COLOR`

> ✅ Phase 1 是**零风险**：新基础设施就位、现有 view 暂时使用 fallback 默认色（视觉可能略变但不报错）。
> 验证：`pnpm typecheck && pnpm build`

### Phase 2 — 布局重构（半天~1 天 / 项目）
- 2.1 `App.vue` → 三段式骨架
- 2.2 `router/index.ts` → title 拼接 `VITE_PROJECT_NAME`
- 2.3 删除 sandbox/desktop-copy 残留 CSS

### Phase 3 — 视图迁移（1~2 天 / 项目）
- 3.1 login view → `van-form` + `van-cell-group` + `van-button`
- 3.2 dashboard view → 自适应栅格 + `van-pull-refresh`
- 3.3 列表 view → 卡片化（按 web.md §5.1）
- 3.4 详情/弹窗 → `van-popup` 替代 `.detail-mask`
- 3.5 party-helper 专属：清空 `UsersView.vue` scoped CSS 107 行

### Phase 4 — 高危操作合规（半天 / 项目）
- 4.1 抽 `composables/useConfirmDanger.ts`（confirmDialog + prompt 双步）
- 4.2 所有写操作接入 reason 必填
- 4.3 `confirmButtonColor` 改 `var(--project-danger-color)`

### Phase 5 — 收尾（半天 / 项目）
- 5.1 `router/index.ts` 加 `/403` `/404` + 路由懒加载
- 5.2 错误页 `view/error/{403,404}.vue`
- 5.3 dashboard 改为 PC 优先栅格 + 移除 `van-tabbar`
- 5.4 brand 切换冒烟（drink-budget 用 `#1989fa`、party-helper 用 `#246bfe`）

## 六、总工期

- drink-budget：**3~4 人日**
- party-helper：**2~3 人日**
- 合计 **5~7 人日**

建议**串行**：先 drink-budget（Vant 范式已对，主要重 App.vue + tokens），完成后 party-helper 更有把握。

## 七、立即可做的"零风险"动作

无需先建 ADR，今天就能提交：

1. 删除 `postcss-px-to-viewport-8-plugin` 依赖 + `postcss.config.js` 中的插件
2. 删除 `main.ts` 中的 `import 'vant/lib/index.css'`
3. 新建 `styles/tokens.css` + `styles/brand.css` 并引用

这三项**无副作用**且立刻生效。

## 八、风险与回退

| 风险 | 缓解 |
|---|---|
| Vant 样式按需后老组件缺样式 | Phase 1 同步启用 `VantResolver` + 删除全量 import |
| 品牌色切换后硬编码色不生效 | Phase 3 视图迁移时统一替换为 token |
| 路由守卫权限漏洞被攻击 | Phase 4 高危操作合规前先在 http 拦截器加严格校验 |
| 视图大改引入回归 | 每 Phase 跑 `pnpm typecheck && pnpm build`，按 PR 拆分 |

## 九、Phase 1 执行确认

执行 Phase 1 前确认两点：

1. 是否同时启用 `unplugin-vue-components` 与删除全量 Vant CSS？**是**（必须同步）
2. `tokens.css` / `brand.css` 是否引入到 `main.ts`？**是**（合并到 `import './styles/index.css'` 即可）