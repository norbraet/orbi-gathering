# Release process and versioning

OrbiGathering uses [Semantic Versioning](https://semver.org/) and
[Conventional Commits](https://www.conventionalcommits.org/) with
release-please to produce release pull requests, Git tags, GitHub releases,
and changelog entries.

## Version sources

| File | Responsibility |
| --- | --- |
| `pubspec.yaml` | Flutter application version. The `+<build>` suffix is Flutter build metadata and does not affect release precedence. |
| `.release-please-manifest.json` | Last released semantic version used by release-please to calculate the next version. |
| `release-please-config.json` | Declares the Dart release strategy, root-package tag format, and pre-1.0 bump policy. |
| `CHANGELOG.md` | Changelog updated by the generated release pull request. |

The repository begins at `0.0.0`. Version `0.y.z` is initial development:
the public API is not yet stable. Move intentionally to `1.0.0` only when the
application has a stable public contract and is ready for its first stable
release.

## Commit messages and version bumps

Every commit and pull request title must use this format:

```text
type(optional-scope)!: concise description
```

The accepted project types are `feat`, `fix`, `deps`, `docs`, `refactor`,
`perf`, `test`, `chore`, `build`, `ci`, `style`, and `revert`. Scopes use
letters, numbers, `.`, `_`, `/`, and `-`.

release-please creates or updates a release pull request only when releasable
commits reach `main`:

| Commit type | Effect |
| --- | --- |
| `fix:` | Patch bump: `0.1.0` to `0.1.1`. |
| `deps:` | Patch bump for a dependency update. |
| `feat:` | Minor bump: `0.1.0` to `0.2.0`. |
| `docs:`, `refactor:`, `perf:`, `test:`, `chore:`, `build:`, `ci:`, `style:`, `revert:` | Valid project commits, but do not create a release by themselves. |

Mark an incompatible change with either `!` after the type or scope, or a
`BREAKING CHANGE:` footer in the commit body:

```text
feat(game)!: replace the event payload format

BREAKING CHANGE: persisted events require a migration before recovery.
```

While the major version is zero, `bump-minor-pre-major` keeps breaking changes
in initial development: `0.1.0` becomes `0.2.0`, not `1.0.0`. Once the project
is intentionally released as `1.0.0`, a breaking change produces the next
major version.

## Release workflow

1. Feature work merges into `develop` using Conventional Commit-style titles.
2. A maintainer runs `mise run release:promote` to open the deliberate
   `develop` to `main` promotion pull request.
3. Merging that pull request runs release-please on `main`.
4. Release-please creates or updates a release pull request containing the
   calculated version, `pubspec.yaml` update, changelog entries, and manifest
   update.
5. Merging the release pull request creates the `v<version>` tag and the
   GitHub release.

The workflow uses the repository secret `RELEASE_PLEASE_TOKEN`. It must be a
fine-grained PAT with read and write access to **Contents**, **Issues**, and
**Pull requests**, so CI runs automatically on release pull requests.
