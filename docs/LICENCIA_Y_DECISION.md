# Licencia y decisión

Este documento registra la decisión de licencia de RootCause Mobile Inspector y el razonamiento detrás de ella.

## Licencia actual

**Apache License 2.0**, desde la fundación del proyecto (v0.1.0) y vigente en v0.3.0. El texto completo está en [`LICENSE`](../LICENSE).

Es la misma licencia que el proyecto hermano, [rootcause-windows-inspector](https://github.com/vladimiracunadev-create/rootcause-windows-inspector), que documentó la decisión primero: misma familia, misma licencia. Este proyecto la hereda de forma consciente desde el primer commit, sin la etapa MIT inicial que tuvo la edición Windows.

## Por qué Apache 2.0 y no MIT

Ambas son permisivas, pero Apache 2.0 añade lo que a MIT le falta:

| Aspecto | MIT | Apache 2.0 |
|---|---|---|
| Redistribución libre | ✅ | ✅ |
| Uso comercial | ✅ | ✅ |
| Modificación sin restricciones | ✅ | ✅ |
| Grant de patentes explícito | ❌ | ✅ |
| Terminación del grant ante litigio de patentes | ❌ | ✅ |
| Requiere preservar avisos | ✅ (mínimo) | ✅ (más explícito) |

## Por qué encaja con un sensor forense

Este producto pide permisos sensibles (estadísticas de uso, lista de apps) y su promesa central es **cero telemetría: la evidencia se queda en el dispositivo**. Esa promesa, en una app cerrada, sería solo marketing. Con el código abierto bajo Apache 2.0:

- la garantía de privacidad **se puede verificar leyendo el código** — [`POLITICA_DE_PRIVACIDAD_LOCAL.md`](POLITICA_DE_PRIVACIDAD_LOCAL.md) apunta a los archivos concretos que la sostienen,
- cualquiera puede compilar su propio APK desde el fuente ([`BUILD_MOVIL.md`](BUILD_MOVIL.md)) y comparar el comportamiento con el binario publicado,
- las heurísticas de detección son auditables ([`HEURISTICAS.md`](HEURISTICAS.md)): un sensor forense cuyo criterio es secreto no es confiable como evidencia.

Transparencia auditable no es un extra del proyecto: es el mecanismo por el que sus afirmaciones se vuelven verificables.

## La cláusula de patentes

Cada contribuidor otorga automáticamente a los usuarios una licencia sobre las patentes que cubran su aporte (sección 3 de la licencia). Y si alguien inicia un litigio de patentes contra el proyecto, pierde ese grant en el acto. Para software de diagnóstico con posible uso corporativo, esa defensa explícita es la diferencia práctica frente a MIT.

## Qué implica para quien haga fork o redistribuya el APK

Puede hacerlo libremente, incluso con fines comerciales, cumpliendo lo que Apache 2.0 exige:

- conservar el archivo `LICENSE` y los avisos de copyright y atribución,
- indicar los cambios relevantes si distribuye una versión modificada,
- no usar el nombre del proyecto de forma que sugiera respaldo del autor.

Además, dos consecuencias específicas de distribuir un APK:

- **La identidad de firma Android no se hereda.** El keystore permanente del autor vive fuera del repositorio y sus secretos (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`) no se publican. Un fork firma con su propia clave, y Android tratará su APK como una app distinta: no puede suplantar ni "actualizar" la instalación oficial. Eso protege a los usuarios, no los limita.
- **Los hashes oficiales solo validan los APKs oficiales.** El `SHA256SUMS.txt` de cada release cubre los binarios publicados en este repositorio; un APK redistribuido por terceros debe verificarse contra los hashes del release original o compilarse desde el fuente.

## Qué NO cubre

- La **marca** y el nombre "RootCause" (eso requiere registro de marca separado).
- No obliga a publicar modificaciones: no es copyleft.
- No impide que terceros usen el código de formas que el autor no anticipe — solo exige atribución y transparencia sobre los cambios.

## Ruta futura

La decisión de fondo (dual license vs mantener Apache 2.0 en una eventual v1.0) se evalúa a nivel de familia RootCause y está documentada en el `LICENCIA_Y_DECISION.md` del proyecto Windows. Mientras esa evaluación no ocurra, este proyecto permanece en Apache 2.0.

## Historial

| Versión | Licencia | Notas |
|---|---|---|
| v0.1.0 | Apache 2.0 | Decisión heredada del hermano Windows, aplicada desde el primer commit |
| v0.1.1 | Apache 2.0 | Sin cambios |
| v0.2.1 | Apache 2.0 | Sin cambios |
| v0.3.0 | Apache 2.0 | Sin cambios |
