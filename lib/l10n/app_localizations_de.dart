import 'app_localizations.dart';

/// German localization
class AppLocalizationsDe extends AppLocalizations {
  @override
  String get appName => 'Icy Easy Send';

  @override
  String get appVersion => 'Version';

  @override
  String get navHome => 'Startseite';

  @override
  String get navHistory => 'Verlauf';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get homeTitle => 'Startseite';

  @override
  String get serverStatus => 'Serverstatus';

  @override
  String get serverRunning => 'Läuft';

  @override
  String get serverStopped => 'Gestoppt';

  @override
  String get serverAddress => 'Serveradresse';

  @override
  String get deviceName => 'Gerätename';

  @override
  String get storageSpace => 'Speicherplatz';

  @override
  String get availableSpace => 'Verfügbarer Speicher';

  @override
  String get sendFiles => 'Dateien senden';

  @override
  String get receiveFiles => 'Dateien empfangen';

  @override
  String get selectFiles => 'Dateien auswählen';

  @override
  String get selectFolder => 'Ordner auswählen';

  @override
  String get dragDropHint => 'Dateien hierher ziehen';

  @override
  String get noFilesSelected => 'Keine Dateien ausgewählt';

  @override
  String filesSelected(int count) =>
      '$count Datei${count > 1 ? 'en' : ''} ausgewählt';

  @override
  String get clearSelection => 'Auswahl löschen';

  @override
  String get startSending => 'Senden starten';

  @override
  String get sending => 'Wird gesendet';

  @override
  String get sendSuccess => 'Erfolgreich gesendet';

  @override
  String get sendFailed => 'Senden fehlgeschlagen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get historyTitle => 'Übertragungsverlauf';

  @override
  String get noHistory => 'Kein Verlauf';

  @override
  String get clearHistory => 'Verlauf löschen';

  @override
  String get sent => 'Gesendet';

  @override
  String get received => 'Empfangen';

  @override
  String get failed => 'Fehlgeschlagen';

  @override
  String get fileSize => 'Dateigröße';

  @override
  String get time => 'Zeit';

  @override
  String get deleteItem => 'Eintrag löschen';

  @override
  String get deleteItemConfirm =>
      'Möchten Sie diesen Eintrag wirklich löschen?';

  @override
  String get openFile => 'Datei öffnen';

  @override
  String get openFolder => 'Ordner öffnen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get general => 'Allgemein';

  @override
  String get language => 'Sprache';

  @override
  String get deviceNameSetting => 'Gerätename';

  @override
  String get editDeviceName => 'Gerätename bearbeiten';

  @override
  String get deviceNameHint => 'Gerätename eingeben';

  @override
  String get deviceNameEmpty => 'Gerätename darf nicht leer sein';

  @override
  String get port => 'Port';

  @override
  String get portHint => 'Portnummer eingeben';

  @override
  String get portInvalid => 'Ungültige Portnummer';

  @override
  String get portInUse => 'Port wird bereits verwendet';

  @override
  String get savePath => 'Speicherpfad';

  @override
  String get selectSavePath => 'Speicherpfad auswählen';

  @override
  String get savePathDesc =>
      'Empfangene Dateien werden hier gespeichert. Standardmäßig wird der System-Download-Ordner verwendet.';

  @override
  String get savePathDefaultBadge => 'Standard';

  @override
  String get savePathUnavailable => 'Speicherpfad konnte nicht ermittelt werden';

  @override
  String get savePathSavedSuccess => 'Speicherpfad erfolgreich festgelegt';

  @override
  String get savePathNotWritable =>
      'In diesen Ordner kann nicht geschrieben werden. Wählen Sie einen anderen Speicherort oder prüfen Sie die Berechtigungen.';

  @override
  String get resetSavePathToDefault => 'Standardordner verwenden';

  @override
  String get savePathResetSuccess =>
      'Auf System-Download-Ordner zurückgesetzt';

  @override
  String get autoStart => 'Autostart';

  @override
  String get autoStartDesc => 'Server beim App-Start automatisch starten';

  @override
  String get network => 'Netzwerk';

  @override
  String get networkDiagnostics => 'Netzwerkdiagnose';

  @override
  String get scanDevices => 'Geräte suchen';

  @override
  String get scanDevicesTitle => 'LAN-Geräte suchen';

  @override
  String get scanningDevices => 'Lokales Netzwerk wird gescannt...';

  @override
  String scanProgress(int scanned, int total, int found) =>
      'Gescannt $scanned/$total, $found Gerät${found == 1 ? '' : 'e'} gefunden';

  @override
  String get noDevicesFound => 'Keine Geräte gefunden';

