/// Textos de los HALLAZGOS del motor de reglas, en los cinco idiomas.
///
/// Vive aparte de `strings.dart` porque cada regla nueva anade tres
/// bloques (titulo, detalle, recomendacion) x 5 idiomas: es la parte que
/// mas crece y la que mas se toca.
///
/// `part of` (y no un archivo suelto) porque estos textos usan `_pick`,
/// que es privado de la libreria: seguir siendo la MISMA libreria es lo
/// que permite partir el archivo sin abrir el mecanismo de traduccion.
part of '../strings.dart';

extension AppStringsFindings on AppStrings {
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
    'perm-escalation' => _pick(
      'Apps que pidieron más permisos',
      'Apps that asked for more permissions',
      'Apps que pediram mais permissões',
      'App che hanno chiesto più permessi',
      'Apps qui ont demandé plus de permissions',
    ),
    'app-usage-anomaly' => _pick(
      'Consumo fuera de lo habitual',
      'Usage out of the ordinary',
      'Consumo fora do habitual',
      'Consumo fuori dal normale',
      'Consommation inhabituelle',
    ),
    'load-rising-suspect' => _pick(
      'App instalada al empezar el deterioro',
      'App installed as the decline began',
      'App instalado quando o desgaste começou',
      'App installata all’inizio del peggioramento',
      'App installée au début de la dégradation',
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
      'perm-escalation' => _pick(
        '$a0 app(s) ganaron permisos peligrosos desde la captura anterior: $a1.',
        '$a0 app(s) gained dangerous permissions since the previous snapshot: $a1.',
        '$a0 app(s) ganharam permissões perigosas desde a captura anterior: $a1.',
        '$a0 app hanno ottenuto permessi pericolosi dall’acquisizione precedente: $a1.',
        '$a0 app(s) ont obtenu des permissions dangereuses depuis la capture précédente : $a1.',
      ),
      // args[2] = '1' cuando alguna de las apps tiene además una capacidad
      // de espionaje concedida y activa. `×∞` = no lo hacía antes.
      'app-usage-anomaly' => _pick(
        '$a0 app(s) multiplicaron su consumo respecto de su propio hábito: $a1.${f.args.length > 2 && f.args[2] == '1' ? ' Alguna tiene además una capacidad de espionaje activa.' : ''}',
        '$a0 app(s) multiplied their usage compared with their own habit: $a1.${f.args.length > 2 && f.args[2] == '1' ? ' One of them also has an active spying capability.' : ''}',
        '$a0 app(s) multiplicaram o consumo em relação ao próprio hábito: $a1.${f.args.length > 2 && f.args[2] == '1' ? ' Alguma tem ainda uma capacidade de espionagem ativa.' : ''}',
        '$a0 app hanno moltiplicato il consumo rispetto alla propria abitudine: $a1.${f.args.length > 2 && f.args[2] == '1' ? ' Una di esse ha anche una capacità di spionaggio attiva.' : ''}',
        '$a0 app(s) ont multiplié leur consommation par rapport à leur propre habitude : $a1.${f.args.length > 2 && f.args[2] == '1' ? ' L’une d’elles a aussi une capacité d’espionnage active.' : ''}',
      ),
      'load-rising-suspect' => _pick(
        '$a0 app(s) se instalaron en la misma ventana en que empezó el deterioro: $a1. Coincidir en el tiempo no es causarlo.',
        '$a0 app(s) were installed in the same window when the decline began: $a1. Coinciding in time is not causing it.',
        '$a0 app(s) foram instalados na mesma janela em que o desgaste começou: $a1. Coincidir no tempo não é causar.',
        '$a0 app sono state installate nella stessa finestra in cui è iniziato il peggioramento: $a1. Coincidere nel tempo non significa causarlo.',
        '$a0 app(s) ont été installées dans la même fenêtre où la dégradation a commencé : $a1. Coïncider dans le temps n’est pas causer.',
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
    'perm-escalation' => _pick(
      'Abre cada app en la pestaña Señaladas: si no reconoces por qué ahora pide ese permiso, revócalo desde la ficha del sistema.',
      'Open each app in the Flagged tab: if you do not recognize why it now asks for that permission, revoke it from the system page.',
      'Abra cada app na aba Sinalizadas: se você não reconhece por que agora pede essa permissão, revogue na ficha do sistema.',
      'Apri ogni app nella scheda Segnalate: se non riconosci perché ora chiede quel permesso, revocalo dalla pagina di sistema.',
      'Ouvrez chaque app dans l’onglet Signalées : si vous ne reconnaissez pas pourquoi elle demande cette permission, révoquez-la depuis la fiche système.',
    ),
    'app-usage-anomaly' => _pick(
      '¿Usaste hoy esa app más que de costumbre? Si no, mira sus permisos concedidos y su ficha del sistema: un consumo que se dispara sin que tú hicieras nada es el indicio a seguir.',
      'Did you use that app more than usual today? If not, check its granted permissions and its system page: usage that spikes without you doing anything is the lead to follow.',
      'Você usou esse app mais que o normal hoje? Se não, veja as permissões concedidas e a ficha do sistema: um consumo que dispara sem você fazer nada é o indício a seguir.',
      'Hai usato quell’app più del solito oggi? Se no, controlla i permessi concessi e la pagina di sistema: un consumo che schizza senza che tu abbia fatto nulla è la pista da seguire.',
      'Avez-vous utilisé cette app plus que d’habitude aujourd’hui ? Sinon, vérifiez ses permissions accordées et sa fiche système : une consommation qui s’envole sans action de votre part est la piste à suivre.',
    ),
    'load-rising-suspect' => _pick(
      'Es el primer sitio donde mirar, no un culpable. Si no reconoces la instalación, revísala en Señaladas; si la reconoces, desinstálala un rato y compara dos capturas en el Historial.',
      'This is the first place to look, not a culprit. If you do not recognize the install, review it in Flagged; if you do, uninstall it for a while and compare two snapshots in History.',
      'É o primeiro lugar para olhar, não um culpado. Se você não reconhece a instalação, revise em Sinalizadas; se reconhece, desinstale por um tempo e compare duas capturas no Histórico.',
      'È il primo posto dove guardare, non un colpevole. Se non riconosci l’installazione, controllala in Segnalate; se la riconosci, disinstallala per un po’ e confronta due acquisizioni nella Cronologia.',
      'C’est le premier endroit où regarder, pas un coupable. Si vous ne reconnaissez pas l’installation, vérifiez-la dans Signalées ; sinon, désinstallez-la un moment et comparez deux captures dans l’Historique.',
    ),
    _ => '',
  };

  /// Descripción humana de un permiso peligroso de Android. La entrada es la
  /// constante SIN el prefijo `android.permission.` (p. ej. `RECORD_AUDIO`).
  /// Para una persona novata, esto reemplaza la "variable de programación".
  /// Constantes desconocidas se humanizan como último recurso.
}
