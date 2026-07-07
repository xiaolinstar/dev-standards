# Changelog

All notable changes to the dev-standards Claude Code plugin follow [Semantic Versioning](https://semver.org/).

## [3.5.0] - 2026-07-07

- **Added** — [ADR-0012](playbook/adr/0012-config-github-l2-only.md)：`~/.config` 仅 GitHub L2 IaC；L3 运行时单一真源在 VPS
- **Added** — `github/<environment>/{variables,secrets}.env` 目录布局；`env init-github-env` 从 L0 模板初始化
- **Changed** — `env-management.md` 重写：废弃 L3 备份至 ~/.config；`import-config` / `apply-config` 退出并提示
- **Changed** — `github-sync-profiles.json` 使用 `config_dir` + `config_basename`；`sync-github-env.mjs` 兼容旧扁平路径
- **Changed** — L2 文件拆为 `variables.env` + `secrets.env`（对齐 GitHub Actions 官方名称）
- **Changed** — `check-env-keys.sh` 新增 `--github`；`--local` 废弃

## [3.4.0] - 2026-07-02

- **Added** — `playbook/web.md`（Web 项目统一规范：PC 优先自适应 + Vant 4 + Tailwind + Design Tokens）
- **Added** — `playbook/adr/0011-web-admin-baseline.md`（Web 后台基线决策，含两份 admin 差异对照附录）
- **Changed** — `playbook/h5-admin.md` 改为继承 web.md，聚焦运营后台特有规则（卡片列表、高危操作二次确认、图表、品牌色覆盖）；废弃旧"PC 沙盒伪手机壳"方案
- **Changed** — `playbook/principles.md` 移除「Web 前端目录约定」显式延后项，已落地于 web.md
- **Changed** — `templates/h5-admin/` 同步升级：App.vue 改为三段式骨架、删除 vw 适配插件、styles 引入 design tokens、login/dashboard 改为 PC 优先自适应栅格
- **Changed** — `templates/h5-admin/package.json` 移除 `postcss-px-to-viewport-8-plugin`（PC 优先场景不再需要 vw 适配）

## [3.3.0] - 2026-07-01

- **Added** — `skills/h5/`（H5 移动端开发 Skill：vw 适配、组件交互、WebView 兼容、坑点）
- **Added** — `adapters/cursor/h5.mdc`（Cursor Rules，派生自 h5.md + h5-admin.md）
- **Changed** — `playbook/INDEX.md` 注册 H5 通用规范主题、h5 Skill；修正 ADR-0010 链接
- **Changed** — `README.md` 目录树补充 skills/h5/ + templates/h5-admin/ + adapter 计数

## [3.2.1] - 2026-06-27

- **Added** — `playbook/env-migration-runbook.md` 与 `env-migration-status.yaml`
- **Added** — `scripts/env/{migration-status,import-to-config,apply-to-runtime}.sh`
- **Added** — `sync.sh env {status|import-config|apply-config}`

## [3.2.0] - 2026-06-28

- **Added** — `playbook/env-management.md`（L0–L3、`~/.config/xiaolinstar`）
- **Added** — `playbook/env-registry.yaml` 与 `scripts/env/*` 键名校验
- **Added** — `sync.sh env {init-config|check}`
- **Changed** — `permissions/manifest.json` deny 运行时 env；`ci-minimum-gate` 链 env-management

## [3.1.0] - 2026-06-28

- **Added** — `playbook/agent-config.md`（Claude + AGENTS 双体系最小维护）
- **Added** — `permissions/manifest.json` + overlays + `sync.sh permissions`
- **Added** — `skills/agent-permissions/`（跨 Agent check/deny 规则生命周期）
- **Added** — ai-todo API 错误码迁移参考实现链接（playbook / adapter / monorepo）
- **Changed** — GitHub 仓库 visibility 改为 public

## [3.0.0] - 2026-06-28

### Added

- Claude Code plugin manifest (`.claude-plugin/plugin.json`)
- Self-hosted `marketplace.json` for local plugin install
- `templates/wechat-mp/` scaffold + `sync.sh template wechat-mp`
- `playbook/snippets/structured-logging.md`
- ADR-0008: activate wechat-mp template

### Changed

- Phase 3 completes enterprise alignment roadmap (Phase 1–3)

## [2.0.0] - 2026-06-27

- Cursor adapter topic rules (api-error-codes, ci-minimum-gate, wechat-mp)
- Husky pre-commit templates (`hooks-precommit` deploy)
- traceId middleware snippet
- dev-bootstrap baseline health checks

## [1.0.0] - 2026-06-24

- Phase 1: baselines, ADR 0003–0006, validators, topic playbooks
