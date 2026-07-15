# Compilar desde el código fuente

## Requisitos

| Herramienta | Versión | Notas |
|---|---|---|
| Flutter SDK | 3.44.x (canal stable) | la CI usa exactamente `3.44.6` |
| Android SDK | platform 34 + build-tools 34+ | vía Android Studio o cmdline-tools |
| JDK | 17+ | para el toolchain de Android |
| Xcode | 15+ (solo builds iOS) | requiere macOS |

Verifica el entorno:

```bash
flutter doctor
```

## Android

```bash
flutter pub get

# Validación (lo mismo que corre la CI)
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test

# Debug en dispositivo/emulador conectado
flutter run

# APK release
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

### Firma release

Sin configuración extra, el build release usa la firma **debug** local
(suficiente para probar en tu propio equipo). Para firmar con un keystore
propio, exporta estas variables antes del build — es el mismo contrato que
usa el workflow de release:

```bash
export ANDROID_KEYSTORE_PATH=/ruta/mi-keystore.jks
export ANDROID_KEYSTORE_PASSWORD=...
export ANDROID_KEY_ALIAS=...
export ANDROID_KEY_PASSWORD=...
flutter build apk --release
```

En PowerShell:

```powershell
$env:ANDROID_KEYSTORE_PATH="C:\ruta\mi-keystore.jks"
$env:ANDROID_KEYSTORE_PASSWORD="..."
$env:ANDROID_KEY_ALIAS="..."
$env:ANDROID_KEY_PASSWORD="..."
flutter build apk --release
```

## iOS

Requiere macOS con Xcode.

```bash
flutter pub get

# Compilar sin firma (validación, lo que corre la CI)
flutter build ios --release --no-codesign

# Ejecutar en simulador
open -a Simulator
flutter run
```

Para instalar en un iPhone físico o distribuir se necesita una cuenta
Apple Developer y perfiles de firma → [`RELEASE_MOVIL.md`](RELEASE_MOVIL.md).

## Problemas comunes

| Síntoma | Causa probable | Solución |
|---|---|---|
| `Android sdkmanager not found` | SDK incompleto | instala cmdline-tools desde Android Studio |
| licencias Android no aceptadas | primera vez con el SDK | `flutter doctor --android-licenses` |
| `CocoaPods not installed` (iOS) | falta CocoaPods | `sudo gem install cocoapods` |
| build iOS falla en Windows/Linux | Xcode solo existe en macOS | usa la CI (job `build-ios`) |
