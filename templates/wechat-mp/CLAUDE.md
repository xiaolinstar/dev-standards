# YOUR_PROJECT 小程序

## 项目信息

| 项 | 值 |
|---|---|
| AppID | YOUR_APPID |
| API Base（dev） | YOUR_API_BASE_URL |
| 负责人 | YOUR_NAME |

## 与标准库偏差

（无则删本节）登记与 [wechat-mp.md](https://github.com/xiaolinstar/dev-standards/blob/main/playbook/wechat-mp.md) 的有意偏离。

## 常用命令

```bash
pnpm check          # typecheck + lint + format:check
pnpm bump-version patch --write
```

## Hook 初始化

见 dev-standards `ci-minimum-gate.md`；部署：`sync.sh hooks-precommit .`
