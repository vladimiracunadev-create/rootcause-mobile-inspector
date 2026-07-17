/// Textos bilingües ES/EN — Dart puro, sin framework de localización.
///
/// Deliberadamente simple: dos idiomas, una clase, getters testeables.
/// Los ids de hallazgo se traducen aquí; el export JSON nunca se traduce.
library;

import '../core/models.dart';

class AppStrings {
  const AppStrings(this.spanish);

  final bool spanish;

  String _t(String es, String en) => spanish ? es : en;

  // Tabs
  String get tabSummary => _t('Resumen', 'Summary');
  String get tabApps => _t('Apps', 'Apps');
  String get tabNetwork => _t('Red', 'Network');
  String get tabStorage => _t('Almacenamiento', 'Storage');
  String get tabDevice => _t('Dispositivo', 'Device');
  String get tabNearby => _t('Cercanía', 'Nearby');
  String get tabHistory => _t('Historial', 'History');
  String get tabSettings => _t('Configuración', 'Settings');
  String get tabAbout => _t('Acerca', 'About');

  // Acciones
  String get actionLanguage => _t('Switch to English', 'Cambiar a español');
  String get actionRefresh => _t('Actualizar captura', 'Refresh snapshot');
  String get actionExport =>
      _t('Exportar JSON forense', 'Export forensic JSON');
  String get loading =>
      _t('Capturando estado del dispositivo…', 'Capturing device state…');
  String exportOk(String path) => _t(
    'Evidencia copiada al portapapeles y guardada en $path',
    'Evidence copied to clipboard and saved to $path',
  );
  String get exportFail =>
      _t('No se pudo exportar la evidencia', 'Could not export evidence');

  // Veredicto
  String get verdictNormal => _t(
    'Sistema estable — sin distorsiones',
    'System stable — no distortions',
  );
  String get verdictWarning => _t(
    'Advertencia — hay indicios que revisar',
    'Warning — signals to review',
  );
  String get verdictCritical => _t(
    'Crítico — distorsión seria en curso',
    'Critical — serious distortion',
  );
  String verdictScore(int score) => _t('Puntaje: $score', 'Score: $score');
  String get findingsNone => _t(
    'Sin hallazgos: el dispositivo se ve estable.',
    'No findings: the device looks stable.',
  );
  String get severityNormal => _t('Normal', 'Normal');
  String get severityWarning => _t('Advertencia', 'Warning');
  String get severityCritical => _t('Crítico', 'Critical');
  String recommendation(String text) =>
      _t('Recomendación: $text', 'Recommendation: $text');

  // Memoria / almacenamiento / batería
  String get memTitle => _t('Memoria', 'Memory');
  String get memUsed => _t('Usada', 'Used');
  String get memAvailable => _t('Disponible', 'Available');
  String get memTotal => _t('Total', 'Total');
  String get storageTitle => _t('Almacenamiento', 'Storage');
  String get storageFree => _t('Libre', 'Free');
  String get storageUsed => _t('Usado', 'Used');
  String get storageTotal => _t('Total', 'Total');
  String get cacheTitle => _t('Caché de esta app', 'This app\'s cache');
  String get cacheSize => _t('Tamaño', 'Size');
  String get cacheNote => _t(
    'Android e iOS no permiten leer la caché de otras apps; esta cifra es la caché propia de RootCause.',
    'Android and iOS do not allow reading other apps\' caches; this figure is RootCause\'s own cache.',
  );
  String get cacheClear => _t('Limpiar caché propia', 'Clear own cache');
  String cacheCleared(String freed) =>
      _t('Caché propia liberada: $freed', 'Own cache cleared: $freed');
  String get volumeInternal => _t('Interno (datos)', 'Internal (data)');
  String get volumeRemovable => _t('extraíble', 'removable');
  String get volumesNone => _t(
    'Sin volúmenes adicionales: este equipo no tiene tarjeta SD ni USB conectado (o el SO no los expone). No es un fallo — se muestran solo cuando existen.',
    'No additional volumes: this device has no SD card or USB attached (or the OS does not expose them). Not a failure — they are listed only when present.',
  );
  String get batteryTitle => _t('Batería', 'Battery');
  String get batteryLevel => _t('Nivel', 'Level');
  String get batteryState => _t('Estado', 'State');
  String get batteryCharging => _t('Cargando', 'Charging');
  String get batteryDischarging => _t('Descargando', 'Discharging');
  String get batteryTemp => _t('Temperatura', 'Temperature');
  String get batteryHealth => _t('Salud', 'Health');
  String get notAvailableOnPlatform =>
      _t('No disponible en este SO', 'Not available on this OS');

