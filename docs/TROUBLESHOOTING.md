# Troubleshooting

## Instalación del APK

### ¿Cuál APK descargo?

| APK | Para quién | Peso relativo |
|---|---|---|
| `…-arm64-v8a.apk` | **Recomendado**: cualquier teléfono moderno (64 bits, 2016+) | ≈ 1/3 del universal |
| `…-armeabi-v7a.apk` | Teléfonos antiguos de 32 bits | ≈ 1/3 del universal |
| `…-universal.apk` | Cualquier equipo, si no sabes cuál elegir | El más pesado (todas las ABIs) |

> ¿Por qué el universal pesa ~45 MB? Empaqueta el engine de Flutter y el
> código AOT para **tres arquitecturas de CPU a la vez**. Detalle completo
> del trade-off (y por qué la edición Windows en Rust pesa menos) →
> [`ARCHITECTURE.md`](ARCHITECTURE.md#trade-off-honesto-peso-del-apk-flutter-vs-rust).

### Problemas frecuentes

| Síntoma | Causa | Solución |
|---|---|---|
| "Aplicación no instalada" al usar un APK por ABI | ABI equivocada para tu CPU | Usa `arm64-v8a` (lo normal) o el `universal` |
| "Aplicación no instalada" | Ya existe una versión firmada con otra clave (releases con firma efímera) | Desinstala la versión anterior e instala de nuevo |
| Android bloquea la instalación | Orígenes desconocidos no autorizados | Ajustes → Apps → tu navegador → "Instalar apps desconocidas" |
| Play Protect advierte | App fuera de Play Store, sin historial de reputación | Verifica el SHA-256 contra `SHA256SUMS.txt` del release y continúa |
| "App no compatible" | Android < 8.0 (API 26) | Versión mínima soportada: Android 8.0 |

## Uso de la app

| Síntoma | Causa | Solución |
|---|---|---|
| La pestaña Apps tarda unos segundos | Enumerar paquetes + permisos es costoso en equipos con muchas apps | Es normal; la captura corre fuera del hilo de UI |
| Temperatura de batería "No disponible" | El fabricante no la reporta (o es iOS) | Limitación del SO, no un fallo |
| Historial vacío tras reinstalar | El historial vive en el sandbox y se borra al desinstalar | Exporta el JSON antes de desinstalar si quieres conservar evidencia |
| El veredicto parece "muy sensible" | Umbrales por defecto | Los umbrales viven en `RuleThresholds` (`lib/core/rule_engine.dart`); configurables en una versión futura |

## Desarrollo / build

| Síntoma | Causa | Solución |
|---|---|---|
| `flutter doctor` no ve el SDK de Android | `ANDROID_HOME` sin definir | Apunta a tu SDK (típicamente `%LOCALAPPDATA%\Android\Sdk`) |
| Licencias Android sin aceptar | Primera vez con el SDK | `flutter doctor --android-licenses` |
| `dart format` falla en CI | Formato distinto al canónico | Corre `dart format lib test` y commitea |
| El build iOS falla en Windows/Linux | Xcode solo existe en macOS | Usa el job `build-ios` de la CI |
| El APK release no respeta mi keystore | Variables de entorno de firma sin definir | Ver [`BUILD_MOVIL.md`](BUILD_MOVIL.md) sección "Firma release" |

¿Algo que no está aquí? Abre un issue con: versión de la app, versión de
Android, pasos y captura del error.
