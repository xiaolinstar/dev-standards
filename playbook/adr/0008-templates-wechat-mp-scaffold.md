---
ID: 0008
Title: 激活 templates/wechat-mp 脚手架（Phase 3）
Status: Accepted
Date: 2026-06-28
Deciders: xingxiaolin
---

## 背景

[ADR-0001](0001-standards-repo-structure.md) 决定方案 C（templates/）暂缓，仅保留占位。
Phase 1 后落地 [wechat-mp.md](../wechat-mp.md) + [ADR-0007](../adr/0007-wechat-miniprogram-baseline.md)，
wechat-mp.md 与 ADR-0007 均引用 `templates/wechat-mp/`，但目录一直为空。

ai-todo `apps/miniapp/` 可作为参考实现；标准库提供**无业务 domain** 的最小 scaffold。

## 决策

1. 在 `templates/wechat-mp/` 提供最小可跑模板（目录、http.ts、CI workflow、bump-version、CLAUDE 占位）
2. 部署命令：`scripts/sync.sh template wechat-mp <dest>`
3. 模板**不含** ai-todo 业务页面/API；新项目复制后替换 `YOUR_*` 占位符
4. 仍**不**建设多模板 monorepo（Python API / Next.js 等留待触发条件）

## 后果

- [templates/wechat-mp/README.md](../../templates/wechat-mp/README.md) 为使用入口
- [ADR-0007](../adr/0007-wechat-miniprogram-baseline.md) 落地段更新为「已提供 scaffold」
- ADR-0001 后果段「方案 C 暂缓」仍成立，但 wechat-mp 单模板已激活
