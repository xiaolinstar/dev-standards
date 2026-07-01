# 微信 JS-SDK 分享与授权参考

> 对应 Skill 核心约定 §10「微信 JS-SDK」。

## wx.config 签名配置

微信 JS-SDK 需要后端生成签名，前端用签名初始化 `wx.config`：

```ts
// src/utils/wechat.ts
import wx from 'weixin-js-sdk';
import http from '@/services/http';

interface WxConfigParams {
  appId: string;
  timestamp: number;
  nonceStr: string;
  signature: string;
}

/**
 * 初始化微信 JS-SDK
 * 必须在页面加载时调用，且 URL 必须是当前页面完整 URL（不含 hash）
 */
export async function initWxConfig() {
  // 当前页面 URL（去掉 hash 部分，微信签名只认 path + query）
  const url = window.location.href.split('#')[0];

  // 后端接口：用 URL 生成签名
  const config = await http.get<WxConfigParams>('/api/wechat/jssdk-config', {
    params: { url },
  });

  wx.config({
    debug: import.meta.env.DEV, // 开发环境开启调试
    appId: config.appId,
    timestamp: config.timestamp,
    nonceStr: config.nonceStr,
    signature: config.signature,
    jsApiList: [
      'updateAppMessageShareData',  // 分享给朋友
      'updateTimelineShareData',    // 分享到朋友圈
      'chooseImage',                // 选择图片
      'previewImage',               // 预览图片
    ],
  });

  // 错误回调
  wx.error((res: any) => {
    console.error('[WX SDK] config error:', res);
  });
}
```

## 分享卡片配置

在 `wx.ready` 回调中配置分享内容。**必须在 wx.config 之后调用**：

```ts
// src/utils/wechat.ts（续）

interface ShareOptions {
  title: string;
  desc: string;
  link?: string;
  imgUrl: string;
}

/**
 * 配置微信分享卡片
 * 在 wx.ready 回调中设置，确保 SDK 初始化完成
 */
export function setupShare(options: ShareOptions) {
  const shareData = {
    title: options.title,
    desc: options.desc,
    // 分享链接必须去掉 hash，且域名需在公众号后台配置
    link: options.link || window.location.href.split('#')[0],
    imgUrl: options.imgUrl,
  };

  wx.ready(() => {
    // 分享给朋友
    wx.updateAppMessageShareData({
      ...shareData,
      success: () => {
        console.log('[WX SDK] share config success');
      },
    });

    // 分享到朋友圈
    wx.updateTimelineShareData({
      title: shareData.title,
      link: shareData.link,
      imgUrl: shareData.imgUrl,
      success: () => {
        console.log('[WX SDK] timeline share config success');
      },
    });
  });
}
```

## 页面中使用

```ts
// src/views/home/index.vue
import { onMounted } from 'vue';
import { initWxConfig, setupShare } from '@/utils/wechat';

onMounted(async () => {
  await initWxConfig();
  setupShare({
    title: '查看最新运营数据',
    desc: '赶快来查看最新的打卡运营数据吧！',
    imgUrl: 'https://yourdomain.com/share-thumb.png',
  });
});
```

---

## OAuth 2.0 授权 code 清洗

### 问题

微信网页授权流程：

1. 用户点击链接 → 跳转微信授权页
2. 用户同意 → 重定向回 `redirect_uri?code=xxx&state=yyy`
3. 前端拿 `code` 调后端换 token

**`code` 是一次性的**（5 分钟有效，且只能用一次）。如果不从 URL 清洗：

- 用户刷新页面 → 重复使用 code → 后端报 500
- 用户分享带 code 的链接 → 他人打开 → 500

### 解决方案

```ts
// src/utils/auth.ts
import { useUserStore } from '@/stores/user';
import http from '@/services/http';

/**
 * 处理微信 OAuth 回调
 * 必须在路由 beforeEach 或 App.vue onMounted 中最先调用
 */
export async function handleWeChatOAuth() {
  const url = new URL(window.location.href);
  const code = url.searchParams.get('code');

  if (!code) return; // 没有 code 参数，跳过

  try {
    // 用 code 换取 token
    const { token } = await http.post<{ token: string }>('/api/auth/wechat', {
      code,
    });

    // 保存 token
    const userStore = useUserStore();
    userStore.setToken(token);
  } catch (error) {
    console.error('[OAuth] code exchange failed:', error);
  } finally {
    // ========== 关键：清洗 URL 中的 code 和 state ==========
    // 无论成功失败都要清洗，防止 code 复用
    url.searchParams.delete('code');
    url.searchParams.delete('state');
    window.history.replaceState({}, '', url.toString());
  }
}
```

### 在路由守卫中调用

```ts
// src/router/index.ts
import { handleWeChatOAuth } from '@/utils/auth';

let oauthHandled = false;

router.beforeEach(async (to) => {
  // OAuth code 清洗只需执行一次
  if (!oauthHandled) {
    await handleWeChatOAuth();
    oauthHandled = true;
  }

  // ... 其他守卫逻辑（登录态检查等）
});
```

---

## 常见坑

### 1. code 复用导致 500

**症状**：用户刷新页面后接口报 500。
**原因**：URL 中的 code 被再次提交到后端，微信返回"code 已使用"。
**修复**：确保 `handleWeChatOAuth` 在 `finally` 块中清洗 URL。

### 2. 签名失败（invalid signature）

**症状**：`wx.config` 报 `invalid signature`。
**原因**：签名时使用的 URL 与当前页面 URL 不一致。
**修复**：

- 签名 URL 必须是 `window.location.href.split('#')[0]`（去掉 hash）
- SPA 应用中，iOS 始终以**首次进入页面**的 URL 计算签名（Android 用当前 URL）
- iOS 兼容方案：每次路由切换后重新调 `initWxConfig()`

### 3. 分享链接域名不匹配

**症状**：分享出去的卡片点开是空白或提示"非微信官方网页"。
**原因**：`link` 参数的域名未在公众号后台「JS 接口安全域名」中配置。
**修复**：在公众号后台 → 公众号设置 → 功能设置 → JS 接口安全域名中添加。

## 依赖安装

```bash
npm install weixin-js-sdk
npm install -D @types/weixin-js-sdk
```
