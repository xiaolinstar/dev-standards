# mixcrit iOS 合规审计报告（SwiftUI + Liquid Glass / 苹果风格）

> **审计日期**：2026-07-18
> **项目路径**：`~/AgentProjects/mixcrit`（与 `dev-standards` 同级，非本仓子目录）
> **审计依据**：[ios.md](../ios.md) · [ADR-0014](../adr/0014-ios-swiftui-liquid-glass-baseline.md) ·
> [skills/ios/](../../skills/ios/SKILL.md) · [ci-minimum-gate.md](../ci-minimum-gate.md)
> **当前工程标识**：`0.0.15 (15)` / P0.13 九宫格吧台原型；`IPHONEOS_DEPLOYMENT_TARGET = 17.0`

---

## 执行摘要

**部分合格（偏「游戏化暗色酒吧」美学，尚未对齐 Liquid Glass 代苹果系统语言）**。

工程是纯 SwiftUI + SpriteKit 原生原型，无跨端、无密钥泄露面，部分控件已用真
`.ultraThinMaterial`——这比「假玻璃」好一档。但对照 `ios.md`：

- **没有** Liquid Glass API / `DesignSystem/Glass.swift` 门控封装
- 大量卡片仍用 `.white.opacity(0.07~0.08)` **假玻璃**
- **零** `accessibilityLabel`；大量写死 `Font.system(size:)`；触控高度可压到 **38 / 22 pt**
- 强制 `.preferredColorScheme(.dark)`；部署 **iOS 17**（标准地板 iOS 18）
- 无测试 target、无 CI、无 `CLAUDE.md`、无 Cursor `ios` adapter

作为 P0 原型可理解；若产品定位是「有设计感、苹果风味」，下列 **P0/P1 应优先修设计层**，工程层可跟第二波。

---

## 本仓库待修复（A/C）— mixcrit

| #      | 问题                                                                                      | 严重度 | 证据                                                                                                                                                                                      | 修复建议                                                                                                                                        |
| ------ | ----------------------------------------------------------------------------------------- | ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| **1**  | **假玻璃卡片**：信息面板用 `Color.white.opacity` 铺底，非系统 Material / Glass            | **P0** | `ScoreView.swift:54` `.background(.white.opacity(0.08), …)`；`ServeFeedbackView.swift:81,120`；`GridBarMixingView.swift:132,181,277,347`；`SimplifiedMixingView.swift:139`                | 抽 `DesignSystem/Glass.swift`：iOS 26+ `.glassEffect` / 否则 `.ultraThinMaterial`；业务侧改调 `appGlass`；**禁止**卡片级 `white.opacity` 假材质 |
| **2**  | **无障碍空白**：全仓 0 处 `accessibilityLabel` / Reduce Motion / Reduce Transparency 处理 | **P0** | `rg accessibility` → 无匹配                                                                                                                                                               | 图标-only / 原料格子 / 出杯按钮补中文 label；引导与庆祝动画读 `accessibilityReduceMotion`；材质路径测 Reduce Transparency                       |
| **3**  | **触控热区低于 44pt**：主操作可缩到 38，次要按钮可到 22                                   | **P0** | `ScreenLayout.swift:76-77` `actionButtonHeight = max(38, 44 * scale)`；`secondaryButtonHeight = max(20, 22 * scale)`；引导主按钮 `MixingOnboardingOverlay.swift:53` `max(34, 40 * scale)` | 地板改为 `max(44, …)`；次要操作若视觉更小，用透明 `contentShape` / `.frame(minHeight: 44)` 保热区                                               |
| **4**  | **Dynamic Type 被压制**：多处写死 pt                                                      | **P1** | 10 个文件含 `.font(.system(size:`（如 `ActionButton.swift:31-33`、`BarHomeView.swift:27`、`MixingOnboardingOverlay.swift:38,44,51`）                                                      | 标题/正文优先语义字体（`.title2` / `.body` / `.caption`）；游戏 HUD 若必须固定字号，在 `CLAUDE.md` 登记例外并保证最大字号下主流程可滚动         |
| **5**  | **部署目标 iOS 17 ≠ 标准 iOS 18**                                                         | **P1** | `project.pbxproj` `IPHONEOS_DEPLOYMENT_TARGET = 17.0`                                                                                                                                     | 能升则升到 18；不能升则在项目 `CLAUDE.md` 写 ADR-0014 例外理由                                                                                  |
| **6**  | **强制深色**：整 App `.preferredColorScheme(.dark)`                                       | **P1** | `ContentView.swift:114`                                                                                                                                                                   | 酒吧氛围可默认深色，但应允许跟随系统 / 提供设置；至少验收浅色 + Reduce Transparency 一条路径，避免「只在深色壁纸好看」                          |
| **7**  | **无 Liquid Glass / 系统 chrome 采纳路径**                                                | **P1** | 全仓无 `glassEffect` / `GlassEffectContainer` / `.buttonStyle(.glass)`；流程用 `ZStack + switch phase`，无 `NavigationStack`/`TabView`                                                    | 游戏全屏舞台可保留自定义；**工具条 / 弹层 / 主 CTA** 走系统 buttonStyle + Glass 封装；升级 SDK 后先删多余自定义背景再看系统效果                 |
| **8**  | **材质上再叠假半透明**                                                                    | **P2** | `ActionButton.swift:40-41` Material + `tint.opacity`；`MixingOnboardingOverlay.swift:60-61` Material + `Color.white.opacity(0.08)`；`MixingStationView.swift:164-170` dock 同模式         | tint 用 `.glass(.regular.tint)`（iOS 26）或减少第二层 opacity；避免 Material 上再铺一层假白雾                                                   |
| **9**  | **架构未按 Feature 切片 / 无 `@Observable` VM**                                           | **P2** | 状态全堆在 `ContentView.swift` `@State`；目录为 `Models/` `Logic/` `Views/` 横切                                                                                                          | P1 经营前再垂直切片；短期可接受，但网络/库存一进就应拆 ViewModel                                                                                |
| **10** | **工程底座缺口**：无测试、无 CI、无 `CLAUDE.md`、App Icon 单层 PNG                        | **P2** | `AGENTS.md` 自陈无 test target；无 `.github/workflows`；`AppIcon.appiconset/AppIcon.png` 单图                                                                                             | 补 scoring 单测（`MojitoScorer` 等纯逻辑）；CI `xcodebuild test`；`CLAUDE.md` 写 Bundle ID / 最低系统 / 设计例外；图标走 Icon Composer 分层     |

