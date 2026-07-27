/// Textos multilingües ES/EN/PT/IT/FR — Dart puro, sin framework de
/// localización.
///
/// Deliberadamente simple: cinco idiomas, una clase, getters testeables.
/// Los ids de hallazgo y las constantes de permiso se traducen aquí; el
/// export JSON nunca se traduce.
library;

import '../core/models.dart';

/// Idiomas soportados por la UI. El orden es el de aparición en el selector.
enum AppLang { es, en, pt, it, fr }

/// Resuelve el idioma efectivo a partir del código guardado en la config y
/// del idioma del equipo. `code` vacío (o desconocido) = "automático": se usa
/// el idioma del dispositivo; si tampoco se reconoce, se cae a inglés.
AppLang resolveLanguage(String code, {required String deviceLanguageCode}) {
  AppLang? fromCode(String c) => switch (c.toLowerCase()) {
    'es' => AppLang.es,
    'en' => AppLang.en,
    'pt' => AppLang.pt,
    'it' => AppLang.it,
    'fr' => AppLang.fr,
    _ => null,
  };
  return fromCode(code) ?? fromCode(deviceLanguageCode) ?? AppLang.en;
}

/// Nombre nativo de cada idioma, para el selector (no se traduce: cada uno
/// se muestra en su propia lengua).
String languageNativeName(AppLang lang) => switch (lang) {
  AppLang.es => 'Español',
  AppLang.en => 'English',
  AppLang.pt => 'Português',
  AppLang.it => 'Italiano',
  AppLang.fr => 'Français',
};

/// Código ISO 639-1 de cada idioma; el que se guarda en la config.
String languageCodeOf(AppLang lang) => switch (lang) {
  AppLang.es => 'es',
  AppLang.en => 'en',
  AppLang.pt => 'pt',
  AppLang.it => 'it',
  AppLang.fr => 'fr',
};

class AppStrings {
  const AppStrings(this.lang);

  final AppLang lang;

  /// Compatibilidad puntual: algún sitio aún razona en "¿es español?".
  bool get spanish => lang == AppLang.es;

  String _pick(String es, String en, String pt, String it, String fr) =>
      switch (lang) {
        AppLang.es => es,
        AppLang.en => en,
        AppLang.pt => pt,
        AppLang.it => it,
        AppLang.fr => fr,
      };

  // Tabs
  String get tabSummary =>
      _pick('Resumen', 'Summary', 'Resumo', 'Riepilogo', 'Résumé');
  String get tabApps => _pick('Apps', 'Apps', 'Apps', 'App', 'Apps');
  String get tabFlagged =>
      _pick('Señaladas', 'Flagged', 'Sinalizadas', 'Segnalate', 'Signalées');
  String get tabNetwork => _pick('Red', 'Network', 'Rede', 'Rete', 'Réseau');
  String get tabStorage => _pick(
    'Almacenamiento',
    'Storage',
    'Armazenamento',
    'Archiviazione',
    'Stockage',
  );
  String get tabDevice =>
      _pick('Dispositivo', 'Device', 'Dispositivo', 'Dispositivo', 'Appareil');
  String get tabNearby =>
      _pick('Cercanía', 'Nearby', 'Proximidade', 'Vicinanze', 'À proximité');
  String get tabHistory =>
      _pick('Historial', 'History', 'Histórico', 'Cronologia', 'Historique');
  String get tabSettings => _pick(
    'Configuración',
    'Settings',
    'Configurações',
    'Impostazioni',
    'Réglages',
  );
  String get tabAbout => _pick('Acerca', 'About', 'Sobre', 'Info', 'À propos');

  // Acciones
  String get actionLanguage =>
      _pick('Idioma', 'Language', 'Idioma', 'Lingua', 'Langue');
  String get actionRefresh => _pick(
    'Actualizar captura',
    'Refresh snapshot',
    'Atualizar captura',
    'Aggiorna acquisizione',
    'Actualiser la capture',
  );
  String get actionExport => _pick(
    'Exportar JSON forense',
    'Export forensic JSON',
    'Exportar JSON forense',
    'Esporta JSON forense',
    'Exporter le JSON forensique',
  );
  String get loading => _pick(
    'Capturando estado del dispositivo…',
    'Capturing device state…',
    'Capturando o estado do dispositivo…',
    'Acquisizione dello stato del dispositivo…',
    'Capture de l’état de l’appareil…',
  );
  String exportOk(String path) => _pick(
    'Evidencia copiada al portapapeles y guardada en $path',
    'Evidence copied to clipboard and saved to $path',
    'Evidência copiada para a área de transferência e salva em $path',
    'Prova copiata negli appunti e salvata in $path',
    'Preuve copiée dans le presse-papiers et enregistrée dans $path',
  );
  String get exportFail => _pick(
    'No se pudo exportar la evidencia',
    'Could not export evidence',
    'Não foi possível exportar a evidência',
    'Impossibile esportare la prova',
    'Impossible d’exporter la preuve',
  );

  // Veredicto
  String get verdictNormal => _pick(
    'Sistema estable — sin distorsiones',
    'System stable — no distortions',
    'Sistema estável — sem distorções',
    'Sistema stabile — nessuna distorsione',
    'Système stable — aucune distorsion',
  );
  String get verdictWarning => _pick(
    'Advertencia — hay indicios que revisar',
    'Warning — signals to review',
    'Aviso — há indícios a revisar',
    'Avviso — segnali da verificare',
    'Avertissement — des signaux à examiner',
  );
  String get verdictCritical => _pick(
    'Crítico — distorsión seria en curso',
    'Critical — serious distortion',
    'Crítico — distorção séria em curso',
    'Critico — distorsione grave in corso',
    'Critique — distorsion grave en cours',
  );
  String verdictScore(int score) => _pick(
    'Puntaje: $score',
    'Score: $score',
    'Pontuação: $score',
    'Punteggio: $score',
    'Score : $score',
  );
  String get findingsNone => _pick(
    'Sin hallazgos: el dispositivo se ve estable.',
    'No findings: the device looks stable.',
    'Sem achados: o dispositivo parece estável.',
    'Nessun rilievo: il dispositivo appare stabile.',
    'Aucune constatation : l’appareil semble stable.',
  );
  String get severityNormal =>
      _pick('Normal', 'Normal', 'Normal', 'Normale', 'Normal');
  String get severityWarning =>
      _pick('Advertencia', 'Warning', 'Aviso', 'Avviso', 'Avertissement');
  String get severityCritical =>
      _pick('Crítico', 'Critical', 'Crítico', 'Critico', 'Critique');
  String recommendation(String text) => _pick(
    'Recomendación: $text',
    'Recommendation: $text',
    'Recomendação: $text',
    'Raccomandazione: $text',
    'Recommandation : $text',
  );

