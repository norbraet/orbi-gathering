import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbi_gathering/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('stores and reads a game', () async {
    await database
        .into(database.games)
        .insert(
          GamesCompanion.insert(
            id: 'game-1',
            status: 'setup',
            updatedAt: DateTime.utc(2026, 7, 11),
          ),
        );

    final game = await (database.select(
      database.games,
    )..where((table) => table.id.equals('game-1'))).getSingle();

    expect(game.id, 'game-1');
    expect(game.status, 'setup');
  });

  test('stores a game event', () async {
    await database
        .into(database.games)
        .insert(
          GamesCompanion.insert(
            id: 'game-1',
            status: 'active',
            updatedAt: DateTime.utc(2026, 7, 11),
          ),
        );

    await database
        .into(database.gameEvents)
        .insert(
          GameEventsCompanion.insert(
            id: 'event-1',
            gameId: 'game-1',
            sequence: 1,
            type: 'GAME_STARTED',
            payloadJson: '{}',
            occurredAt: DateTime.utc(2026, 7, 11),
          ),
        );

    final events = await database.select(database.gameEvents).get();

    expect(events, hasLength(1));
    expect(events.single.gameId, 'game-1');
  });
}
