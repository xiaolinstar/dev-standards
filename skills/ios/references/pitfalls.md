# iOS / Liquid Glass 常见坑

## 设计与材质

### 1. 整页假玻璃

**症状**：全屏「宇宙模糊」/ 半透明白，发脏、费电、不像 iOS。
**修法**：内容层不透明；只在导航 / 浮动控件用 Glass 或 Material。

### 2. 导航栏涂品牌色

**症状**：升级到 iOS 26 SDK 后系统 Liquid Glass / scroll edge 消失。
**修法**：去掉 `.toolbarBackground(Color…)`；品牌色用 `.tint` 与 prominent 按钮。

### 3. 玻璃叠玻璃

**症状**：双重模糊、文字发灰。
**修法**：一层玻璃；其上用普通控件与语义前景色。

### 4. 多玻璃不进 Container

**症状**：交界闪烁、互相采样、掉帧。
**修法**：iOS 26+ 用 `GlassEffectContainer`；旧系统各自 Material 且避免重叠。

### 5. 只测深色模式

**症状**：浅色壁纸上按钮「消失」。
**修法**：浅色 + Reduce Transparency 必测。

## SwiftUI 工程

### 6. View 里直接打网

**症状**：无法单测、生命周期重复请求。
**修法**：`@Observable` ViewModel + `Services/HTTPClient`。

### 7. 滥用 `AnyView` / 类型擦除

**症状**：性能差、动画怪。
**修法**：`@ViewBuilder`、泛型、拆小 View。

### 8. Force unwrap 网络 JSON

**症状**：字段缺失直接崩。
**修法**：`Decodable` + 明确错误；UI 展示可恢复状态。

### 9. Token 进 UserDefaults

**症状**：备份 / 越狱场景泄露。
**修法**：Keychain；登出删除。

### 10. 硬编码生产 API

**症状**：无法切环境、误打生产。
**修法**：`.xcconfig` / scheme；Debug 用 `.localhost` 或 staging。

## 系统与发布

### 11. 最低版本写成 iOS 26

**症状**：大量设备无法安装。
**修法**：部署 iOS 18；玻璃 API 运行时门控（本标准默认）。

### 12. 忽略 `UIDesignRequiresCompatibility`

**症状**：团队以为「关了玻璃」却只在部分机器生效，表现不一致。
**修法**：本标准默认不设该键；若项目例外，写进 `CLAUDE.md` 并全员用同一 SDK 验证。

### 13. 证书与 `.p8` 入库

**症状**：密钥泄漏、Apple 账号风险。
**修法**：gitignore + CI Secrets；pre-commit 密钥扫描。

### 14. 模拟器 only

**症状**：材质、安全区、性能与真机不符。
**修法**：发 TestFlight 前至少一款真机过主路径。

## 与 H5 / 小程序边界

| 场景                  | 用哪套标准                            |
| --------------------- | ------------------------------------- |
| WKWebView 内嵌 H5     | 壳用本 ios 标准；H5 内容用 `h5` Skill |
| 微信小程序            | `wechat-mp`，不是本 Skill             |
| App 内 SwiftUI 原生页 | 本 Skill                              |

不要把 H5 的 `backdrop-filter` 习惯直接搬进 SwiftUI；用系统 Material / Glass。
