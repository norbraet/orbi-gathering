#!/usr/bin/env bash

set -euo pipefail

message_file="${1:?Expected the commit-message file path.}"
first_line="$(head -n 1 "$message_file")"
regex='^(feat|fix|docs|refactor|perf|test|chore|build|ci)(\([a-z0-9._/-]+\))?(!)?: .+$'

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
