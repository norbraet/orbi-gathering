# ADR-004: Use projections, cursor-based undo, and file-backed card-image caching

## Status

Accepted

## Context

Version 1 is an account-free, single-device application, but it still needs durable local storage for decks, games, preferences, card metadata, and recovery. The event-driven game model also needs a concrete undo and recovery strategy before implementation begins. Separately, card artwork improves deck and card browsing but is too large and too volatile to store in SQLite or bundle in the application.

## Decision

- SQLite/Drift is the Version 1 operational database. “No backend” means no remote service, authentication, cloud storage, or multiplayer synchronization; it does not mean no database.
- For a live game, append-only domain events are the source of truth. Current game, player, counter, reminder, and effect records are projections, persisted atomically with each emitted event batch.
- Version 1 persists an active-history cursor. Undo and redo move that cursor without deleting historical events. A new action after undo creates a new active branch, while the replaced branch remains auditable.
- Snapshots are associated with a branch and event boundary. Recovery loads the latest compatible snapshot for the active branch and reduces events through the active cursor.
- Normalized Scryfall card metadata is stored in Drift. Card artwork is cached separately as bounded files, keyed by Scryfall printing identifier and requested image size. Artwork files may be evicted without affecting user-owned deck or game data.

## Consequences

- Version 1 can create and reopen decks and games completely locally, without a backend.
- Live-state recovery, undo, redo, and debugging share one deterministic model; projections remain query-efficient without becoming a second mutable source of truth.
- Branching adds storage and reducer-test complexity, but avoids destructive history and makes later synchronization decisions explicit.
- Image storage stays bounded and avoids database bloat, but offline card-art availability is best-effort after eviction; structured card data remains available.
- Repositories must expose transactions that persist event batches, cursor updates, snapshots, and projections together. Tests must cover undo, redo, branch creation after undo, projection consistency, and restart recovery.
