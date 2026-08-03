package com.rootcause.mobileinspector

import java.io.File

/**
 * Lógica de DECISIÓN de los colectores, sin una sola dependencia de Android.
 *
 * Por qué existe este archivo: hasta v0.7.0 toda la capa nativa vivía pegada
 * a `Context`, así que no había forma de probarla sin un dispositivo — y es
 * justo la capa donde nació el crash de arranque de v0.2.0. Aquí viven las
 * decisiones que NO necesitan el sistema operativo (parsear, clasificar,
 * sumar); `AndroidCollectors` se queda con lo que sí lo necesita (pedir el
 * dato al SO) y delega aquí.
 *
 * La regla para mover algo a este archivo es simple: si se puede escribir un
 * test que falle cuando la lógica esté mal, va aquí.
 */
object CollectorLogic {

    /**
     * Tiendas cuyo instalador consideramos de confianza. Fuera de esta lista
     * (o sin instalador registrado) la app se marca como *sideload*, que suma
     * puntaje de riesgo en el núcleo Dart.
     */
    val TRUSTED_INSTALLERS: Set<String> = setOf(
        "com.android.vending",
        "com.google.android.feedback",
        "com.amazon.venezia",
        "com.huawei.appmarket",
        "com.sec.android.app.samsungapps",
        "org.fdroid.fdroid",
    )

    /**
     * Permisos peligrosos de Android que forman la "superficie" que audita
     * RootCause. Es la definición operativa del riesgo por app: cada uno
     * suma un punto al puntaje que calcula el núcleo Dart.
     */
    val DANGEROUS_PERMISSIONS: Set<String> = setOf(
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

    /** Rutas donde suele quedar el binario `su` en un equipo rooteado. */
    val SU_PATHS: List<String> = listOf(
        "/system/bin/su",
        "/system/xbin/su",
        "/sbin/su",
        "/system/sd/xbin/su",
        "/data/local/bin/su",
        "/data/local/xbin/su",
        "/data/local/su",
    )

    /**
     * Una app sin instalador registrado también cuenta como sideload: es
     * exactamente lo que ocurre con un APK instalado por `adb` o abierto
     * desde el gestor de archivos.
     */
    fun isSideloaded(installer: String?): Boolean =
        installer.isNullOrBlank() || installer !in TRUSTED_INSTALLERS

    /**
     * Paquetes de una lista de componentes aplanados de `Settings.Secure`
     * (`paquete/clase:paquete/clase`). Es la fuente de la detección de
     * stalkerware ACTIVO: servicios de accesibilidad y lectores de
     * notificaciones concedidos y en marcha.
     *
     * Tolerante a propósito: el formato lo escribe el SO y varía entre capas
     * de fabricante (separadores sobrantes, entradas sin clase, espacios).
     * Una entrada rara se ignora; nunca se inventa un paquete.
     */
    fun packagesFromFlattenedComponents(raw: String?): Set<String> {
        if (raw.isNullOrBlank()) return emptySet()
        return raw.split(':')
            .mapNotNull { entry ->
                entry.trim().substringBefore('/').takeIf { it.isNotBlank() }
            }
            .toSet()
    }

    /**
     * Capa del fabricante a partir de propiedades del sistema. [prop] se
     * inyecta para poder probar el formato sin un teléfono delante.
     *
     * Samsung codifica la versión de One UI como `mayor*10000 + menor*100`
     * (8.5 → 80500); el resto de fabricantes publica la cadena tal cual.
     * Cadena vacía = Android puro o capa no reconocida: la UI omite la fila
     * en vez de inventar un nombre.
     */
    fun vendorSkin(prop: (String) -> String?): String {
        prop("ro.build.version.oneui")?.toIntOrNull()?.let { v ->
            return if (v >= 10000) {
                "One UI ${v / 10000}.${(v % 10000) / 100}"
            } else {
                "One UI $v"
            }
        }
        prop("ro.miui.ui.version.name")?.let { return "MIUI $it" }
        prop("ro.build.version.opporom")?.let { return "ColorOS $it" }
        prop("ro.build.version.emui")?.let { return it.replace('_', ' ') }
        prop("ro.build.version.oplusrom")?.let { return "OxygenOS/ColorOS $it" }
        return ""
    }

    /**
     * Indicadores honestos de root. Es un INDICIO, no una prueba: un gestor
     * de root moderno puede ocultarse y un equipo rooteado a propósito da la
     * misma señal.
     *
     * [suPathExists] se inyecta porque en un test no queremos tocar el disco
     * real; [buildTags], [verifiedBootState] y [bootloaderFlashLocked] son
     * las propiedades del SO tal cual las entrega el sistema.
     */
    fun rootIndicators(
        suPathExists: (String) -> Boolean,
        buildTags: String?,
        verifiedBootState: String?,
        bootloaderFlashLocked: String?,
    ): List<String> {
        val indicators = mutableListOf<String>()
        for (path in SU_PATHS) {
            if (suPathExists(path)) indicators += path
        }
        if (buildTags?.contains("test-keys") == true) {
            indicators += "build:test-keys"
        }
        // Integridad de arranque: un verified boot no-verde o un bootloader
        // desbloqueado indican que el sistema pudo ser modificado.
        verifiedBootState?.takeIf { it.isNotBlank() }?.let { state ->
            if (state.lowercase() != "green") indicators += "verifiedboot:$state"
        }
        if (bootloaderFlashLocked == "0") indicators += "bootloader-unlocked"
        return indicators
    }

    /**
     * Tamaño total de un directorio recorriendo sin recursión (una caché con
     * miles de subcarpetas no debe agotar la pila). Un directorio ilegible
     * aporta 0 en vez de abortar el recorrido: evidencia parcial es mejor
     * que ninguna.
     */
    fun directorySize(dir: File): Long {
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
}
