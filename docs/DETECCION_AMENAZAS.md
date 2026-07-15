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

## Amenaza por amenaza

| Familia | ¿RootCause Mobile la ve? | Detalle honesto |
|---|---|---|
| **Apps espía (stalkerware)** | 🟡 Parcial | Si solicita la tríada típica (micrófono+ubicación+SMS) y llegó por sideload, su puntaje de riesgo sube y aparece en `risky-apps`. No podemos ver si los permisos se USAN, solo si se solicitan. |
| **Malware con overlay (bankers)** | 🟡 Parcial | `SYSTEM_ALERT_WINDOW` solicitado suma +3 al puntaje. No detectamos el overlay en acto. |
| **Droppers (instalan otros APK)** | 🟡 Parcial | `REQUEST_INSTALL_PACKAGES` suma +3; sideload suma +2. |
| **Root/jailbreak malicioso o heredado** | 🟡 Indicio | Binarios `su`, test-keys, rutas de jailbreak. Un dispositivo rooteado a propósito da el mismo indicio: contexto humano necesario. |
| **Cryptojacking** | 🔴 No directo | Sin acceso al CPU de otros procesos, el indicio visible es temperatura de batería sostenida (`battery-temp`) + degradación. Es correlación débil y así se declara. |
| **Exfiltración de datos** | 🔴 No | Una app de usuario no puede inspeccionar tráfico ajeno sin ser VPN local. Fuera de alcance v0.1; el contador global de tráfico es contexto, no detección. |
| **Ransomware móvil** | 🔴 No | Sin acceso al filesystem de otras apps no hay señal de cifrado masivo observable. |
| **Phishing / smishing** | 🔴 No | Fuera de alcance: requiere leer SMS/notificaciones, contrario a la política de privacidad del producto. |
| **Vulnerabilidades sin parchear** | 🟡 Contexto | La pestaña Dispositivo muestra el parche de seguridad; un parche muy antiguo es un hallazgo razonable para humanos (regla automática en roadmap). |

## Por qué no prometemos más

- **Android ≥ 8** no permite a una app de usuario leer CPU/RAM/tráfico de
  otras apps (`/proc` restringido, `UsageStats` requiere permiso especial).
- **iOS** no permite ni siquiera listar las apps instaladas.
- Todo lo que este producto afirma detectar está limitado a APIs públicas
  y documentadas, sin trucos frágiles ni permisos invasivos.

El valor del sensor está en lo mismo que la edición Windows: **distorsiones
de recursos + superficie de permisos + indicadores de integridad**, con
evidencia persistida y exportable — el indicio temprano que dice dónde mirar.
