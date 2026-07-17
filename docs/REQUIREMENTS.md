# Requisitos

Requisitos para usar la app y para desarrollarla. Versión actual del
producto: **v0.4.0** (fuente de verdad: `pubspec.yaml`). Licencia Apache 2.0.

---

## 1) Para USAR la app

### Android (producción)

| Componente | Requisito |
|---|---|
| Sistema operativo | Android 8.0 o superior (API 26) |
| Espacio libre | ~30 MB para la app instalada (APK: ~16 MB arm64-v8a, ~45 MB universal) |
| Conectividad | Ninguna — la app no declara el permiso INTERNET en release |
| Cuenta / registro | Ninguno |
| Permisos especiales | Todos opt-in: **Cercanía** pide Bluetooth en runtime; la **alerta de crítico** pide notificaciones (Android 13+); el **tiempo en pantalla** requiere el acceso de uso que solo tú concedes en Ajustes. Sin activarlos, la app no pide nada |

La instalación es por APK directo desde GitHub Releases (hay que autorizar
"orígenes desconocidos" para el navegador o gestor de archivos). Qué APK
descargar según la arquitectura del teléfono:
[TROUBLESHOOTING.md](TROUBLESHOOTING.md).

### iOS (en pausa)

El código compila para iOS 13.0+ (deployment target del proyecto Xcode) y la
CI lo valida en cada push con `flutter build ios --release --no-codesign`.
Pero **distribuir** un `.ipa` real requiere cuenta Apple Developer, que el
proyecto hoy no tiene — por eso la distribución iOS está en pausa. Detalle en
[RELEASE_MOVIL.md](RELEASE_MOVIL.md) y límites de plataforma en
[LIMITACIONES.md](LIMITACIONES.md).

---

## 2) Para DESARROLLAR

### Toolchain común

| Herramienta | Versión | Verificado en |
|---|---|---|
| Flutter SDK | 3.44.6 (canal stable — versión exacta de la CI) | `.github/workflows/ci.yml` |
| Dart SDK | ^3.12.0 (incluido en Flutter) | `pubspec.yaml` |
| Git | reciente | para clonar el repo y el SDK |

### Android

| Herramienta | Versión | Verificado en |
|---|---|---|
| JDK | 17 (Temurin en CI; el build usa compatibilidad Java 17) | `ci.yml`, `android/app/build.gradle.kts` |
| Android Gradle Plugin | 9.0.1 | `android/settings.gradle.kts` |
| Kotlin | 2.3.20 | `android/settings.gradle.kts` |
| Gradle wrapper | 9.1.0 | `android/gradle/wrapper/gradle-wrapper.properties` |
| Android SDK | con platform-tools (`adb`) | requerido por Flutter |
| AVD (emulador) | opcional, para probar sin teléfono | [EMULADOR.md](EMULADOR.md) |

### iOS (solo si compilas para iOS)

- macOS con Xcode instalado (la CI usa `macos-latest`).
- Sin cuenta Apple Developer se puede compilar con `--no-codesign`, pero no
  firmar ni distribuir.

---

## 3) Verificación del entorno

```bash
flutter --version    # debe reportar 3.44.6 / Dart 3.12.x
flutter doctor       # toolchain Android/iOS completo
```

La réplica local de la CI (formato + analyze + tests + APK release) está en
`scripts/ci-local.ps1` y `scripts/ci-local.sh` — ver
[COMMANDS.md](COMMANDS.md).

---

## 4) Requisitos de red y datos

- **Operación:** cero red. La app no habla con internet por diseño; toda la
  evidencia es local ([POLITICA_DE_PRIVACIDAD_LOCAL.md](POLITICA_DE_PRIVACIDAD_LOCAL.md)).
- **Desarrollo:** red solo para `flutter pub get`, clonar el SDK y descargar
  dependencias de Gradle.
- **Almacenamiento de la app:** historial local de hasta 500 capturas en
  JSON Lines más los exports JSON, todo dentro del sandbox de la app.
  Desinstalar la app borra todo ([OPERACION.md](OPERACION.md)).

---

## 5) CI/CD

| Workflow | Runner | Requisitos |
|---|---|---|
| `ci.yml` (quality + build-android + build-ios) | `ubuntu-latest` / `macos-latest` | Flutter 3.44.6 clonado por tag exacto; JDK 17 Temurin |
| `release-android.yml` | `ubuntu-latest` | tag `v*` coherente con `pubspec.yaml`; secretos de firma opcionales (sin ellos, clave efímera) |
| `deploy-landing.yml` | `ubuntu-latest` | GitHub Pages habilitado |

Las actions están pinneadas a commit SHA; el detalle vive en
[CI_GITHUB.md](CI_GITHUB.md).
