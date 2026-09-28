---
name: ios
description: >-
  Native iOS app development with SwiftUI and Apple Liquid Glass design language.
  Use when building SwiftUI iOS apps with translucent/glass aesthetics, adopting
  .glassEffect / GlassEffectContainer / glass button styles, falling back to
  Materials on older iOS, aligning with Apple HIG, SF Symbols, Dynamic Type,
  Reduce Transparency, or structuring Features/ + DesignSystem/ projects.
---

# iOS Native Skill（SwiftUI + Liquid Glass）

技术栈 domain 知识。**业务 domain**（具体产品逻辑）不进本 Skill。

## 何时用

- 写 SwiftUI 原生 iOS App（尤其强调苹果风味 / 透明玻璃质感）
- 接入 Liquid Glass（`.glassEffect`、`GlassEffectContainer`、`.buttonStyle(.glass)`）
- 为 iOS 18–25 写 Materials 回退
- 对齐 Apple HIG（触控、Dynamic Type、辅助功能）
- 搭 Features 垂直切片 + DesignSystem 封装

**不适用**：React Native / Flutter / KMP、纯 UIKit 大仓重构、watchOS/tvOS 专属细节。

## 标准库对齐

本 Skill 是 [playbook/ios.md](../../playbook/ios.md) 的「工具书」。
**决策与基线以 playbook 为准**，本文给具体模式与坑点。

## 核心约定（必读）

### 1. 系统组件优先，让玻璃「免费」出现

用最新 Xcode SDK 构建时，标准导航与控件在 iOS 26+ **自动**采纳 Liquid Glass。
**先删自定义背景**，再谈自定义玻璃：

```swift
// ✅ 让系统决定导航栏材质
NavigationStack {
    ContentView()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done", action: dismiss)
            }
        }
}

// ❌ 遮挡系统 Liquid Glass / scroll edge effect
.toolbarBackground(.visible, for: .navigationBar)
.toolbarBackground(Color.black.opacity(0.8), for: .navigationBar)
```

Tab 同理：优先 `TabView` + 系统样式；需要时用 `.tabBarMinimizeBehavior(.onScrollDown)`
（iOS 26+）让内容层更突出。

### 2. 自定义玻璃：统一走 DesignSystem 封装

业务 View **禁止**散落裸调 `.glassEffect`。集中封装并门控：

```swift
// DesignSystem/Glass.swift
import SwiftUI

struct AppGlassBackground<S: Shape>: ViewModifier {
    var shape: S

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.glassEffect(.regular, in: shape)
        } else {
            content.background(.ultraThinMaterial, in: shape)
        }
    }
}

extension View {
    func appGlass<S: Shape>(in shape: S = .capsule) -> some View {
        modifier(AppGlassBackground(shape: shape))
    }
}
```

```swift
// 使用
Label("Edit", systemImage: "pencil")
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .appGlass(in: .capsule)
```

详细变体、Container、morph → [references/liquid-glass.md](references/liquid-glass.md)

### 3. 按钮：优先系统 glass style，不要手搓

```swift
if #available(iOS 26, *) {
    Button("Continue", action: onContinue)
        .buttonStyle(.glassProminent)   // 主操作
    Button("Cancel", action: onCancel)
        .buttonStyle(.glass)            // 次要
} else {
    Button("Continue", action: onContinue)
        .buttonStyle(.borderedProminent)
    Button("Cancel", action: onCancel)
        .buttonStyle(.bordered)
}
```

**禁止**对 `Button` 再包一层 `.glassEffect(.regular.interactive())` 除非是非 Button 的自定义可点击控件。

### 4. 多玻璃必须进 `GlassEffectContainer`

邻近多个玻璃元素各自采样会「采到彼此」，视觉发脏且费性能。iOS 26+：

```swift
if #available(iOS 26, *) {
    GlassEffectContainer(spacing: 20) {
        HStack(spacing: 20) {
            Image(systemName: "backward.fill").glassEffect()
            Image(systemName: "play.fill").glassEffect()
            Image(systemName: "forward.fill").glassEffect()
        }
    }
}
```

### 5. 分层：玻璃在上，内容在下