  // Red
  String get networkTitle => _t('Estado de red', 'Network state');
  String get netConnected => _t('Conectado', 'Connected');
  String get netTransport => _t('Transporte', 'Transport');
  String get netVpn => _t('VPN activa', 'VPN active');
  String get netMetered => _t('Red medida', 'Metered network');
  String get netDown => _t('Bajada estimada', 'Estimated downlink');
  String get netUp => _t('Subida estimada', 'Estimated uplink');
  String get netTrafficTitle => _t(
    'Tráfico acumulado (desde el arranque)',
    'Accumulated traffic (since boot)',
  );
  String get netRx => _t('Recibido', 'Received');
  String get netTx => _t('Enviado', 'Sent');
  String get netTrafficNote => _t(
    'Contadores globales del SO. RootCause no inspecciona el contenido de tu tráfico.',
    'OS-wide counters. RootCause does not inspect your traffic contents.',
  );
  String get yes => _t('Sí', 'Yes');
  String get no => _t('No', 'No');

  // Apps
  String get appsTitle => _t('Auditoría de apps', 'App audit');
  String get appsTotal => _t('Apps de usuario', 'User apps');
  String get appsRiskyCount =>
      _t('Con superficie riesgosa', 'With risky surface');
  String get appsHonestyNote => _t(
    'Un puntaje alto no prueba malicia: mide la superficie de permisos que la app SOLICITA. Android no permite ver el consumo de otras apps.',
    'A high score does not prove malice: it measures the permission surface the app REQUESTS. Android does not allow reading other apps\' resource usage.',
  );
  String get appsUnsupported => _t(
    'iOS no permite listar las apps instaladas. No es un fallo de RootCause: es diseño del sistema operativo.',
    'iOS does not allow listing installed apps. This is not a RootCause limitation: it is OS design.',
  );
  String appRiskScore(int score) => _t('riesgo $score', 'risk $score');
  String appUsage(String time) => _t('Uso 24 h: $time', '24 h use: $time');
  String get appsUsageGrant => _t(
    'Ver tiempo en pantalla (permiso opcional)',
    'See screen time (optional permission)',
  );
  String get appsUsageNote => _t(
    'Con el acceso de uso (lo concedes tú en Ajustes del sistema) cada app muestra su tiempo en pantalla de las últimas 24 h y la lista se ordena por uso — la respuesta directa a "¿qué app me está gastando el teléfono?".',
    'With usage access (you grant it in system Settings) each app shows its screen time over the last 24 h and the list sorts by usage — the direct answer to "which app is draining my phone?".',
  );
  String appPerms(String perms) =>
      _t('Permisos peligrosos: $perms', 'Dangerous permissions: $perms');
  String appFlags(String flags) => _t('Flags: $flags', 'Flags: $flags');

  // Dispositivo
  String get deviceTitle => _t('Dispositivo', 'Device');
  String get deviceManufacturer => _t('Fabricante', 'Manufacturer');
  String get deviceModel => _t('Modelo', 'Model');
  String get deviceOs => _t('Sistema operativo', 'Operating system');
  String get deviceSkin => _t('Capa del fabricante', 'Vendor skin');
  String get devicePatch => _t('Parche de seguridad', 'Security patch');
  String get deviceCores => _t('Núcleos de CPU', 'CPU cores');
  String get deviceUptime => _t('Tiempo encendido', 'Uptime');
  String get rootTitle =>
      _t('Indicadores de root/jailbreak', 'Root/jailbreak indicators');
  String get rootNone =>
      _t('Sin indicadores conocidos.', 'No known indicators.');
  String get rootNote => _t(
    'Un indicador es un indicio, no una prueba. Un equipo rooteado a propósito genera el mismo indicio.',
    'An indicator is a signal, not proof. A deliberately rooted device produces the same signal.',
  );

  // Historial
  String historyTitle(int count) =>
      _t('Últimas $count capturas', 'Last $count snapshots');
  String get historyEmpty => _t(
    'Aún no hay historial. Cada actualización guarda una captura local.',
    'No history yet. Every refresh stores a local snapshot.',
  );
  String historyRow(int mem, int storage, int risky) => _t(
    'RAM disp. $mem % · Disco libre $storage % · Apps riesgosas $risky',
    'RAM avail. $mem % · Free disk $storage % · Risky apps $risky',
  );

