package com.rootcause.mobileinspector

import android.Manifest
import android.os.Build
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Actividad principal: registra el canal `rootcause/collectors` (la
 * implementación compartida vive en [CollectorsChannel]) y atiende las
 * peticiones de permisos en tiempo de ejecución (BLE y notificaciones).
 */
class MainActivity : FlutterActivity() {

    private var pendingBleResult: MethodChannel.Result? = null
    private var pendingNotifResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        CollectorsChannel.register(
            flutterEngine.dartExecutor.binaryMessenger,
            applicationContext,
            activity = this,
            onRequestBlePermissions = { result ->
                // Una petición nueva reemplaza a una anterior sin resolver.
                pendingBleResult?.success(false)
                pendingBleResult = result
                CollectorsChannel.requestBlePermissions(this)
            },
            onRequestNotificationPermissions = { result ->
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                    result.success(true)
                } else {
                    pendingNotifResult?.success(false)
                    pendingNotifResult = result
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                        CollectorsChannel.NOTIF_REQUEST_CODE,
                    )
                }
            },
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            CollectorsChannel.BLE_REQUEST_CODE -> {
                pendingBleResult?.success(CollectorsChannel.blePermissionsGranted(this))
                pendingBleResult = null
            }
            CollectorsChannel.NOTIF_REQUEST_CODE -> {
                pendingNotifResult?.success(NotificationHelper.permissionGranted(this))
                pendingNotifResult = null
            }
        }
    }
}
