#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Guardián del claim central: "cero telemetría, cero red saliente".
#
# Ese claim se sostiene en un hecho verificable: la app NO declara el permiso
# android.permission.INTERNET. Sin él, el sistema operativo impide cualquier
# socket saliente — no es una promesa, es el SO haciéndola cumplir.
#
# Pero el manifiesto que se instala no es el que escribimos: es el FUSIONADO
# con el de cada dependencia. Una librería añadida mañana puede introducir
# INTERNET sin que nadie toque nuestro manifiesto, y el claim se rompería en
# silencio. Este script mira el manifiesto fusionado, que es el que manda.
#
# Solo se revisan los manifiestos de RELEASE, y esa distinción no es un
# atajo: `android/app/src/debug/AndroidManifest.xml` SÍ declara INTERNET
# porque el tooling de Flutter lo necesita para hot reload y breakpoints.
# Ese permiso no viaja en ningún APK publicado — el claim es sobre lo que se
# distribuye, y esto lo verifica exactamente ahí.
#
# Uso (tras `flutter build apk --release`):
#   bash scripts/check-no-internet.sh
#
# Sale con código != 0 si aparece INTERNET, o si no encuentra ningún
# manifiesto de release que revisar: un chequeo que no revisó nada NO puede
# reportarse como aprobado.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "── Verificando que el manifiesto de RELEASE no declare INTERNET ──"

mapfile -t MANIFESTS < <(
  find build android/app/build -type f -name AndroidManifest.xml \
    -path '*merged_manifest*' -path '*release*' 2>/dev/null | sort -u
)

if [ "${#MANIFESTS[@]}" -eq 0 ]; then
  echo "::error::No se encontró ningún AndroidManifest.xml fusionado de release."
  echo "Compila primero (flutter build apk --release) y vuelve a ejecutar."
  exit 2
fi

FOUND=0
for manifest in "${MANIFESTS[@]}"; do
  echo "  revisando: $manifest"
  if grep -q 'android.permission.INTERNET' "$manifest"; then
    echo "::error::$manifest declara android.permission.INTERNET."
    grep -n 'android.permission.INTERNET' "$manifest" || true
    FOUND=1
  fi
done

if [ "$FOUND" -ne 0 ]; then
  echo ""
  echo "El permiso INTERNET rompe la premisa del producto (cero red saliente)."
  echo "Si una dependencia nueva lo introdujo, quítala o exclúyelo con"
  echo "tools:node=\"remove\" en android/app/src/main/AndroidManifest.xml."
  exit 1
fi

echo "OK: ${#MANIFESTS[@]} manifiesto(s) fusionado(s) revisados, sin INTERNET."
