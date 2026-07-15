# Manual de usuario

RootCause Mobile Inspector observa tu teléfono y te dice, con evidencia,
si algo se comporta distinto. No necesita cuenta, no usa internet y no
envía nada a ninguna parte.

## La idea en una frase

> Cualquier distorsión anómala de los recursos del teléfono —memoria,
> almacenamiento, batería, permisos de apps— puede ser el primer indicio
> de un problema. RootCause vigila esas distorsiones y te dice dónde mirar.

## El semáforo

Arriba de la pestaña **Resumen** siempre hay un veredicto:

- 🟢 **Normal** — nada fuera de lo esperado.
- 🟡 **Advertencia** — hay indicios que conviene revisar.
- 🔴 **Crítico** — hay una distorsión seria ahora mismo.

Debajo del semáforo aparecen los **hallazgos**: cada uno explica qué se
detectó, con qué evidencia y qué se recomienda hacer.

## Pestañas

### Resumen

Semáforo global, hallazgos activos y las tres métricas base: memoria
(usada/disponible), almacenamiento (libre/total) y batería (nivel,
temperatura, salud). El botón **actualizar** (↻) toma una captura nueva.

### Apps (Android)

Lista las apps de usuario ordenadas por **puntaje de riesgo**: cuántos
permisos peligrosos solicita cada una (cámara, micrófono, ubicación, SMS,
contactos…), si puede dibujar sobre otras apps (overlay), si puede instalar
paquetes, y si llegó por **sideload** (fuera de una tienda conocida).

Importante y honesto: un puntaje alto **no significa que la app sea
maliciosa** — significa que su superficie de permisos merece una mirada.
En iPhone esta pestaña indica que el sistema no permite listar apps: no es
un fallo de RootCause, es diseño de iOS.

### Red

Tipo de conexión (WiFi/celular/ethernet), si hay **VPN activa**, si la red
es medida, ancho de banda estimado y tráfico total acumulado desde el
arranque. RootCause no inspecciona tu tráfico: solo lee contadores del SO.

### Almacenamiento

Espacio libre y usado del volumen de datos, y cuánto ocupa la caché propia
de la app. Si el espacio libre baja del 15 % (advertencia) o 5 % (crítico),
lo verás como hallazgo.

### Dispositivo

Fabricante, modelo, versión de OS, **parche de seguridad**, núcleos de CPU,
tiempo encendido e **indicadores de root/jailbreak**. Un indicador es un
indicio (un binario `su` presente, un build firmado con test-keys), no una
prueba definitiva.

### Historial

Cada captura queda guardada en el teléfono (últimas 500). Sirve para
comparar: ¿la memoria disponible viene bajando? ¿apareció una app riesgosa
que ayer no estaba?

### Acerca

Versión, autor, licencia y la política de privacidad local.

## Exportar evidencia

El botón de **exportar** copia la captura actual como JSON al
portapapeles y además la guarda como archivo en la carpeta de documentos
de la app (la ruta exacta aparece en pantalla al exportar). El formato usa
ids estables (`mem-pressure`, `risky-apps`…) para que la evidencia sea
comparable entre dispositivos y con RootCause para Windows.

## Idioma

La app está en **español e inglés**; usa el idioma del sistema.

## Qué NO hace esta app

- No elimina malware ni "limpia" el teléfono.
- No mata procesos de otras apps (el SO no lo permite).
- No lee tu tráfico, mensajes ni archivos personales.
- No usa internet: la evidencia solo sale si tú la exportas.
