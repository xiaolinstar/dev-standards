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
