import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:injectable/injectable.dart';

part 'sentri_database.g.dart';

// --- Tables ---

class CallerCache extends Table {
  TextColumn get phoneNumber => text()();
  JsonColumn get payload => json()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {phoneNumber};
}

class BlockedNumbers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get phoneNumber => text().unique()();
  TextColumn get label => text().nullable()();
  BoolColumn get isPermanent => boolean().withDefault(const Constant(true))();
  DateTimeColumn get blockedAt => dateTime()();
}

class CallRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get phoneNumber => text()();
  TextColumn get name => text().nullable()();
  IntColumn get riskScore => integer().withDefault(const Constant(0))();
  TextColumn get riskCategory => text().withDefault(const Constant('unknown'))();
  BoolColumn get wasBlocked => boolean().withDefault(const Constant(false))();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  DateTimeColumn get timestamp => dateTime()();
}

class UserSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get value => text()();
}

// --- Database ---

@singleton
@DriftDatabase(tables: [CallerCache, BlockedNumbers, CallRecords, UserSettings])
class SentriDatabase extends _$SentriDatabase {
  SentriDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'sentri');
  }
}
