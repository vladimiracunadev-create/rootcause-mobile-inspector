#!/usr/bin/env bash
# Réplica local del job `quality` + `build-android` de ci.yml.
# Uso: ./scripts/ci-local.sh  (desde la raíz del repo)
set -euo pipefail

echo '── flutter pub get ──────────────────────────────────'
flutter pub get

echo '── dart format (lib/ y test/) ───────────────────────'
dart format --output=none --set-exit-if-changed lib test

echo '── flutter analyze ──────────────────────────────────'
flutter analyze

echo '── flutter test ─────────────────────────────────────'
flutter test

echo '── flutter build apk --release ──────────────────────'
flutter build apk --release

echo 'CI local: TODO VERDE ✔'
