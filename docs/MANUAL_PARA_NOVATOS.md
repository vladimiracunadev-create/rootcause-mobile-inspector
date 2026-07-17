# Manual para novatos

Si nunca instalaste una app fuera de la tienda ni sabes qué es un "APK",
este documento es para ti. Sin tecnicismos.

## ¿Qué es RootCause y para qué me sirve?

Es una app que **revisa la salud de tu teléfono** y te avisa si algo se
comporta raro: poca memoria, disco casi lleno, batería demasiado
caliente, o una app que pide demasiados permisos peligrosos.

Piensa en ella como un **chequeo médico del teléfono**: no te opera (no
borra nada, no "limpia"), pero te dice dónde está el problema y qué
conviene hacer.

## ¿Es segura? ¿Me espía?

No. Y no tienes que creernos: se puede **comprobar**.

- La app **no puede usar internet** — está construida sin ese permiso.
  Es físicamente incapaz de enviar tus datos a alguien.
- No pide acceso a tus fotos, mensajes ni contactos.
- Todo lo que ve se queda guardado **dentro de tu teléfono**.
- El código es público: cualquier programador puede revisarlo.

## Instalar, paso a paso

1. Desde el navegador del teléfono entra a
   [la página de descargas](https://github.com/vladimiracunadev-create/rootcause-mobile-inspector/releases/latest).
2. Toca el archivo que termina en **`arm64-v8a.apk`** (si tu teléfono es
   de 2017 en adelante, es ese; si algo falla, usa el que dice
   `universal`).
3. Al abrir la descarga, el teléfono te dirá algo como *"por tu
   seguridad, no puedes instalar apps de origen desconocido"*. Es
   normal: significa que la app no viene de Play Store. Toca
   **Ajustes → Permitir de esta fuente** y vuelve atrás.
4. Toca **Instalar**. Listo.

> Si aparece un aviso de Play Protect, es porque la app es nueva y no
> está en la tienda — no porque tenga algo malo. Puedes tocar
> "Instalar de todas formas".

## Usar la app

1. Abre **RootCause**.
2. Espera unos segundos: está "mirando" el estado del teléfono.
3. Fíjate en el **color de arriba**:
   - 🟢 Verde → todo bien, no hay nada que hacer.
   - 🟡 Amarillo → hay algo que conviene revisar; léelo, la app te
     explica qué es y qué hacer.
   - 🔴 Rojo → hay un problema serio ahora mismo (por ejemplo, disco
     lleno); sigue la recomendación.
4. Desliza las pestañas de arriba para ver más: **Apps** (cuáles piden
   permisos delicados), **Red**, **Almacenamiento** (con tu tarjeta SD si
   tienes), **Dispositivo**, **Cercanía** (aparatos Bluetooth cerca),
   **Historial** y **Configuración**.

## Preguntas típicas

**¿Por qué una app aparece con "riesgo alto"? ¿Es un virus?**
No necesariamente. Significa que **pide muchos permisos delicados**
(cámara + micrófono + SMS, por ejemplo). Si es tu app de mensajería, es
normal. Si es un juego que instalaste ayer de un link raro… sospecha.

**¿La app arregla los problemas?**
No — te los **muestra con evidencia** y te deja **a un toque** de la
pantalla del sistema donde tú puedes arreglarlo (liberar espacio, ver la
batería, desinstalar una app). Eso es a propósito: una app de diagnóstico
no debería tocar tu teléfono sin que tú entiendas por qué.

**¿Gasta batería?**
Casi nada: con la app abierta toma una foto del estado cada 5 minutos
(puedes cambiarlo o apagarlo en Configuración). Si activas la vigilancia
con la app cerrada, puedes limitarla a **solo cuando está cargando** —
así no gasta nada de tu batería.

**¿Y si quiero desinstalarla?**
Como cualquier app: mantén pulsado el icono → Desinstalar. No deja nada
atrás.

## ¿Quieres entender más?

El [Manual de usuario completo](MANUAL_USUARIO.md) explica cada pestaña
con detalle, en lenguaje claro.