  // Memoria / almacenamiento / batería
  String get memTitle =>
      _pick('Memoria', 'Memory', 'Memória', 'Memoria', 'Mémoire');
  String get memUsed => _pick('Usada', 'Used', 'Usada', 'Usata', 'Utilisée');
  String get memAvailable => _pick(
    'Disponible',
    'Available',
    'Disponível',
    'Disponibile',
    'Disponible',
  );
  String get memTotal => _pick('Total', 'Total', 'Total', 'Totale', 'Total');
  String get storageTitle => _pick(
    'Almacenamiento',
    'Storage',
    'Armazenamento',
    'Archiviazione',
    'Stockage',
  );
  String get storageFree => _pick('Libre', 'Free', 'Livre', 'Libero', 'Libre');
  String get storageUsed => _pick('Usado', 'Used', 'Usado', 'Usato', 'Utilisé');
  String get storageTotal =>
      _pick('Total', 'Total', 'Total', 'Totale', 'Total');
  String get cacheTitle => _pick(
    'Caché de esta app',
    'This app\'s cache',
    'Cache deste app',
    'Cache di questa app',
    'Cache de cette app',
  );
  String get cacheSize =>
      _pick('Tamaño', 'Size', 'Tamanho', 'Dimensione', 'Taille');
  String get cacheNote => _pick(
    'Android e iOS no permiten leer la caché de otras apps; esta cifra es la caché propia de RootCause.',
    'Android and iOS do not allow reading other apps\' caches; this figure is RootCause\'s own cache.',
    'Android e iOS não permitem ler o cache de outros apps; este valor é o cache do próprio RootCause.',
    'Android e iOS non permettono di leggere la cache di altre app; questo valore è la cache di RootCause.',
    'Android et iOS n’autorisent pas la lecture du cache des autres apps ; ce chiffre est le cache propre de RootCause.',
  );
  String get cacheClear => _pick(
    'Limpiar caché propia',
    'Clear own cache',
    'Limpar cache próprio',
    'Svuota la cache',
    'Vider le cache propre',
  );
  String cacheCleared(String freed) => _pick(
    'Caché propia liberada: $freed',
    'Own cache cleared: $freed',
    'Cache próprio liberado: $freed',
    'Cache liberata: $freed',
    'Cache propre libéré : $freed',
  );
  String get volumeInternal => _pick(
    'Interno (datos)',
    'Internal (data)',
    'Interno (dados)',
    'Interno (dati)',
    'Interne (données)',
  );
  String get volumeRemovable =>
      _pick('extraíble', 'removable', 'removível', 'rimovibile', 'amovible');
  String get volumesNone => _pick(
    'Sin volúmenes adicionales: este equipo no tiene tarjeta SD ni USB conectado (o el SO no los expone). No es un fallo — se muestran solo cuando existen.',
    'No additional volumes: this device has no SD card or USB attached (or the OS does not expose them). Not a failure — they are listed only when present.',
    'Sem volumes adicionais: este aparelho não tem cartão SD nem USB conectado (ou o SO não os expõe). Não é falha — só aparecem quando existem.',
    'Nessun volume aggiuntivo: questo dispositivo non ha scheda SD né USB collegata (o il SO non li espone). Non è un errore — compaiono solo quando presenti.',
    'Aucun volume supplémentaire : cet appareil n’a ni carte SD ni USB connecté (ou l’OS ne les expose pas). Ce n’est pas une panne — ils n’apparaissent que s’ils existent.',
  );
  String get batteryTitle =>
      _pick('Batería', 'Battery', 'Bateria', 'Batteria', 'Batterie');
  String get batteryLevel =>
      _pick('Nivel', 'Level', 'Nível', 'Livello', 'Niveau');
  String get batteryState =>
      _pick('Estado', 'State', 'Estado', 'Stato', 'État');
  String get batteryCharging =>
      _pick('Cargando', 'Charging', 'Carregando', 'In carica', 'En charge');
  String get batteryDischarging => _pick(
    'Descargando',
    'Discharging',
    'Descarregando',
    'In scarica',
    'En décharge',
  );
  String get batteryTemp => _pick(
    'Temperatura',
    'Temperature',
    'Temperatura',
    'Temperatura',
    'Température',
  );
  String get batteryHealth =>
      _pick('Salud', 'Health', 'Saúde', 'Salute', 'Santé');
  String get notAvailableOnPlatform => _pick(
    'No disponible en este SO',
    'Not available on this OS',
    'Indisponível neste SO',
    'Non disponibile su questo SO',
    'Indisponible sur cet OS',
  );

  // Red
  String get networkTitle => _pick(
    'Estado de red',
    'Network state',
    'Estado da rede',
    'Stato della rete',
    'État du réseau',
  );
  String get netConnected =>
      _pick('Conectado', 'Connected', 'Conectado', 'Connesso', 'Connecté');
  String get netTransport =>
      _pick('Transporte', 'Transport', 'Transporte', 'Trasporto', 'Transport');
  String get netVpn => _pick(
    'VPN activa',
    'VPN active',
    'VPN ativa',
    'VPN attiva',
    'VPN active',
  );
  String get netMetered => _pick(
    'Red medida',
    'Metered network',
    'Rede limitada',
    'Rete a consumo',
    'Réseau facturé',
  );
  String get netDown => _pick(
    'Bajada estimada',
    'Estimated downlink',
    'Download estimado',
    'Download stimato',
    'Débit descendant estimé',
  );
  String get netUp => _pick(
    'Subida estimada',
    'Estimated uplink',
    'Upload estimado',
    'Upload stimato',
    'Débit montant estimé',
  );
  String get netTrafficTitle => _pick(
    'Tráfico acumulado (desde el arranque)',
    'Accumulated traffic (since boot)',
    'Tráfego acumulado (desde a inicialização)',
    'Traffico accumulato (dall’avvio)',
    'Trafic cumulé (depuis le démarrage)',
  );
  String get netRx =>
      _pick('Recibido', 'Received', 'Recebido', 'Ricevuto', 'Reçu');
  String get netTx => _pick('Enviado', 'Sent', 'Enviado', 'Inviato', 'Envoyé');
  String get netTrafficNote => _pick(
    'Contadores globales del SO. RootCause no inspecciona el contenido de tu tráfico.',
    'OS-wide counters. RootCause does not inspect your traffic contents.',
    'Contadores globais do SO. O RootCause não inspeciona o conteúdo do seu tráfego.',
    'Contatori globali del SO. RootCause non ispeziona il contenuto del tuo traffico.',
    'Compteurs globaux de l’OS. RootCause n’inspecte pas le contenu de votre trafic.',
  );
  String get yes => _pick('Sí', 'Yes', 'Sim', 'Sì', 'Oui');
  String get no => _pick('No', 'No', 'Não', 'No', 'Non');

  // Apps
  String get appsTitle => _pick(
    'Auditoría de apps',
    'App audit',
    'Auditoria de apps',
    'Controllo delle app',
    'Audit des apps',
  );
  String get appsTotal => _pick(
    'Apps de usuario',
    'User apps',
    'Apps do usuário',
    'App utente',
    'Apps utilisateur',
  );
  String get appsRiskyCount => _pick(
    'Con superficie riesgosa',
    'With risky surface',
    'Com superfície arriscada',
    'Con superficie a rischio',
    'À surface risquée',
  );
  String get appsHonestyNote => _pick(
    'Un puntaje alto no prueba malicia: mide la superficie de permisos que la app SOLICITA. Android no permite ver el consumo de otras apps.',
    'A high score does not prove malice: it measures the permission surface the app REQUESTS. Android does not allow reading other apps\' resource usage.',
    'Uma pontuação alta não prova malícia: mede a superfície de permissões que o app SOLICITA. O Android não permite ver o consumo de outros apps.',
    'Un punteggio alto non prova malizia: misura la superficie di permessi che l’app RICHIEDE. Android non permette di vedere il consumo di altre app.',
    'Un score élevé ne prouve pas la malveillance : il mesure la surface de permissions que l’app DEMANDE. Android n’autorise pas à voir la consommation des autres apps.',
  );
  String get appsUnsupported => _pick(
    'iOS no permite listar las apps instaladas. No es un fallo de RootCause: es diseño del sistema operativo.',
    'iOS does not allow listing installed apps. This is not a RootCause limitation: it is OS design.',
    'O iOS não permite listar os apps instalados. Não é falha do RootCause: é design do sistema operacional.',
    'iOS non permette di elencare le app installate. Non è un limite di RootCause: è il design del sistema operativo.',
    'iOS n’autorise pas la liste des apps installées. Ce n’est pas une limite de RootCause : c’est la conception du système.',
  );
  String appRiskScore(int score) => _pick(
    'riesgo $score',
    'risk $score',
    'risco $score',
    'rischio $score',
    'risque $score',
  );
  String appUsage(String time) => _pick(
    'Uso 24 h: $time',
    '24 h use: $time',
    'Uso 24 h: $time',
    'Uso 24 h: $time',
    'Utilisation 24 h : $time',
  );
  String get appsUsageGrant => _pick(
    'Ver tiempo en pantalla (permiso opcional)',
    'See screen time (optional permission)',
    'Ver tempo de tela (permissão opcional)',
    'Vedi il tempo di utilizzo (permesso opzionale)',
    'Voir le temps d’écran (permission facultative)',
  );
  String get appsUsageNote => _pick(
    'Con el acceso de uso (lo concedes tú en Ajustes del sistema) cada app muestra su tiempo en pantalla de las últimas 24 h y la lista se ordena por uso — la respuesta directa a "¿qué app me está gastando el teléfono?".',
    'With usage access (you grant it in system Settings) each app shows its screen time over the last 24 h and the list sorts by usage — the direct answer to "which app is draining my phone?".',
    'Com o acesso de uso (você concede nas Configurações do sistema) cada app mostra o tempo de tela das últimas 24 h e a lista é ordenada por uso — a resposta direta a "qual app está gastando meu telefone?".',
    'Con l’accesso all’utilizzo (lo concedi tu nelle Impostazioni di sistema) ogni app mostra il tempo di utilizzo delle ultime 24 h e la lista è ordinata per uso — la risposta diretta a "quale app mi sta consumando il telefono?".',
    'Avec l’accès à l’usage (que vous accordez dans les Réglages système) chaque app affiche son temps d’écran des dernières 24 h et la liste est triée par usage — la réponse directe à « quelle app épuise mon téléphone ? ».',
  );
  String appPerms(String perms) => _pick(
    'Permisos peligrosos: $perms',
    'Dangerous permissions: $perms',
    'Permissões perigosas: $perms',
    'Permessi pericolosi: $perms',
    'Permissions dangereuses : $perms',
  );
  String get appPermsTitle => _pick(
    'Permisos que pide esta app',
    'Permissions this app asks for',
    'Permissões que este app pede',
    'Permessi richiesti da questa app',
    'Permissions demandées par cette app',
  );
  String appFlags(String flags) => _pick(
    'Señales: $flags',
    'Flags: $flags',
    'Sinais: $flags',
    'Segnali: $flags',
    'Signaux : $flags',
  );

