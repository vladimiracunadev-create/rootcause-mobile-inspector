# Distribución — firma permanente y tiendas F-Droid/IzzyOnDroid

Esta guía cubre lo que hoy frena la adopción: la firma efímera (obliga a
desinstalar en cada versión y despierta a Play Protect) y la ausencia de
un canal de actualización. Ambos pasos requieren acciones del **autor**
que este repositorio deja preparadas pero no puede ejecutar solo.

## 1. Firma permanente (5 minutos, solo el autor)

Sin secretos de firma, el workflow usa una clave efímera distinta en cada
release. Con la clave permanente, cada versión se firma igual: las
actualizaciones instalan encima sin desinstalar y Play Protect deja de
ver una firma nueva desconocida.

El keystore permanente ya existe (creado en v0.1.0):
`%USERPROFILE%\.keystores\rootcause-mobile.jks` — credenciales en
`rootcause-mobile-keystore-info.txt`. Sube los 4 secretos al repo:

```bash
# En PowerShell, desde una máquina con el keystore:
$b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$env:USERPROFILE\.keystores\rootcause-mobile.jks"))
gh secret set ANDROID_KEYSTORE_BASE64  -R vladimiracunadev-create/rootcause-mobile-inspector -b $b64
gh secret set ANDROID_KEYSTORE_PASSWORD -R vladimiracunadev-create/rootcause-mobile-inspector -b "<store-pass>"
gh secret set ANDROID_KEY_ALIAS         -R vladimiracunadev-create/rootcause-mobile-inspector -b "rootcause"
gh secret set ANDROID_KEY_PASSWORD      -R vladimiracunadev-create/rootcause-mobile-inspector -b "<key-pass>"
```

Verifica que quedaron los cuatro:

```bash
gh secret list -R vladimiracunadev-create/rootcause-mobile-inspector
```

El siguiente release ya saldrá con `SIGNING_MODE=release-key` (lo declaran
las notas del release). **Importante**: el primer APK firmado con la clave
permanente sigue requiriendo desinstalar el efímero anterior una última vez.

## 2. IzzyOnDroid (el más rápido)

IzzyOnDroid toma los APKs directo de los GitHub Releases, sin rebuild.
Requisito previo: la firma permanente del paso 1.

1. Asegúrate de que cada release publica el APK por ABI (ya lo hace
   `release-android.yml`).
2. Abre una solicitud de inclusión (RFP) en el repositorio de IzzyOnDroid
   siguiendo su plantilla, apuntando a
   <https://github.com/vladimiracunadev-create/rootcause-mobile-inspector>.
3. La metadata de tienda ya está en `fastlane/metadata/android/` (ES y
   en-US) — IzzyOnDroid la lee automáticamente.

## 3. F-Droid (el sello de confianza)

F-Droid **recompila desde el código** y verifica que no haya
antifeatures. Es más lento pero da la máxima garantía.

- Requiere builds reproducibles y que todas las dependencias sean libres
  (ya se cumple: cero dependencias pub externas, solo AndroidX oficial).
- La metadata de `fastlane/metadata/` es la que F-Droid espera.
- El envío se hace vía merge request a `fdroiddata`. Documentar aquí el
  identificador de la app: `com.rootcause.mobileinspector`.

## 4. Builds reproducibles (verificación pública)

Objetivo: que cualquiera confirme que el APK publicado == el código.
Estado actual: el APK release depende de la clave de firma, pero el
contenido (DEX, recursos) debe ser bit a bit reproducible. Pasos:

- Fijar versiones exactas del SDK de Flutter (ya se hace: la CI clona el
  tag exacto) y de AGP/Gradle/Kotlin (fijadas en `android/`).
- Documentar el comando de verificación:
  `flutter build apk --release --split-per-abi` y comparar el hash del
  DEX contra el del APK publicado (excluyendo el bloque de firma).

Este punto queda como trabajo abierto: la reproducibilidad total exige
congelar el entorno de build y está anotada en [ROADMAP.md](ROADMAP.md).

## Estado

| Paso | Quién | Estado |
|---|---|---|
| Metadata de tienda (ES/EN) | preparado en el repo | ✅ |
| Política de privacidad pública | `landing/privacidad.html` | ✅ |
| Firma permanente (secretos) | **autor** | ⏳ pendiente |
| Envío a IzzyOnDroid | autor (tras firma) | ⏳ |
| Envío a F-Droid | autor (tras firma) | ⏳ |
| Builds reproducibles | por hacer | ⏳ |
