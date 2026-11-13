# sync-github 约定优于配置（全量同步）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 `sync-github` 按约定从路径解析元数据，并把 `variables.env` / `secrets.env` 中的非空键全量推到 GitHub Variables / Secrets（无 Variables 时可省略 `variables.env`）。

**Architecture:** 将纯逻辑抽到 `sync-github-env.lib.mjs`（解析路径、解析 env、拼推送计划、校验 required）；CLI `sync-github-env.mjs` 只负责读 profile、调 lib、执行 `gh` 或 dry-run。profile 去掉白名单与 SSH 文件魔法，仅保留 `repository` / `scope` / `config_dir` / `required_*`。

**Tech Stack:** Node.js（`node --test`）、`gh` CLI、bash（`init-github-env.sh` / `check-env-keys.sh`）

**Spec:** [2026-11-13-sync-github-convention-over-config-design.md](../specs/2026-11-13-sync-github-convention-over-config-design.md)

## Global Constraints

- 本阶段不做 `*_FILE` / `*_B64` 自动展开；不做旧扁平 `github-*.env` 静默兼容（缺失新布局则明确报错）。
- 元数据不进数据文件：不以 `GITHUB_REPOSITORY` / `GITHUB_ENVIRONMENT` 为真源。
- Agent 禁区不变：实现与验证可用临时目录；真人密钥目录仍禁止 Agent 读写。
- Conventional Commits；不 `--no-verify`。

---

## File map

| 文件 | 职责 |
|------|------|
| `scripts/env/sync-github-env.lib.mjs` | 纯函数：路径解析、parseEnv、buildPlan、assertRequired |
| `scripts/env/sync-github-env.mjs` | CLI：profile、load files、dry-run / spawn `gh` |
| `scripts/env/sync-github-env.test.mjs` | `node --test` |
| `scripts/env/github-sync-profiles.json` | 去掉 `variables`/`secrets`/`ssh_key_secret`/`legacy_config_file` |
| `scripts/env/init-github-env.sh` | variables 模板可选跳过 |
| `scripts/env/check-env-keys.sh` | `--github` 时缺 L0 variables 模板则 skip |
| `playbook/env-management.md`、`adr/0012-*.md`、`CHANGELOG.md` | 文档 |
| `xiaolin-gateway/docs/env/github/**` + `env-registry.yaml` | 去掉无意义 variables L0 |

---

### Task 1: 纯逻辑库 + 失败测试

**Files:**
- Create: `scripts/env/sync-github-env.lib.mjs`
- Create: `scripts/env/sync-github-env.test.mjs`

**Interfaces:**
- Produces:
  - `parseEnvFile(raw: string): Record<string, string>`
  - `expandHome(path: string, home?: string): string`
  - `resolveL2Paths({ configDir, scope, environment, variablesName?, secretsName? }): { variablesPath, secretsPath }`
  - `buildSyncPlan({ variables, secrets, repository, environment, scope }): Array<{ kind: 'variable'|'secret', key: string, value: string }>`（跳过空值；variables 键 → variable，secrets 键 → secret）
  - `assertRequired(plan, { required_variables?, required_secrets? }): void`（缺则 throw Error）
  - `defaultRepository(project: string, profileRepository?: string): string` → `profileRepository || \`xiaolinstar/${project}\``

- [ ] **Step 1: 写失败测试（库尚不存在）**

