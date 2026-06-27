#!/usr/bin/env bash
# Pre-commit guard: block LocalSecrets.plist and DashScope-style API keys.
set -euo pipefail

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  exit 0
fi

staged=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)

if echo "$staged" | grep -qE '(^|/)LocalSecrets\.plist$'; then
  echo "check-secrets: LocalSecrets.plist must not be committed (see .gitignore)." >&2
  exit 1
fi

if git diff --cached -U0 -- . ':!scripts/check-secrets.sh' 2>/dev/null \
  | grep -E '^\+' \
  | grep -v 'YOUR_DASHSCOPE_API_KEY_HERE' \
  | grep -qE 'sk-[a-zA-Z0-9._-]{20,}'; then
  echo "check-secrets: possible DashScope API key in staged changes." >&2
  exit 1
fi

exit 0