  @override
  String get noDevicesFoundHint =>
      'Stellen Sie sicher, dass auf dem Zielgerät der Server läuft und beide Geräte im selben Netzwerk sind. Prüfen Sie AP-Isolation und Firewall.';

  @override
  String scanDevicesFound(int count) =>
      '$count Gerät${count == 1 ? '' : 'e'} gefunden';

  @override
  String get rescan => 'Erneut suchen';

  @override
  String get runDiagnostics => 'Diagnose ausführen';

  @override
  String get about => 'Über';

  @override
  String get version => 'Version';

  @override
  String get checkUpdate => 'Nach Updates suchen';

  @override
  String get feedback => 'Feedback';

  @override
  String get openSource => 'Open-Source-Lizenzen';

  @override
  String get license => 'Lizenz';

  @override
  String get permissionRequired => 'Berechtigung erforderlich';

  @override
  String get permissionDenied => 'Berechtigung verweigert';

  @override
  String get permissionPermanentlyDenied => 'Berechtigung dauerhaft verweigert';

  @override
  String get permissionStorage => 'Speicherberechtigung';

  @override
  String get permissionStorageDesc =>
      'Speicherberechtigung ist erforderlich, um Dateien zu speichern und zu lesen';

  @override
  String get permissionNotification => 'Benachrichtigungsberechtigung';

  @override
  String get permissionNotificationDesc =>
      'Benachrichtigungsberechtigung ist erforderlich, um den Übertragungsfortschritt anzuzeigen';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get permissionWarning =>
      'Einige Berechtigungen wurden nicht erteilt, einige Funktionen können eingeschränkt sein';

  @override
  String get error => 'Fehler';

  @override
  String get errorUnknown => 'Unbekannter Fehler';

  @override
  String get errorNetwork => 'Netzwerkfehler';

  @override
  String get errorFileNotFound => 'Datei nicht gefunden';

  @override
  String get errorPermission => 'Berechtigungsfehler';

  @override
  String get errorStorage => 'Speicherfehler';

  @override
  String get errorServer => 'Serverfehler';

  @override
  String get errorServerStart => 'Server konnte nicht gestartet werden';

  @override
  String get errorServerStop => 'Server konnte nicht gestoppt werden';

  @override
  String get errorConnection => 'Verbindungsfehler';

  @override
  String get errorTimeout => 'Verbindungszeitüberschreitung';

  @override
  String get retry => 'Wiederholen';

  @override
  String get copied => 'Kopiert';

  @override
  String get copyFailed => 'Kopieren fehlgeschlagen';

  @override
  String get saved => 'Gespeichert';

  @override
  String get saveFailed => 'Speichern fehlgeschlagen';

  @override
  String get deleted => 'Gelöscht';

  @override
  String get deleteFailed => 'Löschen fehlgeschlagen';

  @override
  String get loading => 'Wird geladen';

  @override
  String get success => 'Erfolg';

  @override
  String get warning => 'Warnung';

  @override
  String get info => 'Information';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Schließen';

  @override
  String get selectFilesFailed => 'Dateien konnten nicht ausgewählt werden';

  @override
  String get selectFolderFailed => 'Ordner konnte nicht ausgewählt werden';

  @override
  String folderFilesAdded(int count) =>
      '$count Dateien aus dem Ordner hinzugefügt';

  @override
  String get folderContainsNoFiles =>
      'Der ausgewählte Ordner enthält keine Dateien zum Senden';

  @override
  String get openFileFailed => 'Datei konnte nicht geöffnet werden';

  @override
  String get openFolderFailed => 'Ordner konnte nicht geöffnet werden';

  @override
  String get fileNotExist => 'Datei existiert nicht';

  @override
  String get folderNotExist => 'Ordner existiert nicht';

  @override
  String get diagnosticsTitle => 'Netzwerkdiagnose';

  @override
  String get diagnosticsRunning => 'Diagnose läuft...';

  @override
  String get diagnosticsComplete => 'Diagnose abgeschlossen';

  @override
  String get diagnosticsFailed => 'Diagnose fehlgeschlagen';

  @override
  String get networkStatus => 'Netzwerkstatus';

  @override
  String get wifiConnected => 'WiFi verbunden';

  @override
  String get wifiDisconnected => 'WiFi getrennt';

  @override
  String get mobileData => 'Mobile Daten';

  @override
  String get noConnection => 'Keine Verbindung';

  @override
  String get ipAddress => 'IP-Adresse';

  @override
  String get noIpAddress => 'Keine IP-Adresse';

  @override
  String get serverStatusCheck => 'Serverstatusüberprüfung';

  @override
  String get portCheck => 'Portüberprüfung';