  // Acerca
  String get aboutVersion => _t('Versión', 'Version');
  String get aboutAuthor => _t('Autor', 'Author');
  String get aboutLicense => _t('Licencia', 'License');
  String get aboutPhilosophyTitle => _t('Filosofía', 'Philosophy');
  String get aboutPhilosophyBody => _t(
    'Cualquier distorsión anómala de los recursos del dispositivo puede ser el primer indicio de que algo está ocurriendo. RootCause vigila esas distorsiones, las correlaciona y explica la causa con evidencia. Diagnóstico primero, intervención después.',
    'Any anomalous distortion of device resources can be the first sign that something is happening. RootCause watches those distortions, correlates them and explains the cause with evidence. Diagnosis first, intervention second.',
  );
  String get aboutPrivacyTitle => _t('Privacidad local', 'Local privacy');
  String get aboutPrivacyBody => _t(
    'Esta app no usa internet: no declara el permiso INTERNET en release. El historial vive en el sandbox de la app y la evidencia solo sale del dispositivo si tú la exportas.',
    'This app does not use the internet: it does not declare the INTERNET permission in release. History lives in the app sandbox and evidence only leaves the device if you export it.',
  );
  String snapshotTaken(String when) =>
      _t('Captura tomada: $when', 'Snapshot taken: $when');

  // Acciones de intervención (abren la pantalla del sistema)
  String get actionFreeSpace => _t('Liberar espacio', 'Free up space');
  String get actionBatteryUsage => _t('Ver batería', 'View battery');
  String get actionAppDetails => _t('Ver en el sistema', 'View in system');
  String get actionSystemUpdate =>
      _t('Buscar actualizaciones', 'Check for updates');
  String get actionUnavailable => _t(
    'Esa pantalla del sistema no está disponible en este equipo.',
    'That system screen is not available on this device.',
  );

  // Configuración
  String get settingsCaptureTitle => _t('Captura', 'Capture');
  String get settingsInterval => _t(
    'Auto-captura con la app abierta',
    'Auto-capture while the app is open',
  );
  String get settingsIntervalOff => _t('Apagada', 'Off');
  String settingsIntervalMinutes(int m) => _t('Cada $m min', 'Every $m min');
  String get settingsBackground => _t(
    'Captura en segundo plano (mín. 15 min, lo impone Android)',
    'Background capture (min. 15 min, enforced by Android)',
  );
  String get settingsChargingOnly =>
      _t('Solo cuando está cargando', 'Only while charging');
  String get settingsNotifyCritical => _t(
    'Notificar si una captura en segundo plano pasa a Crítico',
    'Notify if a background capture turns Critical',
  );
  String get settingsBackgroundUnsupported =>
      _t('No disponible en este SO.', 'Not available on this OS.');
  String get settingsThresholdsTitle =>
      _t('Umbrales de detección', 'Detection thresholds');
  String get settingsThresholdsNote => _t(
    'Los cambios aplican al instante y quedan guardados. El export JSON registra siempre la evidencia cruda, no el umbral.',
    'Changes apply instantly and are saved. The JSON export always records raw evidence, not the threshold.',
  );
  String get thresholdMemWarning => _t(
    'Memoria: advertencia si disponible <',
    'Memory: warning if available <',
  );
  String get thresholdMemCritical =>
      _t('Memoria: crítico si disponible <', 'Memory: critical if available <');
  String get thresholdStorageWarning =>
      _t('Disco: advertencia si libre <', 'Storage: warning if free <');
  String get thresholdStorageCritical =>
      _t('Disco: crítico si libre <', 'Storage: critical if free <');
  String get thresholdBatteryWarning => _t(
    'Batería: advertencia si temperatura ≥',
    'Battery: warning if temperature ≥',
  );
  String get thresholdBatteryCritical => _t(
    'Batería: crítico si temperatura ≥',
    'Battery: critical if temperature ≥',
  );
  String get settingsRestoreDefaults =>
      _t('Restaurar valores por defecto', 'Restore defaults');
  String get settingsLanguageTitle => _t('Idioma', 'Language');

