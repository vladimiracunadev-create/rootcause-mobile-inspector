# Limitaciones por plataforma

Tabla de capacidades real, sin marketing. La app declara en runtime qué
soporta cada plataforma (`appsAuditSupported`) y la UI lo comunica.

| Capacidad | Android (8.0+) | iOS (13+) | Por qué |
|---|---|---|---|
| Memoria total/disponible + flag low-memory | ✅ | 🟡 aproximada | iOS no expone memoria del sistema con la misma precisión; se usa ProcessInfo + `os_proc_available_memory` |
| Almacenamiento libre/total | ✅ | ✅ | APIs públicas en ambos |
| Caché propia de la app | ✅ | ✅ | Sandbox propio siempre legible |
| Nivel y estado de batería | ✅ | ✅ | APIs públicas |
| Temperatura de batería | ✅ | ❌ | iOS no la expone a apps de usuario |
| Salud de batería | ✅ (etiqueta del SO) | ❌ | idem |
| Transporte de red / VPN / medida | ✅ | ✅ | `NetworkCapabilities` / `NWPathMonitor` |
| Ancho de banda estimado | ✅ | ❌ | iOS no lo expone |
| Tráfico acumulado (contadores globales) | ✅ | ❌ | `TrafficStats` no tiene equivalente público en iOS |
| Listar apps instaladas + permisos | ✅ (`QUERY_ALL_PACKAGES`) | ❌ | iOS lo prohíbe por diseño |
| Origen de instalación (sideload) | ✅ | ❌ | idem |
| Indicadores root/jailbreak | ✅ | ✅ | Heurísticas de archivos en ambos |
| Parche de seguridad del SO | ✅ | 🟡 versión de iOS | iOS no tiene campo separado de parche |
| Volúmenes adicionales (tarjeta SD / USB) | ✅ | ❌ | iOS no tiene almacenamiento extraíble |
| Escaneo Bluetooth LE (Cercanía) | ✅ opt-in | ❌ | Fuera del alcance iOS actual (distribución en pausa) |
| Captura en segundo plano | ✅ (WorkManager, mín. 15 min) | ❌ | BGTaskScheduler quedó fuera del alcance iOS actual |
| Abrir pantallas del sistema (liberar espacio, batería, ficha de app) | ✅ | 🟡 solo ajustes de la propia app | iOS no expone esas pantallas a terceros |
| Tiempo en pantalla por app (24 h) | ✅ solo con acceso de uso (opt-in en Ajustes) | ❌ | Permiso especial `PACKAGE_USAGE_STATS`; la app no puede autoconcedérselo |
| Widget de pantalla de inicio | ✅ | ❌ | Fuera del alcance iOS actual |
| CPU/RAM de OTRAS apps | ❌ | ❌ | Restringido por el SO desde Android 8 / siempre en iOS (el tiempo en pantalla vía acceso de uso es lo máximo que el SO permite) |
| Matar procesos ajenos | ❌ | ❌ | Restringido por el SO |
| Inspección de tráfico por app | ❌ | ❌ | Requeriría actuar como VPN local — renuncia deliberada (regla "cero red") |

## Limitaciones generales

- Los indicadores de root/jailbreak son heurísticos: un gestor de root
  moderno puede ocultarse, y un dispositivo rooteado a propósito genera el
  mismo indicio. **Indicio, no prueba.**
- El puntaje de riesgo por app mide **superficie de permisos solicitada**,
  no comportamiento observado.
- Las direcciones Bluetooth LE modernas **rotan** (MAC aleatorizada): en
  Cercanía un mismo aparato puede aparecer como varios, y la marca
  PERSISTENTE es un indicio de sesión, no una identificación. En Android
  8–11 el SO exige el permiso de ubicación para escanear BLE (limitación
  de esas versiones, no un uso de ubicación por parte de RootCause).
- La captura en segundo plano depende de WorkManager: Android puede
  aplazarla por ahorro de batería y el intervalo mínimo real es 15
  minutos. La opción "solo cargando" la restringe aún más, a propósito.
- La distribución iOS requiere cuenta Apple Developer; hasta entonces la
  plataforma se valida compilando en CI (`--no-codesign`).
- `QUERY_ALL_PACKAGES` es aceptable para distribución directa (GitHub
  Releases); si algún día se publica en Google Play, requerirá declaración
  de uso o cambiar a `<queries>` selectivo.
