import 'package:flutter/foundation.dart';
import 'package:live_activities/live_activities.dart';

/// Datos que enviamos a la Live Activity de iPhone.
///
/// Guardamos fechas reales en milisegundos porque luego, en SwiftUI,
/// podemos pintarlas como temporizador vivo en la pantalla de bloqueo.
class WorkoutLiveActivityPayload {
  final String customId;
  final String title;
  final DateTime workoutStartedAt;
  final bool isResting;
  final DateTime? restStartedAt;
  final String currentExerciseName;
  final int exercisesCount;
  final int setsCount;

  const WorkoutLiveActivityPayload({
    required this.customId,
    required this.title,
    required this.workoutStartedAt,
    required this.isResting,
    required this.restStartedAt,
    required this.currentExerciseName,
    required this.exercisesCount,
    required this.setsCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'workoutStartedAtMs': workoutStartedAt.millisecondsSinceEpoch,
      'isResting': isResting,
      'restStartedAtMs': restStartedAt?.millisecondsSinceEpoch ?? 0,
      'currentExerciseName': currentExerciseName,
      'exercisesCount': exercisesCount,
      'setsCount': setsCount,
    };
  }
}

/// Fachada simple para crear, actualizar y cerrar la Live Activity.
///
/// Esta clase no rompe Android/Web porque, fuera de iOS, simplemente devuelve
/// sin hacer nada. El render real en pantalla de bloqueo se completa más tarde
/// con la Widget Extension nativa en Xcode.
class WorkoutLiveActivityService {
  WorkoutLiveActivityService._();

  static final WorkoutLiveActivityService instance =
      WorkoutLiveActivityService._();

  /// Pon aquí exactamente el mismo App Group que configurarás en Xcode.
  static const String appGroupId = 'group.com.asddev73.xafit';

  final LiveActivities _plugin = LiveActivities();
  bool _initialized = false;

  bool get _isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _plugin.init(appGroupId: appGroupId);
    _initialized = true;
  }

  Future<bool> areAvailable() async {
    if (!_isSupportedPlatform) return false;

    try {
      await _ensureInitialized();

      final supported = await _plugin.areActivitiesSupported();
      if (!supported) return false;

      return await _plugin.areActivitiesEnabled();
    } catch (_) {
      return false;
    }
  }

  Future<String?> startOrUpdate({
    required WorkoutLiveActivityPayload payload,
    String? currentActivityId,
  }) async {
    if (!await areAvailable()) {
      return currentActivityId;
    }

    final data = payload.toMap();

    if (currentActivityId != null && currentActivityId.isNotEmpty) {
      try {
        await _plugin.updateActivity(currentActivityId, data);
        return currentActivityId;
      } catch (_) {
        // Si el id ya no existe, intentamos crear una nueva actividad.
      }
    }

    try {
      return await _plugin.createActivity(payload.customId, data);
    } catch (_) {
      return currentActivityId;
    }
  }

  Future<void> end(String? activityId) async {
    if (!_isSupportedPlatform) return;
    if (activityId == null || activityId.isEmpty) return;

    try {
      await _ensureInitialized();
      await _plugin.endActivity(activityId);
    } catch (_) {
      // No rompemos la app si la actividad ya no existe o el cierre falla.
    }
  }
}
