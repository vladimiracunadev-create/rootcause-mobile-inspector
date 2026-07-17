# Arquitectura

## Visión general

RootCause Mobile Inspector usa **Flutter** con una separación estricta en tres capas:

```mermaid
flowchart TB
    subgraph UI["🖼 UI — lib/ui/ + lib/main.dart"]
        TABS["9 pestañas Material 3"]
        SEM["Semáforo + hallazgos + acciones"]
        I18N["Bilingüe ES/EN (ES por defecto)"]
    end

    subgraph CORE["🧠 Núcleo compartido — lib/core/ (Dart puro, sin Flutter)"]
        MODELS["models.dart<br/>Snapshot · Finding · Verdict · VolumeInfo"]
        ENGINE["rule_engine.dart<br/>7 familias de reglas"]
        JSON["snapshot_json.dart<br/>export forense"]
        HIST["history_store.dart<br/>JSON Lines · retención 500"]
        CFG["config_store.dart<br/>intervalos · umbrales · idioma"]
        NEAR["nearby.dart<br/>sesión BLE en memoria"]
    end

    subgraph NATIVE["📟 Colectores nativos — MethodChannel 'rootcause/collectors'"]
        KT["android/ · Kotlin<br/>CollectorsChannel + AndroidCollectors<br/>+ BackgroundCaptureWorker"]
        SW["ios/ · Swift<br/>AppDelegate + IosCollectors"]
    end

    UI --> CORE
    CORE --> NATIVE
    KT --> API_A["APIs públicas Android<br/>ActivityManager · StatFs · PackageManager<br/>BatteryManager · ConnectivityManager"]
    SW --> API_I["APIs públicas iOS<br/>ProcessInfo · FileManager · UIDevice"]
```

### Por qué Flutter

- Un solo código para UI + motor de reglas + export en Android e iOS.
- Los colectores (lo único que de verdad difiere por SO) quedan aislados
  en un MethodChannel por plataforma.
- El motor de reglas es **Dart puro**: se testea en CI sin emulador.

## El contrato del MethodChannel

Canal: `rootcause/collectors`. Métodos:

- `collect` → mapa completo de estado (abajo)
- `documentsPath` → ruta del directorio de documentos del sandbox
  (historial y exports; evita depender del plugin `path_provider`)
- `openSystemScreen(screen, packageName?)` → abre la pantalla del sistema
  donde el usuario puede intervenir (`free-space`, `battery`,
  `app-details`, `settings`); devuelve `false` si no existe en la
  plataforma
- `clearOwnCache` → borra la caché propia y devuelve los bytes liberados
- `requestBlePermissions` / `bleScan(seconds)` → permiso y escaneo BLE
  manual (lista `address`/`name`/`rssi`; `null` = no soportado)
- `configureBackgroundCapture(enabled, chargingOnly)` → programa o cancela
  la captura periódica con WorkManager (Android)

En Android el canal se registra desde `CollectorsChannel` tanto en la
Activity como en el engine **headless** del `BackgroundCaptureWorker`: la
captura en segundo plano ejecuta el entrypoint Dart `backgroundCapture`
de `lib/main.dart` — el mismo colector, los mismos umbrales configurados
y el mismo historial que la app abierta, sin lógica duplicada.

El método `collect` devuelve:

```jsonc
{
  "memory":  { "totalBytes": 0, "availableBytes": 0, "lowMemory": false },
  "storage": { "totalBytes": 0, "freeBytes": 0, "appCacheBytes": 0,
               "volumes": [ { "label": "SDCARD", "totalBytes": 0,
                              "freeBytes": 0, "removable": true } ] },
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
               "appsAuditSupported": true,
               "vendorSkin": "One UI 8.5" }
}
```

Reglas del contrato:

- **Campos siempre presentes** con defaults seguros; el Dart valida tipos y
  degrada a valores neutros si falta algo (nunca crashea por el nativo).
- `appsAuditSupported=false` en iOS: la UI muestra "no disponible por diseño
  del SO" en vez de una lista vacía engañosa.
- Los ids de hallazgo (`mem-pressure`, `storage-low`, `battery-temp`,
  `battery-health`, `risky-apps`, `root-indicators`, `load-rising`) son
  estables y neutrales al idioma — mismos principios que la edición Windows.

