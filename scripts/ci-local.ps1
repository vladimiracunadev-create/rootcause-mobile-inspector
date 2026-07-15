# Réplica local del job `quality` + `build-android` de ci.yml.
# Uso: .\scripts\ci-local.ps1  (desde la raíz del repo)
$ErrorActionPreference = 'Stop'

Write-Host '── flutter pub get ──────────────────────────────────' -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host '── dart format (lib/ y test/) ───────────────────────' -ForegroundColor Cyan
dart format --output=none --set-exit-if-changed lib test
if ($LASTEXITCODE -ne 0) { Write-Host 'Formato incorrecto: corre "dart format lib test"' -ForegroundColor Red; exit 1 }

Write-Host '── flutter analyze ──────────────────────────────────' -ForegroundColor Cyan
flutter analyze
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host '── flutter test ─────────────────────────────────────' -ForegroundColor Cyan
flutter test
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host '── flutter build apk --release ──────────────────────' -ForegroundColor Cyan
flutter build apk --release
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host 'CI local: TODO VERDE ✔' -ForegroundColor Green
