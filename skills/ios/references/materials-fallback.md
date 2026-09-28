# Materials 回退（iOS 18–25）

> 在最低部署 iOS 18、Liquid Glass 仅 iOS 26+ 可用的前提下，自定义「透明风格」统一回退到系统
> [Material](https://developer.apple.com/documentation/swiftui/material)。

## 材质阶梯

由通透 → 厚重（按场景选用，默认偏通透）：

| Material             | 典型场景               |
| -------------------- | ---------------------- |
| `.ultraThinMaterial` | 浮动胶囊按钮、轻工具条 |
| `.thinMaterial`      | 卡片浮层、次级面板     |
| `.regularMaterial`   | 默认面板               |
| `.thickMaterial`     | 需要更强分隔时         |
| `.bar`               | 接近系统栏的观感       |

## 标准回退写法

```swift
struct FallbackGlassModifier<S: Shape>: ViewModifier {
    var shape: S

    func body(content: Content) -> some View {
        content.background(.ultraThinMaterial, in: shape)
    }
}
```

与 Liquid Glass 合并封装（推荐放 `DesignSystem/Glass.swift`）：

```swift
struct AppGlassBackground<S: Shape>: ViewModifier {
    var shape: S
    var material: Material = .ultraThinMaterial

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.glassEffect(.regular, in: shape)
        } else {
            content.background(material, in: shape)
        }
    }
}
```

## 按钮回退对照

| iOS 26+                         | 回退                               |
| ------------------------------- | ---------------------------------- |
| `.buttonStyle(.glass)`          | `.buttonStyle(.bordered)`          |
| `.buttonStyle(.glassProminent)` | `.buttonStyle(.borderedProminent)` |
| `.glass(.regular.tint(c))`      | `.tint(c)` + `.bordered`           |

## Sheet / 系统控件

Sheet、Popover、Menu 在旧系统上已有系统材质，**不要**再包一层 `.background(.ultraThinMaterial)`。
自定义背景同样会破坏系统观感（与 Liquid Glass 时代同一原则）。

## Vibrancy（文字压在材质上）

优先让 Label / 系统 `Text` 使用语义色；需要时：

```swift
Text("Caption")
    .foregroundStyle(.secondary)
```

避免在材质上使用低对比的自定义灰（尤其浅色模式）。

## 禁止

```swift
// ❌ 假玻璃
.background(Color.white.opacity(0.15))
.background(
    RoundedRectangle(cornerRadius: 16)
        .fill(.white.opacity(0.2))
        .background(.blur) // 臆造 / 错误 API
)

// ❌ UIKit 模糊直接塞进 SwiftUI 当默认路径（仅互操作例外）
UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
```

UIKit `UIVisualEffectView` 仅在必须包旧控件时使用，并仍选 **system material** 样式，不要用 `.light` / `.dark` 固定样式。

## 测试

在 iOS 18 模拟器跑一遍主路径：材质是否过厚、文字是否可读、深浅色是否都成立。
不要只在 iOS 26 上看「真玻璃」就算验收通过。