  @override
  String get portAvailable => 'Port verfügbar';

  @override
  String get portUnavailable => 'Port nicht verfügbar';

  @override
  String get suggestions => 'Vorschläge';

  @override
  String get syncClipboard => 'Zwischenablage synchronisieren';

  @override
  String filesCount(int count) => '$count Datei${count > 1 ? 'en' : ''} senden';

  @override
  String get sendFile => 'Datei senden';

  @override
  String get releaseToAdd => 'Loslassen, um Dateien hinzuzufügen';

  @override
  String get serverNotRunning =>
      'Server läuft nicht, kann keine freigegebenen Dateien empfangen';

  @override
  String get cannotReceiveFiles => 'Kann keine Dateien empfangen';

  @override
  String get sendingInProgress =>
      'Dateiübertragung läuft, bitte später versuchen';

  @override
  String get pleaseTryLater => 'Bitte später versuchen';

  @override
  String filesAdded(int count) =>
      '$count freigegebene Datei${count > 1 ? 'en' : ''} hinzugefügt';

  @override
  String get preparingSend => 'Senden wird vorbereitet...';

  @override
  String get transferring => 'Wird übertragen';

  @override
  String transferProgress(int current, int total, String fileName) =>
      '[$current/$total] $fileName: Wird übertragen...';

  @override
  String get networkChanged => 'Netzwerk geändert, Serveradresse aktualisiert';

  @override
  String get serverAddressUpdated => 'Serveradresse aktualisiert';

  @override
  String get portCannotBeEmpty => 'Port darf nicht leer sein';

  @override
  String get portMustBeNumber => 'Port muss eine Zahl sein';

  @override
  String get portRange => 'Portbereich: 1-65535';

  @override
  String ipDeleted(String ip) => 'IP gelöscht: $ip';

  @override
  String get runningDiagnostics => 'Netzwerkdiagnose wird ausgeführt...';

  @override
  String get targetDeviceInfo => 'Zielgerät-Info';

  @override
  String get fullAddress => 'Vollständige Adresse';

  @override
  String get targetNotSet => 'Zielgerät nicht festgelegt';

  @override
  String get diagnosticsReport => 'Netzwerkdiagnosebericht';

  @override
  String get reportCopied => 'Diagnosebericht in Zwischenablage kopiert';

  @override
  String get deviceNameCannotBeEmpty => 'Gerätename darf nicht leer sein';

  @override
  String get deviceNameSaved => 'Gerätename gespeichert';

  @override
  String get resetDeviceName => 'Gerätename zurücksetzen';

  @override
  String resetDeviceNameConfirm(String model) =>
      'Möchten Sie den Gerätenamen wirklich auf "$model" zurücksetzen?';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get confirmChange => 'Änderung bestätigen';

  @override
  String concurrentTransfersChange(int from, int to) =>
      'Gleichzeitige Übertragungen von $from auf $to ändern?\n\nHinweis: ${to > from ? "Erhöhung kann die Geschwindigkeit verbessern, aber die Gerätelast erhöhen" : "Verringerung kann die Gerätelast reduzieren, aber die Geschwindigkeit verringern"}';

  @override
  String get concurrentTransfersHint =>
      'Hinweis zu gleichzeitigen Übertragungen';

  @override
  String get concurrentTransfersSaved =>
      'Gleichzeitige Übertragungen gespeichert';

  @override
  String get enterValidNumber => 'Bitte gültige Zahl eingeben';

  @override
  String historyCountRange(int min, int max) =>
      'Verlaufsanzahl-Bereich: $min-$max';

  @override
  String maxHistoryChange(int from, int to) =>
      'Maximale Verlaufseinträge von $from auf $to ändern?\n\n';

  @override
  String currentHistoryCount(int count) =>
      'Aktuelle Verlaufsanzahl: $count Einträge\n\n';

  @override
  String get historyWarning =>
      '⚠️ Warnung: Aktuelle Verlaufsanzahl überschreitet das neue Limit.\n\n';

  @override
  String historyDeleteWarning(int current, int max, int toDelete) =>
      'Nur die neuesten $max Einträge werden behalten, $toDelete alte Einträge werden gelöscht.';

  @override
  String get historyHint =>
      'Hinweis: Neue Einstellung wird beim nächsten Speichern wirksam.';

  @override
  String historyDeleted(int count) =>
      'Einstellungen gespeichert, $count alte Einträge gelöscht';

  @override
  String get maxHistorySaved => 'Maximale Verlaufseinträge gespeichert';

  @override
  String clipboardSizeRange(int min, int max) =>
      'Zwischenablage-Größenbereich: $min-$max MB';

