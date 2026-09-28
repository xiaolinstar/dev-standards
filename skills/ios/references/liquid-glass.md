# Liquid Glass API 参考（iOS 26+）

> 权威：[Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)
> [Adopting Liquid Glass](https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass)

所有示例默认包在 `if #available(iOS 26, *) { … }` 中；回退见
[materials-fallback.md](materials-fallback.md)。

## 核心理念

Liquid Glass 是 **导航与控件功能层** 的动态材质：折射、反射、随内容与交互自适应。
它不是「把所有东西做成毛玻璃」——内容层应保持清晰可读。

## `.glassEffect(_:in:)`

```swift
Text("Hello")
    .padding()
    .glassEffect()                    // 默认 .regular + Capsule
    .glassEffect(.regular, in: .rect(cornerRadius: 20))
    .glassEffect(.clear, in: .circle)
```

常用变体（以 SDK 文档为准）：

| 变体                     | 用途                       |
| ------------------------ | -------------------------- |
| `.regular`               | 默认控件玻璃               |
| `.clear`                 | 更通透；注意对比度         |
| `.regular.tint(color)`   | 着色工具控件               |
| `.regular.interactive()` | 自定义可点击视图的触感反馈 |

规则：

1. `.glassEffect` 放在布局 / padding **之后**
2. `.interactive()` 只用于真正可点的自定义视图；`Button` 请用 buttonStyle
3. 玻璃上的标签用系统前景，不要再叠一层玻璃

## 按钮样式（首选）

```swift
Button("Standard") { }
    .buttonStyle(.glass)

Button("Primary") { }
    .buttonStyle(.glassProminent)

Button("Tinted") { }
    .buttonStyle(.glass(.regular.tint(.orange)))
```

| Style             | 场景                       |
| ----------------- | -------------------------- |
| `.glass`          | 工具条、次要操作           |
| `.glassProminent` | 高强调主操作（少用）       |
| `.glass(_:)`      | 需要 clear / tint 等变体时 |

## `GlassEffectContainer`

多个邻近玻璃必须进容器，统一采样区并允许形状融合：

```swift
GlassEffectContainer(spacing: 24) {
    HStack(spacing: 24) {
        actionGlyph("scissors")
        actionGlyph("doc.on.doc")
        actionGlyph("trash")
    }
}

func actionGlyph(_ name: String) -> some View {
    Image(systemName: name)
        .frame(width: 44, height: 44)
        .glassEffect()
}
```

`spacing` 与内部 `HStack` spacing 对齐；小于阈值的元素会视觉融合。

## 形态变形（morph）

用 `@Namespace` + `glassEffectID` 协调出现/消失：

```swift
@Namespace private var glassNS
@State private var expanded = false

var body: some View {
    GlassEffectContainer(spacing: 40) {
        HStack(spacing: 40) {
            Image(systemName: "scribble.variable")
                .frame(width: 80, height: 80)
                .glassEffect()
                .glassEffectID("pencil", in: glassNS)

            if expanded {
                Image(systemName: "eraser.fill")
                    .frame(width: 80, height: 80)
                    .glassEffect()
                    .glassEffectID("eraser", in: glassNS)
            }
        }
    }

    Button("Toggle") {
        withAnimation { expanded.toggle() }
    }
    .buttonStyle(.glass)
}
```

切换可见性时用 `withAnimation`；需要时可配合 `glassEffectTransition`。

## 导航层推荐配置

```swift
TabView {
    Tab("Home", systemImage: "house") { HomeView() }
    Tab("Search", systemImage: "magnifyingglass", role: .search) {
        SearchView()
    }
}
.tabBarMinimizeBehavior(.onScrollDown)
```

```swift
NavigationSplitView {
    Sidebar()
} detail: {
    Detail()
        .backgroundExtensionEffect()   // 内容在侧栏下「延伸」的错觉
}
```

## 克制清单

- [ ] 玻璃只出现在浮动控件 / 工具簇 / 主操作
- [ ] 列表行、文章正文、设置页表单 **不用** `.glassEffect`
- [ ] 未在玻璃上再叠玻璃
- [ ] 多元素已进 `GlassEffectContainer`
- [ ] 已用最新 SDK 构建并在真机 / 模拟器看过浅色与深色

## 兼容开关（了解即可）

若需「用新 SDK 构建但保持旧外观」，可在 Info 使用
`UIDesignRequiresCompatibility`（见 Apple 文档）。**本标准默认不启用**——产品要苹果风味，应拥抱新材质。