  // Cercanía (BLE)
  String get nearbyTitle => _t('Cercanía Bluetooth', 'Bluetooth nearby');
  String get nearbyIntro => _t(
    'Escaneo manual de dispositivos Bluetooth LE cercanos. 100 % local y bajo demanda: nada se guarda ni se exporta, y la app sigue sin usar internet.',
    'Manual scan of nearby Bluetooth LE devices. 100% local and on demand: nothing is stored or exported, and the app still uses no internet.',
  );
  String nearbyScan(int seconds) =>
      _t('Escanear ($seconds s)', 'Scan ($seconds s)');
  String get nearbyScanning => _t('Escaneando…', 'Scanning…');
  String get nearbyPermissionDenied => _t(
    'Sin permiso de Bluetooth no hay escaneo. Concédelo e inténtalo de nuevo.',
    'Without the Bluetooth permission there is no scan. Grant it and try again.',
  );
  String get nearbyUnsupported => _t(
    'El escaneo BLE no está disponible en este equipo (sin Bluetooth o SO sin soporte).',
    'BLE scanning is not available on this device (no Bluetooth or unsupported OS).',
  );
  String nearbySummary(int devices, int scans) => _t(
    '$devices dispositivo(s) vistos en $scans escaneo(s) de esta sesión',
    '$devices device(s) seen across $scans scan(s) this session',
  );
  String get nearbyPersistent => _t('PERSISTENTE', 'PERSISTENT');
  String nearbyPersistentNote(int count) => _t(
    '$count dispositivo(s) reaparecen a lo largo de la sesión. Un rastreador ajeno se comporta así — pero unos audífonos tuyos también: indicio, no prueba.',
    '$count device(s) keep reappearing across the session. A foreign tracker behaves like this — but so do your own earbuds: a signal, not proof.',
  );
  String get nearbyHonestyNote => _t(
    'Las direcciones BLE modernas rotan (MAC aleatorizada): un mismo aparato puede aparecer como varios. Los escaneos son solo de esta sesión.',
    'Modern BLE addresses rotate (randomized MAC): one device may appear as several. Scans belong to this session only.',
  );
  String nearbySeen(int scans) =>
      _t('visto en $scans escaneo(s)', 'seen in $scans scan(s)');

  // Alerta local de veredicto crítico
  String get alertCriticalTitle =>
      _t('RootCause: veredicto CRÍTICO', 'RootCause: CRITICAL verdict');
  String get alertCriticalBody => _t(
    'La última captura en segundo plano detectó una distorsión seria. Abre la app para ver la evidencia.',
    'The latest background snapshot detected a serious distortion. Open the app to see the evidence.',
  );

  // Historial: tendencia y comparación
  String get trendTitle =>
      _t('Tendencia de las últimas capturas', 'Trend across recent snapshots');
  String get trendMemLegend => _t('RAM disponible %', 'Available RAM %');
  String get trendStorageLegend => _t('Disco libre %', 'Free storage %');
  String get compareHint => _t(
    'Toca dos capturas para compararlas (A → B).',
    'Tap two snapshots to compare them (A → B).',
  );
  String get compareTitle => _t('Comparación A → B', 'Comparison A → B');
  String get compareClear => _t('Quitar selección', 'Clear selection');
  String get compareMem => _t('RAM disponible', 'Available RAM');
  String get compareStorage => _t('Disco libre', 'Free storage');
  String get compareScore => _t('Puntaje', 'Score');
  String get compareRisky => _t('Apps riesgosas', 'Risky apps');

  // Hallazgos (ids estables → texto localizado)
  String findingTitle(Finding f) => switch (f.id) {
    'mem-pressure' => _t('Presión de memoria', 'Memory pressure'),
    'storage-low' => _t('Almacenamiento bajo', 'Low storage'),
    'battery-temp' => _t(
      'Temperatura de batería anómala',
      'Anomalous battery temperature',
    ),
    'battery-health' => _t(
      'Salud de batería degradada',
      'Degraded battery health',
    ),
    'risky-apps' => _t(
      'Apps con superficie de permisos riesgosa',
      'Apps with risky permission surface',
    ),
    'root-indicators' => _t(
      'Indicadores de root/jailbreak',
      'Root/jailbreak indicators',
    ),
    'load-rising' => _t('Carga en ascenso sostenido', 'Sustained rising load'),
    'new-apps' => _t(
      'Apps nuevas desde la última captura',
      'New apps since last snapshot',
    ),
    'patch-old' => _t('Parche de seguridad antiguo', 'Outdated security patch'),
    _ => f.id,
  };

