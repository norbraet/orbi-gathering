#!/usr/bin/env bash

set -euo pipefail

script_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=conventional-commit.sh
source "$script_directory/conventional-commit.sh"

if [[ "${1:-}" == '--message' ]]; then
  first_line="${2:?Expected a message after --message.}"
else
  message_file="${1:?Expected the commit-message file path or --message.}"
  first_line="$(head -n 1 "$message_file")"
fi
# Git may provide a CRLF commit-message file on Windows. The Conventional
# Commits body is unrestricted; normalize only the first line before matching.
first_line="${first_line%$'\r'}"
if conventional_commit_header_is_valid "$first_line"; then
  exit 0
fi

cat >&2 <<'EOF'
Invalid commit message.

Use Conventional Commits:
  type(optional-scope)!?: description

Allowed types:
  feat | fix | deps | docs | refactor | perf | test | chore | build | ci | style | revert

Breaking changes:
  Add ! before the colon, or use a BREAKING CHANGE: footer in the commit body.

Examples:
  feat: add game setup flow
  fix(game): restore active player after restart
  deps: update Flutter dependencies
  refactor!: remove deprecated event schema
  ci(github-actions): update build pipeline
EOF

exit 1