| 层                     | 该用什么                      | 不该用什么          |
| ---------------------- | ----------------------------- | ------------------- |
| 导航 / 工具条 / 主操作 | Liquid Glass / Materials      | 整页半透明遮罩      |
| 列表、卡片、正文       | 不透明 / 系统 List / 分组背景 | `.glassEffect` 铺满 |
| 玻璃上的文字 / 图标    | 系统前景色 + Vibrancy 语义    | 再叠一层玻璃        |

**禁止假玻璃**：

```swift
// ❌
.background(Color.white.opacity(0.2))
.background(.blur) // 非系统材质 API 的臆造写法

// ✅
.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
// 或 iOS 26+ .glassEffect
```

### 6. 架构：Feature 切片 + `@Observable` ViewModel

```swift
@Observable
@MainActor
final class HomeViewModel {
    private(set) var items: [Item] = []
    var isLoading = false

    private let client: HTTPClient

    init(client: HTTPClient) { self.client = client }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        items = try await client.fetchItems()
    }
}
```

```swift
struct HomeView: View {
    @State private var model: HomeViewModel

    var body: some View {
        List(model.items) { item in
            Text(item.title)
        }
        .task { await model.load() }
    }
}
```

- View **不**直接 `URLSession`；统一 `Services/`
- 跨 Feature 共享只放真正共享的 DesignSystem / Services
- 目录约定见 playbook；细节 → [references/architecture.md](references/architecture.md)

### 7. SF Symbols + 无障碍

```swift
Button {
    share()
} label: {
    Image(systemName: "square.and.arrow.up")
}
.accessibilityLabel("分享")
```

- 优先 SF Symbols，少用位图图标
- 纯图标控件 **必须** `accessibilityLabel`
- 字号跟 Dynamic Type：`Font` 用语义样式（`.body` / `.headline`），避免固定 `Font.system(size: 12)` 压制系统

### 8. 辅助功能必测（玻璃类 App 不测=不合格）

开发中切换以下设置，界面仍须可读、可点：

1. **Settings → Accessibility → Display & Text Size → Reduce Transparency**
2. **Reduce Motion**
3. **Increase Contrast**
4. 深色 / 浅色模式来回切
5. 最大 Dynamic Type 字号扫一眼主流程

系统组件大多自动适配；自定义 `appGlass` 在 Reduce Transparency 下应仍保持对比度
（Materials / Glass 系统实现会降级，假玻璃不会）。

## 关键限制（3 个最容易踩）

### 玻璃叠玻璃

玻璃上再铺玻璃 → 发雾、发灰、性能差。
玻璃层上的控件用普通填充 / 系统 label 色，不要套第二层 `.glassEffect`。

### 给系统栏加「品牌底色」

品牌色应落在内容强调（tint、prominent 按钮），不是涂满 NavigationBar/TabBar。
涂满会毁掉 Liquid Glass 与 scroll edge effect。

### 只在最新 iPhone 上看一眼

半透明在浅色壁纸 / 高饱和内容上对比度崩。必须测浅色模式 + Reduce Transparency。

## 跑起来检查

新页面 / 新组件前先扫：

- [ ] 未给 `NavigationStack` / `TabView` / `.toolbar` 加不透明自定义背景
- [ ] 自定义玻璃走 `appGlass`（或等价 DesignSystem API），含 `#available(iOS 26, *)`
- [ ] 多玻璃在 `GlassEffectContainer` 内
- [ ] 按钮优先 `.glass` / `.glassProminent`（有可用性门控）
- [ ] 无 `Color.*.opacity` 假玻璃
- [ ] 触控 ≥ 44pt；图标有 accessibility label
- [ ] Reduce Transparency / Reduce Motion / 深浅色已过目

## 参考（按需查）

- [references/liquid-glass.md](references/liquid-glass.md) — Liquid Glass API 与形态变形
- [references/materials-fallback.md](references/materials-fallback.md) — iOS 18–25 Materials 回退
- [references/hig-and-accessibility.md](references/hig-and-accessibility.md) — HIG 与辅助功能清单
- [references/architecture.md](references/architecture.md) — 目录、状态、网络骨架
- [references/pitfalls.md](references/pitfalls.md) — 常见坑

## 外部权威

- [Adopting Liquid Glass](https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass)
- [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)
- [HIG — Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)
- [WWDC25 — Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/)
- [WWDC25 — Build a SwiftUI app with the new design](https://developer.apple.com/videos/play/wwdc2025/323/)
