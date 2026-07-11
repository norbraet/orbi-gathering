# AGENTS.md

This file defines the coding expectations for automated agents and contributors working in this repository. It applies to the entire repository unless a more specific `AGENTS.md` exists in a subdirectory.

## Project intent

OrbiGathering is an offline-first Flutter companion for physical Magic: The Gathering games. It tracks invisible game state without reproducing the physical battlefield or becoming an authoritative rules engine.

Before making non-trivial changes, read the relevant material in `docs/`. Start with:

1. `docs/vision.md`
2. `docs/gameplay.md`
3. `docs/architecture.md`
4. `docs/tech-stack.md`

Also read `docs/data-model.md` for persistence or domain changes, `docs/api.md` for card-data work, and `docs/ui-design-system.md` for user-interface work. Preserve the accepted decisions under `docs/adr/`; add or amend an ADR when changing a durable architectural decision.

## Toolchain and required checks

Use the repository-pinned toolchain from `mise.toml` rather than an arbitrary system Flutter installation.

```sh
mise install
mise run setup
mise run format
mise run analyze
mise run test
mise run check
```

The Dart formatter and analyzer are authoritative. Do not hand-format against `dart format`, suppress lints broadly, or weaken `analysis_options.yaml` merely to make a change pass. A narrow suppression is acceptable only when the reason is documented next to it.

Run the smallest relevant test during development and `mise run check` before handoff. If a required command cannot run, report the exact command and blocker.

## Architecture

Organize application code by feature and then by responsibility:

```text
lib/
  app/
  core/
  design/
  shared/
  features/<feature>/
    presentation/
    application/
    domain/
    data/
```

- `presentation` contains screens, widgets, controllers, and UI adaptation.
- `application` coordinates use cases and commands.
- `domain` contains framework-independent entities, value objects, policies, reducers, and game rules.
- `data` contains Drift implementations, mappings, local data sources, and external adapters.
- Dependencies point inward. Domain code must not import Flutter, Riverpod, Drift, Dio, or Scryfall-specific models.
- Depend on repository and service interfaces at domain/application boundaries. Keep implementations in the data layer.
- Keep features independent. Move code to `shared` or `core` only after it has a genuine cross-feature responsibility, not in anticipation of reuse.
- Keep widgets free of business rules and persistence concerns. Riverpod coordinates dependencies and application/UI state; `GameEngine` owns game rules and deterministic event generation.

Live-game changes are event-driven. Every meaningful action must be represented by a versioned domain event, persisted atomically, reducible deterministically, recoverable after restart, and compatible with undo. Do not directly mutate materialized game state as a shortcut. Decks and settings may use ordinary CRUD.

## Idiomatic Dart

Follow the current Dart language guidance and the lints enabled by `flutter_lints`.

- Use `UpperCamelCase` for types and extensions, `lowerCamelCase` for members and variables, and `lowercase_with_underscores` for files, directories, libraries, and import prefixes.
- Prefer clear domain vocabulary over abbreviations. Name booleans as predicates such as `isActive`, `hasExpired`, or `canAdvance`.
- Prefer immutable values: `final` locals and fields, `const` constructors and literals, and immutable collections or defensive copies at domain boundaries.
- Use sound null safety deliberately. Model absence with nullable types only when absence is valid; do not use `!` to silence uncertain state.
- Prefer exhaustive `switch` expressions, sealed class hierarchies, records, patterns, and enhanced enums when they make a closed domain model clearer.
- Use named parameters for boolean values and calls with several same-typed arguments. Mark required named parameters with `required`.
- Keep functions small and single-purpose. Return early when that reduces nesting.
- Avoid primitive obsession in the domain. Introduce value objects for identifiers, life changes, turn positions, durations, and similar concepts when they carry invariants.
- Avoid mutable global state, service locators, utility grab bags, and static state used as dependency injection.
- Do not catch `Exception` only to ignore it. Convert infrastructure failures into explicit application/domain results at boundaries, preserving useful context without exposing secrets or user data.
- Public APIs need `///` documentation when their purpose, invariants, ownership, or failure behavior is not obvious. Comments should explain why, not restate the code.
- Keep imports sorted by the formatter/lints, use package imports across `lib/`, and avoid importing another package's `src/` directory.
- Never edit generated files by hand. Keep generator inputs and generated outputs consistent with the repository's chosen source-control policy.

