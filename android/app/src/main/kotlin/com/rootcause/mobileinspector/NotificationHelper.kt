package com.rootcause.mobileinspector

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

/**
 * Notificación LOCAL de veredicto crítico. Sin permiso INTERNET no existe
 * el push: esto es el propio dispositivo avisándose a sí mismo cuando la
 * captura en segundo plano detecta una distorsión seria.
 */
object NotificationHelper {

    private const val CHANNEL_ID = "rootcause-alerts"
    private const val NOTIFICATION_ID = 7403

    fun permissionGranted(context: Context): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS,
            ) == PackageManager.PERMISSION_GRANTED

    fun notifyCritical(context: Context, title: String, body: String): Boolean {
        if (!permissionGranted(context)) return false
        return try {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "RootCause",
                    NotificationManager.IMPORTANCE_HIGH,
                ),
            )
            val openApp = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            val notification = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_stat_rootcause)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setContentIntent(openApp)
                .setAutoCancel(true)
                .build()
            manager.notify(NOTIFICATION_ID, notification)
            true
        } catch (_: Throwable) {
            // Una notificación fallida jamás debe tumbar el Worker.
            false
        }
    }
}
