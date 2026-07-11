#!/usr/bin/env bash

set -euo pipefail

release_branch='main'
integration_branch='develop'

git fetch origin "$release_branch" "$integration_branch" --quiet

ahead_count="$(git rev-list --count "origin/$release_branch..origin/$integration_branch")"

if [[ "$ahead_count" == 0 ]]; then
  printf '%s has no commits ahead of %s; nothing to promote.\n' \
    "$integration_branch" "$release_branch" >&2
  exit 1
fi

printf 'Opening a pull request to promote %s into %s (%s commit(s) ahead).\n' \
  "$integration_branch" "$release_branch" "$ahead_count"

gh pr create \
  --base "$release_branch" \
  --head "$integration_branch" \
  --title "chore: promote $integration_branch to $release_branch" \
  --body "Promotes $integration_branch to $release_branch. Merging this is what triggers release-please to open or update its release pull request." \
  "$@"
