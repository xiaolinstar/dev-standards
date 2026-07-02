# H5 运营管理后台项目标准（继承 H5 + Web 基线）

> 决策见 [ADR-0010](adr/0010-h5-project-baseline.md)（H5 通用）与 [ADR-0011](adr/0011-web-admin-baseline.md)（Web 后台基线）。本文是"运营后台特有规则"。
>
> 适用对象：以**运营管理后台**形态出现的 H5 项目（C 端高频移动端访问 + 兼顾 PC 浏览器展示）。
> 通用技术栈、布局规范、Design Tokens 全部继承自 [web.md](web.md)；本文仅描述运营后台特有的业务规则。

## 0. 与 web.md 的关系

| 内容 | 归属 |
|------|------|
| 技术栈、版本基线（Vue 3 / Vant 4 / Tailwind） | [web.md §2](web.md#2-技术栈与版本基线) |
| Design Tokens、色板、字体栈 | [web.md §3](web.md#3-design-tokens设计令牌) |
| 布局（header + sidebar + main 三段式） | [web.md §4](web.md#4-布局与导航) |
| 列表 / 表单 / 按钮 / 弹窗 通用规范 | [web.md §5~7](web.md#5-列表--表格--表单) |
| 路由守卫、Axios 拦截器模板 | [web.md §8](web.md#8-路由与-rbac) |
| **运营后台特有规则（本文档）** | **以下章节** |

如 §1 中的"PC 兼容沙盒"已被 **PC 优先自适应**取代（见 [ADR-0011](adr/0011-web-admin-baseline.md)）。

## 1. 立场摘要

| 维度 | 选型 | 理由 |
|---|---|---|
| 语言 | TypeScript `strict: true` | 与 web.md 一致 |
| 核心框架 | Vue 3 + Vite + Pinia + Vue Router | 运营后台迭代频率高，SFC 模板代码少 |
| 样式系统 | Tailwind CSS + Design Tokens | 响应式 + 品牌色覆盖 |
| UI 组件库 | **Vant 4**（按需）+ **原生 HTML 复杂控件** | 移动端组件手感 + PC 端兼容 |
| 包管理 | pnpm | monorepo 一致 |
| **布局策略** | **PC 优先自适应**（继承 [web.md §4](web.md#4-布局与导航)） | 一套代码两端共享，PC 用户无需看手机壳 |
| 异步请求 | Axios + 拦截器 | 对接 [api-error-codes.md](api-error-codes.md) |
| 鉴权 | Token + RBAC 动态路由 | 见 [web.md §8](web.md#8-路由与-rbac) |

---

## 2. 项目结构

Monorepo 中的运营后台推荐位于 `apps/admin` 目录下：

```text
apps/admin/
├── src/
│   ├── assets/                # 静态资源（图标、图片）
│   ├── components/            # 全局业务组件（NavBar, TabBar, PermissionBtn）
│   ├── composables/           # 复用 hooks（如 useBodyScrollLock）
│   ├── router/                # 路由配置（静态路由、动态路由、守卫）
│   │   ├── index.ts
│   │   └── routes.ts          # 路由表定义
│   ├── stores/                # Pinia Stores
│   │   ├── user.ts            # 用户信息与权限 Store
│   │   └── global.ts
│   ├── services/              # API 调用
│   │   ├── http.ts            # Axios 拦截器
│   │   └── *.ts               # 按业务域拆分（products.ts / review.ts / users.ts）
│   ├── styles/
│   │   ├── tokens.css         # Design Tokens（继承 web.md §3）
│   │   └── index.css          # 全局基线样式
│   ├── utils/                 # 工具函数（如 h5.ts 中的 handleInputBlur）
│   ├── views/                 # 页面（按业务模块组织）
│   │   ├── login/
│   │   ├── dashboard/
│   │   └── error/
│   ├── App.vue                # 三段式骨架（继承 web.md §4.1）
│   └── main.ts
├── index.html
├── vite.config.ts
├── tailwind.config.js
├── postcss.config.js
├── tsconfig.json
└── package.json
```

---

## 3. 运营后台特有业务规则

### 3.1 移动端"表格平替"（核心规则）

> [!IMPORTANT]
> 运营后台往往需要展示大量指标和流水。在移动端严禁使用 PC 端的横向大表格
> （会引发排版崩溃或无休止的横向滚动）。

统一采用 **卡片式数据单元**：

- 每一项包含：主标题（加粗）、副信息、状态标签、操作按钮组。
- 信息较多且支持展开的项：使用 Vant 的 `van-collapse`。
- 列表加载：必须采用 **下拉刷新 + 上拉无限加载**（继承 [h5.md §2.4](h5.md#24-大列表加载规范list-pagination)），
  严禁放置传统的翻页按钮。
- PC 端可降级为栅格卡片（每行 1~3 列），见 [web.md §5.1](web.md#51-数据列表替代-pc-端横向大表格)。

### 3.2 高危操作的二次确认与风控

移动端触控的误触概率极高，运营后台的写操作（删除、禁用、扣减预算等）必须加入强制安全机制。

**强制规范**：

- 所有有副作用（Side Effects）的写操作，必须绑定 `showConfirmDialog` 二次确认：
  - "确认"按钮颜色统一为 Danger 色（`var(--project-danger-color)`）。
  - 高危操作（涉及资金、不可逆数据变更）的 Dialog 内**必须**包含简易输入框，
    强制运营人员**输入操作原因（Reason）**后方可点击确认提交。

```vue
<script setup lang="ts">
import { showConfirmDialog, showDialog, showToast } from 'vant'
import { ref } from 'vue'

const reason = ref('')

const handleDangerAction = async () => {
  try {
    await showConfirmDialog({
      title: '高危操作警告',
      message: '确定要废弃此条打卡审批预算吗？此操作无法撤销。',
      confirmButtonColor: 'var(--project-danger-color)',
      showCancelButton: true,
      cancelButtonText: '取消',
      confirmButtonText: '继续',
    })

    // 第二步：强制填写原因
    await showDialog({
      title: '填写操作原因',
      message: '请填写本次废弃的具体原因（将记录到审计日志）',
      prompt: {
        placeholder: '至少 10 个字',
        maxlength: 200,
      },
      showCancelButton: true,
    }).then(({ value }: { value?: string }) => {
      if (!value || value.length < 10) {
        showToast('原因长度不足，操作已取消')
        throw new Error('REASON_TOO_SHORT')
      }
      reason.value = value
    })

    // 调用 API 提交
    await submitDangerAction({ reason: reason.value })
    showToast({ type: 'success', message: '操作完成' })
  } catch (err) {
    // 用户取消或校验失败
  }
}
</script>
```

### 3.3 数据可视化图表

- **图表库选型**：推荐 **Apache ECharts（按需打包）** 或 **AntV F2**（轻量移动端）。
- **防止手势冲突**：图表内**禁止**绑定复杂的双指缩放（Zoom）和左右滑动拖拽交互，
  仅保留轻触弹出 Tooltip（继承 [h5-admin §3.3 历史规范](h5.md#44-移动端webview容器兼容性规范)）。
- **响应式**：图表宽度 `100%`，高度固定（如 `h-64` / `h-72`），禁止固定像素。

### 3.4 多项目品牌色切换

通过覆盖 design tokens 实现一键换肤（继承 [web.md §3.2](web.md#32-项目覆盖示例品牌色)）：

```css
/* src/styles/brand.css —— 项目级品牌色覆盖 */
:root {
  --project-primary-color: #1989fa; /* drink-budget */
  /* 或 */
  /* --project-primary-color: #246bfe; */ /* party-helper */
}
```

**严禁**在组件内直接写 `color: #1989fa` 等硬编码色值，必须使用 Tailwind 的 `text-primary` /
`bg-primary` 或 CSS 变量。

### 3.5 移动端安全区适配

底部 TabBar / Fixed 浮动按钮必须做安全区避让：

```css
.van-tabbar {
  padding-bottom: constant(safe-area-inset-bottom);
  padding-bottom: env(safe-area-inset-bottom);
}
```

或使用 Tailwind 工具类：

```html
<div class="pb-safe-bottom">...</div>
```

### 3.6 单项目特例：tabbar vs 水平 nav

- **小屏（< 768px）**：可使用 `van-tabbar`（底部 3~5 个一级入口）。
- **大屏（≥ 768px）**：使用顶部水平 nav（继承 [web.md §4.1](web.md#41-三段式骨架appvue)）。

二级菜单（账号管理、设置等）放在侧栏 / 用户菜单中，不要堆到 tabbar。

---

## 4. 部署规范

1. **环境区分**：通过 `.env.development`、`.env.production` 注入：
   - `VITE_API_BASE_URL`
   - `VITE_PROJECT_NAME`（影响 `document.title`）
   - `VITE_PRIMARY_COLOR`（可选，影响默认品牌色）
2. **Nginx 配置**：HTML5 history 模式需要 `try_files` 兜底（继承 [web.md §10](web.md#10-部署规范)）。
3. **CI 最低门槛**：typecheck + lint + build（参考 [ci-minimum-gate.md](ci-minimum-gate.md)）。

---

## 5. 参考

- [ADR-0010](adr/0010-h5-project-baseline.md) — H5 通用基线
- [ADR-0011](adr/0011-web-admin-baseline.md) — Web 后台基线（含 PC 优先自适应）
- [web.md](web.md) — Web 项目统一规范（布局、tokens、组件规范）
- [h5.md](h5.md) — H5 通用规范（移动端组件、UX 手感、容器兼容）
- [api-error-codes.md](api-error-codes.md) — API 错误处理
- [monorepo.md](monorepo.md) — Monorepo 实践
- [Vant 官方文档](https://vant-ui.github.io/vant/)
