# 项目模板（方案 C — Phase 3 部分激活）

ADR-0001 暂缓完整 template monorepo；Phase 3 按 [ADR-0008](../playbook/adr/0008-templates-wechat-mp-scaffold.md) 激活微信小程序模板。

## 可用模板

| 模板 | 部署命令 | 标准 |
|------|----------|------|
| `wechat-mp/` | `sync.sh template wechat-mp <dest>` | [wechat-mp.md](../playbook/wechat-mp.md) |

## 部署后

1. 读模板内 `README.md` 替换 `YOUR_*` 占位符
2. `sync.sh hooks-precommit` + `sync.sh adapters cursor` 部署标准
3. `dev-bootstrap` 审计合规

## 未来

Python API / Next.js 等模板：触发条件同 principles.md「Web 前端目录约定」— 第 2 个项目出现时评估。
