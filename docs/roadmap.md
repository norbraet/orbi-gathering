# Product roadmap

The roadmap protects the central product boundary: OrbiGathering is a smart game-state companion, not a rules engine, marketplace, social network, or digital battlefield. Dates are intentionally omitted until discovery and the first technical spike validate scope.

## Version 1 — local companion

Version 1 is account-free, offline-first, and single-device.

### M1.0 — Product discovery and prototype

- Play and observe several physical games, including a beginner and an experienced player.
- Record every item tracked outside physical cards.
- Confirm the exact format of the initial Angels deck.
- Produce the domain glossary, screen flow, data-model draft, and clickable dashboard prototype.
- Test whether detailed phase tracking helps or distracts and measure expected taps per turn.

### M1.1 — Technical foundation

- Bootstrap Flutter for iOS and Android with strict Dart analysis and GoRouter.
- Establish design tokens, error handling, logging, repositories, and CI.
- Add Drift schema/migrations and prove persistence across restarts.
- Build the Dio/Scryfall adapter with throttling, caching, cancellation, and test fixtures.

Exit criteria: both platforms launch; database state survives restarts; card search respects current API policy; automated tests run in CI.

### M1.2 — Deck library

- Deck list, creation/editing, duplicate, archive, and preferred printing.
- Fast card search, local cache, plain-text import/export, and manual match resolution.
- Main/sideboard sections, mana curve, color/type distribution, land count, and advisory validation.
- Correct handling for duplicate and multi-faced cards.

Exit criteria: a 60-card deck can be imported and reopened offline after initial loading; ambiguous matches can be resolved manually.

### M1.3 — Game companion MVP

- Configurable game setup and presets.
- Two-player and multiplayer life panels, generic counters, timer, and active-player tracking.
- Detailed/compact phase tracking through the domain engine.
- Domain events, undo/redo foundation, snapshots, and automatic recovery.

Exit criteria: a full tabletop game works without a deck; closing/reopening restores it; every important action can be undone.

### M1.4 — Reminders and effects

- Triggered and manual reminder creation.
- Active effects with deterministic and manual expiration.
- Create a reminder from a selected-deck/Scryfall card.
- Human-readable game history.

Exit criteria: “until end of turn” expires correctly; upkeep reminders target the correct player; history explains state changes.

### M1.5 — Release readiness

- Guided and compact modes, beginner glossary, orientation support, and haptics.
- Accessibility and high-contrast/reduced-motion review.
- Performance, crash recovery, offline, and migration testing.
- Privacy policy, delete-local-data flow, third-party inventory, and Scryfall attribution/policy review.
- Store assets and beta testing.

### Version 1 feature priorities

**Must:** local decks, Scryfall search, text import, setup, life, generic counters, active player, phases, timer, reminders, effects, undo, recovery, and offline selected-deck access.

**Should:** deck statistics, presets, commander counters, rulings, glossary, history, dark/high-contrast themes, landscape, haptics, export, and backup.

**Could:** home-screen widgets, QR deck import, cloud backup, account synchronization, shared links, advanced validation, and custom reminder templates.

## Version 2 — synchronized nearby sessions

### M2.0 — Synchronized sessions

Players create or join a room using a QR or short code. Each device displays owner-specific information plus synchronized public life totals, active player, phase, shared timer, effects, and counters. Devices keep local snapshots and exchange versioned, idempotent events through a lightweight relay backend.

Version 2 work includes:

- optional identity and room lifecycle;
- device/player assignment and host authority;
- server sequencing, duplicate rejection, and missing-event recovery;
- reconnect and conflict behavior;
- privacy rules for public versus device-owned state;
- synchronized life, counters, turn state, timers, and public effects;
- resilience testing under disconnect and clock differences.

Network-assisted sessions are preferred initially over direct Bluetooth peer-to-peer or Web Bluetooth. Direct nearby/offline transport remains an investigation, not a foundation.

## Version 3 — optional continuity and ecosystem

Version 3 is intentionally provisional and should be prioritized from Version 1/2 evidence. Candidates include optional accounts, encrypted cloud backup, multi-device deck/settings synchronization, shareable game summaries, a production bulk-data card index, and refined advanced-format support.

These capabilities must preserve account-free local play and avoid turning the product into a social network or marketplace.

## Future ideas

- Home-screen widgets and richer share/export formats.
- Voice actions, only if they reduce rather than add interaction cost.
- Direct offline nearby connectivity after a cross-platform technical evaluation.
- Custom reminder templates and richer deck-specific companion configuration.
- Advanced advisory deck validation.

## Explicit non-goals for Version 1

Camera/card recognition, automatic battlefield scanning, full hand tracking, executable rules logic, strategy advice, online matchmaking, public profiles/feeds, prices, collection valuation, trading, tournament pairing, full cloud sync, nearby device connections, voice control, and AI interpretation of arbitrary card interactions are postponed.

## First technical spikes

### Spike 1: event-driven game loop

1. Create a two-player game and show both life totals.
2. Advance phases.
3. Add an “until end of turn” effect.
4. End the turn and expire it automatically.
5. Persist every action as an event.
6. Close and reopen the app, restoring exact state.
7. Undo the end-turn action.

This validates the engine, event representation, Drift persistence, undo, recovery, and contextual UI.

### Spike 2: card-to-companion flow

Integrate one selected deck and create a reminder from a Scryfall card. This validates the boundary between upstream card knowledge and application-owned gameplay state.
