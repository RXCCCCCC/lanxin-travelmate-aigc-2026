import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class LocalUsers extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class MemoryCapsules extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn get scope => text()();
  TextColumn get source => text().withDefault(const Constant('agent'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class UserProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get profileJson => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class TripContexts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get destination => text()();
  TextColumn get contextJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ChatMessages extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  TextColumn get sender => text()();
  TextColumn get body => text().named('text')();
  TextColumn get avatarState => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ChatSummaries extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  TextColumn get summary => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AvatarStates extends Table {
  TextColumn get id => text()();
  IntColumn get energy => integer()();
  TextColumn get mood => text()();
  IntColumn get curiosity => integer()();
  IntColumn get rapport => integer()();
  IntColumn get affection => integer()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get triggerType => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  IntColumn get cooldownMinutes => integer().withDefault(const Constant(60))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PhotoCandidates extends Table {
  TextColumn get id => text()();
  TextColumn get location => text()();
  RealColumn get score => real()();
  TextColumn get description => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class TripReviews extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text()();
  TextColumn get reviewJson => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalSyncOperations extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get payloadJson => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [
  LocalUsers,
  MemoryCapsules,
  UserProfiles,
  TripContexts,
  ChatMessages,
  ChatSummaries,
  AvatarStates,
  Reminders,
  PhotoCandidates,
  TripReviews,
  LocalSyncOperations,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  static AppDatabase? _sharedInstance;

  static AppDatabase shared() {
    return _sharedInstance ??= AppDatabase();
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(localSyncOperations);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'lanxin_travelmate',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
