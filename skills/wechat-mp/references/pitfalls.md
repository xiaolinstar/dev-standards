# 常见坑（按踩到频率排序）

> 配合 [SKILL.md §关键限制](../SKILL.md) 阅读。

## 1. 主包超 2MB

**症状**：`miniprogram-ci` 报错 "分包大小超过限制" 或微信开发者工具上传失败。

**原因**：

- 大量图片资源 import 进了 `miniprogram/images/`
- 引入了大体积 npm 包（如完整 lodash、完整 moment）
- TypeScript 编译后 wxml/wxss 体积膨胀

**解法**：

```json
// project.config.json
{
  "miniprogramRoot": "miniprogram/",
  "setting": {
    "minifyWXSS": true,
    "minifyWXML": true,
    "babelSetting": { "ignore": [], "disablePlugins": [], "outputPath": "" }
  }
}
```

- 图片放 CDN，wxml 用 `<image src="https://cdn.example.com/...">`
- 子包配置 `subpackages`
- CI 加 size 检查：

```yaml
- name: Check main package size
  run: |
    du -sb dist/ | awk '{ if ($1 > 2097152) { print "Main package too big"; exit 1 } }'
```

## 2. setData 性能

**症状**：长列表滚动卡顿，wxml 数据更新有明显延迟。

**解法**：

- 列表用 `wx:key`（必备）
- 单次 setData 数据 ≤ 1MB
- 避免全量 setData：用 MobX 自动追踪，或 `setData({ 'item[3].done': true })` 局部更新
- 超长列表（>500）用 `recycle-view`（官方扩展组件）

```ts
// 错误：全量重传
this.setData({ items: this.data.items.map(t => ({ ...t })) });

// 正确：只改一项
this.setData({ [`items[${idx}].done`]: true });
```

## 3. 异步 API 用了 callback 形式

**症状**：业务代码出现 `wx.request({ ..., success: r => ... })`，导致后续代码不能 await。

**解法**：

- 项目里约定只能用 `wxp.*`（见 [SKILL.md §1](../SKILL.md)）
- 装 `miniprogram-api-promise` 在 `app.ts` 一次性 patch
- 代码 review 拦截

## 4. `wx.getUserProfile` 已废弃

**症状**：审核被拒"获取用户信息接口使用不当"。

**解法**：用**头像昵称填写**组件：

```xml
<button open-type="chooseAvatar" bindchooseavatar="onChoose">
  <image src="{{avatarUrl}}" />
</button>
<input type="nickname" placeholder="昵称" bindblur="onNickname" />
```

## 5. 订阅消息权限坑

**症状**：

- 用户点了"允许"但没收到通知
- `accept` 后没立即收到
- 第二天想发，发现用户没"长期订阅"

**解法**：

- 一次性订阅只在用户点击时**当场**发一次，不能囤着
- 需要长期推送 → 申请**长期订阅**模板（审核严格）
- 用户 `ban` 后引导到设置页：`wxp.openSetting()`

## 6. 路由栈溢出

**症状**：`navigateTo:fail webview count limit exceed`。

**原因**：连续 navigateTo 超过 10 层。

**解法**：

- 中间层用 `redirectTo`（关掉当前页）
- 详情页 → 详情页用 `redirectTo`
- 用 `getCurrentPages().length` 自检

## 7. globalData vs Storage

**症状**：团队成员用 `getApp().globalData.token` 存 token，App 销毁后丢。

**解法**：

- token 走 `wx.setStorageSync`（持久）
- globalData 只用于**会话级**临时数据
- 跨页状态用 MobX store

## 8. 调试时 devtools 报错"不在以下 request 合法域名列表中"

**症状**：本地 wx.request 失败 "不在以下合法域名列表中"。

**解法**：

- 微信公众平台 → 开发管理 → 开发设置 → **服务器域名**配置 request 合法域名
- 开发期可勾选"不校验合法域名"（仅开发工具）
- **注意**：勾选"不校验"后上线审核**仍**会拒

## 9. 编译时 TS 报错但 `tsc` 单独跑没问题

**症状**：`pnpm build` 过了，微信开发者工具报"无法编译"。

**原因**：`miniprogram-ci build` 内部跑的是 `project.config.json` 配的编译钩子，不一定走 `tsc`。

**解法**：

- 在 `package.json` 加 `build: "tsc && miniprogram-ci build ..."`
- 让 `tsc` 先跑

## 10. 网络请求阻塞 UI 线程

**症状**：发请求期间页面卡住。

**解法**：

- 永远用 `wxp.request`（Promise），不要用 `wx.requestSync`
- 同步存储用 `wx.getStorageSync` 也要短（<10ms），大对象走异步

## 11. setData 传入未声明的字段

**症状**：TS 编译过，但运行时页面不刷新。

**原因**：WXML 模板只能识别 `data` 里声明过的字段。

**解法**：

- Page/Component 的 `data` 初始值要包含所有字段（即使是 `null`）
- 或在 setData 之前 `this.setData({ newField: null, ...rest })`

## 12. 微信版本兼容

**症状**：新 API 在老基础库上 `undefined`。

**解法**：

- 微信开发者工具 → 详情 → 本地设置 → 调试基础库设到目标最低版本
- 关键新 API 走 `if (wxp.someNewApi) { ... }` 兼容判断
- `manifest.json` → `mp-weixin.libVersion` 设最低基础库
