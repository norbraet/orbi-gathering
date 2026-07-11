# Technology stack

The current platform decision is Flutter. An earlier brainstorming recommendation for React Native, Expo, TypeScript, XState, and TanStack Query is superseded by the dedicated Flutter architecture described here and in [ADR-001](adr/adr-001-use-flutter.md).

## Framework: Flutter

OrbiGathering is neither a conventional CRUD app nor a real-time game engine. It needs a polished, animated, custom tabletop interface alongside strong offline behavior. Flutter provides one Android/iOS codebase, consistent rendering, precise control of custom UI, high-performance animation, `CustomPainter`, and a mature mobile ecosystem.

The goal is a premium fantasy-game interface that still behaves like an excellent mobile application.

## Language: Dart

Dart is Flutter's first-class language and supports sound null safety, static analysis, immutable domain modeling, asynchronous I/O, and code generation. Strict analysis should be enabled from the technical-foundation phase.

## State and dependency management: Riverpod

Riverpod provides dependency injection, application-state composition, testable providers, and lifecycle-aware asynchronous state. It should coordinate repositories and screen state, while the domain-specific `GameEngine` remains responsible for game rules and event generation.

The project distinguishes:

- UI state, such as selections and open panels;
- application state, such as repositories and deck searches;
- game state, derived by the engine from snapshots and events.

## Persistence: SQLite and Drift

SQLite offers durable, transactional local storage on both target platforms. Drift adds typed queries, migrations, reactive streams, and testable repository implementations. It stores decks, entries, cached cards, games, players, reminders, effects, events, snapshots, and settings.

Durability is a product requirement: active state is persisted after every meaningful action and can be restored after termination or restart.

## Card images: on-device file cache

Card metadata belongs in Drift, while card artwork is cached as files on the device. The image-cache implementation is kept behind the card presentation/data boundary. It keys files by the Scryfall printing identifier and requested image size, uses bounded disk storage with eviction, and honors low-data and image-disabled settings. Artwork bytes are not stored as SQLite blobs or bundled wholesale into the app.

## Networking: Dio

Dio supplies cancellation, interceptors, timeouts, headers, error handling, and request coordination needed by the Scryfall adapter. Search requests must be debounced, superseded calls cancelled, and endpoint limits enforced centrally. Details live in [Scryfall integration](api.md).

## Navigation: GoRouter

GoRouter provides declarative navigation, deep-link support, nested routes, and route guards while fitting Flutter's navigation model. It can represent home, deck, game, card-detail, and settings flows without putting navigation in domain code.

## Secure storage: Flutter Secure Storage

Version 1 has no account and should have few or no secrets. Flutter Secure Storage is reserved for sensitive device tokens or credentials introduced by optional services; ordinary decks, games, and settings belong in SQLite. It should not be used as a general database.

## Animation and gestures

Use Flutter's animation framework for routine transitions and feedback, `CustomPainter` for signature visuals such as the life orb, and Rive only for selected premium animations whose value justifies an asset and runtime dependency. Motion must communicate state and honor reduced-motion preferences; see the [UI design system](ui-design-system.md).

## Internal design system

Build reusable Orbi components rather than adopting a large UI component library. Flutter primitives remain available beneath `OrbiButton`, `OrbiPanel`, `PlayerPanel`, `LifeOrb`, and related components, ensuring consistent behavior and accessibility without visually defaulting to Material.

## Testing strategy

- Unit tests for domain logic, engine commands, reducers, expiry rules, and validation.
- Transition tests for detailed and compact turn flow.
- Drift integration and migration tests.
- Contract tests for normalized Scryfall data, caching, throttling, and error handling.
- Recovery, snapshot, undo, and reminder-scheduling tests.
- Widget and golden tests for critical states and accessibility variants.
- End-to-end tests for game setup, complete gameplay, termination/recovery, and deck import.

Automated tests run in continuous integration from the technical-foundation phase. Live Scryfall access is replaced by fixtures and fakes except in explicitly separated integration checks.

## Stack summary

```text
Framework:        Flutter
Language:         Dart
Navigation:       GoRouter
State/DI:         Riverpod
Database:         SQLite + Drift
Networking:       Dio
Secure storage:   Flutter Secure Storage
Animations:       Flutter animations, selected Rive, CustomPainter
Card source:      Scryfall API
Card images:      On-device bounded file cache
Architecture:     Local-first, feature-driven, event-oriented
Backend/auth:     None required for Version 1
```
