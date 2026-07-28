# Changelog

Todos los cambios notables de RootCause Mobile Inspector. El formato sigue
[Keep a Changelog](https://keepachangelog.com/es/1.1.0/) y el proyecto usa
[SemVer](https://semver.org/lang/es/). La versión actual es la fuente de
verdad en `pubspec.yaml`.

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
