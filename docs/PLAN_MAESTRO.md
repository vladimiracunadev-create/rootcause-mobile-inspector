# Plan Maestro — RootCause Mobile Inspector

**Versión base:** v0.2.1 · **Actualizado:** 2026-07-16
**Propósito:** visión del producto y plan por fases. Este documento es la
brújula; el detalle ítem por ítem vive en [ROADMAP.md](ROADMAP.md) y este plan
nunca lo contradice.

## I. De dónde viene

RootCause Mobile Inspector es el **hermano móvil** de
[rootcause-windows-inspector](https://github.com/vladimiracunadev-create/rootcause-windows-inspector)
(Rust, v0.19.0). Hereda su razón de existir: **cualquier distorsión anómala de
los recursos puede ser el primer indicio de que algo está ocurriendo.** En el
escritorio eso significa CPU, disco, procesos y autoarranque; en el móvil,
memoria, almacenamiento, batería, red y superficie de permisos.

La traducción al móvil no es un port literal: es la misma filosofía aplicada a
lo que Android e iOS **sí permiten observar** a una app de usuario. Lo que el
SO no expone se declara como límite, no se disfraza
(→ [LIMITACIONES.md](LIMITACIONES.md)).

```text
RootCause Windows  → sensor forense de escritorio (Rust, GUI + CLI)
RootCause Mobile   → sensor forense de bolsillo   (Flutter, Android + iOS)
Ambos              → diagnóstico primero, intervención después
```

## II. Fase actual — v0.2.x: sensor Android con control y tendencia

Qué hay hoy, verificable en el código y en los releases:

- Núcleo Dart compartido + colectores nativos Kotlin/Swift por MethodChannel.
- Motor de reglas local con 7 familias de hallazgo
  (→ [HEURISTICAS.md](HEURISTICAS.md)), umbrales **modificables por el
  usuario** y regla de tendencia `load-rising` sobre el historial.
- Auto-captura configurable (5 min por defecto, como el original de
  escritorio) + captura en segundo plano con WorkManager (opción
  solo-cargando) ejecutando el mismo núcleo vía engine headless.
- Auditoría de superficie de permisos por app (Android), indicadores
  honestos de root/jailbreak y volúmenes de almacenamiento (SD/USB).
- Acciones de intervención que abren la pantalla exacta del sistema, y
  pestaña Cercanía (escaneo BLE opt-in, sin permiso INTERNET).
- Historial local (JSON Lines, retención 500) + export JSON forense con ids
  neutrales al idioma, comparables con la edición Windows.
- APK firmado publicado por CI (por ABI + universal) y landing en GitHub Pages.

**iOS: en pausa.** Decisión del autor (2026-07-15): la distribución iOS queda
detenida. El build iOS se mantiene compilando en CI (`--no-codesign`) como
vigilancia de regresión del código compartido, sin trabajo adicional de
plataforma.

## III. Fases siguientes

### Fase 1 — v0.2.x: profundidad Android

La prioridad es profundizar donde ya hay producción. Ítems (detalle en
[ROADMAP.md](ROADMAP.md)):

- Regla de parche de seguridad antiguo.
- **Baseline de apps instaladas**: detectar apps nuevas entre capturas — el
  equivalente móvil del `persistence-change` de la edición Windows. Es el paso
  que lleva el patrón "estado bueno conocido → clasificar cambios" a móvil.
- Comparación A vs B en Historial con deltas.
- `PACKAGE_USAGE_STATS` opcional (opt-in del usuario) para consumo real por app.
- Notificación local cuando el veredicto pasa a Critical.

### Fase 2 — v0.3.x: iOS de primera clase (EN PAUSA)

Bloqueada por la decisión de la fase actual. Cuando se retome: cuenta Apple
Developer + `release-ios.yml` (TestFlight), colector iOS ampliado y paridad de
UI/estado documentada por plataforma.

### Largo plazo — evaluado y pospuesto

VPN local para inspección de tráfico, análisis de APK contra listas, modo
empresa (MDM) y núcleo Rust compartido vía FFI están **evaluados y pospuestos**
con su justificación en la tabla final de [ROADMAP.md](ROADMAP.md). No entran
al plan hasta que cambien las condiciones ahí descritas.

## IV. Principios que no cambian

1. Todo hallazgo declarado debe ser **verificable en el código**.
2. Ninguna promesa que el SO no permita cumplir.
3. Privacidad por diseño: sin permiso `INTERNET`, evidencia solo
   local/exportada, cero telemetría.
4. El motor de reglas se mantiene en Dart puro: 100 % testeable sin
   dispositivo.
5. Los ids de hallazgo son estables y neutrales al idioma: el export forense
   debe seguir siendo comparable entre dispositivos y con la edición Windows.

## V. Reglas de trabajo por sesión

```text
1. git log --oneline -3        → ¿en qué commit estamos?
2. CI en GitHub Actions        → ¿verde o rojo? (si rojo, arreglar primero)
3. Leer ROADMAP.md             → ¿qué ítem de la fase actual sigue?
4. Cambio hecho → dart format + flutter analyze + flutter test antes de commit
5. Release → checklist de RELEASE_MOVIL.md (tag = versión de pubspec.yaml)
```

Al modificar el producto de forma significativa, actualizar las secciones
afectadas de este documento y de [ROADMAP.md](ROADMAP.md) en el mismo commit.
