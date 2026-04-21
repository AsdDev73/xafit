package com.example.xafit

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.example.xafit.R

/**
 * XafitWidgetProvider — BroadcastReceiver del widget de pantalla de inicio.
 *
 * Android llama a [onUpdate] cada vez que hay que redibujar el widget:
 * - Al añadir el widget a la pantalla de inicio por primera vez.
 * - Cada [updatePeriodMillis] definido en xafit_widget_info.xml (30 min).
 * - Cuando la app llama a HomeWidget.updateWidget() desde Dart.
 *
 * Los datos los lee de SharedPreferences, donde los guarda home_widget
 * a través de HomeWidgetService.instance.updateSummaryWidget().
 *
 * Las claves deben coincidir EXACTAMENTE con las definidas en
 * lib/services/home_widget_service.dart (_WidgetKeys).
 */
class XafitWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Actualizamos cada instancia del widget que haya en el launcher.
        // El usuario puede añadir el mismo widget varias veces con distintos tamaños.
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    companion object {

        /**
         * Nombre del fichero de SharedPreferences donde home_widget guarda los datos.
         * home_widget usa por defecto el package name de la app como nombre del fichero.
         */
        private const val PREFS_NAME = "com.example.xafit"

        // Claves — deben ser idénticas a _WidgetKeys en home_widget_service.dart
        private const val KEY_WEEKLY_SESSIONS = "weekly_sessions"
        private const val KEY_WEEKLY_VOLUME = "weekly_volume"
        private const val KEY_LAST_EXERCISE = "last_exercise"
        private const val KEY_LAST_DATE = "last_session_date"
        private const val KEY_IS_ACTIVE = "is_workout_active"

        /**
         * Lee los datos de SharedPreferences y actualiza las vistas del widget.
         */
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int
        ) {
            val prefs: SharedPreferences = context.getSharedPreferences(
                PREFS_NAME,
                Context.MODE_PRIVATE
            )

            // Leemos los datos guardados por HomeWidgetService desde Dart.
            // Si no hay datos aún, usamos valores por defecto.
            val weeklySessions = prefs.getInt(KEY_WEEKLY_SESSIONS, 0)
            val weeklyVolume = prefs.getString(KEY_WEEKLY_VOLUME, "0 kg") ?: "0 kg"
            val lastExercise = prefs.getString(
                KEY_LAST_EXERCISE,
                "Sin entrenamientos aún"
            ) ?: "Sin entrenamientos aún"
            val lastDate = prefs.getString(KEY_LAST_DATE, "") ?: ""
            val isActive = prefs.getBoolean(KEY_IS_ACTIVE, false)

            // RemoteViews es el sistema de vistas de Android para widgets.
            // Solo podemos actualizar vistas por su id, no con lógica compleja.
            val views = RemoteViews(context.packageName, R.layout.xafit_widget)

            if (isActive) {
                // Si hay un entreno en curso mostramos un estado diferente
                views.setTextViewText(R.id.widget_weekly_sessions, "●")
                views.setTextViewText(R.id.widget_weekly_volume, "En curso")
                views.setTextViewText(R.id.widget_last_exercise, lastExercise)
                views.setTextViewText(R.id.widget_last_date, "Ahora")
            } else {
                // Estado normal: resumen semanal
                views.setTextViewText(R.id.widget_weekly_sessions, weeklySessions.toString())
                views.setTextViewText(R.id.widget_weekly_volume, weeklyVolume)
                views.setTextViewText(R.id.widget_last_exercise, lastExercise)
                views.setTextViewText(R.id.widget_last_date, lastDate)
            }

            // Aplicamos los cambios al widget
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}