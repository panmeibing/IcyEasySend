import 'app_localizations.dart';

/// Italian localization
class AppLocalizationsIt extends AppLocalizations {
  @override
  String get appName => 'Icy Easy Send';

  @override
  String get appVersion => 'Versione';

  @override
  String get navHome => 'Home';

  @override
  String get navHistory => 'Cronologia';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get homeTitle => 'Home';

  @override
  String get serverStatus => 'Stato del Server';

  @override
  String get serverRunning => 'In Esecuzione';

  @override
  String get serverStopped => 'Fermato';

  @override
  String get serverAddress => 'Indirizzo del Server';

  @override
  String get deviceName => 'Nome Dispositivo';

  @override
  String get storageSpace => 'Spazio di Archiviazione';

  @override
  String get availableSpace => 'Spazio Disponibile';

  @override
  String get sendFiles => 'Invia File';

  @override
  String get receiveFiles => 'Ricevi File';

  @override
  String get selectFiles => 'Seleziona File';

  @override
  String get selectFolder => 'Seleziona Cartella';

  @override
  String get dragDropHint => 'Trascina i file qui';

  @override
  String get noFilesSelected => 'Nessun file selezionato';

  @override
  String filesSelected(int count) => '$count file selezionati';

  @override
  String get clearSelection => 'Cancella Selezione';

  @override
  String get startSending => 'Inizia Invio';

  @override
  String get sending => 'Invio in corso';

  @override
  String get sendSuccess => 'Invio Riuscito';

  @override
  String get sendFailed => 'Invio Fallito';

  @override
  String get cancel => 'Annulla';

  @override
  String get confirm => 'Conferma';

  @override
  String get historyTitle => 'Cronologia Trasferimenti';

  @override
  String get noHistory => 'Nessuna cronologia';

  @override
  String get clearHistory => 'Cancella Cronologia';

  @override
  String get sent => 'Inviato';

  @override
  String get received => 'Ricevuto';

  @override
  String get failed => 'Fallito';

  @override
  String get fileSize => 'Dimensione File';

  @override
  String get time => 'Ora';

  @override
  String get deleteItem => 'Elimina Record';

  @override
  String get deleteItemConfirm =>
      'Sei sicuro di voler eliminare questo record?';

  @override
  String get openFile => 'Apri File';

  @override
  String get openFolder => 'Apri Cartella';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get general => 'Generale';

  @override
  String get language => 'Lingua';

  @override
  String get deviceNameSetting => 'Nome Dispositivo';

  @override
  String get editDeviceName => 'Modifica Nome Dispositivo';

  @override
  String get deviceNameHint => 'Inserisci il nome del dispositivo';

  @override
  String get deviceNameEmpty => 'Il nome del dispositivo non può essere vuoto';

  @override
  String get port => 'Porta';

  @override
  String get portHint => 'Inserisci il numero di porta';

  @override
  String get portInvalid => 'Numero di porta non valido';

  @override
  String get portInUse => 'Porta già in uso';

  @override
  String get savePath => 'Percorso di Salvataggio';

  @override
  String get selectSavePath => 'Seleziona Percorso di Salvataggio';

  @override
  String get savePathDesc =>
      'I file ricevuti vengono salvati qui. Per impostazione predefinita si usa la cartella Download di sistema.';

  @override
  String get savePathDefaultBadge => 'Predefinito';

  @override
  String get savePathUnavailable =>
      'Impossibile ottenere il percorso di salvataggio';

  @override
  String get savePathSavedSuccess => 'Percorso di salvataggio impostato con successo';

  @override
  String get savePathNotWritable =>
      'Impossibile scrivere in questa cartella. Scegli un\'altra posizione o controlla i permessi.';

  @override
  String get resetSavePathToDefault => 'Usa cartella predefinita';

  @override
  String get savePathResetSuccess =>
      'Ripristinata la cartella Download di sistema';

  @override
  String get autoStart => 'Avvio Automatico';

  @override
  String get autoStartDesc =>
      'Avvia automaticamente il servizio all\'avvio dell\'applicazione';

  @override
  String get network => 'Rete';

  @override
  String get networkDiagnostics => 'Diagnostica di Rete';

  @override
  String get scanDevices => 'Cerca dispositivi';

  @override
  String get scanDevicesTitle => 'Cerca dispositivi nella LAN';

  @override
  String get scanningDevices => 'Scansione della rete locale...';

  @override
  String scanProgress(int scanned, int total, int found) =>
      'Scansionati $scanned/$total, trovati $found dispositiv${found == 1 ? 'o' : 'i'}';

  @override
  String get noDevicesFound => 'Nessun dispositivo trovato';

  @override
  String get noDevicesFoundHint =>
      'Assicurati che il dispositivo di destinazione abbia avviato il server e sia sulla stessa rete. Controlla isolamento AP del router e firewall.';

