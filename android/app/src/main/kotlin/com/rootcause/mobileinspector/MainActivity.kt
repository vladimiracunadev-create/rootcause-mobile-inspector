package com.rootcause.mobileinspector

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Actividad principal: registra el canal `rootcause/collectors` (la
 * implementación compartida vive en [CollectorsChannel]) y atiende la
 * petición de permisos BLE en tiempo de ejecución.
 */
class MainActivity : FlutterActivity() {

    private var pendingBleResult: MethodChannel.Result? = null

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
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == CollectorsChannel.BLE_REQUEST_CODE) {
            pendingBleResult?.success(CollectorsChannel.blePermissionsGranted(this))
            pendingBleResult = null
        }
    }
}
