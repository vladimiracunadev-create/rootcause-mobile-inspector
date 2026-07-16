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

## Las 6 familias

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
con `test-keys`. **iOS**: rutas de Cydia/Sileo/MobileSubstrate, `apt`, y
prueba de escritura fuera del sandbox. **Honestidad**: WARNING y no
CRITICAL a propósito — un equipo rooteado a propósito por su dueño
produce el mismo indicio; hace falta contexto humano.

## Veredicto global

```text
severidad_global = max(severidad de todos los hallazgos)
puntaje_global   = Σ (WARNING = 3 · CRITICAL = 10)
```

El puntaje permite comparar capturas entre sí en el historial (¿estoy
peor que ayer?) sin releer cada hallazgo.

## Cómo evolucionan

Cambiar un umbral significa tocar `RuleThresholds` y su test. Agregar una
regla nueva significa: una función privada en el engine, un id nuevo
documentado aquí, sus tests y sus strings ES/EN. El [ROADMAP](ROADMAP.md)
lista las reglas previstas (parche de seguridad antiguo, baseline de apps
entre capturas).
