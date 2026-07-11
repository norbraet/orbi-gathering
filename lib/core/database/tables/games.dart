import 'package:drift/drift.dart';

class Games extends Table {
  TextColumn get id => text()();
  TextColumn get status => text()();
  IntColumn get turnNumber => integer().withDefault(const Constant(0))();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