Follow the current Dart language style and the lints configured in
`analysis_options.yaml`. Do not introduce formatting or naming conventions that
conflict with the project's formatter or analyzer.

## Flutter UI

- Prefer small, composable widgets over large `build` methods or helper methods that return widgets. Extract a widget when it has its own semantics, state, layout responsibility, or meaningful rebuild boundary.
- Use `StatelessWidget` by default. Introduce local state only for genuinely ephemeral UI concerns; place business and workflow state in the appropriate application layer.
- Use `const` widgets whenever their inputs are compile-time constants. Do not add `const` mechanically when it harms correctness or readability.
- Keep `build` methods pure and inexpensive. Do not perform I/O, mutate state, start timers, or call repositories during build.
- Use `Theme.of(context)`, semantic design tokens, and reusable components from `lib/design/`. Do not scatter hard-coded colors, spacing, typography, durations, or decoration values.
- Account for narrow screens, landscape layouts, safe areas, keyboard insets, and supported text scaling. Do not assume a single device size.
- After an asynchronous gap, do not use a stale `BuildContext`; check `context.mounted` or structure the work so context is no longer needed.
- Dispose controllers, focus nodes, animation controllers, stream subscriptions, and timers owned by a state object.
- Assign keys when identity matters across reordering, animation, or state preservation. Do not add keys without an identity requirement.
- Keep animations purposeful, interruptible where appropriate, and compatible with reduced-motion settings.

## State and asynchronous work

- Providers expose dependencies and state; they do not replace domain objects or become containers for unrelated logic.
- Scope providers narrowly and model loading, success, empty, offline, and failure states explicitly.
- Cancel or supersede obsolete requests such as card searches. Debounce user input at the application boundary, not inside a rendering method.
- Never let network availability block an active game. Persist meaningful local actions before presenting them as durable.
- Do not retain `BuildContext`, widget instances, or presentation callbacks in providers, repositories, or domain objects.

## Persistence and Scryfall

- SQLite/Drift owns application data. Scryfall is an upstream card reference source, not the operational database.
- Keep raw Scryfall JSON and Dio types inside the adapter. UI and domain layers consume normalized application models.
- Card names are display data, never identifiers. Preserve Oracle IDs, printing IDs, faces, and migration behavior as described in `docs/data-model.md`.
- Schema changes require explicit migrations and tests from the previously supported schema. Event payload changes require schema versioning and upcasting or a documented compatibility strategy.
- Persist emitted game events and related state changes atomically. Snapshots accelerate recovery but do not replace the event history.
- Cache selected-deck data for offline use. Centralize request headers, throttling, cancellation, retry/backoff, and policy compliance in the card-data adapter.
- Do not log deck contents, game histories, access tokens, or other private user data by default.

## Accessibility and product quality

Accessibility is part of the definition of done, not a later enhancement.

- Give interactive controls meaningful semantics, labels, roles, values, and hints.
- Announce life totals and changes with the relevant player identity.
- Never communicate state by color alone. Preserve readable contrast and high-contrast behavior.
- Support text scaling, large touch targets, logical focus order, screen readers, reduced motion, and optional haptics.
- Keep card name and Oracle text available as structured accessible text; artwork is not an accessible substitute.
- Make destructive and high-impact actions confirmable or immediately undoable.
- Minimize interactions during live play. Every new in-game step should justify the bookkeeping it adds.

## Testing

Match tests to the risk and layer being changed:

- Unit-test domain policies, commands, reducers, value objects, expiry rules, and validation without Flutter bindings or live services.
- Test every game-state transition, deterministic consequence, undo path, and event upcaster affected by a change.
- Use Drift integration tests for repositories, transactions, migrations, snapshots, and recovery.
- Use fixtures and fakes for Scryfall behavior, including multi-faced cards, cancellation, throttling, cache hits, missing fields, and identifier migrations. Normal CI must not depend on live Scryfall access.
- Use widget tests for interaction and semantics; add golden tests only for stable, visually important states.
- Add end-to-end coverage for critical flows such as game setup, gameplay, termination/recovery, and deck import when the infrastructure exists.
- Prefer behavior-focused test names and Arrange–Act–Assert structure. Tests must be deterministic and independent of execution order, wall-clock timing, locale, network, and local machine state.

