# Checklist de release Android

Complemento verificable de [`RELEASE_MOVIL.md`](RELEASE_MOVIL.md): aquel documento explica el proceso; este es la lista para ejecutarlo sin saltarse pasos.

**Regla de oro de la casa: NUNCA marcar un paso como hecho sin haberlo verificado con un comando real.** Por eso cada casilla trae debajo su comando de verificación.

## 1) Pre-release

- [ ] Código verde en local (réplica del CI: pub get, format, analyze, test, build release):

```powershell
.\scripts\ci-local.ps1
# Debe terminar en "CI local: TODO VERDE"
```

- [ ] Versión subida en `pubspec.yaml` — fuente de verdad, formato `<semver>+<build number>`:

```powershell
Select-String '^version:' pubspec.yaml
# Ej.: version: 0.4.0+6 — semver Y build number incrementados respecto al release anterior
```

- [ ] Docs y landing coherentes con la nueva versión (las menciones históricas de changelog se conservan; las de "versión actual" no pueden quedar viejas):

```bash
git grep -n "0\.1\.0" -- README.md docs landing
# Revisar cada resultado: solo deben sobrevivir referencias históricas
```

- [ ] `main` limpia y sincronizada con el remoto:

```bash
git status --short
git pull --ff-only
```

## 2) Release

- [ ] Tag `vX.Y.Z` creado sobre el commit correcto. La parte semver DEBE coincidir con `pubspec.yaml`: el workflow lo verifica como primer paso y falla si no coincide:

```bash
git log --oneline -1
git tag v0.4.0
git push origin v0.4.0
```

- [ ] Si se espera firma con la clave permanente (`release-key`), los 4 secretos deben existir ANTES de pushear el tag; si faltan, el workflow usa una clave efímera de CI (`ephemeral-ci-key`) y actualizar la app requerirá desinstalar:

```bash
gh secret list -R vladimiracunadev-create/rootcause-mobile-inspector
# Deben aparecer: ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD
```

- [ ] Workflow [`release-android.yml`](../.github/workflows/release-android.yml) en verde. Él mismo verifica tag ↔ `pubspec.yaml`, corre `flutter test` como puerta, compila los APKs por ABI (`arm64-v8a`, `armeabi-v7a`) más el `universal`, genera `SHA256SUMS.txt` y declara el modo de firma en las notas:

```bash
gh run watch
gh run list --workflow=release-android.yml --limit 1
# Conclusión esperada: success
```

## 3) Post-release

- [ ] El release publica los 4 assets — 2 APKs por ABI, el universal y `SHA256SUMS.txt`:

```bash
gh release view v0.4.0
# …-arm64-v8a.apk, …-armeabi-v7a.apk, …-universal.apk, SHA256SUMS.txt
```

- [ ] Las notas del release declaran el modo de firma real (`release-key` o `ephemeral-ci-key`):

```bash
gh release view v0.4.0 --json body --jq .body | grep -i "modo de firma"
```

- [ ] Hash SHA-256 verificado en local — debe coincidir carácter a carácter con `SHA256SUMS.txt`:

```powershell
gh release download v0.4.0 -p '*universal.apk' -p 'SHA256SUMS.txt' -D "$env:TEMP\rc-verify" --clobber
Get-FileHash "$env:TEMP\rc-verify\*universal.apk" -Algorithm SHA256
Get-Content "$env:TEMP\rc-verify\SHA256SUMS.txt"
```

- [ ] APK instalado y abierto en el emulador (descarga el universal del último release, lo instala y lanza la app — ver [`EMULADOR.md`](EMULADOR.md)):

```powershell
.\scripts\emulador.ps1
# Debe terminar en "RootCause abierto en el emulador" y la app debe arrancar sin crashes
```

- [ ] Landing actualizada si aplica — el badge de versión vive en `landing/index.html` y cualquier push a `landing/**` dispara el deploy a GitHub Pages:

```powershell
Select-String 'versión-' landing\index.html
gh run list --workflow=deploy-landing.yml --limit 1
```

Referencias: [`RELEASE_MOVIL.md`](RELEASE_MOVIL.md) (proceso y firma), [`CI_GITHUB.md`](CI_GITHUB.md) (workflows), [`TESTING.md`](TESTING.md) (puertas de calidad).
