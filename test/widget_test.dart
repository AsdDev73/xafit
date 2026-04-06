import 'package:flutter_test/flutter_test.dart';
import 'package:xafit/models/workout_session.dart';

WorkoutSession _makeSession({
  String id = 'test-001',
  List<WorkoutExerciseRecord> exercises = const [],
  String? notes,
}) {
  final now = DateTime(2024, 6, 1, 10, 0);
  return WorkoutSession(
    id: id,
    routineId: 'routine-1',
    routineName: 'Empuje',
    startedAt: now,
    finishedAt: now.add(const Duration(minutes: 60)),
    durationSeconds: 3600,
    exercises: exercises,
    totalVolume: 0,
    sessionTags: const [],
    notes: notes,
  );
}

WorkoutSetRecord _makeSet({int setNumber = 1, bool isWarmup = false}) {
  return WorkoutSetRecord(
    setNumber: setNumber,
    reps: 10,
    weight: 80,
    restSeconds: 90,
    createdAt: DateTime(2024, 6, 1),
    isWarmup: isWarmup,
  );
}

void main() {
  group('WorkoutSession', () {
    test('se crea correctamente con los datos esperados', () {
      final session = _makeSession();

      expect(session.id, 'test-001');
      expect(session.routineName, 'Empuje');
      expect(session.durationSeconds, 3600);
      expect(session.exercises, isEmpty);
    });

    test('totalExercises devuelve el número correcto', () {
      final exercise = WorkoutExerciseRecord(
        exerciseId: 'ex-1',
        exerciseName: 'Press banca',
        muscleGroup: 'Pecho',
        tags: const [],
        isCustom: false,
        sets: const [],
      );
      final session = _makeSession(exercises: [exercise]);

      expect(session.totalExercises, 1);
    });

    test('totalSets cuenta series de calentamiento y efectivas', () {
      final exercise = WorkoutExerciseRecord(
        exerciseId: 'ex-1',
        exerciseName: 'Press banca',
        muscleGroup: 'Pecho',
        tags: const [],
        isCustom: false,
        sets: [
          _makeSet(setNumber: 1, isWarmup: true),
          _makeSet(setNumber: 2),
          _makeSet(setNumber: 3),
        ],
      );
      final session = _makeSession(exercises: [exercise]);

      expect(session.totalSets, 3);
      expect(session.totalWarmupSets, 1);
      expect(session.totalWorkingSets, 2);
    });

    test('hasNotes es false cuando notes es null', () {
      final session = _makeSession(notes: null);
      expect(session.hasNotes, false);
    });

    test('hasNotes es true cuando hay notas', () {
      final session = _makeSession(notes: 'Buen entrenamiento');
      expect(session.hasNotes, true);
    });

    test('toMap y fromMap son consistentes', () {
      final session = _makeSession(id: 'round-trip');
      final map = session.toMap();
      final restored = WorkoutSession.fromMap(map);

      expect(restored.id, session.id);
      expect(restored.routineName, session.routineName);
      expect(restored.durationSeconds, session.durationSeconds);
    });
  });
}
