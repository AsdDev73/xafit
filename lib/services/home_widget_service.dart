import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import 'dashboard_service.dart';

/// Identificador del App Group compartido entre la app y el widget.
///
/// En Android este valor no se usa (el widget lee SharedPreferences directamente).
/// En iOS debe coincidir exactamente con el App Group configurado en Xcode.
/// Cuando llegues a configurar el widget en Xcode, crea un App Group con este id.
const String _appGroupId = 'group.com.example.xafit';

/// Nombre de la clase del widget provider en Android (Kotlin).
/// Debe coincidir exactamente con el nombre de la clase en XafitWidgetProvider.kt
const String _androidWidgetName = 'XafitWidgetProvider';

/// Nombre del widget en iOS (el nombre de la Widget Extension en Xcode).
/// Cuando lo configures en Xcode, usa exactamente este nombre.
const String _iOSWidgetName = 'XafitWidget';

/// Claves usadas para pasar datos al widget nativo.
/// Tanto el código Dart como el código nativo (Kotlin/Swift) deben usar
/// exactamente las mismas claves para leer y escribir los datos.
class _WidgetKeys {
  static const String weeklySessions = 'weekly_sessions';
  static const String weeklyVolume = 'weekly_volume';
  static const String lastExercise = 'last_exercise';
  static const String lastSessionDate = 'last_session_date';
  static const String isWorkoutActive = 'is_workout_active';
  static const String workoutStartedAt = 'workout_started_at';
  static const String workoutTitle = 'workout_title';
}

/// Servicio que sincroniza los datos de XaFit con el widget del home screen.
///
/// Cómo funciona:
/// 1. La app guarda datos en un almacenamiento compartido (SharedPreferences en Android,
///    App Group en iOS) usando las claves definidas en [_WidgetKeys].
/// 2. El widget nativo (Kotlin en Android, SwiftUI en iOS) lee esas claves
///    y las muestra en la pantalla de inicio.
/// 3. Cada vez que los datos cambian (nuevo entreno, nueva sesión guardada),
///    hay que llamar a [updateSummaryWidget] para refrescar el widget.
///
/// IMPORTANTE: El widget no se actualiza en tiempo real de forma automática.
/// Hay que llamar explícitamente a los métodos de este servicio cuando los
/// datos cambian.
class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  /// Inicializa home_widget. Llamar una vez al arrancar la app en main.dart.
  ///
  /// Registra el App Group (necesario en iOS) y el nombre del widget.
  Future<void> init() async {
    // En web no tiene sentido inicializar el widget
    if (kIsWeb) return;

    try {
      await HomeWidget.setAppGroupId(_appGroupId);
    } catch (e) {
      debugPrint('[HomeWidgetService] Error en init: $e');
    }
  }

  /// Actualiza el widget de resumen semanal con los datos del dashboard.
  ///
  /// Llamar después de:
  /// - Guardar un entrenamiento
  /// - Volver a la pantalla principal (por si los datos han cambiado)
  Future<void> updateSummaryWidget(DashboardOverview overview) async {
    if (kIsWeb) return;

    try {
      // Preparamos el texto del último ejercicio.
      // Si no hay sesiones guardadas, mostramos un mensaje neutral.
      final lastExercise = overview.lastSession != null &&
              overview.lastSession!.exercises.isNotEmpty
          ? overview.lastSession!.exercises.first.exerciseName
          : 'Sin entrenamientos aún';

      // Formateamos la fecha del último entrenamiento de forma legible.
      final lastDate = overview.lastSession != null
          ? _formatDate(overview.lastSession!.startedAt)
          : '';

      // Guardamos cada dato con su clave correspondiente.
      // El widget nativo leerá estas claves para mostrar la información.
      await HomeWidget.saveWidgetData<int>(
        _WidgetKeys.weeklySessions,
        overview.weeklySessions,
      );
      await HomeWidget.saveWidgetData<String>(
        _WidgetKeys.weeklyVolume,
        _formatVolume(overview.weeklyVolume),
      );
      await HomeWidget.saveWidgetData<String>(
        _WidgetKeys.lastExercise,
        lastExercise,
      );
      await HomeWidget.saveWidgetData<String>(
        _WidgetKeys.lastSessionDate,
        lastDate,
      );

      // Marcamos que no hay entreno activo (estado por defecto).
      // Esto se actualiza en [markWorkoutActive] cuando empieza un entreno.
      await HomeWidget.saveWidgetData<bool>(
        _WidgetKeys.isWorkoutActive,
        false,
      );

      // Pedimos al sistema que refresque el widget con los nuevos datos.
      await _triggerUpdate();
    } catch (e) {
      debugPrint('[HomeWidgetService] Error al actualizar widget: $e');
    }
  }

  /// Marca el widget como "entreno activo" y guarda la hora de inicio.
  ///
  /// Llamar cuando el usuario empieza un entrenamiento.
  /// El widget mostrará un estado diferente con el temporizador en marcha.
  Future<void> markWorkoutActive({
    required DateTime startedAt,
    required String title,
  }) async {
    if (kIsWeb) return;

    try {
      await HomeWidget.saveWidgetData<bool>(
        _WidgetKeys.isWorkoutActive,
        true,
      );
      // Guardamos el timestamp de inicio en milisegundos.
      // El widget nativo calculará el tiempo transcurrido a partir de este valor.
      await HomeWidget.saveWidgetData<int>(
        _WidgetKeys.workoutStartedAt,
        startedAt.millisecondsSinceEpoch,
      );
      await HomeWidget.saveWidgetData<String>(
        _WidgetKeys.workoutTitle,
        title,
      );

      await _triggerUpdate();
    } catch (e) {
      debugPrint('[HomeWidgetService] Error al marcar entreno activo: $e');
    }
  }

  /// Marca el widget como "sin entreno activo".
  ///
  /// Llamar cuando el usuario finaliza o descarta el entrenamiento.
  Future<void> markWorkoutInactive() async {
    if (kIsWeb) return;

    try {
      await HomeWidget.saveWidgetData<bool>(
        _WidgetKeys.isWorkoutActive,
        false,
      );
      await _triggerUpdate();
    } catch (e) {
      debugPrint('[HomeWidgetService] Error al marcar entreno inactivo: $e');
    }
  }

  /// Pide al sistema operativo que redibuje el widget con los datos guardados.
  ///
  /// En Android lanza un broadcast al XafitWidgetProvider.
  /// En iOS notifica a la WidgetKit extension para que se refresque.
  Future<void> _triggerUpdate() async {
    await HomeWidget.updateWidget(
      androidName: _androidWidgetName,
      iOSName: _iOSWidgetName,
    );
  }

  /// Formatea el volumen semanal de forma legible.
  /// Si supera 1000 kg lo muestra en toneladas (ej: "1.2 t").
  String _formatVolume(double volume) {
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)} t';
    }
    if (volume == volume.roundToDouble()) {
      return '${volume.toStringAsFixed(0)} kg';
    }
    return '${volume.toStringAsFixed(1)} kg';
  }

  /// Formatea una fecha de forma legible para el widget.
  /// Muestra "Hoy", "Ayer" o la fecha en formato corto.
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(dateDay).inDays;

    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    if (diff < 7) return 'Hace $diff días';
    return '${date.day}/${date.month}';
  }
}