  @override
  String scanDevicesFound(int count) =>
      'Trovati $count dispositiv${count == 1 ? 'o' : 'i'}';

  @override
  String get rescan => 'Ripeti scansione';

  @override
  String get runDiagnostics => 'Esegui Diagnostica';

  @override
  String get about => 'Informazioni';

  @override
  String get version => 'Versione';

  @override
  String get checkUpdate => 'Verifica Aggiornamenti';

  @override
  String get feedback => 'Feedback';

  @override
  String get openSource => 'Licenze Open Source';

  @override
  String get license => 'Licenza';

  @override
  String get permissionRequired => 'Permesso Richiesto';

  @override
  String get permissionDenied => 'Permesso Negato';

  @override
  String get permissionPermanentlyDenied => 'Permesso Negato Permanentemente';

  @override
  String get permissionStorage => 'Permesso di Archiviazione';

  @override
  String get permissionStorageDesc =>
      'Permesso di archiviazione necessario per salvare e leggere file';

  @override
  String get permissionNotification => 'Permesso di Notifica';

  @override
  String get permissionNotificationDesc =>
      'Permesso di notifica necessario per mostrare il progresso del trasferimento';

  @override
  String get openSettings => 'Apri Impostazioni';

  @override
  String get permissionWarning =>
      'Alcuni permessi non sono stati concessi, alcune funzionalità potrebbero essere limitate';

  @override
  String get error => 'Errore';

  @override
  String get errorUnknown => 'Errore Sconosciuto';

  @override
  String get errorNetwork => 'Errore di Rete';

  @override
  String get errorFileNotFound => 'File Non Trovato';

  @override
  String get errorPermission => 'Errore di Permesso';

  @override
  String get errorStorage => 'Errore di Archiviazione';

  @override
  String get errorServer => 'Errore del Server';

  @override
  String get errorServerStart => 'Impossibile Avviare il Server';

  @override
  String get errorServerStop => 'Impossibile Fermare il Server';

  @override
  String get errorConnection => 'Errore di Connessione';

  @override
  String get errorTimeout => 'Timeout di Connessione';

  @override
  String get retry => 'Riprova';

  @override
  String get copied => 'Copiato';

  @override
  String get copyFailed => 'Copia Fallita';

  @override
  String get saved => 'Salvato';

  @override
  String get saveFailed => 'Salvataggio Fallito';

  @override
  String get deleted => 'Eliminato';

  @override
  String get deleteFailed => 'Eliminazione Fallita';

  @override
  String get loading => 'Caricamento';

  @override
  String get success => 'Successo';

  @override
  String get warning => 'Avviso';

  @override
  String get info => 'Informazione';

  @override
  String get yes => 'Sì';

  @override
  String get no => 'No';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Chiudi';

  @override
  String get selectFilesFailed => 'Selezione file fallita';

  @override
  String get selectFolderFailed => 'Selezione cartella fallita';

  @override
  String folderFilesAdded(int count) =>
      'Aggiunti $count file dalla cartella';

  @override
  String get folderContainsNoFiles =>
      'La cartella selezionata non contiene file da inviare';

  @override
  String get openFileFailed => 'Apertura file fallita';

  @override
  String get openFolderFailed => 'Apertura cartella fallita';

  @override
  String get fileNotExist => 'Il file non esiste';

  @override
  String get folderNotExist => 'La cartella non esiste';

  @override
  String get diagnosticsTitle => 'Diagnostica di Rete';

  @override
  String get diagnosticsRunning => 'Diagnostica in esecuzione...';

  @override
  String get diagnosticsComplete => 'Diagnostica completata';

  @override
  String get diagnosticsFailed => 'Diagnostica fallita';

  @override
  String get networkStatus => 'Stato della Rete';

  @override
  String get wifiConnected => 'WiFi Connesso';

  @override
  String get wifiDisconnected => 'WiFi Disconnesso';

  @override
  String get mobileData => 'Dati Mobili';

  @override
  String get noConnection => 'Nessuna Connessione di Rete';

  @override
  String get ipAddress => 'Indirizzo IP';

  @override
  String get noIpAddress => 'Nessun Indirizzo IP';

  @override
  String get serverStatusCheck => 'Verifica Stato del Server';

  @override
  String get portCheck => 'Verifica Porta';

  @override
  String get portAvailable => 'Porta Disponibile';

  @override
  String get portUnavailable => 'Porta Non Disponibile';

  @override
  String get suggestions => 'Suggerimenti';

  @override
  String get syncClipboard => 'Sincronizza Appunti dell\'Altro Dispositivo';

  @override
  String filesCount(int count) => 'Invia $count file';

  @override
  String get sendFile => 'Invia File';

  @override
  String get shareViaQr => 'Condividi con QR';

