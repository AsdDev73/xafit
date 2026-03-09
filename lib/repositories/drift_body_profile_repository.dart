import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/body_profile.dart' as model;
import 'body_profile_repository.dart';

class DriftBodyProfileRepository implements BodyProfileRepository {
  final AppDatabase db;

  static const String _mainProfileId = 'main';

  DriftBodyProfileRepository(this.db);

  @override
  Future<model.BodyProfile> getProfile() async {
    final row = await (db.select(
      db.profileRecords,
    )..where((tbl) => tbl.id.equals(_mainProfileId))).getSingleOrNull();

    if (row == null) {
      return model.BodyProfile.empty;
    }

    return model.BodyProfile(
      alias: row.alias,
      goal: row.goal,
      heightCm: row.heightCm,
      targetWeight: row.targetWeight,
      age: row.age,
    );
  }

  @override
  Future<void> saveProfile(model.BodyProfile profile) async {
    await db
        .into(db.profileRecords)
        .insertOnConflictUpdate(
          ProfileRecordsCompanion.insert(
            id: _mainProfileId,
            alias: profile.alias,
            goal: profile.goal,
            heightCm: Value(profile.heightCm),
            targetWeight: Value(profile.targetWeight),
            age: Value(profile.age),
          ),
        );
  }
}
