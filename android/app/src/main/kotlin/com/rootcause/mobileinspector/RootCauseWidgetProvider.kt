package com.rootcause.mobileinspector

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Widget de pantalla de inicio: el semáforo sin abrir la app.
 *
 * Corre en el MISMO proceso que la app, así que lee directamente la
 * última línea del historial (`rootcause-history.jsonl`) — sin servicios
 * extra ni duplicar lógica. Se refresca tras cada captura (la app y el
 * Worker llaman `refreshWidget`) y con el ciclo periódico del launcher.
 */
class RootCauseWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) = updateAll(context)

    companion object {

        fun updateAll(context: Context) {
            try {
                val manager = AppWidgetManager.getInstance(context)
                val ids = manager.getAppWidgetIds(
                    ComponentName(context, RootCauseWidgetProvider::class.java),
                )
                if (ids.isEmpty()) return

                val views = RemoteViews(context.packageName, R.layout.rootcause_widget)
                val last = lastCapture(context)
                val spanish = spanishConfigured(context)
                if (last == null) {
                    views.setTextViewText(R.id.widget_dot, "●")
                    views.setTextColor(R.id.widget_dot, Color.GRAY)
                    views.setTextViewText(
                        R.id.widget_status,
                        if (spanish) "Sin capturas" else "No snapshots",
                    )
                    views.setTextViewText(R.id.widget_time, "—")
                } else {
                    val severity = last.optJSONObject("verdict")
                        ?.optString("severity") ?: "normal"
                    val score = last.optJSONObject("verdict")?.optInt("score") ?: 0
                    val time = SimpleDateFormat("HH:mm", Locale.getDefault())
                        .format(Date(last.optLong("timestampMillis")))
                    views.setTextViewText(R.id.widget_dot, "●")
                    views.setTextColor(
                        R.id.widget_dot,
                        when (severity) {
                            "critical" -> Color.rgb(0xE5, 0x39, 0x35)
                            "warning" -> Color.rgb(0xFB, 0x8C, 0x00)
                            else -> Color.rgb(0x43, 0xA0, 0x47)
                        },
                    )
                    views.setTextViewText(
                        R.id.widget_status,
                        if (spanish) "Puntaje $score" else "Score $score",
                    )
                    views.setTextViewText(R.id.widget_time, time)
                }
                views.setOnClickPendingIntent(
                    R.id.widget_root,
                    PendingIntent.getActivity(
                        context,
                        0,
                        Intent(context, MainActivity::class.java),
                        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                    ),
                )
                manager.updateAppWidget(ids, views)
            } catch (_: Throwable) {
                // Un widget que falla no debe afectar capturas ni Worker.
            }
        }

        /** Última línea válida del historial JSON Lines, o null. */
        private fun lastCapture(context: Context): JSONObject? = try {
            val file = File(context.filesDir, "rootcause-history.jsonl")
            if (!file.exists()) {
                null
            } else {
                file.readLines()
                    .lastOrNull { it.isNotBlank() }
                    ?.let { JSONObject(it) }
            }
        } catch (_: Throwable) {
            null
        }

        private fun spanishConfigured(context: Context): Boolean = try {
            val file = File(context.filesDir, "rootcause-config.json")
            !file.exists() || JSONObject(file.readText()).optBoolean("spanish", true)
        } catch (_: Throwable) {
            true
        }
    }
}
