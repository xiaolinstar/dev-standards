// scripts/env/sync-github-env.test.mjs
import { describe, it } from 'node:test'
import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import {
  parseEnvFile,
  resolveL2Paths,
  buildSyncPlan,
  assertRequired,
  defaultRepository,
} from './sync-github-env.lib.mjs'

const CLI = fileURLToPath(new URL('./sync-github-env.mjs', import.meta.url))

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

describe('CLI', () => {
  it('CLI dry-run secrets-only', () => {
    const root = mkdtempSync(join(tmpdir(), 'sync-github-cli-'))
    const home = join(root, 'home')
    const githubDir = join(root, 'github')
    const envDir = join(githubDir, 'aliyun-121')
    mkdirSync(envDir, { recursive: true })
    mkdirSync(home, { recursive: true })
    writeFileSync(
      join(envDir, 'secrets.env'),
      'SERVER_HOST=1.1.1.1\nSERVER_USER=ubuntu\nSERVER_PASSWORD=secret\n',
    )
    const profilePath = join(root, 'profiles.json')
    writeFileSync(
      profilePath,
      JSON.stringify({
        'xiaolin-gateway': {
          repository: 'xiaolinstar/xiaolin-gateway',
          scope: 'environment',
          config_dir: githubDir,
          required_secrets: ['SERVER_HOST', 'SERVER_USER', 'SERVER_PASSWORD'],
        },
      }),
    )

    try {
      const result = spawnSync(
        process.execPath,
        [CLI, '--project', 'xiaolin-gateway', '--environment', 'aliyun-121', '--dry-run'],
        {
          encoding: 'utf8',
          env: {
            ...process.env,
            // Keep homedir() off the real L2 tree if the profile override is ignored.
            HOME: home,
            XIAOLINSTAR_SYNC_PROFILES: profilePath,
          },
        },
      )
      assert.equal(result.status, 0, result.stderr)
      const stdout = result.stdout || ''
      assert.match(stdout, /\[dry-run\] secret SERVER_HOST -> /)
      assert.match(stdout, /\[dry-run\] secret SERVER_USER -> /)
      assert.match(stdout, /\[dry-run\] secret SERVER_PASSWORD -> /)
      assert.doesNotMatch(stdout, /variable /)
      assert.doesNotMatch(stdout, /1\.1\.1\.1/)
    } finally {
      rmSync(root, { recursive: true, force: true })
    }
  })
})
