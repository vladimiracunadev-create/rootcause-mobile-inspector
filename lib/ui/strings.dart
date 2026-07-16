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
  String get tabHistory => _t('Historial', 'History');
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
  String appPerms(String perms) =>
      _t('Permisos peligrosos: $perms', 'Dangerous permissions: $perms');
  String appFlags(String flags) => _t('Flags: $flags', 'Flags: $flags');

  // Dispositivo
  String get deviceTitle => _t('Dispositivo', 'Device');
  String get deviceManufacturer => _t('Fabricante', 'Manufacturer');
  String get deviceModel => _t('Modelo', 'Model');
  String get deviceOs => _t('Sistema operativo', 'Operating system');
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
    _ => f.id,
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
    _ => '',
  };
}
