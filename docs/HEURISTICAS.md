# Heurísticas del motor de reglas

Este documento es la **especificación exacta** de cada regla: umbral,
severidad, evidencia que produce y por qué existe. Todo lo aquí descrito
está implementado en [`lib/core/rule_engine.dart`](../lib/core/rule_engine.dart)
y cubierto por tests en [`test/rule_engine_test.dart`](../test/rule_engine_test.dart).

## Principios

1. **Umbrales centralizados** en `RuleThresholds` — nada de números
   mágicos repartidos por el código.
2. **Cada hallazgo lleva su evidencia** (los `args`): nunca "hay un
   problema" a secas.
3. **Regla no evaluable → regla omitida**: si la plataforma no expone la
   señal (p. ej. temperatura de batería en iOS), no se inventa un valor.
4. **Ids estables** neutrales al idioma: la UI traduce; el export JSON
   conserva el id.

## Las 9 familias

### 1 · `mem-pressure` — presión de memoria

| Condición | Severidad |
|---|---|
| RAM disponible < 20 % del total | 🟡 WARNING |
| RAM disponible < 10 % **o** el SO activa su flag `lowMemory` | 🔴 CRITICAL |

**Evidencia**: porcentaje disponible. **Por qué**: la presión de memoria
sostenida degrada todo el equipo y puede indicar una app fugando memoria
o un proceso anómalo residente.

### 2 · `storage-low` — almacenamiento crítico

| Condición | Severidad |
|---|---|
| Espacio libre < 15 % | 🟡 WARNING |
| Espacio libre < 5 % | 🔴 CRITICAL |

**Evidencia**: porcentaje libre. **Por qué**: bajo el 5 % Android empieza
a fallar (no puede escribir, las apps crashean). También puede delatar
crecimiento anómalo de datos de una app.

### 3 · `battery-temp` — temperatura anómala de batería

| Condición | Severidad |
|---|---|
| ≥ 40 °C | 🟡 WARNING |
| ≥ 45 °C | 🔴 CRITICAL |

**Evidencia**: temperatura en °C. **Por qué**: calor sostenido sin uso
intensivo es la señal indirecta más accesible de carga de CPU anómala
(p. ej. cryptojacking) — Android no deja ver el CPU de otras apps, la
temperatura sí. **Solo se evalúa si la plataforma la expone**
(`temperatureAvailable`); en iOS se omite.

### 4 · `battery-health` — salud de batería degradada

| Condición | Severidad |
|---|---|
| El SO reporta salud ≠ `good`/`unknown` (overheat, dead, over-voltage, failure, cold) | 🟡 WARNING |

**Evidencia**: la etiqueta que reporta el SO.

### 5 · `risky-apps` — superficie de permisos peligrosa

Primero se calcula el **puntaje de riesgo por app** (en Dart compartido,
una sola política):

| Factor | Puntos |
|---|---|
| Cada permiso peligroso solicitado (cámara, micrófono, ubicación, SMS, contactos, llamadas, almacenamiento, sensores, calendario…) | +1 |
| Solicita `SYSTEM_ALERT_WINDOW` (overlay — técnica de bankers) | +3 |
| Solicita `REQUEST_INSTALL_PACKAGES` (dropper potencial) | +3 |
| Solicita device-admin | +2 |
| Instalada por **sideload** (fuera de tienda conocida) | +2 |

| Puntaje de app | Severidad de la app |
|---|---|
| ≥ 8 | 🟡 WARNING |
| ≥ 12 | 🔴 CRITICAL |

Y la regla global:

| Condición | Severidad del hallazgo |
|---|---|
| ≥ 1 app con puntaje ≥ 8 | 🟡 WARNING |
| ≥ 5 apps con puntaje ≥ 8 | 🔴 CRITICAL |

**Evidencia**: cantidad y nombres (hasta 3). **Honestidad**: mide
permisos **solicitados**, no uso real — un puntaje alto es motivo de
revisión humana, no un veredicto de malicia.

### 6 · `root-indicators` — indicadores de root/jailbreak

| Condición | Severidad |
|---|---|
| ≥ 1 indicador | 🟡 WARNING |