  // Pestaña "Señaladas" (apps riesgosas)
  String get flaggedTitle => _pick(
    'Apps señaladas',
    'Flagged apps',
    'Apps sinalizados',
    'App segnalate',
    'Apps signalées',
  );
  String flaggedCount(int count) => _pick(
    '$count app(s) con superficie riesgosa o instaladas fuera de la tienda',
    '$count app(s) with a risky surface or installed outside the store',
    '$count app(s) com superfície arriscada ou instalados fora da loja',
    '$count app con superficie a rischio o installate fuori dallo store',
    '$count app(s) à surface risquée ou installées hors du magasin',
  );
  String get flaggedEmpty => _pick(
    'No hay apps señaladas: ninguna app de usuario pide una superficie de permisos riesgosa ni llegó por sideload. Buena señal.',
    'No flagged apps: no user app requests a risky permission surface or arrived via sideload. Good sign.',
    'Nenhum app sinalizado: nenhum app de usuário pede uma superfície de permissões arriscada nem veio por sideload. Bom sinal.',
    'Nessuna app segnalata: nessuna app utente richiede una superficie di permessi a rischio né è arrivata via sideload. Buon segno.',
    'Aucune app signalée : aucune app utilisateur ne demande une surface de permissions risquée ni n’est arrivée par sideload. Bon signe.',
  );
  String get flaggedNote => _pick(
    'Señalada no significa maliciosa: significa que pide más de lo habitual o no vino de la tienda oficial. Revísala tú y decide.',
    'Flagged does not mean malicious: it means it asks for more than usual or did not come from the official store. Review it yourself and decide.',
    'Sinalizado não significa malicioso: significa que pede mais do que o normal ou não veio da loja oficial. Revise você mesmo e decida.',
    'Segnalata non significa dannosa: significa che chiede più del solito o non proviene dallo store ufficiale. Controllala tu e decidi.',
    'Signalée ne veut pas dire malveillante : elle demande plus que d’habitude ou ne vient pas du magasin officiel. À vous de vérifier et de décider.',
  );

  // Dispositivo
  String get deviceTitle =>
      _pick('Dispositivo', 'Device', 'Dispositivo', 'Dispositivo', 'Appareil');
  String get deviceManufacturer => _pick(
    'Fabricante',
    'Manufacturer',
    'Fabricante',
    'Produttore',
    'Fabricant',
  );
  String get deviceModel =>
      _pick('Modelo', 'Model', 'Modelo', 'Modello', 'Modèle');
  String get deviceOs => _pick(
    'Sistema operativo',
    'Operating system',
    'Sistema operacional',
    'Sistema operativo',
    'Système d’exploitation',
  );
  String get deviceSkin => _pick(
    'Capa del fabricante',
    'Vendor skin',
    'Camada do fabricante',
    'Interfaccia del produttore',
    'Surcouche du fabricant',
  );
  String get devicePatch => _pick(
    'Parche de seguridad',
    'Security patch',
    'Patch de segurança',
    'Patch di sicurezza',
    'Correctif de sécurité',
  );
  String get deviceCores => _pick(
    'Núcleos de CPU',
    'CPU cores',
    'Núcleos de CPU',
    'Core della CPU',
    'Cœurs du CPU',
  );
  String get deviceUptime => _pick(
    'Tiempo encendido',
    'Uptime',
    'Tempo ligado',
    'Tempo di accensione',
    'Temps allumé',
  );
  String get rootTitle => _pick(
    'Indicadores de root/jailbreak',
    'Root/jailbreak indicators',
    'Indicadores de root/jailbreak',
    'Indicatori di root/jailbreak',
    'Indicateurs de root/jailbreak',
  );
  String get rootNone => _pick(
    'Sin indicadores conocidos.',
    'No known indicators.',
    'Sem indicadores conhecidos.',
    'Nessun indicatore noto.',
    'Aucun indicateur connu.',
  );
  String get rootNote => _pick(
    'Un indicador es un indicio, no una prueba. Un equipo rooteado a propósito genera el mismo indicio.',
    'An indicator is a signal, not proof. A deliberately rooted device produces the same signal.',
    'Um indicador é um indício, não uma prova. Um aparelho rooteado de propósito gera o mesmo indício.',
    'Un indicatore è un indizio, non una prova. Un dispositivo rootato di proposito produce lo stesso indizio.',
    'Un indicateur est un indice, pas une preuve. Un appareil rooté volontairement produit le même indice.',
  );

  // Historial
  String historyTitle(int count) => _pick(
    'Últimas $count capturas',
    'Last $count snapshots',
    'Últimas $count capturas',
    'Ultime $count acquisizioni',
    '$count dernières captures',
  );
  String get historyEmpty => _pick(
    'Aún no hay historial. Cada actualización guarda una captura local.',
    'No history yet. Every refresh stores a local snapshot.',
    'Ainda não há histórico. Cada atualização salva uma captura local.',
    'Ancora nessuna cronologia. Ogni aggiornamento salva un’acquisizione locale.',
    'Pas encore d’historique. Chaque actualisation enregistre une capture locale.',
  );
  String historyRow(int mem, int storage, int risky) => _pick(
    'RAM disp. $mem % · Disco libre $storage % · Apps riesgosas $risky',
    'RAM avail. $mem % · Free disk $storage % · Risky apps $risky',
    'RAM disp. $mem % · Disco livre $storage % · Apps arriscados $risky',
    'RAM disp. $mem % · Disco libero $storage % · App a rischio $risky',
    'RAM dispo. $mem % · Disque libre $storage % · Apps risquées $risky',
  );

  // Acerca
  String get aboutVersion =>
      _pick('Versión', 'Version', 'Versão', 'Versione', 'Version');
  String get aboutAuthor =>
      _pick('Autor', 'Author', 'Autor', 'Autore', 'Auteur');
  String get aboutLicense =>
      _pick('Licencia', 'License', 'Licença', 'Licenza', 'Licence');
  String get aboutPhilosophyTitle =>
      _pick('Filosofía', 'Philosophy', 'Filosofia', 'Filosofia', 'Philosophie');
  String get aboutPhilosophyBody => _pick(
    'Cualquier distorsión anómala de los recursos del dispositivo puede ser el primer indicio de que algo está ocurriendo. RootCause vigila esas distorsiones, las correlaciona y explica la causa con evidencia. Diagnóstico primero, intervención después.',
    'Any anomalous distortion of device resources can be the first sign that something is happening. RootCause watches those distortions, correlates them and explains the cause with evidence. Diagnosis first, intervention second.',
    'Qualquer distorção anômala dos recursos do dispositivo pode ser o primeiro indício de que algo está acontecendo. O RootCause vigia essas distorções, correlaciona-as e explica a causa com evidência. Diagnóstico primeiro, intervenção depois.',
    'Qualsiasi distorsione anomala delle risorse del dispositivo può essere il primo indizio che qualcosa sta accadendo. RootCause sorveglia queste distorsioni, le correla e spiega la causa con prove. Prima la diagnosi, poi l’intervento.',
    'Toute distorsion anormale des ressources de l’appareil peut être le premier signe que quelque chose se passe. RootCause surveille ces distorsions, les corrèle et explique la cause avec des preuves. Le diagnostic d’abord, l’intervention ensuite.',
  );
  String get aboutPrivacyTitle => _pick(
    'Privacidad local',
    'Local privacy',
    'Privacidade local',
    'Privacy locale',
    'Confidentialité locale',
  );
  String get aboutPrivacyBody => _pick(
    'Esta app no usa internet: no declara el permiso INTERNET en release. El historial vive en el sandbox de la app y la evidencia solo sale del dispositivo si tú la exportas.',
    'This app does not use the internet: it does not declare the INTERNET permission in release. History lives in the app sandbox and evidence only leaves the device if you export it.',
    'Este app não usa a internet: não declara a permissão INTERNET em release. O histórico vive no sandbox do app e a evidência só sai do dispositivo se você a exportar.',
    'Questa app non usa internet: non dichiara il permesso INTERNET in release. La cronologia vive nella sandbox dell’app e la prova esce dal dispositivo solo se la esporti tu.',
    'Cette app n’utilise pas internet : elle ne déclare pas la permission INTERNET en release. L’historique réside dans le sandbox de l’app et la preuve ne quitte l’appareil que si vous l’exportez.',
  );
  String snapshotTaken(String when) => _pick(
    'Captura tomada: $when',
    'Snapshot taken: $when',
    'Captura feita: $when',
    'Acquisizione effettuata: $when',
    'Capture prise : $when',
  );

