import 'package:flutter/material.dart';

import '../services/language_service.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';
import 'app_localizations_zh_hk.dart';

/// Base class for app localizations
abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
  ];

  /// Get supported locales from LanguageService
  /// This ensures consistency with language configuration
  static List<Locale> get supportedLocales {
    return LanguageService.getSupportedLanguages().entries
        .where((entry) => entry.key != 'system') // Exclude 'system' option
        .map((entry) => entry.value.locale)
        .toList();
  }

  // App info
  String get appName;

  String get appVersion;

  // Bottom navigation
  String get navHome;

  String get navHistory;

  String get navSettings;

  // Home page
  String get homeTitle;

  String get serverStatus;

  String get serverRunning;

  String get serverStopped;

  String get serverAddress;

  String get deviceName;

  String get storageSpace;

  String get availableSpace;

  String get sendFiles;

  String get receiveFiles;

  String get selectFiles;

  String get selectFolder;

  String get dragDropHint;

  String get noFilesSelected;

  String filesSelected(int count);

  String get clearSelection;

  String get startSending;

  String get sending;

  String get sendSuccess;

  String get sendFailed;

  String get cancel;

  String get confirm;

  // History page
  String get historyTitle;

  String get noHistory;

  String get clearHistory;

  String get sent;

  String get received;

  String get failed;

  String get fileSize;

  String get time;

  String get deleteItem;

  String get deleteItemConfirm;

  String get openFile;

  String get openFolder;

  // Settings page
  String get settingsTitle;

  String get general;

  String get language;

  String get deviceNameSetting;

  String get editDeviceName;

  String get deviceNameHint;

  String get deviceNameEmpty;

  String get port;

  String get portHint;

  String get portInvalid;

  String get portInUse;

  String get savePath;

  String get selectSavePath;

  String get autoStart;

  String get autoStartDesc;

  String get network;

  String get networkDiagnostics;

  String get runDiagnostics;

  String get about;

  String get version;

  String get checkUpdate;

  String get feedback;

  String get openSource;

  String get license;

  // Permissions
  String get permissionRequired;

  String get permissionDenied;

  String get permissionPermanentlyDenied;

  String get permissionStorage;

  String get permissionStorageDesc;

  String get permissionNotification;

  String get permissionNotificationDesc;

  String get openSettings;

  String get permissionWarning;

  // Errors
  String get error;

  String get errorUnknown;

  String get errorNetwork;

  String get errorFileNotFound;

  String get errorPermission;

  String get errorStorage;

  String get errorServer;

  String get errorServerStart;

  String get errorServerStop;

  String get errorConnection;

  String get errorTimeout;

  String get retry;

  // Toast messages
  String get copied;

  String get copyFailed;

  String get saved;

  String get saveFailed;

  String get deleted;

  String get deleteFailed;

  String get loading;

  String get success;

  // Dialog
  String get warning;

  String get info;

  String get yes;

  String get no;

  String get ok;

  String get close;

  // File operations
  String get selectFilesFailed;

  String get selectFolderFailed;

  String get openFileFailed;

  String get openFolderFailed;

  String get fileNotExist;

  String get folderNotExist;

  // Network diagnostics
  String get diagnosticsTitle;

  String get diagnosticsRunning;

  String get diagnosticsComplete;

  String get diagnosticsFailed;

  String get networkStatus;

  String get wifiConnected;

  String get wifiDisconnected;

  String get mobileData;

  String get noConnection;

  String get ipAddress;

  String get noIpAddress;

  String get serverStatusCheck;

  String get portCheck;

  String get portAvailable;

  String get portUnavailable;

  String get suggestions;

  // Home page - additional
  String get syncClipboard;

  String filesCount(int count);

  String get sendFile;

  String get releaseToAdd;

  String get serverNotRunning;

  String get cannotReceiveFiles;

  String get sendingInProgress;

  String get pleaseTryLater;

  String filesAdded(int count);

  String get preparingSend;

  String get transferring;

  String transferProgress(int current, int total, String fileName);

  String get networkChanged;

  String get serverAddressUpdated;

  String get portCannotBeEmpty;

  String get portMustBeNumber;

  String get portRange;

  String ipDeleted(String ip);

  String get runningDiagnostics;

  String get targetDeviceInfo;

  String get fullAddress;

  String get targetNotSet;

  String get diagnosticsReport;

  String get reportCopied;

  // Settings page - additional
  String get deviceNameCannotBeEmpty;

  String get deviceNameSaved;

  String get resetDeviceName;

  String resetDeviceNameConfirm(String model);

  String get reset;

  String get confirmChange;

  String concurrentTransfersChange(int from, int to);

  String get concurrentTransfersHint;

  String get concurrentTransfersSaved;

  String get enterValidNumber;

  String historyCountRange(int min, int max);

  String maxHistoryChange(int from, int to);

  String currentHistoryCount(int count);

  String get historyWarning;

  String historyDeleteWarning(int current, int max, int toDelete);

  String get historyHint;

  String historyDeleted(int count);

  String get maxHistorySaved;

  String clipboardSizeRange(int min, int max);

  String maxClipboardSizeChange(int from, int to);

  String get clipboardSizeDecreaseHint;

  String get clipboardSizeIncreaseHint;

  String get maxClipboardSizeSaved;

  String get ipValidationEnabled;

  String get ipValidationDisabled;

  String get deviceSecretKeyCleared;

  String get deviceSecretKeySaved;

  String get loadingDevInfo;

  String get copyLog;

  String logCopied(int lines);

  String get logFileEmpty;

  String get devInfo;

  String labelCopied(String label, String value);

  // Transfer settings card
  String get transferSettings;

  String get concurrentTransfers;

  String concurrentTransfersDesc(int max);

  String get concurrentTransfersHintText;

  String get maxHistory;

  String maxHistoryDesc(int min, int max);

  String maxHistoryHintText(int min, int max);

  String get oldRecordsAutoDelete;

  String get maxClipboard;

  String maxClipboardDesc(int min, int max);

  String maxClipboardHintText(int min, int max);

  String get clipboardSyncLimit;

  String get ipValidation;

  String get ipValidationDesc;

  String get ipValidationEnabledHint;

  String get ipValidationDisabledHint;

  String get deviceSecretKey;

  String get deviceSecretKeyDesc;

  String get deviceSecretKeyHint;

  String get notSet;

  // About card
  String get author;

  String get appDescription;

  // Home page widgets - additional
  String get targetDeviceIP;

  String get ipHint;

  String get clear;

  String get history;

  String get targetDevicePort;

  String resetToDefaultPort(int port);

  String get targetDeviceSecretKey;

  String get secretKeyHint;

  String get aboutSecretKey;

  String get secretKeyFeatureTitle;

  String get secretKeyFeatureDesc;

  String get secretKeyUsageSteps;

  String get secretKeyUsageStep1;

  String get secretKeyUsageStep2;

  String get secretKeyUsageStep3;

  String get secretKeyTip;

  String get secretKeyDescription;

  String get clearSecretKey;

  String get gotIt;

  String get localIP;

  String ipCopied(String ip);

  String get transferred;

  String get transferSpeed;

  String get remainingTime;

  String transferringProgress(double progress);

  // Controllers
  String get storagePermissionMessage;

  String get checkingTargetDevice;

  String get targetDeviceUnavailable;

  String targetDeviceError(String error);

  String get connectionFailed;

  // History page - additional
  String get transferHistory;

  String get clearHistoryTitle;

  String get clearHistoryMessage;

  String get noFilteredRecords;

  String get filterAll;

  String get filterSent;

  String get filterReceived;

  String get statisticsInfo;

  String transfersCount(int count);

  String get totalTransfers;

  String get successfulTransfers;

  String get failedTransfers;

  String get sentFiles;

  String get receivedFiles;

  String get totalSize;

  String get moreActions;

  String get deleteRecord;

  String get viewDetails;

  String get deleteRecordTitle;

  String deleteRecordMessage(String fileName);

  String get deleteRecordNote;

  String get recordDeleted;

  String get filePathNotExist;

  String get cannotOpenFile;

  String cannotOpenFileWithMessage(String message);

  String get iosNoFolderSupport;

  String get cannotOpenFolder;

  String get recentFilesOpened;

  String get receiveRecord;

  String get sendRecord;

  String get fileName;

  String get fromDevice;

  String get toDevice;

  String get deviceIP;

  String get transferTime;

  String get transferStatus;

  String get statusSuccess;

  String get statusFailed;

  String get savedLocation;

  String get copy;

  String get pathCopied;

  String get from;

  String get sentTo;

  // Clipboard related
  String get clipboardRequest;

  String clipboardRequestFrom(String deviceName);

  String get allowClipboardRequest;

  String get clipboardRequestMessage;

  String autoRejectIn(int seconds);

  String get reject;

  String get allow;

  String clipboardSharedWithSecretKey(String deviceName);

  String get clipboardRequestRejected;

  String get clipboardEmpty;

  String clipboardContentTooLarge(double actualSizeMB, int maxSizeMB);

  String get clipboardContentSuccess;

  String get invalidJsonFormat;

  String get serverInternalError;

  // Clipboard sync
  String get requestingClipboard;

  String get clipboardSyncSuccess;

  String get textClipboardSyncSuccess;

  String get fileClipboardSyncSuccess;

  String get clipboardSyncFailed;

  String get syncFailed;

  String clipboardRequestError(String error);

  // File transfer
  String invalidFilesMessage(String fileNames);

  String get waitingForReceiverConfirmation;

  String get fileSendSuccess;

  String filesSendSuccess(int count);

  String get allFilesSendFailed;

  String get failedFiles;

  String get transferComplete;

  String get successCount;

  String get failureCount;

  String transferSummary(
    int successCount,
    int failureCount,
    String failedFiles,
  );

  // Batch transfer status
  String get preparingTransferInfo;

  String waitingForReceiverConfirmFiles(int count);

  String transferringFile(int current, int total, String fileName);

  String get receiverRejected;

  String receiverRejectedWithStatus(int statusCode);

  String get transferIdNotFound;

  // Batch receive
  String get waitingForConfirmation;

  String get preparingToReceive;

  String get rejected;

  String get receiveComplete;

  String receivingProgress(double progress);

  String receivingFiles(int count);

  String receiveFilesCount(int count);

  String get sender;

  String get totalSizeBatch;

  String get fileList;

  String get allFilesReceiveComplete;

  String get receivingFiles2;

  String autoRejectCountdown(int seconds);

  String get rejectAll;

  String get acceptAll;

  // Network diagnostics
  String get networkDiagnosticsReport;

  String get localNetworkInterfaces;

  String get noValidNetworkInterface;

  String get privateNetworkAddress;

  String get targetDeviceReachability;

  String get canConnectToTarget;

  String get cannotConnectToTarget;

  String get healthCheckTest;

  String get healthCheckSuccess;

  String get healthCheckFailed;

  String get statusCode;

  String get response;

  String get internetConnection;

  String get hasInternetConnection;

  String get noInternetConnection;

  // Error messages
  String get networkConnectionFailed;

  String get networkTimeout;

  String get networkRequestFailed;

  String get transferTimeout;

  String get transferInterrupted;

  String get fileNotFound;

  String get fileNotReadable;

  String get fileAccessError;

  String get fileSaveFailed;

  String get fileSizeMismatch;

  String get invalidFileName;

  String get downloadsDirectoryUnavailable;

  String get storageInsufficient;

  String get storageCheckFailed;

  String get networkPermissionDenied;

  String get storagePermissionDenied;

  String serverStartFailed(String reason);

  String get serverPortsOccupied;

  String serverPortsOccupiedRange(int defaultPort, int maxPort);

  String get serverUnknownError;

  String get transferRejected;

  String get fileTooLarge;

  String get fileOrStorageFull;

  String get receiveTimeout;

  String get userRejected;

  String get ipAddressEmpty;

  String get ipAddressInvalidFormat;

  String get ipAddressInvalidRange;

  String get ipAddressSpecial1;

  String get ipAddressSpecial2;

  String ipAddressNotInSameSubnet(
    String localIP,
    String targetIP,
    String localNetwork,
    String targetNetwork,
  );

  String get responseParseError;

  String get responseInvalidFormat;

  String responseStatusCodeError(int statusCode);

  String get fileSelectionError;

  String get fileSelectionCancelled;

  String genericError(String operation);

  String unexpectedError(String details);

  String networkError(String context);

  String fileError(String context);

  String permissionError(String permissionType);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Use LanguageService configuration to check if locale is supported
    final supportedLanguages = LanguageService.getSupportedLanguages();

    // Check if the locale matches any supported language configuration
    for (final config in supportedLanguages.values) {
      if (config.code == 'system') continue; // Skip 'system' option

      final supportedLocale = config.locale;
      if (supportedLocale.languageCode == locale.languageCode) {
        // If country code is specified in both, they must match
        if (supportedLocale.countryCode != null && locale.countryCode != null) {
          if (supportedLocale.countryCode == locale.countryCode) {
            return true;
          }
        } else {
          // If no country code specified, language code match is enough
          return true;
        }
      }
    }

    return false;
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    if (locale.languageCode == 'zh') {
      if (locale.countryCode == 'HK') {
        return AppLocalizationsZhHk();
      }
      return AppLocalizationsZh();
    }
    switch (locale.languageCode) {
      case 'ko':
        return AppLocalizationsKo();
      case 'ja':
        return AppLocalizationsJa();
      case 'fr':
        return AppLocalizationsFr();
      case 'de':
        return AppLocalizationsDe();
      case 'es':
        return AppLocalizationsEs();
      case 'pt':
        return AppLocalizationsPt();
      case 'ru':
        return AppLocalizationsRu();
      case 'it':
        return AppLocalizationsIt();
      case 'nl':
        return AppLocalizationsNl();
      case 'en':
        return AppLocalizationsEn();
      default:
        return AppLocalizationsEn();
    }
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
