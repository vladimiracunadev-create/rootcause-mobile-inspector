# Plan Maestro — RootCause Mobile Inspector

**Versión base:** v0.5.0 · **Actualizado:** 2026-07-16
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

## II. Fase actual — v0.5.x: evidencia de verdad

Qué hay hoy, verificable en el código y en los releases:

- Núcleo Dart compartido + colectores nativos Kotlin/Swift por MethodChannel.
- Motor de reglas local con 9 familias de hallazgo
  (→ [HEURISTICAS.md](HEURISTICAS.md)), umbrales **modificables por el
  usuario**, tendencia `load-rising`, baseline de apps `new-apps`
  (el `persistence-change` móvil) y parche antiguo `patch-old`.
- **Evidencia íntegra y portable**: historial sellado con cadena de
  hashes SHA-256 verificable, informe forense compartible y
  backup/restauración/borrado de toda la evidencia.
- Auto-captura configurable + captura en segundo plano con WorkManager
  (opción solo-cargando) con **notificación local de veredicto crítico**
  y de **app espía** recién instalada — todo por el mismo núcleo vía
  engine headless.
- Tiempo en pantalla por app con el permiso de acceso de uso (opt-in
  real) y **widget de pantalla de inicio** con el semáforo (día/noche).
- Auditoría de superficie de permisos por app (Android), indicadores
  honestos de root/jailbreak (incl. bootloader/verified boot) y
  volúmenes de almacenamiento (SD/USB).
- Acciones de intervención que abren la pantalla exacta del sistema, y
  pestaña Cercanía (escaneo BLE opt-in, con histórico multi-día).
- Historial local (JSON Lines, retención 500) con tendencia visible
  (memoria, disco y temperatura) y comparación A→B + export JSON forense.
- Onboarding de primera vez, accesibilidad y registro local de errores.
- APK firmado publicado por CI (por ABI + universal) y landing en GitHub Pages.

**iOS: en pausa.** Decisión del autor (2026-07-15): la distribución iOS queda
detenida. El build iOS se mantiene compilando en CI (`--no-codesign`) como
vigilancia de regresión del código compartido, sin trabajo adicional de
plataforma.

## III. Fases siguientes

### Fase 1 — distribución y confianza (lo que queda)

El producto ya es robusto; el freno ahora es la adopción. Ítems (detalle
en [DISTRIBUCION.md](DISTRIBUCION.md) y [ROADMAP.md](ROADMAP.md)):

- Firma permanente (secretos del keystore) — requiere acción del autor.
- Envío a IzzyOnDroid y F-Droid con la metadata ya preparada.
- Builds reproducibles verificables públicamente.
- Portugués (PT-BR) y refinamiento del widget.

### Fase 2 — iOS de primera clase (EN PAUSA)

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
