# Roadmap

## v0.8.0 — De la superficie al comportamiento (actual)

El salto conceptual: hasta aquí el sensor evaluaba lo que una app
**declara** (permisos) y lo que el equipo **tiene** (RAM, disco). Ahora
evalúa lo que cada app **hace**, comparada consigo misma.

- ✅ **`app-usage-anomaly`**: una app cuyo consumo de datos o tiempo en
  pantalla se dispara contra su **propia mediana histórica**. Sin umbral
  global inventado: no existe una cifra de "MB al día" que valga igual para
  un reproductor de vídeo y para una app de notas. **CRÍTICO** si además
  tiene una capacidad de espionaje concedida y activa.
- ✅ **`load-rising-suspect`**: correlación temporal — si hay deterioro
  sostenido de recursos Y una app se instaló en la ventana de 12 h, se
  nombra la coincidencia, diciendo explícitamente que **coincidir no es
  causar**.
- ✅ **Elección de interfaz en el arranque**: la introducción de primera vez
  pregunta cuánta información quieres en pantalla, con la **básica marcada**.
  Quien instala esto asustado no debería estrellarse contra diez pestañas
  técnicas; el modo por defecto pasó de `normal` a `simple`.
- ✅ **La capa nativa deja de ser terreno sin tests**: la lógica de decisión
  vive en `CollectorLogic.kt` (sin dependencias de Android) con **20 tests
  JVM** en CI, y el test de integración en emulador corre en CI cada noche
  ([`integration-android.yml`](../.github/workflows/integration-android.yml)).
- ✅ **"Cero red" pasa de promesa a hecho verificado**: `check-no-internet.sh`
  falla el build si el manifiesto **fusionado de release** declarase
  `INTERNET`. Protege el claim contra una dependencia futura, no solo
  contra un descuido propio.
- ✅ **Deuda estructural saldada**: `screens.dart` (1.900 líneas) partido por
  pestaña bajo `ui/screens/`, y los textos que más crecen (hallazgos y
  permisos) fuera de `strings.dart`. Sin cambios de comportamiento.

## v0.7.0 — De superficie a capacidad real

- ✅ **Permisos concedidos vs. solicitados**: de "esta app pide el
  micrófono" a "esta app **TIENE** el micrófono".
- ✅ **Stalkerware activo**: accesibilidad, lector de notificaciones y
  administrador de dispositivo ACTIVOS, señalados arriba y en rojo.
- ✅ **`perm-escalation`**: una app ya conocida gana permisos peligrosos.
- ✅ **Consumo de datos por app** (24 h) e **íconos reales**.
- ✅ **Modos de visualización** Simple / Normal / Avanzado.
- ✅ **Gráfico de tendencia en el informe PDF**.

## v0.6.0 — Cerca de quien la usa

- ✅ **Pestaña Señaladas**: solo las apps que importan, ordenadas por riesgo.
- ✅ **Cinco idiomas con autodetección** (ES/EN/PT/IT/FR).
- ✅ **Permisos en lenguaje humano**: "Micrófono (grabar audio)" en vez de
  `RECORD_AUDIO`.
- ✅ **Informe forense en PDF** compartible.

## v0.5.0 — Evidencia de verdad

Robustez de producto: la evidencia se vuelve portable, íntegra y que
avisa a tiempo.

- ✅ **Cadena de integridad**: historial sellado con SHA-256 encadenado
  (Dart puro, vectores FIPS); `verifyChain()` detecta manipulación y el
  informe lo declara.
- ✅ **Informe forense compartible** (Markdown por el share sheet) +
  **backup/restauración/borrado** de toda la evidencia.
- ✅ **Alerta de app espía**: notifica apps nuevas riesgosas/sideload
  aunque el veredicto global no sea crítico.
- ✅ **Baseline enriquecido** (nuevas/actualizadas/eliminadas),
  **cercanía histórica** multi-día (opt-in), **registro local de errores**,
  indicadores de **bootloader/verified boot** y **temperatura** en la
  tendencia.
- ✅ **Onboarding** de primera vez, **widget** con tema día/noche y
  etiquetas de **accesibilidad**.
- ✅ CHANGELOG, metadata de tiendas, política de privacidad pública y
  guía de distribución (IzzyOnDroid/F-Droid) — ver
  [DISTRIBUCION.md](DISTRIBUCION.md).

## v0.4.0 — Consumo real, parche antiguo y widget

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

Lo que sigue abierto, con el motivo real por el que lo está.

- [ ] **Firma permanente y envío a IzzyOnDroid / F-Droid**. Es el cuello de
      botella de adopción, no de código: mientras el único camino sea
      descargar un APK y autorizar orígenes desconocidos, la base de
      usuarios queda en quienes ya saben hacerlo — que no son las personas
      que más necesitan un detector de stalkerware. **Requiere una acción
      del autor** (generar y custodiar la clave permanente) →
      [DISTRIBUCION.md](DISTRIBUCION.md).
- [ ] **Builds reproducibles verificables públicamente**: el complemento
      natural de `check-no-internet.sh` — que cualquiera pueda comprobar
      que el APK publicado sale exactamente de este código.
- [ ] **Distribución iOS**: requiere cuenta Apple Developer. Hasta
      entonces la plataforma se valida compilando en CI (`--no-codesign`).
- [ ] **Anomalía de uso en la propia UI**: hoy `app-usage-anomaly` llega
      como hallazgo en Resumen; falta mostrar la serie histórica de una app
      concreta ("esto es lo que hacía, esto es lo que hace").
- [ ] **Refinamiento del widget** (más tamaños).
