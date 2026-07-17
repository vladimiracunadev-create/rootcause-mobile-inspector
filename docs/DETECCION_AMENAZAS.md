# Detección de amenazas — mapa honesto (edición móvil)

Igual que la edición Windows, este documento dice **qué detecta hoy** la app,
amenaza por amenaza, y qué queda fuera — y por qué. En móvil la honestidad es
doblemente necesaria: Android e iOS aíslan a las apps de usuario mucho más que
Windows, así que un "antivirus móvil" que promete inspección profunda de otros
procesos está prometiendo algo que el SO no le permite hacer.

## Qué SÍ observa RootCause Mobile hoy

| Señal | Cómo | Hallazgo |
|---|---|---|
| Presión anómala de memoria | `ActivityManager.MemoryInfo` (Android) / `os_proc_available_memory` + ProcessInfo (iOS) | `mem-pressure` |
| Almacenamiento crítico | `StatFs` / `NSFileManager` | `storage-low` |
| Batería con temperatura o salud anómala | broadcast `ACTION_BATTERY_CHANGED` / `UIDevice` (iOS no expone temperatura) | `battery-temp`, `battery-health` |
| Superficie de permisos peligrosa por app | `PackageManager` con `GET_PERMISSIONS` (solo Android) | `risky-apps` |
| Sideload (app fuera de tienda conocida) | `InstallSourceInfo` (solo Android) | contribuye al puntaje |
| Overlay / instalador de paquetes / device-admin | permisos solicitados (solo Android) | contribuye al puntaje |
| Indicadores de root/jailbreak | rutas `su`, build test-keys / rutas Cydia y escritura fuera de sandbox | `root-indicators` |
| VPN activa / red medida | `NetworkCapabilities` / `NWPathMonitor` | visible en pestaña Red |
| Carga en ascenso sostenido (v0.2.0) | serie de capturas del historial local | `load-rising` |
| Apps instaladas entre capturas (v0.3.0) | baseline local de paquetes vistos | `new-apps` |
| Transición del veredicto a crítico (v0.3.0) | captura en segundo plano + notificación LOCAL | alerta en el dispositivo |
| Dispositivos BLE persistentes cerca (v0.2.0) | escaneo manual opt-in `BluetoothLeScanner` (Android) | marca PERSISTENTE en pestaña Cercanía (no entra al export) |

## Amenaza por amenaza

| Familia | ¿RootCause Mobile la ve? | Detalle honesto |
|---|---|---|
| **Apps espía (stalkerware)** | 🟡 Parcial | Si solicita la tríada típica (micrófono+ubicación+SMS) y llegó por sideload, su puntaje de riesgo sube y aparece en `risky-apps`. Desde v0.3.0, si se instala mientras RootCause vigila, además aparece como `new-apps` en la siguiente captura. No podemos ver si los permisos se USAN, solo si se solicitan. |
| **Malware con overlay (bankers)** | 🟡 Parcial | `SYSTEM_ALERT_WINDOW` solicitado suma +3 al puntaje. No detectamos el overlay en acto. |
| **Droppers (instalan otros APK)** | 🟡 Parcial | `REQUEST_INSTALL_PACKAGES` suma +3; sideload suma +2. |
| **Root/jailbreak malicioso o heredado** | 🟡 Indicio | Binarios `su`, test-keys, rutas de jailbreak. Un dispositivo rooteado a propósito da el mismo indicio: contexto humano necesario. |
| **Cryptojacking** | 🟡 Indirecto | Sin acceso al CPU de otros procesos, los indicios visibles son temperatura de batería sostenida (`battery-temp`) y, desde v0.2.0, la caída sostenida de recursos entre capturas (`load-rising`) con la auto-captura activada. Correlación indirecta y así se declara. |
| **Rastreadores BLE ajenos (tipo AirTag)** | 🟡 Indicio (v0.2.0) | Un dispositivo BLE que reaparece en varios escaneos a lo largo de la sesión se marca PERSISTENTE. Las MAC aleatorizadas pueden fragmentar la detección y tus propios accesorios también persisten: indicio para revisar, no identificación. |
| **Exfiltración de datos** | 🔴 No | Una app de usuario no puede inspeccionar tráfico ajeno sin ser VPN local. Fuera de alcance v0.1; el contador global de tráfico es contexto, no detección. |
| **Ransomware móvil** | 🔴 No | Sin acceso al filesystem de otras apps no hay señal de cifrado masivo observable. |
| **Phishing / smishing** | 🔴 No | Fuera de alcance: requiere leer SMS/notificaciones, contrario a la política de privacidad del producto. |
| **Vulnerabilidades sin parchear** | 🟡 Regla automática (v0.4.0) | `patch-old`: parche ≥ 180 días → warning, ≥ 365 → critical, con botón a la actualización del sistema. No sabemos QUÉ CVEs aplican (eso requiere bases externas y red); sabemos que la ventana de exposición crece. |

## Por qué no prometemos más

- **Android ≥ 8** no permite a una app de usuario leer CPU/RAM/tráfico de
  otras apps (`/proc` restringido, `UsageStats` requiere permiso especial).
- **iOS** no permite ni siquiera listar las apps instaladas.
- Todo lo que este producto afirma detectar está limitado a APIs públicas
  y documentadas, sin trucos frágiles ni permisos invasivos.

El valor del sensor está en lo mismo que la edición Windows: **distorsiones
de recursos + superficie de permisos + indicadores de integridad**, con
evidencia persistida y exportable — el indicio temprano que dice dónde mirar.
