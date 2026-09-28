---
ID: 0014
Title: iOS 原生 App 基线（SwiftUI + Liquid Glass 设计语言）
Status: Accepted
Date: 2026-07-18
Deciders: xingxiaolin
---

## 背景

个人产品开始出现「有设计感、苹果风味」的原生 iOS App（透明/玻璃质感、系统控件优先）。
`dev-standards` 已覆盖微信小程序、H5、Web 后台，但 **iOS 原生空白**：

- 每次新建 App 都要重新决定 UI 框架、架构、设计语言与最低系统版本。
- 「透明风格」没有统一约定：有人用旧 `Material` / `UIVisualEffectView`，有人硬画半透明色，
  与 iOS 26 起的 **Liquid Glass** 系统语言脱节。
- Agent 写 SwiftUI 时缺少可引用的 HIG / Liquid Glass API 工具书，容易做出「假玻璃」或过度叠层。

Apple 在 WWDC25 / iOS 26 将 Liquid Glass 定为跨平台控件与导航层的默认材质；
标准组件（TabBar、Toolbar、Sheet 等）在最新 SDK 下自动采纳。
本仓需要把这一事实标准固化为跨项目基线。

## 决策

为原生 iOS App 定义 [playbook/ios.md](../ios.md) 作为跨项目标准。关键选择：

### 1. UI 框架：SwiftUI 优先，不默认 UIKit

**理由**：Liquid Glass 在 SwiftUI 上 API 最完整（`.glassEffect`、`GlassEffectContainer`、
`.buttonStyle(.glass)`）；声明式布局与系统动画对齐成本最低。UIKit 仅作互操作例外
（复杂地图、成熟第三方控件、渐进迁移），不另开 UIKit 基线。

### 2. 设计语言：Liquid Glass 为默认，Materials 为回退

**理由**：产品定位是「苹果风味、有设计感」。默认跟随系统最新材质语言，而不是自绘半透明色。

| 系统版本  | 导航 / 控件层                                          | 自定义玻璃控件                      |
| --------- | ------------------------------------------------------ | ----------------------------------- |
| iOS 26+   | 系统组件自动 Liquid Glass；自定义用 `.glassEffect` 等  | 优先系统 API                        |
| iOS 18–25 | 系统组件用 Materials；自定义用 `.ultraThinMaterial` 等 | 禁止假玻璃（`Color.white.opacity`） |

**强制**：自定义玻璃必须 `#available(iOS 26, *)` 门控，并提供 Materials 回退。

### 3. 最低部署版本：iOS 18

**理由**：覆盖近两年设备，同时避免为 iOS 15/16 维护过时布局 API。
Liquid Glass 能力按运行时可用性启用，不强迫用户升到 iOS 26 才能用 App。

### 4. 架构：`@Observable` + 轻量 MVVM；包管理用 SPM

**理由**：Observation 框架是 SwiftUI 官方状态路径；避免引入 Combine 样板或第三方
状态库作为默认。SPM 是 Xcode 一等公民，不引入 CocoaPods 作为基线。

### 5. 设计原则：系统组件优先，玻璃克制使用

**理由**：Apple《Adopting Liquid Glass》明确——过度自定义背景会遮挡系统效果；
玻璃应限于导航/控件功能层，内容层保持不透明可读。本标准把此条上升为强制约定。

### 6. 可访问性：Reduce Transparency / Reduce Motion / Dynamic Type 为必测

**理由**：半透明与流体动画在辅助功能开启时会被系统削弱或关闭。只用系统组件可自动适配；
自定义玻璃必须手测上述三项，否则视为不合规。

## 范围

**覆盖**：

- 技术选型（语言、UI、架构、包管理、测试、CI）
- 设计语言（Liquid Glass + Materials 回退）与 HIG 对齐要点
- 项目结构与命名
- 安全与密钥（Keychain、ATS、不入库证书）
- Agent 可引用的 Skill / Cursor adapter

**不覆盖**：

- React Native / Flutter / Kotlin Multiplatform → 单独 ADR
- watchOS / tvOS / visionOS 专属规范 → 需要时扩展本文或新 ADR
- 业务域（具体产品逻辑、后端契约细节）→ 项目级 `CLAUDE.md` / `AGENTS.md`
- App Store 审核话术与营销素材 → 项目级文档

## 后果

**正面**：

- 新建 iOS App 有明确默认：SwiftUI + Liquid Glass + iOS 18 floor
- Agent 可通过 `@ios` Skill 直接引用玻璃 API、HIG checklist 与坑点
- 与 H5 / 小程序标准并列，补齐「移动端原生」空白

**负面 / 风险**：

- iOS 26 API 仍在演进，命名或行为微调时需修订 Skill references
- 低于 iOS 18 的存量项目需走 ADR 例外或单独登记最低版本
- macOS CI runner 成本高于 Linux；CI 最低门槛以 Xcode 构建 + 单测为准，真机 UI 测不强制

## 缺口

| 缺口                                           | 计划                         | 链到       |
| ---------------------------------------------- | ---------------------------- | ---------- |
| 尚无 `templates/ios/` 脚手架                   | 出现第 2 个 iOS 产品时再激活 | 待 Phase 2 |
| Xcode Cloud vs GitHub Actions macOS 选型未强制 | 项目级 CLAUDE.md 登记        | 持续       |
| Liquid Glass 上游变更跟踪                      | 关注 WWDC / HIG Materials 页 | 持续       |
| 多窗口 iPad / Stage Manager 细则               | 有 iPad 主力产品时补章节     | 待         |

## 落地

- [playbook/ios.md](../ios.md) — 「怎么用」
- [playbook/INDEX.md](../INDEX.md) — 主题段加链接
- [skills/ios/](../../skills/ios/) — domain Skill（`sync.sh skills`）
- [adapters/cursor/ios.mdc](../../adapters/cursor/ios.mdc) — Cursor Rules 派生镜像
