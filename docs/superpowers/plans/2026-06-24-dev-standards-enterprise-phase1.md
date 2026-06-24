# dev-standards Enterprise Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring `dev-standards` to enterprise-grade by aligning it with CNCF TAG App Delivery + 12-Factor, filling the principle gaps (API error codes, CI minimum gate), and adding validators to enforce the new structure.

**Architecture:** Layered docs (`principles.md` for Agent/流程, `playbook/baselines/*` for external baselines, `playbook/*-*.md` for technical topics, `playbook/adr/` for decisions). Build order is **validators first** (so every later file is checked as it's written), then baselines, then topic playbooks, then the link-update pass. Each new doc is paired with an ADR where the spec requires deviation decisions.

**Tech Stack:** Markdown, bash 3+ validators, `markdownlint-cli` (optional, via `pnpm dlx`), `git`.

**Spec:** `docs/superpowers/specs/2026-06-24-dev-standards-enterprise-phase1-design.md` (commit `929e329`).

## Global Constraints

- **Scope:** Phase 1 only. Do not modify `skills/`, `hooks/`, or `templates/`. Do not create the Plugin manifest.
- **Authoring language:** Chinese for prose (matches existing `principles.md` / `monorepo.md`); English for code, frontmatter, paths, and tool names.
- **Frontmatter (baselines/ files only):** every file in `playbook/baselines/` MUST have YAML frontmatter with 6 fields — `baseline`, `upstream`, `upstream-version`, `status` (one of `adopted|adapted|observing|deprecated`), `deviation-count` (integer), `last-reviewed` (YYYY-MM-DD).
- **Completion rule for new files:** no `TODO` / `TBD` / `待定` in body; every "缺口" item must link to a specific ADR; must be linked from `playbook/INDEX.md`; must be referenced by ≥1 other file.
- **Commit cadence:** commit at the end of each task. Conventional Commits style: `docs:`, `feat:`, `chore:`, `fix:`.
- **Validation:** after each task, run `bash scripts/lint.sh` (when it exists) and fix every reported issue before committing the next task. Final acceptance = `bash scripts/sync.sh validate` exits 0.
- **Editor style:** match the existing files — section heading `## `, no trailing whitespace, files end with single newline.

---

## File Map

**Create (new):**
- `playbook/baselines/README.md` — how to read/write baseline mappings
- `playbook/baselines/twelve-factor.md` — 12-Factor 映射
- `playbook/baselines/cncf-tag-app-delivery.md` — CNCF TAG 映射
- `playbook/api-error-codes.md` — API 错误响应约定
- `playbook/ci-minimum-gate.md` — CI 最低门槛
- `playbook/adr/0003-12-factor-adaptation.md` — 12-Factor 适配决策
- `playbook/adr/0004-cncf-tag-app-delivery-adoption.md` — CNCF TAG 采用决策
- `playbook/adr/0005-api-error-code-convention.md` — 错误码约定决策
- `playbook/adr/0006-ci-minimum-gate.md` — CI 门槛决策
- `scripts/lint.sh` — 串联 markdownlint + 链接 + TODO 扫描 + 孤儿检测
- `scripts/adr-validate.sh` — ADR frontmatter / 必填字段校验
- `scripts/baselines-validate.sh` — baselines/ frontmatter + 过期扫描

**Modify:**
- `playbook/principles.md` — 清 "待补充" 2 项、保留 1 项并标延后、加 baselines 指针
- `playbook/INDEX.md` — 加 baselines 段、4 篇新 ADR 链接、2 个新主题链接
- `README.md` — 目录结构图更新、加 baselines 段
- `CLAUDE.md` — 加基线引用一行
- `adapters/cursor/core-principles.mdc` — 底部加指针
- `scripts/sync.sh` — 加 `validate` 子命令

**Untouched (Phase 1):**
- `playbook/monorepo.md`, `adapters/cursor/monorepo.mdc`, `skills/`, `hooks/`, `templates/`, existing ADR 0001/0002, `playbook/adr/0001-*.md`, `playbook/adr/0002-*.md`

---

## Task 1: Validation scripts (lint + adr + baselines)

**Files:**
- Create: `scripts/adr-validate.sh`
- Create: `scripts/baselines-validate.sh`
- Create: `scripts/lint.sh`

**Goal:** Build the validation scripts before writing any content, so every later task is automatically checked as it's written. Each script exits 0 on success, 1 on any violation, and prints each issue to stdout with a `file:line` prefix.

**Interfaces (consumed by later tasks):**
- `scripts/sync.sh validate` (Task 2) calls all three
- `scripts/lint.sh` calls markdownlint if installed (best-effort, not required)
- ADR frontmatter contract: 6 fields listed in Global Constraints
- Baseline frontmatter contract: same 6 fields plus the `status` enum

- [ ] **Step 1: Write `scripts/adr-validate.sh`**

```bash
#!/usr/bin/env bash
# Validate playbook/adr/*.md: file name pattern + frontmatter completeness.
# Exits 0 if all ADRs are well-formed, 1 otherwise.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADR_DIR="$ROOT/playbook/adr"
errors=0
required=(ID Title Status Date Deciders)

if [[ ! -d "$ADR_DIR" ]]; then
  echo "adr-validate: $ADR_DIR not found" >&2
  exit 0  # no adrs yet is fine
fi

for f in "$ADR_DIR"/*.md; do
  [[ -f "$f" ]] || continue
  base="$(basename "$f")"
  # 1. Filename pattern: NNNN-kebab-case.md
  if ! [[ "$base" =~ ^[0-9]{4}-[a-z0-9-]+\.md$ ]]; then
    echo "$f:1: filename must match NNNN-kebab-case.md (got: $base)" >&2
    errors=$((errors+1))
  fi
  # 2. Frontmatter exists
  if ! head -1 "$f" | grep -q '^---$'; then
    echo "$f:1: missing YAML frontmatter (first line must be ---)" >&2
    errors=$((errors+1))
    continue
  fi
  # 3. Required fields
  for field in "${required[@]}"; do
    if ! grep -qE "^$field:" "$f"; then
      echo "$f: missing required frontmatter field: $field" >&2
      errors=$((errors+1))
    fi
  done
done

if [[ $errors -gt 0 ]]; then
  echo "adr-validate: $errors error(s)" >&2
  exit 1
fi
echo "adr-validate: ok"
```

- [ ] **Step 2: Make `adr-validate.sh` executable and run against existing ADRs (sanity check)**

```bash
chmod +x scripts/adr-validate.sh
bash scripts/adr-validate.sh
```

Expected: prints `adr-validate: ok` and exits 0. (Existing 0001 / 0002 ADRs satisfy the filename pattern but **do not** have all 6 frontmatter fields — verify, and if they fail the check, **fix them as part of this task**, not later.)

- [ ] **Step 3: If 0001 / 0002 ADRs fail, add the missing frontmatter**

Read each of `playbook/adr/0001-standards-repo-structure.md` and `playbook/adr/0002-monorepo-default-selection.md`. If any required field is missing, prepend the frontmatter block:

```markdown
---
ID: 0001
Title: 标准库仓库结构与 Claude Code 对齐
Status: Accepted
Date: 2026-06-21
Deciders: xingxiaolin
---
```

Adjust `ID`, `Title`, `Date` (use the git log date or file mtime) to match. Re-run `bash scripts/adr-validate.sh` until clean.

- [ ] **Step 4: Write `scripts/baselines-validate.sh`**

```bash
#!/usr/bin/env bash
# Validate playbook/baselines/*.md frontmatter + flag stale (>30 days since last-reviewed).
# Exits 0 if all baselines are well-formed and fresh, 1 otherwise.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_DIR="$ROOT/playbook/baselines"
errors=0
required=(baseline upstream upstream-version status deviation-count last-reviewed)
allowed_status=(adopted adapted observing deprecated)
stale_days="${BASELINE_STALE_DAYS:-30}"
stale=()

if [[ ! -d "$BASE_DIR" ]]; then
  echo "baselines-validate: $BASE_DIR not found (skipping)" >&2
  exit 0
fi

# Today as epoch day (UTC); for last-reviewed comparison
today_epoch="$(date -u +%s)"

for f in "$BASE_DIR"/*.md; do
  [[ -f "$f" ]] || continue
  base="$(basename "$f")"
  # README.md is documentation, not a baseline mapping
  [[ "$base" == "README.md" ]] && continue

  if ! head -1 "$f" | grep -q '^---$'; then
    echo "$f:1: missing YAML frontmatter" >&2
    errors=$((errors+1))
    continue
  fi

  for field in "${required[@]}"; do
    if ! grep -qE "^$field:" "$f"; then
      echo "$f: missing required frontmatter field: $field" >&2
      errors=$((errors+1))
    fi
  done

  # status must be one of allowed values
  status="$(grep -E '^status:' "$f" | head -1 | sed -E 's/^status:[[:space:]]*//' | awk '{print $1}')"
  if [[ -n "$status" ]]; then
    ok=0
    for s in "${allowed_status[@]}"; do
      [[ "$status" == "$s" ]] && ok=1
    done
    if [[ $ok -eq 0 ]]; then
      echo "$f: status '$status' not in: ${allowed_status[*]}" >&2
      errors=$((errors+1))
    fi
  fi

  # last-reviewed staleness
  lr="$(grep -E '^last-reviewed:' "$f" | head -1 | sed -E 's/^last-reviewed:[[:space:]]*//' | tr -d '[:space:]')"
  if [[ -n "$lr" ]] && [[ "$lr" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    lr_epoch="$(date -u -d "$lr" +%s 2>/dev/null || echo 0)"
    if [[ $lr_epoch -gt 0 ]]; then
      age_days=$(( (today_epoch - lr_epoch) / 86400 ))
      if [[ $age_days -gt $stale_days ]]; then
        stale+=("$f ($age_days days)")
      fi
    fi
  fi
done

if [[ ${#stale[@]} -gt 0 ]]; then
  echo "baselines-validate: STALE (>$stale_days days):" >&2
  for s in "${stale[@]}"; do echo "  $s" >&2; done
  # staleness is a warning, not error, until Phase 1 ends
  echo "baselines-validate: ok (with stale warnings)"
  exit 0
fi

if [[ $errors -gt 0 ]]; then
  echo "baselines-validate: $errors error(s)" >&2
  exit 1
fi
echo "baselines-validate: ok"
```

- [ ] **Step 5: Make `baselines-validate.sh` executable; run it**

```bash
chmod +x scripts/baselines-validate.sh
bash scripts/baselines-validate.sh
```

Expected: prints `baselines-validate: $BASE_DIR not found (skipping)` and exits 0 (the directory is created in a later task).

- [ ] **Step 6: Write `scripts/lint.sh`**

```bash
#!/usr/bin/env bash
# Aggregate lint: markdownlint (if installed) + internal link check + TODO scan + orphan detection.
# Exits 0 only when all checks pass.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
errors=0

# 1. markdownlint (optional)
if command -v pnpm >/dev/null 2>&1; then
  echo "lint: running markdownlint via pnpm dlx"
  if ! (cd "$ROOT" && pnpm dlx markdownlint-cli@0.45.0 '**/*.md' \
        --ignore node_modules 2>&1 | tee /tmp/mdl.out); then
    if grep -qE "ERR|error" /tmp/mdl.out 2>/dev/null; then
      errors=$((errors+1))
    fi
  fi
elif command -v markdownlint >/dev/null 2>&1; then
  echo "lint: running markdownlint"
  if ! markdownlint '**/*.md' --ignore node_modules; then
    errors=$((errors+1))
  fi
else
  echo "lint: markdownlint not installed (skipping; install with: pnpm add -D markdownlint-cli)"
fi

# 2. TODO / TBD / 待定 scan
echo "lint: scanning for TODO / TBD / 待定"
todo_hits="$(grep -rnE '(TODO|TBD|待定)' "$ROOT" --include='*.md' \
             --exclude-dir=node_modules --exclude-dir=.git || true)"
if [[ -n "$todo_hits" ]]; then
  # Whitelist: this very file mentions TODO/TBD in its own comments and the spec says it's ok
  todo_hits="$(echo "$todo_hits" | grep -v '^scripts/lint.sh:' || true)"
  if [[ -n "$todo_hits" ]]; then
    echo "$todo_hits" >&2
    echo "lint: TODO/TBD/待定 hits above" >&2
    errors=$((errors+1))
  fi
fi

# 3. Internal link check: every .md reference like ](path.md) must resolve
echo "lint: checking internal .md links"
link_errors=0
while IFS= read -r match; do
  file="$(echo "$match" | cut -d: -f1)"
  target="$(echo "$match" | sed -E 's/.*\]\(([^)]+)\).*/\1/' | sed 's/#.*//')"
  [[ -z "$target" ]] && continue
  [[ "$target" =~ ^https?:// ]] && continue
  [[ "$target" =~ ^mailto: ]] && continue
  base_dir="$(dirname "$file")"
  resolved="$base_dir/$target"
  if [[ ! -e "$resolved" ]]; then
    echo "$file: broken internal link → $target" >&2
    link_errors=$((link_errors+1))
  fi
done < <(grep -rEn '\]\([^)]+\.md' "$ROOT" --include='*.md' \
         --exclude-dir=node_modules --exclude-dir=.git || true)
if [[ $link_errors -gt 0 ]]; then
  echo "lint: $link_errors broken internal link(s)" >&2
  errors=$((errors+1))
fi

# 4. Orphan detection: .md files in playbook/ not linked from INDEX.md
echo "lint: checking for orphan playbook/ files"
orphans=0
for f in "$ROOT"/playbook/*.md; do
  [[ -f "$f" ]] || continue
  base="$(basename "$f")"
  [[ "$base" == "INDEX.md" ]] && continue
  if ! grep -q "$base" "$ROOT/playbook/INDEX.md"; then
    echo "playbook/ orphan: $base not referenced in INDEX.md" >&2
    orphans=$((orphans+1))
  fi
done
if [[ $orphans -gt 0 ]]; then
  echo "lint: $orphans orphan file(s) in playbook/" >&2
  errors=$((errors+1))
fi

if [[ $errors -gt 0 ]]; then
  echo "lint: FAIL ($errors issue groups)" >&2
  exit 1
fi
echo "lint: ok"
```

- [ ] **Step 7: Make `lint.sh` executable; run it**

```bash
chmod +x scripts/lint.sh
bash scripts/lint.sh
```

Expected: prints `lint: ok`. (`markdownlint` line prints the install-skip message; TODO scan finds nothing; link check finds nothing; orphan check finds none because the only playbook file is `monorepo.md` which is already in INDEX.)

- [ ] **Step 8: Commit**

```bash
git add scripts/adr-validate.sh scripts/baselines-validate.sh scripts/lint.sh
# also add any modified 0001/0002 ADR
git add playbook/adr/0001-standards-repo-structure.md playbook/adr/0002-monorepo-default-selection.md 2>/dev/null || true
git commit -m "feat(scripts): add adr/baselines/lint validators"
```

---

## Task 2: Wire `sync.sh validate` subcommand

**Files:**
- Modify: `scripts/sync.sh:103-112` (replace `cmd_all` body to call validate first), add `validate` case in main

**Interfaces (consumed by Task 6 final acceptance):**
- `bash scripts/sync.sh validate` exits 0 when all three scripts pass; non-zero otherwise.

- [ ] **Step 1: Add a `cmd_validate()` function above `main()` in `scripts/sync.sh`**

Insert immediately after the `cmd_all()` function (around line 112), before `main()`:

```bash
cmd_validate() {
  local script failed=0
  for script in lint.sh adr-validate.sh baselines-validate.sh; do
    if [[ -x "$ROOT/scripts/$script" ]]; then
      echo "→ $script"
      if ! bash "$ROOT/scripts/$script"; then
        failed=1
      fi
    else
      echo "warning: $ROOT/scripts/$script not found or not executable" >&2
    fi
  done
  return $failed
}
```

- [ ] **Step 2: Add `validate` case in `main()`**

In the `case "$cmd" in` block (around line 117), add a new branch:

```bash
    validate) cmd_validate ;;
```

Insert it before the `*)` error branch.

- [ ] **Step 3: Update `usage()` to advertise `validate`**

In the `usage()` heredoc (lines 9-27), add to the Commands list:

```
  validate            Run all validators (lint + adr + baselines)
```

- [ ] **Step 4: Run validate and confirm exit 0**

```bash
bash scripts/sync.sh validate
```

Expected: prints `lint: ok` / `adr-validate: ok` / `baselines-validate: ok` (or skip messages) and exits 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/sync.sh
git commit -m "feat(scripts): add sync.sh validate subcommand"
```

---

## Task 3: `playbook/baselines/README.md`

**Files:**
- Create: `playbook/baselines/README.md`

**Interfaces:**
- Linked from `playbook/INDEX.md` (Task 9) and `CLAUDE.md` (Task 11).
- Describes the **采用 / 落地 / 缺口** three-section template that Tasks 4 and 5 use.

- [ ] **Step 1: Create the directory**

```bash
mkdir -p playbook/baselines
```

- [ ] **Step 2: Write the file**

Create `playbook/baselines/README.md` with this content (Chinese prose matching the rest of the playbook):

```markdown
# 外部基线映射

> 本目录收录本仓**承认**的外部行业基线（CNCF TAG、12-Factor、OWASP 等），以及它们在本仓的"采用 / 落地 / 缺口"。

## 怎么读

每篇基线文件顶部是 YAML frontmatter，6 个字段：

| 字段 | 含义 |
|---|---|
| `baseline` | 基线名（如 `12-Factor App`） |
| `upstream` | 上游权威链接 |
| `upstream-version` | 上游版本号或"长期稳定" |
| `status` | `adopted`（直接采用）/ `adapted`（裁剪后采用）/ `observing`（仅观察）/ `deprecated`（弃用） |
| `deviation-count` | 本文件"缺口"段中链到的 ADR 数量（整型） |
| `last-reviewed` | 上次复核日期，格式 `YYYY-MM-DD` |

## 怎么改

1. **新增基线**：复制 `twelve-factor.md` 或 `cncf-tag-app-delivery.md` 作为骨架，按三段式填充；状态从 `observing` 起步，落地后再升 `adopted`/`adapted`。
2. **偏离基线**：在"缺口"段显式列出，写明理由；**必须**新建一篇 ADR 并在"缺口"段链上（ID + 标题），否则不算完成。
3. **基线变更**：上游公告或版本变化 → 评估影响 → 改 frontmatter / 缺口段；产出新 ADR。

## 与本仓其他文件的关系

| 文件 | 关系 |
|---|---|
| `../principles.md` | **正交**——principles 是 Agent/流程层；baselines 是行业基线层。冲突时由 ADR 仲裁。 |
| `../adr/` | baselines 的"缺口"段每条必须链到 ADR；ADR 引用 baselines 作为决策依据。 |
| `../../adapters/cursor/` | Cursor 规则**派生**自 principles + baselines；不允许反哺。 |
| `../../skills/` / `../../hooks/` | 流程层只**引用** baselines 链接，不复制内容。 |

## 复用模板（每条基线项的三段式）

```markdown
### [编号 / 标题]

**采用**：原文一条（或简短摘录）。

**落地**：本仓已用什么约定承接（链到 `playbook/<file>.md` 或 `principles.md §N`）。

**缺口 / ADR**：
- 偏离合规的地方 → ADR-NNNN（标题）
- 待 Phase N 实现的项 → [Phase N 计划链接]
```
```

- [ ] **Step 3: Run lint**

```bash
bash scripts/sync.sh validate
```

Expected: passes (no broken links introduced; the only `.md` link is the relative one which is fine because `principles.md` exists).

- [ ] **Step 4: Commit**

```bash
git add playbook/baselines/README.md
git commit -m "docs(baselines): add baselines/README.md with three-section template"
```

---

## Task 4: 12-Factor baseline + ADR-0003

**Files:**
- Create: `playbook/baselines/twelve-factor.md`
- Create: `playbook/adr/0003-12-factor-adaptation.md`

**Interfaces:**
- `twelve-factor.md` references ADR-0003 in the "缺口"段.
- ADR-0003 status `Accepted`; all 6 frontmatter fields present.

- [ ] **Step 1: Read the upstream**

Use WebFetch on `https://12factor.net/` to grab the 12 factor titles. List them in order: Codebase / Dependencies / Config / Backing Services / Build, Release, Run / Processes / Port Binding / Concurrency / Disposability / Dev/Prod Parity / Logs / Admin Processes.

- [ ] **Step 2: Write `playbook/adr/0003-12-factor-adaptation.md`**

```markdown
---
ID: 0003
Title: 12-Factor 适配：solo dev 简化
Status: Accepted
Date: 2026-06-24
Deciders: xingxiaolin
---

## 背景

12-Factor 是面向云原生 12 要素应用的方法论。在 solo dev 跨项目场景下，全部按字面执行会引入不必要的复杂度（多 deploy 流水线、严格 backing services 解耦、强无状态进程约束等）。

本 ADR 决定本仓对 12 条因子的"按字面 / 简化 / 不适用"立场。

## 决策

| Factor | 立场 | 理由 |
|---|---|---|
| I. Codebase | 按字面 | 一个 repo 一个应用是默认。monorepo 多 app 场景见 monorepo.md。 |
| II. Dependencies | 按字面 | 显式依赖声明（pyproject.toml / package.json）+ 锁文件。 |
| III. Config | 按字面 | 走环境变量，`.env.example` 文档化。 |
| IV. Backing Services | 简化 | 不强求"附加资源"解耦到 DB URL 字符串；本地 SQLite 与生产 Postgres 并存是允许的，但**必须**走环境变量切换。 |
| V. Build, Release, Run | 简化 | 必有 build 与 release；"run" 不强制严格分离（本地 `python -m` 直跑允许），但 release 产物必须可重放（lock 文件 + 镜像 tag）。 |
| VI. Processes | 按字面 | 无状态进程；session 用外部 store（Redis/DB）。 |
| VII. Port Binding | 按字面 | 自包含 HTTP server，不依赖外部 web 容器。 |
| VIII. Concurrency | 不适用 | solo dev 几乎不扩进程；遇到再启用（PM2 / gunicorn workers）。 |
| IX. Disposability | 简化 | 快速启动是底线（<3s 目标）；优雅关停**建议**但不强制——kill -9 兼容即可。 |
| X. Dev/Prod Parity | 简化 | "尽量相似"为原则；DB 类型差异允许（见 Factor IV），但**不**允许"dev 用 SQLite/prod 用 MySQL 但 schema 不同"。 |
| XI. Logs | 简化 | stdout + 文件双写；集中采集由 Phase 2 hooks 处理。**不**强制纯事件流。 |
| XII. Admin Processes | 按字面 | 一次性脚本走 `python -m app.admin` 或 `pnpm admin`，不嵌进 web 进程。 |

## 后果

- 本仓的 `playbook/baselines/twelve-factor.md` 据此落地。
- 任何后续偏离必须新增 ADR 链到本文件（这是 0004 / 0005 / 0006 的前导）。
```

- [ ] **Step 3: Write `playbook/baselines/twelve-factor.md`**

```markdown
---
baseline: 12-Factor App
upstream: https://12factor.net/
upstream-version: "1.0 (原始版本，长期稳定)"
status: adapted
deviation-count: 4
last-reviewed: 2026-06-24
---

> 本文件为 12-Factor 在本仓的"采用 / 落地 / 缺口"映射。**所有偏离必须显式链到 ADR**，且总体立场由 [ADR-0003](adr/0003-12-factor-adaptation.md) 决定。

## I. Codebase

**采用**：One codebase tracked in revision control, many deploys.

**落地**：默认单包（[principles.md §8](../principles.md)）；≥2 个可运行产物时升 monorepo（[monorepo.md](../monorepo.md)）。

**缺口 / ADR**：无。

## II. Dependencies

**采用**：Explicitly declare and isolate dependencies.

**落地**：显式依赖声明（pyproject.toml / package.json）+ 锁文件（uv.lock / pnpm-lock.yaml）；详见 [monorepo.md](../monorepo.md) 包边界规则。

**缺口 / ADR**：无。

## III. Config

**采用**：Store config in the environment.

**落地**：[principles.md §5](../principles.md) 已定义；`.env.example` 文档化变量名（已落实）。

**缺口 / ADR**：无。

## IV. Backing Services

**采用**：Treat backing services as attached resources.

**落地**：DB / cache / queue URL 走环境变量。**允许**本地 SQLite 与生产 Postgres 并存（schema 相同前提下）；见 [ADR-0003](adr/0003-12-factor-adaptation.md)。

**缺口 / ADR**：
- "schema 相同"在多 DB 引擎下的强校验 → 待 Phase 2 加 CI 检查。

## V. Build, Release, Run

**采用**：Strict separation between build, release, and run stages.

**落地**：build = 锁文件 + 镜像构建；release = tag + 环境配置注入；run = 进程启动。详见 [ADR-0003](adr/0003-12-factor-adaptation.md)；CI 最低门槛见 [ci-minimum-gate.md](../ci-minimum-gate.md)。

**缺口 / ADR**：[ADR-0006](adr/0006-ci-minimum-gate.md) 决定 CI 必选项。

## VI. Processes

**采用**：Execute the app as one or more stateless processes.

**落地**：进程不持有 session 状态；session 走外部 store。

**缺口 / ADR**：无。

## VII. Port Binding

**采用**：Export services via port binding.

**落地**：FastAPI / Node HTTP server 自包含，不依赖外部 web 容器（[monorepo.md](../monorepo.md) Python 应用部分）。

**缺口 / ADR**：无。

## VIII. Concurrency

**采用**：Scale out via the process model.

**落地**：[ADR-0003](adr/0003-12-factor-adaptation.md) 标"不适用"；遇多 worker 场景再启用（gunicorn -w N / PM2）。

**缺口 / ADR**：[ADR-0003](adr/0003-12-factor-adaptation.md)。

## IX. Disposability

**采用**：Maximize robustness with fast startup and graceful shutdown.

**落地**：<3s 启动目标；kill -9 兼容是底线；优雅关停**建议**非强制（[ADR-0003](adr/0003-12-factor-adaptation.md)）。

**缺口 / ADR**：[ADR-0003](adr/0003-12-factor-adaptation.md)。

## X. Dev/Prod Parity

**采用**：Keep development, staging, and production as similar as possible.

**落地**：DB 类型差异**允许**（本地 SQLite、生产 Postgres），schema 必须一致；"dev/prod schema 不同"禁止（[ADR-0003](adr/0003-12-factor-adaptation.md)）。

**缺口 / ADR**：
- "schema 一致"的强校验（alembic / prisma migrate）→ 待 Phase 2 加 CI 步骤。

## XI. Logs

**采用**：Treat logs as event streams.

**落地**：stdout + 文件双写；traceId 必填（见 [api-error-codes.md](../api-error-codes.md)）；集中采集由 Phase 2 hooks 处理。

**缺口 / ADR**：
- 集中采集 / ELK 接入 → Phase 2。

## XII. Admin Processes

**采用**：Run admin/management tasks as one-off processes.

**落地**：`python -m app.admin` 或 `pnpm admin`；不嵌进 web 进程。

**缺口 / ADR**：无。
```

- [ ] **Step 4: Run validate**

```bash
bash scripts/sync.sh validate
```

Expected: passes. The orphan check in `lint.sh` looks at `playbook/*.md` (top level), not `playbook/baselines/`, so the new files don't trigger the orphan rule. The baselines-validate script reads each file and checks the 6 fields and `status` enum — both should pass.

- [ ] **Step 5: Commit**

```bash
git add playbook/baselines/twelve-factor.md playbook/adr/0003-12-factor-adaptation.md
git commit -m "docs(baselines): add 12-Factor mapping and ADR-0003 adaptation"
```

---

## Task 5: CNCF TAG App Delivery baseline + ADR-0004

**Files:**
- Create: `playbook/baselines/cncf-tag-app-delivery.md`
- Create: `playbook/adr/0004-cncf-tag-app-delivery-adoption.md`

**Interfaces:**
- `cncf-tag-app-delivery.md` references ADR-0004 in the "缺口"段.
- ADR-0004 status `Accepted`.

- [ ] **Step 1: Read the upstream**

Use WebFetch on `https://github.com/cncf/toc/blob/main/tags/app-delivery.md` (or the CNCF TAG landing if URL moved) to confirm the 5 subdomains: CI/CD, Continuous Delivery, GitOps, Progressive Delivery, Observability. Note: do not copy the page text verbatim — only the structure and 2-3 keywords per subdomain.

- [ ] **Step 2: Write `playbook/adr/0004-cncf-tag-app-delivery-adoption.md`**

```markdown
---
ID: 0004
Title: CNCF TAG App Delivery 采用范围
Status: Accepted
Date: 2026-06-24
Deciders: xingxiaolin
---

## 背景

CNCF TAG App Delivery 包含 5 个子域：CI/CD、Continuous Delivery、GitOps、Progressive Delivery、Observability。在 solo dev 场景下全部深入投入不现实。

本 ADR 决定本仓对 5 个子域的"采用 / 观察 / 不采用"立场。

## 决策

| 子域 | 立场 | 理由 |
|---|---|---|
| CI/CD | 采用（浅） | lint + test + secret scan 必走（见 [ADR-0006](0006-ci-minimum-gate.md)）；多 runner / 复杂 pipeline 不引入。 |
| Continuous Delivery | 观察 | 当前无 CD 流水线；走手动 release tag + 镜像构建。出现第 2 个生产项目时再升"采用"。 |
| GitOps | 不采用 | solo dev 单环境运行；Argo CD / Flux 投入产出比不划算。 |
| Progressive Delivery | 不采用 | 无多版本路由需求（canary / blue-green）；出现第 2 个线上用户项目时再评估。 |
| Observability | 采用（浅） | 结构化日志 + traceId 是底线（[ADR-0005](0005-api-error-code-convention.md)）；metrics / tracing 集中化推到 Phase 2。 |

## 后果

- `playbook/baselines/cncf-tag-app-delivery.md` 据此落地。
- Continuous Delivery / GitOps / Progressive Delivery 三个子域若未来被采用，必须新开 ADR 链接到本文件。
- 前端/小程序目录约定（principles.md 待补项 2）不在本基线覆盖范围；显式延后到"出现第 2 个前端项目"时启动。
```

- [ ] **Step 3: Write `playbook/baselines/cncf-tag-app-delivery.md`**

```markdown
---
baseline: CNCF TAG App Delivery
upstream: https://github.com/cncf/toc/blob/main/tags/app-delivery.md
upstream-version: "current (无版本号，跟踪 toc 仓库 main 分支)"
status: adapted
deviation-count: 1
last-reviewed: 2026-06-24
---

> 本文件为 CNCF TAG App Delivery 在本仓的"采用 / 落地 / 缺口"映射。总体立场由 [ADR-0004](adr/0004-cncf-tag-app-delivery-adoption.md) 决定。
>
> 与 [12-Factor XI. Logs](../baselines/twelve-factor.md) 重叠时，observability 段以本文件为准，logs 段以 12-Factor 为准。

## CI/CD

**采用**：任何合入主干的代码必须经过自动化 build/test 流水线；流水线产物可复现。

**落地**：[ci-minimum-gate.md](../ci-minimum-gate.md) 定义最低门槛（lint / typecheck-or-test / secret scan）；等价物表允许不同工具栈。

**缺口 / ADR**：[ADR-0006](adr/0006-ci-minimum-gate.md)。

## Continuous Delivery

**采用**：流水线产出的 artifact 可一键部署到任意环境；部署自动化、可审计。

**落地**：当前**无**自动 CD；走 `git tag vX.Y.Z` + 手动触发部署（[monorepo.md](../monorepo.md) §版本与发布）。

**缺口 / ADR**：
- 自动 CD 流水线 → 出现第 2 个生产项目时启动（[ADR-0004](adr/0004-cncf-tag-app-delivery-adoption.md)）。

## GitOps

**采用**：环境配置以 Git 为唯一真相；环境差异 = Git 仓库差异。

**落地**：当前**无**；配置走环境变量 + `.env.example`（[principles.md §5](../principles.md)），不引入 Argo CD / Flux。

**缺口 / ADR**：[ADR-0004](adr/0004-cncf-tag-app-delivery-adoption.md) 决定不采用。

## Progressive Delivery

**采用**：新版本以受控方式（金丝雀 / 蓝绿 / 特性开关）逐步放量。

**落地**：当前**无**；单版本直发。

**缺口 / ADR**：[ADR-0004](adr/0004-cncf-tag-app-delivery-adoption.md) 决定不采用；触发条件 = 出现第 2 个线上用户项目。

## Observability

**采用**：应用行为可被外部系统观测（metrics / logs / traces）。

**落地**：结构化日志（JSON 行）+ traceId 必填（[api-error-codes.md](../api-error-codes.md)）；指标与链路追踪集中化推到 Phase 2。

**缺口 / ADR**：
- metrics / tracing 集中化（Prometheus / OpenTelemetry）→ Phase 2。
```

- [ ] **Step 4: Run validate**

```bash
bash scripts/sync.sh validate
```

Expected: passes.

- [ ] **Step 5: Commit**

```bash
git add playbook/baselines/cncf-tag-app-delivery.md playbook/adr/0004-cncf-tag-app-delivery-adoption.md
git commit -m "docs(baselines): add CNCF TAG App Delivery mapping and ADR-0004 adoption"
```

---

## Task 6: API error codes topic + ADR-0005

**Files:**
- Create: `playbook/api-error-codes.md`
- Create: `playbook/adr/0005-api-error-code-convention.md`

**Interfaces:**
- Referenced by `playbook/baselines/twelve-factor.md` §XI (already done in Task 4) and `playbook/baselines/cncf-tag-app-delivery.md` §Observability.
- Will be referenced from `playbook/INDEX.md` (Task 9).

- [ ] **Step 1: Write `playbook/adr/0005-api-error-code-convention.md`**

```markdown
---
ID: 0005
Title: API 错误码与 HTTP 状态约定
Status: Accepted
Date: 2026-06-24
Deciders: xingxiaolin
---

## 背景

跨项目 API 错误响应此前无统一约定。本 ADR 决定错误响应体 schema、HTTP 状态码语义、业务错误码分层。

## 决策

### 错误响应体 schema

```json
{
  "code": "AUTH_INVALID_TOKEN",
  "message": "token 已过期或无效",
  "details": { "reason": "expired" },
  "traceId": "01HXY..."
}
```

| 字段 | 必填 | 含义 |
|---|---|---|
| `code` | 是 | 业务错误码（见下） |
| `message` | 是 | 用户可读的中文/英文提示 |
| `details` | 否 | 结构化补充信息（如校验失败的具体字段） |
| `traceId` | 是 | 与日志关联的请求 ID（用于客服 / 排障） |

### HTTP 状态码语义

| 范围 | 语义 |
|---|---|
| 4xx | 客户端错误（请求格式 / 鉴权 / 业务规则不满足） |
| 5xx | 服务端错误（实现 bug / 依赖故障 / 资源耗尽） |

`code` 与 HTTP 状态码**正交**：HTTP 表达"哪一类失败"，`code` 表达"具体原因"。

### 业务错误码分层

| 前缀 | 含义 | HTTP 状态 |
|---|---|---|
| `AUTH_*` | 鉴权 / 权限 | 401 / 403 |
| `VAL_*` | 参数校验 | 400 / 422 |
| `BIZ_*` | 业务规则 | 400 / 409 / 422 |
| `SYS_*` | 系统 / 依赖 | 500 / 502 / 503 / 504 |

错误码大写、下划线分隔；枚举值集中在 `packages/shared/errors`（monorepo 项目）或 `app/errors.py`（单包项目），**禁止**散落。

## 后果

- `playbook/api-error-codes.md` 据此落地。
- 任何新错误码必须先在枚举文件中定义，**禁止**直接硬编码字符串。
- traceId 与 logging 系统的关联实现由 Phase 2 hooks 处理。
```

- [ ] **Step 2: Write `playbook/api-error-codes.md`**

```markdown
# API 错误码与 HTTP 状态约定

> 决策见 [ADR-0005](adr/0005-api-error-code-convention.md)。本文是"怎么用"。

## 错误响应体

任何非 2xx 响应必须返回 JSON 体：

```json
{
  "code": "AUTH_INVALID_TOKEN",
  "message": "token 已过期或无效",
  "details": { "reason": "expired" },
  "traceId": "01HXY..."
}
```

字段说明见 ADR-0005 §错误响应体 schema。

## HTTP 状态码

| 状态 | 含义 | 典型场景 |
|---|---|---|
| 400 | 请求格式错误 | JSON 解析失败、必填字段缺失 |
| 401 | 未认证 | token 缺失或无效 |
| 403 | 已认证但无权限 | 角色不足 |
| 404 | 资源不存在 | 路径或 ID 不存在 |
| 409 | 资源冲突 | 重复创建、版本冲突 |
| 422 | 语义错误 | 参数格式正确但值不合法 |
| 500 | 内部错误 | 未捕获异常 |
| 502/503/504 | 上下游故障 | DB / 缓存 / 第三方不可用 |

## 业务错误码

| 前缀 | 含义 |
|---|---|
| `AUTH_*` | 鉴权 / 权限 |
| `VAL_*` | 参数校验 |
| `BIZ_*` | 业务规则 |
| `SYS_*` | 系统 / 依赖 |

示例（来自 ADR-0005 决策）：

| code | HTTP | 含义 |
|---|---|---|
| `AUTH_INVALID_TOKEN` | 401 | token 无效或过期 |
| `AUTH_FORBIDDEN` | 403 | 角色不足 |
| `VAL_REQUIRED_FIELD` | 400 | 必填字段缺失 |
| `VAL_INVALID_FORMAT` | 422 | 格式不合法 |
| `BIZ_DUPLICATE` | 409 | 资源已存在 |
| `BIZ_STATE_CONFLICT` | 409 | 状态机不匹配 |
| `SYS_DB_UNAVAILABLE` | 503 | 数据库不可用 |
| `SYS_UPSTREAM_TIMEOUT` | 504 | 上游超时 |

## 实现位置

- **monorepo 项目**：枚举集中在 `packages/shared/errors/`；每个错误一个文件，导出一个 `class` 或 `const`。
- **单包项目**：集中在 `app/errors.py` 或同等位置。
- **禁止**：在 controller / handler 里直接写字符串字面量。

## traceId

`traceId` 是请求进入系统时生成的唯一 ID（推荐 ULID / UUIDv7），必须：

- 出现在错误响应体
- 出现在所有该请求产生的日志条目
- 出现在所有对外 HTTP 调用的 `X-Trace-Id` header
- 由 middleware / interceptor 在请求入口生成

## 客户端处理建议

- 优先用 `code` 字段判断错误类型（**不要** 解析 `message` 文本）
- 用户提示用 `message`
- 客服/排障用 `traceId`
```

- [ ] **Step 3: Run validate**

```bash
bash scripts/sync.sh validate
```

Expected: passes. The orphan check will **flag** `playbook/api-error-codes.md` as not referenced in `playbook/INDEX.md` — this is the expected intermediate state, fix in Task 9. To avoid commit-time lint failure: temporarily add the link, or accept the lint error, commit, fix in Task 9. **Easier path**: add the entry to `playbook/INDEX.md` now in this task, even though Task 9 is the formal "update INDEX" task.

- [ ] **Step 4: Add the new file to `playbook/INDEX.md` (interim)**

Open `playbook/INDEX.md` and add a new section after the "Monorepo 实践指南" link:

```markdown
## 主题（跨项目技术约定）

- [API 错误码与 HTTP 状态约定](api-error-codes.md)
```

- [ ] **Step 5: Re-run validate**

```bash
bash scripts/sync.sh validate
```

Expected: passes (orphan gone, no broken links).

- [ ] **Step 6: Commit**

```bash
git add playbook/adr/0005-api-error-code-convention.md playbook/api-error-codes.md playbook/INDEX.md
git commit -m "docs(playbook): add API error codes convention and ADR-0005"
```

---

## Task 7: CI minimum gate topic + ADR-0006

**Files:**
- Create: `playbook/ci-minimum-gate.md`
- Create: `playbook/adr/0006-ci-minimum-gate.md`
- Modify: `playbook/INDEX.md` (add link to the new file)

**Interfaces:**
- Referenced by `playbook/baselines/twelve-factor.md` §V and `playbook/baselines/cncf-tag-app-delivery.md` §CI/CD.

- [ ] **Step 1: Write `playbook/adr/0006-ci-minimum-gate.md`**

```markdown
---
ID: 0006
Title: CI 最低门槛
Status: Accepted
Date: 2026-06-24
Deciders: xingxiaolin
---

## 背景

CNCF TAG "CI/CD" 与 12-Factor V 都要求"任何合入都过流水线"。在 solo dev 场景下，完整 CI 平台（GitHub Actions 复杂 workflow / Jenkins / GitLab CI 高级功能）不必要；但**最低**门槛必须定义并强制。

本 ADR 决定 CI 必选项与可选项。

## 决策

### 必选项（3 项）

1. **lint** — 静态检查（代码风格 + 潜在 bug）
2. **typecheck or test** — TypeScript 走 `tsc --noEmit`；Python 走 `mypy` 或 `pytest`；Go 走 `go vet` + `go test`
3. **secret scan** — 防止密钥入库

### 可选项（4 项）

4. test — 完整测试套件
5. build — 编译 / 打包 / 镜像构建
6. dep audit — 依赖漏洞扫描（`pip-audit` / `pnpm audit` / `npm audit`）
7. sbom — 软件物料清单生成

### 工具等价物表（必选项）

| 类别 | 备选 |
|---|---|
| lint (Python) | ruff / flake8 / pylint |
| lint (TS) | eslint / biome |
| lint (Go) | golangci-lint |
| typecheck (TS) | tsc --noEmit |
| typecheck (Python) | mypy / pyright |
| secret scan | gitleaks / trufflehog / detect-secrets |

**不**强制具体工具；项目自选但必须**至少一项**。

## 后果

- `playbook/ci-minimum-gate.md` 据此落地。
- 任何新项目 `dev-bootstrap` 时必须确保 3 项必选 CI 步骤（Phase 2 加 Skill 校验）。
- 等价物表是推荐而非强制；项目可用同类别其他工具。
```

- [ ] **Step 2: Write `playbook/ci-minimum-gate.md`**

```markdown
# CI 最低门槛

> 决策见 [ADR-0006](adr/0006-ci-minimum-gate.md)。本文是"怎么用"。

## 必选 3 项

任何合入主干的操作必须触发以下三项检查，**全部通过**才允许 merge：

### 1. Lint

- **目的**：风格统一 + 潜在 bug 捕获
- **触发**：pre-commit + CI
- **工具**：见 ADR-0006 §工具等价物表

### 2. Typecheck or Test

- **目的**：类型 / 行为正确性
- **触发**：CI
- **降级**：项目无类型系统时降级为 test 套件

### 3. Secret Scan

- **目的**：防止 API key / 私钥 / token 入库
- **触发**：pre-commit + CI
- **工具**：gitleaks（推荐）/ trufflehog / detect-secrets

## 可选 4 项

| 项 | 推荐触发 |
|---|---|
| test | CI（与 typecheck 并行） |
| build | CI（PR 阶段） |
| dep audit | CI（每日 / 每周） |
| sbom | release 时 |

## 流水线骨架（GitHub Actions 示例）

```yaml
name: ci
on: [push, pull_request]
jobs:
  gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4  # 或 setup-python / setup-go
        with: { ... }
      - run: <lint>          # 必选
      - run: <typecheck-or-test>  # 必选
      - run: <secret-scan>   # 必选
      - run: <test>          # 可选
      - run: <build>         # 可选
```

## 与 monorepo 的关系

- 根 `package.json` 的 `lint` / `typecheck` / `test` script 是上述命令的"编排入口"
- 各子包暴露等价 npm script，`pnpm -r lint` 可递归
- Python 子包（`apps/api`）的 `pytest` 由根 script 显式 `cd apps/api && ...` 触发

## 不在 CI 范围

- 端到端测试（Playwright / Cypress）→ 单独流水线
- 性能测试 → 单独流水线
- 部署 → 单独流水线（`Continuous Delivery` 子域）
```

- [ ] **Step 3: Add the new file to `playbook/INDEX.md`**

Open `playbook/INDEX.md`, after the `api-error-codes.md` entry you added in Task 6:

```markdown
- [CI 最低门槛](ci-minimum-gate.md)
```

- [ ] **Step 4: Run validate**

```bash
bash scripts/sync.sh validate
```

Expected: passes.

- [ ] **Step 5: Commit**

```bash
git add playbook/adr/0006-ci-minimum-gate.md playbook/ci-minimum-gate.md playbook/INDEX.md
git commit -m "docs(playbook): add CI minimum gate and ADR-0006"
```

---

## Task 8: Update `playbook/principles.md` (clear backlog)

**Files:**
- Modify: `playbook/principles.md` — replace the "待补充" section; add a pointer to `baselines/`.

**Interfaces:**
- The "待补充" section currently lists 3 items; this task removes 2 (now covered by Tasks 6 & 7) and explicitly defers 1.

- [ ] **Step 1: Read the current "待补充" section**

Open `playbook/principles.md` and locate the section at the bottom (around line 49-54):

```markdown
## 待补充（从项目中提取）

- [ ]  API 错误码与 HTTP 状态约定
- [ ]  前端/小程序目录约定
- [ ]  CI 最低门槛（lint / test / secret scan）
```

- [ ] **Step 2: Replace it with a "已落地的补全" section + a "延后" section**

Replace the entire "待补充" block with:

```markdown
## 已落地的补全

- API 错误码与 HTTP 状态约定 → 详见 [api-error-codes.md](api-error-codes.md) / [ADR-0005](adr/0005-api-error-code-convention.md)
- CI 最低门槛 → 详见 [ci-minimum-gate.md](ci-minimum-gate.md) / [ADR-0006](adr/0006-ci-minimum-gate.md)

## 显式延后

- **前端 / 小程序目录约定** — 不在本阶段覆盖。触发条件：出现第 2 个前端项目时启动。理由：单项目特例不上升为通用标准；见 [ADR-0004](adr/0004-cncf-tag-app-delivery-adoption.md) 末尾说明。

## 外部基线

行业基线对齐见 [baselines/](baselines/README.md)（CNCF TAG App Delivery、12-Factor）。冲突时按 [INDEX.md](INDEX.md) §ADR 仲裁顺序处理。
```

- [ ] **Step 3: Update the top-level note in `principles.md`**

Find the leading `>` blockquote (line 3):

```markdown
> 短、稳定、跨项目。真源就是本文；Cursor 写法派生见 `adapters/cursor/`（adapter 镜像），流程见 `skills/`。
```

Append to that line: ` 行业基线对齐见 [baselines/](baselines/README.md)；` 决策走 [ADR](adr/)。`

Final form:

```markdown
> 短、稳定、跨项目。真源就是本文；Cursor 写法派生见 `adapters/cursor/`（adapter 镜像），流程见 `skills/`。行业基线对齐见 [baselines/](baselines/README.md)；决策走 [ADR](adr/)。
```

- [ ] **Step 4: Run validate**

```bash
bash scripts/sync.sh validate
```

Expected: passes.

- [ ] **Step 5: Commit**

```bash
git add playbook/principles.md
git commit -m "docs(principles): clear backlog, defer frontend convention, add baselines pointer"
```

---

## Task 9: Update `playbook/INDEX.md` (full version)

**Files:**
- Modify: `playbook/INDEX.md` — full restructure: principles / topics / baselines / ADRs.

**Interfaces:**
- This is the **single source of truth** for what files exist; the orphan check in `lint.sh` reads from it.

- [ ] **Step 1: Read the current INDEX**

Open `playbook/INDEX.md` and confirm the current state. Note: the `api-error-codes.md` and `ci-minimum-gate.md` links added in Tasks 6/7 are partial; this task finalizes the full structure.

- [ ] **Step 2: Replace INDEX.md with the full version**

```markdown
# Playbook 索引

> 本目录是 `dev-standards` 文档的真源。ADR 是冲突仲裁的最高层。

## 原则（Agent / 流程层）

- [L1 开发原则](principles.md)
- [Monorepo 实践指南](monorepo.md)

## 主题（跨项目技术约定）

- [API 错误码与 HTTP 状态约定](api-error-codes.md)
- [CI 最低门槛](ci-minimum-gate.md)

## 外部基线（行业对位）

- [baselines/ 目录说明](baselines/README.md)
- [CNCF TAG App Delivery 映射](baselines/cncf-tag-app-delivery.md)
- [12-Factor 映射](baselines/twelve-factor.md)

## ADR（Architecture / Standard Decision Records）

仲裁顺序：principles ↔ baselines 冲突时，**ADR 优先**。详见 `baselines/README.md` §与本仓其他文件的关系。

| ID | 标题 | 状态 |
|----|------|------|
| [0001](adr/0001-standards-repo-structure.md) | 标准库仓库结构与 Claude Code 对齐 | Accepted |
| [0002](adr/0002-monorepo-default-selection.md) | Monorepo / 单包默认选型 | Accepted |
| [0003](adr/0003-12-factor-adaptation.md) | 12-Factor 适配：solo dev 简化 | Accepted |
| [0004](adr/0004-cncf-tag-app-delivery-adoption.md) | CNCF TAG App Delivery 采用范围 | Accepted |
| [0005](adr/0005-api-error-code-convention.md) | API 错误码与 HTTP 状态约定 | Accepted |
| [0006](adr/0006-ci-minimum-gate.md) | CI 最低门槛 | Accepted |

## Skills（一等公民，源码在 `../skills/`）

| Skill | 用途 |
|-------|------|
| dev-bootstrap | 新建或整理项目时的检查清单 |

## Hooks（一等公民，源码在 `../hooks/`）

PreToolUse 守卫模板（如提交前确认）。按项目部署，非全局强制。

## Adapters（派生镜像，源码在 `../adapters/`）

| Adapter | 用途 | 部署目标 |
|---------|------|----------|
| [cursor](../adapters/cursor/) | Cursor Rules（派生自 principles.md / monorepo.md） | `<project>/.cursor/rules/` |

## Templates（方案 C 预留，源码在 `../templates/`）

未来用于项目脚手架，当前为空。
```

- [ ] **Step 3: Run validate**

```bash
bash scripts/sync.sh validate
```

Expected: passes. The orphan check looks at `playbook/*.md` (not `playbook/baselines/*.md` or `playbook/adr/*.md`), so all 4 top-level playbook files (`principles.md`, `monorepo.md`, `api-error-codes.md`, `ci-minimum-gate.md`) are now referenced.

- [ ] **Step 4: Commit**

```bash
git add playbook/INDEX.md
git commit -m "docs(playbook): full restructure of INDEX with topics, baselines, and 4 new ADRs"
```

---

## Task 10: Update `README.md`

**Files:**
- Modify: `README.md` — directory structure diagram, baselines section, sedimentation flow step.

- [ ] **Step 1: Update the "目录结构" code block**

Find the `dev-standards/` directory tree in README.md (around lines 22-37). Replace it with:

```text
dev-standards/
├── CLAUDE.md              # Claude Code 入口（本仓库自用）
├── README.md              # 本文件
├── docs/
│   └── superpowers/       # 设计 spec / 实施 plan
├── playbook/
│   ├── principles.md      # L1 原则（Agent / 流程层）
│   ├── monorepo.md        # monorepo 实践
│   ├── api-error-codes.md # 跨项目 API 错误响应约定
│   ├── ci-minimum-gate.md # CI 必选 3 项 + 可选 4 项
│   ├── baselines/         # 外部行业基线映射（CNCF TAG / 12-Factor / …）
│   ├── INDEX.md           # 文档索引（含 ADR 仲裁顺序）
│   └── adr/               # 架构 / 标准决策记录
├── skills/                # Claude Code Skill 源码（一等公民）
│   └── dev-bootstrap/
├── hooks/                 # Claude hooks 模板（一等公民）
├── adapters/              # 非 Claude Code Agent 的兼容镜像
│   └── cursor/            # Cursor rules（派生自 playbook/）
├── scripts/               # 同步 / 校验脚本
│   ├── sync.sh            # 入口
│   ├── lint.sh            # markdownlint + 链接 + TODO + 孤儿
│   ├── adr-validate.sh    # ADR frontmatter
│   └── baselines-validate.sh  # baselines/ frontmatter + 过期
└── templates/             # 方案 C 预留
```

- [ ] **Step 2: Add a "外部基线" row to the "定位" table**

Find the table at the top (around lines 9-17). After the `Adapters` row, add:

```markdown
| 外部基线映射 | `playbook/baselines/` | 人读；principles / skills 引用 |
```

- [ ] **Step 3: Update the "沉淀流程" section**

Find the "沉淀流程" section (around lines 56-62). After step 5 ("迭代"), add a step 6:

```markdown
6. **基线月扫** — 每月跑 `bash scripts/sync.sh validate`；`last-reviewed` > 30 天的 baselines/ 文件要重读上游并复核
```

- [ ] **Step 4: Add a "## 外部基线" section before "## 与 Claude Code 的对应关系"**

```markdown
## 外部基线

行业基线对齐见 [`playbook/baselines/`](playbook/baselines/README.md)。当前覆盖：

- [CNCF TAG App Delivery](playbook/baselines/cncf-tag-app-delivery.md) — CI/CD、Continuous Delivery、GitOps、Progressive Delivery、Observability
- [12-Factor](playbook/baselines/twelve-factor.md) — Codebase / Dependencies / Config / …

新增基线流程见 `playbook/baselines/README.md` §怎么改。

```

- [ ] **Step 5: Run validate**

```bash
bash scripts/sync.sh validate
```

Expected: passes. (The internal link to `playbook/baselines/README.md` resolves; no broken links introduced.)

- [ ] **Step 6: Commit**

```bash
git add README.md
git commit -m "docs: update README with baselines section, directory tree, and validation step"
```

---

## Task 11: Update `CLAUDE.md` and `adapters/cursor/core-principles.mdc`

**Files:**
- Modify: `CLAUDE.md` — add one pointer line
- Modify: `adapters/cursor/core-principles.mdc` — add one pointer line

- [ ] **Step 1: Add a pointer to `CLAUDE.md`**

Open `CLAUDE.md`. After the "## 边界" section, add a new section before the final "## 首选 Skill" section:

```markdown
## 修改基线时

- 读 `playbook/baselines/README.md` §怎么改
- 任何偏离必须新建 ADR 并在"缺口"段链上
- 跑 `bash scripts/sync.sh validate` 确认 0 违例
```

- [ ] **Step 2: Add a pointer to `adapters/cursor/core-principles.mdc`**

Open the file. Append at the bottom (after the last existing line, on a new line):

```markdown
> 行业基线对齐见 `playbook/baselines/`；本文件为 Agent 流程层派生。
```

- [ ] **Step 3: Run validate**

```bash
bash scripts/sync.sh validate
```

Expected: passes. (The `.mdc` link `playbook/baselines/` is relative, resolves to the existing directory. The `CLAUDE.md` addition has no internal links to check.)

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md adapters/cursor/core-principles.mdc
git commit -m "docs: add baselines pointer to CLAUDE.md and cursor core principles"
```

---

## Task 12: Final acceptance — full validate + smoke test

**Files:**
- (no file changes; verification only)

**Goal:** Confirm all spec §6.2 acceptance criteria pass, and a downstream `sync.sh skills` works.

- [ ] **Step 1: Run full validate and capture output**

```bash
bash scripts/sync.sh validate 2>&1 | tee /tmp/phase1-validate.log
echo "exit: $?"
```

Expected: exit 0; output contains `lint: ok`, `adr-validate: ok`, `baselines-validate: ok`.

- [ ] **Step 2: Manual checklist verification**

Walk through spec §6.2 验收清单 and tick every box. The key checks:

```bash
# File completeness (9 new files)
for f in \
  playbook/baselines/README.md \
  playbook/baselines/twelve-factor.md \
  playbook/baselines/cncf-tag-app-delivery.md \
  playbook/api-error-codes.md \
  playbook/ci-minimum-gate.md \
  playbook/adr/0003-12-factor-adaptation.md \
  playbook/adr/0004-cncf-tag-app-delivery-adoption.md \
  playbook/adr/0005-api-error-code-convention.md \
  playbook/adr/0006-ci-minimum-gate.md; do
  [[ -f "$f" ]] && echo "OK: $f" || echo "MISSING: $f"
done
```

All 9 should print `OK:`.

- [ ] **Step 3: No TODO/TBD in body**

```bash
grep -rEn '(TODO|TBD|待定)' playbook/ --include='*.md' || echo "clean"
```

Expected: `clean` (no hits in playbook/ docs themselves; the spec references these strings as forbidden patterns, but the spec is in `docs/superpowers/specs/`, not `playbook/`).

- [ ] **Step 4: ADR count = 4 new, all Accepted**

```bash
for f in playbook/adr/000{3,4,5,6}-*.md; do
  status="$(grep -E '^Status:' "$f" | awk '{print $2}')"
  echo "$f → $status"
done
```

Expected: 4 lines, each `→ Accepted`.

- [ ] **Step 5: Sync smoke test (skills only — adapters/hooks are Phase 2)**

```bash
bash scripts/sync.sh skills
```

Expected: prints `synced: dev-bootstrap → ~/.claude/skills/dev-bootstrap/` and exits 0. (This validates the modified `sync.sh` still works after the `validate` subcommand was added.)

- [ ] **Step 6: Show final state**

```bash
git log --oneline -15
git status
```

Expected: clean working tree; ~12 commits since the initial `chore: initial scaffold of dev-standards`.

- [ ] **Step 7: Tag Phase 1 completion**

```bash
git tag phase-1-complete
git log --oneline -1
```

Expected: a `phase-1-complete` tag pointing at the latest commit.

- [ ] **Step 8: Final commit (no-op or summary)**

If everything is clean, there's nothing to commit. If you created any temp files (`/tmp/phase1-validate.log`), they are outside the repo and not tracked. Verify with `git status` — it should print "nothing to commit, working tree clean".

---

## Self-Review (post-write)

**Spec coverage check:**

- §1 背景与目标 → preamble of plan
- §2 In Scope (5 file categories) → Tasks 3-7 cover content; Task 8-11 cover modifications; Task 1-2 cover scripts
- §2 Out of Scope → explicitly excluded; Skills/Hooks/templates untouched
- §3.1 directory tree → reproduced in plan File Map
- §3.2 层级职责矩阵 → encoded in `baselines/README.md` (Task 3) and §consumed-by references
- §3.3 引用方向 → encoded in the "Interfaces" blocks and in the prose of each playbook file
- §4.1 baselines/README 三段式 → Task 3 content
- §4.2 twelve-factor.md → Task 4
- §4.3 cncf-tag-app-delivery.md → Task 5
- §4.4 4 ADRs → Tasks 4 (0003), 5 (0004), 6 (0005), 7 (0006)
- §4.5 api-error-codes.md → Task 6
- §4.6 ci-minimum-gate.md → Task 7
- §4.7 modifications → Tasks 8, 9, 10, 11
- §5.1 冲突仲裁 → encoded in INDEX.md and baselines/README
- §5.2 frontmatter → enforced by Task 1's `baselines-validate.sh` and Task 4/5 frontmatter
- §5.3 周期性维护 → encoded in README "沉淀流程" step 6
- §5.4 文件级完成判据 → enforced by validators (Tasks 1)
- §6.1 静态检查 → Tasks 1 & 2
- §6.2 验收清单 → Task 12

**Placeholder scan:** no `TBD` / `TODO` / "implement later" in any task. Step 5 in Task 4 says "Note: do not copy" — that's an instruction, not a placeholder.

**Type consistency:** the frontmatter contract (6 fields, `status` enum) is defined once in Task 1 and used identically in Tasks 4 and 5. The ADR contract (6 fields) is defined in Task 1 and used in Tasks 4, 5, 6, 7. The `sync.sh validate` subcommand is added in Task 2 and consumed in Tasks 3-12. No naming drift.

**One subtle point:** Task 6 Step 3 anticipates the orphan-check failure and resolves it inline (Step 4) by editing `playbook/INDEX.md` mid-task. This is intentional and documented — the alternative is committing a known-failing state. Task 9 then makes the same edit as part of the full INDEX restructure; the second commit in Task 9 will show INDEX.md as already containing those two links, so it'll be a no-op or tiny diff.