```js
// scripts/env/sync-github-env.test.mjs
import { describe, it } from 'node:test'
import assert from 'node:assert/strict'
import {
  parseEnvFile,
  resolveL2Paths,
  buildSyncPlan,
  assertRequired,
  defaultRepository,
} from './sync-github-env.lib.mjs'

describe('parseEnvFile', () => {
  it('skips comments and empty values stay as empty string', () => {
    const v = parseEnvFile('# c\nA=1\nB=\nC="x y"\n')
    assert.equal(v.A, '1')
    assert.equal(v.B, '')
    assert.equal(v.C, 'x y')
  })
})

describe('resolveL2Paths', () => {
  it('environment scope uses env subdirectory', () => {
    const p = resolveL2Paths({
      configDir: '/cfg/github',
      scope: 'environment',
      environment: 'aliyun-121',
    })
    assert.equal(p.variablesPath, '/cfg/github/aliyun-121/variables.env')
    assert.equal(p.secretsPath, '/cfg/github/aliyun-121/secrets.env')
  })
  it('repository scope has no env subdirectory', () => {
    const p = resolveL2Paths({
      configDir: '/cfg/github',
      scope: 'repository',
      environment: 'ignored',
    })
    assert.equal(p.variablesPath, '/cfg/github/variables.env')
    assert.equal(p.secretsPath, '/cfg/github/secrets.env')
  })
})

describe('buildSyncPlan', () => {
  it('syncs all non-empty keys from each file kind', () => {
    const plan = buildSyncPlan({
      variables: { DEPLOY_HOST: '1.2.3.4', SKIP: '' },
      secrets: { SERVER_PASSWORD: 'x' },
      repository: 'xiaolinstar/xiaolin-gateway',
      environment: 'aliyun-121',
      scope: 'environment',
    })
    assert.deepEqual(
      plan.map((x) => `${x.kind}:${x.key}`),
      ['variable:DEPLOY_HOST', 'secret:SERVER_PASSWORD'],
    )
  })
  it('secrets-only plan has no variables', () => {
    const plan = buildSyncPlan({
      variables: {},
      secrets: { SERVER_HOST: 'h', SERVER_USER: 'u', SERVER_PASSWORD: 'p' },
      repository: 'xiaolinstar/xiaolin-gateway',
      environment: 'tencent-101',
      scope: 'environment',
    })
    assert.equal(plan.length, 3)
    assert.ok(plan.every((x) => x.kind === 'secret'))
  })
})

describe('assertRequired', () => {
  it('throws when required secret missing', () => {
    assert.throws(() =>
      assertRequired([{ kind: 'secret', key: 'A', value: '1' }], {
        required_secrets: ['SERVER_HOST'],
      }),
    )
  })
})

describe('defaultRepository', () => {
  it('uses profile or xiaolinstar/project', () => {
    assert.equal(defaultRepository('xiaolin-gateway', 'org/gw'), 'org/gw')
    assert.equal(defaultRepository('xiaolin-gateway'), 'xiaolinstar/xiaolin-gateway')
  })
})
```

- [ ] **Step 2: 跑测试确认失败**

Run: `cd ~/AgentProjects/dev-standards && node --test scripts/env/sync-github-env.test.mjs`  
Expected: FAIL（MODULE_NOT_FOUND 或 export 缺失）

- [ ] **Step 3: 实现 `sync-github-env.lib.mjs`**

实现上述导出函数。`buildSyncPlan` 对 `variables` / `secrets` 对象分别迭代，值为空字符串则跳过。`assertRequired` 在 plan 中查找 `kind+key` 且 value 非空。

- [ ] **Step 4: 跑测试确认通过**

