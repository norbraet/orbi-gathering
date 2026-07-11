#!/usr/bin/env bash

set -euo pipefail

script_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=conventional-commit.sh
source "$script_directory/conventional-commit.sh"

template='.github/PULL_REQUEST_TEMPLATE.md'
branch="$(git branch --show-current)"
commit_subject="$(git log -1 --pretty=%s)"
body_file="$(mktemp)"

cleanup() {
  rm -f "$body_file"
}
trap cleanup EXIT

if conventional_commit_header_is_valid "$commit_subject"; then
  pull_request_title="$commit_subject"
elif [[ "$commit_subject" =~ $conventional_commit_branch_subject_regex ]] && [[ -n "${BASH_REMATCH[2]}" ]]; then
  pull_request_title="${BASH_REMATCH[1]}: ${BASH_REMATCH[2]}"
else
  printf 'The latest commit does not have a Conventional Commit title: %s\n' \
    "$commit_subject" >&2
  printf 'Use e.g. "feat: add game setup" or pass a branch-style subject such as "feat/4-game-setup".\n' >&2
  exit 1
fi

printf 'Using pull request title: %s\n' "$pull_request_title"

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

gh pr create --title "$pull_request_title" --body-file "$body_file" "$@"
