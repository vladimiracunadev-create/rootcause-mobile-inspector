# Roadmap

## v0.1.1 — Landing + APKs por ABI (actual)

- ✅ Landing page en GitHub Pages (mismo esquema que la edición Windows)
- ✅ Release publica APKs divididos por ABI (arm64-v8a / armeabi-v7a,
  ≈ 1/3 del peso) además del universal
- ✅ Trade-off de peso Flutter vs Rust documentado con números en
  ARCHITECTURE.md

## v0.1.0 — Fundación multiplataforma

- ✅ Arquitectura Flutter: núcleo Dart compartido + colectores nativos
  (Kotlin/Swift) por MethodChannel
- ✅ Motor de reglas local con 6 familias de hallazgo y umbrales centralizados
- ✅ Auditoría de superficie de permisos por app (Android)
- ✅ Indicadores de root/jailbreak honestos
- ✅ Historial local (JSON Lines, retención 500) + export JSON forense
- ✅ UI Material 3 bilingüe ES/EN con semáforo y evidencia
- ✅ CI multiplataforma (Android + iOS) y release Android automatizado

## v0.2.x — Profundidad Android

- [ ] Regla de parche de seguridad antiguo (> N meses → warning)
- [ ] Baseline de apps instaladas: detectar apps NUEVAS entre capturas
  (equivalente móvil del `persistence-change` de la edición Windows)
- [ ] Comparación A vs B en el tab Historial con deltas
- [ ] Permiso `PACKAGE_USAGE_STATS` opcional (opt-in del usuario) para
  consumo real de batería/datos por app
- [ ] Notificación local cuando el veredicto pasa a Critical

## v0.3.x — iOS de primera clase (EN PAUSA)

> Decisión 2026-07-15: la distribución iOS queda en pausa por decisión del
> autor. El build iOS se mantiene compilando en CI como vigilancia de
> regresión del código compartido, sin trabajo adicional de plataforma.

- [ ] Cuenta Apple Developer + `release-ios.yml` (TestFlight)
- [ ] Colector iOS ampliado (memoria con mach APIs, jailbreak avanzado)
- [ ] Paridad de UI/estado por plataforma documentada

## Ideas evaluadas y pospuestas

| Idea | Por qué se pospone |
|---|---|
| VPN local para inspección de tráfico | Gran superficie de código y de confianza; contradice "cero red" v0.1 |
| Análisis de APK (hashes contra listas) | Requiere red o bases locales grandes |
| Modo empresa (MDM) | Primero validar el producto individual |
| Núcleo Rust compartido vía FFI (colectores en Rust, UI Flutter) | Ganancia real solo si el peso/consumo se vuelven críticos; hoy el costo de complejidad no se justifica — ver trade-off en [ARCHITECTURE.md](ARCHITECTURE.md#trade-off-honesto-peso-del-apk-flutter-vs-rust) |

## Principios que no cambian

1. Todo hallazgo declarado debe ser **verificable en el código**.
2. Ninguna promesa que el SO no permita cumplir.
3. Privacidad por diseño: sin `INTERNET`, evidencia solo local/exportada.