  @override
  String get webShareTitle => 'Scansiona per ricevere';

  @override
  String get webShareHint =>
      'Il destinatario può scansionare con la fotocamera di sistema e scaricare nel browser, senza installare l’app. Restate sulla stessa Wi‑Fi / LAN. Alcuni scanner di terze parti possono bloccare i link LAN; usa Copia link.';

  @override
  String get webShareCopyLink => 'Copia link';

  @override
  String get webShareLinkCopied => 'Link copiato';

  @override
  String get webShareStopSharing => 'Interrompi condivisione';

  @override
  String get webShareStopped => 'Condivisione web interrotta';

  @override
  String get webShareServerRequired =>
      'Avvia il server locale prima di condividere con QR';

  @override
  String get webShareCreated =>
      'Condivisione web creata. Il destinatario può scansionare per scaricare.';

  @override
  String get webShareFailed => 'Creazione della condivisione web non riuscita';

  @override
  String get webSharePeerName => 'Condivisione web';

  @override
  String webShareFilesSummary(int count, String size) =>
      '$count file · $size';

  @override
  String webShareExpiresIn(String time) => 'Scade tra $time';

  @override
  String get releaseToAdd => 'Rilascia per aggiungere file';

  @override
  String get serverNotRunning =>
      'Il server non è in esecuzione, impossibile ricevere file condivisi';

  @override
  String get cannotReceiveFiles => 'Impossibile ricevere file';

  @override
  String get sendingInProgress => 'Invio file in corso, riprova più tardi';

  @override
  String get pleaseTryLater => 'Riprova più tardi';

  @override
  String filesAdded(int count) => '$count file condivisi aggiunti';

  @override
  String get preparingSend => 'Preparazione invio...';

  @override
  String get transferring => 'Trasferimento';

  @override
  String transferProgress(int current, int total, String fileName) =>
      '[$current/$total] $fileName: Trasferimento...';

  @override
  String get networkChanged => 'Rete cambiata, indirizzo del server aggiornato';

  @override
  String get serverAddressUpdated => 'Indirizzo del server aggiornato';

  @override
  String get portCannotBeEmpty => 'La porta non può essere vuota';

  @override
  String get portMustBeNumber => 'La porta deve essere un numero';

  @override
  String get portRange => 'Intervallo porta: 1-65535';

  @override
  String ipDeleted(String ip) => 'IP eliminato: $ip';

  @override
  String get runningDiagnostics => 'Esecuzione diagnostica di rete...';

  @override
  String get targetDeviceInfo => 'Informazioni Dispositivo di Destinazione';

  @override
  String get fullAddress => 'Indirizzo Completo';

  @override
  String get targetNotSet => 'Dispositivo di destinazione non impostato';

  @override
  String get diagnosticsReport => 'Rapporto Diagnostica di Rete';

  @override
  String get reportCopied => 'Rapporto diagnostica copiato negli appunti';

  @override
  String get deviceNameCannotBeEmpty =>
      'Il nome del dispositivo non può essere vuoto';

  @override
  String get deviceNameSaved => 'Nome dispositivo salvato';

  @override
  String get resetDeviceName => 'Ripristina Nome Dispositivo';

  @override
  String resetDeviceNameConfirm(String model) =>
      'Sei sicuro di voler ripristinare il nome del dispositivo a "$model"?';

  @override
  String get reset => 'Ripristina';

  @override
  String get confirmChange => 'Conferma Modifica';

  @override
  String concurrentTransfersChange(int from, int to) =>
      'Sei sicuro di voler modificare il numero di trasferimenti concorrenti da $from a $to?\n\nSuggerimento: ${to > from ? "Aumentare il numero di trasferimenti concorrenti può migliorare la velocità di trasferimento, ma aumenterà anche il carico del dispositivo" : "Diminuire il numero di trasferimenti concorrenti può ridurre il carico del dispositivo, ma potrebbe ridurre la velocità di trasferimento"}';

  @override
  String get concurrentTransfersHint =>
      'Suggerimento Trasferimenti Concorrenti';

  @override
  String get concurrentTransfersSaved =>
      'Numero di trasferimenti concorrenti salvato';

  @override
  String get enterValidNumber => 'Inserisci un numero valido';

  @override
  String historyCountRange(int min, int max) =>
      'Intervallo conteggio cronologia: $min-$max';

  @override
  String maxHistoryChange(int from, int to) =>
      'Sei sicuro di voler modificare il numero massimo di record di cronologia da $from a $to?\n\n';

  @override
  String currentHistoryCount(int count) =>
      'Conteggio cronologia attuale: $count record\n\n';

  @override
  String get historyWarning =>
      '⚠️ Avviso: Il numero di record di cronologia salvati è maggiore del numero impostato.\n\n';