  // Acciones de intervención (abren la pantalla del sistema)
  String get actionFreeSpace => _pick(
    'Liberar espacio',
    'Free up space',
    'Liberar espaço',
    'Libera spazio',
    'Libérer de l’espace',
  );
  String get actionBatteryUsage => _pick(
    'Ver batería',
    'View battery',
    'Ver bateria',
    'Vedi batteria',
    'Voir la batterie',
  );
  String get actionAppDetails => _pick(
    'Ver en el sistema',
    'View in system',
    'Ver no sistema',
    'Apri nel sistema',
    'Voir dans le système',
  );
  String get actionSystemUpdate => _pick(
    'Buscar actualizaciones',
    'Check for updates',
    'Buscar atualizações',
    'Cerca aggiornamenti',
    'Rechercher des mises à jour',
  );
  String get actionUnavailable => _pick(
    'Esa pantalla del sistema no está disponible en este equipo.',
    'That system screen is not available on this device.',
    'Essa tela do sistema não está disponível neste aparelho.',
    'Quella schermata di sistema non è disponibile su questo dispositivo.',
    'Cet écran système n’est pas disponible sur cet appareil.',
  );

  // Configuración
  String get settingsCaptureTitle =>
      _pick('Captura', 'Capture', 'Captura', 'Acquisizione', 'Capture');
  String get settingsInterval => _pick(
    'Auto-captura con la app abierta',
    'Auto-capture while the app is open',
    'Autocaptura com o app aberto',
    'Acquisizione automatica con l’app aperta',
    'Capture auto quand l’app est ouverte',
  );
  String get settingsIntervalOff =>
      _pick('Apagada', 'Off', 'Desligada', 'Spenta', 'Désactivée');
  String settingsIntervalMinutes(int m) => _pick(
    'Cada $m min',
    'Every $m min',
    'A cada $m min',
    'Ogni $m min',
    'Toutes les $m min',
  );
  String get settingsBackground => _pick(
    'Captura en segundo plano (mín. 15 min, lo impone Android)',
    'Background capture (min. 15 min, enforced by Android)',
    'Captura em segundo plano (mín. 15 min, imposto pelo Android)',
    'Acquisizione in background (min. 15 min, imposto da Android)',
    'Capture en arrière-plan (min. 15 min, imposé par Android)',
  );
  String get settingsChargingOnly => _pick(
    'Solo cuando está cargando',
    'Only while charging',
    'Somente ao carregar',
    'Solo durante la carica',
    'Uniquement en charge',
  );
  String get settingsNotifyCritical => _pick(
    'Notificar si una captura en segundo plano pasa a Crítico',
    'Notify if a background capture turns Critical',
    'Notificar se uma captura em segundo plano ficar Crítica',
    'Notifica se un’acquisizione in background diventa Critica',
    'Notifier si une capture en arrière-plan devient Critique',
  );
  String get settingsBackgroundUnsupported => _pick(
    'No disponible en este SO.',
    'Not available on this OS.',
    'Indisponível neste SO.',
    'Non disponibile su questo SO.',
    'Indisponible sur cet OS.',
  );
  String get settingsThresholdsTitle => _pick(
    'Umbrales de detección',
    'Detection thresholds',
    'Limiares de detecção',
    'Soglie di rilevamento',
    'Seuils de détection',
  );
  String get settingsThresholdsNote => _pick(
    'Los cambios aplican al instante y quedan guardados. El export JSON registra siempre la evidencia cruda, no el umbral.',
    'Changes apply instantly and are saved. The JSON export always records raw evidence, not the threshold.',
    'As mudanças aplicam-se na hora e ficam salvas. O export JSON registra sempre a evidência crua, não o limiar.',
    'Le modifiche si applicano subito e restano salvate. L’export JSON registra sempre la prova grezza, non la soglia.',
    'Les changements s’appliquent aussitôt et sont enregistrés. L’export JSON consigne toujours la preuve brute, pas le seuil.',
  );
  String get thresholdMemWarning => _pick(
    'Memoria: advertencia si disponible <',
    'Memory: warning if available <',
    'Memória: aviso se disponível <',
    'Memoria: avviso se disponibile <',
    'Mémoire : avertissement si disponible <',
  );
  String get thresholdMemCritical => _pick(
    'Memoria: crítico si disponible <',
    'Memory: critical if available <',
    'Memória: crítico se disponível <',
    'Memoria: critico se disponibile <',
    'Mémoire : critique si disponible <',
  );
  String get thresholdStorageWarning => _pick(
    'Disco: advertencia si libre <',
    'Storage: warning if free <',
    'Disco: aviso se livre <',
    'Disco: avviso se libero <',
    'Disque : avertissement si libre <',
  );
  String get thresholdStorageCritical => _pick(
    'Disco: crítico si libre <',
    'Storage: critical if free <',
    'Disco: crítico se livre <',
    'Disco: critico se libero <',
    'Disque : critique si libre <',
  );
  String get thresholdBatteryWarning => _pick(
    'Batería: advertencia si temperatura ≥',
    'Battery: warning if temperature ≥',
    'Bateria: aviso se temperatura ≥',
    'Batteria: avviso se temperatura ≥',
    'Batterie : avertissement si température ≥',
  );
  String get thresholdBatteryCritical => _pick(
    'Batería: crítico si temperatura ≥',
    'Battery: critical if temperature ≥',
    'Bateria: crítico se temperatura ≥',
    'Batteria: critico se temperatura ≥',
    'Batterie : critique si température ≥',
  );
  String get settingsRestoreDefaults => _pick(
    'Restaurar valores por defecto',
    'Restore defaults',
    'Restaurar padrões',
    'Ripristina valori predefiniti',
    'Restaurer les valeurs par défaut',
  );
  String get settingsLanguageTitle =>
      _pick('Idioma', 'Language', 'Idioma', 'Lingua', 'Langue');
  String get settingsLanguageAuto => _pick(
    'Automático (sistema)',
    'Automatic (system)',
    'Automático (sistema)',
    'Automatico (sistema)',
    'Automatique (système)',
  );
  String get settingsNearbyHistory => _pick(
    'Histórico de Cercanía entre sesiones (detecta rastreadores multi-día)',
    'Cross-session Nearby history (detects multi-day trackers)',
    'Histórico de Proximidade entre sessões (detecta rastreadores multi-dias)',
    'Cronologia Vicinanze tra sessioni (rileva tracker multi-giorno)',
    'Historique de proximité entre sessions (détecte les traceurs multi-jours)',
  );

