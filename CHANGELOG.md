# Changelog

Todos los cambios notables de RootCause Mobile Inspector. El formato sigue
[Keep a Changelog](https://keepachangelog.com/es/1.1.0/) y el proyecto usa
[SemVer](https://semver.org/lang/es/). La versión actual es la fuente de
verdad en `pubspec.yaml`.

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