  @override
  String historyDeleteWarning(int current, int max, int toDelete) =>
      'Verranno mantenuti solo gli ultimi $max record, i $toDelete record vecchi in eccesso verranno eliminati.';

  @override
  String get historyHint =>
      'Suggerimento: La nuova impostazione entrerà in vigore al prossimo salvataggio della cronologia.';

  @override
  String historyDeleted(int count) =>
      'Impostazione salvata, $count record vecchi eliminati';

  @override
  String get maxHistorySaved =>
      'Numero massimo di record di cronologia salvato';

  @override
  String clipboardSizeRange(int min, int max) =>
      'Intervallo dimensione appunti: $min-$max MB';

  @override
  String maxClipboardSizeChange(int from, int to) =>
      'Sei sicuro di voler modificare la dimensione massima degli appunti da $from MB a $to MB?\n\n';

  @override
  String get clipboardSizeDecreaseHint =>
      '⚠️ Suggerimento: Dopo aver ridotto il limite, il contenuto degli appunti che supera il limite non potrà essere sincronizzato, si consiglia di utilizzare la funzione di trasferimento file.';

  @override
  String get clipboardSizeIncreaseHint =>
      'Suggerimento: Dopo aver aumentato il limite, è possibile sincronizzare contenuti degli appunti più grandi, ma potrebbe influire sulla velocità di trasferimento.';

  @override
  String get maxClipboardSizeSaved => 'Dimensione massima appunti salvata';

  @override
  String get ipValidationEnabled => 'Validazione indirizzo IP abilitata';

  @override
  String get ipValidationDisabled => 'Validazione indirizzo IP disabilitata';

  @override
  String get deviceSecretKeyCleared => 'Chiave segreta dispositivo cancellata';

  @override
  String get deviceSecretKeySaved => 'Chiave segreta dispositivo salvata';

  @override
  String get loadingDevInfo => 'Caricamento informazioni di sviluppo...';

  @override
  String get copyLog => 'Copia Log';

  @override
  String logCopied(int lines) =>
      'Ultime $lines righe del log copiate negli appunti';

  @override
  String get logFileEmpty => 'File di log vuoto';

  @override
  String get devInfo => 'Informazioni di Sviluppo';

  @override
  String labelCopied(String label, String value) => '$label copiato: $value';

  @override
  String get transferSettings => 'Impostazioni Trasferimento';

  @override
  String get concurrentTransfers => 'Numero Trasferimenti Concorrenti';

  @override
  String concurrentTransfersDesc(int max) =>
      'Numero di file trasferiti concorrentemente (1-$max)';

  @override
  String get concurrentTransfersHintText =>
      'Un numero maggiore di trasferimenti concorrenti può utilizzare meglio la larghezza di banda, ma può aumentare il carico del dispositivo';

  @override
  String get maxHistory => 'Numero Massimo Record Cronologia';

  @override
  String maxHistoryDesc(int min, int max) =>
      'Numero massimo di record di trasferimento salvati ($min-$max)';

  @override
  String maxHistoryHintText(int min, int max) =>
      'Inserisci il numero ($min-$max)';

  @override
  String get oldRecordsAutoDelete =>
      'I record vecchi che superano il numero impostato verranno eliminati automaticamente, mantenendo solo i più recenti';

  @override
  String get maxClipboard => 'Dimensione Massima Appunti';

  @override
  String maxClipboardDesc(int min, int max) =>
      'Dimensione massima degli appunti consentita per la sincronizzazione ($min-$max MB)';

  @override
  String maxClipboardHintText(int min, int max) =>
      'Inserisci la dimensione ($min-$max MB)';

  @override
  String get clipboardSyncLimit =>
      'Il contenuto degli appunti che supera questa dimensione non potrà essere sincronizzato, si consiglia di utilizzare la funzione di trasferimento file';

  @override
  String get ipValidation => 'Validazione Indirizzo IP';

  @override
  String get ipValidationDesc =>
      'Verifica se l\'IP del dispositivo di destinazione è nello stesso segmento di rete';

  @override
  String get ipValidationEnabledHint =>
      'Quando abilitato, verificherà se l\'IP di destinazione è nello stesso segmento di rete, può evitare la connessione al dispositivo sbagliato';

  @override
  String get ipValidationDisabledHint =>
      'Quando disabilitato, non verificherà il segmento di rete IP, adatto per ambienti di rete complessi (come hotspot, VPN, ecc.)';

  @override
  String get deviceSecretKey => 'Chiave Segreta Locale';

  @override
  String get deviceSecretKeyDesc =>
      'Dopo l\'impostazione, altri dispositivi devono fornire la chiave corretta per saltare la conferma';

  @override
  String get deviceSecretKeyHint =>
      'Inserisci la chiave segreta (lascia vuoto per non usare la chiave)';

  @override
  String get notSet => 'Non Impostato';

