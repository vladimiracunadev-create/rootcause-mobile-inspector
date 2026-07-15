# CI/CD en GitHub Actions

## Workflows

| Workflow | Disparo | Qué hace |
|---|---|---|
| [`ci.yml`](../.github/workflows/ci.yml) | push/PR a `main`, manual | `quality` (formato + analyze + tests) · `build-android` (APK release) · `build-ios` (build sin firma en macOS) |
| [`release-android.yml`](../.github/workflows/release-android.yml) | tag `v*`, manual | coherencia tag↔pubspec → tests → APK firmado → `SHA256SUMS.txt` → GitHub Release |

## Decisiones de robustez

1. **Actions pinneadas a commit SHA** — nunca a tags móviles (`@v4`), para
   inmunidad ante re-tagging malicioso:

   ```yaml
   uses: actions/checkout@08eba0b27e820071cde6df949e0beb9ba4906955 # v4.3.0
   ```

2. **Flutter instalado clonando el tag exacto del SDK** (`git clone --depth 1
   --branch 3.44.6 https://github.com/flutter/flutter`) — sin actions de
   terceros para el toolchain, versión idéntica a la de desarrollo local.

3. **`permissions` mínimos por workflow**: `contents: read` en CI;
   `contents: write` solo en release (necesario para publicar).

4. **`concurrency`** con cancelación en CI (un push nuevo cancela el run
   anterior de la misma rama) y sin cancelación en release.

5. **`timeout-minutes` explícito** en todos los jobs.

6. **Puerta de calidad en release**: los tests corren de nuevo antes de
   compilar el APK del release; un tag sobre código roto no publica.

7. **Coherencia tag ↔ versión**: si el tag `vX.Y.Z` no coincide con
   `version:` de `pubspec.yaml`, el release falla con error claro.

## Firma en release

El workflow lee 4 secretos del repositorio:

| Secreto | Contenido |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | keystore `.jks` codificado en base64 |
| `ANDROID_KEYSTORE_PASSWORD` | contraseña del keystore |
| `ANDROID_KEY_ALIAS` | alias de la clave |
| `ANDROID_KEY_PASSWORD` | contraseña de la clave |

Si **no** están configurados, el release no falla: genera una clave efímera
en el runner y lo declara en las notas del release (`ephemeral-ci-key`).
Detalles y comandos → [`RELEASE_MOVIL.md`](RELEASE_MOVIL.md).

## Réplica local de la CI

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --release
```

## Verificación de workflows antes de push

Los YAML de este repo se validan con `actionlint` (sintaxis de Actions +
shellcheck de los `run:`) además del parser YAML. La CI aumenta la
confianza, pero no reemplaza probar la app en un dispositivo real.