Run: `node --test scripts/env/sync-github-env.test.mjs`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
cd ~/AgentProjects/dev-standards
git add scripts/env/sync-github-env.lib.mjs scripts/env/sync-github-env.test.mjs
git commit -m "feat(env): add sync-github lib with sync-all plan builder"
```

---

### Task 2: 重写 CLI（新布局 only + dry-run）

**Files:**
- Modify: `scripts/env/sync-github-env.mjs`（整文件按下方语义重写）
- Test: 沿用 Task 1；另加 CLI 级 dry-run 手工/脚本验证（临时目录，不碰真实 `~/.config/xiaolinstar` 密钥）

**Interfaces:**
- Consumes: Task 1 lib
- Produces: CLI 行为符合 spec 验收 1–4

- [ ] **Step 1: 重写 `sync-github-env.mjs`**

行为要点：

1. 读 `--project`（必填）、`--environment`/`--env`（environment scope 必填；缺省可保留 `production` 但文档说明应用显式传）、`--dry-run`。
2. 加载 profile；`repository = defaultRepository(project, profile.repository)`；`scope = profile.scope || 'repository'`。
3. `config_dir` 经 `expandHome`；`resolveL2Paths`。
4. 分别 `existsSync` 读 variables/secrets；皆不存在 → stderr 打印期望路径 + `init-github-env` 提示，exit 1。
5. **不再**加载旧扁平路径 / `legacy_config_file` / `--env-file` 合并白名单逻辑（可删除 `--env-file`，或保留仅当指向单文件时当作 secrets 全量——本阶段 **删除 `--env-file`**，YAGNI）。
6. `buildSyncPlan` → `assertRequired(plan, profile)`。
7. 打印 `→ loaded <path>`。
8. dry-run：对每项 `console.log(\`[dry-run] ${kind} ${key} -> ${target}\`)`；正式：`gh variable|secret set KEY --repo R [--env E] --body V`（stdio inherit）。
9. 删除 `readSshKey` / `ssh_key_secret` 分支。

- [ ] **Step 2: 用临时目录验证 secrets-only dry-run**

```bash
TMP=$(mktemp -d)
mkdir -p "$TMP/xiaolin-gateway/github/aliyun-121"
printf 'SERVER_HOST=1.1.1.1\nSERVER_USER=ubuntu\nSERVER_PASSWORD=secret\n' \
  > "$TMP/xiaolin-gateway/github/aliyun-121/secrets.env"
# 临时改 profile 不可行；改为在测试中注入：给 lib 测即可。
# CLI 验证：在 sync-github-env.test.mjs 增加 integration 风格测试：
# 写临时 profile JSON + 临时 config_dir，spawn node sync-github-env.mjs
# 用环境变量 XIAOLINSTAR_SYNC_PROFILES 指向临时 profile（实现时加这一 hook，仅测试用）
```

实现细节：CLI 支持 `process.env.XIAOLINSTAR_SYNC_PROFILES` 覆盖 profiles 路径（未设置则用默认 `github-sync-profiles.json`）。测试 spawn：

```js
it('CLI dry-run secrets-only', async () => {
  // mkdir temp github/aliyun-121/secrets.env only
  // write temp profiles json with config_dir pointing to temp/github
  // spawnSync('node', [cli, '--project', 'xiaolin-gateway', '--environment', 'aliyun-121', '--dry-run'], { env: { ...process.env, XIAOLINSTAR_SYNC_PROFILES: profilePath } })
  // assert stdout includes 'secret SERVER_HOST' and does not include 'variable '
})
```

- [ ] **Step 3: 跑 `node --test scripts/env/sync-github-env.test.mjs`**  
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add scripts/env/sync-github-env.mjs scripts/env/sync-github-env.test.mjs
git commit -m "feat(env): sync-github pushes all keys from variables/secrets.env"
```

---

### Task 3: 精简 `github-sync-profiles.json`

**Files:**
- Modify: `scripts/env/github-sync-profiles.json`

- [ ] **Step 1: 每个项目只保留**

`repository`, `l2_category`（若仍有引用可留）, `scope`, `config_dir`, `required_variables`（如有）, `required_secrets`（如有）

删除：`variables`, `secrets`, `ssh_key_secret`, `legacy_config_file`。

gateway 示例：

```json
"xiaolin-gateway": {
  "repository": "xiaolinstar/xiaolin-gateway",
  "l2_category": "platform",
  "scope": "environment",
  "config_dir": "~/.config/xiaolinstar/xiaolin-gateway/github",
  "required_secrets": ["SERVER_HOST", "SERVER_USER", "SERVER_PASSWORD"]
}
```

ai-todo 保留 `required_variables: ["DEPLOY_HOST", "DEPLOY_USER"]`，去掉 `ssh_key_secret` 与白名单数组。

- [ ] **Step 2: Commit**

```bash
git add scripts/env/github-sync-profiles.json
git commit -m "refactor(env): drop sync profile allowlists and ssh_key magic"
```

---

### Task 4: `init-github-env` — variables 可选

**Files:**
- Modify: `scripts/env/init-github-env.sh`

- [ ] **Step 1: 改 `copy_one`**

- `kind=variables` 且 `resolve_template` 为空：打印 `skip: no L0 variables template (optional)`，return 0，不 exit 1。
- `kind=secrets` 且模板为空：仍 exit 1（secrets 为常见必填；若将来 content 也无 secrets 再放宽——本阶段 secrets 缺失仍 fail）。
- 调用顺序保持 `copy_one variables` 然后 `copy_one secrets`。

- [ ] **Step 2: 手工 dry-run（gateway，不写真实密钥目录也可）**

若 gateway 已删 variables L0（Task 5），在实现 Task 5 后验证：

```bash
~/AgentProjects/dev-standards/scripts/sync.sh env init-github-env \
  --project xiaolin-gateway --environment aliyun-121 --dry-run
```

Expected: variables skip 行 + secrets would copy 行。

- [ ] **Step 3: Commit**

```bash
git add scripts/env/init-github-env.sh
git commit -m "fix(env): init-github-env skips missing optional variables template"
```

---

### Task 5: gateway L0 + registry（无 Variables）

**Files:**
- Delete: `xiaolin-gateway/docs/env/github/tencent-101/variables.env.example`
- Delete: `xiaolin-gateway/docs/env/github/aliyun-121/variables.env.example`
- Modify: `xiaolin-gateway/docs/env/README.md`、`github-environments.example.env`（说明仅 secrets；variables 可选/省略）
- Modify: `dev-standards/playbook/env-registry.yaml` — gateway `github_environments` 条目去掉 `l0_variables` 行

- [ ] **Step 1: 删除两个 variables.example；更新 README / index 一句**
- [ ] **Step 2: registry 去掉 `l0_variables`**
- [ ] **Step 3: Commit（两个仓可各一次）**

```bash
cd ~/AgentProjects/xiaolin-gateway
git add docs/env
git commit -m "docs(env): drop unused GitHub variables L0 for dual-host CD"

cd ~/AgentProjects/dev-standards
git add playbook/env-registry.yaml
git commit -m "docs(env): gateway registry omits optional l0_variables"
```

---

### Task 6: `check-env-keys --github` 跳过缺失 variables 模板

**Files:**
- Modify: `scripts/env/check-env-keys.sh`（约 114–119 行）

- [ ] **Step 1: 循环内若 `gh_template` 不存在**

- variables：`echo "skip [github:$env:$kind]: no L0 template"`，continue  
- secrets：模板不存在仍 FAIL（与 init 一致）

若 template 不存在但 runtime 存在：variables 可 warn；secrets 保持现有 `check_pair` 行为。

- [ ] **Step 2: Commit**

```bash
git add scripts/env/check-env-keys.sh
git commit -m "fix(env): github check skips missing optional variables template"
```

---

### Task 7: 文档 + CHANGELOG

**Files:**
- Modify: `playbook/env-management.md`（§~/.config 布局、sync 语义、去掉「文件内 GITHUB_*」；警告存量文件勿留元数据键）
- Modify: `playbook/adr/0012-config-github-l2-only.md`（补「全量同步；元数据来自约定」短段；旧扁平改为「报错引导」）
- Modify: `CHANGELOG.md` Unreleased
- Modify: design spec Status → Accepted（可选）

- [ ] **Step 1: 编辑上述文档**
- [ ] **Step 2: `bash scripts/sync.sh validate`（允许 baselines stale warning；env-registry 必须 ok）**
- [ ] **Step 3: Commit**

```bash
git add playbook/env-management.md playbook/adr/0012-config-github-l2-only.md CHANGELOG.md \
  docs/superpowers/specs/2026-11-13-sync-github-convention-over-config-design.md
git commit -m "docs(env): document sync-all convention for sync-github"
```

---

### Task 8: 验收清单（人类终端）

Agent **不**读真实 `~/.config/xiaolinstar/**`。实现者提示用户执行：

```bash
# 若本地 variables.env 仅含 GITHUB_*，先删文件或删这些键
~/AgentProjects/dev-standards/scripts/sync.sh env sync-github \
  --project xiaolin-gateway --environment tencent-101 --dry-run
~/AgentProjects/dev-standards/scripts/sync.sh env sync-github \
  --project xiaolin-gateway --environment aliyun-121 --dry-run
```

Expected: 仅 `secret SERVER_*` 三行；无 `variable`。确认后去掉 `--dry-run` 正式推。

ai-todo（若本机有 L2）：dry-run 应列出 variables.env 内全部非空键。

- [ ] **Step 1: 把上述命令交给用户；根据回报勾选 spec 验收 1–4**

---

## Spec coverage (self-review)

| Spec 要求 | Task |
|-----------|------|
| 约定元数据 / 文件全量同步 | 1–2 |
| variables.env 可选 | 4–6、gateway Task 5 |
| 无 FILE 魔法 | Task 2 删除 readSshKey |
| 新布局 only 报错 | Task 2 |
| required_* 校验 | Task 1–3 |
| dry-run | Task 2 |
| 文档 / 迁移警告 GITHUB_* | Task 7–8 |
| 旧扁平兼容后续 | Out of scope（未实现） |

无 TBD 占位；CLI 测试用 `XIAOLINSTAR_SYNC_PROFILES` 避免碰真实密钥目录。
