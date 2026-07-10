# Contributing to OrbiGathering

Start with `docs/vision.md`, then read the relevant gameplay, architecture, data-model, and UI guidance. OrbiGathering complements a physical Magic table; it is not a digital battlefield or authoritative rules engine.

## Before implementation

1. Search existing issues and discussions.
2. Use the appropriate issue form for non-trivial work.
3. Agree on scope and acceptance criteria before large changes.
4. Create or update an ADR when changing a durable architectural decision.

Issues move from `status: needs-triage` to `status: ready` only when the outcome, boundaries, dependencies, acceptance criteria, priority, area, and milestone are clear.

## Development workflow

- Keep pull requests focused and link the issue they resolve.
- Use the issue-form prefixes `feat:`, `fix:`, and `chore:`; GitHub uses the issue title when suggesting a development branch.
- Prefer branch names such as `feat/123-game-setup`, `fix/124-life-total`, and `refactor/125-event-reducer` when creating branches manually.
- Use Conventional Commit-style PR titles, such as `feat(game): persist phase changes`.
- Run `flutter analyze` and `flutter test` before requesting review.
- Add tests for domain rules, reducers, migrations, recovery, and external-data normalization.
- Use fixtures and fakes instead of live Scryfall calls in normal automated tests.
- Include screenshots or recordings for visible UI changes.

## Definition of done

Work is done when acceptance criteria pass, tests and analysis pass, affected documentation is current, accessibility and offline behavior are considered, migrations are safe, and the change is reviewable and reversible where appropriate.

## Triage cadence

Maintainers should review Inbox weekly, confirm milestone priorities, split oversized work, close obsolete requests, and keep only accepted work in Ready. Release milestones should be reviewed against the exit criteria in `docs/roadmap.md`.
