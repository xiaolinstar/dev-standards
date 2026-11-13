#!/usr/bin/env node
import { spawnSync } from 'node:child_process'
import { existsSync, readFileSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import {
  assertRequired,
  buildSyncPlan,
  defaultRepository,
  expandHome,
  parseEnvFile,
  resolveL2Paths,
} from './sync-github-env.lib.mjs'

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '../..')
const profilesPath =
  process.env.XIAOLINSTAR_SYNC_PROFILES ||
  join(ROOT, 'scripts/env/github-sync-profiles.json')
const PROFILES = JSON.parse(readFileSync(profilesPath, 'utf8'))

const args = process.argv.slice(2)
const dryRun = args.includes('--dry-run')
const project = readArgValue('--project')
const environment = readArgValue('--environment') || readArgValue('--env') || 'production'

if (!project) {
  console.error('Usage: sync-github-env.mjs --project <name> [--dry-run] [--environment NAME]')
  console.error(`Known projects: ${Object.keys(PROFILES).join(', ')}`)
  process.exit(1)
}

const profile = PROFILES[project]
if (!profile) {
  console.error(`Unknown project: ${project}`)
  process.exit(1)
}

if (!profile.config_dir) {
  console.error(`Missing config_dir for ${project}`)
  process.exit(1)
}

const repository = defaultRepository(project, profile.repository)
const scope = profile.scope || 'repository'
const configDir = expandHome(profile.config_dir)
const { variablesPath, secretsPath } = resolveL2Paths({
  configDir,
  scope,
  environment,
})

const hasVariables = existsSync(variablesPath)
const hasSecrets = existsSync(secretsPath)
if (!hasVariables && !hasSecrets) {
  console.error(`Missing L2 config for ${project} (environment=${environment}). Expected:`)
  console.error(`  - ${variablesPath}`)
  console.error(`  - ${secretsPath}`)
  console.error('Run: sync.sh env init-github-env --project <name> --environment <name>')
  process.exit(1)
}

const variables = hasVariables ? parseEnvFile(readFileSync(variablesPath, 'utf8')) : {}
const secrets = hasSecrets ? parseEnvFile(readFileSync(secretsPath, 'utf8')) : {}
if (hasVariables) console.log(`→ loaded ${variablesPath}`)
if (hasSecrets) console.log(`→ loaded ${secretsPath}`)

const plan = buildSyncPlan({ variables, secrets, repository, environment, scope })
try {
  assertRequired(plan, profile)
} catch (error) {
  console.error(error.message)
  process.exit(1)
}

for (const item of plan) applyPlanItem(item)

console.log(
  `GitHub L2 sync complete for ${project} (${repository}, env=${environment}, scope=${scope}).`,
)

function readArgValue(name) {
  const index = args.indexOf(name)
  if (index < 0) return ''
  return args[index + 1] || ''
}

function applyPlanItem({ kind, key, value, repository: repo, environment: envName, scope: itemScope }) {
  const target = itemScope === 'environment' ? `${repo}/${envName}` : repo
  if (dryRun) {
    console.log(`[dry-run] ${kind} ${key} -> ${target}`)
    return
  }

  const command = ['gh', kind === 'variable' ? 'variable' : 'secret', 'set', key, '--repo', repo]
  if (itemScope === 'environment') command.push('--env', envName)
  command.push('--body', value)

  const result = spawnSync(command[0], command.slice(1), { stdio: 'inherit' })
  if (result.status !== 0) process.exit(result.status || 1)
}
