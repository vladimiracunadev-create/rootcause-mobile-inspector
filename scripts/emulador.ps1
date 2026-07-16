# Arranca el emulador Android CON VENTANA, instala el último APK del
# release y abre RootCause — todo en un comando.
#
# Uso: .\scripts\emulador.ps1
# Requisitos: Android SDK con un AVD creado (Android Studio → Device Manager)
#             y gh CLI autenticado (solo para descargar el release).
$ErrorActionPreference = 'Stop'

$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$emu = "$sdk\emulator\emulator.exe"
$adb = "$sdk\platform-tools\adb.exe"
$repo = 'vladimiracunadev-create/rootcause-mobile-inspector'

if (-not (Test-Path $emu)) { Write-Host "No hay Android SDK en $sdk" -ForegroundColor Red; exit 1 }

# 1. Elegir el primer AVD disponible
$avd = (& $emu -list-avds | Select-Object -First 1)
if (-not $avd) {
    Write-Host 'No hay AVDs. Crea uno: Android Studio → Device Manager → Create Virtual Device' -ForegroundColor Red
    exit 1
}
Write-Host "AVD: $avd" -ForegroundColor Cyan

# 2. Arrancar el emulador con ventana (si no está ya corriendo)
$running = (& $adb devices) -match 'emulator-\d+\s+device'
if (-not $running) {
    # Si la última posición de ventana quedó fuera de pantalla, se borra
    # para que el emulador arranque centrado (evita la ventana "cortada").
    $userIni = "$env:USERPROFILE\.android\avd\$avd.avd\emulator-user.ini"
    if (Test-Path $userIni) {
        $pos = Get-Content $userIni | Where-Object { $_ -match '^window\.(x|y)\s*=\s*(-?\d+)' }
        $offscreen = $pos | Where-Object { [int]($_ -replace '.*=\s*', '') -lt 0 }
        if ($offscreen) {
            Write-Host 'Posición de ventana fuera de pantalla — restaurando…' -ForegroundColor Yellow
            Remove-Item $userIni -Force
        }
    }
    Write-Host 'Arrancando emulador (ventana visible)…' -ForegroundColor Cyan
    Start-Process $emu -ArgumentList '-avd', $avd, '-no-snapshot-save', '-gpu', 'auto'
}

# 3. Esperar el boot completo
Write-Host 'Esperando boot…' -ForegroundColor Cyan
& $adb wait-for-device
do { Start-Sleep 3; $boot = (& $adb shell getprop sys.boot_completed 2>$null) } until ("$boot".Trim() -eq '1')
Write-Host 'Emulador listo.' -ForegroundColor Green

# 4. Descargar el APK universal del último release (el emulador es x86_64)
$dl = Join-Path $env:TEMP 'rootcause-apk'
New-Item -ItemType Directory -Force $dl | Out-Null
Write-Host 'Descargando APK universal del último release…' -ForegroundColor Cyan
gh release download -R $repo -p '*universal.apk' -D $dl --clobber

# 5. Instalar y abrir
$apk = Get-ChildItem $dl -Filter '*universal.apk' | Select-Object -First 1
Write-Host "Instalando $($apk.Name)…" -ForegroundColor Cyan
& $adb install -r $apk.FullName
& $adb shell monkey -p com.rootcause.mobileinspector -c android.intent.category.LAUNCHER 1 | Out-Null
Write-Host 'RootCause abierto en el emulador ✔' -ForegroundColor Green
