# Roadmap

## v0.2.0 — Control, tendencia y cercanía (actual)

Nace del feedback de uso real: "no tengo control para optimizar", "el
original se actualizaba cada 5 minutos", "mi tarjeta SD no se
diferencia", "no puedo ver dispositivos cerca".

- ✅ Pestaña **Configuración**: intervalo de auto-captura (5 min por
  defecto, como el original de escritorio), umbrales de detección
  modificables e idioma — todo persistido (`rootcause-config.json`)
- ✅ **Captura en segundo plano** con WorkManager (mín. 15 min, lo impone
  Android; opción "solo cargando") ejecutando el MISMO núcleo Dart vía
  engine headless — cero lógica duplicada
- ✅ Regla **`load-rising`**: caída sostenida de memoria/disco a lo largo
  del historial — la distorsión que crece como indicio temprano
- ✅ **Volúmenes de almacenamiento**: tarjeta SD / USB detectados y
  reportados por separado; sin tarjeta, la sección no aparece
- ✅ **Acciones de intervención**: cada hallazgo de disco/batería abre la
  pantalla del sistema donde el usuario SÍ puede actuar; ficha de sistema
  por app; limpiar caché propia
- ✅ Pestaña **Cercanía**: escaneo BLE manual opt-in con marca de
  persistencia (sin permiso INTERNET; `BLUETOOTH_SCAN` con
  `neverForLocation`)
- ✅ Español por defecto con toggle EN persistente

## v0.1.1 — Landing + APKs por ABI

- ✅ Landing page en GitHub Pages (mismo esquema que la edición Windows)
- ✅ Release publica APKs divididos por ABI (arm64-v8a / armeabi-v7a,
  ≈ 1/3 del peso) además del universal
- ✅ Trade-off de peso Flutter vs Rust documentado con números en
  ARCHITECTURE.md

## v0.1.0 — Fundación multiplataforma

- ✅ Arquitectura Flutter: núcleo Dart compartido + colectores nativos
  (Kotlin/Swift) por MethodChannel
- ✅ Motor de reglas local con 6 familias de hallazgo y umbrales centralizados
- ✅ Auditoría de superficie de permisos por app (Android)
- ✅ Indicadores de root/jailbreak honestos
- ✅ Historial local (JSON Lines, retención 500) + export JSON forense
- ✅ UI Material 3 bilingüe ES/EN con semáforo y evidencia
- ✅ CI multiplataforma (Android + iOS) y release Android automatizado

## v0.2.x — Profundidad Android (pendiente)

- [ ] Regla de parche de seguridad antiguo (> N meses → warning)
- [ ] Baseline de apps instaladas: detectar apps NUEVAS entre capturas
  (equivalente móvil del `persistence-change` de la edición Windows)
- [ ] Comparación A vs B en el tab Historial con deltas
- [ ] Permiso `PACKAGE_USAGE_STATS` opcional (opt-in del usuario) para
  consumo real de batería/datos por app
- [ ] Notificación local cuando el veredicto pasa a Critical

## v0.3.x — iOS de primera clase (EN PAUSA)

> Decisión 2026-07-15: la distribución iOS queda en pausa por decisión del
> autor. El build iOS se mantiene compilando en CI como vigilancia de
> regresión del código compartido, sin trabajo adicional de plataforma.

- [ ] Cuenta Apple Developer + `release-ios.yml` (TestFlight)
- [ ] Colector iOS ampliado (memoria con mach APIs, jailbreak avanzado)
- [ ] Paridad de UI/estado por plataforma documentada

## Ideas evaluadas y pospuestas

| Idea | Por qué se pospone |
|---|---|
| VPN local para inspección de tráfico | Gran superficie de código y de confianza; contradice "cero red" v0.1 |
| Análisis de APK (hashes contra listas) | Requiere red o bases locales grandes |
| Modo empresa (MDM) | Primero validar el producto individual |
| Núcleo Rust compartido vía FFI (colectores en Rust, UI Flutter) | Ganancia real solo si el peso/consumo se vuelven críticos; hoy el costo de complejidad no se justifica — ver trade-off en [ARCHITECTURE.md](ARCHITECTURE.md#trade-off-honesto-peso-del-apk-flutter-vs-rust) |

## Principios que no cambian

1. Todo hallazgo declarado debe ser **verificable en el código**.
2. Ninguna promesa que el SO no permita cumplir.
3. Privacidad por diseño: sin `INTERNET`, evidencia solo local/exportada.
