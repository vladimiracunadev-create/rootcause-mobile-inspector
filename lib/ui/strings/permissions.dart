/// Permisos peligrosos y senales especiales en lenguaje HUMANO.
///
/// Para una persona no tecnica esto es lo que convierte una constante de
/// Android (`RECORD_AUDIO`) en algo accionable. Es el bloque mas largo de
/// la app y el mas mecanico.
part of '../strings.dart';

extension AppStringsPermissions on AppStrings {
  String permissionLabel(String perm) => switch (perm) {
    'CAMERA' => _pick(
      'Cámara',
      'Camera',
      'Câmera',
      'Fotocamera',
      'Appareil photo',
    ),
    'RECORD_AUDIO' => _pick(
      'Micrófono (grabar audio)',
      'Microphone (record audio)',
      'Microfone (gravar áudio)',
      'Microfono (registrare audio)',
      'Microphone (enregistrer l’audio)',
    ),
    'ACCESS_FINE_LOCATION' => _pick(
      'Ubicación precisa (GPS)',
      'Precise location (GPS)',
      'Localização precisa (GPS)',
      'Posizione precisa (GPS)',
      'Localisation précise (GPS)',
    ),
    'ACCESS_COARSE_LOCATION' => _pick(
      'Ubicación aproximada',
      'Approximate location',
      'Localização aproximada',
      'Posizione approssimativa',
      'Localisation approximative',
    ),
    'ACCESS_BACKGROUND_LOCATION' => _pick(
      'Ubicación en segundo plano (te sigue con la app cerrada)',
      'Background location (tracks you with the app closed)',
      'Localização em segundo plano (segue você com o app fechado)',
      'Posizione in background (ti segue con l’app chiusa)',
      'Localisation en arrière-plan (vous suit app fermée)',
    ),
    'READ_CONTACTS' => _pick(
      'Leer tus contactos',
      'Read your contacts',
      'Ler seus contatos',
      'Leggere i tuoi contatti',
      'Lire vos contacts',
    ),
    'WRITE_CONTACTS' => _pick(
      'Modificar tus contactos',
      'Modify your contacts',
      'Modificar seus contatos',
      'Modificare i tuoi contatti',
      'Modifier vos contacts',
    ),
    'GET_ACCOUNTS' => _pick(
      'Ver las cuentas del teléfono',
      'See the phone\'s accounts',
      'Ver as contas do telefone',
      'Vedere gli account del telefono',
      'Voir les comptes du téléphone',
    ),
    'READ_SMS' => _pick(
      'Leer tus SMS',
      'Read your text messages',
      'Ler seus SMS',
      'Leggere i tuoi SMS',
      'Lire vos SMS',
    ),
    'SEND_SMS' => _pick(
      'Enviar SMS (puede costar dinero)',
      'Send text messages (may cost money)',
      'Enviar SMS (pode custar dinheiro)',
      'Inviare SMS (può costare denaro)',
      'Envoyer des SMS (peut coûter de l’argent)',
    ),
    'RECEIVE_SMS' => _pick(
      'Recibir/interceptar SMS',
      'Receive/intercept text messages',
      'Receber/interceptar SMS',
      'Ricevere/intercettare SMS',
      'Recevoir/intercepter des SMS',
    ),
    'RECEIVE_MMS' => _pick(
      'Recibir mensajes MMS',
      'Receive MMS messages',
      'Receber mensagens MMS',
      'Ricevere messaggi MMS',
      'Recevoir des MMS',
    ),
    'READ_CALL_LOG' => _pick(
      'Leer tu historial de llamadas',
      'Read your call history',
      'Ler seu histórico de chamadas',
      'Leggere il registro chiamate',
      'Lire votre journal d’appels',
    ),
    'WRITE_CALL_LOG' => _pick(
      'Modificar tu historial de llamadas',
      'Modify your call history',
      'Modificar seu histórico de chamadas',
      'Modificare il registro chiamate',
      'Modifier votre journal d’appels',
    ),
    'READ_PHONE_STATE' => _pick(
      'Ver el estado y datos del teléfono',
      'See phone status and identity',
      'Ver o estado e a identidade do telefone',
      'Vedere stato e identità del telefono',
      'Voir l’état et l’identité du téléphone',
    ),
    'READ_PHONE_NUMBERS' => _pick(
      'Leer tu número de teléfono',
      'Read your phone number',
      'Ler seu número de telefone',
      'Leggere il tuo numero di telefono',
      'Lire votre numéro de téléphone',
    ),
    'CALL_PHONE' => _pick(
      'Llamar por teléfono sin preguntarte',
      'Place phone calls without asking',
      'Fazer chamadas sem perguntar',
      'Effettuare chiamate senza chiedere',
      'Passer des appels sans demander',
    ),
    'ANSWER_PHONE_CALLS' => _pick(
      'Contestar llamadas',
      'Answer phone calls',
      'Atender chamadas',
      'Rispondere alle chiamate',
      'Répondre aux appels',
    ),
    'PROCESS_OUTGOING_CALLS' => _pick(
      'Ver y desviar llamadas salientes',
      'See and reroute outgoing calls',
      'Ver e redirecionar chamadas efetuadas',
      'Vedere e deviare le chiamate in uscita',
      'Voir et rediriger les appels sortants',
    ),
    'READ_EXTERNAL_STORAGE' => _pick(
      'Leer tus archivos y fotos',
      'Read your files and photos',
      'Ler seus arquivos e fotos',
      'Leggere i tuoi file e foto',
      'Lire vos fichiers et photos',
    ),
    'WRITE_EXTERNAL_STORAGE' => _pick(
      'Modificar tus archivos',
      'Modify your files',
      'Modificar seus arquivos',
      'Modificare i tuoi file',
      'Modifier vos fichiers',
    ),
    'MANAGE_EXTERNAL_STORAGE' => _pick(
      'Acceso total a todos tus archivos',
      'Full access to all your files',
      'Acesso total a todos os seus arquivos',
      'Accesso completo a tutti i tuoi file',
      'Accès total à tous vos fichiers',
    ),
    'READ_MEDIA_IMAGES' => _pick(
      'Ver tus fotos',
      'View your photos',
      'Ver suas fotos',
      'Vedere le tue foto',
      'Voir vos photos',
    ),
    'READ_MEDIA_VIDEO' => _pick(
      'Ver tus videos',
      'View your videos',
      'Ver seus vídeos',
      'Vedere i tuoi video',
      'Voir vos vidéos',
    ),
    'READ_MEDIA_AUDIO' => _pick(
      'Ver tu música y audio',
      'View your music and audio',
      'Ver sua música e áudio',
      'Vedere la tua musica e audio',
      'Voir votre musique et audio',
    ),
    'BODY_SENSORS' => _pick(
      'Sensores corporales (ritmo cardíaco)',
      'Body sensors (heart rate)',
      'Sensores corporais (ritmo cardíaco)',
      'Sensori corporei (battito cardiaco)',
      'Capteurs corporels (rythme cardiaque)',
    ),
    'ACTIVITY_RECOGNITION' => _pick(
      'Detectar tu actividad física (pasos, movimiento)',
      'Detect your physical activity (steps, movement)',
      'Detectar sua atividade física (passos, movimento)',
      'Rilevare la tua attività fisica (passi, movimento)',
      'Détecter votre activité physique (pas, mouvement)',
    ),
    'READ_CALENDAR' => _pick(
      'Leer tu calendario',
      'Read your calendar',
      'Ler sua agenda',
      'Leggere il tuo calendario',
      'Lire votre agenda',
    ),
    'WRITE_CALENDAR' => _pick(
      'Modificar tu calendario',
      'Modify your calendar',
      'Modificar sua agenda',
      'Modificare il tuo calendario',
      'Modifier votre agenda',
    ),
    'BLUETOOTH_CONNECT' => _pick(
      'Conectarse a dispositivos Bluetooth',
      'Connect to Bluetooth devices',
      'Conectar a dispositivos Bluetooth',
      'Connettersi a dispositivi Bluetooth',
      'Se connecter aux appareils Bluetooth',
    ),
    'BLUETOOTH_SCAN' => _pick(
      'Buscar dispositivos Bluetooth cercanos',
      'Scan for nearby Bluetooth devices',
      'Buscar dispositivos Bluetooth próximos',
      'Cercare dispositivi Bluetooth vicini',
      'Rechercher les appareils Bluetooth proches',
    ),
    'NEARBY_WIFI_DEVICES' => _pick(
      'Detectar dispositivos Wi-Fi cercanos',
      'Detect nearby Wi-Fi devices',
      'Detectar dispositivos Wi-Fi próximos',
      'Rilevare dispositivi Wi-Fi vicini',
      'Détecter les appareils Wi-Fi proches',
    ),
    'POST_NOTIFICATIONS' => _pick(
      'Mostrar notificaciones',
      'Show notifications',
      'Mostrar notificações',
      'Mostrare notifiche',
      'Afficher des notifications',
    ),
    _ => _humanizeConstant(perm),
  };