  @override
  String maxClipboardSizeChange(int from, int to) =>
      'Maximale Zwischenablage-Größe von $from MB auf $to MB ändern?\n\n';

  @override
  String get clipboardSizeDecreaseHint =>
      '⚠️ Hinweis: Nach der Verringerung können Zwischenablage-Inhalte, die das Limit überschreiten, nicht synchronisiert werden. Verwenden Sie stattdessen die Dateiübertragung.';

  @override
  String get clipboardSizeIncreaseHint =>
      'Hinweis: Nach der Erhöhung können größere Zwischenablage-Inhalte synchronisiert werden, dies kann jedoch die Übertragungsgeschwindigkeit beeinträchtigen.';

  @override
  String get maxClipboardSizeSaved =>
      'Maximale Zwischenablage-Größe gespeichert';

  @override
  String get ipValidationEnabled => 'IP-Validierung aktiviert';

  @override
  String get ipValidationDisabled => 'IP-Validierung deaktiviert';

  @override
  String get deviceSecretKeyCleared => 'Geräte-Geheimschlüssel gelöscht';

  @override
  String get deviceSecretKeySaved => 'Geräte-Geheimschlüssel gespeichert';

  @override
  String get loadingDevInfo => 'Entwicklerinformationen werden geladen...';

  @override
  String get copyLog => 'Protokoll kopieren';

  @override
  String logCopied(int lines) =>
      'Letzte $lines Zeilen des Protokolls in Zwischenablage kopiert';

  @override
  String get logFileEmpty => 'Protokolldatei ist leer';

  @override
  String get devInfo => 'Entwicklerinformationen';

  @override
  String labelCopied(String label, String value) => '$label kopiert: $value';

  @override
  String get transferSettings => 'Übertragungseinstellungen';

  @override
  String get concurrentTransfers => 'Gleichzeitige Übertragungen';

  @override
  String concurrentTransfersDesc(int max) =>
      'Anzahl gleichzeitiger Dateiübertragungen (1-$max)';

  @override
  String get concurrentTransfersHintText =>
      'Höhere Parallelität kann die Bandbreite besser nutzen, aber die Gerätelast erhöhen';

  @override
  String get maxHistory => 'Maximale Verlaufseinträge';

  @override
  String maxHistoryDesc(int min, int max) =>
      'Maximale Anzahl zu speichernder Übertragungseinträge ($min-$max)';

  @override
  String maxHistoryHintText(int min, int max) => 'Anzahl eingeben ($min-$max)';

  @override
  String get oldRecordsAutoDelete =>
      'Alte Einträge, die das Limit überschreiten, werden automatisch gelöscht, nur die neuesten werden behalten';

  @override
  String get maxClipboard => 'Maximale Zwischenablage-Größe';

  @override
  String maxClipboardDesc(int min, int max) =>
      'Maximal zulässige Zwischenablage-Größe für Synchronisierung ($min-$max MB)';

  @override
  String maxClipboardHintText(int min, int max) =>
      'Größe eingeben ($min-$max MB)';

  @override
  String get clipboardSyncLimit =>
      'Zwischenablage-Inhalte, die diese Größe überschreiten, können nicht synchronisiert werden, verwenden Sie stattdessen die Dateiübertragung';

  @override
  String get ipValidation => 'IP-Validierung';

  @override
  String get ipValidationDesc =>
      'Überprüfen, ob die IP des Zielgeräts im selben Subnetz ist';

  @override
  String get ipValidationEnabledHint =>
      'Wenn aktiviert, wird überprüft, ob die Ziel-IP im selben Subnetz ist, um Verbindungen zu falschen Geräten zu vermeiden';

  @override
  String get ipValidationDisabledHint =>
      'Wenn deaktiviert, wird das IP-Subnetz nicht überprüft, geeignet für komplexe Netzwerkumgebungen (Hotspot, VPN usw.)';

  @override
  String get deviceSecretKey => 'Geräte-Geheimschlüssel';

  @override
  String get deviceSecretKeyDesc =>
      'Wenn festgelegt, müssen andere Geräte den richtigen Schlüssel angeben, um die Bestätigung zu überspringen';

  @override
  String get deviceSecretKeyHint =>
      'Geheimschlüssel eingeben (leer lassen zum Deaktivieren)';

  @override
  String get notSet => 'Nicht festgelegt';

  @override
  String get author => 'Autor';

  @override
  String get appDescription =>
      'Ein einfaches und benutzerfreundliches LAN-Dateiübertragungstool';

  @override
  String get targetDeviceIP => 'IP-Adresse des Zielgeräts';

  @override
  String get ipHint => 'z.B.: 192.168.1.100';

  @override
  String get clear => 'Löschen';