---

## 标准库待反馈（B/C）

| #     | 问题                                                                                                              | 建议落点                                                                                                 | 状态                                   |
| ----- | ----------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- | -------------------------------------- |
| **1** | **游戏类全屏 App**（自定义舞台、强制氛围色、弱化 Navigation chrome）与「系统组件优先拿免费 Liquid Glass」存在张力 | `playbook/ios.md` 增「游戏 / 沉浸式例外」小节：舞台可自定义，**控件层仍须 Material/Glass + 44pt + a11y** | **待确认**（建议补，避免下一轮假阳性） |
| **2** | SpriteKit / SceneKit 与 SwiftUI 混布时的材质边界未写                                                              | `skills/ios/references/pitfalls.md` 或 `architecture.md` 加一小节                                        | 待                                     |
| **3** | 审计索引 README 仍只写 web/h5-admin 依据                                                                          | `playbook/audits/README.md` 扩展 ios 依据                                                                | **本轮已改**                           |

---

## 合规评分卡（对照 ios.md 检查清单）

### 设计语言 / 苹果透明风格

| 项                                  | 结果 | 说明                                                                                |
| ----------------------------------- | ---- | ----------------------------------------------------------------------------------- |
| 系统组件优先（导航/Tab/Toolbar）    | ⚠️   | 游戏用自定义 phase 切换，合理；但控件层未预留系统 glass 路径                        |
| Liquid Glass（iOS 26+）             | ❌   | 未使用任何 `glassEffect` / glass buttonStyle                                        |
| Materials 回退                      | ⚠️   | `ActionButton`、订单胶囊、dock、部分卡片用了 `.ultraThinMaterial`；大量面板仍假玻璃 |
| 禁止假玻璃                          | ❌   | 多处 `.white.opacity(0.07/0.08)`                                                    |
| `DesignSystem/Glass.swift` 集中门控 | ❌   | 目录不存在                                                                          |
| 玻璃克制（不整页铺）                | ✅   | 内容舞台是写实调酒/SpriteKit，未整页毛玻璃——方向对                                  |

### HIG / 辅助功能

| 项                                    | 结果 | 说明                                                          |
| ------------------------------------- | ---- | ------------------------------------------------------------- |
| 触控 ≥ 44pt                           | ❌   | `actionButtonHeight` 地板 38；`secondaryButtonHeight` 地板 22 |
| Dynamic Type                          | ⚠️   | 部分用语义字体，但关键 HUD/标题大量写死 pt                    |
| accessibility label                   | ❌   | 全仓 0                                                        |
| Reduce Transparency / Motion 实测路径 | ❌   | 代码无分支；强制 dark 增加验收死角                            |
| SF Symbols                            | ✅   | 操作按钮广泛使用                                              |
| Semantic / 品牌色                     | ⚠️   | 大量手写 `Color(red:g:b:)`；可接受于游戏皮肤，建议收拢 Tokens |

