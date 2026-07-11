# OrbiGathering documentation

OrbiGathering is a local-first mobile companion for physical Magic: The Gathering games. The documentation is organized by concern so product intent, domain rules, implementation decisions, and delivery planning can evolve independently.

## Documentation map

- [Product vision](vision.md) — what OrbiGathering is, whom it serves, its boundaries, principles, and success measures.
- [Architecture](architecture.md) — application structure, game engine, persistence, offline behavior, and the path to synchronized multiplayer.
- [Technology stack](tech-stack.md) — the Flutter/Dart stack and the rationale for each major dependency.
- [UI design system](ui-design-system.md) — visual direction, interaction principles, reusable components, motion, layouts, and accessibility.
- [Gameplay model](gameplay.md) — supported Magic concepts, formats, turn flow, counters, reminders, effects, and game-facing features.
- [Data model](data-model.md) — application entities, relationships, event envelope, snapshots, and representative schemas.
- [Scryfall integration](api.md) — card-data access, caching, rate limiting, images, identifiers, bulk data, and the `CardCatalog` boundary.
- [Roadmap](roadmap.md) — Version 1 scope, phased delivery, release criteria, Version 2 multiplayer, and later ideas.
- [Release process](release.md) — version sources, Conventional Commit mapping, pre-1.0 policy, and the release workflow.

## Architecture decision records

- [ADR-001: Use Flutter](adr/adr-001-use-flutter.md)
- [ADR-002: Use Scryfall](adr/adr-002-use-scryfall.md)
- [ADR-003: Use event-driven local-first game state](adr/adr-003-event-driven-game-state.md)
- [ADR-004: Use projections, cursor-based undo, and file-backed card-image caching](adr/adr-004-live-state-and-card-cache.md)

## Reading paths

New contributors should start with the [product vision](vision.md), then read [gameplay](gameplay.md), [architecture](architecture.md), and [technology stack](tech-stack.md). Designers can start with the [UI design system](ui-design-system.md). Work involving cards or decks should also consult the [Scryfall integration](api.md) and [data model](data-model.md).
