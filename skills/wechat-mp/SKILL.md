---
name: wechat-mp
description: WeChat native mini-program (微信小程序) development patterns and pitfalls. Use when working in a native TS mini-program project — building pages/components, integrating wx.* APIs, handling login/state/storage, running miniprogram-ci, or troubleshooting runtime limits (2M main package, setData perf, async APIs).
---

# WeChat Mini-Program Skill（原生 + TypeScript）

技术栈 domain 知识。**业务 domain**（ai-todo 任务、drink-budget 预算等）不进本 Skill。

## 何时用

- 在原生 + TS 微信小程序项目里写代码（Page / Component / API 调用）
- 涉及登录、支付、订阅消息、扫码、定位、文件等 wx.* API
- 调 miniprogram-ci 上传
- 处理 setData 性能、主包大小、审核问题
- 写 automator E2E 测试

**不适用**：Taro / uni-app 跨端、云开发为主项目、插件市场、硬件小程序。

## 标准库对齐

本 Skill 是 [playbook/wechat-mp.md](../../../playbook/wechat-mp.md) 的"工具书"。**决策与基线以 wechat-mp.md 为准**，本文给具体模式与坑点。

## 核心约定（必读）

### 1. 异步 API 全部 Promise 化

`wx.request` / `wx.login` / `wx.getStorage` 等原生 API 默认 callback，**项目里禁止直接用 callback**。统一用 [miniprogram-api-promise](https://github.com/wechat-miniprogram/api-promise) 全局 patch：

```ts
// miniprogram/app.ts
import { promisifyAll } from 'miniprogram-api-promise';

const wxp = {} as Record<string, any>;
promisifyAll(wx, wxp);  // 给 wx 上的所有函数补 Promise 版本
(globalThis as any).wxp = wxp;
```

```ts
// 使用
const res = await wxp.request({ url, method: 'GET' });
// 不要写：wx.request({ ..., success: r => ... })
```

### 2. 网络层走 `services/http.ts`

**禁止**在页面/组件里直接 `wxp.request`。统一过 `services/http.ts`：

```ts
// miniprogram/services/http.ts
interface RequestOpts {
  url: string;
  method?: 'GET' | 'POST' | ...;
  data?: unknown;
  // 见 api-error-codes.md
}

export async function http<T>(opts: RequestOpts): Promise<T> {
  const token = wx.getStorageSync('token');
  const res = await wxp.request({
    url: `${BASE_URL}${opts.url}`,
    method: opts.method ?? 'GET',
    data: opts.data,
    header: { Authorization: token ? `Bearer ${token}` : '' },
  });
  if (res.statusCode >= 400) throw new ApiError(res.data);
  return res.data as T;
}
```

错误格式遵循 [playbook/api-error-codes.md](../../../playbook/api-error-codes.md)。

### 3. 登录流程

```text
wx.login() → 拿 code
→ POST /api/login { code } → 后端用 code 换 openid + session_key → 签发自家 token
→ 前端把 token 存到 wx.setStorageSync('token')
→ 业务请求 Header: Authorization: Bearer <token>
```

**禁止**：
- 前端持久化 `session_key`
- 用 `openid` 当唯一凭据（多 appid 不通用）
- 跳过 token 校验直接信任前端传的 `userId`

### 4. 状态管理（MobX 模式）

```ts
// miniprogram/stores/todo.ts
import { makeAutoObservable } from 'mobx-miniprogram';

class TodoStore {
  items: Todo[] = [];

  constructor() {
    makeAutoObservable(this);
  }

  async load() {
    this.items = await http<Todo[]>({ url: '/todos' });
  }

  get pendingCount() {
    return this.items.filter(t => !t.done).length;
  }
}

export const todoStore = new TodoStore();
```

```ts
// miniprogram/stores/index.ts —— 给 wxml 用
import { todoStore } from './todo';

export const stores = { todo: todoStore };
```

```ts
// 页面里用 store
import { stores } from '../stores';
Page({
  data: { todo: stores.todo },  // wxml 里直接 todo.items
});
```

```xml
<!-- wxml -->
<view wx:for="{{todo.items}}" wx:key="id">{{item.title}}</view>
<view>待办：{{todo.pendingCount}}</view>
```

注意：MobX-miniprogram 需在 `project.config.json` 开 `enhance: true`、装 `mobx-miniprogram-bindings`。

### 5. 组件设计

- 组件目录 = 组件名 = 4 个文件同名（`<name>.ts/.wxml/.wxss/.json`）
- 组件用 **Component({...})**，不用 Page
- 父子通信：props down (`properties`)，events up (`triggerEvent`)
- 复杂状态：父组件订阅 store，子组件纯展示

```ts
// miniprogram/components/todo-item/index.ts
Component({
  properties: {
    item: { type: Object, value: null },
  },
  methods: {
    onTap() {
      this.triggerEvent('toggle', this.data.item.id);
    },
  },
});
```

### 6. 存储分层

| 数据 | 位置 |
|---|---|
| token | `wx.setStorageSync`（**不**用 globalData） |
| 缓存的业务数据 | `wx.setStorageSync` 带前缀 `cache:`，并加 TTL 字段 |
| 用户偏好 | `wx.setStorageSync` |
| 临时状态（页面内） | Page `data` |
| 全局跨页状态 | MobX store |
| 大文件/图片 | `wx.getFileSystemManager`，**不**进 Storage |

## 关键限制（3 个最容易踩）

### 主包 ≤ 2MB（2024 起严格 2M）

- 图片资源**必须**放 CDN 或分包，不要 import 进 miniprogram/
- 使用 `subpackages` 配置分包子包
- 依赖体积：`taro-cli` / `lodash` 这类大库**慎用**

### setData 性能

- 单次 setData 数据 ≤ 1MB
- 避免 `setData({ items: this.data.items.concat([...]) })` 这种全量更新 → 用 MobX 自动追踪或局部更新
- wxml 不要渲染超长列表（>500 项），用 `recycle-view` 或分页

### 异步 API 兼容性

- `wx.getUserProfile` 已被回收（2022），用**头像昵称填写**组件（`button open-type="chooseAvatar"`）
- 订阅消息：必须用户**主动**点击 `button open-type="subscribe"` 才弹
- `wx.getSystemInfoSync` 改用 `wx.getDeviceInfo` / `wx.getWindowInfo`

## 跑起来检查

新页面/新组件前先扫：

- [ ] 异步 API 走 `wxp.*`（promisified），不走 `wx.*` 的 callback 形式
- [ ] 网络请求走 `services/http.ts`，不在页面里裸调
- [ ] 登录态校验在 `http.ts` 统一处理（401 → 跳登录）
- [ ] 组件 props 类型显式声明
- [ ] 主包体积未超 2M（CI 加 `size-limit` 检查，见 [playbook/wechat-mp.md §CI 最低门槛](../../../playbook/wechat-mp.md)）
- [ ] 用户协议 / 隐私协议在小程序后台配置（首次提交审核时人工）

## 参考（按需查）

- [references/api-patterns.md](references/api-patterns.md) — 常用 wx.* API 的 TS 模式
- [references/component-patterns.md](references/component-patterns.md) — 组件设计模式
- [references/network-and-auth.md](references/network-and-auth.md) — http.ts 与登录态
- [references/testing-automator.md](references/testing-automator.md) — miniprogram-automator E2E
- [references/miniprogram-ci.md](references/miniprogram-ci.md) — CI 上传与发布
- [references/pitfalls.md](references/pitfalls.md) — 常见坑（审核、兼容性、性能）

## 外部权威

- [微信小程序官方文档](https://developers.weixin.qq.com/miniprogram/dev/framework/)
- [miniprogram-ci](https://developers.weixin.qq.com/miniprogram/dev/devtools/ci.html)
- [miniprogram-automator](https://developers.weixin.qq.com/miniprogram/dev/devtools/auto/automator.html)
- [mobx-miniprogram](https://github.com/wechat-miniprogram/mobx-miniprogram)