**Indicadores Android**: binario `su` en 7 rutas conocidas; build firmado
con `test-keys`; desde v0.5.0 también **bootloader desbloqueado**
(`ro.boot.flash.locked=0`) y **verified boot no-verde**
(`ro.boot.verifiedbootstate`). **iOS**: rutas de Cydia/Sileo/MobileSubstrate,
`apt`, y prueba de escritura fuera del sandbox. **Honestidad**: WARNING y
no CRITICAL a propósito — un equipo rooteado a propósito por su dueño
produce el mismo indicio; hace falta contexto humano.

### 7 · `load-rising` — carga en ascenso sostenido (v0.2.0)

| Condición | Severidad |
|---|---|
| La memoria disponible **o** el disco libre caen de forma sostenida a lo largo de las capturas recientes | 🟡 WARNING |

Parámetros exactos (constantes en `RuleEngine`): se necesitan ≥ 4 puntos
(capturas previas + la actual) dentro de una ventana de 6 horas; ningún
paso puede mejorar más de 2 puntos porcentuales (tolerancia a ruido) y la
caída total debe ser ≥ 15 puntos. Memoria y disco se evalúan por separado
y pueden generar dos hallazgos independientes.

**Evidencia**: métrica afectada + porcentaje inicial y final de la serie.
**Por qué**: es la razón de existir del sistema aplicada al tiempo — la
distorsión que crece de forma sostenida es el indicio temprano, aunque
ningún umbral absoluto haya disparado todavía. Requiere historial: con la
auto-captura activada la serie se alimenta sola.

### 8 · `new-apps` — apps nuevas desde la última captura (v0.3.0)

| Condición | Severidad |
|---|---|
| ≥ 1 app instalada que no estaba en el baseline de la captura anterior | 🟡 WARNING |

El equivalente móvil del `persistence-change` de la edición Windows: el
malware llega **instalándose**. El baseline (`rootcause-apps-baseline.json`)
registra cada paquete visto; la comparación es transitoria a propósito —
el hallazgo aparece en la captura que detecta la instalación y el
baseline lo absorbe después.

**Evidencia**: cantidad, nombres (hasta 3) y cuántas de las nuevas tienen
superficie riesgosa o sideload. **Honestidad**: la primera captura
inicializa el baseline EN SILENCIO (lo ya instalado no es "nuevo"); una
app desinstalada se poda, así que reinstalar vuelve a contar como evento;
en iOS no hay baseline porque no hay lista de apps que comparar.

### 9 · `patch-old` — parche de seguridad antiguo (v0.4.0)

| Condición | Severidad |
|---|---|
| Parche con ≥ 180 días de antigüedad | 🟡 WARNING |
| Parche con ≥ 365 días de antigüedad | 🔴 CRITICAL |

**Evidencia**: edad en días + fecha del parche. **Por qué**: cada mes sin
parches acumula vulnerabilidades CONOCIDAS y públicas; a un año, el
equipo es atacable con exploits documentados. **Honestidad**: solo se
evalúa si la plataforma expone la fecha en formato parseable
(Android: `YYYY-MM-DD`); iOS reporta su versión, no una fecha → regla
omitida, no inventada. El hallazgo trae el botón "Buscar actualizaciones"
que abre la pantalla de actualización del sistema.

## Veredicto global

```text
severidad_global = max(severidad de todos los hallazgos)
puntaje_global   = Σ (WARNING = 3 · CRITICAL = 10)
```

El puntaje permite comparar capturas entre sí en el historial (¿estoy
peor que ayer?) sin releer cada hallazgo.

## Umbrales modificables por el usuario (v0.2.0)

Desde la pestaña **Configuración** el usuario puede ajustar los umbrales
de memoria, disco y temperatura de batería (persisten en
`rootcause-config.json`). Los valores de las tablas de arriba son los
por defecto; el export JSON registra siempre la evidencia cruda, nunca el
umbral, así que la evidencia sigue siendo comparable entre dispositivos
con configuraciones distintas.

## Cómo evolucionan

Cambiar un umbral por defecto significa tocar `RuleThresholds` y su test.
Agregar una regla nueva significa: una función privada en el engine, un id
nuevo documentado aquí, sus tests y sus strings ES/EN. El
[ROADMAP](ROADMAP.md) lista lo previsto.
