#!/usr/bin/env sh

# 1. Secret scan (必须安装 gitleaks)
if ! command -v gitleaks >/dev/null 2>&1; then
  echo "❌ gitleaks 未安装，请先安装："
  echo "   macOS:  brew install gitleaks"
  echo "   Linux:  https://github.com/gitleaks/gitleaks#installation"
  exit 1
fi
gitleaks protect --staged --redact --no-banner || exit 1

# 2. lint-staged
npx --no -- lint-staged
