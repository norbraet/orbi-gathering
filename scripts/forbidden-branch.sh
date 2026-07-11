#!/usr/bin/env bash

set -euo pipefail

operation="${1:-change}"
branch="$(git branch --show-current)"

case "$branch" in
  main|master|develop)
    printf 'Direct %s on the %s branch is forbidden. Create a feature branch first.\n' \
      "$operation" "$branch" >&2
    exit 1
    ;;
esac