  // Evidencia (backup / restaurar / borrar / informe)
  String get evidenceTitle =>
      _pick('Evidencia', 'Evidence', 'Evidência', 'Prove', 'Preuves');
  String get evidenceNote => _pick(
    'Tu evidencia es tuya: respáldala para que sobreviva a desinstalar o cambiar de teléfono, o bórrala cuando quieras. Nada sale del dispositivo salvo que tú lo compartas.',
    'Your evidence is yours: back it up so it survives uninstalling or switching phones, or wipe it whenever you want. Nothing leaves the device unless you share it.',
    'Sua evidência é sua: faça backup para que sobreviva à desinstalação ou à troca de telefone, ou apague quando quiser. Nada sai do dispositivo a menos que você compartilhe.',
    'Le tue prove sono tue: fai il backup così sopravvivono alla disinstallazione o al cambio di telefono, oppure cancellale quando vuoi. Nulla esce dal dispositivo se non lo condividi tu.',
    'Vos preuves sont à vous : sauvegardez-les pour qu’elles survivent à une désinstallation ou à un changement de téléphone, ou effacez-les quand vous voulez. Rien ne quitte l’appareil sauf si vous le partagez.',
  );
  String get evidenceBackup => _pick(
    'Exportar backup',
    'Export backup',
    'Exportar backup',
    'Esporta backup',
    'Exporter la sauvegarde',
  );
  String get evidenceRestore => _pick(
    'Restaurar backup',
    'Restore backup',
    'Restaurar backup',
    'Ripristina backup',
    'Restaurer la sauvegarde',
  );
  String get evidenceWipe => _pick(
    'Borrar evidencia',
    'Wipe evidence',
    'Apagar evidência',
    'Cancella prove',
    'Effacer les preuves',
  );
  String get evidenceReport => _pick(
    'Generar informe forense',
    'Generate forensic report',
    'Gerar relatório forense',
    'Genera rapporto forense',
    'Générer le rapport forensique',
  );
  String backupDone(String path) => _pick(
    'Backup guardado en $path',
    'Backup saved to $path',
    'Backup salvo em $path',
    'Backup salvato in $path',
    'Sauvegarde enregistrée dans $path',
  );
  String get restoreOk => _pick(
    'Backup restaurado. Actualizando…',
    'Backup restored. Refreshing…',
    'Backup restaurado. Atualizando…',
    'Backup ripristinato. Aggiornamento…',
    'Sauvegarde restaurée. Actualisation…',
  );
  String get restoreFail => _pick(
    'El archivo no es un backup válido de RootCause.',
    'The file is not a valid RootCause backup.',
    'O arquivo não é um backup válido do RootCause.',
    'Il file non è un backup valido di RootCause.',
    'Le fichier n’est pas une sauvegarde RootCause valide.',
  );
  String get wipeConfirmTitle => _pick(
    '¿Borrar toda la evidencia?',
    'Wipe all evidence?',
    'Apagar toda a evidência?',
    'Cancellare tutte le prove?',
    'Effacer toutes les preuves ?',
  );
  String get wipeConfirmBody => _pick(
    'Se eliminarán historial, baseline, cercanía y exports de este dispositivo. La configuración se conserva. No se puede deshacer.',
    'History, baseline, nearby and exports will be deleted from this device. Settings are kept. This cannot be undone.',
    'Serão excluídos histórico, baseline, proximidade e exports deste dispositivo. As configurações são mantidas. Não pode ser desfeito.',
    'Verranno eliminati cronologia, baseline, vicinanze ed export da questo dispositivo. Le impostazioni vengono mantenute. Non è reversibile.',
    'L’historique, la baseline, la proximité et les exports seront supprimés de cet appareil. Les réglages sont conservés. Irréversible.',
  );
  String get wipeDone => _pick(
    'Evidencia borrada.',
    'Evidence wiped.',
    'Evidência apagada.',
    'Prove cancellate.',
    'Preuves effacées.',
  );
  String get cancel =>
      _pick('Cancelar', 'Cancel', 'Cancelar', 'Annulla', 'Annuler');
  String get confirm =>
      _pick('Borrar', 'Wipe', 'Apagar', 'Cancella', 'Effacer');
  String get reportShareTitle => _pick(
    'Informe forense RootCause',
    'RootCause forensic report',
    'Relatório forense RootCause',
    'Rapporto forense RootCause',
    'Rapport forensique RootCause',
  );
  String get shareFailed => _pick(
    'No se pudo compartir en este equipo.',
    'Could not share on this device.',
    'Não foi possível compartilhar neste aparelho.',
    'Impossibile condividere su questo dispositivo.',
    'Impossible de partager sur cet appareil.',
  );

  // Diagnóstico (registro de errores)
  String get diagTitle => _pick(
    'Diagnóstico',
    'Diagnostics',
    'Diagnóstico',
    'Diagnostica',
    'Diagnostic',
  );
  String get diagNone => _pick(
    'Sin errores registrados.',
    'No errors recorded.',
    'Nenhum erro registrado.',
    'Nessun errore registrato.',
    'Aucune erreur enregistrée.',
  );
  String get diagShare => _pick(
    'Compartir registro',
    'Share log',
    'Compartilhar registro',
    'Condividi registro',
    'Partager le journal',
  );
  String get diagClear => _pick(
    'Borrar registro',
    'Clear log',
    'Apagar registro',
    'Cancella registro',
    'Effacer le journal',
  );
  String get diagNote => _pick(
    'Si la app falla, el error queda aquí (local, nunca se envía). Compártelo para reportar el problema.',
    'If the app fails, the error stays here (local, never sent). Share it to report the problem.',
    'Se o app falhar, o erro fica aqui (local, nunca enviado). Compartilhe para relatar o problema.',
    'Se l’app va in errore, l’errore resta qui (locale, mai inviato). Condividilo per segnalare il problema.',
    'Si l’app échoue, l’erreur reste ici (locale, jamais envoyée). Partagez-la pour signaler le problème.',
  );

  // Onboarding
  String get onboardTitle1 => _pick(
    'Diagnóstico primero',
    'Diagnosis first',
    'Diagnóstico primeiro',
    'Prima la diagnosi',
    'Le diagnostic d’abord',
  );
  String get onboardBody1 => _pick(
    'RootCause vigila memoria, almacenamiento, batería, red y apps de tu teléfono, y explica con evidencia si algo se comporta distinto.',
    'RootCause watches your phone\'s memory, storage, battery, network and apps, and explains with evidence when something behaves differently.',
    'O RootCause vigia memória, armazenamento, bateria, rede e apps do seu telefone, e explica com evidência se algo se comporta diferente.',
    'RootCause sorveglia memoria, archiviazione, batteria, rete e app del tuo telefono e spiega con prove se qualcosa si comporta in modo diverso.',
    'RootCause surveille la mémoire, le stockage, la batterie, le réseau et les apps de votre téléphone, et explique avec des preuves si quelque chose se comporte différemment.',
  );
  String get onboardTitle2 => _pick(
    'Lo que NO hace',
    'What it does NOT do',
    'O que NÃO faz',
    'Cosa NON fa',
    'Ce qu’il NE fait PAS',
  );
  String get onboardBody2 => _pick(
    'No es antivirus ni "limpiador": no elimina malware ni mata apps (Android no lo permite). Te muestra indicios y te lleva a la pantalla del sistema donde tú decides.',
    'It is not an antivirus or "cleaner": it does not remove malware or kill apps (Android forbids it). It shows you signals and takes you to the system screen where you decide.',
    'Não é antivírus nem "limpador": não remove malware nem mata apps (o Android não permite). Mostra indícios e leva você à tela do sistema onde você decide.',
    'Non è un antivirus né un "pulitore": non rimuove malware né chiude app (Android lo vieta). Ti mostra indizi e ti porta alla schermata di sistema dove decidi tu.',
    'Ce n’est pas un antivirus ni un « nettoyeur » : il ne supprime pas les malwares et ne ferme pas les apps (Android l’interdit). Il vous montre des indices et vous mène à l’écran système où vous décidez.',
  );
  String get onboardTitle3 => _pick(
    'Todo local',
    'All local',
    'Tudo local',
    'Tutto locale',
    'Tout en local',
  );
  String get onboardBody3 => _pick(
    'Sin internet, sin cuentas, sin telemetría: la app ni siquiera declara el permiso de red. Tu evidencia solo sale si tú la compartes.',
    'No internet, no accounts, no telemetry: the app does not even declare the network permission. Your evidence only leaves if you share it.',
    'Sem internet, sem contas, sem telemetria: o app nem declara a permissão de rede. Sua evidência só sai se você compartilhar.',
    'Niente internet, niente account, niente telemetria: l’app non dichiara nemmeno il permesso di rete. La tua prova esce solo se la condividi tu.',
    'Pas d’internet, pas de comptes, pas de télémétrie : l’app ne déclare même pas la permission réseau. Vos preuves ne sortent que si vous les partagez.',
  );
  String get onboardNext =>
      _pick('Siguiente', 'Next', 'Próximo', 'Avanti', 'Suivant');
  String get onboardStart =>
      _pick('Empezar', 'Get started', 'Começar', 'Inizia', 'Commencer');

