# Proceso de release

## Android (automatizado)

### 1. Preparar versión

`pubspec.yaml` es la fuente de verdad de la versión:

```yaml
version: 0.1.0+1   # <semver>+<build number>
```

El tag DEBE coincidir con la parte semver (el workflow lo verifica).

### 2. Publicar

```bash
git tag v0.1.0
git push origin v0.1.0
```

El workflow [`release-android.yml`](../.github/workflows/release-android.yml):

1. Verifica coherencia tag ↔ `pubspec.yaml`.
2. Corre los tests (puerta de calidad).
3. Compila el APK release **firmado**.
4. Publica el GitHub Release con el APK + `SHA256SUMS.txt` y notas con el
   modo de firma usado.

### 3. Verificar (obligatorio, no opcional)

```bash
gh release view v0.1.0
gh run list --workflow=release-android.yml --limit 1
# El hash local debe coincidir con SHA256SUMS.txt
```

## Firma Android — clave permanente vs efímera

| Modo | Cuándo | Implicación |
|---|---|---|
| `release-key` | los 4 secretos están configurados | Misma identidad de firma en todos los releases: Android permite **actualizar** la app sin desinstalar |
| `ephemeral-ci-key` | secretos ausentes | APK válido e instalable, pero cada release firma distinto: actualizar requiere desinstalar |

### Configurar la clave permanente (una sola vez)

El keystore del proyecto se genera y guarda **fuera del repositorio**
(p. ej. `%USERPROFILE%\.keystores\rootcause-mobile.jks`). Luego:

```powershell
$repo = 'vladimiracunadev-create/rootcause-mobile-inspector'
$ks = "$env:USERPROFILE\.keystores\rootcause-mobile.jks"
[Convert]::ToBase64String([IO.File]::ReadAllBytes($ks)) | gh secret set ANDROID_KEYSTORE_BASE64 -R $repo
gh secret set ANDROID_KEYSTORE_PASSWORD -R $repo   # pega la contraseña
gh secret set ANDROID_KEY_ALIAS -R $repo           # alias (p. ej. rootcause)
gh secret set ANDROID_KEY_PASSWORD -R $repo        # contraseña de la clave
```

> ⚠️ El keystore y sus contraseñas NUNCA se versionan. `.gitignore` ya
> excluye `*.jks`, `*.keystore` y `keystore.properties`.

## iOS (camino documentado, EN PAUSA)

> Decisión 2026-07-15: la distribución iOS queda **en pausa** por decisión
> del autor. El build iOS sigue compilando en CI solo como vigilancia de
> regresión del código compartido.

Estado actual: la app iOS **compila en CI** sin firma (job `build-ios`).
Para distribuir hace falta:

1. **Cuenta Apple Developer** (99 USD/año).
2. Certificado de distribución + provisioning profile (o gestión automática
   de Xcode).
3. `flutter build ipa` en macOS con la firma configurada.
4. Subida vía App Store Connect (TestFlight primero, App Store después) —
   revisión de Apple incluida. Alternativa fuera de tienda: solo
   *ad hoc*/enterprise, con límites de Apple.

Cuando exista la cuenta, el paso natural es un `release-ios.yml` con los
secretos de firma de Apple (certificado + profile en base64) espejo del
flujo Android.

## Checklist de release (resumen)

- [ ] `flutter analyze` y `flutter test` verdes en local
- [ ] `version:` de `pubspec.yaml` actualizada (semver + build number)
- [ ] README/docs actualizados si cambió el alcance
- [ ] `git tag vX.Y.Z && git push origin vX.Y.Z`
- [ ] Workflow release verde
- [ ] `gh release view vX.Y.Z` muestra APK + SHA256SUMS.txt
- [ ] Hash verificado e instalación probada en un dispositivo real
