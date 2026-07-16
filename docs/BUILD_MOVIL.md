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

## Probar el APK en un emulador (sin teléfono)

El **Android Emulator** oficial (incluido con Android Studio) ejecuta un
Android completo en tu PC. En el emulador la CPU es `x86_64`, así que usa
el APK **universal** del release.

### Vía Android Studio (fácil)

1. Android Studio → **Device Manager** → *Create Virtual Device* →
   elige un teléfono (p. ej. "Medium Phone") y una imagen de sistema
   reciente → Finish.
2. Pulsa ▶ para arrancar el emulador.
3. **Arrastra y suelta** el APK universal sobre la ventana del emulador —
   se instala solo.

### Vía línea de comandos (reproducible)

```powershell
$sdk = "$env:LOCALAPPDATA\Android\Sdk"

# Listar AVDs existentes y arrancar uno
& "$sdk\emulator\emulator.exe" -list-avds
& "$sdk\emulator\emulator.exe" -avd <NOMBRE_AVD>

# Instalar y lanzar el APK (con el emulador ya arrancado)
& "$sdk\platform-tools\adb.exe" install RootCause-Mobile-Inspector-<v>-android-universal.apk
& "$sdk\platform-tools\adb.exe" shell monkey -p com.rootcause.mobileinspector 1
```

Alternativas de terceros (BlueStacks, Genymotion, Waydroid en Linux)
también funcionan, pero el AVD oficial es el único que replica Android
sin modificaciones — mejor para validar comportamiento real.

> Nota honesta: en el emulador algunas señales pierden sentido (batería
> simulada, sin sideload real); es ideal para probar la UI y el flujo,
> no para evaluar la detección completa.

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
