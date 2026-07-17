# Documento para reclutadores

> Guía rápida para reclutadores y líderes técnicos que evalúan al autor
> (Vladimir Acuña): qué es RootCause Mobile Inspector y qué capacidades
> profesionales concretas demuestra este repositorio. Cada afirmación es
> verificable en el código.

## 1. Resumen ejecutivo

**RootCause Mobile Inspector** (v0.2.1) es un sensor forense de diagnóstico
para **Android e iOS**, construido con **Flutter 3.44.6 / Dart 3.12**. Es el
hermano móvil de
[rootcause-windows-inspector](https://github.com/vladimiracunadev-create/rootcause-windows-inspector)
(Rust, v0.19.0): misma filosofía — cualquier distorsión anómala de recursos
puede ser el primer indicio de un problema — aplicada a lo que un teléfono sí
permite observar. Todo local, cero telemetría, Apache 2.0.

No se vende como antivirus ni "limpiador mágico": es una herramienta de
diagnóstico y evidencia, con sus límites declarados por escrito.

## 2. Qué demuestra este repositorio, en concreto

### Flutter multiplataforma con canal nativo propio

- Núcleo Dart compartido + colectores nativos escritos a mano en **Kotlin**
  (`android/app/src/main/kotlin/.../AndroidCollectors.kt`) y **Swift**
  (`ios/Runner/AppDelegate.swift`), unidos por un **MethodChannel propio**
  (`lib/platform/collectors.dart`).
- **Cero paquetes de pub.dev en runtime**: `pubspec.yaml` solo depende del
  SDK de Flutter (la única dependencia externa es `flutter_lints`, y solo en
  desarrollo). Todo el acceso a plataforma es código propio, no plugins de
  terceros.

### Motor de reglas Dart puro, 100 % testeable

- `lib/core/rule_engine.dart` no toca plataforma: recibe un snapshot y
  produce hallazgos con severidad, evidencia y recomendación (7 familias,
  incluida la tendencia temporal `load-rising`, especificadas en
  [HEURISTICAS.md](HEURISTICAS.md)).
- Suite de tests sobre el núcleo Dart (motor, modelos, export forense,
  historial) más tests de widget — corre en segundos, sin dispositivo ni
  emulador (→ [TESTING.md](TESTING.md)).
- Export JSON forense con **ids de hallazgo neutrales al idioma**,
  comparables entre dispositivos y con la edición Windows.

### CI/CD con criterio de seguridad

- Actions oficiales **pinneadas a commit SHA** (no a tags móviles), permisos
  mínimos por workflow, timeouts y concurrency explícitos.
- Flutter se instala clonando el **tag exacto** del SDK — sin actions de
  terceros en la cadena de suministro.
- Release por tag con puertas reales: verificación tag ↔ `pubspec.yaml`,
  tests previos obligatorios, **firma del APK con secretos** del repositorio
  y **fallback documentado a clave efímera** (el modo de firma se declara en
  las notas del release), APKs por ABI + universal y `SHA256SUMS.txt`.
- Detalle completo en [CI_GITHUB.md](CI_GITHUB.md) y
  [RELEASE_MOVIL.md](RELEASE_MOVIL.md).

### Documentación de nivel producto

Más de quince documentos en `docs/` ([índice](INDEX.md)): arquitectura con
diagramas, especificación exacta de cada heurística, estrategia de tests,
manual de usuario en dos niveles, guía de emulador, troubleshooting, política
de privacidad verificable en el código y landing en GitHub Pages
(<https://vladimiracunadev-create.github.io/rootcause-mobile-inspector/>).

### Honestidad técnica como decisión de ingeniería

- [LIMITACIONES.md](LIMITACIONES.md) declara lo que el SO no permite: iOS no
  deja listar apps ajenas; Android no expone CPU/RAM de otras apps. La app lo
  reporta como "no disponible", no lo disfraza.
- Los indicadores de root/jailbreak se comunican como **indicio, no prueba**.
- El trade-off de peso Flutter vs Rust está explicado **con números** en
  [ARCHITECTURE.md](ARCHITECTURE.md#trade-off-honesto-peso-del-apk-flutter-vs-rust).
- La pausa de la distribución iOS es una decisión registrada y fechada en
  [ROADMAP.md](ROADMAP.md), manteniendo el build iOS en CI como vigilancia de
  regresión. Alcance controlado, no promesas.

## 3. Tecnologías usadas

| Tecnología | Rol |
|---|---|
| Flutter / Dart | UI Material 3 bilingüe ES/EN + núcleo de reglas compartido |
| Kotlin | Colectores nativos Android (memoria, almacenamiento, batería, red, apps y permisos, root) |
| Swift | Colectores nativos iOS dentro de los límites del sandbox |
| MethodChannel | Puente propio Dart ↔ nativo, sin plugins externos |
| GitHub Actions | CI multiplataforma (Android + iOS) y release firmado por tag |

## 4. El portfolio completo

Este repositorio es la mitad móvil de una familia de dos productos del mismo
autor, que muestra rango en dos stacks distintos con una sola filosofía:

- **RootCause Windows Inspector** — Rust, sensor forense de escritorio con
  baselines de autoarranque/servicios/red local, ETW/WPR e historial SQLite:
  <https://github.com/vladimiracunadev-create/rootcause-windows-inspector>
- **RootCause Mobile Inspector** — este repositorio.

## 5. En una frase

> Un sensor forense móvil en Flutter con canal nativo propio, motor de reglas
> puro y testeable, CI/CD endurecido y documentación que dice la verdad sobre
> lo que el sistema operativo permite.

Autor: Vladimir Acuña ·
[@vladimiracunadev-create](https://github.com/vladimiracunadev-create)
