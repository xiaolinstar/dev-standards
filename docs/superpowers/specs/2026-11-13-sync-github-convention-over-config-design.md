# sync-github：约定优于配置（文件全量同步）

Date: 2026-11-13  
Status: Draft（待用户审阅后进入实现计划）  
Scope: `dev-standards` · `scripts/env/sync-github-env.mjs` 及相关 L0 / 文档  
Out of scope（后续）：旧扁平文件兼容增强、`DEPLOY_SSH_KEY_FILE` 等本地变换、仓库级与 Environment 混合推送策略细化

## 问题

1. 本地 `variables.env` 混入 `GITHUB_REPOSITORY` / `GITHUB_ENVIRONMENT` 等**元数据**，与要推上 GitHub 的**数据**不分。
2. 实际推送键由 `github-sync-profiles.json` **白名单**决定，导致「文件里有键却不同步」——与 GitHub Environment「Variables + Secrets」及开发者直觉不符。
3. gateway 等无 Variables 的项目仍被迫维护仅含元数据的 `variables.env`，产生歧义。

## 目标

- **约定优于配置**：路径与 CLI 决定 project / environment / repository；数据文件只含要同步的键。
- **文件全量同步**：`variables.env` → Environment（或仓库）Variables；`secrets.env` → Secrets。
- **可选文件**：无 Variables 时可省略 `variables.env`（及对应 L0 `.example`）。
- **特殊键**：本阶段不做魔法变换；用户自行准备可原样推送的值；用 `--dry-run` 自检。

## 非目标（本阶段）

- 不实现 `*_FILE` / `*_B64` 自动展开。
- 不删除 profile 文件本身（仍承载 repository、scope、可选 required 校验）。
- 不强行改写用户已有的 `~/.config/.../*.env`；迁移说明要求删除文件内 `GITHUB_*`——若仍保留，全量同步会把它们当作普通 Variable 推上 GitHub（由 dry-run 可见）。

## 约定

```text
~/.config/xiaolinstar/<project>/github/<environment>/
  variables.env   # 可选
  secrets.env     # 可选
```

| 元数据 | 来源（约定） | 主动声明（覆盖） |
|--------|--------------|------------------|
| project | `--project` | — |
| environment | `--environment` / `--env` | — |
| repository | profile.`repository`，缺省 `xiaolinstar/<project>` | 本阶段不支持文件内覆盖 |
| scope | profile.`scope`（`environment` \| `repository`） | — |

`scope: repository`：读 `github/variables.env` + `github/secrets.env`（无环境子目录），`gh … set` 不带 `--env`。

至少存在 `variables.env` 或 `secrets.env` 之一；二者皆缺 → 报错并提示 `init-github-env`。

## 同步语义

1. 分别解析两个文件（存在才读）。
2. 对每个非空 `KEY=value`：
   - 来自 `variables.env` → `gh variable set KEY --repo <repository> [--env <environment>] --body <value>`
   - 来自 `secrets.env` → `gh secret set …`（同上）
3. **不再**用 profile.`variables` / `secrets` 数组过滤。
4. profile 可选保留 `required_variables` / `required_secrets`：仅校验「键存在且非空」，缺则 exit 1。
5. `--dry-run`：打印将推送的 `variable|secret KEY → repo[/env]`，不调用 `gh` 写入。
6. 移除（或不再调用）基于 `DEPLOY_SSH_KEY_FILE` / `DEPLOY_SSH_KEY_B64` / inline `DEPLOY_SSH_KEY` 的自动读文件逻辑；需要私钥时用户把内容写入 `secrets.env` 对应 Secret 名，或自行 `gh secret set`。

## Profile 形状（本阶段）

```json
{
  "xiaolin-gateway": {
    "repository": "xiaolinstar/xiaolin-gateway",
    "scope": "environment",
    "config_dir": "~/.config/xiaolinstar/xiaolin-gateway/github",
    "required_secrets": ["SERVER_HOST", "SERVER_USER", "SERVER_PASSWORD"]
  }
}
```

- 删除或忽略：`variables`、`secrets` 白名单（实现时以「忽略」过渡亦可，文档标明废弃）。
- 删除或忽略：`ssh_key_secret` 自动路径（后续方案再议）。
- 保留：`repository`、`scope`、`config_dir`、`required_*`。

## L0 / 文档影响

- gateway：删除仅含 `GITHUB_*` 的 `variables.env.example`（或整文件不提供）；`env-registry` 中对应 `l0_variables` 可空/省略。
- `init-github-env`：variables 模板缺失时跳过并提示「optional」，不 fail；secrets 模板缺失时按项目需要 fail 或 warn（gateway：secrets 必有模板）。
- `env-management.md` / ADR-0012 补丁段：写明「全量同步 + 元数据来自约定」；不再要求文件内 `GITHUB_*`。
- 存量本地 `~/.config/.../variables.env`：用户应删除 `GITHUB_REPOSITORY` / `GITHUB_ENVIRONMENT`，否则会被当成 GitHub Variable 推送。

## 兼容（本阶段最小）

- 仅支持 ADR-0012 目录布局；旧扁平 `github-*.env` / `env.env`：**报错并提示新路径**（不做静默合并）。若实现成本过高，可保留只读加载一期，但不在本设计承诺范围内——**基础方案选择：新布局 only，缺失则明确报错**。

## 验收

1. gateway：仅有 `secrets.env` 时，`sync-github --environment aliyun-121 --dry-run` 列出三个 `SERVER_*`，无 variable 行；正式 sync 后 Environment Secrets 更新。
2. ai-todo（或任意含 variables 的项目）：`variables.env` 内所有非空键出现在 dry-run variable 列表；secrets 同理。
3. 文件内误留 `GITHUB_ENVIRONMENT=…` 时 dry-run 会显示将推送该 variable（文档已警告）。
4. 两文件皆无 → 非零退出。
5. Agent 禁区不变：人类终端执行 sync。

## 决议记录

- 方案 1（约定 + 文件全量同步）已认可。
- 特殊键 / 旧文件：后续方案；本阶段不做。