  /// Descripción humana de una "señal especial" (flag) de la app.
  String flagLabel(String flag) => switch (flag) {
    'overlay' => _pick(
      'Puede dibujar sobre otras apps',
      'Can draw over other apps',
      'Pode desenhar sobre outros apps',
      'Può disegnare sopra altre app',
      'Peut dessiner par-dessus les autres apps',
    ),
    'installs-packages' => _pick(
      'Puede instalar otras apps',
      'Can install other apps',
      'Pode instalar outros apps',
      'Può installare altre app',
      'Peut installer d’autres apps',
    ),
    'device-admin' => _pick(
      'Administrador del dispositivo',
      'Device administrator',
      'Administrador do dispositivo',
      'Amministratore del dispositivo',
      'Administrateur de l’appareil',
    ),
    'accessibility-service' => _pick(
      '⚠ Accesibilidad ACTIVA: puede leer tu pantalla y tocar por ti',
      '⚠ Accessibility ACTIVE: can read your screen and tap for you',
      '⚠ Acessibilidade ATIVA: pode ler sua tela e tocar por você',
      '⚠ Accessibilità ATTIVA: può leggere lo schermo e toccare per te',
      '⚠ Accessibilité ACTIVE : peut lire votre écran et toucher à votre place',
    ),
    'notification-listener' => _pick(
      '⚠ Lee TODAS tus notificaciones (activo)',
      '⚠ Reads ALL your notifications (active)',
      '⚠ Lê TODAS as suas notificações (ativo)',
      '⚠ Legge TUTTE le tue notifiche (attivo)',
      '⚠ Lit TOUTES vos notifications (actif)',
    ),
    'device-admin-active' => _pick(
      '⚠ Administrador del dispositivo ACTIVO: control elevado',
      '⚠ Device administrator ACTIVE: elevated control',
      '⚠ Administrador do dispositivo ATIVO: controle elevado',
      '⚠ Amministratore del dispositivo ATTIVO: controllo elevato',
      '⚠ Administrateur de l’appareil ACTIF : contrôle élevé',
    ),
    'sideloaded' => _pick(
      'Instalada fuera de la tienda oficial',
      'Installed outside the official store',
      'Instalada fora da loja oficial',
      'Installata fuori dallo store ufficiale',
      'Installée hors du magasin officiel',
    ),
    _ => _humanizeConstant(flag),
  };

  /// Último recurso: convierte `READ_SOME_THING` o `some-flag` en algo más
  /// legible ("Read some thing") sin inventar una traducción falsa.
  String _humanizeConstant(String raw) {
    final words = raw
        .replaceAll('.', ' ')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return raw;
    final first = words.first;
    final capitalized = first.isEmpty
        ? first
        : '${first[0].toUpperCase()}${first.substring(1)}';
    return [capitalized, ...words.skip(1)].join(' ');
  }
}
