# Política de privacidad local

La misma política que la edición Windows, aplicada al móvil: **la
privacidad se demuestra por diseño, no por promesa.**

## Qué datos toca la app

| Dato | Se lee | Se guarda | Sale del dispositivo |
|---|---|---|---|
| Memoria total/disponible | ✅ | En historial local | ❌ (solo si TÚ exportas) |
| Almacenamiento libre/total | ✅ | En historial local | ❌ |
| Batería (nivel, temperatura, salud) | ✅ | En historial local | ❌ |
| Estado de red (transporte, VPN, medida) | ✅ | En historial local | ❌ |
| Lista de apps y permisos que SOLICITAN (Android) | ✅ | En historial local | ❌ |
| Volúmenes de almacenamiento (tarjeta SD: libre/total) | ✅ | En historial local | ❌ |
| Dispositivos Bluetooth LE cercanos (escaneo manual opt-in) | ✅ solo al pulsar Escanear | ❌ solo en memoria de la sesión | ❌ nunca (ni siquiera en el export) |
| Baseline de apps vistas (para detectar instalaciones nuevas) | ✅ | En el sandbox (`rootcause-apps-baseline.json`) | ❌ |
| Tiempo en pantalla por app (solo si TÚ concedes el acceso de uso en Ajustes) | ✅ opt-in | En historial local | ❌ (solo si exportas) |
| Cercanía histórica (días en que se vio cada BLE, opt-in) | ✅ opt-in | `rootcause-nearby.json` (sandbox) | ❌ |
| Registro local de errores (para diagnóstico) | ✅ | `rootcause-crashlog.txt` (sandbox) | ❌ (solo si lo compartes) |
| Contenido de tu tráfico de red | ❌ nunca | — | — |
| SMS, contactos, fotos, archivos personales | ❌ nunca | — | — |
| Identificadores de publicidad / cuentas | ❌ nunca | — | — |

## Garantías verificables en el código

1. **Sin permiso INTERNET**: el manifest principal de Android no lo declara;
   el APK de release no puede abrir conexiones salientes. Verificable en
   [`android/app/src/main/AndroidManifest.xml`](../android/app/src/main/AndroidManifest.xml).
2. **Historial en el sandbox**: `rootcause-history.jsonl` vive en el
   directorio privado de la app; desinstalar la app lo elimina.
3. **Export solo manual**: el JSON forense se copia al portapapeles y se
   guarda en la carpeta de documentos de la app únicamente cuando pulsas
   exportar. No hay sincronización, ni cuentas, ni "nube".
4. **Sin analytics ni crash reporting**: cero SDKs de terceros
   (`pubspec.yaml` no tiene dependencias externas).
5. **Bluetooth sin ubicación**: el permiso `BLUETOOTH_SCAN` se declara con
   `neverForLocation` — Android garantiza que el escaneo no puede usarse
   para inferir dónde estás. El resultado vive solo en memoria mientras la
   app está abierta: no se guarda en el historial ni entra al export JSON.
6. **La captura en segundo plano es local**: el Worker ejecuta el mismo
   núcleo que la app abierta y escribe únicamente en el historial del
   sandbox. Sin permiso INTERNET, tampoco en segundo plano sale nada.
7. **La alerta de crítico es una notificación LOCAL** (permiso
   `POST_NOTIFICATIONS`, opt-out en Configuración): el dispositivo se
   avisa a sí mismo. No existe infraestructura de push — no puede
   existir sin INTERNET.
8. **El informe, el backup y el registro de errores se comparten por el
   share sheet del SISTEMA** (FileProvider): es la app que tú elijas la
   que envía, no RootCause. La app nunca toca la red.
9. **La cadena de hashes SHA-256 del historial** deja la evidencia
   verificable ante terceros sin exponer nada: el sello se calcula
   localmente sobre datos que ya son tuyos.

## Lo que esto significa

- Nadie —incluido el autor— recibe datos de tu dispositivo.
- La evidencia es tuya: se queda contigo hasta que decidas compartirla.
- Si un tercero te pide el export JSON, revisa antes su contenido: incluye
  nombres de apps instaladas y métricas del equipo.