  @override
  String get author => 'Autore';

  @override
  String get appDescription =>
      'Uno strumento semplice e facile da usare per il trasferimento di file in rete locale';

  @override
  String get targetDeviceIP => 'Indirizzo IP Dispositivo di Destinazione';

  @override
  String get ipHint => 'Ad esempio: 192.168.1.100';

  @override
  String get clear => 'Cancella';

  @override
  String get history => 'Cronologia';

  @override
  String resetToDefaultPort(int port) =>
      'Ripristina alla porta predefinita ($port)';

  @override
  String get targetDeviceSecretKey =>
      'Chiave Segreta Dispositivo di Destinazione (Opzionale)';

  @override
  String get secretKeyHint => 'La chiave corretta può saltare la conferma';

  @override
  String get aboutSecretKey => 'Informazioni Chiave Segreta';

  @override
  String get secretKeyFeatureTitle => 'Descrizione Funzione Chiave Segreta';

  @override
  String get secretKeyFeatureDesc =>
      'Se il dispositivo di destinazione ha impostato una chiave segreta, inserire la chiave corretta può saltare la finestra di conferma e trasferire file o sincronizzare gli appunti direttamente.';

  @override
  String get secretKeyUsageSteps => 'Passaggi di utilizzo:';

  @override
  String get secretKeyUsageStep1 =>
      '1. Il dispositivo di destinazione imposta la chiave segreta locale nella pagina delle impostazioni';

  @override
  String get secretKeyUsageStep2 =>
      '2. Inserisci la chiave segreta del dispositivo di destinazione in questo campo di input';

  @override
  String get secretKeyUsageStep3 =>
      '3. Quando invii file o richiedi gli appunti, se la chiave è corretta, l\'altra parte accetterà automaticamente';

  @override
  String get secretKeyTip =>
      'Suggerimento: Lascia vuoto per utilizzare il metodo di conferma manuale tradizionale';

  @override
  String get secretKeyDescription => 'Descrizione Chiave Segreta';

  @override
  String get clearSecretKey => 'Cancella Chiave Segreta';

  @override
  String get gotIt => 'Capito';

  @override
  String get targetDevicePort => 'Porta Dispositivo di Destinazione';

  @override
  String get localIP => 'IP Locale';

  @override
  String ipCopied(String ip) => 'Indirizzo IP copiato: $ip';

  @override
  String get transferred => 'Trasferito';

  @override
  String get transferSpeed => 'Velocità di Trasferimento';

  @override
  String get remainingTime => 'Tempo Rimanente';

  @override
  String transferringProgress(double progress) =>
      'Trasferimento ${progress.toStringAsFixed(1)}%';

  @override
  String get storagePermissionMessage =>
      'Permesso di archiviazione necessario per selezionare i file. Abilita il permesso manualmente nelle impostazioni.';

  @override
  String get checkingTargetDevice => 'Verifica dispositivo di destinazione...';

  @override
  String get targetDeviceUnavailable =>
      'Dispositivo di destinazione non disponibile';

  @override
  String targetDeviceError(String error) =>
      'Dispositivo di destinazione non disponibile\nErrore: $error';

  @override
  String get connectionFailed => 'Connessione fallita';

  @override
  String get transferHistory => 'Cronologia Trasferimenti';

  @override
  String get clearHistoryTitle => 'Cancella Cronologia';

  @override
  String get clearHistoryMessage =>
      'Sei sicuro di voler cancellare tutta la cronologia dei trasferimenti? Questa operazione non può essere annullata.';

  @override
  String get noFilteredRecords => 'Nessun record corrispondente';

  @override
  String get filterAll => 'Tutti';

  @override
  String get filterSent => 'Inviati';

  @override
  String get filterReceived => 'Ricevuti';

  @override
  String get statisticsInfo => 'Informazioni Statistiche';

  @override
  String transfersCount(int count) => '$count trasferimenti';

  @override
  String get totalTransfers => 'Totale Trasferimenti';

  @override
  String get successfulTransfers => 'Successo';

  @override
  String get failedTransfers => 'Fallito';

  @override
  String get sentFiles => 'Inviati';

  @override
  String get receivedFiles => 'Ricevuti';

  @override
  String get totalSize => 'Dimensione Totale';

  @override
  String get moreActions => 'Altre Azioni';

  @override
  String get deleteRecord => 'Elimina Record';

  @override
  String get viewDetails => 'Visualizza Dettagli';

  @override
  String get deleteRecordTitle => 'Elimina Record';

  @override
  String deleteRecordMessage(String fileName) =>
      'Sei sicuro di voler eliminare il record di trasferimento di "$fileName"?\n\nNota: Questo eliminerà solo il record, non il file stesso.';

  @override
  String get deleteRecordNote =>
      'Nota: Questo eliminerà solo il record, non il file stesso.';

