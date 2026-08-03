# Changelog

Todos los cambios notables de RootCause Mobile Inspector. El formato sigue
[Keep a Changelog](https://keepachangelog.com/es/1.1.0/) y el proyecto usa
[SemVer](https://semver.org/lang/es/). La versión actual es la fuente de
verdad en `pubspec.yaml`.

## [0.8.0] - 2026-08-03 — De la superficie al comportamiento

Hasta aquí el sensor evaluaba lo que una app **declara** (permisos) y lo
que el equipo **tiene** (RAM, disco). Esta versión añade una segunda capa:
lo que cada app **hace**, comparada consigo misma.

### Added

- **Consumo fuera de lo habitual** (`app-usage-anomaly`): detecta una app
  cuyo consumo de datos o tiempo en pantalla se dispara contra su **propia
  mediana histórica**. No hay umbral global inventado — no existe una cifra
  de "MB al día" que valga igual para un reproductor de vídeo y para una
  app de notas. Es **CRÍTICO** cuando la app además tiene una capacidad de
  espionaje concedida y activa: capacidad real + consumo disparado es la
  coincidencia que de verdad importa.
- **App instalada al empezar el deterioro** (`load-rising-suspect`):
  correlación temporal entre un deterioro sostenido de recursos y las apps
  instaladas en las 12 h previas. El hallazgo dice explícitamente, en los
  cinco idiomas, que **coincidir en el tiempo no es causar**: da el primer
  sitio donde mirar, no un culpable.
- **Elección de interfaz en el primer arranque**: la introducción pregunta
  cuánta información quieres en pantalla (Básica / Normal / Avanzada) con
  la **básica ya marcada**. Se puede cambiar cuando sea en Configuración.
- **Tests de la capa nativa**: la lógica de decisión Kotlin vive ahora en
  `CollectorLogic.kt` (sin dependencias de Android) con **20 tests JVM**
  que corren en CI sin emulador. Cubre origen de instalación, componentes
  activos (la base de la detección de stalkerware), capa del fabricante,
  indicadores de root y tamaño de caché.
- **Verificación del claim "cero red"**: `scripts/check-no-internet.sh`
  falla el build si el manifiesto **fusionado de release** declarase
  `INTERNET`. Protege la premisa contra una dependencia futura, no solo
  contra un descuido propio. Corre en cada build de CI.
- **Test de integración en emulador dentro de CI**
  (`integration-android.yml`): cada noche y a demanda. Es lo único que
  ejercita de punta a punta el camino Kotlin ↔ MethodChannel ↔ Dart.

### Changed

- **El modo de visualización por defecto pasa de `normal` a `simple`.**
  Quien instala esto asustado no debería estrellarse contra diez pestañas
  técnicas. **Una configuración existente conserva su modo**: el cambio
  solo afecta a instalaciones nuevas.
- **`lib/ui/screens.dart` (1.900 líneas) partido por pestaña** bajo
  `lib/ui/screens/`, con `screens.dart` como barril: los imports existentes
  siguen funcionando igual. Los textos que más crecen (hallazgos y
  permisos) salen de `strings.dart` a `lib/ui/strings/`. Sin cambios de
  comportamiento.
- El baseline de apps registra `createdMillis` para distinguir las apps que
  entraron con la **inicialización** (fecha desconocida, nunca se señalan)
  de las instalaciones realmente **observadas**.

### Fixed

- El ROADMAP declaraba v0.5.0 como versión actual con el proyecto en 0.7.0,
  y listaba como pendiente el portugués, entregado en v0.6.0.

## [0.7.0] - 2026-07-27 — De superficie a capacidad real

### Added

- **Permisos concedidos vs. solicitados**: cada app distingue los permisos
  peligrosos que TIENE concedidos ahora (resaltados) de los que solo pide.
  El salto de "esta app pide el micrófono" a "esta app TIENE el micrófono".
- **Detección de stalkerware activo**: se señala en rojo, arriba de todo,
  cuando una app tiene un **servicio de accesibilidad**, un **lector de
  notificaciones** o un **administrador de dispositivo** ACTIVOS — el vector
  clásico de espionaje. Suben el puntaje de riesgo con fuerza.
- **Escalada de permisos** (`perm-escalation`): avisa cuando una app YA
  conocida gana permisos peligrosos desde la captura anterior (típicamente
  tras actualizarse). El "¿por qué ahora quiere el micrófono?".
- **Consumo de datos por app** (24 h): con el acceso de uso, cada app muestra
  cuántos datos movió — hermano del tiempo en pantalla.
- **Íconos reales de las apps**: la lista muestra el ícono de cada app para
  reconocerla de un vistazo (no solo el nombre).
- **Modos de visualización** (Configuración): **Simple** (solo Resumen,
  Señaladas y Configuración, para personas no técnicas / tercera edad),
  **Normal** y **Avanzado** (todo, incluida Cercanía Bluetooth).
- **Gráfico de tendencia en el informe PDF**: RAM disponible y disco libre
  como líneas vectoriales, además de la tabla.

### Changed

- **Accesibilidad**: las tarjetas de app se leen como una sola unidad para
  lectores de pantalla y respetan el tamaño de fuente del sistema.
- El export JSON incluye los permisos concedidos, el consumo de datos y las
  escaladas de permisos (campos nuevos, esquema compatible).

## [0.6.0] - 2026-07-27 — Cerca de quien la usa

### Added

- **Pestaña "Señaladas"**: lista dedicada y contador de las apps con
  superficie de permisos riesgosa o instaladas fuera de la tienda,
  ordenadas por riesgo. Reencuadra lo que la app ya detectaba en una vista
  corta y accionable (sigue sin poder "bloquear": Android/iOS no lo
  permiten).
- **Cuatro idiomas nuevos y autodetección**: además de español e inglés,
  ahora portugués, italiano y francés. El idioma por defecto se toma de la
  configuración del equipo; se puede fijar a mano (o volver a
  "Automático") desde el menú de idioma o Configuración.

### Changed

- **Permisos en lenguaje humano**: cada permiso peligroso se muestra con
  una descripción clara (p. ej. "Ubicación precisa (GPS)", "Micrófono
  (grabar audio)") en vez de la constante técnica de Android. Pensado para
  personas sin formación técnica y de la tercera edad.
- **Apps en orden alfabético**: sin el acceso de uso, la lista de apps se
  ordena por nombre (con el acceso de uso se mantiene el orden por consumo).
- **Informe forense en PDF**: el informe compartible pasa de Markdown a un
  PDF generado en Dart puro (sin dependencias externas). Mismo contenido —
  veredicto, hallazgos, métricas, tendencia e integridad — en un archivo
  que cualquiera abre y lee.

## [0.5.0] - 2026-07-17 — Evidencia de verdad

### Added

- **Cadena de integridad**: cada captura del historial se sella con
  SHA-256 encadenado (implementación Dart pura, verificada contra
  vectores FIPS 180-4). El informe declara si la cadena verifica —
  evidencia manipulable se vuelve evidencia verificable.
- **Informe forense compartible**: botón que genera un Markdown legible
  (veredicto, hallazgos, métricas, tendencia, integridad) y lo comparte
  por el share sheet del sistema. Sigue sin permiso INTERNET.
- **Backup / restauración / borrado** de evidencia: exporta todo (config,
  historial, baseline, cercanía, registro de errores) a un JSON portable,
  restáuralo en otro teléfono, o borra la evidencia sin desinstalar.
- **Alerta de app espía**: notifica cuando se instala una app con
  superficie riesgosa o por sideload mientras la app vigila, aunque el
  veredicto global no sea crítico.
- **Baseline enriquecido**: además de apps NUEVAS, registra ACTUALIZADAS
  y ELIMINADAS (ciclo de vida completo, como la edición Windows).
- **Cercanía histórica** (opt-in): registra en qué días se vio cada
  dispositivo BLE para detectar rastreadores multi-día.
- **Registro local de errores**: si la app falla, el error queda en un
  archivo exportable (nunca se envía) — visible en Acerca.
- **Indicadores de integridad de arranque**: bootloader desbloqueado y
  verified boot no-verde se suman a los indicadores de root.
- **Temperatura de batería** en el gráfico de tendencia del Historial.
- **Introducción de primera vez** (3 pasos: qué es, qué no es, privacidad).
- **Widget** con tema claro/oscuro según el sistema.
- Accesibilidad: etiquetas semánticas en el semáforo y el gráfico.
- `CHANGELOG.md`, metadata para tiendas (IzzyOnDroid/F-Droid) y política
  de privacidad pública.

### Changed

- El export forense documenta su política de `schemaVersion` (campos
  nuevos no suben la versión; los lectores ignoran lo desconocido).

## [0.4.0] - 2026-07-17 — Consumo, parche y widget

### Added

- Tiempo en pantalla por app con el acceso de uso (opt-in real).
- Regla `patch-old`: parche de seguridad antiguo (≥ 180 días warning,
  ≥ 365 critical).
- Widget de pantalla de inicio con el semáforo.

## [0.3.0] - 2026-07-17 — El sensor que avisa

### Added

- Notificación local de veredicto crítico (solo en la transición).
- Baseline de apps: detección de instalaciones nuevas (`new-apps`).
- Historial con gráfico de tendencia y comparación A→B.

## [0.2.1] - 2026-07-17

### Fixed

- Crash de primer arranque en release (R8 eliminaba un constructor de
  WorkManager). WorkManager pasa a inicialización bajo demanda.

### Added

- Capa del fabricante (One UI, MIUI, ColorOS…) en Dispositivo.

## [0.2.0] - 2026-07-16 — Control, tendencia y cercanía

### Added

- Configuración: auto-captura (5 min por defecto), captura en segundo
  plano (WorkManager) y umbrales modificables.
- Regla `load-rising` (carga en ascenso sostenido).
- Volúmenes de almacenamiento (tarjeta SD / USB).
- Acciones de intervención que abren la pantalla del sistema.
- Pestaña Cercanía (escaneo BLE opt-in).
- Español por defecto con toggle a inglés persistente.

## [0.1.1] - 2026-07-15

### Added

- Landing en GitHub Pages y APKs divididos por ABI.

## [0.1.0] - 2026-07-15 — Fundación

### Added

- Arquitectura Flutter (núcleo Dart + colectores Kotlin/Swift por
  MethodChannel), motor de reglas local, historial JSON Lines, export
  forense, UI Material 3 bilingüe y CI/CD.

[0.5.0]: https://github.com/vladimiracunadev-create/rootcause-mobile-inspector/releases/tag/v0.5.0
[0.4.0]: https://github.com/vladimiracunadev-create/rootcause-mobile-inspector/releases/tag/v0.4.0
[0.3.0]: https://github.com/vladimiracunadev-create/rootcause-mobile-inspector/releases/tag/v0.3.0
[0.2.1]: https://github.com/vladimiracunadev-create/rootcause-mobile-inspector/releases/tag/v0.2.1
[0.2.0]: https://github.com/vladimiracunadev-create/rootcause-mobile-inspector/releases/tag/v0.2.0
[0.1.1]: https://github.com/vladimiracunadev-create/rootcause-mobile-inspector/releases/tag/v0.1.1
[0.1.0]: https://github.com/vladimiracunadev-create/rootcause-mobile-inspector/releases/tag/v0.1.0
