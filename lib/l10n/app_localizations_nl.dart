// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appName => 'Icy Easy Send';

  @override
  String get appVersion => 'Versie';

  @override
  String get navHome => 'Home';

  @override
  String get navHistory => 'Geschiedenis';

  @override
  String get navSettings => 'Instellingen';

  @override
  String get homeTitle => 'Home';

  @override
  String get serverStatus => 'Servicestatus';

  @override
  String get serverRunning => 'Actief';

  @override
  String get serverStopped => 'Gestopt';

  @override
  String get serverAddress => 'Serviceadres';

  @override
  String get deviceName => 'Apparaatnaam';

  @override
  String get storageSpace => 'Opslagruimte';

  @override
  String get availableSpace => 'Beschikbare ruimte';

  @override
  String get sendFiles => 'Bestanden verzenden';

  @override
  String get receiveFiles => 'Bestanden ontvangen';

  @override
  String get selectFiles => 'Bestanden selecteren';

  @override
  String get selectFolder => 'Map selecteren';

  @override
  String get dragDropHint => 'Sleep bestanden hierheen';

  @override
  String get noFilesSelected => 'Geen bestanden geselecteerd';

  @override
  String filesSelected(int count) {
    return '$count bestanden geselecteerd';
  }

  @override
  String get clearSelection => 'Selectie wissen';

  @override
  String get startSending => 'Verzenden starten';

  @override
  String get sending => 'Verzenden';

  @override
  String get sendSuccess => 'Verzenden geslaagd';

  @override
  String get sendFailed => 'Verzenden mislukt';

  @override
  String get cancel => 'Annuleren';

  @override
  String get confirm => 'Bevestigen';

  @override
  String get historyTitle => 'Overdrachtsgeschiedenis';

  @override
  String get noHistory => 'Geen geschiedenis';

  @override
  String get clearHistory => 'Geschiedenis wissen';

  @override
  String get sent => 'Verzonden';

  @override
  String get received => 'Ontvangen';

  @override
  String get failed => 'Mislukt';

  @override
  String get fileSize => 'Bestandsgrootte';

  @override
  String get time => 'Tijd';

  @override
  String get deleteItem => 'Record verwijderen';

  @override
  String get deleteItemConfirm =>
      'Weet u zeker dat u dit record wilt verwijderen?';

  @override
  String get openFile => 'Bestand openen';

  @override
  String get openFolder => 'Map openen';

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get general => 'Algemeen';

  @override
  String get language => 'Taal';

  @override
  String get deviceNameSetting => 'Apparaatnaam';

  @override
  String get editDeviceName => 'Apparaatnaam wijzigen';

  @override
  String get deviceNameHint => 'Voer apparaatnaam in';

  @override
  String get deviceNameEmpty => 'Apparaatnaam mag niet leeg zijn';

  @override
  String get port => 'Poort';

  @override
  String get portHint => 'Voer poortnummer in';

  @override
  String get portInvalid => 'Ongeldig poortnummer';

  @override
  String get portInUse => 'Poort is al in gebruik';

  @override
  String get savePath => 'Opslagpad';

  @override
  String get selectSavePath => 'Opslagpad selecteren';

  @override
  String get savePathDesc =>
      'Ontvangen bestanden worden hier opgeslagen. Standaard wordt de systeemdownloadmap gebruikt.';

  @override
  String get savePathDefaultBadge => 'Standaard';

  @override
  String get savePathUnavailable => 'Kan opslagpad niet bepalen';

  @override
  String get savePathSavedSuccess => 'Opslagpad succesvol ingesteld';

  @override
  String get savePathNotWritable =>
      'Kan niet naar deze map schrijven. Kies een andere locatie of controleer de machtigingen.';

  @override
  String get resetSavePathToDefault => 'Standaardmap gebruiken';

  @override
  String get savePathResetSuccess => 'Hersteld naar systeemdownloadmap';

  @override
  String get autoStart => 'Automatisch starten';

  @override
  String get autoStartDesc =>
      'Service automatisch starten bij het opstarten van de app';

  @override
  String get network => 'Netwerk';

  @override
  String get networkDiagnostics => 'Netwerkdiagnose';

  @override
  String get scanDevices => 'Apparaten scannen';

  @override
  String get scanDevicesTitle => 'LAN-apparaten scannen';

  @override
  String get scanningDevices => 'Lokaal netwerk scannen...';

  @override
  String scanProgress(int scanned, int total, int found) {
    String _temp0 = intl.Intl.pluralLogic(
      found,
      locale: localeName,
      other: 'Gescand $scanned/$total, $found apparaaten gevonden',
      one: 'Gescand $scanned/$total, $found apparaat gevonden',
    );
    return '$_temp0';
  }

  @override
  String get noDevicesFound => 'Geen apparaten gevonden';

  @override
  String get noDevicesFoundHint =>
      'Controleer of de doelapparaat de server heeft gestart en op hetzelfde netwerk zit. Controleer AP-isolatie en firewall.';

  @override
  String scanDevicesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apparaaten gevonden',
      one: '$count apparaat gevonden',
    );
    return '$_temp0';
  }

  @override
  String get rescan => 'Opnieuw scannen';

  @override
  String get runDiagnostics => 'Diagnose uitvoeren';

  @override
  String get about => 'Over';

  @override
  String get version => 'Versie';

  @override
  String get checkUpdate => 'Controleren op updates';

  @override
  String get feedback => 'Feedback';

  @override
  String get openSource => 'Open source licenties';

  @override
  String get license => 'Licentie';

  @override
  String get permissionRequired => 'Toestemming vereist';

  @override
  String get permissionDenied => 'Toestemming geweigerd';

  @override
  String get permissionPermanentlyDenied => 'Toestemming permanent geweigerd';

  @override
  String get permissionStorage => 'Opslagtoestemming';

  @override
  String get permissionStorageDesc =>
      'Opslagtoestemming vereist om bestanden op te slaan en te lezen';

  @override
  String get permissionNotification => 'Meldingstoestemming';

  @override
  String get permissionNotificationDesc =>
      'Meldingstoestemming vereist om overdrachtsvoortgang weer te geven';

  @override
  String get openSettings => 'Instellingen openen';

  @override
  String get permissionWarning =>
      'Sommige toestemmingen zijn niet verleend, bepaalde functies kunnen beperkt zijn';

  @override
  String get error => 'Fout';

  @override
  String get errorUnknown => 'Onbekende fout';

  @override
  String get errorNetwork => 'Netwerkfout';

  @override
  String get errorFileNotFound => 'Bestand niet gevonden';

  @override
  String get errorPermission => 'Toestemmingsfout';

  @override
  String get errorStorage => 'Opslagfout';

  @override
  String get errorServer => 'Serverfout';

  @override
  String get errorServerStart => 'Server starten mislukt';

  @override
  String get errorServerStop => 'Server stoppen mislukt';

  @override
  String get errorConnection => 'Verbindingsfout';

  @override
  String get errorTimeout => 'Verbinding time-out';

  @override
  String get retry => 'Opnieuw proberen';

  @override
  String get copied => 'Gekopieerd';

  @override
  String get copyFailed => 'Kopiëren mislukt';

  @override
  String get saved => 'Opgeslagen';

  @override
  String get saveFailed => 'Opslaan mislukt';

  @override
  String get deleted => 'Verwijderd';

  @override
  String get deleteFailed => 'Verwijderen mislukt';

  @override
  String get loading => 'Laden';

  @override
  String get success => 'Succes';

  @override
  String get warning => 'Waarschuwing';

  @override
  String get info => 'Tip';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nee';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Sluiten';

  @override
  String get selectFilesFailed => 'Bestanden selecteren mislukt';

  @override
  String get selectFolderFailed => 'Map selecteren mislukt';

  @override
  String folderFilesAdded(int count) {
    return '$count bestanden uit map toegevoegd';
  }

  @override
  String get folderContainsNoFiles =>
      'De geselecteerde map bevat geen bestanden om te verzenden';

  @override
  String get openFileFailed => 'Bestand openen mislukt';

  @override
  String get openFolderFailed => 'Map openen mislukt';

  @override
  String get fileNotExist => 'Bestand bestaat niet';

  @override
  String get folderNotExist => 'Map bestaat niet';

  @override
  String get diagnosticsTitle => 'Netwerkdiagnose';

  @override
  String get diagnosticsRunning => 'Diagnose wordt uitgevoerd...';

  @override
  String get diagnosticsComplete => 'Diagnose voltooid';

  @override
  String get diagnosticsFailed => 'Diagnose mislukt';

  @override
  String get networkStatus => 'Netwerkstatus';

  @override
  String get wifiConnected => 'WiFi verbonden';

  @override
  String get wifiDisconnected => 'WiFi niet verbonden';

  @override
  String get mobileData => 'Mobiele data';

  @override
  String get noConnection => 'Geen netwerkverbinding';

  @override
  String get ipAddress => 'IP-adres';

  @override
  String get noIpAddress => 'Geen IP-adres';

  @override
  String get serverStatusCheck => 'Serverstatuscontrole';

  @override
  String get portCheck => 'Poortcontrole';

  @override
  String get portAvailable => 'Poort beschikbaar';

  @override
  String get portUnavailable => 'Poort niet beschikbaar';

  @override
  String get suggestions => 'Suggesties';

  @override
  String get syncClipboard => 'Klembord van andere apparaat synchroniseren';

  @override
  String filesCount(int count) {
    return '$count bestanden verzenden';
  }

  @override
  String get sendFile => 'Bestand verzenden';

  @override
  String get shareViaQr => 'Delen via QR';

  @override
  String get webShareTitle => 'Scan om te ontvangen';

  @override
  String get webShareHint =>
      'De ontvanger scant met de systeemcamera en downloadt in de browser — zonder app. Blijf op hetzelfde Wi‑Fi / LAN. Sommige scanners van derden blokkeren LAN-links; gebruik Link kopiëren.';

  @override
  String get webShareCopyLink => 'Link kopiëren';

  @override
  String get webShareLinkCopied => 'Link gekopieerd';

  @override
  String get webShareStopSharing => 'Delen stoppen';

  @override
  String get webShareStopped => 'Webdeling gestopt';

  @override
  String get webShareServerRequired =>
      'Start de lokale server voordat je via QR deelt';

  @override
  String get webShareCreated =>
      'Webdeling gemaakt. De ontvanger kan scannen om te downloaden.';

  @override
  String get webShareFailed => 'Webdeling maken mislukt';

  @override
  String get webSharePeerName => 'Webdeling';

  @override
  String webShareFilesSummary(int count, String size) {
    return '$count bestand(en) · $size';
  }

  @override
  String webShareExpiresIn(String time) {
    return 'Verloopt over $time';
  }

  @override
  String get releaseToAdd => 'Loslaten om bestanden toe te voegen';

  @override
  String get serverNotRunning =>
      'Server is niet actief, kan gedeelde bestanden niet ontvangen';

  @override
  String get cannotReceiveFiles => 'Kan bestanden niet ontvangen';

  @override
  String get sendingInProgress =>
      'Bezig met verzenden, probeer het later opnieuw';

  @override
  String get pleaseTryLater => 'Probeer het later opnieuw';

  @override
  String filesAdded(int count) {
    return '$count gedeelde bestanden toegevoegd';
  }

  @override
  String get preparingSend => 'Verzenden voorbereiden...';

  @override
  String get transferring => 'Overdragen';

  @override
  String transferProgress(int current, int total, String fileName) {
    return '[$current/$total] $fileName: Overdragen...';
  }

  @override
  String get networkChanged =>
      'Netwerk is gewijzigd, serveradres is bijgewerkt';

  @override
  String get serverAddressUpdated => 'Serveradres bijgewerkt';

  @override
  String get portCannotBeEmpty => 'Poort mag niet leeg zijn';

  @override
  String get portMustBeNumber => 'Poort moet een getal zijn';

  @override
  String get portRange => 'Poortbereik: 1-65535';

  @override
  String ipDeleted(String ip) {
    return 'IP verwijderd: $ip';
  }

  @override
  String get runningDiagnostics => 'Netwerkdiagnose uitvoeren...';

  @override
  String get targetDeviceInfo => 'Doelapparaatinformatie';

  @override
  String get fullAddress => 'Volledig adres';

  @override
  String get targetNotSet => 'Doelapparaat niet ingesteld';

  @override
  String get diagnosticsReport => 'Netwerkdiagnoserapport';

  @override
  String get reportCopied => 'Diagnoserapport gekopieerd naar klembord';

  @override
  String get deviceNameCannotBeEmpty => 'Apparaatnaam mag niet leeg zijn';

  @override
  String get deviceNameSaved => 'Apparaatnaam opgeslagen';

  @override
  String get resetDeviceName => 'Apparaatnaam resetten';

  @override
  String resetDeviceNameConfirm(String model) {
    return 'Weet u zeker dat u de apparaatnaam wilt resetten naar \"$model\"?';
  }

  @override
  String get reset => 'Resetten';

  @override
  String get confirmChange => 'Wijziging bevestigen';

  @override
  String concurrentTransfersIncrease(int from, int to) {
    return 'Weet u zeker dat u het aantal gelijktijdige overdrachten wilt wijzigen van $from naar $to?\n\nTip: Het verhogen van het aantal kan de overdrachtssnelheid verbeteren, maar verhoogt ook de belasting van het apparaat';
  }

  @override
  String concurrentTransfersDecrease(int from, int to) {
    return 'Weet u zeker dat u het aantal gelijktijdige overdrachten wilt wijzigen van $from naar $to?\n\nTip: Het verlagen van het aantal kan de belasting van het apparaat verminderen, maar kan de overdrachtssnelheid verlagen';
  }

  @override
  String get concurrentTransfersHint => 'Tip voor gelijktijdige overdrachten';

  @override
  String get concurrentTransfersSaved =>
      'Aantal gelijktijdige overdrachten opgeslagen';

  @override
  String get enterValidNumber => 'Voer een geldig getal in';

  @override
  String historyCountRange(int min, int max) {
    return 'Bereik geschiedenisrecords: $min-$max';
  }

  @override
  String maxHistoryChange(int from, int to) {
    return 'Weet u zeker dat u het maximale aantal geschiedenisrecords wilt wijzigen van $from naar $to?\n\n';
  }

  @override
  String currentHistoryCount(int count) {
    return 'Huidig aantal geschiedenisrecords: $count\n\n';
  }

  @override
  String get historyWarning =>
      '⚠️ Waarschuwing: Het huidige aantal opgeslagen geschiedenisrecords is groter dan de ingestelde hoeveelheid.\n\n';

  @override
  String historyDeleteWarning(int current, int max, int toDelete) {
    return 'Alleen de nieuwste $max records worden bewaard, de $toDelete oudere records worden verwijderd.';
  }

  @override
  String get historyHint =>
      'Tip: De nieuwe instelling wordt van kracht bij het volgende opslaan van geschiedenisrecords.';

  @override
  String historyDeleted(int count) {
    return 'Instellingen opgeslagen, $count oude records verwijderd';
  }

  @override
  String get maxHistorySaved =>
      'Maximaal aantal geschiedenisrecords opgeslagen';

  @override
  String clipboardSizeRange(int min, int max) {
    return 'Klembordgroottebereik: $min-$max MB';
  }

  @override
  String maxClipboardSizeChange(int from, int to) {
    return 'Weet u zeker dat u de maximale klembordgrootte wilt wijzigen van $from MB naar $to MB?\n\n';
  }

  @override
  String get clipboardSizeDecreaseHint =>
      '⚠️ Tip: Na het verlagen van de limiet kan klembordinhoud die de limiet overschrijdt niet worden gesynchroniseerd. Het wordt aanbevolen om de bestandsoverdrachtsfunctie te gebruiken.';

  @override
  String get clipboardSizeIncreaseHint =>
      'Tip: Na het verhogen van de limiet kan grotere klembordinhoud worden gesynchroniseerd, maar dit kan de overdrachtssnelheid beïnvloeden.';

  @override
  String get maxClipboardSizeSaved => 'Maximale klembordgrootte opgeslagen';

  @override
  String get ipValidationEnabled => 'IP-adresvalidatie ingeschakeld';

  @override
  String get ipValidationDisabled => 'IP-adresvalidatie uitgeschakeld';

  @override
  String get deviceSecretKeyCleared => 'Apparaatsleutel gewist';

  @override
  String get deviceSecretKeySaved => 'Apparaatsleutel opgeslagen';

  @override
  String get loadingDevInfo => 'Ontwikkelingsinformatie laden...';

  @override
  String get copyLog => 'Log kopiëren';

  @override
  String logCopied(int lines) {
    return 'Laatste $lines regels van log gekopieerd naar klembord';
  }

  @override
  String get logFileEmpty => 'Logbestand is leeg';

  @override
  String get devInfo => 'Ontwikkelingsinformatie';

  @override
  String labelCopied(String label, String value) {
    return '$label gekopieerd: $value';
  }

  @override
  String get transferSettings => 'Overdrachtsinstellingen';

  @override
  String get concurrentTransfers => 'Aantal gelijktijdige overdrachten';

  @override
  String concurrentTransfersDesc(int max) {
    return 'Aantal bestanden dat tegelijkertijd wordt overgedragen (1-$max)';
  }

  @override
  String get concurrentTransfersHintText =>
      'Een hoger aantal kan de bandbreedte beter benutten, maar kan de belasting van het apparaat verhogen';

  @override
  String get maxHistory => 'Maximaal aantal geschiedenisrecords';

  @override
  String maxHistoryDesc(int min, int max) {
    return 'Maximaal aantal opgeslagen overdrachtsrecords ($min-$max)';
  }

  @override
  String maxHistoryHintText(int min, int max) {
    return 'Voer aantal in ($min-$max)';
  }

  @override
  String get oldRecordsAutoDelete =>
      'Oude records die het ingestelde aantal overschrijden worden automatisch verwijderd, alleen de nieuwste records worden bewaard';

  @override
  String get maxClipboard => 'Maximale klembordgrootte';

  @override
  String maxClipboardDesc(int min, int max) {
    return 'Maximale klembordgrootte die gesynchroniseerd mag worden ($min-$max MB)';
  }

  @override
  String maxClipboardHintText(int min, int max) {
    return 'Voer grootte in ($min-$max MB)';
  }

  @override
  String get clipboardSyncLimit =>
      'Klembordinhoud die deze grootte overschrijdt kan niet worden gesynchroniseerd. Het wordt aanbevolen om de bestandsoverdrachtsfunctie te gebruiken';

  @override
  String get ipValidation => 'IP-adresvalidatie';

  @override
  String get ipValidationDesc =>
      'Controleer of het IP van het doelapparaat zich in hetzelfde subnet bevindt';

  @override
  String get ipValidationEnabledHint =>
      'Wanneer ingeschakeld, wordt gecontroleerd of het doel-IP zich in hetzelfde subnet bevindt, om verbinding met verkeerde apparaten te voorkomen';

  @override
  String get ipValidationDisabledHint =>
      'Wanneer uitgeschakeld, wordt het IP-subnet niet gecontroleerd, geschikt voor complexe netwerkomgevingen (zoals hotspots, VPN, enz.)';

  @override
  String get deviceSecretKey => 'Apparaatsleutel';

  @override
  String get deviceSecretKeyDesc =>
      'Na instelling moeten andere apparaten de juiste sleutel opgeven om bevestiging over te slaan';

  @override
  String get deviceSecretKeyHint =>
      'Voer sleutel in (leeg laten betekent geen sleutel gebruiken)';

  @override
  String get notSet => 'Niet ingesteld';

  @override
  String get author => 'Auteur';

  @override
  String get update => 'Update';

  @override
  String get github => 'GitHub';

  @override
  String get githubLinkCopied => 'GitHub-link gekopieerd';

  @override
  String get openGitHubFailed =>
      'Kon de browser niet openen; link in plaats daarvan gekopieerd';

  @override
  String get appDescription =>
      'Een eenvoudig te gebruiken LAN-bestandsoverdrachtshulpmiddel';

  @override
  String get targetDeviceIP => 'IP-adres van doelapparaat';

  @override
  String get ipHint => 'Bijvoorbeeld: 192.168.1.100';

  @override
  String get clear => 'Wissen';

  @override
  String get history => 'Geschiedenis';

  @override
  String get targetDevicePort => 'Poort van doelapparaat';

  @override
  String resetToDefaultPort(int port) {
    return 'Resetten naar standaardpoort ($port)';
  }

  @override
  String get targetDeviceSecretKey => 'Sleutel van doelapparaat (optioneel)';

  @override
  String get secretKeyHint =>
      'Juiste sleutel kan bevestiging van andere partij overslaan';

  @override
  String get aboutSecretKey => 'Over sleutel';

  @override
  String get secretKeyFeatureTitle => 'Uitleg sleutelfunctie';

  @override
  String get secretKeyFeatureDesc =>
      'Als het doelapparaat een sleutel heeft ingesteld, kan na het invoeren van de juiste sleutel het bevestigingsvenster worden overgeslagen en kunnen bestanden direct worden overgedragen of het klembord worden gesynchroniseerd.';

  @override
  String get secretKeyUsageSteps => 'Gebruiksstappen:';

  @override
  String get secretKeyUsageStep1 =>
      '1. Doelapparaat stelt apparaatsleutel in op de instellingenpagina';

  @override
  String get secretKeyUsageStep2 =>
      '2. Voer de sleutel van het doelapparaat in dit invoerveld in';

  @override
  String get secretKeyUsageStep3 =>
      '3. Bij het verzenden van bestanden of aanvragen van klembord, als de sleutel correct is, accepteert de andere partij automatisch';

  @override
  String get secretKeyTip =>
      'Tip: Leeg laten betekent de traditionele handmatige bevestigingsmethode gebruiken';

  @override
  String get secretKeyDescription => 'Sleutelbeschrijving';

  @override
  String get clearSecretKey => 'Sleutel wissen';

  @override
  String get gotIt => 'Begrepen';

  @override
  String get localIP => 'Lokaal IP';

  @override
  String ipCopied(String ip) {
    return 'IP-adres gekopieerd: $ip';
  }

  @override
  String get transferred => 'Overgedragen';

  @override
  String get transferSpeed => 'Overdrachtssnelheid';

  @override
  String get remainingTime => 'Resterende tijd';

  @override
  String transferringProgress(double progress) {
    final intl.NumberFormat progressNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String progressString = progressNumberFormat.format(progress);

    return 'Overdragen $progressString%';
  }

  @override
  String get storagePermissionMessage =>
      'Opslagtoestemming vereist om bestanden te selecteren. Open de toestemming handmatig in de instellingen.';

  @override
  String get checkingTargetDevice => 'Doelapparaat controleren...';

  @override
  String get targetDeviceUnavailable => 'Doelapparaat niet beschikbaar';

  @override
  String targetDeviceError(String error) {
    return 'Doelapparaat niet beschikbaar\nFout: $error';
  }

  @override
  String get connectionFailed => 'Verbinding mislukt';

  @override
  String get transferHistory => 'Overdrachtsgeschiedenis';

  @override
  String get clearHistoryTitle => 'Geschiedenis wissen';

  @override
  String get clearHistoryMessage =>
      'Weet u zeker dat u alle overdrachtsgeschiedenis wilt wissen? Deze actie kan niet ongedaan worden gemaakt.';

  @override
  String get noFilteredRecords => 'Geen records die aan de voorwaarden voldoen';

  @override
  String get filterAll => 'Alles';

  @override
  String get filterSent => 'Verzonden';

  @override
  String get filterReceived => 'Ontvangen';

  @override
  String get statisticsInfo => 'Statistieken';

  @override
  String transfersCount(int count) {
    return '$count overdrachten';
  }

  @override
  String get totalTransfers => 'Totaal overdrachten';

  @override
  String get successfulTransfers => 'Geslaagd';

  @override
  String get failedTransfers => 'Mislukt';

  @override
  String get sentFiles => 'Verzonden';

  @override
  String get receivedFiles => 'Ontvangen';

  @override
  String get totalSize => 'Totale grootte';

  @override
  String get moreActions => 'Meer acties';

  @override
  String get deleteRecord => 'Record verwijderen';

  @override
  String get viewDetails => 'Details bekijken';

  @override
  String get deleteRecordTitle => 'Record verwijderen';

  @override
  String deleteRecordMessage(String fileName) {
    return 'Weet u zeker dat u het overdrachtsrecord van \"$fileName\" wilt verwijderen?\n\nLet op: Dit verwijdert alleen het record, niet het bestand zelf.';
  }

  @override
  String get deleteRecordNote =>
      'Let op: Dit verwijdert alleen het record, niet het bestand zelf.';

  @override
  String get recordDeleted => 'Record verwijderd';

  @override
  String get filePathNotExist => 'Bestandspad bestaat niet';

  @override
  String get cannotOpenFile => 'Kan bestand niet openen';

  @override
  String cannotOpenFileWithMessage(String message) {
    return 'Kan bestand niet openen: $message';
  }

  @override
  String get iosNoFolderSupport =>
      'iOS ondersteunt het direct openen van mappen niet';

  @override
  String get cannotOpenFolder => 'Kan map niet openen';

  @override
  String get recentFilesOpened => 'Recente bestanden geopend, zoek handmatig';

  @override
  String get receiveRecord => 'Ontvangstrecord';

  @override
  String get sendRecord => 'Verzendrecord';

  @override
  String get fileName => 'Bestandsnaam';

  @override
  String get fromDevice => 'Van apparaat';

  @override
  String get toDevice => 'Naar apparaat';

  @override
  String get deviceIP => 'Apparaat-IP';

  @override
  String get transferTime => 'Overdrachtsduur';

  @override
  String get transferStatus => 'Overdrachtsstatus';

  @override
  String get statusSuccess => 'Geslaagd';

  @override
  String get statusFailed => 'Mislukt';

  @override
  String get savedLocation => 'Opslaglocatie';

  @override
  String get copy => 'Kopiëren';

  @override
  String get pathCopied => 'Pad gekopieerd naar klembord';

  @override
  String get from => 'Van';

  @override
  String get sentTo => 'Verzonden naar';

  @override
  String get clipboardRequest => 'Klemborverzoek';

  @override
  String clipboardRequestFrom(String deviceName) {
    return 'Apparaat \"$deviceName\" vraagt toegang tot uw klembordinhoud';
  }

  @override
  String get allowClipboardRequest => 'Toestaan?';

  @override
  String get clipboardRequestMessage => 'Klemborverzoek';

  @override
  String autoRejectIn(int seconds) {
    return 'Automatisch weigeren over $seconds seconden';
  }

  @override
  String get reject => 'Weigeren';

  @override
  String get allow => 'Toestaan';

  @override
  String clipboardSharedWithSecretKey(String deviceName) {
    return '$deviceName geverifieerd met sleutel, klembord automatisch gedeeld';
  }

  @override
  String get clipboardRequestRejected =>
      'Gebruiker heeft klemborverzoek geweigerd';

  @override
  String get clipboardEmpty => 'Klembord is leeg';

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

    return 'Klembordinhoud te groot ($actualSizeMBString MB), overschrijdt de limiet van het andere apparaat ($maxSizeMB MB). Het wordt aanbevolen om de bestandsoverdrachtsfunctie te gebruiken.';
  }

  @override
  String get clipboardContentSuccess => 'Klembordinhoud succesvol opgehaald';

  @override
  String get invalidJsonFormat => 'Ongeldig JSON-formaat';

  @override
  String get serverInternalError => 'Interne serverfout';

  @override
  String get backgroundRejectNeedsSecretKey =>
      'Apparaat is op de achtergrond. Alleen automatische sync/ontvangst met overeenkomende geheime sleutel wordt ondersteund.';

  @override
  String get foregroundServiceNotificationTitle => 'IcyEasySend';

  @override
  String get foregroundServiceNotificationText =>
      'Wacht op bestandoverdracht en klembordsync op de achtergrond';

  @override
  String get androidBackgroundReceiveHint =>
      'Op de achtergrond kunnen alleen apparaten met een overeenkomende geheime sleutel automatisch synchroniseren of verzenden. Houd de blijvende melding aan.';

  @override
  String get clipboardOverlay => 'Zwevende klembordknop';

  @override
  String get clipboardOverlayDesc =>
      'Tik op de zwevende knop om tekst-/afbeeldingscache te vernieuwen voor synchronisatie op de achtergrond';

  @override
  String get clipboardOverlayHint =>
      'Op de achtergrond wordt alleen de laatst vernieuwde inhoud gesynchroniseerd. Uitschakelen wist de cache en verbergt de knop.';

  @override
  String get clipboardOverlayPermissionNeeded =>
      'Sta \"Weergeven over andere apps\" toe in de systeeminstellingen. De knop verschijnt na terugkeer.';

  @override
  String get clipboardOverlayEnabledToast =>
      'Zwevende klembordknop ingeschakeld';

  @override
  String get clipboardBackgroundCacheMiss =>
      'Systeemklembord is op de achtergrond niet leesbaar en er is geen cache. Open de app of tik op de zwevende knop om te vernieuwen.';

  @override
  String get requestingClipboard => 'Klembord aanvragen...';

  @override
  String get clipboardSyncSuccess => 'Klembord succesvol gesynchroniseerd';

  @override
  String get textClipboardSyncSuccess =>
      'Tekstklembord succesvol gesynchroniseerd';

  @override
  String get fileClipboardSyncSuccess =>
      'Bestandsklembord succesvol gesynchroniseerd\nKan in app of bestandsbeheerder worden geplakt';

  @override
  String get clipboardSyncFailed => 'Klembordsynchronisatie mislukt';

  @override
  String get syncFailed => 'Synchronisatie mislukt';

  @override
  String clipboardRequestError(String error) {
    return 'Fout bij aanvragen klembord: $error';
  }

  @override
  String invalidFilesMessage(String fileNames) {
    return 'De volgende bestanden zijn ongeldig of niet toegankelijk:\n$fileNames';
  }

  @override
  String get waitingForReceiverConfirmation =>
      'Wachten op bevestiging van ontvanger...';

  @override
  String get fileSendSuccess => 'Bestand succesvol verzonden!';

  @override
  String filesSendSuccess(int count) {
    return '$count bestanden succesvol verzonden!';
  }

  @override
  String get allFilesSendFailed => 'Alle bestanden verzenden mislukt';

  @override
  String get failedFiles => 'Mislukte bestanden';

  @override
  String get transferComplete => 'Overdracht voltooid';

  @override
  String get successCount => 'Geslaagd';

  @override
  String get failureCount => 'Mislukt';

  @override
  String transferSummary(
    int successCount,
    int failureCount,
    String failedFiles,
  ) {
    return 'Geslaagd: $successCount bestanden\nMislukt: $failureCount bestanden\n\nMislukte bestanden:\n$failedFiles';
  }

  @override
  String get preparingTransferInfo => 'Overdrachtsinformatie voorbereiden...';

  @override
  String waitingForReceiverConfirmFiles(int count) {
    return 'Wachten op bevestiging van ontvanger voor $count bestanden...';
  }

  @override
  String transferringFile(int current, int total, String fileName) {
    return 'Bestand $current/$total overdragen: $fileName';
  }

  @override
  String get receiverRejected => 'Ontvanger heeft geweigerd';

  @override
  String receiverRejectedWithStatus(int statusCode) {
    return 'Ontvanger heeft geweigerd\nStatuscode: $statusCode';
  }

  @override
  String get transferIdNotFound => 'Overdrachts-ID niet gevonden';

  @override
  String get waitingForConfirmation => 'Wachten op bevestiging...';

  @override
  String get preparingToReceive => 'Ontvangst voorbereiden...';

  @override
  String get rejected => 'Geweigerd';

  @override
  String get receiveComplete => 'Ontvangst voltooid';

  @override
  String receivingProgress(double progress) {
    final intl.NumberFormat progressNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String progressString = progressNumberFormat.format(progress);

    return 'Ontvangen... $progressString%';
  }

  @override
  String receivingFiles(int count) {
    return '$count bestanden ontvangen';
  }

  @override
  String receiveFilesCount(int count) {
    return '$count bestanden ontvangen';
  }

  @override
  String get sender => 'Afzender';

  @override
  String get totalSizeBatch => 'Totale grootte';

  @override
  String get fileList => 'Bestandslijst';

  @override
  String get allFilesReceiveComplete => 'Alle bestanden ontvangen!';

  @override
  String get receivingFiles2 => 'Bestanden ontvangen...';

  @override
  String autoRejectCountdown(int seconds) {
    return 'Deze bestanden ontvangen? (Automatisch weigeren over $seconds seconden)';
  }

  @override
  String get rejectAll => 'Alles weigeren';

  @override
  String get acceptAll => 'Alles accepteren';

  @override
  String get networkDiagnosticsReport => 'Netwerkdiagnoserapport';

  @override
  String get localNetworkInterfaces => 'Lokale netwerkinterfaces';

  @override
  String get noValidNetworkInterface =>
      'Geen geldige netwerkinterface gevonden';

  @override
  String get privateNetworkAddress => 'Privé netwerkadres';

  @override
  String get targetDeviceReachability => 'Bereikbaarheid doelapparaat';

  @override
  String get canConnectToTarget => 'Kan verbinding maken met doelapparaat';

  @override
  String get cannotConnectToTarget =>
      'Kan geen verbinding maken met doelapparaat';

  @override
  String get healthCheckTest => 'Gezondheidscontroletest';

  @override
  String get healthCheckSuccess => 'Gezondheidscontrole geslaagd';

  @override
  String get healthCheckFailed => 'Gezondheidscontrole mislukt';

  @override
  String get statusCode => 'Statuscode';

  @override
  String get response => 'Reactie';

  @override
  String get internetConnection => 'Internetverbinding';

  @override
  String get hasInternetConnection => 'Heeft internetverbinding';

  @override
  String get noInternetConnection => 'Geen internetverbinding';

  @override
  String get networkConnectionFailed =>
      'Kan geen verbinding maken met doelapparaat, controleer netwerkverbinding en IP-adres';

  @override
  String get networkTimeout =>
      'Verbinding time-out, doelapparaat is mogelijk offline of netwerk is instabiel';

  @override
  String get networkRequestFailed =>
      'Netwerkverzoek mislukt, controleer netwerkverbinding';

  @override
  String get transferTimeout =>
      'Overdracht time-out, controleer netwerkverbinding';

  @override
  String get transferInterrupted => 'Overdracht onderbroken, probeer opnieuw';

  @override
  String get fileNotFound => 'Bestand bestaat niet';

  @override
  String get fileNotReadable =>
      'Kan bestand niet lezen, zorg ervoor dat het bestand bestaat en toegankelijk is';

  @override
  String get fileAccessError =>
      'Bestandstoegang fout, controleer bestandsrechten';

  @override
  String get fileSaveFailed => 'Bestand opslaan mislukt';

  @override
  String get fileSizeMismatch =>
      'Bestand opslaan mislukt: bestandsgrootte komt niet overeen';

  @override
  String get invalidFileName => 'Bestandsnaam bevat ongeldige tekens';

  @override
  String get downloadsDirectoryUnavailable =>
      'Kan geen toegang krijgen tot downloadmap';

  @override
  String get storageInsufficient =>
      'Onvoldoende opslagruimte, kan bestand niet ontvangen';

  @override
  String get diskFullTitle => 'Schijf vol';

  @override
  String get storageCheckFailed => 'Kan opslagruimte niet controleren';

  @override
  String get networkPermissionDenied =>
      'Netwerktoegang vereist om bestanden over te dragen';

  @override
  String get storagePermissionDenied =>
      'Opslagtoestemming vereist om bestanden op te slaan';

  @override
  String serverStartFailed(String reason) {
    return 'Kan server niet starten: $reason';
  }

  @override
  String get serverPortsOccupied =>
      'Kan server niet starten: alle poorten zijn bezet';

  @override
  String serverPortsOccupiedRange(int defaultPort, int maxPort) {
    return 'Kan server niet starten: poorten $defaultPort-$maxPort zijn allemaal bezet';
  }

  @override
  String get serverUnknownError => 'Kan server niet starten: onbekende fout';

  @override
  String get transferRejected =>
      'Andere partij heeft geweigerd bestand te ontvangen';

  @override
  String get fileTooLarge => 'Bestand te groot, maximaal 2GB ondersteund';

  @override
  String get fileOrStorageFull =>
      'Bestand te groot of opslagruimte van andere partij onvoldoende';

  @override
  String get receiveTimeout => 'Ontvangst time-out, automatisch geweigerd';

  @override
  String get userRejected => 'Gebruiker heeft geweigerd bestand te ontvangen';

  @override
  String get ipAddressEmpty => 'IP-adres mag niet leeg zijn';

  @override
  String get ipAddressInvalidFormat =>
      'IP-adres formaat ongeldig, gebruik xxx.xxx.xxx.xxx formaat';

  @override
  String get ipAddressInvalidRange =>
      'IP-adres formaat ongeldig, elk getal moet tussen 0-255 zijn';

  @override
  String get ipAddressSpecial1 => 'Kan 0.0.0.0 niet gebruiken als doeladres';

  @override
  String get ipAddressSpecial2 =>
      'Kan broadcast-adres 255.255.255.255 niet gebruiken';

  @override
  String ipAddressNotInSameSubnet(
    String localIP,
    String targetIP,
    String localNetwork,
    String targetNetwork,
  ) {
    return '⚠️ Subnet komt niet overeen\nLokaal IP: $localIP (subnet: $localNetwork.x)\nDoel-IP: $targetIP (subnet: $targetNetwork.x)\n\nTip: Beide apparaten moeten zich in hetzelfde LAN (zelfde subnet) bevinden om bestanden over te dragen.\nVoor klasse C IPv4-adressen moeten de eerste drie cijfers van beide IP-adressen hetzelfde zijn, bijvoorbeeld beide 192.168.2, alleen het laatste cijfer verschilt\nDe eenvoudigste methode is om beide apparaten met dezelfde WiFi of router te verbinden.\n';
  }

  @override
  String get responseParseError => 'Kan serverreactie niet parseren';

  @override
  String get responseInvalidFormat =>
      'Reactieformaat van doelapparaat is onjuist';

  @override
  String responseStatusCodeError(int statusCode) {
    return 'Server retourneerde foutstatuscode: $statusCode';
  }

  @override
  String get fileSelectionError => 'Fout bij selecteren van bestanden';

  @override
  String get fileSelectionCancelled => 'Bestandsselectie geannuleerd';

  @override
  String genericError(String operation) {
    return '$operation mislukt';
  }

  @override
  String unexpectedError(String details) {
    return 'Onverwachte fout opgetreden: $details';
  }

  @override
  String networkError(String context) {
    return 'Netwerkfout: $context';
  }

  @override
  String fileError(String context) {
    return 'Bestandsfout: $context';
  }

  @override
  String permissionError(String permissionType) {
    return '$permissionType toestemming vereist om door te gaan';
  }

  @override
  String get foregroundServiceChannelName => 'Achtergrond-overdrachtservice';

  @override
  String get foregroundServiceChannelDescription =>
      'Houdt de app klaar om LAN-bestanden en klembordverzoeken op de achtergrond te ontvangen';

  @override
  String get peerUnreachable =>
      'Kan geen verbinding maken met het doelapparaat';

  @override
  String get peerUnreachableBoth =>
      'Apparaat niet bereikbaar (noch LAN noch relay)';

  @override
  String get peerUnsupported =>
      'De versie van het andere apparaat ondersteunt koppelen niet';

  @override
  String get identityMismatch =>
      'De apparaatcode komt niet overeen met de publieke sleutel; koppelen afgebroken';

  @override
  String get cannotPairSelf =>
      'Een apparaat kan niet met zichzelf worden gekoppeld';

  @override
  String get pairingTitle => 'Apparaten koppelen';

  @override
  String get compareHint =>
      'Controleer of beide apparaten exact hetzelfde getal tonen. Zo niet, dan is de verbinding mogelijk gemanipuleerd.';

  @override
  String get compareHintRelay =>
      'Dit apparaat zit niet op hetzelfde netwerk. Vergelijk de 6 cijfers telefonisch met de ander en bevestig alleen bij een exacte match. Zonder die controle is er geen enkele bescherming.';

  @override
  String get pairOverRelay => 'Koppelen via de relay';

  @override
  String get enterDeviceCode =>
      'Voer de 32-tekens apparaatcode van het andere apparaat in';

  @override
  String get invalidDeviceCode =>
      'De apparaatcode moet 32 hexadecimale tekens bevatten';

  @override
  String get alreadyPaired => 'Dit apparaat staat al in de vertrouwenslijst';

  @override
  String get peerAlreadyPaired =>
      'The other device still trusts this one; unpair on that device first';

  @override
  String get relayUnavailable => 'Maak eerst verbinding met de relayserver';

  @override
  String get peerBusy => 'Het andere apparaat behandelt al een ander verzoek';

  @override
  String get peerPairingBlocked =>
      'The other device has blocked this one; ask them to unblock it first';

  @override
  String get peerRelayPairingOff =>
      'Het andere apparaat accepteert geen verzoeken via de relay';

  @override
  String incomingRequest(String deviceName) {
    return '\"$deviceName\" wil koppelen met dit apparaat';
  }

  @override
  String outgoingRequest(String deviceName) {
    return 'Koppelen met \"$deviceName\"';
  }

  @override
  String get waitingPeer => 'Wachten op bevestiging…';

  @override
  String get peerAccepted => 'Het andere apparaat heeft bevestigd';

  @override
  String get peerRejected => 'Het andere apparaat heeft het koppelen geweigerd';

  @override
  String get peerTimeout => 'Het andere apparaat heeft niet op tijd bevestigd';

  @override
  String get pairingFailed => 'Koppelen mislukt';

  @override
  String pairingSucceeded(String deviceName) {
    return 'Koppeling met \"$deviceName\" voltooid';
  }

  @override
  String get codesMatch => 'Getallen komen overeen, koppelen';

  @override
  String get codesDiffer => 'Verschillend, annuleren';

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
  String get pairedDevicesTitle => 'Gekoppelde apparaten';

  @override
  String get pairedDevicesEmpty => 'Nog geen gekoppelde apparaten';

  @override
  String get addPairedDevice => 'Nieuw apparaat koppelen';

  @override
  String get unpair => 'Ontkoppelen';

  @override
  String unpairConfirm(String deviceName) {
    return 'Na het verwijderen van \"$deviceName\" moeten de getallen opnieuw worden vergeleken. Doorgaan?';
  }

  @override
  String get deviceCodeLabel => 'Code van dit apparaat';

  @override
  String get title => 'Relayserver';

  @override
  String get description =>
      'Stuurt bestanden door via je eigen server wanneer apparaten niet op hetzelfde netwerk zitten. Directe verbindingen krijgen altijd voorrang.';

  @override
  String get encryptionNotice =>
      'Bestanden zijn end-to-end versleuteld tussen de twee gekoppelde apparaten; alleen zij kunnen ontsleutelen. De server ziet alleen het tijdstip en het aantal bytes.';

  @override
  String get acceptPairingLabel => 'Koppelverzoeken via de relay accepteren';

  @override
  String get acceptPairingHint =>
      'Elk apparaat met het servertoken kan een verzoek naar jouw apparaatcode sturen. Een geweigerd apparaat verschijnt niet opnieuw.';

  @override
  String get iosForegroundNotice =>
      'Op iOS kun je alleen ontvangen via de relay wanneer de app geopend is.';

  @override
  String get enableLabel => 'Relay inschakelen';

  @override
  String get serverUrlLabel => 'Serveradres';

  @override
  String get tokenLabel => 'Toegangstoken';

  @override
  String get invalidUrl => 'Het adres moet beginnen met http:// of https://';

  @override
  String get insecureUrlWarning =>
      'Met http:// is het verkeer onversleuteld, alleen voor lokale tests';

  @override
  String get testConnection => 'Verbinding testen';

  @override
  String get testSucceeded => 'Verbinding geslaagd';

  @override
  String get save => 'Opslaan';

  @override
  String get statusDisabled => 'Uitgeschakeld';

  @override
  String get statusConnecting => 'Verbinden…';

  @override
  String get statusConnected => 'Verbonden';

  @override
  String get statusReconnecting => 'Opnieuw verbinden…';

  @override
  String get statusRejected => 'Geweigerd door de server';

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
      'Apparaat niet bereikbaar via het lokale netwerk';

  @override
  String get relayRouteUnavailable =>
      'Apparaat niet bereikbaar via de relayserver';

  @override
  String get relayNotConnected => 'Niet verbonden met de relayserver';

  @override
  String get relayPeerOffline =>
      'De ontvanger moet de app openen om via de relay te ontvangen';

  @override
  String get relayPeerNotPaired =>
      'De ontvanger heeft dit apparaat niet in de vertrouwenslijst';

  @override
  String get relayPeerBusy =>
      'De ontvanger verwerkt al een andere reeks bestanden';

  @override
  String get relayNeedsPairedDevice =>
      'Overdracht via de relay vereist eerst koppelen';

  @override
  String get relayNegotiatingSession => 'Versleutelde sessie opzetten…';

  @override
  String get relayIdentityMismatch =>
      'Ongeldige handtekening; mogelijk niet het gekoppelde apparaat';

  @override
  String get relayTransferNotice =>
      'Overdracht via de relayserver; de snelheid hangt af van de bandbreedte';

  @override
  String retryingAfterInterruption(int attempt, int maxAttempts) {
    return 'Verbinding verbroken, opnieuw proberen ($attempt/$maxAttempts)…';
  }
}
