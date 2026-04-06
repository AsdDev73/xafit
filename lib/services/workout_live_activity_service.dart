/// Datos que se enviarán a la Live Activity de iPhone cuando se implemente.
///
/// La Live Activity mostrará el entrenamiento en curso en la pantalla de
/// bloqueo y la Dynamic Island. Requiere iOS 16.1+ y configuración en Xcode.
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

/// Fachada para Live Activities de iPhone.
///
/// Actualmente en modo stub — no hace nada en ninguna plataforma.
/// Cuando se añada soporte iOS real, se implementará aquí con la
/// Widget Extension nativa en Xcode y el paquete live_activities.
class WorkoutLiveActivityService {
  WorkoutLiveActivityService._();

  static final WorkoutLiveActivityService instance =
      WorkoutLiveActivityService._();

  /// App Group que se configurará en Xcode al implementar Live Activities.
  static const String appGroupId = 'group.com.asddev73.xafit';

  Future<bool> areAvailable() async => false;

  Future<String?> startOrUpdate({
    required WorkoutLiveActivityPayload payload,
    String? currentActivityId,
  }) async =>
      currentActivityId;

  Future<void> end(String? activityId) async {}
}