  String _metricName(String key) => switch (key) {
    'memory' => _t('memoria disponible', 'available memory'),
    'storage' => _t('disco libre', 'free storage'),
    _ => key,
  };

  String findingDetail(Finding f) {
    final a0 = f.args.isNotEmpty ? f.args[0] : '?';
    final a1 = f.args.length > 1 ? f.args[1] : '?';
    return switch (f.id) {
      'mem-pressure' => _t(
        'Solo queda $a0 % de memoria disponible.',
        'Only $a0 % of memory remains available.',
      ),
      'storage-low' => _t(
        'Solo queda $a0 % de almacenamiento libre.',
        'Only $a0 % of storage remains free.',
      ),
      'battery-temp' => _t(
        'La batería está a $a0 °C.',
        'Battery temperature is $a0 °C.',
      ),
      'battery-health' => _t(
        'El SO reporta la salud de batería como "$a0".',
        'The OS reports battery health as "$a0".',
      ),
      'risky-apps' => _t(
        '$a0 app(s) con puntaje de riesgo alto: $a1.',
        '$a0 app(s) with high risk score: $a1.',
      ),
      'root-indicators' => _t(
        '$a0 indicador(es): $a1.',
        '$a0 indicator(s): $a1.',
      ),
      'load-rising' => _t(
        'La ${_metricName(a0)} cayó de $a1 % a ${f.args.length > 2 ? f.args[2] : '?'} % de forma sostenida en las últimas capturas.',
        'The ${_metricName(a0)} fell steadily from $a1 % to ${f.args.length > 2 ? f.args[2] : '?'} % across recent snapshots.',
      ),
      'new-apps' => _t(
        '$a0 app(s) instaladas desde la captura anterior: $a1.${f.args.length > 2 && f.args[2] != '0' ? ' ${f.args[2]} con superficie riesgosa o sideload.' : ''}',
        '$a0 app(s) installed since the previous snapshot: $a1.${f.args.length > 2 && f.args[2] != '0' ? ' ${f.args[2]} with risky surface or sideload.' : ''}',
      ),
      'patch-old' => _t(
        'El último parche de seguridad ($a1) tiene $a0 días.',
        'The latest security patch ($a1) is $a0 days old.',
      ),
      _ => f.args.join(', '),
    };
  }

  String findingReco(Finding f) => switch (f.id) {
    'mem-pressure' => _t(
      'Cierra apps en segundo plano; si persiste tras reiniciar, revisa qué app la consume.',
      'Close background apps; if it persists after reboot, review which app consumes it.',
    ),
    'storage-low' => _t(
      'Libera espacio (fotos, descargas, cachés) antes de que el SO empiece a fallar.',
      'Free up space (photos, downloads, caches) before the OS starts failing.',
    ),
    'battery-temp' => _t(
      'Deja reposar el equipo; calor sostenido sin uso intensivo merece revisar apps activas.',
      'Let the device rest; sustained heat without heavy use warrants reviewing active apps.',
    ),
    'battery-health' => _t(
      'Considera diagnóstico de batería del fabricante.',
      'Consider the manufacturer\'s battery diagnostics.',
    ),
    'risky-apps' => _t(
      'Revisa cada app listada: ¿reconoces su origen? ¿necesita esos permisos?',
      'Review each listed app: do you recognize its origin? Does it need those permissions?',
    ),
    'root-indicators' => _t(
      'Si no rooteaste este equipo a propósito, investiga el origen del indicador.',
      'If you did not deliberately root this device, investigate the indicator\'s origin.',
    ),
    'load-rising' => _t(
      'Algo consume el recurso de forma continua. Compara las capturas del Historial y revisa qué cambió (app nueva, sincronización, proceso atascado).',
      'Something is steadily consuming the resource. Compare History snapshots and review what changed (new app, sync, stuck process).',
    ),
    'new-apps' => _t(
      '¿Reconoces estas instalaciones? Si alguna llegó sola o por sideload, revísala en la pestaña Apps y su ficha del sistema.',
      'Do you recognize these installs? If any arrived on its own or via sideload, review it in the Apps tab and its system page.',
    ),
    'patch-old' => _t(
      'Busca actualizaciones del sistema: un equipo sin parches acumula vulnerabilidades conocidas y públicas.',
      'Check for system updates: an unpatched device accumulates known, public vulnerabilities.',
    ),
    _ => '',
  };
}
