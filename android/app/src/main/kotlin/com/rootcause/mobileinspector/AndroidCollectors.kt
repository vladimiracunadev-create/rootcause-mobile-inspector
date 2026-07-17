package com.rootcause.mobileinspector

import android.app.ActivityManager
import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.TrafficStats
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.os.SystemClock
import android.os.storage.StorageManager
import java.io.File

/**
 * Colectores nativos Android — solo APIs públicas y documentadas del SO.
 * Devuelve el mapa del contrato `rootcause/collectors` (docs/ARCHITECTURE.md).
 * Toda lectura es local; esta app no declara el permiso INTERNET.
 */
class AndroidCollectors(private val context: Context) {

    fun collect(): Map<String, Any?> = mapOf(
        "memory" to safe { memory() },
        "storage" to safe { storage() },
        "battery" to safe { battery() },
        "network" to safe { network() },
        "apps" to safe { apps() },
        "device" to safe { device() },
    )

    /**
     * Aísla cada colector: si una sección falla en un dispositivo concreto
     * (Throwable incluido — un Error no debe matar el proceso), esa sección
     * degrada a null y el Dart la convierte en valores neutros. Evidencia
     * parcial es mejor que un crash de arranque.
     */
    private inline fun <T> safe(block: () -> T): T? = try {
        block()
    } catch (_: Throwable) {
        null
    }

    private fun memory(): Map<String, Any?> {
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val info = ActivityManager.MemoryInfo()
        am.getMemoryInfo(info)
        return mapOf(
            "totalBytes" to info.totalMem,
            "availableBytes" to info.availMem,
            "lowMemory" to info.lowMemory,
        )
    }

    private fun storage(): Map<String, Any?> {
        val stat = StatFs(Environment.getDataDirectory().absolutePath)
        val cacheBytes = directorySize(context.cacheDir) +
            directorySize(context.codeCacheDir) +
            (context.externalCacheDir?.let { directorySize(it) } ?: 0L)
        return mapOf(
            "totalBytes" to stat.totalBytes,
            "freeBytes" to stat.availableBytes,
            "appCacheBytes" to cacheBytes,
            "volumes" to volumes(),
        )
    }

    /**
     * Volúmenes adicionales (tarjeta SD, USB OTG). El volumen primario
     * emulado se omite: es la misma partición que el volumen de datos ya
     * reportado. Sin tarjeta la lista queda vacía — caso normal, no error.
     */
    private fun volumes(): List<Map<String, Any?>> {
        val sm = context.getSystemService(Context.STORAGE_SERVICE) as StorageManager
        val result = mutableListOf<Map<String, Any?>>()
        for (dir in context.getExternalFilesDirs(null).filterNotNull()) {
            val volume = try {
                sm.getStorageVolume(dir)
            } catch (_: Exception) {
                null
            } ?: continue
            if (volume.isPrimary && !volume.isRemovable) continue
            val stat = try {
                StatFs(dir.absolutePath)
            } catch (_: Exception) {
                continue
            }
            result += mapOf(
                "label" to (volume.getDescription(context) ?: "SD"),
                "totalBytes" to stat.totalBytes,
                "freeBytes" to stat.availableBytes,
                "removable" to volume.isRemovable,
            )
        }
        return result
    }

    private fun directorySize(dir: File): Long {
        if (!dir.exists()) return 0L
        var total = 0L
        val stack = ArrayDeque<File>()
        stack.addLast(dir)
        while (stack.isNotEmpty()) {
            val current = stack.removeLast()
            val children = current.listFiles() ?: continue
            for (child in children) {
                if (child.isDirectory) stack.addLast(child) else total += child.length()
            }
        }
        return total
    }