## Ciclo de vida de una captura

```mermaid
sequenceDiagram
    autonumber
    actor U as Usuario
    participant UI as UI (main.dart)
    participant CH as MethodChannel
    participant N as Nativo (Kotlin/Swift)
    participant RE as RuleEngine (Dart)
    participant HS as HistoryStore

    U->>UI: pulsa ↻ (o al abrir la app)
    UI->>CH: invokeMethod("collect")
    CH->>N: collect()
    Note over N: Lectura de APIs públicas<br/>fuera del hilo de UI
    N-->>CH: mapa con memoria, storage,<br/>batería, red, apps, device
    CH-->>UI: Snapshot (validación defensiva:<br/>campo ausente → default seguro)
    UI->>RE: evaluate(snapshot)
    RE-->>UI: Verdict (semáforo + score + findings)
    UI->>HS: append(JSON line) + trim(500)
    UI-->>U: semáforo, hallazgos con evidencia<br/>y recomendación
```

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
| `load-rising` | caída sostenida (≥ 15 pts en ≤ 6 h) de memoria disponible o disco libre a lo largo del historial | — |

Puntaje de riesgo por app (Android): +1 por permiso peligroso solicitado,
+3 por `SYSTEM_ALERT_WINDOW` u `REQUEST_INSTALL_PACKAGES`, +2 por
device-admin, +2 por sideload.

Veredicto global = máxima severidad; puntaje = Σ (warning=3, critical=10).
Umbrales centralizados en `RuleThresholds` — desde v0.2.0 el usuario los
ajusta en la pestaña Configuración (`config_store.dart` los persiste como
`rootcause-config.json`) y la regla de tendencia consume el historial
reciente. Especificación exacta en [HEURISTICAS.md](HEURISTICAS.md).

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
| Flutter vs binario nativo (Rust) | Un solo código para Android **e** iOS; ver trade-off de peso abajo |
| MethodChannel propio vs plugins pub.dev | Menos dependencias de terceros, contrato único auditable, control total de qué se lee |
| JSON Lines vs sqflite | Cero deps nativas extra; el volumen (500 capturas) no justifica SQL |
| Sin permiso INTERNET | Privacidad verificable por diseño, no por promesa |
| Ids de hallazgo estables | Evidencia comparable entre dispositivos y con RootCause Windows |

## Trade-off honesto: peso del APK (Flutter vs Rust)

La edición Windows está escrita en Rust y compila a un binario nativo de
~4–18 MB sin runtime. La edición móvil eligió Flutter para tener **un solo
código base en Android e iOS** (requisito del producto), y eso tiene un
costo declarado:

| Componente dentro del APK | Peso aproximado |
|---|---|
| Engine de Flutter (renderizado Impeller/Skia, C++) | ~9–10 MB **por arquitectura** |
| Código Dart compilado AOT + runtime Dart | ~4–6 MB por arquitectura |
| Recursos, ICU, manifest, firma | ~2 MB |

El APK **universal** empaqueta TRES arquitecturas (arm64-v8a, armeabi-v7a,
x86_64) → todo lo anterior ×3 ≈ **45 MB**. Por eso el release publica
también APKs **divididos por ABI** (`--split-per-abi`): el APK que tu
teléfono realmente necesita pesa ≈ **1/3** del universal.

Mitigaciones ya aplicadas: R8 + shrink de recursos, tree-shaking de
iconos (la fuente Material pasa de 1.6 MB a ~2 KB) y cero dependencias
pub externas. Lo que NO se puede quitar es el engine de Flutter: es el
precio del multiplataforma. Un núcleo Rust compartido vía FFI (colectores
en Rust, UI en Flutter) queda evaluado en el
[ROADMAP](ROADMAP.md) como evolución posible si el peso o el consumo se
vuelven críticos.

En **consumo en ejecución** la app sigue la filosofía RootCause: sin red y
con el trabajo pesado (enumerar apps) una sola vez por captura, fuera del
hilo de UI. La captura es bajo demanda o con auto-captura configurable; la
variante en segundo plano usa WorkManager (mínimo 15 minutos, opción
solo-cargando) en vez de un daemon residente — el sensor no debe consumir
lo que dice vigilar.
