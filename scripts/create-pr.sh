#!/usr/bin/env bash

set -euo pipefail

script_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=conventional-commit.sh
source "$script_directory/conventional-commit.sh"

repository_root="$(git rev-parse --show-toplevel)"
template="$repository_root/.github/PULL_REQUEST_TEMPLATE.md"
linked_issue_marker='<!-- LINKED_ISSUE -->'

branch="$(git branch --show-current)"
body_file="$(mktemp)"

cleanup() {
  rm -f "$body_file"
}
trap cleanup EXIT

if [[ -z "$branch" ]]; then
  printf 'Cannot create a pull request from a detached HEAD.\n' >&2
  exit 1
fi

if [[ ! -f "$template" ]]; then
  printf 'Pull request template not found: %s\n' "$template" >&2
  exit 1
fi

if ! grep -Fq "$linked_issue_marker" "$template"; then
  printf 'Pull request template does not contain marker: %s\n' \
    "$linked_issue_marker" >&2
  exit 1
fi

if ! commit_subject="$(git log -1 --pretty=%s)"; then
  printf 'Cannot determine the latest commit subject.\n' >&2
  exit 1
fi

if conventional_commit_header_is_valid "$commit_subject"; then
  pull_request_title="$commit_subject"
elif [[ "$commit_subject" =~ $conventional_commit_branch_subject_regex ]] &&
  [[ -n "${BASH_REMATCH[2]}" ]]; then
  pull_request_title="${BASH_REMATCH[1]}: ${BASH_REMATCH[2]}"
else
  printf 'The latest commit does not have a Conventional Commit title: %s\n' \
    "$commit_subject" >&2
  printf '%s\n' \
    'Use e.g. "feat: add game setup" or make the latest commit subject branch-style, such as "feat/4-game-setup".' \
    >&2
  exit 1
fi

printf 'Using pull request title: %s\n' "$pull_request_title"

linked_issue=''

if [[ "$branch" =~ ^(${conventional_commit_types})/([0-9]+)- ]]; then
  issue_number="${BASH_REMATCH[2]}"
  linked_issue="Closes #$issue_number"

  printf 'Linking this pull request to issue #%s from branch %s.\n' \
    "$issue_number" "$branch"
else
  printf 'No issue number found in branch %s; creating an unlinked pull request.\n' \
    "$branch" >&2
fi

awk \
  -v marker="$linked_issue_marker" \
  -v replacement="$linked_issue" \
  '{
    if (index($0, marker)) {
      print replacement
    } else {
      print
    }
  }' \
  "$template" > "$body_file"

gh pr create \
  --title "$pull_request_title" \
  --body-file "$body_file" \
  "$@"
