import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/game_events.dart';
import 'tables/games.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Games, GameEvents])
final class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'orbi_gathering'));

  @override
  int get schemaVersion => 1;
}
