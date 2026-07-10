#!/usr/bin/env bash

set -euo pipefail

if [[ "${1:-}" == '--message' ]]; then
  first_line="${2:?Expected a message after --message.}"
else
  message_file="${1:?Expected the commit-message file path or --message.}"
  first_line="$(head -n 1 "$message_file")"
fi
# Git may provide a CRLF commit-message file on Windows. The Conventional
# Commits body is unrestricted; normalize only the first line before matching.
first_line="${first_line%$'\r'}"
regex='^(feat|fix|docs|refactor|perf|test|chore|build|ci)(\([A-Za-z0-9._/-]+\))?(!)?: .+$'

if [[ "$first_line" =~ $regex ]]; then
  exit 0
fi

cat >&2 <<'EOF'
Invalid commit message.

Use Conventional Commits:
  type(optional-scope)!?: description

Allowed types:
  feat | fix | docs | refactor | perf | test | chore | build | ci

Examples:
  feat: add game setup flow
  fix(game): restore active player after restart
  refactor!: remove deprecated event schema
  ci(github-actions): update build pipeline
EOF

exit 1
