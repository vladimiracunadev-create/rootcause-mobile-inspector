# Roadmap

## v0.4.0 — Consumo real, parche antiguo y widget (actual)

- ✅ **Tiempo en pantalla por app** (opt-in REAL: el permiso especial de
  acceso de uso solo puede concederlo el usuario en Ajustes): cada app
  muestra su uso de 24 h y la lista se ordena por consumo — la respuesta
  a "¿qué app me está gastando el teléfono?". Sin permiso, la columna no
  existe y un botón lleva a la pantalla del sistema.
- ✅ Regla **`patch-old`**: parche de seguridad ≥ 180 días → warning,
  ≥ 365 → critical, con botón "Buscar actualizaciones". En iOS se omite
  (no hay fecha de parche que evaluar).
- ✅ **Widget de pantalla de inicio**: el semáforo + puntaje + hora sin
  abrir la app; se refresca tras cada captura (también las del Worker)
  y al tocarlo abre RootCause.

## v0.3.0 — El sensor que avisa

El monitoreo continuo cierra el círculo: vigilar → detectar → avisar.

- ✅ **Notificación local de veredicto crítico**: cuando una captura en
  segundo plano pasa a CRÍTICO, el teléfono avisa — solo en la
  transición, no cada 15 minutos. 100 % local (sin INTERNET no hay push:
  es el dispositivo avisándose a sí mismo). Opt-out en Configuración.
- ✅ **Baseline de apps** (`new-apps`): detecta apps instaladas entre
  capturas — el equivalente móvil del `persistence-change` de la edición
  Windows. Primera captura silenciosa; reinstalar también cuenta.
- ✅ **Tendencia visible + comparación A→B** en Historial: gráfico de RAM
  disponible y disco libre sobre las capturas, y selección de dos
  capturas con deltas (memoria, disco, puntaje, apps riesgosas).
- ✅ Flujo de captura unificado (`CaptureService`): la app abierta y el
  Worker ejecutan exactamente la misma política.
- Verificado end-to-end con el build release en emulador: la alerta
  crítica se disparó en vivo al forzar umbrales.

## v0.2.1 — Arranque release reparado + capa del fabricante

- ✅ **Fix del crash de primer arranque de v0.2.0 en release** (reportado
  en un Samsung A35 5G y reproducido con el APK publicado): R8 eliminaba
  el constructor de `WorkDatabase_Impl` que WorkManager instancia por
  reflexión al iniciar el proceso. Triple corrección: reglas R8 explícitas
  (`proguard-rules.pro`), inicialización de WorkManager **bajo demanda**
  (nada corre en el arranque) y colectores aislados que capturan
  `Throwable`. Verificado con el build release en emulador: arranque
  limpio + worker en segundo plano escribiendo historial.
- ✅ Pestaña Dispositivo muestra la **capa del fabricante** (One UI,
  MIUI, ColorOS, EMUI…) cuando el equipo la expone.

## v0.2.0 — Control, tendencia y cercanía

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

## Pendiente

- [ ] Cercanía: histórico de escaneos entre sesiones (opt-in) para
  detectar rastreadores a lo largo de días
- [ ] Refinamiento del widget (tamaños, tema del sistema)

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