  // Cercanía (BLE)
  String get nearbyTitle => _pick(
    'Cercanía Bluetooth',
    'Bluetooth nearby',
    'Proximidade Bluetooth',
    'Vicinanze Bluetooth',
    'Bluetooth à proximité',
  );
  String get nearbyIntro => _pick(
    'Escaneo manual de dispositivos Bluetooth LE cercanos. 100 % local y bajo demanda: nada se guarda ni se exporta, y la app sigue sin usar internet.',
    'Manual scan of nearby Bluetooth LE devices. 100% local and on demand: nothing is stored or exported, and the app still uses no internet.',
    'Varredura manual de dispositivos Bluetooth LE próximos. 100 % local e sob demanda: nada é salvo nem exportado, e o app continua sem usar internet.',
    'Scansione manuale dei dispositivi Bluetooth LE vicini. 100 % locale e su richiesta: nulla viene salvato o esportato e l’app continua a non usare internet.',
    'Balayage manuel des appareils Bluetooth LE proches. 100 % local et à la demande : rien n’est stocké ni exporté, et l’app n’utilise toujours pas internet.',
  );
  String nearbyScan(int seconds) => _pick(
    'Escanear ($seconds s)',
    'Scan ($seconds s)',
    'Escanear ($seconds s)',
    'Scansiona ($seconds s)',
    'Balayer ($seconds s)',
  );
  String get nearbyScanning => _pick(
    'Escaneando…',
    'Scanning…',
    'Escaneando…',
    'Scansione…',
    'Balayage…',
  );
  String get nearbyPermissionDenied => _pick(
    'Sin permiso de Bluetooth no hay escaneo. Concédelo e inténtalo de nuevo.',
    'Without the Bluetooth permission there is no scan. Grant it and try again.',
    'Sem permissão de Bluetooth não há varredura. Conceda e tente novamente.',
    'Senza il permesso Bluetooth non c’è scansione. Concedilo e riprova.',
    'Sans la permission Bluetooth, pas de balayage. Accordez-la et réessayez.',
  );
  String get nearbyUnsupported => _pick(
    'El escaneo BLE no está disponible en este equipo (sin Bluetooth o SO sin soporte).',
    'BLE scanning is not available on this device (no Bluetooth or unsupported OS).',
    'A varredura BLE não está disponível neste aparelho (sem Bluetooth ou SO sem suporte).',
    'La scansione BLE non è disponibile su questo dispositivo (senza Bluetooth o SO non supportato).',
    'Le balayage BLE n’est pas disponible sur cet appareil (pas de Bluetooth ou OS non pris en charge).',
  );
  String nearbySummary(int devices, int scans) => _pick(
    '$devices dispositivo(s) vistos en $scans escaneo(s) de esta sesión',
    '$devices device(s) seen across $scans scan(s) this session',
    '$devices dispositivo(s) vistos em $scans varredura(s) desta sessão',
    '$devices dispositivo/i visti in $scans scansione/i di questa sessione',
    '$devices appareil(s) vus sur $scans balayage(s) de cette session',
  );
  String get nearbyPersistent => _pick(
    'PERSISTENTE',
    'PERSISTENT',
    'PERSISTENTE',
    'PERSISTENTE',
    'PERSISTANT',
  );
  String nearbyPersistentNote(int count) => _pick(
    '$count dispositivo(s) reaparecen a lo largo de la sesión. Un rastreador ajeno se comporta así — pero unos audífonos tuyos también: indicio, no prueba.',
    '$count device(s) keep reappearing across the session. A foreign tracker behaves like this — but so do your own earbuds: a signal, not proof.',
    '$count dispositivo(s) reaparecem ao longo da sessão. Um rastreador alheio se comporta assim — mas seus fones também: indício, não prova.',
    '$count dispositivo/i riappaiono nel corso della sessione. Un tracker estraneo si comporta così — ma anche i tuoi auricolari: indizio, non prova.',
    '$count appareil(s) réapparaissent au fil de la session. Un traceur étranger se comporte ainsi — mais vos écouteurs aussi : indice, pas preuve.',
  );
  String get nearbyHonestyNote => _pick(
    'Las direcciones BLE modernas rotan (MAC aleatorizada): un mismo aparato puede aparecer como varios. Los escaneos son solo de esta sesión.',
    'Modern BLE addresses rotate (randomized MAC): one device may appear as several. Scans belong to this session only.',
    'Os endereços BLE modernos rotacionam (MAC aleatório): um mesmo aparelho pode aparecer como vários. As varreduras são só desta sessão.',
    'Gli indirizzi BLE moderni ruotano (MAC casuale): uno stesso dispositivo può apparire come più. Le scansioni valgono solo per questa sessione.',
    'Les adresses BLE modernes tournent (MAC aléatoire) : un même appareil peut apparaître comme plusieurs. Les balayages ne valent que pour cette session.',
  );
  String nearbySeen(int scans) => _pick(
    'visto en $scans escaneo(s)',
    'seen in $scans scan(s)',
    'visto em $scans varredura(s)',
    'visto in $scans scansione/i',
    'vu sur $scans balayage(s)',
  );

  // Alerta local de veredicto crítico
  String get alertCriticalTitle => _pick(
    'RootCause: veredicto CRÍTICO',
    'RootCause: CRITICAL verdict',
    'RootCause: veredito CRÍTICO',
    'RootCause: verdetto CRITICO',
    'RootCause : verdict CRITIQUE',
  );
  String get alertCriticalBody => _pick(
    'La última captura en segundo plano detectó una distorsión seria. Abre la app para ver la evidencia.',
    'The latest background snapshot detected a serious distortion. Open the app to see the evidence.',
    'A última captura em segundo plano detectou uma distorção séria. Abra o app para ver a evidência.',
    'L’ultima acquisizione in background ha rilevato una distorsione grave. Apri l’app per vedere la prova.',
    'La dernière capture en arrière-plan a détecté une distorsion grave. Ouvrez l’app pour voir la preuve.',
  );
  String get alertNewAppTitle => _pick(
    'RootCause: app nueva con superficie riesgosa',
    'RootCause: new app with risky surface',
    'RootCause: novo app com superfície arriscada',
    'RootCause: nuova app con superficie a rischio',
    'RootCause : nouvelle app à surface risquée',
  );
  String alertNewAppBody(String names) => _pick(
    'Se instaló $names con permisos peligrosos o por sideload mientras RootCause vigilaba. Revísala en la pestaña Apps.',
    '$names was installed with dangerous permissions or via sideload while RootCause was watching. Review it in the Apps tab.',
    '$names foi instalado com permissões perigosas ou por sideload enquanto o RootCause vigiava. Revise na aba Apps.',
    '$names è stata installata con permessi pericolosi o via sideload mentre RootCause sorvegliava. Controllala nella scheda App.',
    '$names a été installée avec des permissions dangereuses ou par sideload pendant que RootCause surveillait. Vérifiez-la dans l’onglet Apps.',
  );

  // Historial: tendencia y comparación
  String get trendTitle => _pick(
    'Tendencia de las últimas capturas',
    'Trend across recent snapshots',
    'Tendência das últimas capturas',
    'Andamento delle ultime acquisizioni',
    'Tendance des dernières captures',
  );
  String get trendMemLegend => _pick(
    'RAM disponible %',
    'Available RAM %',
    'RAM disponível %',
    'RAM disponibile %',
    'RAM disponible %',
  );
  String get trendStorageLegend => _pick(
    'Disco libre %',
    'Free storage %',
    'Disco livre %',
    'Disco libero %',
    'Disque libre %',
  );
  String get trendTempLegend => _pick(
    'Temp. batería (0–60 °C)',
    'Battery temp (0–60 °C)',
    'Temp. bateria (0–60 °C)',
    'Temp. batteria (0–60 °C)',
    'Temp. batterie (0–60 °C)',
  );
  String get compareHint => _pick(
    'Toca dos capturas para compararlas (A → B).',
    'Tap two snapshots to compare them (A → B).',
    'Toque em duas capturas para compará-las (A → B).',
    'Tocca due acquisizioni per confrontarle (A → B).',
    'Touchez deux captures pour les comparer (A → B).',
  );
  String get compareTitle => _pick(
    'Comparación A → B',
    'Comparison A → B',
    'Comparação A → B',
    'Confronto A → B',
    'Comparaison A → B',
  );
  String get compareClear => _pick(
    'Quitar selección',
    'Clear selection',
    'Limpar seleção',
    'Rimuovi selezione',
    'Effacer la sélection',
  );
  String get compareMem => _pick(
    'RAM disponible',
    'Available RAM',
    'RAM disponível',
    'RAM disponibile',
    'RAM disponible',
  );
  String get compareStorage => _pick(
    'Disco libre',
    'Free storage',
    'Disco livre',
    'Disco libero',
    'Disque libre',
  );
  String get compareScore =>
      _pick('Puntaje', 'Score', 'Pontuação', 'Punteggio', 'Score');
  String get compareRisky => _pick(
    'Apps riesgosas',
    'Risky apps',
    'Apps arriscados',
    'App a rischio',
    'Apps risquées',
  );

