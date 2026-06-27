# 组件设计模式

> 与 [SKILL.md §5 组件设计](../SKILL.md) 配套。

## 目录结构

每个组件一个目录，**4 文件同名**：

```
components/
└── todo-item/
    ├── index.ts         # 组件逻辑
    ├── index.wxml       # 模板
    ├── index.wxss       # 样式
    └── index.json       # 组件配置
```

`components/todo-item/index.json`：
```json
{ "component": true, "usingComponents": {} }
```

主 `miniprogram/app.json`：
```json
{
  "pages": ["pages/home/index"],
  "usingComponents": {
    "todo-item": "/components/todo-item/index"
  }
}
```

## Component 完整骨架

```ts
// components/todo-item/index.ts
Component({
  options: {
    addGlobalClass: true,  // 让 wxss 继承页面全局样式
    multipleSlots: true,    // 启用多 slot
  },

  properties: {
    item: { type: Object, value: null },
    showDelete: { type: Boolean, value: false },
  },

  data: {
    expanded: false,  // 内部状态
  },

  lifetimes: {
    attached() {
      // 组件挂载
    },
    detached() {
      // 组件卸载，清理定时器/监听器
      if (this._watcher) this._watcher();
    },
  },

  observers: {
    'item.done'(done: boolean) {
      if (done) this.setData({ expanded: false });
    },
  },

  methods: {
    onToggle() {
      this.triggerEvent('toggle', { id: this.data.item.id });
    },
    onDelete() {
      this.triggerEvent('delete', { id: this.data.item.id });
    },
    onExpand() {
      this.setData({ expanded: !this.data.expanded });
    },
  },
});
```

```xml
<!-- components/todo-item/index.wxml -->
<view class="todo-item todo-item--{{item.done ? 'done' : 'pending'}}">
  <view class="todo-item__main" bindtap="onToggle">
    <text>{{item.title}}</text>
  </view>
  <view wx:if="{{showDelete}}" class="todo-item__delete" bindtap="onDelete">
    <text>×</text>
  </view>
</view>
```

```scss
/* components/todo-item/index.wxss */
.todo-item {
  display: flex;
  padding: 24rpx;
  border-bottom: 1rpx solid #eee;

  &--done .todo-item__main { text-decoration: line-through; color: #999; }
  &__main { flex: 1; }
  &__delete { width: 60rpx; text-align: center; }
}
```

## Behavior 复用

跨组件复用 mixin（类似 Vue mixin）：

```ts
// behaviors/track.ts
export const trackBehavior = Behavior({
  methods: {
    track(event: string, data?: Record<string, unknown>) {
      // 调 wx.reportEvent 或自家埋点
    },
  },
});
```

```ts
// components/foo/index.ts
import { trackBehavior } from '../../behaviors/track';

Component({
  behaviors: [trackBehavior],
  methods: {
    onTap() {
      this.track('foo_tap', { id: this.data.id });
    },
  },
});
```

## 父子通信

```ts
// 父组件
Component({
  methods: {
    onChildToggle(e: WechatMiniprogram.CustomEvent) {
      const { id } = e.detail;
      this.data.store.toggle(id);
    },
  },
});
```

```xml
<!-- 父 wxml -->
<todo-item
  item="{{item}}"
  bind:toggle="onChildToggle"
/>
```

**注意**：`bind:` 前缀是 TS 友好写法（区分原生 bindtap）。等价于 `bindtoggle`。

## 插槽（Slot）

```xml
<!-- 子组件 wxml -->
<view class="card">
  <slot name="header" />
  <slot />  <!-- 默认 slot -->
  <slot name="footer" />
</view>
```

```xml
<!-- 父 wxml -->
<card>
  <view slot="header">标题</view>
  <view>内容</view>
  <view slot="footer">
    <button bindtap="onSubmit">确定</button>
  </view>
</card>
```

## 组件库选型

| 库 | 风格 | 体积 | 适用 |
|---|---|---|---|
| Vant Weapp | 组件丰富 | 中 | 业务复杂、有现成 UI 需求 |
| TDesign Miniprogram | 腾讯系 | 中 | 与腾讯生态对齐 |
| 自研 | 按需 | 最小 | 设计统一、3 项目共享 |

3 个项目共享推荐：**自研 + 设计 token 复用**。3 项目 UI 差异大时用 Vant Weapp。
