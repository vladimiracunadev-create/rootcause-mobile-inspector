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
| CPU/RAM de OTRAS apps | ❌ | ❌ | Restringido por el SO desde Android 8 / siempre en iOS |
| Matar procesos ajenos | ❌ | ❌ | Restringido por el SO |
| Inspección de tráfico por app | ❌ | ❌ | Requeriría actuar como VPN local (fuera de alcance v0.1) |

## Limitaciones generales

- Los indicadores de root/jailbreak son heurísticos: un gestor de root
  moderno puede ocultarse, y un dispositivo rooteado a propósito genera el
  mismo indicio. **Indicio, no prueba.**
- El puntaje de riesgo por app mide **superficie de permisos solicitada**,
  no comportamiento observado.
- La distribución iOS requiere cuenta Apple Developer; hasta entonces la
  plataforma se valida compilando en CI (`--no-codesign`).
- `QUERY_ALL_PACKAGES` es aceptable para distribución directa (GitHub
  Releases); si algún día se publica en Google Play, requerirá declaración
  de uso o cambiar a `<queries>` selectivo.
