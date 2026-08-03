package com.rootcause.mobileinspector

import java.io.File
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

/**
 * Tests JVM de la lógica de decisión nativa. Corren sin emulador y sin
 * dispositivo (`./gradlew :app:testDebugUnitTest`) porque `CollectorLogic`
 * no toca Android.
 *
 * Hasta v0.8.0 la capa Kotlin no tenía un solo test — y es la capa donde
 * nació el crash de arranque de v0.2.0. Esto cubre la parte que se puede
 * cubrir aquí; el canal completo lo verifica el test de integración en el
 * emulador de CI.
 */
class CollectorLogicTest {

    @get:Rule
    val temp = TemporaryFolder()

    // ── Origen de instalación (sideload) ────────────────────────────────

    @Test
    fun `una tienda de confianza no es sideload`() {
        assertFalse(CollectorLogic.isSideloaded("com.android.vending"))
        assertFalse(CollectorLogic.isSideloaded("org.fdroid.fdroid"))
        assertFalse(CollectorLogic.isSideloaded("com.sec.android.app.samsungapps"))
    }

    @Test
    fun `sin instalador registrado cuenta como sideload`() {
        // Es justo lo que ocurre con un APK instalado por adb o abierto
        // desde el gestor de archivos: el caso que más importa detectar.
        assertTrue(CollectorLogic.isSideloaded(null))
        assertTrue(CollectorLogic.isSideloaded(""))
        assertTrue(CollectorLogic.isSideloaded("   "))
    }

    @Test
    fun `un instalador desconocido cuenta como sideload`() {
        assertTrue(CollectorLogic.isSideloaded("com.dudoso.store"))
    }

    // ── Componentes activos (detección de stalkerware) ──────────────────

    @Test
    fun `extrae los paquetes de una lista de componentes aplanados`() {
        val raw = "com.spy/com.spy.Service:com.otra/.Listener"
        assertEquals(
            setOf("com.spy", "com.otra"),
            CollectorLogic.packagesFromFlattenedComponents(raw),
        )
    }

    @Test
    fun `tolera el formato que escriben las capas de fabricante`() {
        // Separadores sobrantes, espacios y una entrada sin clase: ninguna
        // de estas variantes debe hacer perder un paquete real.
        val raw = " com.spy/com.spy.Service :: com.sinclase : "
        assertEquals(
            setOf("com.spy", "com.sinclase"),
            CollectorLogic.packagesFromFlattenedComponents(raw),
        )
    }

    @Test
    fun `sin servicios activos devuelve conjunto vacio, nunca null`() {
        assertTrue(CollectorLogic.packagesFromFlattenedComponents(null).isEmpty())
        assertTrue(CollectorLogic.packagesFromFlattenedComponents("").isEmpty())
        assertTrue(CollectorLogic.packagesFromFlattenedComponents("   ").isEmpty())
    }

    // ── Capa del fabricante ─────────────────────────────────────────────

    @Test
    fun `decodifica la version de One UI que codifica Samsung`() {
        // 80500 = 8.5. Es la aritmética con más riesgo de bug de todo el
        // colector, y la que un usuario detectaría al instante.
        assertEquals("One UI 8.5", CollectorLogic.vendorSkin(propOf("ro.build.version.oneui" to "80500")))
        assertEquals("One UI 6.1", CollectorLogic.vendorSkin(propOf("ro.build.version.oneui" to "60100")))
        assertEquals("One UI 5.0", CollectorLogic.vendorSkin(propOf("ro.build.version.oneui" to "50000")))
    }

    @Test
    fun `una version de One UI antigua sin codificar se muestra tal cual`() {
        assertEquals("One UI 3", CollectorLogic.vendorSkin(propOf("ro.build.version.oneui" to "3")))
    }

    @Test
    fun `reconoce el resto de capas conocidas`() {
        assertEquals("MIUI V14", CollectorLogic.vendorSkin(propOf("ro.miui.ui.version.name" to "V14")))
        assertEquals("ColorOS 13", CollectorLogic.vendorSkin(propOf("ro.build.version.opporom" to "13")))
        assertEquals("EmotionUI 12", CollectorLogic.vendorSkin(propOf("ro.build.version.emui" to "EmotionUI_12")))
    }

    @Test
    fun `Android puro devuelve cadena vacia en vez de inventar un nombre`() {
        assertEquals("", CollectorLogic.vendorSkin { null })
    }

