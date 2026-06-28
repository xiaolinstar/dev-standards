#!/usr/bin/env node
import { existsSync, readFileSync } from 'node:fs'
import { homedir } from 'node:os'
import { dirname, join, resolve } from 'node:path'
import { spawnSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '../..')
const PROFILES = JSON.parse(
  readFileSync(join(ROOT, 'scripts/env/github-sync-profiles.json'), 'utf8'),
)

const args = process.argv.slice(2)
const dryRun = args.includes('--dry-run')
const project = readArgValue('--project')
const environmentArg = readArgValue('--environment') || readArgValue('--env') || 'production'

if (!project) {
  console.error('Usage: sync-github-env.mjs --project <name> [--dry-run] [--env-file path]')
  console.error(`Known projects: ${Object.keys(PROFILES).join(', ')}`)
  process.exit(1)
}

const profile = PROFILES[project]
if (!profile) {
  console.error(`Unknown project: ${project}`)
  process.exit(1)
}

const envFileArg = readArgValue('--env-file')
const envFile = resolveConfigFile(profile, envFileArg, environmentArg)
const values = parseEnvFile(readFileSync(envFile, 'utf8'))
const repository = values.GITHUB_REPOSITORY || profile.repository
const environment = values.GITHUB_ENVIRONMENT || profile.environment || environmentArg
const scope = profile.scope || 'repository'

for (const key of profile.variables || []) {
  setGithubValue({
    kind: 'variable',
    key,
    value: values[key],
    repository,
    environment,
    scope,
    required: (profile.required_variables || []).includes(key),
  })
}

const sshKey = profile.ssh_key_secret ? readSshKey(values) : ''
if (sshKey && profile.ssh_key_secret) {
  setGithubValue({
    kind: 'secret',
    key: profile.ssh_key_secret,
    value: sshKey,
    repository,
    environment,
    scope,
    required: false,
  })
}

for (const key of profile.secrets || []) {
  setGithubValue({
    kind: 'secret',
    key,
    value: values[key],
    repository,
    environment,
    scope,
    required: (profile.required_secrets || []).includes(key),
  })
}

if (profile.ssh_key_secret && !sshKey && !values.DEPLOY_PASSWORD) {
  console.error(
    'Missing deployment credential: set DEPLOY_SSH_KEY_FILE, DEPLOY_SSH_KEY, DEPLOY_SSH_KEY_B64, or DEPLOY_PASSWORD.',
  )
  process.exit(1)
}

console.log(`GitHub L2 sync complete for ${project} (${repository}, scope=${scope}).`)

function resolveConfigFile(profile, override, environmentName) {
  if (override) {
    const path = expandHome(override)
    if (!existsSync(path)) {
      console.error(`Missing env file: ${path}`)
      process.exit(1)
    }
    return path
  }

  const candidates = [
    expandHome(
      profile.config_file.replace('github-production.env', `github-${environmentName}.env`),
    ),
    expandHome(profile.config_file),
  ]
  if (profile.legacy_config_file) {
    candidates.push(
      expandHome(
        profile.legacy_config_file.replace('github-production.env', `github-${environmentName}.env`),
      ),
      expandHome(profile.legacy_config_file),
    )
  }

  for (const path of candidates) {
    if (existsSync(path)) {
      return path
    }
  }

  console.error(`Missing env file for ${project}. Tried:`)
  for (const path of candidates) {
    console.error(`  - ${path}`)
  }
  console.error('Copy docs/env/github-production.env to the config path and fill values first.')
  process.exit(1)
}

function readArgValue(name) {
  const index = args.indexOf(name)
  if (index < 0) return ''
  return args[index + 1] || ''
}

function expandHome(path) {
  if (path === '~') return homedir()
  if (path.startsWith('~/')) return resolve(homedir(), path.slice(2))
  return path
}

function parseEnvFile(raw) {
  const result = {}
  for (const rawLine of raw.split(/\r?\n/)) {
    const line = rawLine.trim()
    if (!line || line.startsWith('#')) continue
    const equalsIndex = line.indexOf('=')
    if (equalsIndex < 0) continue

    const key = line.slice(0, equalsIndex).trim()
    let value = line.slice(equalsIndex + 1).trim()
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1)
    }
    result[key] = value
  }
  return result
}

function readSshKey(values) {
  if (values.DEPLOY_SSH_KEY_FILE) {
    const keyPath = expandHome(values.DEPLOY_SSH_KEY_FILE)
    if (dryRun && !existsSync(keyPath)) {
      console.log(`[dry-run] secret DEPLOY_SSH_KEY would read file: ${keyPath}`)
      return 'dry-run-ssh-key'
    }
    if (!existsSync(keyPath)) {
      console.error(`Missing DEPLOY_SSH_KEY_FILE: ${keyPath}`)
      process.exit(1)
    }
    return readFileSync(keyPath, 'utf8').trim()
  }

  if (values.DEPLOY_SSH_KEY_B64) {
    return Buffer.from(values.DEPLOY_SSH_KEY_B64, 'base64').toString('utf8').trim()
  }

  if (values.DEPLOY_SSH_KEY) {
    return values.DEPLOY_SSH_KEY.replaceAll('\\n', '\n').trim()
  }

  return ''
}

function setGithubValue({ kind, key, value, repository, environment, scope, required }) {
  if (!value) {
    if (required) {
      console.error(`Missing required ${kind}: ${key}`)
      process.exit(1)
    }
    return
  }

  const command = ['gh', kind === 'variable' ? 'variable' : 'secret', 'set', key, '--repo', repository]
  if (scope === 'environment') {
    command.push('--env', environment)
  }
  if (kind === 'variable') {
    command.push('--body', value)
  } else {
    command.push('--body', value)
  }

  if (dryRun) {
    const target = scope === 'environment' ? `${repository}/${environment}` : repository
    console.log(`[dry-run] ${kind} ${key} -> ${target}`)
    return
  }

  const result = spawnSync(command[0], command.slice(1), {
    stdio: 'inherit',
  })

  if (result.status !== 0) {
    process.exit(result.status || 1)
  }
}
