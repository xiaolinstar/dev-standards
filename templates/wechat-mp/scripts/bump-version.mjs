#!/usr/bin/env node
/**
 * Sync package.json version → project.config.json versionName
 * Usage: node scripts/bump-version.mjs patch|minor|major|x.y.z [--write]
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const pkgPath = resolve(root, 'package.json');
const projectPath = resolve(root, 'project.config.json');
const args = process.argv.slice(2);
const write = args.includes('--write');
const bumpArg = args.find((a) => !a.startsWith('--'));

if (!bumpArg) {
  console.error('Usage: node scripts/bump-version.mjs <patch|minor|major|x.y.z> [--write]');
  process.exit(2);
}

function parseVersion(v) {
  const m = /^(\d+)\.(\d+)\.(\d+)$/.exec(v);
  if (!m) throw new Error(`Invalid semver: ${v}`);
  return [Number(m[1]), Number(m[2]), Number(m[3])];
}

function nextVersion(current, bump) {
  const [major, minor, patch] = parseVersion(current);
  if (bump === 'major') return `${major + 1}.0.0`;
  if (bump === 'minor') return `${major}.${minor + 1}.0`;
  if (bump === 'patch') return `${major}.${minor}.${patch + 1}`;
  if (/^\d+\.\d+\.\d+$/.test(bump)) return bump;
  throw new Error(`Unknown bump: ${bump}`);
}

const pkg = JSON.parse(readFileSync(pkgPath, 'utf8'));
const project = JSON.parse(readFileSync(projectPath, 'utf8'));
const next = nextVersion(pkg.version, bumpArg);

console.log(`version: ${pkg.version} -> ${next}`);
if (!write) {
  console.log('[DRY-RUN] Re-run with --write to apply.');
  process.exit(0);
}

pkg.version = next;
project.versionName = next;
writeFileSync(pkgPath, `${JSON.stringify(pkg, null, 2)}\n`, 'utf8');
writeFileSync(projectPath, `${JSON.stringify(project, null, 2)}\n`, 'utf8');
console.log('[OK] Updated package.json and project.config.json');
