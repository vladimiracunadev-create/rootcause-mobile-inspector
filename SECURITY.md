# Política de seguridad

## Versiones con soporte

| Versión | Soporte |
|---|---|
| 0.1.x | ✅ Correcciones de seguridad |
| < 0.1 | ❌ |

## Reportar una vulnerabilidad

1. **No abras un issue público** con el detalle del fallo.
2. Usa **GitHub Security Advisories** del repositorio
   (`Security → Report a vulnerability`) para un reporte privado.
3. Incluye: versión afectada, plataforma (Android/iOS), pasos de
   reproducción y el impacto que estimas.

Compromiso: acuse de recibo en un plazo razonable y crédito en el
advisory si lo deseas.

## Superficie de la app (qué sí y qué no hace)

- **Cero red saliente**: el manifest principal no declara el permiso
  `INTERNET` (los builds *debug* de Flutter lo añaden solo para hot-reload;
  el APK de release no lo lleva). Ninguna captura, historial o export sale
  del dispositivo por decisión de diseño.
- **Lectura, no intervención**: los colectores solo leen APIs públicas del
  SO (memoria, almacenamiento, batería, estado de red, paquetes instalados
  en Android). No mata procesos, no modifica configuración, no eleva
  privilegios.
- **Evidencia local**: el historial vive en el sandbox de la app; el export
  JSON se escribe únicamente donde el usuario lo indique.
- **Firma de releases**: los APK de Releases publican su hash en
  `SHA256SUMS.txt`; verifica la integridad antes de instalar.
