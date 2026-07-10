#!/usr/bin/env bash

set -euo pipefail

template='.github/PULL_REQUEST_TEMPLATE.md'
branch="$(git branch --show-current)"
body_file="$(mktemp)"

cleanup() {
  rm -f "$body_file"
}
trap cleanup EXIT

cp "$template" "$body_file"

if [[ "$branch" =~ (^|[/_-])([0-9]+)([-_/]|$) ]]; then
  issue_number="${BASH_REMATCH[2]}"
  printf '\n## Linked issue\n\nCloses #%s\n' "$issue_number" >> "$body_file"
  printf 'Linking this pull request to issue #%s from branch %s.\n' \
    "$issue_number" "$branch"
else
  printf 'No issue-number segment found in branch %s; creating an unlinked pull request.\n' \
    "$branch" >&2
fi

gh pr create --fill --body-file "$body_file" "$@"
