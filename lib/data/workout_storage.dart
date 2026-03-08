import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/workout_session.dart';

class ExercisePerformanceSnapshot {
  final DateTime lastPerformedAt;
  final double lastWeight;
  final int lastReps;
  final double prWeight;
  final int prReps;
  final double bestSetVolume;

  const ExercisePerformanceSnapshot({
    required this.lastPerformedAt,
    required this.lastWeight,
    required this.lastReps,
    required this.prWeight,
    required this.prReps,
    required this.bestSetVolume,
  });
}

class _MutableExerciseSnapshot {
  DateTime? lastPerformedAt;
  double? lastWeight;
  int? lastReps;

  double? prWeight;
  int? prReps;

  double? bestSetVolume;

  void registerSet({
    required DateTime timestamp,
    required double weight,
    required int reps,
  }) {
    if (lastPerformedAt == null || timestamp.isAfter(lastPerformedAt!)) {
      lastPerformedAt = timestamp;
      lastWeight = weight;
      lastReps = reps;
    }

    final shouldUpdatePr =
        prWeight == null ||
        weight > prWeight! ||
        (weight == prWeight! && reps > (prReps ?? 0));

    if (shouldUpdatePr) {
      prWeight = weight;
      prReps = reps;
    }

    final setVolume = weight * reps;
    if (bestSetVolume == null || setVolume > bestSetVolume!) {
      bestSetVolume = setVolume;
    }
  }

  ExercisePerformanceSnapshot toSnapshot() {
    return ExercisePerformanceSnapshot(
      lastPerformedAt: lastPerformedAt!,
      lastWeight: lastWeight!,
      lastReps: lastReps!,
      prWeight: prWeight!,
      prReps: prReps!,
      bestSetVolume: bestSetVolume!,
    );
  }
}

class WorkoutStorage {
  static const String _sessionsKey = 'xafit_workout_sessions';

  static Future<List<WorkoutSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionsKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List;

    final sessions = decoded
        .map((item) => WorkoutSession.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sessions;
  }

  static Future<void> saveSession(WorkoutSession session) async {
    final sessions = await loadSessions();

    sessions.removeWhere((item) => item.id == session.id);
    sessions.insert(0, session);

    await _persistSessions(sessions);
  }

  static Future<void> deleteSession(String sessionId) async {
    final sessions = await loadSessions();
    sessions.removeWhere((item) => item.id == sessionId);
    await _persistSessions(sessions);
  }

  static Future<void> clearAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
  }

  static Future<Map<String, ExercisePerformanceSnapshot>>
  loadExerciseSnapshots() async {
    final sessions = await loadSessions();
    final Map<String, _MutableExerciseSnapshot> snapshots = {};

    for (final session in sessions) {
      for (final exercise in session.exercises) {
        if (exercise.sets.isEmpty) continue;

        final snapshot = snapshots.putIfAbsent(
          exercise.exerciseId,
          () => _MutableExerciseSnapshot(),
        );

        for (final set in exercise.sets) {
          snapshot.registerSet(
            timestamp: set.createdAt,
            weight: set.weight,
            reps: set.reps,
          );
        }
      }
    }

    return snapshots.map((key, value) => MapEntry(key, value.toSnapshot()));
  }

  static Future<void> _persistSessions(List<WorkoutSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(sessions.map((session) => session.toMap()).toList());
    await prefs.setString(_sessionsKey, raw);
  }
}