  @override
  String get recordDeleted => 'Record eliminato';

  @override
  String get filePathNotExist => 'Il percorso del file non esiste';

  @override
  String get cannotOpenFile => 'Impossibile aprire il file';

  @override
  String cannotOpenFileWithMessage(String message) =>
      'Impossibile aprire il file: $message';

  @override
  String get iosNoFolderSupport =>
      'iOS non supporta l\'apertura diretta delle cartelle';

  @override
  String get cannotOpenFolder => 'Impossibile aprire la cartella';

  @override
  String get recentFilesOpened =>
      'File recenti aperti, cerca manualmente il file';

  @override
  String get receiveRecord => 'Record Ricezione';

  @override
  String get sendRecord => 'Record Invio';

  @override
  String get fileName => 'Nome File';

  @override
  String get fromDevice => 'Dal Dispositivo';

  @override
  String get toDevice => 'Al Dispositivo';

  @override
  String get deviceIP => 'IP Dispositivo';

  @override
  String get transferTime => 'Ora Trasferimento';

  @override
  String get transferStatus => 'Stato Trasferimento';

  @override
  String get statusSuccess => 'Successo';

  @override
  String get statusFailed => 'Fallito';

  @override
  String get savedLocation => 'Posizione Salvata';

  @override
  String get copy => 'Copia';

  @override
  String get pathCopied => 'Percorso copiato negli appunti';

  @override
  String get from => 'Da';

  @override
  String get sentTo => 'Inviato a';

  // Clipboard related
  @override
  String get clipboardRequest => 'Richiesta Appunti';

  @override
  String clipboardRequestFrom(String deviceName) =>
      'Il dispositivo "$deviceName" richiede di ottenere il contenuto dei tuoi appunti';

  @override
  String get allowClipboardRequest => 'Consentire?';

  @override
  String get clipboardRequestMessage => 'Richiesta Appunti';

  @override
  String autoRejectIn(int seconds) => 'Rifiuto automatico tra $seconds secondi';

  @override
  String get reject => 'Rifiuta';

  @override
  String get allow => 'Consenti';

  @override
  String clipboardSharedWithSecretKey(String deviceName) =>
      '$deviceName ha superato la verifica con chiave segreta, condivisione automatica degli appunti';

  @override
  String get clipboardRequestRejected =>
      'L\'utente ha rifiutato la richiesta degli appunti';

  @override
  String get clipboardEmpty => 'Appunti vuoti';

  @override
  String clipboardContentTooLarge(double actualSizeMB, int maxSizeMB) =>
      'Il contenuto degli appunti è troppo grande (${actualSizeMB.toStringAsFixed(2)} MB), supera il limite del dispositivo di destinazione ($maxSizeMB MB). Si consiglia di utilizzare la funzione di trasferimento file.';

  @override
  String get clipboardContentSuccess =>
      'Contenuto degli appunti ottenuto con successo';

  @override
  String get invalidJsonFormat => 'Formato JSON non valido';

  @override
  String get serverInternalError => 'Errore interno del server';


  @override
  String get backgroundRejectNeedsSecretKey => 'Il dispositivo è in background. È supportata solo la sincronizzazione/ricezione automatica con chiave segreta corrispondente.';

  @override
  String get foregroundServiceNotificationTitle => 'IcyEasySend';

  @override
  String get foregroundServiceNotificationText => 'In attesa di trasferimenti e sync appunti in background';

  @override
  String get androidBackgroundReceiveHint => 'In background solo i dispositivi con chiave segreta corrispondente possono sincronizzare o inviare automaticamente. Mantieni la notifica persistente.';

  @override
  String get clipboardOverlay => 'Pulsante flottante appunti';

  @override
  String get clipboardOverlayDesc => 'Tocca il pulsante flottante per aggiornare la cache testo/immagine per la sync in background';

  @override
  String get clipboardOverlayHint => 'In background viene sincronizzato solo l\'ultimo contenuto aggiornato. Disattivare cancella la cache e nasconde il pulsante.';

  @override
  String get clipboardOverlayPermissionNeeded => 'Consenti "Visualizza sopra altre app" nelle impostazioni. Il pulsante apparirà al ritorno.';

  @override
  String get clipboardOverlayEnabledToast => 'Pulsante flottante appunti attivato';

  @override
  String get clipboardBackgroundCacheMiss => 'Impossibile leggere gli appunti di sistema in background e nessuna cache disponibile. Apri l\'app o tocca il pulsante flottante per aggiornare.';
  // Clipboard sync
  @override
  String get requestingClipboard => 'Richiesta appunti...';

  @override
  String get clipboardSyncSuccess => 'Sincronizzazione appunti riuscita';

  @override
  String get textClipboardSyncSuccess =>
      'Sincronizzazione appunti di testo riuscita';

