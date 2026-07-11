# Application architecture

## Architectural overview

OrbiGathering uses a local-first, feature-driven, event-oriented architecture. Physical battlefield state, companion-managed state, Scryfall reference data, and application-owned persistent data remain separate.

```text
Presentation
    ↓
Application commands
    ↓
GameEngine → GameSession → GameState
    ↓
Domain events
    ↓
Local persistence (snapshots + events)
    ↓
Optional synchronization adapter
```

The game workflow uses an explicit domain engine rather than a generic state-machine library. Deck editing and settings use conventional CRUD; event-based reconstruction is reserved for live games, where undo, recovery, replay, and future synchronization make it valuable. The event log is the durable source of truth for a live game. Tables that expose the latest game, player, reminder, effect, or counter state are projections: they are updated in the same database transaction as their event batch and are never an independent mutation path.

This decision is formalized in [ADR-003](adr/adr-003-event-driven-game-state.md).

## Layered, feature-driven structure

```text
lib/
  app/
  core/
  design/
  shared/
  features/
    cards/
    decks/
    game/
    reminders/
    effects/
    players/
    settings/
```

Each feature is divided where useful into:

```text
presentation/
application/
domain/
data/
```

- **Presentation** contains screens, widgets, and UI adaptation.
- **Application** coordinates use cases and commands.
- **Domain** contains framework-independent entities, policies, reducers, and the game engine.
- **Data** implements repositories, persistence mappings, and external adapters.

Domain code should not depend on Flutter widgets. Riverpod provides dependency injection and application state, not the rules of the game.

## Game engine

The core flow is:

```text
GameEngine
    ↓
GameSession
    ↓
GameState
    ↓
Domain Events
    ↓
UI
```

`GameEngine` validates a command against current state and emits one or more deterministic domain events. `GameSession` identifies the active game and owns its event stream and snapshot. `GameState` is a derived, immutable view consumed by the UI. Reducers apply events consistently.

Turn progression is a hierarchical finite-state domain model:

```text
game
├── setup
├── active
│   ├── beginning
│   │   ├── untap
│   │   ├── upkeep
│   │   └── draw
│   ├── firstMain
│   ├── combat
│   │   ├── beginning
│   │   ├── attackers
│   │   ├── blockers
│   │   ├── damage
│   │   └── ending
│   ├── secondMain
│   └── ending
│       ├── endStep
│       └── cleanup
├── paused
└── completed
```

The engine supports hierarchical phases, guarded transitions, timers, pause/resume, reminder activation, automatic cleanup, and later remote events. The detailed domain is documented in [gameplay](gameplay.md).

## Commands, events, and undo

Every meaningful live-game action becomes an append-only event, including life and counter changes, phase advancement, reminders, effect expiry, pause/resume, and game completion. A command may yield multiple events when consequences are deterministic; ending a turn can expire effects, reset resources, and change the active player in one transaction.

Undo must not destructively edit history. Version 1 uses an append-only event log plus a persisted active-history cursor. Recovery reduces events only through that cursor; undo moves it backward and redo moves it forward. If a new command follows undo, it starts a new active branch while the former branch remains auditable. Event schemas are versioned for migrations and future multiplayer compatibility. See [data model](data-model.md) for the event envelope and catalog.

## Persistence and recovery

SQLite through Drift stores decks, cached cards, games, players, effects, reminders, events, snapshots, and settings. Complete live-game state must never exist only in memory.

After each meaningful action:

1. Validate the command.
2. Persist emitted events, the active-history cursor, and affected projections atomically.
3. Update or periodically create a snapshot for the active branch.
4. Publish the derived state to the UI.

On launch, load the newest compatible snapshot and reduce subsequent events. This must recover from background termination, an operating-system kill, a restart, or a temporary crash. The home screen can then offer, for example:

```text
Resume game
Angels vs. Player 2
Turn 6 — First main phase
Last updated 4 minutes ago
```

Snapshots bound replay cost; events remain the audit trail. Drift migrations and event-schema upcasters must be tested.

## Repository pattern

Application and domain layers depend on repository interfaces rather than Drift tables, Dio responses, or Scryfall JSON. Representative boundaries include game, deck, settings, and `CardCatalog` repositories. Implementations coordinate local caches and remote sources while keeping failure and offline behavior explicit.

Scryfall-specific details are isolated in the [API integration](api.md). Never expose external card models directly to UI or domain code.

## Networking and offline support

Version 1 requires no backend or authentication. Dio handles Scryfall requests behind the card repository. Search is debounced and throttled; cached deck cards remain available offline. Network failure must not interrupt an active game.

Local persistence owns user data. Scryfall is upstream reference data, not the operational game database. “No backend” means no remote server, account, or synchronization service in Version 1; it does not mean the app has no database:

```text
Scryfall
    ↓
Card-data gateway and local cache
    ↓
Application database
    ↓
Deck builder and game companion
```

## Multiplayer preparation

Version 1 event identifiers, actor identifiers, sequence metadata, idempotency, and schema versions prepare for Version 2 without imposing remote infrastructure now.

The preferred Version 2 design is a network-assisted local session:

1. A host creates a room and displays a QR or short code.
2. Other devices join through a lightweight relay backend.
3. Devices retain local snapshots and exchange public game events.
4. Reconnecting clients request events after their last acknowledged sequence.
5. The server rejects duplicates and enforces basic authority.

A device normally updates its assigned player; the host manages turn order and settings; shared changes require permission. Private information stays on the owning device unless explicitly shared.

Direct Bluetooth peer-to-peer and Web Bluetooth are not architectural foundations. They have cross-platform, browser-support, conflict-handling, and debugging costs; direct nearby connectivity can be investigated later for offline environments.

## Testing architecture

Tests cover domain policies, game-engine transitions, event reducers and upcasting, snapshots, undo/redo, recovery, Drift repositories and migrations, Scryfall adapters, reminder scheduling, effect expiry, and end-to-end game flows. Fakes implement repository interfaces so domain tests never require live network access.
