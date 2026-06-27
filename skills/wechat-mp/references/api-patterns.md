# 常用 wx.* API 的 TS 模式

> 与 [SKILL.md §1 异步 API Promise 化](../SKILL.md) 配套使用。
> 所有示例假设已装 `miniprogram-api-promise` 并在 `app.ts` 打过补丁，使用 `wxp.*`。

## 网络请求

```ts
// 基础 GET
const res = await wxp.request({
  url: '/api/todos',
  method: 'GET',
  data: { page: 1, pageSize: 20 },
});
// res.statusCode / res.data / res.header

// 上传文件
const upload = await wxp.uploadFile({
  url: '/api/upload',
  filePath: tempFilePath,  // wx.chooseImage 返回的临时路径
  name: 'file',
  formData: { kind: 'avatar' },
});

// 下载
const download = await wxp.downloadFile({ url });
// download.tempFilePath
```

注意：`uploadFile` 和 `downloadFile` **不**会被 `miniprogram-api-promise` patch，**不**返回 `request` 风格的 `statusCode/data` 字段。

## 登录 / 用户信息

```ts
// 登录拿 code（不能拿用户信息了，2022 后）
const { code } = await wxp.login();
// → 发到后端 /api/login 换 token

// 头像（用 chooseAvatar 组件，不能调 API）
// wxml: <button open-type="chooseAvatar" bindchooseavatar="onChooseAvatar">
onChooseAvatar(e: WechatMiniprogram.CustomEvent) {
  const { avatarUrl } = e.detail;
  // 上传 avatarUrl 到自家 OSS
}

// 昵称（用 type="nickname" 的 input 组件）
// wxml: <input type="nickname" bindblur="onNicknameBlur">
onNicknameBlur(e: WechatMiniprogram.CustomEvent) {
  const nickname = e.detail.value;
}
```

**注意**：
- `wx.getUserProfile` 已废弃，不要用
- `wx.checkSession` 只校验 `session_key`，**不**等同"用户已登录"——用后端 token 校验

## 存储

```ts
// 同步（小数据，< 1MB / key）
wx.setStorageSync('token', token);
const token = wx.getStorageSync('token') || '';
wx.removeStorageSync('token');

// 异步（大数据）
const { data } = await wxp.getStorage({ key: 'big-blob' });

// 缓存 with TTL（手写）
interface Cached<T> { value: T; expiresAt: number }
async function getCached<T>(key: string, loader: () => Promise<T>, ttlMs: number): Promise<T> {
  const raw = wx.getStorageSync(`cache:${key}`);
  if (raw && raw.expiresAt > Date.now()) return raw.value;
  const value = await loader();
  wx.setStorageSync(`cache:${key}`, { value, expiresAt: Date.now() + ttlMs } as Cached<T>);
  return value;
}
```

**限制**：
- 单个 key 1MB；总容量 10MB（前端可申请扩到更多，但慢）
- 同步 API 阻塞 UI 线程，**禁止**在 `onLoad` 里大量调用

## 路由

```ts
// 保留当前页面（返回可回退）
wxp.navigateTo({ url: '/pages/detail/index?id=1' });

// 关闭当前页（无返回）
wxp.redirectTo({ url: '/pages/login/index' });

// Tab 切换（必须用 switchTab）
wxp.switchTab({ url: '/pages/home/index' });

// 重新启动
wxp.reLaunch({ url: '/pages/home/index' });

// 返回
wxp.navigateBack({ delta: 1 });
```

**坑**：
- 页面栈最多 **10 层**（2024 调整后），超出需 `redirectTo`
- Tab 页只能用 `switchTab`
- 路由参数走 query string，**不**支持复杂对象（要传就用 JSON 字符串再 parse）

## 系统信息

```ts
// 推荐用新 API（替代 getSystemInfoSync）
const device = await wxp.getDeviceInfo();
const window = await wxp.getWindowInfo();
const appBase = await wxp.getAppBaseInfo();

// 平台
const { system, platform } = device;  // 'ios' / 'android' / 'devtools' / 'mac' ...
// 判断是否开发者工具
const isDevtools = platform === 'devtools';
```

## 位置

```ts
// 一次性定位
const { latitude, longitude } = await wxp.getLocation({ type: 'gcj02' });

// 持续定位（页面 onUnload 必 stop）
const watcher = await wxp.startLocationUpdate({});
wxp.onLocationChange(loc => console.log(loc.latitude, loc.longitude));
// 清理
wxp.stopLocationUpdate({});
wxp.offLocationChange();
```

**审核注意**：位置类用途必须在小程序后台配置"用户隐私协议"中声明 `location` 字段，否则审核拒绝。

## 扫码

```ts
// 仅相机扫码
const { result } = await wxp.scanCode({ scanType: ['qrCode'] });
```

## 订阅消息

```ts
// 必须用户点击 <button open-type="subscribe"> 后调用
wxp.requestSubscribeMessage({
  tmplIds: ['TEMPLATE_ID_1', 'TEMPLATE_ID_2'],
});
// 返回 { 'TEMPLATE_ID_1': 'accept' | 'reject' | 'ban' }
```

**坑**：
- `accept` 表示用户同意；`reject` 一次性，**不持久**；`ban` 是永久拒绝（需引导到设置）
- 一个模板 ID 用户每天最多接收 **N 条**（具体看模板设置）

## 支付

```ts
// 调 wxpay 前必须先从后端拿 prepay 参数
const prepay = await http<{ ... }>({ url: '/api/order/prepay', method: 'POST', data: orderId });
await wxp.requestPayment({
  timeStamp: prepay.timeStamp,
  nonceStr: prepay.nonceStr,
  package: prepay.package,
  signType: 'MD5',
  paySign: prepay.paySign,
});
```

**禁止**前端生成 `sign` —— 永远后端签名后下发。

## 转发

```ts
// wxml: <button open-type="share">
onShareAppMessage() {
  return {
    title: '分享标题',
    path: '/pages/detail/index?id=1',
    imageUrl: 'https://...',  // 自定义缩略图
  };
}

// 分享到朋友圈（基础库 2.11.3+）
onShareTimeline() {
  return { title: '...' };
}
```