  @override
  String get history => 'Verlauf';

  @override
  String get targetDevicePort => 'Port des Zielgeräts';

  @override
  String resetToDefaultPort(int port) =>
      'Auf Standardport zurücksetzen ($port)';

  @override
  String get targetDeviceSecretKey =>
      'Geheimschlüssel des Zielgeräts (Optional)';

  @override
  String get secretKeyHint =>
      'Richtiger Schlüssel kann Bestätigung überspringen';

  @override
  String get aboutSecretKey => 'Über Geheimschlüssel';

  @override
  String get secretKeyFeatureTitle => 'Geheimschlüssel-Funktion';

  @override
  String get secretKeyFeatureDesc =>
      'Wenn das Zielgerät einen Geheimschlüssel festgelegt hat, können Sie durch Eingabe des richtigen Schlüssels den Bestätigungsdialog überspringen und direkt Dateien übertragen oder die Zwischenablage synchronisieren.';

  @override
  String get secretKeyUsageSteps => 'Verwendungsschritte:';

  @override
  String get secretKeyUsageStep1 =>
      '1. Zielgerät legt seinen Geheimschlüssel in den Einstellungen fest';

  @override
  String get secretKeyUsageStep2 =>
      '2. Geben Sie den Geheimschlüssel des Zielgeräts in dieses Feld ein';

  @override
  String get secretKeyUsageStep3 =>
      '3. Beim Senden von Dateien oder Anfordern der Zwischenablage wird die andere Partei automatisch akzeptieren, wenn der Schlüssel korrekt ist';

  @override
  String get secretKeyTip =>
      'Tipp: Leer lassen, um die traditionelle manuelle Bestätigung zu verwenden';

  @override
  String get secretKeyDescription => 'Geheimschlüssel-Beschreibung';

  @override
  String get clearSecretKey => 'Geheimschlüssel löschen';

  @override
  String get gotIt => 'Verstanden';

  @override
  String get localIP => 'Lokale IP';

  @override
  String ipCopied(String ip) => 'IP-Adresse kopiert: $ip';

  @override
  String get transferred => 'Übertragen';

  @override
  String get transferSpeed => 'Übertragungsgeschwindigkeit';

  @override
  String get remainingTime => 'Verbleibende Zeit';

  @override
  String transferringProgress(double progress) =>
      'Wird übertragen ${progress.toStringAsFixed(1)}%';

  @override
  String get storagePermissionMessage =>
      'Speicherberechtigung ist erforderlich, um Dateien auszuwählen. Bitte aktivieren Sie sie manuell in den Einstellungen.';

  @override
  String get checkingTargetDevice => 'Zielgerät wird überprüft...';

  @override
  String get targetDeviceUnavailable => 'Zielgerät nicht verfügbar';

  @override
  String targetDeviceError(String error) =>
      'Zielgerät nicht verfügbar\nFehler: $error';

  @override
  String get connectionFailed => 'Verbindung fehlgeschlagen';

  @override
  String get transferHistory => 'Übertragungsverlauf';

  @override
  String get clearHistoryTitle => 'Verlauf löschen';

  @override
  String get clearHistoryMessage =>
      'Möchten Sie wirklich den gesamten Übertragungsverlauf löschen? Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get noFilteredRecords => 'Keine übereinstimmenden Einträge';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterSent => 'Gesendet';

  @override
  String get filterReceived => 'Empfangen';

  @override
  String get statisticsInfo => 'Statistiken';

  @override
  String transfersCount(int count) =>
      '$count Übertragung${count > 1 ? 'en' : ''}';

  @override
  String get totalTransfers => 'Gesamt';

  @override
  String get successfulTransfers => 'Erfolg';

  @override
  String get failedTransfers => 'Fehlgeschlagen';

  @override
  String get sentFiles => 'Gesendet';

  @override
  String get receivedFiles => 'Empfangen';

  @override
  String get totalSize => 'Gesamtgröße';

  @override
  String get moreActions => 'Weitere Aktionen';

  @override
  String get viewDetails => 'Details anzeigen';

  @override
  String get deleteRecord => 'Eintrag löschen';

  @override
  String get deleteRecordTitle => 'Eintrag löschen';

  @override
  String deleteRecordMessage(String fileName) =>
      'Möchten Sie wirklich den Übertragungseintrag für "$fileName" löschen?\n\nHinweis: Dies löscht nur den Eintrag, nicht die Datei selbst.';

  @override
  String get deleteRecordNote =>
      'Hinweis: Dies löscht nur den Eintrag, nicht die Datei selbst.';

  @override
  String get recordDeleted => 'Eintrag gelöscht';

