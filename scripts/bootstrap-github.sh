#!/usr/bin/env bash

set -euo pipefail

labels_file='.github/labels.yml'
milestones_file='.github/milestones.yml'
project_file='.github/project.yml'
is_dry_run=false

usage() {
  cat <<'EOF'
Usage: scripts/bootstrap-github.sh [--dry-run]

Synchronize the repository labels, milestones, and GitHub Project from the
canonical configuration under .github/. Existing items are updated and missing
items are created. Project views and built-in workflows remain a manual step.
EOF
}

while (($# > 0)); do
  case "$1" in
    --dry-run)
      is_dry_run=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

for command in gh git sed; do
  if ! command -v "$command" >/dev/null 2>&1; then
    printf 'Required command not found: %s\n' "$command" >&2
    exit 1
  fi
done

for file in "$labels_file" "$milestones_file" "$project_file"; do
  if [[ ! -f "$file" ]]; then
    printf 'Required configuration file not found: %s\n' "$file" >&2
    exit 1
  fi
done

run() {
  if [[ "$is_dry_run" == true ]]; then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
    return
  fi

  "$@"
}

if [[ "$is_dry_run" == false ]]; then
  gh auth status >/dev/null
fi

repository="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
owner="${repository%%/*}"

printf 'Synchronizing GitHub configuration for %s.\n' "$repository"

while IFS='|' read -r name color description; do
  [[ -z "$name" ]] && continue
  run gh label create "$name" \
    --repo "$repository" \
    --color "$color" \
    --description "$description" \
    --force
done < <(
  sed -n 's/^  - { name: "\([^"]*\)", color: "\([^"]*\)", description: "\([^"]*\)" }$/\1|\2|\3/p' "$labels_file"
)

milestone_title=''
previous_milestone_title=''
while IFS= read -r line; do
  if [[ "$line" =~ ^[[:space:]]*-[[:space:]]title:[[:space:]]\"(.*)\"$ ]]; then
    milestone_title="${BASH_REMATCH[1]}"
    continue
  fi

  if [[ "$line" =~ ^[[:space:]]*previous_title:[[:space:]]\"(.*)\"$ ]]; then
    previous_milestone_title="${BASH_REMATCH[1]}"
    continue
  fi

  if [[ "$line" =~ ^[[:space:]]*description:[[:space:]]\"(.*)\"$ ]] && [[ -n "$milestone_title" ]]; then
    description="${BASH_REMATCH[1]}"
    existing_number="$(
      gh api --paginate "repos/$repository/milestones?state=all&per_page=100" \
        --jq ".[] | select(.title == \"$milestone_title\") | .number" |
        head -n 1
    )"

    if [[ -z "$existing_number" ]] && [[ -n "$previous_milestone_title" ]]; then
      existing_number="$(
        gh api --paginate "repos/$repository/milestones?state=all&per_page=100" \
          --jq ".[] | select(.title == \"$previous_milestone_title\") | .number" |
          head -n 1
      )"
    fi

    if [[ -n "$existing_number" ]]; then
      run gh api --method PATCH "repos/$repository/milestones/$existing_number" \
        -f title="$milestone_title" \
        -f description="$description"
    else
      run gh api --method POST "repos/$repository/milestones" \
        -f title="$milestone_title" \
        -f description="$description"
    fi
    milestone_title=''
    previous_milestone_title=''
  fi
done < "$milestones_file"

project_title="$(sed -n 's/^title: //p' "$project_file" | head -n 1)"
project_description="$(sed -n 's/^description: //p' "$project_file" | head -n 1)"
project_readme="$(
  sed -n '/^readme: |$/,/^fields:$/p' "$project_file" |
    sed '1d;$d;s/^  //'
)"

project_number="$(
  gh project list --owner "$owner" --limit 100 --format json \
    --jq ".projects[] | select(.title == \"$project_title\") | .number" |
    head -n 1
)"

if [[ -z "$project_number" ]]; then
  if [[ "$is_dry_run" == true ]]; then
    printf '[dry-run] create project %q for %q\n' "$project_title" "$owner"
    printf '[dry-run] project fields and repository link require the created project number\n'
    exit 0
  fi

  project_number="$(
    gh project create --owner "$owner" --title "$project_title" \
      --format json --jq .number
  )"
fi

project_id="$(
  gh project view "$project_number" --owner "$owner" --format json --jq .id
)"

project_update_query='mutation($projectId:ID!,$title:String!,$shortDescription:String!,$readme:String!){updateProjectV2(input:{projectId:$projectId,title:$title,shortDescription:$shortDescription,readme:$readme}){projectV2{id}}}'
run gh api graphql \
  -f query="$project_update_query" \
  -f projectId="$project_id" \
  -f title="$project_title" \
  -f shortDescription="$project_description" \
  -f readme="$project_readme"

run gh project link "$project_number" --owner "$owner" --repo "$repository"

while IFS='|' read -r field_key options; do
  [[ -z "$field_key" ]] && continue
  case "$field_key" in
    delivery_status) field_name='Delivery status' ;;
    priority) field_name='Priority' ;;
    effort) field_name='Effort' ;;
    area) field_name='Area' ;;
    *)
      printf 'Unknown project field key: %s\n' "$field_key" >&2
      exit 1
      ;;
  esac
  existing_field="$(
    gh project field-list "$project_number" --owner "$owner" --limit 100 \
      --format json --jq ".fields[] | select(.name == \"$field_name\") | .name" |
      head -n 1
  )"

  if [[ -z "$existing_field" ]]; then
    run gh project field-create "$project_number" \
      --owner "$owner" \
      --name "$field_name" \
      --data-type SINGLE_SELECT \
      --single-select-options "$options"
  else
    printf 'Project field already exists: %s\n' "$field_name"
  fi
done < <(
  sed -n '/^fields:$/,/^workflows:$/p' "$project_file" |
    sed -n 's/^  \([^:]*\): \[\(.*\)\]$/\1|\2/p' |
    sed 's/, /,/g'
)

printf 'GitHub labels, milestones, project metadata, link, and fields are synchronized.\n'
printf 'Configure project views and built-in workflows in the GitHub UI as documented.\n'
