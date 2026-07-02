# 项目模板（方案 C — Phase 3 部分激活）

ADR-0001 暂缓完整 template monorepo；Phase 3 按 [ADR-0008](../playbook/adr/0008-templates-wechat-mp-scaffold.md) 激活微信小程序模板。

## 可用模板

| 模板 | 部署命令 | 标准 |
|------|----------|------|
| `wechat-mp/` | `sync.sh template wechat-mp <dest>` | [wechat-mp.md](../playbook/wechat-mp.md) |
| `h5-admin/` | `sync.sh template h5-admin <dest>` | [h5-admin.md](../playbook/h5-admin.md) + [web.md](../playbook/web.md) |

## 部署后

1. 读模板内 `README.md` 替换 `YOUR_*` 占位符
2. `sync.sh hooks-precommit` + `sync.sh adapters cursor` 部署标准
3. `dev-bootstrap` 审计合规

## 品牌色覆盖

h5-admin 模板默认使用蓝主色 (`--project-primary-color: #2563eb`)。项目覆盖：

```css
/* src/styles/brand.css */
:root {
  --project-primary-color: #YOUR_BRAND_COLOR;
}
```

## 未来

Python API / Next.js 等模板：触发条件同 principles.md「显式延后」— 出现 2 个及以上非 Vue Web 前端项目时启动。
Vue 生态内的 Web 后台基线已落地于 [web.md](../playbook/web.md)。
