# Catálogo de la familia RootCause

Documento fuente de verdad para distinguir las **dos ediciones** de la familia
RootCause: qué cubre cada una, qué comparten y a quién sirve cada una. Si una
superficie pública (landing, README, release) contradice este catálogo, este
documento tiene prioridad.

## 1. Las dos ediciones

| | RootCause **Windows** Inspector | RootCause **Mobile** Inspector |
|---|---|---|
| Versión | v0.19.0 | v0.1.1 |
| Lenguaje | Rust (GUI egui + CLI) | Flutter (Dart + Kotlin + Swift) |
| Plataforma | Windows 10/11 | Android 8.0+ (producción) · iOS 13+ (compila en CI, distribución en pausa) |
| Qué es | Sensor forense de escritorio con señales de comportamiento (persistencia, servicios, red local, anomalías) — declaradamente **no** un antivirus ni un EDR: complementa, no reemplaza | Sensor forense de bolsillo: distorsiones de memoria, almacenamiento, batería y red + auditoría de superficie de permisos por app |
| Distribución | GitHub Release: instalador, portable, CLI-only, módulo PowerShell, extensión VS Code | GitHub Release: APK firmado por ABI (arm64-v8a, armeabi-v7a) + universal |
| Repo | <https://github.com/vladimiracunadev-create/rootcause-windows-inspector> | <https://github.com/vladimiracunadev-create/rootcause-mobile-inspector> |
| Landing | <https://vladimiracunadev-create.github.io/rootcause-windows-inspector/> | <https://vladimiracunadev-create.github.io/rootcause-mobile-inspector/> |

## 2. Qué cubre cada una

### Edición Windows (Rust)

- Semáforo global, top de procesos con severidad, presión CPU/RAM/I/O.
- Baselines de **autoarranque**, **servicios** y **red conocida** con
  clasificación NUEVO/MODIFICADO/ELIMINADO y alertas (`persistence-change`,
  `service-change`, `unknown-device`).
- Modo de precisión ETW/WPR, historial SQLite con comparación A/B, reportes
  forenses en Markdown, CLI completa.

### Edición Mobile (Flutter)

- Semáforo global + motor de reglas local con 6 familias de hallazgo:
  memoria, almacenamiento, temperatura/salud de batería, superficie de
  permisos por app (Android), root/jailbreak
  (→ [HEURISTICAS.md](HEURISTICAS.md)).
- Historial local (JSON Lines, retención 500) y export JSON forense.
- Límites del SO declarados, no disfrazados: iOS no permite listar apps
  ajenas y Android no expone CPU/RAM de otras apps
  (→ [LIMITACIONES.md](LIMITACIONES.md)).

## 3. Qué comparten (el ADN de la familia)

| Rasgo común | Concreción |
|---|---|
| Filosofía | Cualquier distorsión anómala de recursos puede ser el primer indicio; diagnóstico primero, intervención después |
| Export forense comparable | JSON con **ids de hallazgo neutrales al idioma**, estables entre versiones y comparables entre ediciones y dispositivos |
| Privacidad | Todo local: cero telemetría; la edición móvil ni siquiera declara el permiso `INTERNET` |
| Honestidad técnica | Mapa explícito de qué se detecta y qué queda fuera por diseño del SO (`DETECCION_AMENAZAS.md` en ambos repos) |
| Interfaz | Bilingüe español/inglés, semáforo por severidad, evidencia junto a cada hallazgo |
| Entrega | CI en GitHub Actions, release automatizado por tag con hashes `SHA256SUMS.txt` |
| Licencia | Apache 2.0 en ambas |

La diferencia de peso entre ambas (binario Rust ~MB de un dígito vs APK
Flutter) está documentada con números en el trade-off de
[ARCHITECTURE.md](ARCHITECTURE.md#trade-off-honesto-peso-del-apk-flutter-vs-rust).

## 4. A quién sirve cada una

| Perfil | Edición recomendada | Por qué |
|---|---|---|
| Soporte técnico / power user de PC | Windows | Correlación proceso-disco-red-servicios y ruta ETW/WPR para casos duros |
| Analista que vigila persistencia y cambios | Windows | Motor de baselines (autoarranque, servicios, red local) con alertas |
| Usuario de teléfono con síntomas ("va lento", "se calienta") | Mobile | Semáforo + evidencia sin conocimientos técnicos |
| Quien audita qué apps piden permisos peligrosos | Mobile (Android) | Puntaje de riesgo por superficie de permisos, overlay/sideload/device-admin |
| Quien necesita evidencia de PC **y** teléfono en un mismo caso | Ambas | Los exports JSON usan ids comparables entre ediciones |

## 5. Reglas de comunicación

- Ninguna edición se presenta como antivirus, EDR ni "limpiador mágico":
  ambas son **sensores de apoyo a la decisión** que dejan evidencia.
- No prometer en una edición lo que solo existe en la otra (p. ej. baseline
  de apps instaladas: entregado en Windows, planificado en móvil →
  [ROADMAP.md](ROADMAP.md)).
- iOS se comunica siempre como "compila en CI, distribución en pausa" — nunca
  como plataforma soportada en producción.
- Un botón de descarga no debe prometer un artefacto que el workflow no
  publica.
