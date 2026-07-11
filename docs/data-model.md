# Data model

## Model boundaries

Application-owned data is persisted locally and remains separate from normalized Scryfall records. Decks and settings use conventional CRUD. Live games use snapshots plus subsequent immutable events. Identifiers are stable UUID-like values unless an upstream Scryfall identifier is explicitly named.

## Relationships

```text
Deck 1 ── * DeckEntry * ── 1 CardRecord

Game 1 ── * Player
Game 1 ── * GameEvent
Game 1 ── * GameSnapshot
Game 1 ── * Reminder
Game 1 ── * ActiveEffect
Game 1 ── * Counter

Player 0..1 ── * Reminder / ActiveEffect / Counter
CardRecord 0..1 ── * DeckEntry / Reminder / ActiveEffect
```

Some counters and effects are game-owned rather than player-owned. A selected deck association belongs to a player within a game and does not mutate the deck.

## Deck

```text
Deck
- id
- name
- format
- description
- createdAt
- updatedAt
- archivedAt
```

`archivedAt` is nullable. A deck owns ordered main-deck and sideboard entries and may later own reminder templates.

## DeckEntry

```text
DeckEntry
- deckId
- oracleId
- preferredScryfallCardId
- quantity
- section
- customSortOrder
- notes
```

`oracleId` identifies the conceptual card across ordinary printings; `preferredScryfallCardId` identifies the desired physical printing. Names are display data, never primary keys. `section` initially distinguishes main deck and sideboard.

## Player

```text
Player
- id
- gameId
- name
- seatOrder
- teamId
- startingLife
- currentLife
- selectedDeckId
- isLocallyManaged
```

Current life may be materialized for query speed but is derived from game initialization and subsequent events. `teamId` supports shared-team formats; `selectedDeckId` is optional.

## Game

```text
Game
- id
- presetId
- status
- activePlayerId
- turnNumber
- roundNumber
- currentPhase
- currentStep
- detailedPhaseTracking
- timerEnabled
- startedAt
- pausedAt
- endedAt
- updatedAt
- schemaVersion
- activeHistoryCursor
```

Live fields form the latest materialized state and must agree with the newest snapshot plus events through `activeHistoryCursor`. Status is setup, active, paused, or completed. They are projections, not an alternative source of truth.

## GameSnapshot

```text
GameSnapshot
- id
- gameId
- throughEventId
- throughSequence
- statePayload
- stateSchemaVersion
- createdAt
- branchId
```

A snapshot serializes complete derived state at a known event boundary and active-history branch. On recovery, the engine loads the latest compatible snapshot and reduces later active events through the cursor. Snapshot frequency is an implementation policy.

## GameEvent

The event envelope is designed for local use now and synchronization later:

```ts
type GameEvent = {
  id: string;
  gameId: string;
  actorDeviceId: string;
  actorPlayerId?: string;
  sequence?: number;
  occurredAt: string;
  type: GameEventType;
  payload: unknown;
  schemaVersion: number;
  parentEventId?: string;
};
```

`id` makes events idempotent. A local sequence provides deterministic order; a server-assigned sequence can be added in multiplayer. Payloads are discriminated and versioned in implementation rather than remaining untyped.

Initial event types include:

```text
GAME_STARTED
LIFE_CHANGED
COUNTER_CHANGED
PHASE_ADVANCED
TURN_ENDED
REMINDER_CREATED
REMINDER_COMPLETED
EFFECT_CREATED
EFFECT_EXPIRED
ACTIVE_PLAYER_CHANGED
GAME_PAUSED
GAME_RESUMED
GAME_ENDED
```

Representative history reads:

```text
Player A lost 3 life
Player B gained 2 life
Player A’s life was set to 10
```

Events form an append-only history. Version 1 persists an active-history cursor and branch relationship: undo and redo move the cursor without deleting events, while an action after undo starts a new active branch. Projections and snapshots describe only the active branch through its cursor. This preserves auditability and gives a deterministic recovery model; synchronization can later add server ordering without replacing it.

## Reminder

```text
Reminder
- id
- gameId
- ownerPlayerId
- title
- description
- triggerType
- triggerPlayerId
- triggerTurnOffset
- expirationBehavior
- repeatBehavior
- relatedOracleId
- relatedScryfallCardId
- createdAt
- completedAt
- status
```

Triggers cover next turn, upkeep, draw, beginning/end of combat, end step, end of current turn, a turn offset, and manual display. Card links are optional.

## ActiveEffect

```text
ActiveEffect
- id
- gameId
- ownerPlayerId
- affectedPlayerId
- affectedObjectLabel
- name
- sourceOracleId
- sourceScryfallCardId
- startTurn
- durationType
- expirationPhaseOrStep
- numericModifier
- notes
- status
- createdAt
- expiredAt
```

`affectedObjectLabel` is intentionally free-form so the app need not model battlefield objects. Duration types include end of turn, next turn, next upkeep, rest of game, while source remains, and manual.

## Counter

```text
Counter
- id
- gameId
- ownerPlayerId
- type
- name
- icon
- currentValue
- minimumValue
- increment
- color
- description
```

`ownerPlayerId` is nullable for game-wide state. Built-in types include poison, energy, experience, commander tax, commander damage by opposing commander, initiative, monarch, and day/night; custom values use the same shape. Commander damage may require an additional source-player or commander identifier in its typed metadata.

## Cached card records

Normalized card records include Scryfall printing ID, Oracle ID, set, collector number, language, faces, gameplay fields, image references, legality data, and cache timestamps. They are described in [Scryfall integration](api.md). The UI never persists or consumes raw Scryfall JSON directly.

## Storage and integrity rules

- Persist event batches and their materialized state transactionally.
- Foreign keys must prevent orphaned game-owned records.
- User deletion removes all local data, including cached associations and histories according to policy.
- Migrations cover Drift schema versions, event payload versions, and snapshot-state versions.
- Timestamps are stored in UTC and formatted in the UI.
- External card migrations may update references while retaining user selections and notes.