  @override
  String get fileClipboardSyncSuccess =>
      'Sincronizzazione appunti file riuscita\nPuoi incollare nell\'applicazione o nel gestore file';

  @override
  String get clipboardSyncFailed => 'Sincronizzazione appunti fallita';

  @override
  String get syncFailed => 'Sincronizzazione fallita';

  @override
  String clipboardRequestError(String error) =>
      'Errore durante la richiesta degli appunti: $error';

  // File transfer
  @override
  String invalidFilesMessage(String fileNames) =>
      'I seguenti file non sono validi o inaccessibili:\n$fileNames';

  @override
  String get waitingForReceiverConfirmation =>
      'In attesa della conferma del destinatario...';

  @override
  String get fileSendSuccess => 'File inviato con successo!';

  @override
  String filesSendSuccess(int count) => '$count file inviati con successo!';

  @override
  String get allFilesSendFailed => 'Invio di tutti i file fallito';

  @override
  String get failedFiles => 'File Falliti';

  @override
  String get transferComplete => 'Trasferimento Completato';

  @override
  String get successCount => 'Successo';

  @override
  String get failureCount => 'Fallito';

  @override
  String transferSummary(
    int successCount,
    int failureCount,
    String failedFiles,
  ) =>
      'Successo: $successCount file\nFallito: $failureCount file\n\nFile falliti:\n$failedFiles';

  // Batch transfer status
  @override
  String get preparingTransferInfo =>
      'Preparazione informazioni trasferimento...';

  @override
  String waitingForReceiverConfirmFiles(int count) =>
      'In attesa della conferma del destinatario per $count file...';

  @override
  String transferringFile(int current, int total, String fileName) =>
      'Trasferimento file $current/$total: $fileName';

  @override
  String get receiverRejected => 'Il destinatario ha rifiutato la ricezione';

  @override
  String receiverRejectedWithStatus(int statusCode) =>
      'Il destinatario ha rifiutato la ricezione\nCodice di stato: $statusCode';

  @override
  String get transferIdNotFound => 'ID trasferimento non trovato';

  // Batch receive
  @override
  String get waitingForConfirmation => 'In attesa di conferma...';

  @override
  String get preparingToReceive => 'Preparazione alla ricezione...';

  @override
  String get rejected => 'Rifiutato';

  @override
  String get receiveComplete => 'Ricezione completata';

  @override
  String receivingProgress(double progress) =>
      'Ricezione... ${progress.toStringAsFixed(1)}%';

  @override
  String receivingFiles(int count) => 'Ricezione $count file';

  @override
  String receiveFilesCount(int count) => 'Ricevi $count file';

  @override
  String get sender => 'Mittente';

  @override
  String get totalSizeBatch => 'Dimensione Totale';

  @override
  String get fileList => 'Elenco File';

  @override
  String get allFilesReceiveComplete => 'Tutti i file ricevuti!';

  @override
  String get receivingFiles2 => 'Ricezione file...';

  @override
  String autoRejectCountdown(int seconds) =>
      'Ricevere questi file? (Rifiuto automatico tra $seconds secondi)';

  @override
  String get rejectAll => 'Rifiuta Tutti';

  @override
  String get acceptAll => 'Accetta Tutti';

  // Network diagnostics
  @override
  String get networkDiagnosticsReport => 'Rapporto Diagnostica di Rete';

  @override
  String get localNetworkInterfaces => 'Interfacce di Rete Locali';

  @override
  String get noValidNetworkInterface =>
      'Nessuna interfaccia di rete valida trovata';

  @override
  String get privateNetworkAddress => 'Indirizzo di Rete Privata';

  @override
  String get targetDeviceReachability =>
      'Raggiungibilità Dispositivo di Destinazione';

  @override
  String get canConnectToTarget =>
      'Può connettersi al dispositivo di destinazione';

  @override
  String get cannotConnectToTarget =>
      'Impossibile connettersi al dispositivo di destinazione';

  @override
  String get healthCheckTest => 'Test di Verifica Salute';

  @override
  String get healthCheckSuccess => 'Verifica salute riuscita';

  @override
  String get healthCheckFailed => 'Verifica salute fallita';

  @override
  String get statusCode => 'Codice di Stato';

  @override
  String get response => 'Risposta';

  @override
  String get internetConnection => 'Connessione Internet';

  @override
  String get hasInternetConnection => 'Ha connessione internet';

  @override
  String get noInternetConnection => 'Nessuna connessione internet';

  // Error messages
  @override
  String get networkConnectionFailed =>
      'Impossibile connettersi al dispositivo di destinazione, verificare la connessione di rete e l\'indirizzo IP';

  @override
  String get networkTimeout =>
      'Timeout di connessione, il dispositivo di destinazione potrebbe essere offline o la rete è instabile';