  @override
  String get filePathNotExist => 'Dateipfad existiert nicht';

  @override
  String get cannotOpenFile => 'Datei kann nicht geöffnet werden';

  @override
  String cannotOpenFileWithMessage(String message) =>
      'Datei kann nicht geöffnet werden: $message';

  @override
  String get iosNoFolderSupport =>
      'iOS unterstützt das direkte Öffnen von Ordnern nicht';

  @override
  String get cannotOpenFolder => 'Ordner kann nicht geöffnet werden';

  @override
  String get recentFilesOpened =>
      'Zuletzt verwendete Dateien geöffnet, bitte manuell suchen';

  @override
  String get receiveRecord => 'Empfangseintrag';

  @override
  String get sendRecord => 'Sendeeintrag';

  @override
  String get fileName => 'Dateiname';

  @override
  String get fromDevice => 'Von Gerät';

  @override
  String get toDevice => 'An Gerät';

  @override
  String get deviceIP => 'Geräte-IP';

  @override
  String get transferTime => 'Übertragungszeit';

  @override
  String get transferStatus => 'Übertragungsstatus';

  @override
  String get statusSuccess => 'Erfolg';

  @override
  String get statusFailed => 'Fehlgeschlagen';

  @override
  String get savedLocation => 'Gespeicherter Ort';

  @override
  String get copy => 'Kopieren';

  @override
  String get pathCopied => 'Pfad in Zwischenablage kopiert';

  @override
  String get from => 'Von';

  @override
  String get sentTo => 'Gesendet an';

  // Clipboard related
  @override
  String get clipboardRequest => 'Zwischenablage-Anfrage';

  @override
  String clipboardRequestFrom(String deviceName) =>
      'Gerät "$deviceName" fordert Zugriff auf Ihre Zwischenablage an';

  @override
  String get allowClipboardRequest => 'Diese Anfrage erlauben?';

  @override
  String get clipboardRequestMessage => 'Zwischenablage-Anfrage';

  @override
  String autoRejectIn(int seconds) =>
      'Automatische Ablehnung in $seconds Sekunden';

  @override
  String get reject => 'Ablehnen';

  @override
  String get allow => 'Erlauben';

  @override
  String clipboardSharedWithSecretKey(String deviceName) =>
      '$deviceName mit Geheimschlüssel verifiziert, Zwischenablage automatisch geteilt';

  @override
  String get clipboardRequestRejected =>
      'Benutzer hat Zwischenablage-Anfrage abgelehnt';

  @override
  String get clipboardEmpty => 'Zwischenablage ist leer';

  @override
  String clipboardContentTooLarge(double actualSizeMB, int maxSizeMB) =>
      'Zwischenablage-Inhalt zu groß (${actualSizeMB.toStringAsFixed(2)} MB), überschreitet das Limit des Empfängergeräts ($maxSizeMB MB). Bitte verwenden Sie stattdessen die Dateiübertragung.';

  @override
  String get clipboardContentSuccess =>
      'Zwischenablage-Inhalt erfolgreich abgerufen';

  @override
  String get invalidJsonFormat => 'Ungültiges JSON-Format';

  @override
  String get serverInternalError => 'Interner Serverfehler';

  // Clipboard sync
  @override
  String get requestingClipboard => 'Zwischenablage wird angefordert...';

  @override
  String get clipboardSyncSuccess =>
      'Zwischenablage erfolgreich synchronisiert';

  @override
  String get textClipboardSyncSuccess =>
      'Text-Zwischenablage erfolgreich synchronisiert';

  @override
  String get fileClipboardSyncSuccess =>
      'Datei-Zwischenablage erfolgreich synchronisiert\nSie können in der App oder im Dateimanager einfügen';

  @override
  String get clipboardSyncFailed =>
      'Zwischenablage-Synchronisierung fehlgeschlagen';

  @override
  String get syncFailed => 'Synchronisierung fehlgeschlagen';

  @override
  String clipboardRequestError(String error) =>
      'Fehler beim Anfordern der Zwischenablage: $error';

  // File transfer
  @override
  String invalidFilesMessage(String fileNames) =>
      'Die folgenden Dateien sind ungültig oder nicht zugänglich:\n$fileNames';

  @override
  String get waitingForReceiverConfirmation =>
      'Warte auf Bestätigung des Empfängers...';

  @override
  String get fileSendSuccess => 'Datei erfolgreich gesendet!';

  @override
  String filesSendSuccess(int count) => '$count Dateien erfolgreich gesendet!';

  @override
  String get allFilesSendFailed => 'Alle Dateien konnten nicht gesendet werden';

  @override
  String get failedFiles => 'Fehlgeschlagene Dateien';

