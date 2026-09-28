# iOS 原生 App 项目标准（SwiftUI + Liquid Glass）

> 决策见 [ADR-0014](adr/0014-ios-swiftui-liquid-glass-baseline.md)。本文是「怎么用」。
>
> 适用对象：有设计感、苹果风味的原生 iOS 产品（透明 / 玻璃质感、系统控件优先）。
> 跨端方案（React Native / Flutter / KMP）不在本标准范围。

## 适用范围

- **技术栈**：Swift + SwiftUI（UIKit 仅互操作例外）。
- **设计语言**：Liquid Glass（iOS 26+）为默认；Materials 为回退。
- **最低部署**：iOS 18。
- **场景**：单人 / 小团队多产品、新建或补差。

**不适用**：跨端框架、纯 UIKit 遗留大仓、watchOS / tvOS / visionOS 专属 App（可复用设计原则，结构另议）。

## 立场摘要

| 维度         | 选型                                                    | 理由                                             |
| ------------ | ------------------------------------------------------- | ------------------------------------------------ |
| 语言         | Swift（开启严格并发检查）                               | Apple 一等公民；与 Observation / async 对齐      |
| UI           | **SwiftUI 优先**                                        | Liquid Glass API 最完整；声明式动画成本低        |
| 设计语言     | **Liquid Glass 默认** + Materials 回退                  | 产品定位「苹果风味」；跟系统材质语言             |
| 最低系统     | **iOS 18**                                              | 近两年设备覆盖；玻璃能力运行时门控               |
| 架构         | `@Observable` + 轻量 MVVM                               | 官方状态路径；避免过重状态库                     |
| 包管理       | Swift Package Manager                                   | Xcode 原生；不引入 CocoaPods 为基线              |
| 图标         | SF Symbols（优先）+ Asset Catalog                       | 系统一致性、动态着色、无障碍                     |
| 字体 / 颜色  | 系统 Dynamic Type + Semantic Color                      | 自动适配深色模式与辅助功能                       |
| 测试         | Swift Testing + XCTest                                  | 单测必选；UI 测按需                              |
| CI           | Xcode Cloud 或 GitHub Actions `macos-*`                 | 至少 `build` + `test`                            |
| **提交规范** | conventional commits + commitlint（有 Node 侧时）/ 等价 | 与 [ci-minimum-gate.md](ci-minimum-gate.md) 对齐 |

**与基线冲突时**：以 [ADR-0014](adr/0014-ios-swiftui-liquid-glass-baseline.md) 为准。

## 设计语言（苹果透明风格）

### 分层原则

```text
┌─────────────────────────────────────┐
│  Navigation / Controls              │  ← Liquid Glass / Materials（功能层）
├─────────────────────────────────────┤
│  Content（不透明、高对比）            │  ← 禁止整页假玻璃
└─────────────────────────────────────┘
```

1. **系统组件优先**：`NavigationStack`、`TabView`、`.toolbar`、`Sheet`、`Button` 等用标准 API，
   在最新 SDK 下自动获得 Liquid Glass；**禁止**给这些组件加自定义不透明背景遮挡系统效果。
2. **玻璃克制**：自定义 `.glassEffect` 只用于关键功能控件（浮动工具条、主操作簇），
   不要给列表卡片、正文背景、整页容器铺玻璃。
3. **禁止假玻璃**：不得用 `Color.white.opacity(0.x)` / 静态模糊图冒充材质。
4. **回退必写**：自定义玻璃必须 `#available(iOS 26, *)`，否则走 `.ultraThinMaterial` 等 Materials。

### API 速查（决策层）

| 场景              | iOS 26+                                    | iOS 18–25 回退                                   |
| ----------------- | ------------------------------------------ | ------------------------------------------------ |
| 标准按钮          | `.buttonStyle(.glass)` / `.glassProminent` | `.bordered` / `.borderedProminent`               |
| 自定义形状玻璃    | `.glassEffect(.regular, in: .capsule)`     | `.background(.ultraThinMaterial, in: Capsule())` |
| 多玻璃协同 / 变形 | `GlassEffectContainer` + `glassEffectID`   | 各自 Materials，无 morph                         |
| 导航栏 / Tab      | 系统默认（去掉自定义 background）          | 同上                                             |

详细代码模式 → [skills/ios/](../skills/ios/SKILL.md)。

### 必须遵守的 HIG 要点

- 触控目标 ≥ **44×44 pt**
- 支持 **Dynamic Type**（避免写死字号压制系统字号）
- 测试 **Reduce Transparency**、**Reduce Motion**、**Increase Contrast**
- 深色 / 浅色模式均用 Semantic Color（`.primary` / `.secondary` / Asset Catalog 变体）
- 图标提供 accessibility label（VoiceOver / Voice Control）

权威文档：

- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)
- [Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- [Adopting Liquid Glass](https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass)
- [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)

## 项目结构

```text
<AppName>/
├── AppName.xcodeproj/            # 或 .xcworkspace（仅 SPM 依赖时优先单工程）
├── AppName/
│   ├── App/
│   │   ├── AppNameApp.swift      # @main
│   │   └── AppEnvironment.swift  # 依赖注入入口（可选）
│   ├── Features/                 # 按功能域垂直切片
│   │   └── <Feature>/
│   │       ├── Views/
│   │       ├── ViewModels/       # @Observable
│   │       └── Models/
│   ├── DesignSystem/             # 颜色、间距、玻璃包装、按钮样式
│   │   ├── Tokens.swift
│   │   └── Glass.swift           # iOS 26 门控 + Materials 回退
│   ├── Services/                 # 网络、Keychain、推送等
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   └── Localizable.xcstrings
│   └── Info.plist                # 仅放无法用 Build Settings 表达的项
├── AppNameTests/
├── AppNameUITests/               # 可选
├── Packages/                     # 本地 SPM（可选）
├── .github/workflows/            # 若用 GH Actions
├── CLAUDE.md                     # Bundle ID、最低系统、证书策略、负责人
├── AGENTS.md                     # 跨 Agent 短约定（可 @ 本标准）
└── README.md
```

**关键约定**：

- Feature 垂直切片；**禁止**按「全部 View / 全部 Model」横切堆目录。
- 玻璃与材质封装集中在 `DesignSystem/Glass.swift`，业务 View 不散落 `#available`。
- 密钥、证书、`.p8` / provisioning profile **不入库**；走 Keychain + CI Secrets。

## 代码风格

- **命名**：类型 PascalCase；属性 / 方法 camelCase；文件与主类型同名。
- **View**：一个文件一个主 `View`；复杂子视图可拆 `private struct`。
- **状态**：UI 状态用 `@State` / `@Binding`；跨屏业务状态用 `@Observable` ViewModel，
  经 `.environment` 或初始化注入；**禁止**在 View 里直接发网络请求堆业务逻辑。
- **并发**：`async/await`；`@MainActor` 标注 UI 边界；避免无隔离的共享可变状态。
- **不引入**：Force unwrap 作为常态（启动期已知常量除外）；`AnyView` 滥用；
  无障碍标签缺失的纯图标按钮。

## 网络与安全

- ATS 默认开启；例外域名必须在项目 `CLAUDE.md` 登记理由。
- Token / 刷新令牌进 **Keychain**，不进 `UserDefaults` / 文件明文。
- API 错误体尽量对齐 [api-error-codes.md](api-error-codes.md)（若后端同源）；
  客户端统一在 `Services/HTTPClient` 解码与映射。
- 日志脱敏：不打印 Authorization、手机号、精确定位。

## CI 最低门槛（iOS 专属）

在 [ci-minimum-gate.md](ci-minimum-gate.md) 通用项之外：

| 项       | 要求                                                  |
| -------- | ----------------------------------------------------- |
| Build    | Debug 配置 `xcodebuild … build` 成功                  |
| Test     | 至少单元测试 target 可跑（可无 UI 测）                |
| 密钥扫描 | 证书 / `.p12` / `.p8` / 私钥不进库（gitleaks 或等价） |
| 版本     | Marketing Version + Build Number 策略写进 `CLAUDE.md` |

真机 / 截图 / TestFlight 上传不强制进「最低门槛」；发布流程项目自定并文档化。

## 分环境

| 环境       | Bundle ID 建议                    | 配置                 | 分发                 |
| ---------- | --------------------------------- | -------------------- | -------------------- |
| Debug      | `…app.dev` 或同一 ID + Debug flag | `.xcconfig` / scheme | 模拟器 / 开发设备    |
| TestFlight | 生产 Bundle ID                    | Release              | TestFlight 内部/外部 |
| App Store  | 生产 Bundle ID                    | Release              | 人工提交审核         |

API Base URL 用 Build Configuration / `.xcconfig` 注入，**禁止**在源码硬编码生产地址且无法切换。

## 缺口 / 已知偏差

| 缺口                             | 缓解 / 计划                       | 链到          |
| -------------------------------- | --------------------------------- | ------------- |
| 尚无 `templates/ios/` 脚手架     | 从首个合规产品复制工程骨架        | ADR-0014 缺口 |
| Liquid Glass API 可能随 SDK 微调 | Skill references 跟进 WWDC / 文档 | skills/ios    |
| 多产品共享 DesignSystem 包       | 出现第 2 个 App 时抽本地 SPM      | 待 Phase 2    |

## 跑起来检查清单

新项目 / 补差时，按 [skills/dev-bootstrap](../skills/dev-bootstrap/SKILL.md) 走。**额外检查项**：

- [ ] 最低部署 iOS 18（或项目 CLAUDE.md 登记 ADR 例外）
- [ ] 导航 / Tab / Toolbar **无**自定义不透明背景遮挡系统材质
- [ ] 自定义玻璃走 `DesignSystem/Glass.swift`，含 iOS 26 门控 + Materials 回退
- [ ] 无 `Color.*.opacity` 假玻璃
- [ ] 触控目标 ≥ 44pt；图标按钮有 accessibility label
- [ ] 已测 Reduce Transparency / Reduce Motion / 深浅色
- [ ] 密钥与证书不在仓库；CI 能 `build` + `test`
- [ ] 已部署 [ios domain skill](../skills/ios/SKILL.md)（`sync.sh skills`）

## 参考

- [ADR-0014](adr/0014-ios-swiftui-liquid-glass-baseline.md) — 本标准决策依据
- [principles.md](principles.md) — 通用原则
- [ci-minimum-gate.md](ci-minimum-gate.md) — CI 必选项
- [skills/ios/](../skills/ios/SKILL.md) — 模式、API、坑点（Agent 工具书）
- [Apple HIG](https://developer.apple.com/design/human-interface-guidelines)
- [Adopting Liquid Glass](https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass)
