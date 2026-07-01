#!/usr/bin/env sh

# 1. Secret scan (降级：本地未装 gitleaks 不阻断，CI 兜底)
if command -v gitleaks >/dev/null 2>&1; then
  gitleaks protect --staged --redact --no-banner || exit 1
else
  echo "⚠️  gitleaks 未装；CI 兜底（.github/workflows/ci.yml）"
fi

# 2. lint-staged
npx --no -- lint-staged
