package com.rootcause.mobileinspector

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.storage.StorageManager
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Canal `rootcause/collectors`: una sola implementación registrable tanto
 * desde la Activity (app abierta) como desde el engine headless del Worker
 * de captura en segundo plano — el mismo contrato en ambos contextos.
 */
object CollectorsChannel {

    const val NAME = "rootcause/collectors"
    const val BLE_REQUEST_CODE = 7401
    const val NOTIF_REQUEST_CODE = 7402

    fun register(
        messenger: BinaryMessenger,
        context: Context,
        activity: Activity? = null,
        onRequestBlePermissions: ((MethodChannel.Result) -> Unit)? = null,
        onRequestNotificationPermissions: ((MethodChannel.Result) -> Unit)? = null,
    ) {
        val mainHandler = Handler(Looper.getMainLooper())
        MethodChannel(messenger, NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "collect" -> Thread {
                    val payload = try {
                        AndroidCollectors(context).collect()
                    } catch (_: Throwable) {
                        // Throwable, no solo Exception: un Error sin capturar
                        // en este hilo mataría el proceso completo. El Dart
                        // degrada un mapa vacío a snapshot neutro.
                        emptyMap<String, Any?>()
                    }
                    mainHandler.post { result.success(payload) }
                }.start()

                "documentsPath" -> result.success(context.filesDir.absolutePath)

                "openSystemScreen" -> result.success(
                    openSystemScreen(
                        activity ?: context,
                        call.argument<String>("screen") ?: "",
                        call.argument<String>("packageName"),
                    ),
                )

                "clearOwnCache" -> Thread {
                    val freed = try {
                        clearOwnCache(context)
                    } catch (_: Throwable) {
                        0L
                    }
                    mainHandler.post { result.success(freed) }
                }.start()

                "requestBlePermissions" -> when {
                    blePermissionsGranted(context) -> result.success(true)
                    onRequestBlePermissions != null -> onRequestBlePermissions(result)
                    else -> result.success(false)
                }

                "requestNotificationPermissions" -> when {
                    NotificationHelper.permissionGranted(context) -> result.success(true)
                    onRequestNotificationPermissions != null ->
                        onRequestNotificationPermissions(result)
                    else -> result.success(false)
                }

                "notifyCritical" -> result.success(
                    NotificationHelper.notifyCritical(
                        context,
                        call.argument<String>("title") ?: "RootCause",
                        call.argument<String>("body") ?: "",
                    ),
                )

                "bleScan" -> bleScan(
                    context,
                    call.argument<Int>("seconds") ?: 15,
                ) { list -> mainHandler.post { result.success(list) } }

                "refreshWidget" -> {
                    RootCauseWidgetProvider.updateAll(context)
                    result.success(null)
                }

                "configureBackgroundCapture" -> {
                    BackgroundCapture.configure(
                        context,
                        enabled = call.argument<Boolean>("enabled") ?: false,
                        chargingOnly = call.argument<Boolean>("chargingOnly") ?: true,
                    )
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    // ── Acciones de intervención ─────────────────────────────────────────
    // La app no puede matar procesos ni limpiar datos ajenos (límite del
    // SO): abre la pantalla del sistema donde el usuario SÍ puede.

    private fun openSystemScreen(
        context: Context,
        screen: String,
        packageName: String?,
    ): Boolean {
        val intent = when (screen) {
            "free-space" -> Intent(StorageManager.ACTION_MANAGE_STORAGE)
            "battery" -> Intent(Intent.ACTION_POWER_USAGE_SUMMARY)
            "app-details" -> {
                if (packageName.isNullOrEmpty()) return false
                Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.parse("package:$packageName"),
                )
            }
            "usage-access" -> Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            "system-update" -> Intent("android.settings.SYSTEM_UPDATE_SETTINGS")
            "settings" -> Intent(Settings.ACTION_SETTINGS)
            else -> return false
        }
        if (context !is Activity) intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            context.startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
    }

    /** Borra la caché propia de la app y devuelve los bytes liberados. */
    private fun clearOwnCache(context: Context): Long {
        val targets = listOfNotNull(
            context.cacheDir,
            context.codeCacheDir,
            context.externalCacheDir,
        )
        var freed = 0L
        for (dir in targets) {
            val children = dir.listFiles() ?: continue
            for (child in children) freed += deleteRecursively(child)
        }
        return freed
    }

    private fun deleteRecursively(file: File): Long {
        var freed = 0L
        if (file.isDirectory) {
            file.listFiles()?.forEach { freed += deleteRecursively(it) }
            file.delete()
        } else {
            val size = file.length()
            if (file.delete()) freed += size
        }
        return freed
    }

    // ── Escaneo Bluetooth LE (opt-in, sin permiso INTERNET) ──────────────

    /** Android 12+ usa BLUETOOTH_SCAN (neverForLocation); 8–11 exigen ubicación. */
    fun blePermissionsRequired(): Array<String> =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(Manifest.permission.BLUETOOTH_SCAN)
        } else {
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
        }

    fun blePermissionsGranted(context: Context): Boolean =
        blePermissionsRequired().all {
            ContextCompat.checkSelfPermission(context, it) ==
                PackageManager.PERMISSION_GRANTED
        }

    fun requestBlePermissions(activity: Activity) {
        ActivityCompat.requestPermissions(
            activity,
            blePermissionsRequired(),
            BLE_REQUEST_CODE,
        )
    }

    /**
     * Escaneo manual acotado en el tiempo. Devuelve `null` (no soportado)
     * si el equipo no tiene Bluetooth, está apagado o falta el permiso —
     * la UI comunica cada caso, no lo disfraza.
     */
    @SuppressLint("MissingPermission") // Verificado con blePermissionsGranted.
    private fun bleScan(
        context: Context,
        seconds: Int,
        done: (List<Map<String, Any?>>?) -> Unit,
    ) {
        if (!blePermissionsGranted(context)) {
            done(null)
            return
        }
        val manager =
            context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        val adapter = manager?.adapter
        val scanner = if (adapter?.isEnabled == true) adapter.bluetoothLeScanner else null
        if (scanner == null) {
            done(null)
            return
        }
        val found = LinkedHashMap<String, Map<String, Any?>>()
        val callback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                // El nombre sale del propio anuncio BLE; no se conecta a nada.
                val name = result.scanRecord?.deviceName ?: ""
                found[result.device.address] = mapOf(
                    "address" to result.device.address,
                    "name" to name,
                    "rssi" to result.rssi,
                )
            }
        }
        try {
            scanner.startScan(callback)
        } catch (_: SecurityException) {
            done(null)
            return
        }
        Handler(Looper.getMainLooper()).postDelayed({
            try {
                scanner.stopScan(callback)
            } catch (_: SecurityException) {
                // El permiso se revocó a mitad de escaneo: se entrega lo visto.
            }
            done(found.values.toList())
        }, seconds.coerceIn(1, 60) * 1000L)
    }
}
