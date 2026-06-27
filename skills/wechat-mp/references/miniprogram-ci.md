# miniprogram-ci：CI 上传与发布

> 微信官方 CLI 工具，免本地微信开发者工具。
> 文档：https://developers.weixin.qq.com/miniprogram/dev/devtools/ci.html

## 前置

1. 微信公众平台 → 开发管理 → 开发设置 → 拿到 **AppID** 和 **AppSecret**
2. 同一页面下载 **小程序代码上传密钥**（`private.<APPID>.key`），妥善保存
3. 配置 IP 白名单（CI 机器出口 IP）

## 本地试用

```bash
npm i -g miniprogram-ci

# 项目根准备 miniprogram/ 编译产物
miniprogram-ci build \
  --pp ./miniprogram \
  --uv 1.0.0 \
  --appid wx1234567890abcdef \
  --pkp ./private.wx1234567890abcdef.key \
  --output dist

# 预览（生成体验码）
miniprogram-ci preview \
  --pp ./miniprogram \
  --uv 1.0.0 \
  --appid wx1234567890abcdef \
  --pkp ./private.wx1234567890abcdef.key

# 上传（开发版 / 体验版素材）
miniprogram-ci upload \
  --pp ./miniprogram \
  --uv 1.0.0 \
  --appid wx1234567890abcdef \
  --pkp ./private.wx1234567890abcdef.key \
  --ud 1.0.0               # upload description（体验版描述）
  --auto 1                  # 1 = 体验版，0 = 开发版（默认）
```

## CI 集成（GitHub Actions）

密钥通过 Secrets 注入。**不要**把 `.key` 文件入库。

```bash
# 在 CI 里临时恢复 key
echo "${{ secrets.WECHAT_KEY_BASE64 }}" | base64 -d > /tmp/private.key
```

完整 workflow 见 [playbook/wechat-mp.md §CI/CD](../../../playbook/wechat-mp.md#cicdgithub-actions-模板)。

## 参数速查

| 参数 | 含义 | 必填 |
|---|---|---|
| `--pp` | 编译产物路径（miniprogram/） | ✓ |
| `--uv` | 上传号（version） | ✓ |
| `--pkp` | 私钥文件路径 | ✓ |
| `--appid` | 小程序 AppID | ✓ |
| `--ud` | 体验版描述 | 体验版时必填 |
| `--auto` | 1=体验版 / 0=开发版 |  |
| `--qr` | 输出二维码到 stdout | preview 时 |
| `--proxy` | 代理 |  |

## 错误排查

| 错误 | 原因 | 解法 |
|---|---|---|
| `Error: getaddrinfo ENOTFOUND` | 网络不通 | 检查代理 / IP 白名单 |
| `Error: invalid key` | 私钥和 appid 不匹配 | 重新下载 key |
| `Error: 45009` | 调用频率超限 | 间隔 60s 重试 |
| `Error: 40013` | appid 错误 | 检查 `--appid` |
| `Error: invalid version` | versionName 非法 | 限制为 `x.y.z` 格式 |
| `Error: 包大小超过限制` | 编译产物 > 2M | 看 pitfalls.md |
| `Error: miniprogramRoot` | 路径找不到 | 检查 `--pp` |

## 多环境 appid

dev / trial / release 可用不同 appid（用同一个也行）：

- **同一 appid**：开发版/体验版/正式版都通过 CI 上传，正式版靠"提交审核"区分
- **不同 appid**：每个环境一个 appid（适合 dev/trial/prod 业务隔离）

**项目级 CLAUDE.md 写明**用了哪种。

## 不做的事

- 不在 CI 里自动提交正式版审核（涉及类目、隐私、内容合规，必须人工）
- 不在 CI 里自动调用"发布"接口（只有上传 + 等待审核）
- 不把 `private.*.key` 入库（gitleaks 会拦）

## 备选：使用 `@wechat-miniprogram/cli`

社区封装版，命令更友好（如 `wxmp upload`），但底层仍是 `miniprogram-ci`。新项目**推荐直接用官方 `miniprogram-ci`**，少一层依赖。
