---
ID: 0007
Title: 微信小程序项目标准（原生 + TypeScript）
Status: Accepted
Date: 2026-06-27
Deciders: xingxiaolin
---

## 背景

3 个原生微信小程序项目（ai-todo / drink-budget / party-helper）均已上线，但长期缺乏统一标准：

- **每次新建/接手项目都要重新决定**技术选型（状态管理、Lint、测试）和工程结构（目录、CI workflow）。
- **3 个项目之间结构不一致**，同一个工具在 3 个项目里要走不同的命令路径。
- **CI/CD 与版本流程各自实现**，上传体验版/正式版靠"我记得当时是怎么做的"。

12-Factor V 要求"build / release / run 严格分离"，CNCF TAG App Delivery 要求"标准化发布流程"。在原生小程序场景下，**官方工具 `miniprogram-ci` 已经是事实标准**，但本仓此前未把它纳入基线。

## 决策

为原生 + TypeScript 微信小程序项目定义 [playbook/wechat-mp.md](../wechat-mp.md) 作为跨项目标准。关键选择：

### 1. 不引入跨端框架（Taro / uni-app）

**理由**：3 个项目均不需跨端；引入跨端会显著增加包体积（运行时 + 编译产物）和学习成本。原生最轻，符合"3 个项目体量不大"的现实。

**未来扩展**：如需支持跨端，新增 ADR，本标准不覆盖。

### 2. 状态管理默认 MobX / zustand（不强制 redux）

**理由**：3 个项目业务状态都不复杂；redux 的 action/reducer/store 三件套是过重模板。MobX 装饰器风格 + zustand hook 风格都适合小程序生命周期。

**强制项**：状态变更必须可追踪（DevTools 能看），但不强制具体库。

### 3. CI/CD 用 GitHub Actions + `miniprogram-ci`

**理由**：`miniprogram-ci` 是微信官方 CI 工具，可命令行完成"上传开发版 / 体验版"全过程，免本地微信开发者工具。GitHub Actions 是仓库内项目最常用的 CI 平台。

**不强制**：项目用 Gitee / CODING / GitLab CI 时，替换 workflow 文件即可，命令一致。

### 4. 分环境对应微信三档（开发版 / 体验版 / 正式版）

**理由**：这是微信公众平台原生支持的三个发布档位，强行引入自定义"preprod / staging"无意义。

| 环境 | 触发 | 谁审 |
|---|---|---|
| 开发版 | push to main | 内部（自动） |
| 体验版 | tag `trial-v*` 或手动 | 体验成员 |
| 正式版 | GitHub Release | **人工到微信后台提交审核** |

**关键约束**：CI **不**自动提交正式版审核（涉及类目、隐私协议、内容合规，必须人工）。

### 5. 版本策略：代码版本 = APP versionName = CHANGELOG

**理由**：微信小程序要求 `project.config.json` 的 `versionName` 严格递增且与"上传号"绑定。3 个项目历史上都出现过"代码改了 versionName 没改"导致上传失败。

**机制**：

- 代码版本用 semver，由 release-please 自动 bump
- `scripts/bump-version.ts` 同步到 `project.config.json`
- 上传号 dev 用 `1.0.${run_number}`，避免与正式版冲突

### 6. 密钥走 GitHub Secrets，`project.private.config.json` 不入库

**理由**：微信小程序密钥一旦泄露 = appid 被他人控制。私钥（`private.<APPID>.key`）和 appid 都不能进库。

**实现**：

- `private.<APPID>.key` 在 CI 时由 Secrets base64 解码到临时文件
- `project.private.config.json`（含 appid / 私钥路径 / es6 设置）必须 gitignore
- pre-commit gitleaks 兜底

## 范围

**覆盖**：

- 技术选型（语言、框架、状态、样式、Lint、测试、提交）
- 项目结构（目录树、命名）
- 分环境与发布流程
- CI/CD workflow 模板
- 版本策略
- 密钥管理

**不覆盖**：

- 跨端方案（Taro / uni-app）→ 未来如需支持，新增 ADR
- 云开发（wx.cloud）为主的项目 → 单独 ADR
- 插件市场 / 硬件小程序 → 单独 ADR
- 业务域特定决策（具体接口签名、数据库选型）→ 项目级 CLAUDE.md

## 后果

**正面**：

- 3 个项目可复用同一份 CI workflow、同一份脚手架
- 新建项目从 `templates/wechat-mp/` 复制即可，30 分钟内可跑通
- 任何小程序项目的"该有的东西"清单明确

**负面 / 风险**：

- 偏离本标准的小程序项目需走 ADR 例外流程
- 3 个已上线项目需要按本标准**审计 → 补差**（详见 dev-bootstrap 走审计模式）
- 微信平台政策变化时（如"上传号规则调整"），需重审本标准

## 缺口

| 缺口 | 计划 | 链到 |
|---|---|---|
| 3 个项目历史代码可能与本标准不一致 | `dev-bootstrap` 审计后逐项补差 | [skills/dev-bootstrap](../../skills/dev-bootstrap/SKILL.md) |
| Taro / uni-app 不在覆盖范围 | Phase 3 视需要扩展 | 待 |
| E2E automator 在 CI 中稳定性 | 暂不强制，列为可选 | 待 Phase 2 |
| 小程序码（QR）生成 CI 化 | 当前手动，wxacode.get 可后续接入 | 待 Phase 2 |
| 微信审核策略变化跟踪 | 关注 [微信公众平台公告](https://mp.weixin.qq.com/) | 持续 |

## 落地

- [playbook/wechat-mp.md](../wechat-mp.md) — "怎么用"
- [playbook/INDEX.md](../INDEX.md) — 主题段已加链接
- [skills/wechat-mp/](../../skills/wechat-mp/) — domain 知识 Skill（`sync.sh skills` 同步）
- [templates/wechat-mp/](../../templates/wechat-mp/) — 脚手架（`sync.sh template wechat-mp`）
