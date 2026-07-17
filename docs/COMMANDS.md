# Comandos y scripts

Referencia centralizada de comandos útiles del proyecto. El detalle de build
está en [BUILD_MOVIL.md](BUILD_MOVIL.md) y el flujo de CI en
[CI_GITHUB.md](CI_GITHUB.md).

---

## 1) Flutter / Dart

```bash
flutter pub get                                        # dependencias
dart format --output=none --set-exit-if-changed lib test   # formato (falla si difiere)
flutter analyze                                        # análisis estático
flutter test                                           # tests unitarios
flutter run                                            # ejecutar en dispositivo/emulador conectado
flutter build apk --release                            # APK universal
flutter build apk --release --split-per-abi            # APKs por ABI (arm64-v8a, armeabi-v7a…)
```

Notas:

- El flag exacto de formato es el mismo que exige la CI: si `dart format`
  cambiaría algo, el job falla. Corrige con `dart format lib test`.
- Los APK quedan en `build/app/outputs/flutter-apk/`.
- Sin secretos de firma configurados, el build release cae a la firma debug
  (instalable en local; ver [RELEASE_MOVIL.md](RELEASE_MOVIL.md)).

---

## 2) Scripts del repo

### `scripts/ci-local.ps1` (PowerShell) y `scripts/ci-local.sh` (bash)

Réplica local de los jobs `quality` + `build-android` de `ci.yml`, en orden:
`flutter pub get` → `dart format --set-exit-if-changed` → `flutter analyze` →
`flutter test` → `flutter build apk --release`. Se corta en el primer fallo.

```powershell
.\scripts\ci-local.ps1    # desde la raíz del repo
```

```bash
./scripts/ci-local.sh     # desde la raíz del repo
```

### `scripts/emulador.ps1` (PowerShell, Windows)

Arranca el primer AVD disponible con ventana visible, espera el boot completo,
descarga el APK **universal** del último GitHub Release (vía `gh`), lo instala
con `adb install -r` y abre la app. Requiere Android SDK con un AVD creado y
`gh` autenticado. Guía completa en [EMULADOR.md](EMULADOR.md).

```powershell
.\scripts\emulador.ps1
```

---

## 3) adb (dispositivo o emulador)

```bash
adb devices                                            # dispositivos conectados
adb install -r build/app/outputs/flutter-apk/app-release.apk   # instalar/actualizar
adb uninstall com.rootcause.mobileinspector            # desinstalar (borra historial y exports)
adb shell getprop ro.product.cpu.abi                   # confirmar arquitectura (¿qué APK?)
```

### Logcat filtrado por la app

```bash
adb logcat --pid="$(adb shell pidof -s com.rootcause.mobileinspector)"
adb logcat -s flutter                                  # alternativa: solo el motor Flutter
```

### Captura de pantalla del dispositivo

```bash
adb shell screencap -p /sdcard/rootcause.png
adb pull /sdcard/rootcause.png
adb shell rm /sdcard/rootcause.png
```

---

## 4) gh (GitHub CLI)

```bash
# Descargar el APK del último release (por ABI o universal)
gh release download -R vladimiracunadev-create/rootcause-mobile-inspector -p '*arm64-v8a.apk'
gh release download -R vladimiracunadev-create/rootcause-mobile-inspector -p '*universal.apk'
gh release download -R vladimiracunadev-create/rootcause-mobile-inspector -p 'SHA256SUMS.txt'

# Seguir en vivo el workflow en curso (CI o release)
gh run watch
```

---

## 5) GitHub Actions del repo

| Workflow | Disparo | Qué hace |
|---|---|---|
| `.github/workflows/ci.yml` | push/PR a `main` | formato + analyze + tests, APK release, build iOS sin firma |
| `.github/workflows/release-android.yml` | tag `v*` | APKs firmados (por ABI + universal), `SHA256SUMS.txt`, GitHub Release |
| `.github/workflows/deploy-landing.yml` | push a `main` que toque `landing/` | publica la landing en GitHub Pages |