Do not update expectations merely because a test fails. First establish whether the implementation or the expectation is wrong.

## Dependencies and platform code

- Prefer the Dart and Flutter SDKs before adding a package. New dependencies need a concrete use case, active maintenance, compatible licensing, and acceptable mobile-size/platform impact.
- Keep platform-specific code behind a Dart interface and test the platform-independent behavior separately.
- Changes under `android/` or `ios/` must preserve the Flutter application's package identity, signing assumptions, minimum supported versions, and the unaffected platform.
- Never commit credentials, signing material, local SDK paths, or machine-specific configuration.

## Change discipline

- Keep changes focused. Do not reformat, rename, or refactor unrelated code.
- Preserve user changes already present in the worktree.
- If an implementation changes an accepted architectural decision:
  - do not silently modify it
  - create or update an ADR
  - explain the tradeoffs
- Use Conventional Commit-style PR titles: `type(optional-scope): concise description`.
- A change is complete when formatting, analysis, and relevant tests pass; architectural boundaries remain intact; offline/recovery and accessibility implications are handled; migrations are safe; and documentation is current.

## GitHub issues and implementation branches

Create or update a GitHub issue before beginning a non-trivial implementation unless the user explicitly asks to work without one. Search for an existing issue first and avoid duplicates. Issue titles use the repository's Conventional Commit vocabulary, for example `feat(game): add turn progression` or `chore(docs): clarify recovery policy`.

Every issue created by an agent must contain these sections:

- **Description** — the user or product problem, intended outcome, and relevant context.
- **Suggested solution** — a proposed implementation direction and important constraints; distinguish it from fixed requirements when alternatives remain open.
- **Scope / affected files** — the expected features, layers, packages, documents, or file paths. Mark genuinely unknown paths as discovery work rather than inventing precision.
- **Acceptance criteria** — observable checkbox criteria, including appropriate tests, offline/recovery, accessibility, migration, or documentation requirements.

When creating or maintaining an issue:

- Apply all matching labels from `.github/labels.yml`, including status, type, priority, and affected area. Do not add unrelated labels.
- Assign the most specific available milestone from `.github/milestones.yml`; milestones express delivery order, not release version. Leave the milestone empty only when no current milestone fits.
- Add the issue to the relevant GitHub Project. The repository's delivery project is normally appropriate; if the relevant project is unclear, leave the issue unassigned rather than guessing.
- Maintain native GitHub issue dependency relationships. Use **blocked by** for prerequisites and **blocking** for work that cannot start until the current issue is complete. Keep relationships accurate when scope changes so the dependency graph communicates a real implementation order.
- Prefer creating sub-issues for larger features or epics instead of putting all work into a single issue. Use a parent issue to capture the overall goal, roadmap, and completion status, and create sub-issues for independently implementable workstreams. Link them using GitHub's native parent/sub-issue relationships, and keep dependencies between sub-issues accurate.

Before implementation, inspect the issue's acceptance criteria, dependencies, and current worktree. Work on a dedicated branch:

- For an issue, use `<type>/<issue-number>-<short-kebab-description>`, for example `feat/12-recoverable-game-loop`.
- Without an issue, use `<type>/<short-kebab-description>`, for example `chore/update-agent-guidance`.
- Branch from the repository's active integration branch, normally `develop`, unless the issue or user specifies another base. Confirm the current branch and worktree state first; do not switch branches over unrelated uncommitted changes without user direction.
- Create and switch with `git switch -c <branch-name> <base-branch>` when the branch does not exist, or switch to the existing branch with `git switch <branch-name>`.
- Implement only the issue scope, preserve unrelated worktree changes, and run the relevant checks before handoff.
- Never stage, commit, push, open a pull request, or otherwise publish changes unless the user explicitly asks for that action.

When multiple architectural solutions exist:

- preserve existing patterns
- do not introduce a new architectural style
- propose architectural changes before implementing them

## Decision Making

When implementing a feature:

1. Search for an existing implementation first.
2. Reuse existing abstractions.
3. Prefer extending the architecture over replacing it.
4. Preserve consistency across features.
5. If documentation and code disagree, treat documentation as the intended architecture unless clearly outdated.
