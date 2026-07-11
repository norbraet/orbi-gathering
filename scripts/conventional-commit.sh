#!/usr/bin/env bash

# Shared Conventional Commit grammar for local hooks and PR helpers. Keep the
# accepted types aligned with docs/release.md.

conventional_commit_types='feat|fix|deps|docs|refactor|perf|test|chore|build|ci|style|revert'
conventional_commit_header_regex="^(${conventional_commit_types})(\\([A-Za-z0-9._/-]+\\))?(!)?: .+$"
conventional_commit_branch_subject_regex="^(${conventional_commit_types})[/_-][0-9]+[-_ ]+(.+)$"

conventional_commit_header_is_valid() {
  local header="$1"
  [[ "$header" =~ $conventional_commit_header_regex ]]
}