    private fun battery(): Map<String, Any?> {
        val intent: Intent? = context.registerReceiver(
            null,
            IntentFilter(Intent.ACTION_BATTERY_CHANGED),
        )
        val level = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = intent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val pct = if (level >= 0 && scale > 0) (level * 100) / scale else -1
        val status = intent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val charging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
            status == BatteryManager.BATTERY_STATUS_FULL
        val tempTenths = intent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) ?: 0
        val voltage = intent?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 0) ?: 0
        val health = intent?.getIntExtra(
            BatteryManager.EXTRA_HEALTH,
            BatteryManager.BATTERY_HEALTH_UNKNOWN,
        ) ?: BatteryManager.BATTERY_HEALTH_UNKNOWN
        return mapOf(
            "levelPercent" to pct,
            "charging" to charging,
            "temperatureCelsius" to tempTenths / 10.0,
            "temperatureAvailable" to (intent != null),
            "voltageMillivolts" to voltage,
            "healthy" to (
                health == BatteryManager.BATTERY_HEALTH_GOOD ||
                    health == BatteryManager.BATTERY_HEALTH_UNKNOWN
                ),
            "healthLabel" to healthLabel(health),
        )
    }

    private fun healthLabel(health: Int): String = when (health) {
        BatteryManager.BATTERY_HEALTH_GOOD -> "good"
        BatteryManager.BATTERY_HEALTH_OVERHEAT -> "overheat"
        BatteryManager.BATTERY_HEALTH_DEAD -> "dead"
        BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> "over-voltage"
        BatteryManager.BATTERY_HEALTH_UNSPECIFIED_FAILURE -> "failure"
        BatteryManager.BATTERY_HEALTH_COLD -> "cold"
        else -> "unknown"
    }

    private fun network(): Map<String, Any?> {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val caps: NetworkCapabilities? =
            cm.activeNetwork?.let { cm.getNetworkCapabilities(it) }
        val transport = when {
            caps == null -> "none"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "cellular"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_BLUETOOTH) -> "bluetooth"
            else -> "other"
        }
        return mapOf(
            "connected" to (caps != null),
            "transport" to transport,
            "vpnActive" to (caps?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) ?: false),
            "metered" to (
                caps?.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED)?.not()
                    ?: false
                ),
            "downstreamKbps" to (caps?.linkDownstreamBandwidthKbps ?: 0),
            "upstreamKbps" to (caps?.linkUpstreamBandwidthKbps ?: 0),
            "totalRxBytes" to TrafficStats.getTotalRxBytes(),
            "totalTxBytes" to TrafficStats.getTotalTxBytes(),
        )
    }

    /**
     * Auditoría de superficie de permisos de apps de usuario. El nativo
     * entrega evidencia cruda; el puntaje y la severidad se calculan en el
     * núcleo Dart compartido (una sola política, testeable).
     */
    private fun apps(): List<Map<String, Any?>> {
        val pm = context.packageManager
        val usage = usageByPackage()
        return installedPackages(pm)
            .asSequence()
            .filter { it.applicationInfo != null }
            .filterNot { (it.applicationInfo!!.flags and ApplicationInfo.FLAG_SYSTEM) != 0 }
            .filterNot { it.packageName == context.packageName }
            .map { pkg -> appEntry(pm, pkg, usage) }
            .toList()
    }

    /**
     * Tiempo en primer plano por paquete (últimas 24 h) medido por el SO.
     * Requiere el permiso especial de acceso de uso que el USUARIO concede
     * en Ajustes (opt-in); sin él devuelve null y cada app reporta -1.
     */
    fun usageAccessGranted(): Boolean = try {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        appOps.unsafeCheckOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            context.packageName,
        ) == AppOpsManager.MODE_ALLOWED
    } catch (_: Throwable) {
        false
    }

    private fun usageByPackage(): Map<String, Long>? {
        if (!usageAccessGranted()) return null
        return try {
            val usm = context.getSystemService(Context.USAGE_STATS_SERVICE)
                as UsageStatsManager
            val end = System.currentTimeMillis()
            usm.queryAndAggregateUsageStats(end - 24L * 60 * 60 * 1000, end)
                .mapValues { it.value.totalTimeInForeground }
        } catch (_: Throwable) {
            null
        }
    }

    private fun appEntry(
        pm: PackageManager,
        pkg: PackageInfo,
        usage: Map<String, Long>?,
    ): Map<String, Any?> {
        val requested = pkg.requestedPermissions?.toList() ?: emptyList()
        val dangerous = requested
            .filter { it in DANGEROUS_PERMISSIONS }
            .map { it.removePrefix("android.permission.") }
        val flags = mutableListOf<String>()
        if ("android.permission.SYSTEM_ALERT_WINDOW" in requested) flags += "overlay"
        if ("android.permission.REQUEST_INSTALL_PACKAGES" in requested) {
            flags += "installs-packages"
        }
        if ("android.permission.BIND_DEVICE_ADMIN" in requested) flags += "device-admin"
        val label = try {
            pkg.applicationInfo?.loadLabel(pm)?.toString() ?: pkg.packageName
        } catch (_: Exception) {
            pkg.packageName
        }
        return mapOf(
            "packageName" to pkg.packageName,
            "label" to label,
            "versionName" to (pkg.versionName ?: "?"),
            "dangerousPermissions" to dangerous,
            "specialFlags" to flags,
            "sideloaded" to isSideloaded(pm, pkg.packageName),
            "foregroundMillis24h" to (usage?.get(pkg.packageName) ?: -1L),
        )
    }

    @Suppress("DEPRECATION")
    private fun installedPackages(pm: PackageManager): List<PackageInfo> = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getInstalledPackages(
                PackageManager.PackageInfoFlags.of(PackageManager.GET_PERMISSIONS.toLong()),
            )
        } else {
            pm.getInstalledPackages(PackageManager.GET_PERMISSIONS)
        }
    } catch (_: Exception) {
        emptyList()
    }

    @Suppress("DEPRECATION")
    private fun isSideloaded(pm: PackageManager, packageName: String): Boolean {
        val installer = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                pm.getInstallSourceInfo(packageName).installingPackageName
            } else {
                pm.getInstallerPackageName(packageName)
            }
        } catch (_: Exception) {
            null
        }
        return installer == null || installer !in TRUSTED_INSTALLERS
    }

    private fun device(): Map<String, Any?> = mapOf(
        "manufacturer" to Build.MANUFACTURER,
        "model" to Build.MODEL,
        "osVersion" to (Build.VERSION.RELEASE ?: "?"),
        "sdkInt" to Build.VERSION.SDK_INT,
        "securityPatch" to (Build.VERSION.SECURITY_PATCH ?: "?"),
        "cpuCores" to Runtime.getRuntime().availableProcessors(),
        "uptimeMillis" to SystemClock.elapsedRealtime(),
        "rootIndicators" to rootIndicators(),
        "appsAuditSupported" to true,
        "vendorSkin" to vendorSkin(),
        "usageAccessGranted" to usageAccessGranted(),
    )

    /**
     * Capa del fabricante (One UI, MIUI, ColorOS, EMUI, OxygenOS) leída de
     * las propiedades de sistema del vendor. Es informativa: si la lectura
     * falla o el equipo es Android puro, se entrega cadena vacía y la UI
     * omite la fila.
     */
    private fun vendorSkin(): String {
        sysProp("ro.build.version.oneui")?.toIntOrNull()?.let { v ->
            // Samsung codifica 8.5 como 80500: mayor*10000 + menor*100.
            return if (v >= 10000) "One UI ${v / 10000}.${(v % 10000) / 100}" else "One UI $v"
        }
        sysProp("ro.miui.ui.version.name")?.let { return "MIUI $it" }
        sysProp("ro.build.version.opporom")?.let { return "ColorOS $it" }
        sysProp("ro.build.version.emui")?.let { return it.replace('_', ' ') }
        sysProp("ro.build.version.oplusrom")?.let { return "OxygenOS/ColorOS $it" }
        return ""
    }

    /** Lectura defensiva de una propiedad de sistema; null si no existe. */
    private fun sysProp(name: String): String? = try {
        val clazz = Class.forName("android.os.SystemProperties")
        val get = clazz.getMethod("get", String::class.java)
        (get.invoke(null, name) as? String)?.takeIf { it.isNotBlank() }
    } catch (_: Throwable) {
        null
    }

    /**
     * Indicadores honestos de root: binarios `su` en rutas conocidas y build
     * firmado con test-keys. Es un INDICIO, no una prueba.
     */
    private fun rootIndicators(): List<String> {
        val indicators = mutableListOf<String>()
        val suPaths = listOf(
            "/system/bin/su",
            "/system/xbin/su",
            "/sbin/su",
            "/system/sd/xbin/su",
            "/data/local/bin/su",
            "/data/local/xbin/su",
            "/data/local/su",
        )
        for (path in suPaths) {
            try {
                if (File(path).exists()) indicators += path
            } catch (_: SecurityException) {
                // Sin permiso para consultar esa ruta: se omite, no se especula.
            }
        }
        if (Build.TAGS?.contains("test-keys") == true) {
            indicators += "build:test-keys"
        }
        return indicators
    }

    private companion object {
        val TRUSTED_INSTALLERS = setOf(
            "com.android.vending",
            "com.google.android.feedback",
            "com.amazon.venezia",
            "com.huawei.appmarket",
            "com.sec.android.app.samsungapps",
            "org.fdroid.fdroid",
        )

        val DANGEROUS_PERMISSIONS = setOf(
            "android.permission.CAMERA",
            "android.permission.RECORD_AUDIO",
            "android.permission.ACCESS_FINE_LOCATION",
            "android.permission.ACCESS_COARSE_LOCATION",
            "android.permission.ACCESS_BACKGROUND_LOCATION",
            "android.permission.READ_CONTACTS",
            "android.permission.WRITE_CONTACTS",
            "android.permission.GET_ACCOUNTS",
            "android.permission.READ_SMS",
            "android.permission.SEND_SMS",
            "android.permission.RECEIVE_SMS",
            "android.permission.RECEIVE_MMS",
            "android.permission.READ_CALL_LOG",
            "android.permission.WRITE_CALL_LOG",
            "android.permission.READ_PHONE_STATE",
            "android.permission.READ_PHONE_NUMBERS",
            "android.permission.CALL_PHONE",
            "android.permission.ANSWER_PHONE_CALLS",
            "android.permission.PROCESS_OUTGOING_CALLS",
            "android.permission.READ_EXTERNAL_STORAGE",
            "android.permission.WRITE_EXTERNAL_STORAGE",
            "android.permission.MANAGE_EXTERNAL_STORAGE",
            "android.permission.READ_MEDIA_IMAGES",
            "android.permission.READ_MEDIA_VIDEO",
            "android.permission.READ_MEDIA_AUDIO",
            "android.permission.BODY_SENSORS",
            "android.permission.ACTIVITY_RECOGNITION",
            "android.permission.READ_CALENDAR",
            "android.permission.WRITE_CALENDAR",
            "android.permission.BLUETOOTH_CONNECT",
            "android.permission.BLUETOOTH_SCAN",
            "android.permission.NEARBY_WIFI_DEVICES",
            "android.permission.POST_NOTIFICATIONS",
        )
    }
}
