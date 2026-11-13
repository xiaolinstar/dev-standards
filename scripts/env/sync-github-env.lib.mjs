import { homedir } from 'node:os'
import { join, resolve } from 'node:path'

const DEFAULT_VARIABLES_NAME = 'variables.env'
const DEFAULT_SECRETS_NAME = 'secrets.env'

export function parseEnvFile(raw) {
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

export function expandHome(path, home = homedir()) {
  if (path === '~') return home
  if (path.startsWith('~/')) return resolve(home, path.slice(2))
  return path
}

export function resolveL2Paths({
  configDir,
  scope,
  environment,
  variablesName = DEFAULT_VARIABLES_NAME,
  secretsName = DEFAULT_SECRETS_NAME,
}) {
  const base =
    scope === 'environment' ? join(configDir, environment) : configDir
  return {
    variablesPath: join(base, variablesName),
    secretsPath: join(base, secretsName),
  }
}

export function buildSyncPlan({
  variables,
  secrets,
  repository,
  environment,
  scope,
}) {
  const plan = []
  for (const [key, value] of Object.entries(variables)) {
    if (value === '') continue
    plan.push({ kind: 'variable', key, value, repository, environment, scope })
  }
  for (const [key, value] of Object.entries(secrets)) {
    if (value === '') continue
    plan.push({ kind: 'secret', key, value, repository, environment, scope })
  }
  return plan
}

export function assertRequired(plan, { required_variables = [], required_secrets = [] } = {}) {
  for (const key of required_variables) {
    const entry = plan.find((x) => x.kind === 'variable' && x.key === key)
    if (!entry || entry.value === '') {
      throw new Error(`Missing required variable: ${key}`)
    }
  }
  for (const key of required_secrets) {
    const entry = plan.find((x) => x.kind === 'secret' && x.key === key)
    if (!entry || entry.value === '') {
      throw new Error(`Missing required secret: ${key}`)
    }
  }
}

export function defaultRepository(project, profileRepository) {
  return profileRepository || `xiaolinstar/${project}`
}
