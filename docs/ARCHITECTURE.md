# Arquitectura

## Visión general

RootCause Mobile Inspector usa **Flutter** con una separación estricta en tres capas:

```text
┌───────────────────────────────────────────────────────────┐
│  UI (lib/ui/ + lib/main.dart)                             │
│  Material 3 · tabs · semáforo · export · bilingüe ES/EN   │
├───────────────────────────────────────────────────────────┤
│  Núcleo compartido (lib/core/) — Dart puro, sin Flutter   │
│  models.dart · rule_engine.dart · snapshot_json.dart      │
│  history_store.dart                                       │
├───────────────────────────────────────────────────────────┤
│  Colectores nativos (MethodChannel "rootcause/collectors")│
│  android/ → Kotlin (MainActivity.kt)                      │
│  ios/     → Swift  (AppDelegate.swift)                    │
└───────────────────────────────────────────────────────────┘
```

### Por qué Flutter

- Un solo código para UI + motor de reglas + export en Android e iOS.
- Los colectores (lo único que de verdad difiere por SO) quedan aislados
  en un MethodChannel por plataforma.
- El motor de reglas es **Dart puro**: se testea en CI sin emulador.

## El contrato del MethodChannel

Canal: `rootcause/collectors`, con dos métodos:

- `collect` → mapa completo de estado (abajo)
- `documentsPath` → ruta del directorio de documentos del sandbox
  (historial y exports; evita depender del plugin `path_provider`)

El método `collect` devuelve:

```jsonc
{
  "memory":  { "totalBytes": 0, "availableBytes": 0, "lowMemory": false },
  "storage": { "totalBytes": 0, "freeBytes": 0, "appCacheBytes": 0 },
  "battery": { "levelPercent": 0, "charging": false, "temperatureCelsius": 0.0,
               "voltageMillivolts": 0, "healthy": true, "healthLabel": "good" },
  "network": { "connected": true, "transport": "wifi", "vpnActive": false,
               "metered": false, "downstreamKbps": 0, "upstreamKbps": 0,
               "totalRxBytes": 0, "totalTxBytes": 0 },
  "apps":    [ { "packageName": "...", "label": "...", "versionName": "...",
                 "dangerousPermissions": [], "specialFlags": [],
                 "sideloaded": false } ],
  "device":  { "manufacturer": "...", "model": "...", "osVersion": "...",
               "sdkInt": 0, "securityPatch": "...", "cpuCores": 0,
               "uptimeMillis": 0, "rootIndicators": [],
               "appsAuditSupported": true }
}
```

Reglas del contrato:

- **Campos siempre presentes** con defaults seguros; el Dart valida tipos y
  degrada a valores neutros si falta algo (nunca crashea por el nativo).
- `appsAuditSupported=false` en iOS: la UI muestra "no disponible por diseño
  del SO" en vez de una lista vacía engañosa.
- Los ids de hallazgo (`mem-pressure`, `storage-low`, `battery-temp`,
  `battery-health`, `risky-apps`, `root-indicators`) son estables y neutrales
  al idioma — mismos principios que la edición Windows.

## Motor de reglas (lib/core/rule_engine.dart)

Función pura `Snapshot → Verdict`:

| Regla | Warning | Critical |
|---|---|---|
| `mem-pressure` | disponible < 20 % | disponible < 10 % o flag lowMemory |
| `storage-low` | libre < 15 % | libre < 5 % |
| `battery-temp` | ≥ 40 °C | ≥ 45 °C |
| `battery-health` | salud reportada ≠ good/unknown | — |
| `risky-apps` | ≥ 1 app con score ≥ 8 | ≥ 5 apps con score ≥ 8 |
| `root-indicators` | ≥ 1 indicador | — |

Puntaje de riesgo por app (Android): +1 por permiso peligroso solicitado,
+3 por `SYSTEM_ALERT_WINDOW` u `REQUEST_INSTALL_PACKAGES`, +2 por
device-admin, +2 por sideload.

Veredicto global = máxima severidad; puntaje = Σ (warning=3, critical=10).
Umbrales centralizados en `RuleThresholds` (testeables y evolucionables).

## Persistencia e historial

`history_store.dart` guarda cada captura como una línea JSON (JSON Lines) en
el directorio de documentos de la app, con retención acotada (500 líneas).
Sin SQLite ni plugins nativos extra: menos superficie, misma evidencia.

## Export forense

`snapshot_json.dart` serializa snapshot + veredicto con `dart:convert`
(`schemaVersion` incluido). El botón de export copia el JSON al
portapapeles y lo guarda como archivo en el directorio de documentos del
sandbox; nada sale del dispositivo por sí solo.

## Decisiones y trade-offs

| Decisión | Razón |
|---|---|
| MethodChannel propio vs plugins pub.dev | Menos dependencias de terceros, contrato único auditable, control total de qué se lee |
| JSON Lines vs sqflite | Cero deps nativas extra; el volumen (500 capturas) no justifica SQL |
| Sin permiso INTERNET | Privacidad verificable por diseño, no por promesa |
| Ids de hallazgo estables | Evidencia comparable entre dispositivos y con RootCause Windows |
