# WeChat Mini-Program Template（原生 + TypeScript）

> 决策：[ADR-0008](../../playbook/adr/0008-templates-wechat-mp-scaffold.md) · 标准：[wechat-mp.md](../../playbook/wechat-mp.md)

## 部署

```bash
mkdir -p ~/AgentProjects/my-miniapp && cd ~/AgentProjects/my-miniapp
git init
~/AgentProjects/dev-standards/scripts/sync.sh template wechat-mp .
```

## 部署后必做

1. 复制 `project.private.config.example.json` → `project.private.config.json`，填入真实 `appid`
2. 编辑 `CLAUDE.md`：`YOUR_APPID`、`YOUR_API_BASE_URL`
3. 合并 dev-standards 标准到项目：

   ```bash
   ~/AgentProjects/dev-standards/scripts/sync.sh hooks-precommit .
   ~/AgentProjects/dev-standards/scripts/sync.sh adapters cursor .
   pnpm install
   ```

4. GitHub Secrets：`WECHAT_APPID`、`WECHAT_PRIVATE_KEY_BASE64`（见 `.github/workflows/` 注释）
5. 跑 `pnpm check` 确认本地通过

## 占位符

| 占位 | 替换为 |
|---|---|
| `YOUR_APPID` | 微信公众平台 appid |
| `YOUR_API_BASE_URL` | 后端 API 根 URL（dev/trial/release 写 CLAUDE.md） |
| `private.YOUR_APPID.key` | CI 中 Secrets 解码后的私钥文件名 |

## 与 ai-todo 的关系

本模板提取**工程结构**（参考 ai-todo `apps/miniapp/`），**不含** ai-todo 业务页面与 API 类型。
复杂项目可从 ai-todo 复制 domain 代码，再对照 wechat-mp 标准补差。

## 包含

- `miniprogram/` — app + index 页 + `services/http.ts` + wxp 工具
- `scripts/bump-version.mjs` — 同步 package.json ↔ project.config.json
- `.github/workflows/ci.yml` / `release.yml`
- ESLint / Prettier / tsconfig 最小配置
