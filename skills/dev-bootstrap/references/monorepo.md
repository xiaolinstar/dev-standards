# Monorepo Bootstrap 参考

标准库真源：`playbook/monorepo.md`、`playbook/adr/0002-monorepo-default-selection.md`

## 先判断要不要 monorepo

不满足以下条件时，保持**单包**，不要建空 `apps/` / `packages/`：

- ≥2 个独立可运行产物（API + CLI、Web + 小程序…）
- 或 ≥2 个消费者需要共享 TS 类型/客户端
- 或 各组件需要独立 SemVer 与发布节奏

## 初始化步骤

1. 根目录 `pnpm-workspace.yaml`：

   ```yaml
   packages:
     - "apps/*"
     - "packages/*"
   ```

2. 根 `package.json`：`private: true`、`packageManager`、`pnpm -r` 编排脚本

3. 创建 `apps/<first-app>/` 与（如需）`packages/shared/`

4. 有 TypeScript 时：根 `tsconfig.base.json`，子包 extends

5. 从 dev-standards 部署 Cursor adapter（含 `monorepo.mdc`）：`sync.sh adapters cursor <project>`

6. README 写清：`pnpm install`、常用 build/test 命令、各 app 入口

## 审计清单

```
Monorepo Audit:
- [ ] 符合 ADR-0002 升级条件（否则应拆回单包）
- [ ] pnpm-workspace.yaml 仅含 apps/*、packages/*
- [ ] 根 package.json 为 private，含 packageManager
- [ ] 无 packages → apps 反向依赖
- [ ] 内部依赖使用 workspace:*
- [ ] 各可发布组件有独立 version 源（package.json / pyproject.toml）
- [ ] 多组件时有 compatibility 或 release 文档
- [ ] scripts/ 中 CI 关键检查可不依赖 pnpm
- [ ] .gitignore 覆盖 node_modules、dist、.venv
```

## 输出格式

审计完成后报告：

1. 是否应为 monorepo（是/否 + 理由）
2. 已有项 / 缺失项（按阻塞程度排序）
3. 一条具体下一步（如「补 tsconfig.base.json」）
