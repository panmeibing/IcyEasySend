// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Icy Easy Send';

  @override
  String get appVersion => 'Version';

  @override
  String get navHome => 'Accueil';

  @override
  String get navHistory => 'Historique';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get homeTitle => 'Accueil';

  @override
  String get serverStatus => 'État du serveur';

  @override
  String get serverRunning => 'En cours';

  @override
  String get serverStopped => 'Arrêté';

  @override
  String get serverAddress => 'Adresse du serveur';

  @override
  String get deviceName => 'Nom de l\'appareil';

  @override
  String get storageSpace => 'Espace de stockage';

  @override
  String get availableSpace => 'Espace disponible';

  @override
  String get sendFiles => 'Envoyer des fichiers';

  @override
  String get receiveFiles => 'Recevoir des fichiers';

  @override
  String get selectFiles => 'Sélectionner des fichiers';

  @override
  String get selectFolder => 'Sélectionner un dossier';

  @override
  String get dragDropHint => 'Glissez-déposez les fichiers ici';

  @override
  String get noFilesSelected => 'Aucun fichier sélectionné';

  @override
  String filesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers sélectionnés',
      one: '$count fichier sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get clearSelection => 'Effacer';

  @override
  String get startSending => 'Envoyer';

  @override
  String get sending => 'Envoi en cours';

  @override
  String get sendSuccess => 'Envoyé avec succès';

  @override
  String get sendFailed => 'Échec de l\'envoi';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get historyTitle => 'Historique des transferts';

  @override
  String get noHistory => 'Aucun historique';

  @override
  String get clearHistory => 'Effacer l\'historique';

  @override
  String get sent => 'Envoyé';

  @override
  String get received => 'Reçu';

  @override
  String get failed => 'Échoué';

  @override
  String get fileSize => 'Taille du fichier';

  @override
  String get time => 'Heure';

  @override
  String get deleteItem => 'Supprimer l\'enregistrement';

  @override
  String get deleteItemConfirm =>
      'Êtes-vous sûr de vouloir supprimer cet élément ?';

  @override
  String get openFile => 'Ouvrir le fichier';

  @override
  String get openFolder => 'Ouvrir le dossier';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get general => 'Général';

  @override
  String get language => 'Langue';

  @override
  String get deviceNameSetting => 'Nom de l\'appareil';

  @override
  String get editDeviceName => 'Modifier le nom de l\'appareil';

  @override
  String get deviceNameHint => 'Entrez le nom de l\'appareil';

  @override
  String get deviceNameEmpty => 'Le nom de l\'appareil ne peut pas être vide';

  @override
  String get port => 'Port';

  @override
  String get portHint => 'Entrez le numéro de port';

  @override
  String get portInvalid => 'Numéro de port invalide';

  @override
  String get portInUse => 'Le port est déjà utilisé';

  @override
  String get savePath => 'Chemin de sauvegarde';

  @override
  String get selectSavePath => 'Sélectionner le chemin de sauvegarde';

  @override
  String get savePathDesc =>
      'Les fichiers reçus sont enregistrés ici. Le dossier Téléchargements du système est utilisé par défaut.';

  @override
  String get savePathDefaultBadge => 'Par défaut';

  @override
  String get savePathUnavailable =>
      'Impossible de déterminer le chemin de sauvegarde';

  @override
  String get savePathSavedSuccess => 'Chemin de sauvegarde défini avec succès';

  @override
  String get savePathNotWritable =>
      'Impossible d\'écrire dans ce dossier. Choisissez un autre emplacement ou vérifiez les autorisations.';

  @override
  String get resetSavePathToDefault => 'Utiliser le dossier par défaut';

  @override
  String get savePathResetSuccess =>
      'Rétabli vers le dossier Téléchargements du système';

  @override
  String get autoStart => 'Démarrage automatique';

  @override
  String get autoStartDesc =>
      'Démarrer le serveur automatiquement au lancement de l\'application';

  @override
  String get network => 'Réseau';

  @override
  String get networkDiagnostics => 'Diagnostics réseau';

  @override
  String get scanDevices => 'Scanner les appareils';

  @override
  String get scanDevicesTitle => 'Scanner les appareils du LAN';

  @override
  String get scanningDevices => 'Analyse du réseau local...';

  @override
  String scanProgress(int scanned, int total, int found) {
    String _temp0 = intl.Intl.pluralLogic(
      found,
      locale: localeName,
      other: 'Analysé $scanned/$total, $found appareils trouvés',
      one: 'Analysé $scanned/$total, $found appareil trouvé',
    );
    return '$_temp0';
  }

  @override
  String get noDevicesFound => 'Aucun appareil trouvé';

  @override
  String get noDevicesFoundHint =>
      'Assurez-vous que l\'appareil cible a démarré le serveur et est sur le même réseau. Vérifiez l\'isolation AP du routeur et le pare-feu.';

  @override
  String scanDevicesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appareils trouvés',
      one: '$count appareil trouvé',
    );
    return '$_temp0';
  }

  @override
  String get rescan => 'Relancer le scan';

  @override
  String get runDiagnostics => 'Exécuter les diagnostics';

  @override
  String get about => 'À propos';

  @override
  String get version => 'Version';

  @override
  String get checkUpdate => 'Vérifier les mises à jour';

  @override
  String get feedback => 'Commentaires';

  @override
  String get openSource => 'Licences open source';

  @override
  String get license => 'Licence';

  @override
  String get permissionRequired => 'Permission requise';

  @override
  String get permissionDenied => 'Permission refusée';

  @override
  String get permissionPermanentlyDenied => 'Permission définitivement refusée';

  @override
  String get permissionStorage => 'Permission de stockage';

  @override
  String get permissionStorageDesc =>
      'La permission de stockage est requise pour enregistrer et lire les fichiers';

  @override
  String get permissionNotification => 'Permission de notification';

  @override
  String get permissionNotificationDesc =>
      'La permission de notification est requise pour afficher la progression du transfert';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get permissionWarning =>
      'Certaines permissions ne sont pas accordées, certaines fonctionnalités peuvent être limitées';

  @override
  String get error => 'Erreur';

  @override
  String get errorUnknown => 'Erreur inconnue';

  @override
  String get errorNetwork => 'Erreur réseau';

  @override
  String get errorFileNotFound => 'Fichier introuvable';

  @override
  String get errorPermission => 'Erreur de permission';

  @override
  String get errorStorage => 'Erreur de stockage';

  @override
  String get errorServer => 'Erreur du serveur';

  @override
  String get errorServerStart => 'Échec du démarrage du serveur';

  @override
  String get errorServerStop => 'Échec de l\'arrêt du serveur';

  @override
  String get errorConnection => 'Erreur de connexion';

  @override
  String get errorTimeout => 'Délai de connexion dépassé';

  @override
  String get retry => 'Réessayer';

  @override
  String get copied => 'Copié';

  @override
  String get copyFailed => 'Échec de la copie';

  @override
  String get saved => 'Enregistré';

  @override
  String get saveFailed => 'Échec de l\'enregistrement';

  @override
  String get deleted => 'Supprimé';

  @override
  String get deleteFailed => 'Échec de la suppression';

  @override
  String get loading => 'Chargement';

  @override
  String get success => 'Succès';

  @override
  String get warning => 'Avertissement';

  @override
  String get info => 'Information';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Fermer';

  @override
  String get selectFilesFailed => 'Échec de la sélection des fichiers';

  @override
  String get selectFolderFailed => 'Échec de la sélection du dossier';

  @override
  String folderFilesAdded(int count) {
    return '$count fichiers ajoutés depuis le dossier';
  }

  @override
  String get folderContainsNoFiles =>
      'Le dossier sélectionné ne contient aucun fichier à envoyer';

  @override
  String get openFileFailed => 'Échec de l\'ouverture du fichier';

  @override
  String get openFolderFailed => 'Échec de l\'ouverture du dossier';

  @override
  String get fileNotExist => 'Le fichier n\'existe pas';

  @override
  String get folderNotExist => 'Le dossier n\'existe pas';

  @override
  String get diagnosticsTitle => 'Diagnostics réseau';

  @override
  String get diagnosticsRunning => 'Exécution des diagnostics en cours...';

  @override
  String get diagnosticsComplete => 'Diagnostics terminés';

  @override
  String get diagnosticsFailed => 'Échec des diagnostics';

  @override
  String get networkStatus => 'État du réseau';

  @override
  String get wifiConnected => 'WiFi connecté';

  @override
  String get wifiDisconnected => 'WiFi déconnecté';

  @override
  String get mobileData => 'Données mobiles';

  @override
  String get noConnection => 'Aucune connexion';

  @override
  String get ipAddress => 'Adresse IP';

  @override
  String get noIpAddress => 'Aucune adresse IP';

  @override
  String get serverStatusCheck => 'Vérification de l\'état du serveur';

  @override
  String get portCheck => 'Vérification du port';

  @override
  String get portAvailable => 'Port disponible';

  @override
  String get portUnavailable => 'Port indisponible';

  @override
  String get suggestions => 'Suggestions';

  @override
  String get syncClipboard => 'Synchroniser le presse-papiers distant';

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Envoyer $count fichiers',
      one: 'Envoyer $count fichier',
    );
    return '$_temp0';
  }

  @override
  String get sendFile => 'Envoyer un fichier';

  @override
  String get shareViaQr => 'Partager par QR';

  @override
  String get webShareTitle => 'Scanner pour recevoir';

  @override
  String get webShareHint =>
      'Le destinataire scanne avec l’appareil photo système et télécharge dans le navigateur — sans installer l’app. Restez sur le même Wi‑Fi / LAN. Certains scanners tiers peuvent bloquer les liens locaux ; utilisez Copier le lien.';

  @override
  String get webShareCopyLink => 'Copier le lien';

  @override
  String get webShareLinkCopied => 'Lien copié';

  @override
  String get webShareStopSharing => 'Arrêter le partage';

  @override
  String get webShareStopped => 'Partage web arrêté';

  @override
  String get webShareServerRequired =>
      'Démarrez le serveur local avant de partager par QR';

  @override
  String get webShareCreated =>
      'Partage web créé. Le destinataire peut scanner pour télécharger.';

  @override
  String get webShareFailed => 'Échec de la création du partage web';

  @override
  String get webSharePeerName => 'Partage web';

  @override
  String webShareFilesSummary(int count, String size) {
    return '$count fichier(s) · $size';
  }

  @override
  String webShareExpiresIn(String time) {
    return 'Expire dans $time';
  }

  @override
  String get releaseToAdd => 'Relâchez pour ajouter des fichiers';

  @override
  String get serverNotRunning =>
      'Le serveur n\'est pas en cours d\'exécution, impossible de recevoir les fichiers partagés';

  @override
  String get cannotReceiveFiles => 'Impossible de recevoir les fichiers';

  @override
  String get sendingInProgress =>
      'Transfert de fichier en cours, veuillez réessayer plus tard';

  @override
  String get pleaseTryLater => 'Veuillez réessayer plus tard';

  @override
  String filesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers partagés ajoutés',
      one: '$count fichier partagé ajouté',
    );
    return '$_temp0';
  }

  @override
  String get preparingSend => 'Préparation de l\'envoi...';

  @override
  String get transferring => 'Transfert en cours';

  @override
  String transferProgress(int current, int total, String fileName) {
    return '[$current/$total] $fileName: Transfert en cours...';
  }

  @override
  String get networkChanged => 'Réseau modifié, adresse du serveur mise à jour';

  @override
  String get serverAddressUpdated => 'Adresse du serveur mise à jour';

  @override
  String get portCannotBeEmpty => 'Le port ne peut pas être vide';

  @override
  String get portMustBeNumber => 'Le port doit être un nombre';

  @override
  String get portRange => 'Plage de ports : 1-65535';

  @override
  String ipDeleted(String ip) {
    return 'IP supprimée : $ip';
  }

  @override
  String get runningDiagnostics => 'Exécution des diagnostics réseau...';

  @override
  String get targetDeviceInfo => 'Informations sur l\'appareil cible';

  @override
  String get fullAddress => 'Adresse complète';

  @override
  String get targetNotSet => 'Appareil cible non défini';

  @override
  String get diagnosticsReport => 'Rapport de diagnostics réseau';

  @override
  String get reportCopied =>
      'Rapport de diagnostics copié dans le presse-papiers';

  @override
  String get deviceNameCannotBeEmpty =>
      'Le nom de l\'appareil ne peut pas être vide';

  @override
  String get deviceNameSaved => 'Nom de l\'appareil enregistré';

  @override
  String get resetDeviceName => 'Réinitialiser le nom de l\'appareil';

  @override
  String resetDeviceNameConfirm(String model) {
    return 'Êtes-vous sûr de vouloir réinitialiser le nom de l\'appareil à \"$model\" ?';
  }

  @override
  String get reset => 'Réinitialiser';

  @override
  String get confirmChange => 'Confirmer la modification';

  @override
  String concurrentTransfersIncrease(int from, int to) {
    return 'Modifier le nombre de transferts simultanés de $from à $to ?\n\nNote : L\'augmentation peut améliorer la vitesse mais augmenter la charge de l\'appareil';
  }

  @override
  String concurrentTransfersDecrease(int from, int to) {
    return 'Modifier le nombre de transferts simultanés de $from à $to ?\n\nNote : La diminution peut réduire la charge de l\'appareil mais diminuer la vitesse';
  }

  @override
  String get concurrentTransfersHint => 'Conseil sur les transferts simultanés';

  @override
  String get concurrentTransfersSaved =>
      'Nombre de transferts simultanés enregistré';

  @override
  String get enterValidNumber => 'Veuillez entrer un nombre valide';

  @override
  String historyCountRange(int min, int max) {
    return 'Plage du nombre d\'historiques : $min-$max';
  }

  @override
  String maxHistoryChange(int from, int to) {
    return 'Modifier le nombre maximum d\'éléments d\'historique de $from à $to ?\n\n';
  }

  @override
  String currentHistoryCount(int count) {
    return 'Nombre d\'historiques actuel : $count éléments\n\n';
  }

  @override
  String get historyWarning =>
      '⚠️ Avertissement : Le nombre d\'historiques actuel dépasse la nouvelle limite.\n\n';

  @override
  String historyDeleteWarning(int current, int max, int toDelete) {
    return 'Seuls les $max éléments les plus récents seront conservés, $toDelete anciens éléments seront supprimés.';
  }

  @override
  String get historyHint =>
      'Note : Le nouveau paramètre prendra effet lors du prochain enregistrement.';

  @override
  String historyDeleted(int count) {
    return 'Paramètres enregistrés, $count anciens éléments supprimés';
  }

  @override
  String get maxHistorySaved =>
      'Nombre maximum d\'éléments d\'historique enregistré';

  @override
  String clipboardSizeRange(int min, int max) {
    return 'Plage de taille du presse-papiers : $min-$max Mo';
  }

  @override
  String maxClipboardSizeChange(int from, int to) {
    return 'Modifier la taille maximale du presse-papiers de $from Mo à $to Mo ?\n\n';
  }

  @override
  String get clipboardSizeDecreaseHint =>
      '⚠️ Note : Après la diminution, le contenu du presse-papiers dépassant la limite ne pourra pas être synchronisé. Utilisez le transfert de fichiers à la place.';

  @override
  String get clipboardSizeIncreaseHint =>
      'Note : Après l\'augmentation, un contenu de presse-papiers plus volumineux peut être synchronisé, mais cela peut affecter la vitesse de transfert.';

  @override
  String get maxClipboardSizeSaved =>
      'Taille maximale du presse-papiers enregistrée';

  @override
  String get ipValidationEnabled => 'Validation IP activée';

  @override
  String get ipValidationDisabled => 'Validation IP désactivée';

  @override
  String get deviceSecretKeyCleared => 'Clé secrète de l\'appareil effacée';

  @override
  String get deviceSecretKeySaved => 'Clé secrète de l\'appareil enregistrée';

  @override
  String get loadingDevInfo =>
      'Chargement des informations de développement...';

  @override
  String get copyLog => 'Copier le journal';

  @override
  String logCopied(int lines) {
    return 'Les $lines dernières lignes du journal ont été copiées dans le presse-papiers';
  }

  @override
  String get logFileEmpty => 'Le fichier journal est vide';

  @override
  String get devInfo => 'Informations de développement';

  @override
  String labelCopied(String label, String value) {
    return '$label copié : $value';
  }

  @override
  String get transferSettings => 'Paramètres de transfert';

  @override
  String get concurrentTransfers => 'Transferts simultanés';

  @override
  String concurrentTransfersDesc(int max) {
    return 'Nombre de transferts de fichiers simultanés (1-$max)';
  }

  @override
  String get concurrentTransfersHintText =>
      'Une concurrence plus élevée peut mieux utiliser la bande passante mais peut augmenter la charge de l\'appareil';

  @override
  String get maxHistory => 'Nombre maximum d\'éléments d\'historique';

  @override
  String maxHistoryDesc(int min, int max) {
    return 'Nombre maximum d\'enregistrements de transfert à sauvegarder ($min-$max)';
  }

  @override
  String maxHistoryHintText(int min, int max) {
    return 'Entrez le nombre ($min-$max)';
  }

  @override
  String get oldRecordsAutoDelete =>
      'Les anciens enregistrements dépassant la limite seront automatiquement supprimés, ne conservant que les plus récents';

  @override
  String get maxClipboard => 'Taille maximale du presse-papiers';

  @override
  String maxClipboardDesc(int min, int max) {
    return 'Taille maximale du presse-papiers autorisée pour la synchronisation ($min-$max Mo)';
  }

  @override
  String maxClipboardHintText(int min, int max) {
    return 'Entrez la taille ($min-$max Mo)';
  }

  @override
  String get clipboardSyncLimit =>
      'Le contenu du presse-papiers dépassant cette taille ne peut pas être synchronisé, utilisez le transfert de fichiers à la place';

  @override
  String get ipValidation => 'Validation IP';

  @override
  String get ipValidationDesc =>
      'Valider si l\'adresse IP de l\'appareil cible est dans le même sous-réseau';

  @override
  String get ipValidationEnabledHint =>
      'Lorsqu\'elle est activée, vérifie si l\'IP cible est dans le même sous-réseau pour éviter de se connecter aux mauvais appareils';

  @override
  String get ipValidationDisabledHint =>
      'Lorsqu\'elle est désactivée, ne vérifie pas le sous-réseau IP, adapté aux environnements réseau complexes (point d\'accès, VPN, etc.)';

  @override
  String get deviceSecretKey => 'Clé secrète de l\'appareil';

  @override
  String get deviceSecretKeyDesc =>
      'Lorsqu\'elle est définie, les autres appareils doivent fournir la clé correcte pour ignorer la confirmation';

  @override
  String get deviceSecretKeyHint =>
      'Entrez la clé secrète (laissez vide pour désactiver)';

  @override
  String get notSet => 'Non défini';

  @override
  String get author => 'Auteur';

  @override
  String get update => 'Mise à jour';

  @override
  String get github => 'GitHub';

  @override
  String get githubLinkCopied => 'Lien GitHub copié';

  @override
  String get openGitHubFailed =>
      'Impossible d\'ouvrir le navigateur ; lien copié à la place';

  @override
  String get appDescription =>
      'Un outil de transfert de fichiers LAN simple et facile à utiliser';

  @override
  String get targetDeviceIP => 'Adresse IP de l\'appareil cible';

  @override
  String get ipHint => 'ex. : 192.168.1.100';

  @override
  String get clear => 'Effacer';

  @override
  String get history => 'Historique';

  @override
  String get targetDevicePort => 'Port de l\'appareil cible';

  @override
  String resetToDefaultPort(int port) {
    return 'Réinitialiser au port par défaut ($port)';
  }

  @override
  String get targetDeviceSecretKey =>
      'Clé secrète de l\'appareil cible (facultatif)';

  @override
  String get secretKeyHint => 'La clé correcte peut ignorer la confirmation';

  @override
  String get aboutSecretKey => 'À propos de la clé secrète';

  @override
  String get secretKeyFeatureTitle => 'Fonctionnalité de clé secrète';

  @override
  String get secretKeyFeatureDesc =>
      'Si l\'appareil cible a défini une clé secrète, entrer la clé correcte vous permet d\'ignorer la boîte de dialogue de confirmation et de transférer directement des fichiers ou de synchroniser le presse-papiers.';

  @override
  String get secretKeyUsageSteps => 'Étapes d\'utilisation :';

  @override
  String get secretKeyUsageStep1 =>
      '1. L\'appareil cible définit sa clé secrète dans les paramètres';

  @override
  String get secretKeyUsageStep2 =>
      '2. Entrez la clé secrète de l\'appareil cible dans ce champ';

  @override
  String get secretKeyUsageStep3 =>
      '3. Lors de l\'envoi de fichiers ou de la demande du presse-papiers, si la clé est correcte, l\'autre partie acceptera automatiquement';

  @override
  String get secretKeyTip =>
      'Conseil : Laissez vide pour utiliser la confirmation manuelle traditionnelle';

  @override
  String get secretKeyDescription => 'Description de la clé secrète';

  @override
  String get clearSecretKey => 'Effacer la clé secrète';

  @override
  String get gotIt => 'Compris';

  @override
  String get localIP => 'IP locale';

  @override
  String ipCopied(String ip) {
    return 'Adresse IP copiée : $ip';
  }

  @override
  String get transferred => 'Transféré';

  @override
  String get transferSpeed => 'Vitesse de transfert';

  @override
  String get remainingTime => 'Temps restant';

  @override
  String transferringProgress(double progress) {
    final intl.NumberFormat progressNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String progressString = progressNumberFormat.format(progress);

    return 'Transfert en cours $progressString%';
  }

  @override
  String get storagePermissionMessage =>
      'La permission de stockage est requise pour sélectionner des fichiers. Veuillez l\'activer manuellement dans les paramètres.';

  @override
  String get checkingTargetDevice => 'Vérification de l\'appareil cible...';

  @override
  String get targetDeviceUnavailable => 'Appareil cible indisponible';

  @override
  String targetDeviceError(String error) {
    return 'Appareil cible indisponible\nErreur : $error';
  }

  @override
  String get connectionFailed => 'Échec de la connexion';

  @override
  String get transferHistory => 'Historique des transferts';

  @override
  String get clearHistoryTitle => 'Effacer l\'historique';

  @override
  String get clearHistoryMessage =>
      'Êtes-vous sûr de vouloir effacer tout l\'historique des transferts ? Cette action ne peut pas être annulée.';

  @override
  String get noFilteredRecords => 'Aucun enregistrement correspondant';

  @override
  String get filterAll => 'Tout';

  @override
  String get filterSent => 'Envoyé';

  @override
  String get filterReceived => 'Reçu';

  @override
  String get statisticsInfo => 'Statistiques';

  @override
  String transfersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transferts',
      one: '$count transfert',
    );
    return '$_temp0';
  }

  @override
  String get totalTransfers => 'Total';

  @override
  String get successfulTransfers => 'Succès';

  @override
  String get failedTransfers => 'Échoué';

  @override
  String get sentFiles => 'Envoyé';

  @override
  String get receivedFiles => 'Reçu';

  @override
  String get totalSize => 'Taille totale';

  @override
  String get moreActions => 'Plus d\'actions';

  @override
  String get deleteRecord => 'Supprimer l\'enregistrement';

  @override
  String get viewDetails => 'Voir les détails';

  @override
  String get deleteRecordTitle => 'Supprimer l\'enregistrement';

  @override
  String deleteRecordMessage(String fileName) {
    return 'Êtes-vous sûr de vouloir supprimer l\'enregistrement de transfert pour \"$fileName\" ?\n\nNote : Cela supprimera uniquement l\'enregistrement, pas le fichier lui-même.';
  }

  @override
  String get deleteRecordNote =>
      'Note : Cela supprimera uniquement l\'enregistrement, pas le fichier lui-même.';

  @override
  String get recordDeleted => 'Enregistrement supprimé';

  @override
  String get filePathNotExist => 'Le chemin du fichier n\'existe pas';

  @override
  String get cannotOpenFile => 'Impossible d\'ouvrir le fichier';

  @override
  String cannotOpenFileWithMessage(String message) {
    return 'Impossible d\'ouvrir le fichier : $message';
  }

  @override
  String get iosNoFolderSupport =>
      'iOS ne prend pas en charge l\'ouverture directe des dossiers';

  @override
  String get cannotOpenFolder => 'Impossible d\'ouvrir le dossier';

  @override
  String get recentFilesOpened =>
      'Fichiers récents ouverts, veuillez rechercher manuellement';

  @override
  String get receiveRecord => 'Enregistrement de réception';

  @override
  String get sendRecord => 'Enregistrement d\'envoi';

  @override
  String get fileName => 'Nom du fichier';

  @override
  String get fromDevice => 'De l\'appareil';

  @override
  String get toDevice => 'Vers l\'appareil';

  @override
  String get deviceIP => 'IP de l\'appareil';

  @override
  String get transferTime => 'Heure du transfert';

  @override
  String get transferStatus => 'État du transfert';

  @override
  String get statusSuccess => 'Succès';

  @override
  String get statusFailed => 'Échoué';

  @override
  String get savedLocation => 'Emplacement enregistré';

  @override
  String get copy => 'Copier';

  @override
  String get pathCopied => 'Chemin copié dans le presse-papiers';

  @override
  String get from => 'De';

  @override
  String get sentTo => 'Envoyé à';

  @override
  String get clipboardRequest => 'Demande de presse-papiers';

  @override
  String clipboardRequestFrom(String deviceName) {
    return 'L\'appareil \"$deviceName\" demande l\'accès au contenu de votre presse-papiers';
  }

  @override
  String get allowClipboardRequest => 'Autoriser cette demande ?';

  @override
  String get clipboardRequestMessage => 'Demande de presse-papiers';

  @override
  String autoRejectIn(int seconds) {
    return 'Rejet automatique dans $seconds secondes';
  }

  @override
  String get reject => 'Rejeter';

  @override
  String get allow => 'Autoriser';

  @override
  String clipboardSharedWithSecretKey(String deviceName) {
    return '$deviceName vérifié avec la clé secrète, presse-papiers partagé automatiquement';
  }

  @override
  String get clipboardRequestRejected =>
      'L\'utilisateur a rejeté la demande de presse-papiers';

  @override
  String get clipboardEmpty => 'Le presse-papiers est vide';

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

    return 'Contenu du presse-papiers trop volumineux ($actualSizeMBString Mo), dépasse la limite de l\'appareil destinataire ($maxSizeMB Mo). Veuillez utiliser le transfert de fichiers à la place.';
  }

  @override
  String get clipboardContentSuccess =>
      'Contenu du presse-papiers récupéré avec succès';

  @override
  String get invalidJsonFormat => 'Format JSON invalide';

  @override
  String get serverInternalError => 'Erreur interne du serveur';

  @override
  String get backgroundRejectNeedsSecretKey =>
      'L\'appareil est en arrière-plan. Seule la synchronisation/réception automatique avec clé secrète correspondante est prise en charge.';

  @override
  String get foregroundServiceNotificationTitle => 'IcyEasySend';

  @override
  String get foregroundServiceNotificationText =>
      'En attente des transferts et de la synchro presse-papiers en arrière-plan';

  @override
  String get androidBackgroundReceiveHint =>
      'En arrière-plan, seuls les appareils avec une clé secrète correspondante peuvent synchroniser ou envoyer automatiquement. Conservez la notification persistante.';

  @override
  String get clipboardOverlay => 'Bouton flottant presse-papiers';

  @override
  String get clipboardOverlayDesc =>
      'Appuyez sur le bouton flottant pour actualiser le cache texte/image pour la synchro en arrière-plan';

  @override
  String get clipboardOverlayHint =>
      'En arrière-plan, seul le dernier contenu actualisé peut être synchronisé. Désactiver vide le cache et masque le bouton.';

  @override
  String get clipboardOverlayPermissionNeeded =>
      'Autorisez \"Afficher par-dessus d\'autres applications\" dans les paramètres. Le bouton apparaîtra à votre retour.';

  @override
  String get clipboardOverlayEnabledToast =>
      'Bouton flottant presse-papiers activé';

  @override
  String get clipboardBackgroundCacheMiss =>
      'Impossible de lire le presse-papiers système en arrière-plan et aucun cache disponible. Ouvrez l\'app ou appuyez sur le bouton flottant pour actualiser.';

  @override
  String get requestingClipboard => 'Demande du presse-papiers...';

  @override
  String get clipboardSyncSuccess => 'Presse-papiers synchronisé avec succès';

  @override
  String get textClipboardSyncSuccess =>
      'Presse-papiers texte synchronisé avec succès';

  @override
  String get fileClipboardSyncSuccess =>
      'Presse-papiers de fichiers synchronisé avec succès\nVous pouvez coller dans l\'application ou le gestionnaire de fichiers';

  @override
  String get clipboardSyncFailed =>
      'Échec de la synchronisation du presse-papiers';

  @override
  String get syncFailed => 'Échec de la synchronisation';

  @override
  String clipboardRequestError(String error) {
    return 'Une erreur s\'est produite lors de la demande du presse-papiers : $error';
  }

  @override
  String invalidFilesMessage(String fileNames) {
    return 'Les fichiers suivants sont invalides ou inaccessibles :\n$fileNames';
  }

  @override
  String get waitingForReceiverConfirmation =>
      'En attente de la confirmation du destinataire...';

  @override
  String get fileSendSuccess => 'Fichier envoyé avec succès !';

  @override
  String filesSendSuccess(int count) {
    return '$count fichiers envoyés avec succès !';
  }

  @override
  String get allFilesSendFailed => 'Échec de l\'envoi de tous les fichiers';

  @override
  String get failedFiles => 'Fichiers échoués';

  @override
  String get transferComplete => 'Transfert terminé';

  @override
  String get successCount => 'Succès';

  @override
  String get failureCount => 'Échoué';

  @override
  String transferSummary(
    int successCount,
    int failureCount,
    String failedFiles,
  ) {
    return 'Succès : $successCount fichiers\nÉchoué : $failureCount fichiers\n\nFichiers échoués :\n$failedFiles';
  }

  @override
  String get preparingTransferInfo =>
      'Préparation des informations de transfert...';

  @override
  String waitingForReceiverConfirmFiles(int count) {
    return 'En attente de la confirmation du destinataire pour $count fichiers...';
  }

  @override
  String transferringFile(int current, int total, String fileName) {
    return 'Transfert du fichier $current/$total : $fileName';
  }

  @override
  String get receiverRejected => 'Le destinataire a rejeté';

  @override
  String receiverRejectedWithStatus(int statusCode) {
    return 'Le destinataire a rejeté\nCode d\'état : $statusCode';
  }

  @override
  String get transferIdNotFound => 'ID de transfert introuvable';

  @override
  String get waitingForConfirmation => 'En attente de confirmation...';

  @override
  String get preparingToReceive => 'Préparation de la réception...';

  @override
  String get rejected => 'Rejeté';

  @override
  String get receiveComplete => 'Réception terminée';

  @override
  String receivingProgress(double progress) {
    final intl.NumberFormat progressNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String progressString = progressNumberFormat.format(progress);

    return 'Réception en cours... $progressString%';
  }

  @override
  String receivingFiles(int count) {
    return 'Réception de $count fichiers';
  }

  @override
  String receiveFilesCount(int count) {
    return 'Recevoir $count fichiers';
  }

  @override
  String get sender => 'Expéditeur';

  @override
  String get totalSizeBatch => 'Taille totale';

  @override
  String get fileList => 'Liste des fichiers';

  @override
  String get allFilesReceiveComplete =>
      'Tous les fichiers ont été reçus avec succès !';

  @override
  String get receivingFiles2 => 'Réception des fichiers...';

  @override
  String autoRejectCountdown(int seconds) {
    return 'Accepter ces fichiers ? (Rejet automatique dans $seconds secondes)';
  }

  @override
  String get rejectAll => 'Tout rejeter';

  @override
  String get acceptAll => 'Tout accepter';

  @override
  String get networkDiagnosticsReport => 'Rapport de diagnostics réseau';

  @override
  String get localNetworkInterfaces => 'Interfaces réseau locales';

  @override
  String get noValidNetworkInterface =>
      'Aucune interface réseau valide trouvée';

  @override
  String get privateNetworkAddress => 'Adresse réseau privée';

  @override
  String get targetDeviceReachability => 'Accessibilité de l\'appareil cible';

  @override
  String get canConnectToTarget => 'Peut se connecter à l\'appareil cible';

  @override
  String get cannotConnectToTarget =>
      'Impossible de se connecter à l\'appareil cible';

  @override
  String get healthCheckTest => 'Test de vérification de l\'état';

  @override
  String get healthCheckSuccess => 'Vérification de l\'état réussie';

  @override
  String get healthCheckFailed => 'Échec de la vérification de l\'état';

  @override
  String get statusCode => 'Code d\'état';

  @override
  String get response => 'Réponse';

  @override
  String get internetConnection => 'Connexion Internet';

  @override
  String get hasInternetConnection => 'A une connexion Internet';

  @override
  String get noInternetConnection => 'Pas de connexion Internet';

  @override
  String get networkConnectionFailed =>
      'Impossible de se connecter à l\'appareil cible, veuillez vérifier la connexion réseau et l\'adresse IP';

  @override
  String get networkTimeout =>
      'Délai de connexion dépassé, l\'appareil cible peut être hors ligne ou le réseau est instable';

  @override
  String get networkRequestFailed =>
      'Échec de la requête réseau, veuillez vérifier la connexion réseau';

  @override
  String get transferTimeout =>
      'Délai de transfert dépassé, veuillez vérifier la connexion réseau';

  @override
  String get transferInterrupted => 'Transfert interrompu, veuillez réessayer';

  @override
  String get fileNotFound => 'Fichier introuvable';

  @override
  String get fileNotReadable =>
      'Impossible de lire le fichier, veuillez vous assurer que le fichier existe et dispose des autorisations d\'accès';

  @override
  String get fileAccessError =>
      'Erreur d\'accès au fichier, veuillez vérifier les autorisations du fichier';

  @override
  String get fileSaveFailed => 'Échec de l\'enregistrement du fichier';

  @override
  String get fileSizeMismatch =>
      'Échec de l\'enregistrement du fichier : taille du fichier non concordante';

  @override
  String get invalidFileName =>
      'Le nom du fichier contient des caractères invalides';

  @override
  String get downloadsDirectoryUnavailable =>
      'Impossible d\'accéder au répertoire de téléchargements';

  @override
  String get storageInsufficient =>
      'Espace de stockage insuffisant, impossible de recevoir le fichier';

  @override
  String get diskFullTitle => 'Disque plein';

  @override
  String get storageCheckFailed =>
      'Impossible de vérifier l\'espace de stockage';

  @override
  String get networkPermissionDenied =>
      'L\'autorisation d\'accès au réseau est requise pour transférer des fichiers';

  @override
  String get storagePermissionDenied =>
      'L\'autorisation d\'accès au stockage est requise pour enregistrer des fichiers';

  @override
  String serverStartFailed(String reason) {
    return 'Impossible de démarrer le serveur : $reason';
  }

  @override
  String get serverPortsOccupied =>
      'Impossible de démarrer le serveur : tous les ports sont occupés';

  @override
  String serverPortsOccupiedRange(int defaultPort, int maxPort) {
    return 'Impossible de démarrer le serveur : les ports $defaultPort-$maxPort sont tous occupés';
  }

  @override
  String get serverUnknownError =>
      'Impossible de démarrer le serveur : erreur inconnue';

  @override
  String get transferRejected => 'Transfert rejeté par le destinataire';

  @override
  String get fileTooLarge =>
      'Fichier trop volumineux, maximum 2 Go pris en charge';

  @override
  String get fileOrStorageFull =>
      'Fichier trop volumineux ou espace de stockage du destinataire insuffisant';

  @override
  String get receiveTimeout =>
      'Délai de réception dépassé, rejeté automatiquement';

  @override
  String get userRejected => 'L\'utilisateur a rejeté le transfert de fichier';

  @override
  String get ipAddressEmpty => 'L\'adresse IP ne peut pas être vide';

  @override
  String get ipAddressInvalidFormat =>
      'Format d\'adresse IP invalide, veuillez utiliser le format xxx.xxx.xxx.xxx';

  @override
  String get ipAddressInvalidRange =>
      'Format d\'adresse IP invalide, chaque nombre doit être entre 0 et 255';

  @override
  String get ipAddressSpecial1 =>
      'Impossible d\'utiliser 0.0.0.0 comme adresse cible';

  @override
  String get ipAddressSpecial2 =>
      'Impossible d\'utiliser l\'adresse de diffusion 255.255.255.255';

  @override
  String ipAddressNotInSameSubnet(
    String localIP,
    String targetIP,
    String localNetwork,
    String targetNetwork,
  ) {
    return '⚠️ Incompatibilité de sous-réseau\nIP locale : $localIP (sous-réseau : $localNetwork.x)\nIP cible : $targetIP (sous-réseau : $targetNetwork.x)\n\nNote : Les deux appareils doivent être sur le même réseau local (même sous-réseau) pour transférer des fichiers.\nPour les adresses IPv4 de classe C, les trois premiers nombres doivent être identiques, par exemple tous deux 192.168.2, seul le dernier nombre diffère\nLe moyen le plus simple est de connecter les deux appareils au même WiFi ou routeur.\n';
  }

  @override
  String get responseParseError =>
      'Impossible d\'analyser la réponse du serveur';

  @override
  String get responseInvalidFormat =>
      'Le format de réponse de l\'appareil cible est incorrect';

  @override
  String responseStatusCodeError(int statusCode) {
    return 'Le serveur a renvoyé un code d\'état d\'erreur : $statusCode';
  }

  @override
  String get fileSelectionError =>
      'Une erreur s\'est produite lors de la sélection du fichier';

  @override
  String get fileSelectionCancelled => 'Sélection de fichier annulée';

  @override
  String genericError(String operation) {
    return '$operation a échoué';
  }

  @override
  String unexpectedError(String details) {
    return 'Une erreur inattendue s\'est produite : $details';
  }

  @override
  String networkError(String context) {
    return 'Erreur réseau : $context';
  }

  @override
  String fileError(String context) {
    return 'Erreur de fichier : $context';
  }

  @override
  String permissionError(String permissionType) {
    return 'L\'autorisation $permissionType est requise pour continuer';
  }

  @override
  String get foregroundServiceChannelName =>
      'Service de transfert en arrière-plan';

  @override
  String get foregroundServiceChannelDescription =>
      'Maintient l\'app capable de recevoir fichiers LAN et requêtes presse-papiers en arrière-plan';

  @override
  String get peerUnreachable => 'Impossible de joindre l\'appareil cible';

  @override
  String get peerUnreachableBoth =>
      'Appareil inaccessible (réseau local et relais)';

  @override
  String get peerUnsupported =>
      'La version de l\'autre appareil est trop ancienne pour l\'appairage';

  @override
  String get identityMismatch =>
      'Le code de l\'appareil ne correspond pas à sa clé publique, appairage annulé';

  @override
  String get cannotPairSelf =>
      'Impossible d\'appairer l\'appareil avec lui-même';

  @override
  String get pairingTitle => 'Appairage d\'appareils';

  @override
  String get compareHint =>
      'Vérifiez que les deux appareils affichent exactement le même nombre. Sinon, la connexion a peut-être été altérée.';

  @override
  String get compareHintRelay =>
      'Cet appareil n\'est pas sur le même réseau. Comparez les 6 chiffres de vive voix avec l\'autre personne et ne confirmez qu\'en cas d\'identité parfaite. Sans cette vérification, il n\'y a aucune protection.';

  @override
  String get pairOverRelay => 'Appairer via le relais';

  @override
  String get enterDeviceCode =>
      'Saisissez le code à 32 caractères de l\'autre appareil';

  @override
  String get invalidDeviceCode =>
      'Le code doit comporter 32 caractères hexadécimaux';

  @override
  String get alreadyPaired =>
      'Cet appareil est déjà dans la liste de confiance';

  @override
  String get peerAlreadyPaired =>
      'The other device still trusts this one; unpair on that device first';

  @override
  String get relayUnavailable => 'Connectez d\'abord le serveur relais';

  @override
  String get peerBusy => 'L\'autre appareil traite déjà une autre demande';

  @override
  String get peerPairingBlocked =>
      'The other device has blocked this one; ask them to unblock it first';

  @override
  String get peerRelayPairingOff =>
      'L\'autre appareil n\'accepte pas les demandes via le relais';

  @override
  String incomingRequest(String deviceName) {
    return '« $deviceName » demande à s\'appairer avec cet appareil';
  }

  @override
  String outgoingRequest(String deviceName) {
    return 'Appairage avec « $deviceName »';
  }

  @override
  String get waitingPeer => 'En attente de confirmation…';

  @override
  String get peerAccepted => 'L\'autre appareil a confirmé';

  @override
  String get peerRejected => 'L\'autre appareil a refusé l\'appairage';

  @override
  String get peerTimeout => 'L\'autre appareil n\'a pas confirmé à temps';

  @override
  String get pairingFailed => 'Échec de l\'appairage';

  @override
  String pairingSucceeded(String deviceName) {
    return 'Appairage avec « $deviceName » terminé';
  }

  @override
  String get codesMatch => 'Les nombres correspondent, appairer';

  @override
  String get codesDiffer => 'Différents, annuler';

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
  String get pairedDevicesTitle => 'Appareils appairés';

  @override
  String get pairedDevicesEmpty => 'Aucun appareil appairé';

  @override
  String get addPairedDevice => 'Appairer un appareil';

  @override
  String get unpair => 'Dissocier';

  @override
  String unpairConfirm(String deviceName) {
    return 'Après la suppression de « $deviceName », il faudra à nouveau comparer les nombres. Confirmer ?';
  }

  @override
  String get deviceCodeLabel => 'Code de cet appareil';

  @override
  String get title => 'Serveur relais';

  @override
  String get description =>
      'Transfère les fichiers via votre propre serveur quand les appareils ne sont pas sur le même réseau. La connexion directe reste prioritaire.';

  @override
  String get encryptionNotice =>
      'Les fichiers sont chiffrés de bout en bout entre les deux appareils appairés, seuls eux peuvent les déchiffrer. Le serveur ne voit que l\'horodatage et le nombre d\'octets.';

  @override
  String get acceptPairingLabel =>
      'Accepter les demandes d\'appairage via le relais';

  @override
  String get acceptPairingHint =>
      'Tout appareil disposant du jeton du serveur peut solliciter votre code d\'appareil. Un appareil refusé ne réapparaît plus.';

  @override
  String get iosForegroundNotice =>
      'Sur iOS, la réception via le relais ne fonctionne que lorsque l\'application est ouverte.';

  @override
  String get enableLabel => 'Activer le relais';

  @override
  String get serverUrlLabel => 'Adresse du serveur';

  @override
  String get tokenLabel => 'Jeton d\'accès';

  @override
  String get invalidUrl => 'L\'adresse doit commencer par http:// ou https://';

  @override
  String get insecureUrlWarning =>
      'Le trafic n\'est pas chiffré avec http://, à réserver aux tests locaux';

  @override
  String get testConnection => 'Tester la connexion';

  @override
  String get testSucceeded => 'Connexion réussie';

  @override
  String get save => 'Enregistrer';

  @override
  String get statusDisabled => 'Désactivé';

  @override
  String get statusConnecting => 'Connexion…';

  @override
  String get statusConnected => 'Connecté';

  @override
  String get statusReconnecting => 'Reconnexion…';

  @override
  String get statusRejected => 'Refusé par le serveur';

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
  String get lanRouteUnavailable => 'Appareil inaccessible via le réseau local';

  @override
  String get relayRouteUnavailable =>
      'Appareil inaccessible via le serveur relais';

  @override
  String get relayNotConnected => 'Non connecté au serveur relais';

  @override
  String get relayPeerOffline =>
      'Le destinataire doit ouvrir l\'application pour recevoir via le relais';

  @override
  String get relayPeerNotPaired =>
      'Le destinataire n\'a pas ajouté cet appareil à sa liste de confiance';

  @override
  String get relayPeerBusy =>
      'Le destinataire traite déjà un autre lot de fichiers';

  @override
  String get relayNeedsPairedDevice =>
      'Le transfert par relais nécessite un appairage préalable';

  @override
  String get relayNegotiatingSession =>
      'Établissement d\'une session chiffrée…';

  @override
  String get relayIdentityMismatch =>
      'Signature invalide : ce n\'est peut-être pas l\'appareil appairé';

  @override
  String get relayTransferNotice =>
      'Transfert via le serveur relais, la vitesse dépend de sa bande passante';

  @override
  String retryingAfterInterruption(int attempt, int maxAttempts) {
    return 'Connexion interrompue, nouvelle tentative ($attempt/$maxAttempts)…';
  }
}
