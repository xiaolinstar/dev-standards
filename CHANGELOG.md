# Changelog

All notable changes to the dev-standards Claude Code plugin follow [Semantic Versioning](https://semver.org/).

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