  @override
  String get transferComplete => 'Übertragung abgeschlossen';

  @override
  String get successCount => 'Erfolg';

  @override
  String get failureCount => 'Fehlgeschlagen';

  @override
  String transferSummary(
    int successCount,
    int failureCount,
    String failedFiles,
  ) =>
      'Erfolg: $successCount Dateien\nFehlgeschlagen: $failureCount Dateien\n\nFehlgeschlagene Dateien:\n$failedFiles';

  // Batch transfer status
  @override
  String get preparingTransferInfo => 'Übertragungsinfo wird vorbereitet...';

  @override
  String waitingForReceiverConfirmFiles(int count) =>
      'Warte auf Bestätigung des Empfängers für $count Dateien...';

  @override
  String transferringFile(int current, int total, String fileName) =>
      'Übertrage Datei $current/$total: $fileName';

  @override
  String get receiverRejected => 'Empfänger hat abgelehnt';

  @override
  String receiverRejectedWithStatus(int statusCode) =>
      'Empfänger hat abgelehnt\nStatuscode: $statusCode';

  @override
  String get transferIdNotFound => 'Übertragungs-ID nicht gefunden';

  // Batch receive
  @override
  String get waitingForConfirmation => 'Warte auf Bestätigung...';

  @override
  String get preparingToReceive => 'Empfang wird vorbereitet...';

  @override
  String get rejected => 'Abgelehnt';

  @override
  String get receiveComplete => 'Empfang abgeschlossen';

  @override
  String receivingProgress(double progress) =>
      'Empfange... ${progress.toStringAsFixed(1)}%';

  @override
  String receivingFiles(int count) => 'Empfange $count Dateien';

  @override
  String receiveFilesCount(int count) => '$count Dateien empfangen';

  @override
  String get sender => 'Absender';

  @override
  String get totalSizeBatch => 'Gesamtgröße';

  @override
  String get fileList => 'Dateiliste';

  @override
  String get allFilesReceiveComplete => 'Alle Dateien erfolgreich empfangen!';

  @override
  String get receivingFiles2 => 'Empfange Dateien...';

  @override
  String autoRejectCountdown(int seconds) =>
      'Diese Dateien akzeptieren? (Automatische Ablehnung in $seconds Sekunden)';

  @override
  String get rejectAll => 'Alle ablehnen';

  @override
  String get acceptAll => 'Alle akzeptieren';

  // Network diagnostics
  @override
  String get networkDiagnosticsReport => 'Netzwerkdiagnosebericht';

  @override
  String get localNetworkInterfaces => 'Lokale Netzwerkschnittstellen';

  @override
  String get noValidNetworkInterface =>
      'Keine gültige Netzwerkschnittstelle gefunden';

  @override
  String get privateNetworkAddress => 'Private Netzwerkadresse';

  @override
  String get targetDeviceReachability => 'Erreichbarkeit des Zielgeräts';

  @override
  String get canConnectToTarget => 'Kann sich mit Zielgerät verbinden';

  @override
  String get cannotConnectToTarget => 'Kann sich nicht mit Zielgerät verbinden';

  @override
  String get healthCheckTest => 'Gesundheitscheck-Test';

  @override
  String get healthCheckSuccess => 'Gesundheitscheck erfolgreich';

  @override
  String get healthCheckFailed => 'Gesundheitscheck fehlgeschlagen';

  @override
  String get statusCode => 'Statuscode';

  @override
  String get response => 'Antwort';

  @override
  String get internetConnection => 'Internetverbindung';

  @override
  String get hasInternetConnection => 'Hat Internetverbindung';

  @override
  String get noInternetConnection => 'Keine Internetverbindung';

  // Error messages
  @override
  String get networkConnectionFailed =>
      'Verbindung zum Zielgerät nicht möglich, bitte überprüfen Sie die Netzwerkverbindung und IP-Adresse';

  @override
  String get networkTimeout =>
      'Verbindungszeitüberschreitung, Zielgerät ist möglicherweise offline oder das Netzwerk ist instabil';

  @override
  String get networkRequestFailed =>
      'Netzwerkanfrage fehlgeschlagen, bitte überprüfen Sie die Netzwerkverbindung';

  @override
  String get transferTimeout =>
      'Übertragungszeitüberschreitung, bitte überprüfen Sie die Netzwerkverbindung';

  @override
  String get transferInterrupted =>
      'Übertragung unterbrochen, bitte erneut versuchen';

  @override
  String get fileNotFound => 'Datei nicht gefunden';

  @override
  String get fileNotReadable =>
      'Datei kann nicht gelesen werden, bitte stellen Sie sicher, dass die Datei existiert und Zugriffsrechte vorhanden sind';

