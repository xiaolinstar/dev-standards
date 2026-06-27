# dev-standards Enterprise Phase 2 Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development or superpowers:executing-plans.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the consumption gap left after Phase 1 — Cursor rules for all topic playbooks, deployable pre-commit hooks, dev-bootstrap baseline checks, and traceId reference snippets.

**Architecture:** Playbook remains source of truth; adapters/hooks/skills only reference or derive. Build order: **sync.sh extension first** → Cursor `.mdc` trio → hooks templates → dev-bootstrap + snippets → INDEX/docs pass → acceptance.

**Tech Stack:** Markdown, `.mdc` (Cursor rules), bash, Husky 9 / lint-staged / commitlint / gitleaks (template only).

**Spec:** `docs/superpowers/specs/2026-06-27-dev-standards-enterprise-phase2-design.md`

**Prerequisite:** Phase 1 tag `phase-1-complete`; Sprint 0/1 doc hygiene done; `bash scripts/sync.sh validate` green.

## Global Constraints

- **Scope:** Phase 2 only. No Plugin manifest, no `templates/wechat-mp/` scaffold, no new ADR unless a decision changes.
- **Authoring language:** Chinese prose; English for code, paths, tool names.
- **Completion rule:** no `TODO` / `TBD` / `待定` in new playbook/hooks/adapters files; link from `INDEX.md`; `validate` exit 0 after each task commit.
- **Commit cadence:** one commit per task; Conventional Commits.
- **Cursor `.mdc`:** ≤ 80 lines body; bottom line cites playbook path.

---

## File Map

**Create:**

- `adapters/cursor/api-error-codes.mdc`
- `adapters/cursor/ci-minimum-gate.mdc`
- `adapters/cursor/wechat-mp.mdc`
- `hooks/pre-commit/README.md`
- `hooks/pre-commit/husky-pre-commit.sh`
- `hooks/pre-commit/husky-commit-msg.sh`
- `hooks/pre-commit/commitlint.config.cjs`
- `hooks/pre-commit/package.json.snippet`
- `playbook/snippets/trace-id-middleware.md`

**Modify:**

- `scripts/sync.sh` — `hooks-precommit` subcommand; `cmd_adapters` copies all `*.mdc`
- `skills/dev-bootstrap/SKILL.md` — §标准库健康检查
- `skills/dev-bootstrap/references/standards-overview.md` — baselines 月扫
- `playbook/INDEX.md` — snippets + adapter 列表
- `playbook/api-error-codes.md` — link traceId snippet
- `hooks/README.md` — pre-commit 段
- `adapters/README.md` — 3 个 `.mdc` 登记

**Untouched:**

- `playbook/baselines/*` content（仅 `last-reviewed` 可在 acceptance 时刷新）
- `git-commit-guard.py`
- Phase 3 `templates/`

---

## Task 1: `sync.sh hooks-precommit` + adapter multi-`.mdc` copy

**Goal:** Deployment plumbing before content.

- [ ] **Step 1:** Add `cmd_hooks_precommit()` — copy `hooks/pre-commit/*` to `<project>/` with README instructions; warn if `.husky/` already exists
- [ ] **Step 2:** Verify `cmd_adapters()` copies **all** `adapters/cursor/*.mdc` (not hard-coded list)
- [ ] **Step 3:** Update `usage()` heredoc
- [ ] **Step 4:** Smoke test both commands on `/tmp/dev-standards-smoke`
- [ ] **Step 5:** `bash scripts/sync.sh validate` → commit `feat(scripts): add hooks-precommit deploy command`

---

## Task 2: Cursor `api-error-codes.mdc`

**Files:** Create `adapters/cursor/api-error-codes.mdc`

- [ ] **Step 1:** Read `playbook/api-error-codes.md`; extract error body schema, prefix table, traceId rules
- [ ] **Step 2:** Write `.mdc` with `globs: **/*.{ts,py,go}` and `alwaysApply: false`
- [ ] **Step 3:** Bottom: `来源：playbook/api-error-codes.md`
- [ ] **Step 4:** validate + commit `feat(adapters): add cursor api-error-codes rule`

---

## Task 3: Cursor `ci-minimum-gate.mdc`

**Files:** Create `adapters/cursor/ci-minimum-gate.mdc`

