import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class WorkoutSessions extends Table {
  TextColumn get id => text()();
  TextColumn get routineId => text()();
  TextColumn get routineName => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime()();
  IntColumn get durationSeconds => integer()();
  RealColumn get totalVolume => real()();
  TextColumn get sessionTagsJson => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

class WorkoutExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionId => text()();
  TextColumn get exerciseId => text()();
  TextColumn get exerciseName => text()();
  TextColumn get muscleGroup => text()();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer()();
}

class WorkoutSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutExerciseId => integer()();
  IntColumn get setNumber => integer()();
  IntColumn get reps => integer()();
  RealColumn get weight => real()();
  IntColumn get restSeconds => integer()();
  DateTimeColumn get createdAt => dateTime()();
}

class ProfileRecords extends Table {
  TextColumn get id => text()();
  TextColumn get alias => text()();
  TextColumn get goal => text()();
  RealColumn get heightCm => real().nullable()();
  RealColumn get targetWeight => real().nullable()();
  IntColumn get age => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class BodyProgressRecords extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()();
  RealColumn get weight => real()();
  RealColumn get waist => real().nullable()();
  RealColumn get chest => real().nullable()();
  RealColumn get arm => real().nullable()();
  RealColumn get thigh => real().nullable()();
  RealColumn get bodyFat => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    WorkoutSessions,
    WorkoutExercises,
    WorkoutSets,
    ProfileRecords,
    BodyProgressRecords,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(profileRecords);
        await m.createTable(bodyProgressRecords);
      }
    },
  );
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'xafit_db',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.dart.js'),
    ),
  );
}