  @override
  String get fileAccessError =>
      'Dateizugriffsfehler, bitte überprüfen Sie die Dateiberechtigungen';

  @override
  String get fileSaveFailed => 'Speichern der Datei fehlgeschlagen';

  @override
  String get fileSizeMismatch =>
      'Speichern der Datei fehlgeschlagen: Dateigrößen stimmen nicht überein';

  @override
  String get invalidFileName => 'Dateiname enthält ungültige Zeichen';

  @override
  String get downloadsDirectoryUnavailable =>
      'Zugriff auf Download-Verzeichnis nicht möglich';

  @override
  String get storageInsufficient =>
      'Unzureichender Speicherplatz, Datei kann nicht empfangen werden';

  @override
  String get storageCheckFailed => 'Speicherplatz kann nicht überprüft werden';

  @override
  String get networkPermissionDenied =>
      'Netzwerkzugriffsberechtigung erforderlich, um Dateien zu übertragen';

  @override
  String get storagePermissionDenied =>
      'Speicherzugriffsberechtigung erforderlich, um Dateien zu speichern';

  @override
  String serverStartFailed(String reason) =>
      'Server kann nicht gestartet werden: $reason';

  @override
  String get serverPortsOccupied =>
      'Server kann nicht gestartet werden: Alle Ports sind belegt';

  @override
  String serverPortsOccupiedRange(int defaultPort, int maxPort) =>
      'Server kann nicht gestartet werden: Ports $defaultPort-$maxPort sind alle belegt';

  @override
  String get serverUnknownError =>
      'Server kann nicht gestartet werden: Unbekannter Fehler';

  @override
  String get transferRejected => 'Übertragung vom Empfänger abgelehnt';

  @override
  String get fileTooLarge => 'Datei zu groß, maximal 2GB unterstützt';

  @override
  String get fileOrStorageFull =>
      'Datei zu groß oder Speicherplatz des Empfängers unzureichend';

  @override
  String get receiveTimeout =>
      'Empfangszeitüberschreitung, automatisch abgelehnt';

  @override
  String get userRejected => 'Benutzer hat Dateiübertragung abgelehnt';

  @override
  String get ipAddressEmpty => 'IP-Adresse darf nicht leer sein';

  @override
  String get ipAddressInvalidFormat =>
      'Ungültiges IP-Adressformat, bitte verwenden Sie das Format xxx.xxx.xxx.xxx';

  @override
  String get ipAddressInvalidRange =>
      'Ungültiges IP-Adressformat, jede Zahl muss zwischen 0-255 liegen';

  @override
  String get ipAddressSpecial1 =>
      '0.0.0.0 kann nicht als Zieladresse verwendet werden';

  @override
  String get ipAddressSpecial2 =>
      'Broadcast-Adresse 255.255.255.255 kann nicht verwendet werden';

  @override
  String ipAddressNotInSameSubnet(
    String localIP,
    String targetIP,
    String localNetwork,
    String targetNetwork,
  ) =>
      '⚠️ Subnetz-Nichtübereinstimmung\n'
      'Lokale IP: $localIP (Subnetz: $localNetwork.x)\n'
      'Ziel-IP: $targetIP (Subnetz: $targetNetwork.x)\n'
      '\n'
      'Hinweis: Beide Geräte müssen sich im selben LAN (gleiches Subnetz) befinden, um Dateien zu übertragen.\n'
      'Bei IPv4-Adressen der Klasse C sollten die ersten drei Zahlen gleich sein, z.B. beide 192.168.2, nur die letzte Zahl unterscheidet sich\n'
      'Der einfachste Weg ist, beide Geräte mit demselben WLAN oder Router zu verbinden.\n';

  @override
  String get responseParseError => 'Serverantwort kann nicht geparst werden';

  @override
  String get responseInvalidFormat =>
      'Antwortformat des Zielgeräts ist inkorrekt';

  @override
  String responseStatusCodeError(int statusCode) =>
      'Server hat Fehlerstatuscode zurückgegeben: $statusCode';

  @override
  String get fileSelectionError => 'Fehler beim Auswählen der Datei';

  @override
  String get fileSelectionCancelled => 'Dateiauswahl abgebrochen';

  @override
  String genericError(String operation) => '$operation fehlgeschlagen';

  @override
  String unexpectedError(String details) =>
      'Unerwarteter Fehler aufgetreten: $details';

  @override
  String networkError(String context) => 'Netzwerkfehler: $context';

  @override
  String fileError(String context) => 'Dateifehler: $context';

  @override
  String permissionError(String permissionType) =>
      '$permissionType-Berechtigung erforderlich, um fortzufahren';
}