    // ── Indicadores de root ─────────────────────────────────────────────

    @Test
    fun `un equipo limpio no genera ningun indicador`() {
        val indicators = CollectorLogic.rootIndicators(
            suPathExists = { false },
            buildTags = "release-keys",
            verifiedBootState = "green",
            bootloaderFlashLocked = "1",
        )
        assertTrue(indicators.isEmpty(), "no debe acusar a un equipo limpio: $indicators")
    }

    @Test
    fun `un binario su encontrado se reporta con su ruta`() {
        val indicators = CollectorLogic.rootIndicators(
            suPathExists = { it == "/system/xbin/su" },
            buildTags = "release-keys",
            verifiedBootState = "green",
            bootloaderFlashLocked = "1",
        )
        assertEquals(listOf("/system/xbin/su"), indicators)
    }

    @Test
    fun `build con test-keys, verified boot naranja y bootloader abierto suman`() {
        val indicators = CollectorLogic.rootIndicators(
            suPathExists = { false },
            buildTags = "test-keys",
            verifiedBootState = "orange",
            bootloaderFlashLocked = "0",
        )
        assertEquals(
            listOf("build:test-keys", "verifiedboot:orange", "bootloader-unlocked"),
            indicators,
        )
    }

    @Test
    fun `verified boot verde en mayusculas sigue siendo verde`() {
        val indicators = CollectorLogic.rootIndicators(
            suPathExists = { false },
            buildTags = null,
            verifiedBootState = "GREEN",
            bootloaderFlashLocked = null,
        )
        assertTrue(indicators.isEmpty(), "GREEN no debe acusar: $indicators")
    }

    @Test
    fun `propiedades ausentes no generan indicadores fantasma`() {
        // Muchos equipos no exponen estas propiedades: la ausencia de dato
        // jamás debe convertirse en un indicio.
        val indicators = CollectorLogic.rootIndicators(
            suPathExists = { false },
            buildTags = null,
            verifiedBootState = null,
            bootloaderFlashLocked = null,
        )
        assertTrue(indicators.isEmpty(), "sin datos no hay indicios: $indicators")
    }

    // ── Tamaño de caché ─────────────────────────────────────────────────

    @Test
    fun `suma el tamano de un arbol de directorios`() {
        val root = temp.newFolder("cache")
        File(root, "a.bin").writeBytes(ByteArray(100))
        val sub = File(root, "sub").apply { mkdirs() }
        File(sub, "b.bin").writeBytes(ByteArray(250))
        File(sub, "hondo").apply { mkdirs() }.let {
            File(it, "c.bin").writeBytes(ByteArray(50))
        }
        assertEquals(400L, CollectorLogic.directorySize(root))
    }

    @Test
    fun `un directorio inexistente mide cero, no lanza`() {
        assertEquals(0L, CollectorLogic.directorySize(File(temp.root, "no-existe")))
    }

    @Test
    fun `un directorio vacio mide cero`() {
        assertEquals(0L, CollectorLogic.directorySize(temp.newFolder("vacio")))
    }

    // ── Superficie de permisos ──────────────────────────────────────────

    @Test
    fun `la superficie peligrosa cubre las capacidades de vigilancia`() {
        // Si alguna de estas desaparece de la lista, una app de espionaje
        // dejaría de puntuar. El test lo bloquea.
        for (perm in listOf(
            "android.permission.CAMERA",
            "android.permission.RECORD_AUDIO",
            "android.permission.ACCESS_FINE_LOCATION",
            "android.permission.ACCESS_BACKGROUND_LOCATION",
            "android.permission.READ_SMS",
            "android.permission.READ_CONTACTS",
            "android.permission.READ_CALL_LOG",
        )) {
            assertTrue(perm in CollectorLogic.DANGEROUS_PERMISSIONS, "falta $perm")
        }
    }

    @Test
    fun `un permiso inofensivo no infla el puntaje de riesgo`() {
        assertFalse("android.permission.INTERNET" in CollectorLogic.DANGEROUS_PERMISSIONS)
        assertFalse("android.permission.VIBRATE" in CollectorLogic.DANGEROUS_PERMISSIONS)
    }

    private fun propOf(vararg pairs: Pair<String, String>): (String) -> String? {
        val map = pairs.toMap()
        return { map[it] }
    }
}
