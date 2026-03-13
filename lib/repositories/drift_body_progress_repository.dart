import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/body_progress_entry.dart';
import 'body_progress_repository.dart';

class DriftBodyProgressRepository implements BodyProgressRepository {
  final AppDatabase db;

  DriftBodyProgressRepository(this.db);

  @override
  Future<List<BodyProgressEntry>> getEntries() async {
    final rows = await (db.select(
      db.bodyProgressRecords,
    )..orderBy([(tbl) => OrderingTerm.desc(tbl.date)])).get();

    return rows
        .map(
          (row) => BodyProgressEntry(
            id: row.id,
            date: row.date,
            weight: row.weight,
            waist: row.waist,
            chest: row.chest,
            arm: row.arm,
            thigh: row.thigh,
            bodyFat: row.bodyFat,
          ),
        )
        .toList();
  }

  @override
  Future<void> saveEntry(BodyProgressEntry entry) async {
    await db
        .into(db.bodyProgressRecords)
        .insertOnConflictUpdate(
          BodyProgressRecordsCompanion.insert(
            id: entry.id,
            date: entry.date,
            weight: entry.weight,
            waist: Value(entry.waist),
            chest: Value(entry.chest),
            arm: Value(entry.arm),
            thigh: Value(entry.thigh),
            bodyFat: Value(entry.bodyFat),
          ),
        );
  }

  @override
  Future<void> deleteEntry(String entryId) async {
    await (db.delete(
      db.bodyProgressRecords,
    )..where((tbl) => tbl.id.equals(entryId))).go();
  }

  @override
  Future<void> clearAllEntries() async {
    await db.delete(db.bodyProgressRecords).go();
  }
}
