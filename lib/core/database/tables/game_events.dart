import 'package:drift/drift.dart';

import 'games.dart';

class GameEvents extends Table {
  TextColumn get id => text()();
  TextColumn get gameId => text().references(Games, #id)();
  IntColumn get sequence => integer()();
  TextColumn get type => text()();
  TextColumn get payloadJson => text()();
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();
  DateTimeColumn get occurredAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {gameId, sequence},
  ];
}
