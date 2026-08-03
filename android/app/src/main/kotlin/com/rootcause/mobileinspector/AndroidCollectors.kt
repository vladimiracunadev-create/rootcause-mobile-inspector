package com.rootcause.mobileinspector

import android.app.ActivityManager
import android.app.AppOpsManager
import android.app.admin.DevicePolicyManager
import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.TrafficStats
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.os.SystemClock
import android.os.storage.StorageManager
import android.provider.Settings
import android.util.Base64
import java.io.ByteArrayOutputStream
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

    private fun directorySize(dir: File): Long = CollectorLogic.directorySize(dir)

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
        // Capacidades CONCEDIDAS y activas (el vector de stalkerware): se
        // calculan una vez y se cruzan por paquete en cada app.
        val accessibility = enabledComponentPackages(
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        )
        val notifListeners = enabledComponentPackages("enabled_notification_listeners")
        val deviceAdmins = activeDeviceAdminPackages()
        // Datos por app (24 h) solo si el usuario concedió el acceso de uso.
        val end = System.currentTimeMillis()
        val start = end - 24L * 60 * 60 * 1000
        val nsm = if (usageAccessGranted()) networkStatsManager() else null
        return installedPackages(pm)
            .asSequence()
            .filter { it.applicationInfo != null }
            .filterNot { (it.applicationInfo!!.flags and ApplicationInfo.FLAG_SYSTEM) != 0 }
            .filterNot { it.packageName == context.packageName }
            .map { pkg ->
                appEntry(
                    pm,
                    pkg,
                    usage,
                    accessibility,
                    notifListeners,
                    deviceAdmins,
                    nsm,
                    start,
                    end,
                )
            }
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
        accessibility: Set<String>,
        notifListeners: Set<String>,
        deviceAdmins: Set<String>,
        nsm: NetworkStatsManager?,
        start: Long,
        end: Long,
    ): Map<String, Any?> {
        val requested = pkg.requestedPermissions?.toList() ?: emptyList()
        val grantFlags = pkg.requestedPermissionsFlags
        val dangerous = requested
            .filter { it in CollectorLogic.DANGEROUS_PERMISSIONS }
            .map { it.removePrefix("android.permission.") }
        // Permisos peligrosos CONCEDIDOS ahora mismo (no solo solicitados):
        // el bit REQUESTED_PERMISSION_GRANTED del arreglo paralelo de flags.
        val granted = requested.mapIndexedNotNull { i, perm ->
            val isGranted = grantFlags != null && i < grantFlags.size &&
                (grantFlags[i] and PackageInfo.REQUESTED_PERMISSION_GRANTED) != 0
            if (perm in CollectorLogic.DANGEROUS_PERMISSIONS && isGranted) {
                perm.removePrefix("android.permission.")
            } else {
                null
            }
        }
        val flags = mutableListOf<String>()
        if ("android.permission.SYSTEM_ALERT_WINDOW" in requested) flags += "overlay"
        if ("android.permission.REQUEST_INSTALL_PACKAGES" in requested) {
            flags += "installs-packages"
        }
        if ("android.permission.BIND_DEVICE_ADMIN" in requested) flags += "device-admin"
        // Capacidades activas: concedidas y en uso, no solo declaradas.
        if (pkg.packageName in accessibility) flags += "accessibility-service"
        if (pkg.packageName in notifListeners) flags += "notification-listener"
        if (pkg.packageName in deviceAdmins) flags += "device-admin-active"
        val label = try {
            pkg.applicationInfo?.loadLabel(pm)?.toString() ?: pkg.packageName
        } catch (_: Exception) {
            pkg.packageName
        }
        val uid = pkg.applicationInfo?.uid ?: -1
        val data = if (nsm != null && uid >= 0) {
            dataUsageByUid(nsm, uid, start, end)
        } else {
            null
        }
        return mapOf(
            "packageName" to pkg.packageName,
            "label" to label,
            "versionName" to (pkg.versionName ?: "?"),
            "dangerousPermissions" to dangerous,
            "grantedPermissions" to granted,
            "specialFlags" to flags,
            "sideloaded" to isSideloaded(pm, pkg.packageName),
            "foregroundMillis24h" to (usage?.get(pkg.packageName) ?: -1L),
            "rxBytes24h" to (data?.first ?: -1L),
            "txBytes24h" to (data?.second ?: -1L),
            "iconBase64" to (iconBase64(pkg.applicationInfo, pm) ?: ""),
        )
    }

    /** Paquetes de los componentes habilitados en un setting `pkg/Clase:…`. */
    private fun enabledComponentPackages(setting: String): Set<String> = try {
        CollectorLogic.packagesFromFlattenedComponents(
            Settings.Secure.getString(context.contentResolver, setting),
        )
    } catch (_: Throwable) {
        emptySet()
    }

    /** Paquetes con un administrador de dispositivo ACTIVO. */
    private fun activeDeviceAdminPackages(): Set<String> = try {
        val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE)
            as DevicePolicyManager
        dpm.activeAdmins?.map { it.packageName }?.toSet() ?: emptySet()
    } catch (_: Throwable) {
        emptySet()
    }

    private fun networkStatsManager(): NetworkStatsManager? = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            context.getSystemService(Context.NETWORK_STATS_SERVICE)
                as NetworkStatsManager
        } else {
            null
        }
    } catch (_: Throwable) {
        null
    }

    /**
     * Datos (rx, tx) de un uid en la ventana [start, end] sumando WiFi y móvil.
     * Requiere el acceso de uso (ya verificado por el llamador). Devuelve null
     * si el SO no lo expone para este equipo/uid.
     */
    @Suppress("DEPRECATION")
    private fun dataUsageByUid(
        nsm: NetworkStatsManager,
        uid: Int,
        start: Long,
        end: Long,
    ): Pair<Long, Long>? {
        var rx = 0L
        var tx = 0L
        var any = false
        for (type in intArrayOf(ConnectivityManager.TYPE_WIFI, ConnectivityManager.TYPE_MOBILE)) {
            try {
                val stats: NetworkStats =
                    nsm.queryDetailsForUid(type, null, start, end, uid) ?: continue
                val bucket = NetworkStats.Bucket()
                while (stats.hasNextBucket()) {
                    stats.getNextBucket(bucket)
                    rx += bucket.rxBytes
                    tx += bucket.txBytes
                }
                stats.close()
                any = true
            } catch (_: Throwable) {
                // Ese transporte no está disponible para este uid; se ignora.
            }
        }
        return if (any) Pair(rx, tx) else null
    }

    /**
     * Ícono de la app como PNG Base64 (48x48). Se reduce a un tamaño pequeño
     * para no inflar el canal; null si falla la carga o el render.
     */
    private fun iconBase64(appInfo: ApplicationInfo?, pm: PackageManager): String? {
        if (appInfo == null) return null
        return try {
            val drawable = appInfo.loadIcon(pm)
            val size = 48
            val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, size, size)
            drawable.draw(canvas)
            val out = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
            bitmap.recycle()
            Base64.encodeToString(out.toByteArray(), Base64.NO_WRAP)
        } catch (_: Throwable) {
            null
        }
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
        return CollectorLogic.isSideloaded(installer)
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
    private fun vendorSkin(): String = CollectorLogic.vendorSkin(::sysProp)

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
    private fun rootIndicators(): List<String> = CollectorLogic.rootIndicators(
        suPathExists = { path ->
            try {
                File(path).exists()
            } catch (_: SecurityException) {
                // Sin permiso para consultar esa ruta: se omite, no se especula.
                false
            }
        },
        buildTags = Build.TAGS,
        verifiedBootState = sysProp("ro.boot.verifiedbootstate"),
        bootloaderFlashLocked = sysProp("ro.boot.flash.locked"),
    )

}