  @override
  String get networkRequestFailed =>
      'Richiesta di rete fallita, verificare la connessione di rete';

  @override
  String get transferTimeout =>
      'Timeout di trasferimento, verificare la connessione di rete';

  @override
  String get transferInterrupted => 'Trasferimento interrotto, riprovare';

  @override
  String get fileNotFound => 'Il file non esiste';

  @override
  String get fileNotReadable =>
      'Impossibile leggere il file, assicurarsi che il file esista e abbia il permesso di accesso';

  @override
  String get fileAccessError =>
      'Errore di accesso al file, verificare i permessi del file';

  @override
  String get fileSaveFailed => 'Salvataggio file fallito';

  @override
  String get fileSizeMismatch =>
      'Salvataggio file fallito: dimensione del file non corrisponde';

  @override
  String get invalidFileName =>
      'Il nome del file contiene caratteri non validi';

  @override
  String get downloadsDirectoryUnavailable =>
      'Impossibile accedere alla directory dei download';

  @override
  String get storageInsufficient =>
      'Spazio di archiviazione insufficiente, impossibile ricevere il file';

  @override
  String get storageCheckFailed =>
      'Impossibile verificare lo spazio di archiviazione';

  @override
  String get networkPermissionDenied =>
      'Permesso di accesso alla rete necessario per trasferire file';

  @override
  String get storagePermissionDenied =>
      'Permesso di accesso all\'archiviazione necessario per salvare file';

  @override
  String serverStartFailed(String reason) =>
      'Impossibile avviare il server: $reason';

  @override
  String get serverPortsOccupied =>
      'Impossibile avviare il server: tutte le porte sono occupate';

  @override
  String serverPortsOccupiedRange(int defaultPort, int maxPort) =>
      'Impossibile avviare il server: le porte $defaultPort-$maxPort sono tutte occupate';

  @override
  String get serverUnknownError =>
      'Impossibile avviare il server: errore sconosciuto';

  @override
  String get transferRejected =>
      'Il destinatario ha rifiutato la ricezione del file';

  @override
  String get fileTooLarge => 'File troppo grande, massimo supportato 2GB';

  @override
  String get fileOrStorageFull =>
      'File troppo grande o spazio di archiviazione del destinatario insufficiente';

  @override
  String get receiveTimeout =>
      'Timeout di ricezione, rifiutato automaticamente';

  @override
  String get userRejected => 'L\'utente ha rifiutato la ricezione del file';

  @override
  String get ipAddressEmpty => 'L\'indirizzo IP non può essere vuoto';

  @override
  String get ipAddressInvalidFormat =>
      'Formato indirizzo IP non valido, utilizzare il formato xxx.xxx.xxx.xxx';

  @override
  String get ipAddressInvalidRange =>
      'Formato indirizzo IP non valido, ogni numero deve essere compreso tra 0-255';

  @override
  String get ipAddressSpecial1 =>
      'Impossibile utilizzare 0.0.0.0 come indirizzo di destinazione';

  @override
  String get ipAddressSpecial2 =>
      'Impossibile utilizzare l\'indirizzo broadcast 255.255.255.255';

  @override
  String ipAddressNotInSameSubnet(
    String localIP,
    String targetIP,
    String localNetwork,
    String targetNetwork,
  ) =>
      '⚠️ Segmenti di rete non corrispondenti\n'
      'IP locale: $localIP (segmento: $localNetwork.x)\n'
      'IP di destinazione: $targetIP (segmento: $targetNetwork.x)\n'
      '\n'
      'Suggerimento: Entrambi i dispositivi devono essere sulla stessa rete locale (stesso segmento) per trasferire file.\n'
      'Per gli indirizzi IPv4 di Classe C, i primi tre numeri dei due indirizzi IP devono essere uguali, ad esempio entrambi 192.169.2, solo l\'ultimo numero è diverso\n'
      'Il modo più semplice è connettere entrambi i dispositivi allo stesso WiFi o router.\n';

  @override
  String get responseParseError =>
      'Impossibile analizzare la risposta del server';

  @override
  String get responseInvalidFormat =>
      'Formato risposta del dispositivo di destinazione non corretto';

  @override
  String responseStatusCodeError(int statusCode) =>
      'Il server ha restituito un codice di errore: $statusCode';

  @override
  String get fileSelectionError => 'Errore durante la selezione del file';

  @override
  String get fileSelectionCancelled => 'Selezione file annullata';

  @override
  String genericError(String operation) => '$operation fallito';

  @override
  String unexpectedError(String details) =>
      'Si è verificato un errore imprevisto: $details';

  @override
  String networkError(String context) => 'Errore di rete: $context';

  @override
  String fileError(String context) => 'Errore file: $context';

  @override
  String permissionError(String permissionType) =>
      'Permesso $permissionType necessario per continuare l\'operazione';
}
