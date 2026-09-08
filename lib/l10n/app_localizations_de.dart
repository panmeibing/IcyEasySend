// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

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
  String filesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien ausgewählt',
      one: '$count Datei ausgewählt',
    );
    return '$_temp0';
  }

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
  String get savePathUnavailable =>
      'Speicherpfad konnte nicht ermittelt werden';

  @override
  String get savePathSavedSuccess => 'Speicherpfad erfolgreich festgelegt';

  @override
  String get savePathNotWritable =>
      'In diesen Ordner kann nicht geschrieben werden. Wählen Sie einen anderen Speicherort oder prüfen Sie die Berechtigungen.';

  @override
  String get resetSavePathToDefault => 'Standardordner verwenden';

  @override
  String get savePathResetSuccess => 'Auf System-Download-Ordner zurückgesetzt';

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
  String scanProgress(int scanned, int total, int found) {
    String _temp0 = intl.Intl.pluralLogic(
      found,
      locale: localeName,
      other: 'Gescannt $scanned/$total, $found Geräte gefunden',
      one: 'Gescannt $scanned/$total, $found Gerät gefunden',
    );
    return '$_temp0';
  }

  @override
  String get noDevicesFound => 'Keine Geräte gefunden';

  @override
  String get noDevicesFoundHint =>
      'Stellen Sie sicher, dass auf dem Zielgerät der Server läuft und beide Geräte im selben Netzwerk sind. Prüfen Sie AP-Isolation und Firewall.';

  @override
  String scanDevicesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Geräte gefunden',
      one: '$count Gerät gefunden',
    );
    return '$_temp0';
  }

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
  String folderFilesAdded(int count) {
    return '$count Dateien aus dem Ordner hinzugefügt';
  }

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
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien senden',
      one: '$count Datei senden',
    );
    return '$_temp0';
  }

  @override
  String get sendFile => 'Datei senden';

  @override
  String get shareViaQr => 'Per QR teilen';

  @override
  String get webShareTitle => 'Scannen zum Empfangen';

  @override
  String get webShareHint =>
      'Der Empfänger scannt mit der Systemkamera und lädt im Browser herunter — ohne App-Installation. Bleiben Sie im selben Wi‑Fi / LAN. Manche Drittanbieter-Scanner blockieren LAN-Links; nutzen Sie Link kopieren.';

  @override
  String get webShareCopyLink => 'Link kopieren';

  @override
  String get webShareLinkCopied => 'Link kopiert';

  @override
  String get webShareStopSharing => 'Teilen beenden';

  @override
  String get webShareStopped => 'Web-Freigabe beendet';

  @override
  String get webShareServerRequired =>
      'Starten Sie den lokalen Server, bevor Sie per QR teilen';

  @override
  String get webShareCreated =>
      'Web-Freigabe erstellt. Der Empfänger kann scannen und herunterladen.';

  @override
  String get webShareFailed => 'Web-Freigabe konnte nicht erstellt werden';

  @override
  String get webSharePeerName => 'Web-Freigabe';

  @override
  String webShareFilesSummary(int count, String size) {
    return '$count Datei(en) · $size';
  }

  @override
  String webShareExpiresIn(String time) {
    return 'Läuft ab in $time';
  }

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
  String filesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count freigegebene Dateien hinzugefügt',
      one: '$count freigegebene Datei hinzugefügt',
    );
    return '$_temp0';
  }

  @override
  String get preparingSend => 'Senden wird vorbereitet...';

  @override
  String get transferring => 'Wird übertragen';

  @override
  String transferProgress(int current, int total, String fileName) {
    return '[$current/$total] $fileName: Wird übertragen...';
  }

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
  String ipDeleted(String ip) {
    return 'IP gelöscht: $ip';
  }

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
  String resetDeviceNameConfirm(String model) {
    return 'Möchten Sie den Gerätenamen wirklich auf \"$model\" zurücksetzen?';
  }

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get confirmChange => 'Änderung bestätigen';

  @override
  String concurrentTransfersIncrease(int from, int to) {
    return 'Gleichzeitige Übertragungen von $from auf $to ändern?\n\nHinweis: Erhöhung kann die Geschwindigkeit verbessern, aber die Gerätelast erhöhen';
  }

  @override
  String concurrentTransfersDecrease(int from, int to) {
    return 'Gleichzeitige Übertragungen von $from auf $to ändern?\n\nHinweis: Verringerung kann die Gerätelast reduzieren, aber die Geschwindigkeit verringern';
  }

  @override
  String get concurrentTransfersHint =>
      'Hinweis zu gleichzeitigen Übertragungen';

  @override
  String get concurrentTransfersSaved =>
      'Gleichzeitige Übertragungen gespeichert';

  @override
  String get enterValidNumber => 'Bitte gültige Zahl eingeben';

  @override
  String historyCountRange(int min, int max) {
    return 'Verlaufsanzahl-Bereich: $min-$max';
  }

  @override
  String maxHistoryChange(int from, int to) {
    return 'Maximale Verlaufseinträge von $from auf $to ändern?\n\n';
  }

  @override
  String currentHistoryCount(int count) {
    return 'Aktuelle Verlaufsanzahl: $count Einträge\n\n';
  }

  @override
  String get historyWarning =>
      '⚠️ Warnung: Aktuelle Verlaufsanzahl überschreitet das neue Limit.\n\n';

  @override
  String historyDeleteWarning(int current, int max, int toDelete) {
    return 'Nur die neuesten $max Einträge werden behalten, $toDelete alte Einträge werden gelöscht.';
  }

  @override
  String get historyHint =>
      'Hinweis: Neue Einstellung wird beim nächsten Speichern wirksam.';

  @override
  String historyDeleted(int count) {
    return 'Einstellungen gespeichert, $count alte Einträge gelöscht';
  }

  @override
  String get maxHistorySaved => 'Maximale Verlaufseinträge gespeichert';

  @override
  String clipboardSizeRange(int min, int max) {
    return 'Zwischenablage-Größenbereich: $min-$max MB';
  }

  @override
  String maxClipboardSizeChange(int from, int to) {
    return 'Maximale Zwischenablage-Größe von $from MB auf $to MB ändern?\n\n';
  }

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
  String logCopied(int lines) {
    return 'Letzte $lines Zeilen des Protokolls in Zwischenablage kopiert';
  }

  @override
  String get logFileEmpty => 'Protokolldatei ist leer';

  @override
  String get devInfo => 'Entwicklerinformationen';

  @override
  String labelCopied(String label, String value) {
    return '$label kopiert: $value';
  }

  @override
  String get transferSettings => 'Übertragungseinstellungen';

  @override
  String get concurrentTransfers => 'Gleichzeitige Übertragungen';

  @override
  String concurrentTransfersDesc(int max) {
    return 'Anzahl gleichzeitiger Dateiübertragungen (1-$max)';
  }

  @override
  String get concurrentTransfersHintText =>
      'Höhere Parallelität kann die Bandbreite besser nutzen, aber die Gerätelast erhöhen';

  @override
  String get maxHistory => 'Maximale Verlaufseinträge';

  @override
  String maxHistoryDesc(int min, int max) {
    return 'Maximale Anzahl zu speichernder Übertragungseinträge ($min-$max)';
  }

  @override
  String maxHistoryHintText(int min, int max) {
    return 'Anzahl eingeben ($min-$max)';
  }

  @override
  String get oldRecordsAutoDelete =>
      'Alte Einträge, die das Limit überschreiten, werden automatisch gelöscht, nur die neuesten werden behalten';

  @override
  String get maxClipboard => 'Maximale Zwischenablage-Größe';

  @override
  String maxClipboardDesc(int min, int max) {
    return 'Maximal zulässige Zwischenablage-Größe für Synchronisierung ($min-$max MB)';
  }

  @override
  String maxClipboardHintText(int min, int max) {
    return 'Größe eingeben ($min-$max MB)';
  }

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
  String get update => 'Update';

  @override
  String get github => 'GitHub';

  @override
  String get githubLinkCopied => 'GitHub-Link kopiert';

  @override
  String get openGitHubFailed =>
      'Browser konnte nicht geöffnet werden; Link stattdessen kopiert';

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
  String resetToDefaultPort(int port) {
    return 'Auf Standardport zurücksetzen ($port)';
  }

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
  String ipCopied(String ip) {
    return 'IP-Adresse kopiert: $ip';
  }

  @override
  String get transferred => 'Übertragen';

  @override
  String get transferSpeed => 'Übertragungsgeschwindigkeit';

  @override
  String get remainingTime => 'Verbleibende Zeit';

  @override
  String transferringProgress(double progress) {
    final intl.NumberFormat progressNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String progressString = progressNumberFormat.format(progress);

    return 'Wird übertragen $progressString%';
  }

  @override
  String get storagePermissionMessage =>
      'Speicherberechtigung ist erforderlich, um Dateien auszuwählen. Bitte aktivieren Sie sie manuell in den Einstellungen.';

  @override
  String get checkingTargetDevice => 'Zielgerät wird überprüft...';

  @override
  String get targetDeviceUnavailable => 'Zielgerät nicht verfügbar';

  @override
  String targetDeviceError(String error) {
    return 'Zielgerät nicht verfügbar\nFehler: $error';
  }

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
  String transfersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Übertragungen',
      one: '$count Übertragung',
    );
    return '$_temp0';
  }

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
  String get deleteRecord => 'Eintrag löschen';

  @override
  String get viewDetails => 'Details anzeigen';

  @override
  String get deleteRecordTitle => 'Eintrag löschen';

  @override
  String deleteRecordMessage(String fileName) {
    return 'Möchten Sie wirklich den Übertragungseintrag für \"$fileName\" löschen?\n\nHinweis: Dies löscht nur den Eintrag, nicht die Datei selbst.';
  }

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
  String cannotOpenFileWithMessage(String message) {
    return 'Datei kann nicht geöffnet werden: $message';
  }

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

  @override
  String get clipboardRequest => 'Zwischenablage-Anfrage';

  @override
  String clipboardRequestFrom(String deviceName) {
    return 'Gerät \"$deviceName\" fordert Zugriff auf Ihre Zwischenablage an';
  }

  @override
  String get allowClipboardRequest => 'Diese Anfrage erlauben?';

  @override
  String get clipboardRequestMessage => 'Zwischenablage-Anfrage';

  @override
  String autoRejectIn(int seconds) {
    return 'Automatische Ablehnung in $seconds Sekunden';
  }

  @override
  String get reject => 'Ablehnen';

  @override
  String get allow => 'Erlauben';

  @override
  String clipboardSharedWithSecretKey(String deviceName) {
    return '$deviceName mit Geheimschlüssel verifiziert, Zwischenablage automatisch geteilt';
  }

  @override
  String get clipboardRequestRejected =>
      'Benutzer hat Zwischenablage-Anfrage abgelehnt';

  @override
  String get clipboardEmpty => 'Zwischenablage ist leer';

  @override
  String clipboardContentTooLarge(double actualSizeMB, int maxSizeMB) {
    final intl.NumberFormat actualSizeMBNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 2,
        );
    final String actualSizeMBString = actualSizeMBNumberFormat.format(
      actualSizeMB,
    );

    return 'Zwischenablage-Inhalt zu groß ($actualSizeMBString MB), überschreitet das Limit des Empfängergeräts ($maxSizeMB MB). Bitte verwenden Sie stattdessen die Dateiübertragung.';
  }

  @override
  String get clipboardContentSuccess =>
      'Zwischenablage-Inhalt erfolgreich abgerufen';

  @override
  String get invalidJsonFormat => 'Ungültiges JSON-Format';

  @override
  String get serverInternalError => 'Interner Serverfehler';

  @override
  String get backgroundRejectNeedsSecretKey =>
      'Gerät ist im Hintergrund. Nur automatische Sync/Empfang mit passendem Geheimschlüssel wird unterstützt.';

  @override
  String get foregroundServiceNotificationTitle => 'IcyEasySend';

  @override
  String get foregroundServiceNotificationText =>
      'Wartet im Hintergrund auf Dateiübertragung und Zwischenablage-Sync';

  @override
  String get androidBackgroundReceiveHint =>
      'Im Hintergrund können nur Geräte mit passendem Geheimschlüssel automatisch synchronisieren oder senden. Behalten Sie die Dauerbenachrichtigung bei.';

  @override
  String get clipboardOverlay => 'Zwischenablage-Floating-Button';

  @override
  String get clipboardOverlayDesc =>
      'Tippen Sie auf den Floating-Button, um Text-/Bild-Cache für Hintergrund-Sync zu aktualisieren';

  @override
  String get clipboardOverlayHint =>
      'Im Hintergrund wird nur der zuletzt aktualisierte Inhalt synchronisiert. Ausschalten löscht den Cache und blendet den Button aus.';

  @override
  String get clipboardOverlayPermissionNeeded =>
      'Erlauben Sie in den Systemeinstellungen \"Über anderen Apps einblenden\". Der Button erscheint nach der Rückkehr.';

  @override
  String get clipboardOverlayEnabledToast =>
      'Zwischenablage-Floating-Button aktiviert';

  @override
  String get clipboardBackgroundCacheMiss =>
      'Zwischenablage im Hintergrund nicht lesbar und kein Cache verfügbar. App öffnen oder Floating-Button tippen zum Aktualisieren.';

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
  String clipboardRequestError(String error) {
    return 'Fehler beim Anfordern der Zwischenablage: $error';
  }

  @override
  String invalidFilesMessage(String fileNames) {
    return 'Die folgenden Dateien sind ungültig oder nicht zugänglich:\n$fileNames';
  }

  @override
  String get waitingForReceiverConfirmation =>
      'Warte auf Bestätigung des Empfängers...';

  @override
  String get fileSendSuccess => 'Datei erfolgreich gesendet!';

  @override
  String filesSendSuccess(int count) {
    return '$count Dateien erfolgreich gesendet!';
  }

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
  ) {
    return 'Erfolg: $successCount Dateien\nFehlgeschlagen: $failureCount Dateien\n\nFehlgeschlagene Dateien:\n$failedFiles';
  }

  @override
  String get preparingTransferInfo => 'Übertragungsinfo wird vorbereitet...';

  @override
  String waitingForReceiverConfirmFiles(int count) {
    return 'Warte auf Bestätigung des Empfängers für $count Dateien...';
  }

  @override
  String transferringFile(int current, int total, String fileName) {
    return 'Übertrage Datei $current/$total: $fileName';
  }

  @override
  String get receiverRejected => 'Empfänger hat abgelehnt';

  @override
  String receiverRejectedWithStatus(int statusCode) {
    return 'Empfänger hat abgelehnt\nStatuscode: $statusCode';
  }

  @override
  String get transferIdNotFound => 'Übertragungs-ID nicht gefunden';

  @override
  String get waitingForConfirmation => 'Warte auf Bestätigung...';

  @override
  String get preparingToReceive => 'Empfang wird vorbereitet...';

  @override
  String get rejected => 'Abgelehnt';

  @override
  String get receiveComplete => 'Empfang abgeschlossen';

  @override
  String receivingProgress(double progress) {
    final intl.NumberFormat progressNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String progressString = progressNumberFormat.format(progress);

    return 'Empfange... $progressString%';
  }

  @override
  String receivingFiles(int count) {
    return 'Empfange $count Dateien';
  }

  @override
  String receiveFilesCount(int count) {
    return '$count Dateien empfangen';
  }

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
  String autoRejectCountdown(int seconds) {
    return 'Diese Dateien akzeptieren? (Automatische Ablehnung in $seconds Sekunden)';
  }

  @override
  String get rejectAll => 'Alle ablehnen';

  @override
  String get acceptAll => 'Alle akzeptieren';

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
  String get diskFullTitle => 'Speicher voll';

  @override
  String get storageCheckFailed => 'Speicherplatz kann nicht überprüft werden';

  @override
  String get networkPermissionDenied =>
      'Netzwerkzugriffsberechtigung erforderlich, um Dateien zu übertragen';

  @override
  String get storagePermissionDenied =>
      'Speicherzugriffsberechtigung erforderlich, um Dateien zu speichern';

  @override
  String serverStartFailed(String reason) {
    return 'Server kann nicht gestartet werden: $reason';
  }

  @override
  String get serverPortsOccupied =>
      'Server kann nicht gestartet werden: Alle Ports sind belegt';

  @override
  String serverPortsOccupiedRange(int defaultPort, int maxPort) {
    return 'Server kann nicht gestartet werden: Ports $defaultPort-$maxPort sind alle belegt';
  }

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
  ) {
    return '⚠️ Subnetz-Nichtübereinstimmung\nLokale IP: $localIP (Subnetz: $localNetwork.x)\nZiel-IP: $targetIP (Subnetz: $targetNetwork.x)\n\nHinweis: Beide Geräte müssen sich im selben LAN (gleiches Subnetz) befinden, um Dateien zu übertragen.\nBei IPv4-Adressen der Klasse C sollten die ersten drei Zahlen gleich sein, z.B. beide 192.168.2, nur die letzte Zahl unterscheidet sich\nDer einfachste Weg ist, beide Geräte mit demselben WLAN oder Router zu verbinden.\n';
  }

  @override
  String get responseParseError => 'Serverantwort kann nicht geparst werden';

  @override
  String get responseInvalidFormat =>
      'Antwortformat des Zielgeräts ist inkorrekt';

  @override
  String responseStatusCodeError(int statusCode) {
    return 'Server hat Fehlerstatuscode zurückgegeben: $statusCode';
  }

  @override
  String get fileSelectionError => 'Fehler beim Auswählen der Datei';

  @override
  String get fileSelectionCancelled => 'Dateiauswahl abgebrochen';

  @override
  String genericError(String operation) {
    return '$operation fehlgeschlagen';
  }

  @override
  String unexpectedError(String details) {
    return 'Unerwarteter Fehler aufgetreten: $details';
  }

  @override
  String networkError(String context) {
    return 'Netzwerkfehler: $context';
  }

  @override
  String fileError(String context) {
    return 'Dateifehler: $context';
  }

  @override
  String permissionError(String permissionType) {
    return '$permissionType-Berechtigung erforderlich, um fortzufahren';
  }

  @override
  String get foregroundServiceChannelName => 'Hintergrund-Übertragungdienst';

  @override
  String get foregroundServiceChannelDescription =>
      'Hält die App bereit, LAN-Dateien und Zwischenablage-Anfragen im Hintergrund zu empfangen';

  @override
  String get peerUnreachable => 'Zielgerät nicht erreichbar';

  @override
  String get peerUnreachableBoth =>
      'Gerät nicht erreichbar (weder lokal noch per Relay)';

  @override
  String get peerUnsupported =>
      'Die Version des anderen Geräts unterstützt keine Kopplung';

  @override
  String get identityMismatch =>
      'Gerätecode passt nicht zum öffentlichen Schlüssel, Kopplung abgebrochen';

  @override
  String get cannotPairSelf =>
      'Ein Gerät kann sich nicht mit sich selbst koppeln';

  @override
  String get pairingTitle => 'Gerätekopplung';

  @override
  String get compareHint =>
      'Prüfen Sie, ob beide Geräte genau dieselbe Zahl anzeigen. Andernfalls wurde die Verbindung möglicherweise manipuliert.';

  @override
  String get compareHintRelay =>
      'Dieses Gerät ist nicht im selben Netzwerk. Vergleichen Sie die 6 Ziffern per Telefon oder Sprachanruf und bestätigen Sie nur bei exakter Übereinstimmung. Ohne diesen Abgleich gibt es keinerlei Schutz.';

  @override
  String get pairOverRelay => 'Über das Relay koppeln';

  @override
  String get enterDeviceCode =>
      'Geben Sie den 32-stelligen Gerätecode der Gegenstelle ein';

  @override
  String get invalidDeviceCode =>
      'Der Gerätecode muss aus 32 Hexadezimalzeichen bestehen';

  @override
  String get alreadyPaired => 'Dieses Gerät ist bereits vertrauenswürdig';

  @override
  String get peerAlreadyPaired =>
      'The other device still trusts this one; unpair on that device first';

  @override
  String get relayUnavailable => 'Zuerst mit dem Relay-Server verbinden';

  @override
  String get peerBusy =>
      'Die Gegenstelle bearbeitet bereits eine andere Anfrage';

  @override
  String get peerPairingBlocked =>
      'The other device has blocked this one; ask them to unblock it first';

  @override
  String get peerRelayPairingOff =>
      'Die Gegenstelle nimmt keine Kopplungsanfragen über das Relay an';

  @override
  String incomingRequest(String deviceName) {
    return '„$deviceName“ möchte sich mit diesem Gerät koppeln';
  }

  @override
  String outgoingRequest(String deviceName) {
    return 'Kopplung mit „$deviceName“';
  }

  @override
  String get waitingPeer => 'Warten auf Bestätigung…';

  @override
  String get peerAccepted => 'Das andere Gerät hat bestätigt';

  @override
  String get peerRejected => 'Das andere Gerät hat die Kopplung abgelehnt';

  @override
  String get peerTimeout => 'Das andere Gerät hat nicht rechtzeitig bestätigt';

  @override
  String get pairingFailed => 'Kopplung fehlgeschlagen';

  @override
  String pairingSucceeded(String deviceName) {
    return 'Kopplung mit „$deviceName“ abgeschlossen';
  }

  @override
  String get codesMatch => 'Zahlen stimmen überein, koppeln';

  @override
  String get codesDiffer => 'Unterschiedlich, abbrechen';

  @override
  String get blockPeer => 'Block';

  @override
  String get pairingBlocklistTitle => 'Pairing blocklist';

  @override
  String get pairingBlocklistEmpty => 'No blocked devices';

  @override
  String get pairingBlocklistManage => 'Blocklist';

  @override
  String get unblockPeer => 'Unblock';

  @override
  String unblockPeerConfirm(String name) {
    return 'Unblock \"$name\"? They will be able to request pairing again.';
  }

  @override
  String get pairedDevicesTitle => 'Gekoppelte Geräte';

  @override
  String get pairedDevicesEmpty => 'Noch keine gekoppelten Geräte';

  @override
  String get addPairedDevice => 'Neues Gerät koppeln';

  @override
  String get unpair => 'Entkoppeln';

  @override
  String unpairConfirm(String deviceName) {
    return 'Nach dem Entfernen von „$deviceName“ müssen die Zahlen erneut verglichen werden. Fortfahren?';
  }

  @override
  String get deviceCodeLabel => 'Code dieses Geräts';

  @override
  String get title => 'Relay-Server';

  @override
  String get description =>
      'Leitet Dateien über Ihren eigenen Server weiter, wenn die Geräte nicht im selben Netzwerk sind. Direkte Verbindungen haben immer Vorrang.';

  @override
  String get encryptionNotice =>
      'Dateien sind zwischen den beiden gekoppelten Geräten Ende-zu-Ende verschlüsselt; nur sie können entschlüsseln. Der Server sieht lediglich Zeitpunkt und Byteanzahl.';

  @override
  String get acceptPairingLabel => 'Kopplungsanfragen über das Relay annehmen';

  @override
  String get acceptPairingHint =>
      'Jedes Gerät mit dem Servertoken kann eine Anfrage an Ihren Gerätecode senden. Einmal abgelehnte Geräte fragen nicht erneut.';

  @override
  String get iosForegroundNotice =>
      'Unter iOS ist der Empfang über das Relay nur bei geöffneter App möglich.';

  @override
  String get enableLabel => 'Relay aktivieren';

  @override
  String get serverUrlLabel => 'Serveradresse';

  @override
  String get tokenLabel => 'Zugangstoken';

  @override
  String get invalidUrl =>
      'Die Adresse muss mit http:// oder https:// beginnen';

  @override
  String get insecureUrlWarning =>
      'Mit http:// ist der Verkehr unverschlüsselt, nur für lokale Tests geeignet';

  @override
  String get testConnection => 'Verbindung testen';

  @override
  String get testSucceeded => 'Verbindung erfolgreich';

  @override
  String get save => 'Speichern';

  @override
  String get statusDisabled => 'Deaktiviert';

  @override
  String get statusConnecting => 'Verbinden…';

  @override
  String get statusConnected => 'Verbunden';

  @override
  String get statusReconnecting => 'Erneut verbinden…';

  @override
  String get statusRejected => 'Vom Server abgelehnt';

  @override
  String get clipboardNeedsPairing => 'Pair with the device first';

  @override
  String get clipboardRelayUnavailable => 'Not connected to the relay server';

  @override
  String get clipboardPeerOffline => 'The peer is not online on the relay';

  @override
  String get clipboardFailed => 'Clipboard sync over the relay failed';

  @override
  String get clipboardPeerNoUi =>
      'The peer cannot confirm the request right now';

  @override
  String get clipboardPeerBusy => 'The peer is busy, try again later';

  @override
  String get clipboardTooLargeForRelay =>
      'Clipboard content exceeds the configured size limit';

  @override
  String get clipboardStreamFailed =>
      'Failed to fetch clipboard data over the relay stream';

  @override
  String get clipboardPeerTimeout =>
      'The peer did not answer the clipboard request';

  @override
  String get clipboardDeclined => 'The peer declined the clipboard request';

  @override
  String selectedRelayPeer(String name) {
    return 'Selected relay peer: $name';
  }

  @override
  String get clearSelectedPeer => 'Clear selection';

  @override
  String get lanRouteUnavailable =>
      'Gerät über das lokale Netzwerk nicht erreichbar';

  @override
  String get relayRouteUnavailable =>
      'Gerät über den Relay-Server nicht erreichbar';

  @override
  String get relayNotConnected => 'Nicht mit dem Relay-Server verbunden';

  @override
  String get relayPeerOffline =>
      'Die Gegenstelle muss die App öffnen, um über das Relay zu empfangen';

  @override
  String get relayPeerNotPaired =>
      'Die Gegenstelle hat dieses Gerät nicht als vertrauenswürdig eingetragen';

  @override
  String get relayPeerBusy =>
      'Die Gegenstelle bearbeitet gerade einen anderen Stapel';

  @override
  String get relayNeedsPairedDevice =>
      'Übertragung über das Relay erfordert eine vorherige Kopplung';

  @override
  String get relayNegotiatingSession =>
      'Verschlüsselte Sitzung wird aufgebaut…';

  @override
  String get relayIdentityMismatch =>
      'Ungültige Signatur; möglicherweise nicht das gekoppelte Gerät';

  @override
  String get relayTransferNotice =>
      'Übertragung über den Relay-Server; die Geschwindigkeit hängt von dessen Bandbreite ab';

  @override
  String retryingAfterInterruption(int attempt, int maxAttempts) {
    return 'Verbindung unterbrochen, neuer Versuch ($attempt/$maxAttempts)…';
  }
}