  // Informe (PDF) — títulos y frases propias del informe forense
  String get reportTitle => _pick(
    'Informe forense',
    'Forensic report',
    'Relatório forense',
    'Rapporto forense',
    'Rapport forensique',
  );
  String get reportGenerated =>
      _pick('Generado', 'Generated', 'Gerado', 'Generato', 'Généré');
  String get reportDevice =>
      _pick('Equipo', 'Device', 'Aparelho', 'Dispositivo', 'Appareil');
  String get reportVerdict =>
      _pick('Veredicto', 'Verdict', 'Veredito', 'Verdetto', 'Verdict');
  String get reportFindings =>
      _pick('Hallazgos', 'Findings', 'Achados', 'Rilievi', 'Constatations');
  String get reportMetrics =>
      _pick('Métricas', 'Metrics', 'Métricas', 'Metriche', 'Métriques');
  String reportAvailableOf(String total) => _pick(
    'disponibles de $total',
    'available of $total',
    'disponíveis de $total',
    'disponibili di $total',
    'disponibles sur $total',
  );
  String reportFreeOf(String total) => _pick(
    'libres de $total',
    'free of $total',
    'livres de $total',
    'liberi di $total',
    'libres sur $total',
  );
  String reportAppsLine(int total, int risky) => _pick(
    '$total apps de usuario, $risky con superficie riesgosa',
    '$total user apps, $risky with risky surface',
    '$total apps do usuário, $risky com superfície arriscada',
    '$total app utente, $risky con superficie a rischio',
    '$total apps utilisateur, $risky à surface risquée',
  );
  String get reportColSnapshot =>
      _pick('Captura', 'Snapshot', 'Captura', 'Acquisizione', 'Capture');
  String get reportColStorage =>
      _pick('Disco', 'Storage', 'Disco', 'Disco', 'Disque');
  String get reportColScore =>
      _pick('Puntaje', 'Score', 'Pontuação', 'Punteggio', 'Score');
  String get reportIntegrityTitle => _pick(
    'Integridad de la evidencia',
    'Evidence integrity',
    'Integridade da evidência',
    'Integrità delle prove',
    'Intégrité des preuves',
  );
  String reportChainOk(int sealed, int total) => _pick(
    'Cadena de hashes VERIFICADA: $sealed de $total capturas selladas (SHA-256 encadenado).',
    'Hash chain VERIFIED: $sealed of $total snapshots sealed (chained SHA-256).',
    'Cadeia de hashes VERIFICADA: $sealed de $total capturas seladas (SHA-256 encadeado).',
    'Catena di hash VERIFICATA: $sealed di $total acquisizioni sigillate (SHA-256 concatenato).',
    'Chaîne de hachages VÉRIFIÉE : $sealed sur $total captures scellées (SHA-256 chaîné).',
  );
  String get reportChainTampered => _pick(
    'ATENCIÓN: la cadena de hashes NO verifica — el historial pudo ser alterado.',
    'WARNING: the hash chain does NOT verify — the history may have been tampered with.',
    'ATENÇÃO: a cadeia de hashes NÃO verifica — o histórico pode ter sido alterado.',
    'ATTENZIONE: la catena di hash NON verifica — la cronologia potrebbe essere stata alterata.',
    'ATTENTION : la chaîne de hachages NE se vérifie PAS — l’historique a pu être altéré.',
  );
  String get reportFooter => _pick(
    'Generado localmente por RootCause Mobile Inspector (sin permiso INTERNET: nada salió del dispositivo hasta que su dueño compartió este archivo).',
    'Generated locally by RootCause Mobile Inspector (no INTERNET permission: nothing left the device until its owner shared this file).',
    'Gerado localmente pelo RootCause Mobile Inspector (sem permissão INTERNET: nada saiu do dispositivo até o dono compartilhar este arquivo).',
    'Generato localmente da RootCause Mobile Inspector (senza permesso INTERNET: nulla è uscito dal dispositivo finché il proprietario non ha condiviso questo file).',
    'Généré localement par RootCause Mobile Inspector (sans permission INTERNET : rien n’a quitté l’appareil jusqu’à ce que son propriétaire partage ce fichier).',
  );

  // Hallazgos (ids estables → texto localizado)
  String findingTitle(Finding f) => switch (f.id) {
    'mem-pressure' => _pick(
      'Presión de memoria',
      'Memory pressure',
      'Pressão de memória',
      'Pressione di memoria',
      'Pression mémoire',
    ),
    'storage-low' => _pick(
      'Almacenamiento bajo',
      'Low storage',
      'Armazenamento baixo',
      'Archiviazione scarsa',
      'Stockage faible',
    ),
    'battery-temp' => _pick(
      'Temperatura de batería anómala',
      'Anomalous battery temperature',
      'Temperatura de bateria anômala',
      'Temperatura della batteria anomala',
      'Température de batterie anormale',
    ),
    'battery-health' => _pick(
      'Salud de batería degradada',
      'Degraded battery health',
      'Saúde da bateria degradada',
      'Salute della batteria degradata',
      'Santé de batterie dégradée',
    ),
    'risky-apps' => _pick(
      'Apps con superficie de permisos riesgosa',
      'Apps with risky permission surface',
      'Apps com superfície de permissões arriscada',
      'App con superficie di permessi a rischio',
      'Apps à surface de permissions risquée',
    ),
    'root-indicators' => _pick(
      'Indicadores de root/jailbreak',
      'Root/jailbreak indicators',
      'Indicadores de root/jailbreak',
      'Indicatori di root/jailbreak',
      'Indicateurs de root/jailbreak',
    ),
    'load-rising' => _pick(
      'Carga en ascenso sostenido',
      'Sustained rising load',
      'Carga em ascensão sustentada',
      'Carico in aumento sostenuto',
      'Charge en hausse soutenue',
    ),
    'new-apps' => _pick(
      'Apps nuevas desde la última captura',
      'New apps since last snapshot',
      'Apps novos desde a última captura',
      'Nuove app dall’ultima acquisizione',
      'Nouvelles apps depuis la dernière capture',
    ),
    'patch-old' => _pick(
      'Parche de seguridad antiguo',
      'Outdated security patch',
      'Patch de segurança antigo',
      'Patch di sicurezza obsoleta',
      'Correctif de sécurité ancien',
    ),
    _ => f.id,
  };

  String _metricName(String key) => switch (key) {
    'memory' => _pick(
      'memoria disponible',
      'available memory',
      'memória disponível',
      'memoria disponibile',
      'mémoire disponible',
    ),
    'storage' => _pick(
      'disco libre',
      'free storage',
      'disco livre',
      'disco libero',
      'disque libre',
    ),
    _ => key,
  };