### 工程 / 基线

| 项                               | 结果 | 说明                                                   |
| -------------------------------- | ---- | ------------------------------------------------------ |
| SwiftUI 优先                     | ✅   | 纯原生；SpriteKit 仅舞台                               |
| 最低部署 iOS 18                  | ❌   | 现为 17.0                                              |
| SPM / 无 CocoaPods               | ✅   | 无第三方依赖                                           |
| Feature 垂直切片 + `@Observable` | ❌   | 横切 + ContentView 上帝状态                            |
| 测试 + CI build/test             | ❌   | 无                                                     |
| 密钥 / 证书不入库                | ✅   | 离线原型，无敏感面；gitignore 已忽略 DerivedData/build |
| `CLAUDE.md` / 标准例外登记       | ❌   | 仅有 `AGENTS.md`                                       |
| Cursor `ios.mdc` 已部署          | ❌   | 项目无 `.cursor/rules`                                 |

### 已做得好的地方（别误伤）

1. **真 Material 已起步**：`ActionButton`、调酒台 dock、订单胶囊、部分 overlay 用了 `.ultraThinMaterial`，不是纯 CSS 思维假模糊。
2. **首页主 CTA** 用系统 `.borderedProminent` / `.bordered`（`BarHomeView.swift:64-88`）——升级 SDK 后最容易「免费」吃到新材质。
3. **Safe area + 自适应布局**：`ScreenLayout` 按可用高度分档，原料宽度保底 44。
4. **文档完整**：`docs/` 产品/规格/QA 分层清晰；版本与 P0 目标在 README 说清楚。
5. **无跨端包袱**：符合 ADR-0014「SwiftUI 优先」前提。

---

## 苹果风格落差（一句话画像）

| 维度   | 现状体感                                      | 目标体感（ios.md）                               |
| ------ | --------------------------------------------- | ------------------------------------------------ |
| 材质   | 暗色酒吧 + 局部真 Material + 多处假半透明卡片 | 控件层 Liquid Glass / Material，内容层写实不透明 |
| 控件   | 自定义胶囊 + plain Button + 手绘描边光晕      | 系统 glass / bordered + 克制 tint                |
| 导航   | 全屏 phase 切换                               | 沉浸舞台可保留；工具/弹层跟系统                  |
| 无障碍 | 未建模                                        | 标签 + Reduce\* + 动态字体为默认验收             |

---

## 建议修复顺序（可执行）

### Wave 1 — 设计语言与触控（约 1–2 人日）

1. 新增 `mixcrit/DesignSystem/Glass.swift`（`appGlass` 门控，对齐 Skill 示例）。
2. 替换所有 `.background(.white.opacity(0.0x), in: …)` 信息卡片为 `appGlass` / Material。
3. `ScreenLayout` 触控地板统一 ≥ 44；引导按钮同步。
4. 为原料格、出杯、返回等补 `accessibilityLabel`。

### Wave 2 — 系统语言与部署（约 0.5–1 人日）

1. 评估部署升到 iOS 18；写 `CLAUDE.md`（Bundle ID、版本策略、游戏沉浸例外）。
2. 主 CTA / 弹层按钮改为系统 style，并预留 `#available(iOS 26, *)` glass style。
3. 重新考虑 `preferredColorScheme(.dark)`：默认暗色 vs 强制暗色。

### Wave 3 — 工程底座（约 1 人日）

1. 给 `MojitoScorer` / FeedbackEvaluator 加 Swift Testing。
2. GitHub Actions `macos-*`：`xcodebuild test`。
3. `./scripts/sync.sh adapters cursor ~/AgentProjects/mixcrit` 挂上 `ios.mdc`。

---

## 下一步

1. **请确认 B1**：是否在 `ios.md` 增加「游戏 / 沉浸式例外」——控件层仍强制 Material/Glass + 44pt + a11y，舞台允许自定义。
2. 确认后可在 mixcrit 开 Wave 1 PR（假玻璃清除 + Glass 封装 + 触控地板）。
3. 需要我直接改 mixcrit 代码时，说一声（当前工作区是 `dev-standards`，改业务仓前建议 `move_agent_to_root`）。
