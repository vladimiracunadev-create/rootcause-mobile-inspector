# Flutter para RootCause — por qué la edición móvil se escribió así

## 1. Objetivo de este documento

La edición Windows de RootCause está escrita en Rust y su repo explica por qué
(ver `docs/RUST_PARA_ROOTCAUSE.md` en `rootcause-windows-inspector`). Este
documento hace lo mismo para la edición móvil: explica **por qué Flutter**, qué
se ganó, qué se pagó, y qué alternativas se descartaron y por qué. Todo lo
afirmado aquí es verificable en el código de este repositorio.

## 2. La restricción que manda: Android **e** iOS

El requisito del producto es un sensor forense que corra en ambos móviles con
la misma evidencia y el mismo veredicto. Con Flutter (3.44.6, Dart 3.12), un
solo código Dart cubre:

- la UI completa (Material 3, bilingüe ES/EN),
- el motor de reglas (`lib/core/rule_engine.dart`),
- el export JSON forense (`lib/core/snapshot_json.dart`),
- el historial local (`lib/core/history_store.dart`).

Lo único que de verdad difiere por sistema operativo — leer memoria, batería,
red, apps — queda aislado en colectores nativos pequeños: Kotlin en
`android/app/src/main/kotlin/` y Swift en `ios/Runner/AppDelegate.swift`.

## 3. Canal nativo propio, cero plugins de terceros

En vez de plugins de pub.dev, este repo define **un solo MethodChannel propio**
(`rootcause/collectors`) con dos métodos: `collect` y `documentsPath`. El
puente Dart vive en `lib/platform/collectors.dart`; el contrato completo está
en [ARCHITECTURE.md](ARCHITECTURE.md).

El resultado se verifica en `pubspec.yaml`: la sección `dependencies` contiene
únicamente el SDK de Flutter, y las `dev_dependencies` son `flutter_test`
(parte del SDK) y `flutter_lints` (linter; no entra al APK).

```yaml
dependencies:
  flutter:
    sdk: flutter
```

Por qué importa:

- **Superficie de auditoría mínima**: nadie más que este repo decide qué se
  lee del dispositivo. Un contrato, dos implementaciones, todo a la vista.
- **Cero cadena de suministro pub externa**: no hay paquetes de terceros que
  revisar, fijar ni actualizar por CVE ajenos.
- **Coherencia con la casa**: sin permiso `INTERNET` en release
  (`android/app/src/main/AndroidManifest.xml`), la promesa de cero telemetría
  es verificable por diseño, no por confianza.

El costo honesto: cosas que un plugin regala (rutas de documentos, info de
batería) se implementaron a mano. Para el alcance de esta app, ese costo fue
bajo y el control lo compensa.

## 4. Núcleo Dart puro: testeable sin dispositivo

`lib/core/` no importa Flutter — solo Dart. Eso permite que los tests de
`test/` (modelos, motor de reglas, export JSON, historial) corran en CI sin
emulador ni dispositivo físico:

```powershell
flutter test
```

Es el equivalente móvil de la separación `models.rs` / `services/` de la
edición Windows: la lógica que decide el veredicto se prueba como función pura
`Snapshot → Verdict`.

## 5. El trade-off honesto: peso del APK

Un binario Rust de la edición Windows pesa una fracción de lo que pesa un APK
Flutter, porque Flutter empaqueta su engine de renderizado en cada
arquitectura. Este costo está declarado y **cuantificado con números reales en
[ARCHITECTURE.md](ARCHITECTURE.md#trade-off-honesto-peso-del-apk-flutter-vs-rust)**,
junto con las mitigaciones aplicadas (APKs divididos por ABI, R8, tree-shaking
de iconos). No se repite aquí para no duplicar cifras.

## 6. Alternativas evaluadas y por qué no

| Alternativa | Por qué se descartó |
|---|---|
| Kotlin + Swift nativos puros | Duplicar UI, motor de reglas, export e historial en dos códigos que hay que mantener idénticos a mano. El riesgo real no es escribirlo dos veces: es que las dos copias diverjan en silencio |
| React Native | Añade un puente JavaScript en runtime y arrastra el ecosistema npm como cadena de suministro — lo contrario de la regla "cero dependencias externas auditables" de este proyecto |
| Rust + FFI (colectores en Rust, UI en Flutter) | Evaluado y pospuesto en el [ROADMAP](ROADMAP.md#ideas-evaluadas-y-pospuestas): la ganancia solo aparece si el peso o el consumo se vuelven críticos; hoy el costo de complejidad (toolchain doble, bindings) no se justifica |

Ninguna de estas opciones es mala en general. Son malas **para este producto**,
cuyas restricciones son: dos plataformas, un mantenedor, evidencia idéntica en
ambas, y dependencias externas en cero.

## 7. Cómo leer este repositorio sin perderte

1. `pubspec.yaml` — versión, SDK, y la prueba de cero dependencias.
2. `lib/main.dart` — arranque y flujo principal de la UI.
3. `lib/core/` — modelos, motor de reglas, export, historial (Dart puro).
4. `lib/platform/collectors.dart` — el puente al canal nativo.
5. `android/.../MainActivity.kt` y `ios/Runner/AppDelegate.swift` — las dos
   implementaciones del contrato.
6. `test/` — qué protege cada pieza.

## 8. Conclusión

Flutter no se eligió por moda: se eligió porque la restricción dominante era
**un solo código para dos sistemas operativos con cero dependencias de
terceros**, y Flutter con un canal nativo propio es la forma más barata de
cumplirla. El precio (peso del APK) está medido, documentado y mitigado; y la
puerta a un núcleo Rust compartido queda abierta en el roadmap si algún día
las cuentas cambian.