  String findingDetail(Finding f) {
    final a0 = f.args.isNotEmpty ? f.args[0] : '?';
    final a1 = f.args.length > 1 ? f.args[1] : '?';
    return switch (f.id) {
      'mem-pressure' => _pick(
        'Solo queda $a0 % de memoria disponible.',
        'Only $a0 % of memory remains available.',
        'Resta apenas $a0 % de memória disponível.',
        'Resta solo il $a0 % di memoria disponibile.',
        'Il ne reste que $a0 % de mémoire disponible.',
      ),
      'storage-low' => _pick(
        'Solo queda $a0 % de almacenamiento libre.',
        'Only $a0 % of storage remains free.',
        'Resta apenas $a0 % de armazenamento livre.',
        'Resta solo il $a0 % di archiviazione libera.',
        'Il ne reste que $a0 % de stockage libre.',
      ),
      'battery-temp' => _pick(
        'La batería está a $a0 °C.',
        'Battery temperature is $a0 °C.',
        'A bateria está a $a0 °C.',
        'La batteria è a $a0 °C.',
        'La batterie est à $a0 °C.',
      ),
      'battery-health' => _pick(
        'El SO reporta la salud de batería como "$a0".',
        'The OS reports battery health as "$a0".',
        'O SO reporta a saúde da bateria como "$a0".',
        'Il SO segnala la salute della batteria come "$a0".',
        'L’OS indique la santé de la batterie comme « $a0 ».',
      ),
      'risky-apps' => _pick(
        '$a0 app(s) con puntaje de riesgo alto: $a1.',
        '$a0 app(s) with high risk score: $a1.',
        '$a0 app(s) com pontuação de risco alta: $a1.',
        '$a0 app con punteggio di rischio alto: $a1.',
        '$a0 app(s) à score de risque élevé : $a1.',
      ),
      'root-indicators' => _pick(
        '$a0 indicador(es): $a1.',
        '$a0 indicator(s): $a1.',
        '$a0 indicador(es): $a1.',
        '$a0 indicatore/i: $a1.',
        '$a0 indicateur(s) : $a1.',
      ),
      'load-rising' => _pick(
        'La ${_metricName(a0)} cayó de $a1 % a ${f.args.length > 2 ? f.args[2] : '?'} % de forma sostenida en las últimas capturas.',
        'The ${_metricName(a0)} fell steadily from $a1 % to ${f.args.length > 2 ? f.args[2] : '?'} % across recent snapshots.',
        'A ${_metricName(a0)} caiu de $a1 % para ${f.args.length > 2 ? f.args[2] : '?'} % de forma sustentada nas últimas capturas.',
        'La ${_metricName(a0)} è scesa da $a1 % a ${f.args.length > 2 ? f.args[2] : '?'} % in modo costante nelle ultime acquisizioni.',
        'La ${_metricName(a0)} a chuté de $a1 % à ${f.args.length > 2 ? f.args[2] : '?'} % de façon soutenue sur les dernières captures.',
      ),
      'new-apps' => _pick(
        '$a0 app(s) instaladas desde la captura anterior: $a1.${f.args.length > 2 && f.args[2] != '0' ? ' ${f.args[2]} con superficie riesgosa o sideload.' : ''}',
        '$a0 app(s) installed since the previous snapshot: $a1.${f.args.length > 2 && f.args[2] != '0' ? ' ${f.args[2]} with risky surface or sideload.' : ''}',
        '$a0 app(s) instalados desde a captura anterior: $a1.${f.args.length > 2 && f.args[2] != '0' ? ' ${f.args[2]} com superfície arriscada ou sideload.' : ''}',
        '$a0 app installate dall’acquisizione precedente: $a1.${f.args.length > 2 && f.args[2] != '0' ? ' ${f.args[2]} con superficie a rischio o sideload.' : ''}',
        '$a0 app(s) installées depuis la capture précédente : $a1.${f.args.length > 2 && f.args[2] != '0' ? ' ${f.args[2]} à surface risquée ou sideload.' : ''}',
      ),
      'patch-old' => _pick(
        'El último parche de seguridad ($a1) tiene $a0 días.',
        'The latest security patch ($a1) is $a0 days old.',
        'O último patch de segurança ($a1) tem $a0 dias.',
        'L’ultima patch di sicurezza ($a1) ha $a0 giorni.',
        'Le dernier correctif de sécurité ($a1) date de $a0 jours.',
      ),
      _ => f.args.join(', '),
    };
  }

  String findingReco(Finding f) => switch (f.id) {
    'mem-pressure' => _pick(
      'Cierra apps en segundo plano; si persiste tras reiniciar, revisa qué app la consume.',
      'Close background apps; if it persists after reboot, review which app consumes it.',
      'Feche apps em segundo plano; se persistir após reiniciar, veja qual app consome.',
      'Chiudi le app in background; se persiste dopo il riavvio, verifica quale app la consuma.',
      'Fermez les apps en arrière-plan ; si cela persiste après redémarrage, cherchez quelle app la consomme.',
    ),
    'storage-low' => _pick(
      'Libera espacio (fotos, descargas, cachés) antes de que el SO empiece a fallar.',
      'Free up space (photos, downloads, caches) before the OS starts failing.',
      'Libere espaço (fotos, downloads, caches) antes que o SO comece a falhar.',
      'Libera spazio (foto, download, cache) prima che il SO inizi a dare problemi.',
      'Libérez de l’espace (photos, téléchargements, caches) avant que l’OS ne défaille.',
    ),
    'battery-temp' => _pick(
      'Deja reposar el equipo; calor sostenido sin uso intensivo merece revisar apps activas.',
      'Let the device rest; sustained heat without heavy use warrants reviewing active apps.',
      'Deixe o aparelho descansar; calor sustentado sem uso intenso merece revisar apps ativos.',
      'Lascia riposare il dispositivo; calore sostenuto senza uso intenso merita di controllare le app attive.',
      'Laissez l’appareil se reposer ; une chaleur soutenue sans usage intensif mérite d’examiner les apps actives.',
    ),
    'battery-health' => _pick(
      'Considera diagnóstico de batería del fabricante.',
      'Consider the manufacturer\'s battery diagnostics.',
      'Considere o diagnóstico de bateria do fabricante.',
      'Valuta la diagnostica della batteria del produttore.',
      'Envisagez le diagnostic de batterie du fabricant.',
    ),
    'risky-apps' => _pick(
      'Revisa cada app listada: ¿reconoces su origen? ¿necesita esos permisos?',
      'Review each listed app: do you recognize its origin? Does it need those permissions?',
      'Revise cada app listado: você reconhece a origem? ele precisa dessas permissões?',
      'Controlla ogni app elencata: ne riconosci l’origine? le servono quei permessi?',
      'Vérifiez chaque app listée : en reconnaissez-vous l’origine ? A-t-elle besoin de ces permissions ?',
    ),
    'root-indicators' => _pick(
      'Si no rooteaste este equipo a propósito, investiga el origen del indicador.',
      'If you did not deliberately root this device, investigate the indicator\'s origin.',
      'Se você não rooteou este aparelho de propósito, investigue a origem do indicador.',
      'Se non hai rootato questo dispositivo di proposito, indaga sull’origine dell’indicatore.',
      'Si vous n’avez pas rooté cet appareil volontairement, cherchez l’origine de l’indicateur.',
    ),
    'load-rising' => _pick(
      'Algo consume el recurso de forma continua. Compara las capturas del Historial y revisa qué cambió (app nueva, sincronización, proceso atascado).',
      'Something is steadily consuming the resource. Compare History snapshots and review what changed (new app, sync, stuck process).',
      'Algo consome o recurso de forma contínua. Compare as capturas do Histórico e veja o que mudou (app novo, sincronização, processo travado).',
      'Qualcosa consuma la risorsa in modo continuo. Confronta le acquisizioni della Cronologia e verifica cosa è cambiato (nuova app, sincronizzazione, processo bloccato).',
      'Quelque chose consomme la ressource en continu. Comparez les captures de l’Historique et cherchez ce qui a changé (nouvelle app, synchronisation, processus bloqué).',
    ),
    'new-apps' => _pick(
      '¿Reconoces estas instalaciones? Si alguna llegó sola o por sideload, revísala en la pestaña Apps y su ficha del sistema.',
      'Do you recognize these installs? If any arrived on its own or via sideload, review it in the Apps tab and its system page.',
      'Você reconhece estas instalações? Se alguma chegou sozinha ou por sideload, revise na aba Apps e na ficha do sistema.',
      'Riconosci queste installazioni? Se qualcuna è arrivata da sola o via sideload, controllala nella scheda App e nella sua pagina di sistema.',
      'Reconnaissez-vous ces installations ? Si l’une est arrivée seule ou par sideload, vérifiez-la dans l’onglet Apps et sa fiche système.',
    ),
    'patch-old' => _pick(
      'Busca actualizaciones del sistema: un equipo sin parches acumula vulnerabilidades conocidas y públicas.',
      'Check for system updates: an unpatched device accumulates known, public vulnerabilities.',
      'Busque atualizações do sistema: um aparelho sem patches acumula vulnerabilidades conhecidas e públicas.',
      'Cerca aggiornamenti di sistema: un dispositivo senza patch accumula vulnerabilità note e pubbliche.',
      'Recherchez les mises à jour système : un appareil sans correctifs accumule des vulnérabilités connues et publiques.',
    ),
    _ => '',
  };

  /// Descripción humana de un permiso peligroso de Android. La entrada es la
  /// constante SIN el prefijo `android.permission.` (p. ej. `RECORD_AUDIO`).
  /// Para una persona novata, esto reemplaza la "variable de programación".
  /// Constantes desconocidas se humanizan como último recurso.
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
