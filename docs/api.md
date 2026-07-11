# Scryfall integration

## Role and philosophy

Scryfall is the canonical upstream source for Magic card reference data, but it is not OrbiGathering's operational database. Application-owned decks, preferred printings, games, players, histories, counters, reminders, effects, settings, and synchronization metadata remain in local SQLite.

```text
Scryfall
    ↓
Card-data gateway and local cache
    ↓
Application database
    ↓
Deck builder and game companion
```

This boundary keeps games usable during network failures and protects the rest of the application from latency and API/schema changes. See [ADR-002](adr/adr-002-use-scryfall.md).

## Card catalog boundary

All Scryfall-specific behavior lives behind an internal interface. Dart implementation types may differ, but the capability boundary is:

```ts
interface CardCatalog {
  searchCards(query: string): Promise<CardSearchResult>;
  findCardByName(name: string): Promise<CardRecord | null>;
  getCardsByIdentifiers(identifiers: CardIdentifier[]): Promise<CardRecord[]>;
  getRulings(cardId: string): Promise<CardRuling[]>;
  refreshCatalog(): Promise<CatalogRefreshResult>;
}
```

Screens and domain services consume normalized `CardRecord` values, never raw Scryfall JSON. This supports tests without live calls, alternative caching, a future backend proxy or local index, schema adaptation, and possibly another source.

## Search and named-card access

Early releases may query Scryfall directly through a Dio-based adapter. Search input is debounced, superseded requests are cancelled, successful results are cached, and repeated card fetches are coalesced. Requests include Scryfall's currently required `User-Agent` and `Accept` headers.

The original research recorded a two-requests-per-second limit for card search and named-card endpoints. Treat this as an implementation ceiling only after checking current Scryfall documentation; policies must be reviewed again before public release. Central throttling, error handling, backoff, and any server-provided retry instructions belong in the adapter. Never make one API request per rendered list item.

Search results use thumbnails and normalized display data. Opening detail may fetch missing fields and rulings, then persist them. Selected-deck cards should already be cached for offline in-game lookup.

## Deck import and the collection endpoint

Plain-text import first parses quantities, names, sets, collector numbers, and main/sideboard markers locally. Resolve unique card references in batches through Scryfall's collection endpoint where practical. The original API research records a maximum of 75 identifiers per collection request, enough for most ordinary decks' unique cards; verify the current limit before release.

Unmatched or ambiguous entries are shown for manual resolution. Store stable identifiers after resolution so future opening does not depend on repeating name searches.

## Cache strategy

The local cache stores normalized metadata for saved-deck cards, recent searches, viewed details, preferred printings, and viewed rulings. Records include fetch/update timestamps and enough structured fields to render offline. Image caching is separate from metadata caching: artwork is a bounded on-device file cache, never raw SQLite blobs. Cache keys use the Scryfall printing ID and image size; the cache respects low-data and image-disabled settings and can evict old files under an explicit storage budget.

Cache policy should:

- return usable local results immediately where possible;
- refresh stale data opportunistically when online;
- avoid fetching an unchanged card repeatedly;
- keep game and deck access functional during failures;
- handle upstream card migrations and deleted or replaced records;
- make storage limits and eviction explicit.

Format legality can change, so validation is advisory and refreshable rather than permanently authoritative.

## Stable identity, printings, and faces

The model distinguishes conceptual card, physical printing, card face, and deck entry:

- `oracle_id` represents the underlying card across ordinary printings;
- Scryfall `id` represents a particular printing;
- `set`, `collector_number`, and `lang` help identify that printing;
- face records represent multi-faced layouts;
- a deck entry stores an Oracle ID plus an optional preferred Scryfall printing ID.

Card names are not keys: they contain punctuation, can be localized, and can describe multi-faced layouts. The synchronization layer must tolerate rare Scryfall card migrations and update references without losing quantities, notes, or preferred-printing intent.

## Card details and rulings

Normalized detail data supports name, image, mana cost, type line, Oracle text, power/toughness or loyalty, keywords, set and collector number, legalities, related faces, and attribution. Scryfall ruling objects can include Oracle rulings, release-note entries, and Scryfall notes.

The UI clearly separates:

- official Oracle text;
- published rulings;
- app-created beginner explanations;
- user-created notes.

App explanations must never look authoritative.

## Images

Use Scryfall-provided image URLs and image endpoints according to the current usage policy. Preserve original proportions and copyright/artist information; do not distort images or crop required attribution. Use thumbnails in lists and larger images only on detail screens. Cache recently used images locally as bounded files and provide low-data and image-disabled settings. The implementation should use the printing ID plus requested size as its cache key, revalidate URLs through card metadata, and allow old files to be evicted without affecting a deck or card record.

Do not package every image or printing in the application binary. Card artwork text is not an accessible substitute for structured card name and Oracle text.

## Bulk data

Scryfall publishes daily bulk exports. Bulk metadata is the preferred long-term basis for local search indexes, a backend card cache, deterministic imports, and reduced live-search dependence.

A later production pipeline may:

1. Download relevant bulk metadata in a backend job.
2. Normalize it into an application-specific card index.
3. Publish a compact searchable dataset.
4. update clients incrementally.
5. Continue serving image references under Scryfall's requirements.

Bulk refresh is not required for the initial direct-API release, but the `CardCatalog` abstraction must leave room for it.

## Failure and testing requirements

Network errors never interrupt active game tracking. The adapter exposes meaningful offline, throttled, not-found, validation, and transient-failure results. Tests use fixtures for multi-faced cards, printings, legality changes, deck collection batches, rulings, missing fields, throttling, cancellation, cache hits, and upstream identifier migration.

Before every public release, review current API limits, required headers, bulk-data guidance, image rules, attribution requirements, and terms instead of relying indefinitely on initial research.
