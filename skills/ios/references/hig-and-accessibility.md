# HIG 与辅助功能清单

> 权威：[Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)
> [Materials](https://developer.apple.com/design/human-interface-guidelines/materials)

面向「苹果风味」产品的最短可执行清单；不是 HIG 全文摘要。

## 布局与触控

- [ ] 可点击区域 ≥ **44×44 pt**（图标按钮用 `.frame` 保证热区，不只靠 glyph 尺寸）
- [ ] 主要操作拇指区可达（底部 / 工具条），危险操作不与主操作紧贴难分
- [ ] 尊重 safe area；全屏沉浸内容用 `ignoresSafeArea` 时控件仍避让刘海与 Home Indicator
- [ ] 列表 / 表单用系统 `List` / `Form`，享受系统行高与圆角演进

## 文字与动态类型

```swift
// ✅
Text("Title").font(.title2)
Text("Body").font(.body)

// ❌ 压制用户字号设置
Text("Body").font(.system(size: 14))
```

- [ ] 主流程在最大 Dynamic Type 下不严重裁切（可滚动优先于缩小字）
- [ ] 数字 / 等宽需要时用 `.monospacedDigit()`，不要整页等宽字体

## 颜色与对比

- [ ] 使用 Semantic Color（`.primary` / `.secondary` / Asset Catalog 的 Any/Dark/High Contrast）
- [ ] 品牌 tint 用于强调，不用于大面积导航底
- [ ] 玻璃 / 材质上的文字在浅色模式仍可读（测 Reduce Transparency）

## 图标

- [ ] 优先 [SF Symbols](https://developer.apple.com/sf-symbols/)
- [ ] 渲染模式：模板图标跟 tint；多色符号有意为之才用 `.multicolor`
- [ ] 每个无文字图标控件有 `accessibilityLabel`（中文产品用中文标签）

## 动效

- [ ] 用 `withAnimation` / 系统转场；避免无限闪烁吸引注意
- [ ] `accessibilityReduceMotion == true` 时关闭大位移 morph / parallax
- [ ] Liquid Glass morph 依赖动画；Reduce Motion 下应有可理解的瞬时切换

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

withAnimation(reduceMotion ? nil : .snappy) {
    expanded.toggle()
}
```

## 必测辅助功能开关

| 设置                | 期望                     |
| ------------------- | ------------------------ |
| Reduce Transparency | 材质变实，文字对比不崩   |
| Reduce Motion       | 无眩晕大动画；功能仍可用 |
| Increase Contrast   | 边框 / 文字更清晰        |
| Bold Text           | 布局不溢出失控           |
| VoiceOver           | 主流程可朗读、可激活     |

## App 图标（Liquid Glass 时代）

- 用 **Icon Composer** / 分层图标资源，让系统处理高光与模糊
- 提供 Default / Dark / Clear / Tinted 所需层（按当前 Xcode 模板）
- 不要在母版里预烘焙最终圆角遮罩

## 审核向（简）

- 隐私权限字符串（`NSCameraUsageDescription` 等）写清用途
- 登录墙外提供可浏览内容或明确游客路径（按品类）
- 账户删除入口（若支持账户）符合现行 Guideline
