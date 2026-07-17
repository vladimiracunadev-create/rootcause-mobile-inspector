# RootCause Mobile frente al open source de diagnóstico móvil

Comparativa honesta con herramientas open source que un usuario podría
considerar junto a (o en vez de) RootCause Mobile Inspector. Las herramientas
ajenas se describen **solo en términos generales de su categoría**, sin
versiones ni cifras: para datos exactos, consulta cada proyecto.

**Dónde encaja RootCause Mobile (v0.4.0):** sensor forense **local y sin
red** (sin permiso `INTERNET` en release) que correlaciona varias señales del
propio dispositivo — memoria, almacenamiento, batería, red, superficie de
permisos por app, indicadores de root/jailbreak — y entrega un **veredicto
explicado** (semáforo + hallazgos con evidencia) más un **export JSON forense**
comparable con la edición Windows. Apache 2.0, cero telemetría. **No es
antivirus ni escáner de malware.**

## Tabla comparativa por categoría

| Herramienta | Categoría general | Qué responde |
|---|---|---|
| **RootCause Mobile** | Correlación local multi-señal | "¿Hay distorsiones de recursos o superficie de riesgo en ESTE dispositivo, y por qué?" |
| Hypatia | Escáner de malware | "¿Algún archivo coincide con firmas de malware conocidas?" |
| Auditor (GrapheneOS) | Atestación de hardware | "¿Puedo probar criptográficamente que el sistema operativo no fue alterado?" |
| Exodus Privacy | Análisis de trackers y permisos | "¿Qué rastreadores y permisos incorpora esta app?" |
| PCAPdroid | Captura de tráfico de red | "¿Con quién está hablando mi dispositivo por la red?" |
| SnoopSnitch | Análisis de red móvil y parches | "¿Mi red móvil muestra anomalías y mi Android tiene los parches que dice tener?" |

## Qué hace cada categoría — y qué aporta RootCause que ellas no

- **Escáneres de malware** (categoría de Hypatia) comparan archivos contra
  bases de firmas conocidas: responden "¿esto ES malware conocido?". RootCause
  no busca firmas; busca **síntomas**: presión de memoria, almacenamiento
  agotado, batería fuera de rango, apps con superficie de permisos peligrosa,
  indicios de root. Un malware sin firma publicada puede pasar limpio un
  escáner y aun así dejar distorsiones que RootCause sí muestra.
- **Atestación de hardware** (categoría de Auditor) verifica la integridad del
  sistema operativo con criptografía anclada en hardware — la respuesta más
  fuerte posible a "¿me modificaron el SO?". RootCause solo ofrece indicadores
  heurísticos de root/jailbreak (**indicio, no prueba**, ver
  [LIMITACIONES.md](LIMITACIONES.md)), pero funciona en cualquier dispositivo,
  sin segundo aparato ni requisitos de hardware.
- **Análisis de trackers** (categoría de Exodus Privacy) inspecciona qué SDKs
  de rastreo y permisos declara una app, típicamente contra un catálogo
  externo. RootCause audita la **superficie de permisos realmente solicitada**
  por cada app instalada en tu dispositivo, con puntaje explicado, 100 %
  offline.
- **Captura de tráfico** (categoría de PCAPdroid) observa las conexiones en
  vivo, normalmente actuando como VPN local. RootCause renunció a esa vía a
  propósito: contradice su regla de cero red (ver
  [ROADMAP.md](ROADMAP.md#ideas-evaluadas-y-pospuestas)). Solo reporta estado
  de red puntual: transporte, VPN activa, contadores globales.
- **Análisis de red móvil y parches** (categoría de SnoopSnitch) examina
  eventos de la capa de radio y la correspondencia real de los parches de
  seguridad. RootCause reporta la fecha de parche que declara el sistema, sin
  verificarla contra la capa de radio.

Lo que ninguna de esas categorías hace y RootCause sí: **correlacionar varias
señales locales en un solo veredicto explicado**, guardar historial local
(JSON Lines) y exportar evidencia JSON con ids de hallazgo estables,
**comparable con la edición Windows** de RootCause — mismo lenguaje de
evidencia en el PC y en el teléfono.

## Qué hacen ellas que RootCause NO hace

| Capacidad | ¿RootCause la tiene? |
|---|---|
| Escaneo de firmas de malware | ❌ No, y no está en el roadmap: requiere bases de firmas grandes o red |
| Atestación criptográfica de hardware | ❌ No; solo indicadores heurísticos de root/jailbreak |
| Captura o inspección de tráfico de red | ❌ No; renuncia deliberada (cero red) |
| Detección de SDKs de rastreo dentro del código de una app | ❌ No; audita permisos solicitados, no el código |
| Análisis de la capa de radio / banda base | ❌ No |

## Posicionamiento

RootCause Mobile **complementa, no reemplaza**. Un kit razonable usa un
escáner de malware para firmas conocidas, atestación si el hardware lo
permite, un analizador de trackers antes de instalar apps, captura de tráfico
cuando hay que ver la red — y RootCause como el sensor local que correlaciona
los síntomas del dispositivo y deja evidencia forense comparable entre tu
teléfono y tu PC. Todos estos proyectos empujan en la misma dirección:
diagnóstico y seguridad móvil abiertos y auditables.

Ver también: [DETECCION_AMENAZAS.md](DETECCION_AMENAZAS.md) (amenaza →
detección hoy), [ARCHITECTURE.md](ARCHITECTURE.md) y
[LIMITACIONES.md](LIMITACIONES.md).
