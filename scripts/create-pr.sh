#!/usr/bin/env bash

set -euo pipefail

script_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=conventional-commit.sh
source "$script_directory/conventional-commit.sh"

repository_root="$(git rev-parse --show-toplevel)"
template="$repository_root/.github/PULL_REQUEST_TEMPLATE.md"
linked_issue_marker='<!-- LINKED_ISSUE -->'
commit_list_marker='<!-- COMMIT_LIST -->'

branch="$(git branch --show-current)"
body_file="$(mktemp)"
commit_list_file="$(mktemp)"

cleanup() {
  rm -f "$body_file" "$commit_list_file"
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

if ! grep -Fq "$commit_list_marker" "$template"; then
  printf 'Pull request template does not contain marker: %s\n' \
    "$commit_list_marker" >&2
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

base_branch=''
argument_index=1
while ((argument_index <= $#)); do
  argument="${!argument_index}"
  case "$argument" in
    --base)
      ((argument_index++))
      if ((argument_index > $#)); then
        printf 'The --base option requires a branch name.\n' >&2
        exit 1
      fi
      base_branch="${!argument_index}"
      ;;
    --base=*)
      base_branch="${argument#--base=}"
      ;;
  esac
  ((argument_index++))
done

if [[ -z "$base_branch" ]]; then
  base_branch="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  base_branch="${base_branch#origin/}"
fi

if [[ -z "$base_branch" ]]; then
  printf 'Cannot determine the pull request base branch; pass --base explicitly.\n' >&2
  exit 1
fi

base_ref="$base_branch"
if ! git rev-parse --verify --quiet "$base_ref^{commit}" >/dev/null; then
  base_ref="origin/$base_branch"
fi

if ! git rev-parse --verify --quiet "$base_ref^{commit}" >/dev/null; then
  printf 'Pull request base branch is not available locally: %s\n' "$base_branch" >&2
  printf 'Fetch it or pass a different --base branch.\n' >&2
  exit 1
fi

if ! git log --reverse --format='- %s' "$base_ref..HEAD" > "$commit_list_file"; then
  printf 'Cannot determine commits relative to base branch: %s\n' "$base_branch" >&2
  exit 1
fi

if [[ ! -s "$commit_list_file" ]]; then
  printf '%s\n' '- No commits found relative to the pull request base branch.' > "$commit_list_file"
fi

printf 'Listing commits relative to base branch %s.\n' "$base_branch"

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
  -v linked_issue_marker="$linked_issue_marker" \
  -v linked_issue="$linked_issue" \
  -v commit_list_marker="$commit_list_marker" \
  -v commit_list_file="$commit_list_file" \
  '{
    if (index($0, linked_issue_marker)) {
      print linked_issue
    } else if (index($0, commit_list_marker)) {
      for (commit_index = 1; commit_index <= commit_count; commit_index++) {
        print commit_lines[commit_index]
      }
    } else {
      print
    }
  }
  BEGIN {
    commit_count = 0
    while ((getline line < commit_list_file) > 0) {
      commit_lines[++commit_count] = line
    }
    close(commit_list_file)
  }' \
  "$template" > "$body_file"

gh pr create \
  --title "$pull_request_title" \
  --body-file "$body_file" \
  "$@"