- [ ] **Step 1:** Read `playbook/ci-minimum-gate.md` §必选 4 项 + §本地 pre-commit
- [ ] **Step 2:** Write `.mdc` — 4 mandatory gates + Husky stack names (no full yaml dump)
- [ ] **Step 3:** `globs: .github/workflows/**,.husky/**,package.json,commitlint.config.*`
- [ ] **Step 4:** validate + commit `feat(adapters): add cursor ci-minimum-gate rule`

---

## Task 4: Cursor `wechat-mp.mdc`

**Files:** Create `adapters/cursor/wechat-mp.mdc`

- [ ] **Step 1:** Read `playbook/wechat-mp.md` §目录结构 + §关键约定 + §分环境
- [ ] **Step 2:** Write `.mdc` — 目录树摘要、wxp 强制、http.ts、2MB 限制
- [ ] **Step 3:** `globs: apps/miniapp/**,**/miniprogram/**`
- [ ] **Step 4:** Point to `skills/wechat-mp/` for patterns
- [ ] **Step 5:** validate + commit `feat(adapters): add cursor wechat-mp rule`

---

## Task 5: `hooks/pre-commit/` templates

**Files:** Create `hooks/pre-commit/*`

- [ ] **Step 1:** `husky-pre-commit.sh` — gitleaks protect (degrade if missing) + lint-staged placeholder
- [ ] **Step 2:** `husky-commit-msg.sh` — commitlint
- [ ] **Step 3:** `commitlint.config.cjs` — `@commitlint/config-conventional`
- [ ] **Step 4:** `package.json.snippet` — prepare, lint-staged, devDependencies list
- [ ] **Step 5:** `README.md` — 安装步骤，链到 `ci-minimum-gate.md`
- [ ] **Step 6:** validate + commit `feat(hooks): add pre-commit template directory`

---

## Task 6: traceId snippet + api-error-codes link

**Files:** Create `playbook/snippets/trace-id-middleware.md`; modify `api-error-codes.md`, `INDEX.md`

- [ ] **Step 1:** Write snippet — FastAPI middleware + Express middleware minimal examples
- [ ] **Step 2:** Add `## 实现参考` section in `api-error-codes.md` linking snippet
- [ ] **Step 3:** INDEX §主题 or new §片段 链到 snippets/
- [ ] **Step 4:** validate + commit `docs(playbook): add traceId middleware snippet`

---

## Task 7: `dev-bootstrap` baseline checks

**Files:** Modify `skills/dev-bootstrap/SKILL.md`, `references/standards-overview.md`

- [ ] **Step 1:** Add §标准库健康检查 checklist:
  - [ ] `bash ~/AgentProjects/dev-standards/scripts/sync.sh validate` exit 0
  - [ ] baselines `last-reviewed` ≤ 30 days (or note stale in audit output)
- [ ] **Step 2:** Audit 输出格式引用 `audit-feedback-loop.md` B 类落点含 baselines
- [ ] **Step 3:** validate + commit `docs(skills): add baseline health checks to dev-bootstrap`

---

## Task 8: Documentation pass

**Files:** `hooks/README.md`, `adapters/README.md`, `playbook/INDEX.md`, `README.md`

- [ ] **Step 1:** hooks README — document `hooks-precommit` vs `hooks` (Claude guard)
- [ ] **Step 2:** adapters README — table lists 5 `.mdc` files
- [ ] **Step 3:** INDEX Adapters 段更新
- [ ] **Step 4:** README 快速开始加 `hooks-precommit` 一行
- [ ] **Step 5:** validate + commit `docs: Phase 2 file map and deploy docs`

---

## Task 9: Final acceptance

- [ ] **Step 1:** `bash scripts/sync.sh validate 2>&1 | tee /tmp/phase2-validate.log` → exit 0
- [ ] **Step 2:** File checklist from spec §4.1 — all `OK`
- [ ] **Step 3:** `sync.sh adapters cursor` + `sync.sh hooks-precommit` smoke on temp dir
- [ ] **Step 4:** `git tag phase-2-complete` (after all commits merged to main)
- [ ] **Step 5:** Working tree clean

---

## Self-Review

- Spec §2.1 all items mapped to Tasks 2–7
- Spec §2.2 out-of-scope items absent from tasks
- No new ADR unless implementation discovers a decision conflict
- Phase 3 items only mentioned in spec §6, not implemented here
