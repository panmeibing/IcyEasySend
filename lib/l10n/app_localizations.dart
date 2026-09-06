import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('nl'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh'),
    Locale('zh', 'HK'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Icy Easy Send'**
  String get appName;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get appVersion;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @serverStatus.
  ///
  /// In en, this message translates to:
  /// **'Server Status'**
  String get serverStatus;

  /// No description provided for @serverRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get serverRunning;

  /// No description provided for @serverStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get serverStopped;

  /// No description provided for @serverAddress.
  ///
  /// In en, this message translates to:
  /// **'Server Address'**
  String get serverAddress;

  /// No description provided for @deviceName.
  ///
  /// In en, this message translates to:
  /// **'Device Name'**
  String get deviceName;

  /// No description provided for @storageSpace.
  ///
  /// In en, this message translates to:
  /// **'Storage Space'**
  String get storageSpace;

  /// No description provided for @availableSpace.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availableSpace;

  /// No description provided for @sendFiles.
  ///
  /// In en, this message translates to:
  /// **'Send Files'**
  String get sendFiles;

  /// No description provided for @receiveFiles.
  ///
  /// In en, this message translates to:
  /// **'Receive Files'**
  String get receiveFiles;

  /// No description provided for @selectFiles.
  ///
  /// In en, this message translates to:
  /// **'Select Files'**
  String get selectFiles;

  /// No description provided for @selectFolder.
  ///
  /// In en, this message translates to:
  /// **'Select Folder'**
  String get selectFolder;

  /// No description provided for @dragDropHint.
  ///
  /// In en, this message translates to:
  /// **'Drag and drop files here'**
  String get dragDropHint;

  /// No description provided for @noFilesSelected.
  ///
  /// In en, this message translates to:
  /// **'No files selected'**
  String get noFilesSelected;

  /// No description provided for @filesSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} file selected} other{{count} files selected}}'**
  String filesSelected(int count);

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearSelection;

  /// No description provided for @startSending.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get startSending;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get sending;

  /// No description provided for @sendSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sent successfully'**
  String get sendSuccess;

  /// No description provided for @sendFailed.
  ///
  /// In en, this message translates to:
  /// **'Send failed'**
  String get sendFailed;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer History'**
  String get historyTitle;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No history'**
  String get noHistory;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get clearHistory;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @received.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get received;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @fileSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get fileSize;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @deleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteItem;

  /// No description provided for @deleteItemConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get deleteItemConfirm;

  /// No description provided for @openFile.
  ///
  /// In en, this message translates to:
  /// **'Open File'**
  String get openFile;

  /// No description provided for @openFolder.
  ///
  /// In en, this message translates to:
  /// **'Open Folder'**
  String get openFolder;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @deviceNameSetting.
  ///
  /// In en, this message translates to:
  /// **'Device Name'**
  String get deviceNameSetting;

  /// No description provided for @editDeviceName.
  ///
  /// In en, this message translates to:
  /// **'Edit Device Name'**
  String get editDeviceName;

  /// No description provided for @deviceNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter device name'**
  String get deviceNameHint;

  /// No description provided for @deviceNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Device name cannot be empty'**
  String get deviceNameEmpty;

  /// No description provided for @port.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port;

  /// No description provided for @portHint.
  ///
  /// In en, this message translates to:
  /// **'Enter port number'**
  String get portHint;

  /// No description provided for @portInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid port number'**
  String get portInvalid;

  /// No description provided for @portInUse.
  ///
  /// In en, this message translates to:
  /// **'Port is already in use'**
  String get portInUse;

  /// No description provided for @savePath.
  ///
  /// In en, this message translates to:
  /// **'Save Path'**
  String get savePath;

  /// No description provided for @selectSavePath.
  ///
  /// In en, this message translates to:
  /// **'Select Save Path'**
  String get selectSavePath;

  /// No description provided for @savePathDesc.
  ///
  /// In en, this message translates to:
  /// **'Received files are saved here. The system downloads folder is used by default.'**
  String get savePathDesc;

  /// No description provided for @savePathDefaultBadge.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get savePathDefaultBadge;

  /// No description provided for @savePathUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to resolve save path'**
  String get savePathUnavailable;

  /// No description provided for @savePathSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Save path updated successfully'**
  String get savePathSavedSuccess;

  /// No description provided for @savePathNotWritable.
  ///
  /// In en, this message translates to:
  /// **'Cannot write to this folder. Please choose another location or check permissions.'**
  String get savePathNotWritable;

  /// No description provided for @resetSavePathToDefault.
  ///
  /// In en, this message translates to:
  /// **'Use default folder'**
  String get resetSavePathToDefault;

  /// No description provided for @savePathResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Restored to system downloads folder'**
  String get savePathResetSuccess;

  /// No description provided for @autoStart.
  ///
  /// In en, this message translates to:
  /// **'Auto Start'**
  String get autoStart;

  /// No description provided for @autoStartDesc.
  ///
  /// In en, this message translates to:
  /// **'Start server automatically when app launches'**
  String get autoStartDesc;

  /// No description provided for @network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get network;

  /// No description provided for @networkDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Network Diagnostics'**
  String get networkDiagnostics;

  /// No description provided for @scanDevices.
  ///
  /// In en, this message translates to:
  /// **'Scan Devices'**
  String get scanDevices;

  /// No description provided for @scanDevicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan LAN Devices'**
  String get scanDevicesTitle;

  /// No description provided for @scanningDevices.
  ///
  /// In en, this message translates to:
  /// **'Scanning local network...'**
  String get scanningDevices;

  /// No description provided for @scanProgress.
  ///
  /// In en, this message translates to:
  /// **'{found, plural, =1{Scanned {scanned}/{total}, found {found} device} other{Scanned {scanned}/{total}, found {found} devices}}'**
  String scanProgress(int scanned, int total, int found);

  /// No description provided for @noDevicesFound.
  ///
  /// In en, this message translates to:
  /// **'No devices found'**
  String get noDevicesFound;

  /// No description provided for @noDevicesFoundHint.
  ///
  /// In en, this message translates to:
  /// **'Make sure the target device has started the server and is on the same network. Check router AP isolation and firewall settings.'**
  String get noDevicesFoundHint;

  /// No description provided for @scanDevicesFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Found {count} device} other{Found {count} devices}}'**
  String scanDevicesFound(int count);

  /// No description provided for @rescan.
  ///
  /// In en, this message translates to:
  /// **'Rescan'**
  String get rescan;

  /// No description provided for @runDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Run Diagnostics'**
  String get runDiagnostics;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @checkUpdate.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get checkUpdate;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @openSource.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get openSource;

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permissionRequired;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission Denied'**
  String get permissionDenied;

  /// No description provided for @permissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission Permanently Denied'**
  String get permissionPermanentlyDenied;

  /// No description provided for @permissionStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage Permission'**
  String get permissionStorage;

  /// No description provided for @permissionStorageDesc.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is required to save and read files'**
  String get permissionStorageDesc;

  /// No description provided for @permissionNotification.
  ///
  /// In en, this message translates to:
  /// **'Notification Permission'**
  String get permissionNotification;

  /// No description provided for @permissionNotificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is required to show transfer progress'**
  String get permissionNotificationDesc;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @permissionWarning.
  ///
  /// In en, this message translates to:
  /// **'Some permissions are not granted, some features may be limited'**
  String get permissionWarning;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get errorUnknown;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get errorNetwork;

  /// No description provided for @errorFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get errorFileNotFound;

  /// No description provided for @errorPermission.
  ///
  /// In en, this message translates to:
  /// **'Permission error'**
  String get errorPermission;

  /// No description provided for @errorStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage error'**
  String get errorStorage;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get errorServer;

  /// No description provided for @errorServerStart.
  ///
  /// In en, this message translates to:
  /// **'Failed to start server'**
  String get errorServerStart;

  /// No description provided for @errorServerStop.
  ///
  /// In en, this message translates to:
  /// **'Failed to stop server'**
  String get errorServerStop;

  /// No description provided for @errorConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get errorConnection;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timeout'**
  String get errorTimeout;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @copyFailed.
  ///
  /// In en, this message translates to:
  /// **'Copy failed'**
  String get copyFailed;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get saveFailed;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get deleteFailed;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @selectFilesFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to select files'**
  String get selectFilesFailed;

  /// No description provided for @selectFolderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to select folder'**
  String get selectFolderFailed;

  /// No description provided for @folderFilesAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {count} files from folder'**
  String folderFilesAdded(int count);

  /// No description provided for @folderContainsNoFiles.
  ///
  /// In en, this message translates to:
  /// **'The selected folder contains no files to send'**
  String get folderContainsNoFiles;

  /// No description provided for @openFileFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open file'**
  String get openFileFailed;

  /// No description provided for @openFolderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open folder'**
  String get openFolderFailed;

  /// No description provided for @fileNotExist.
  ///
  /// In en, this message translates to:
  /// **'File does not exist'**
  String get fileNotExist;

  /// No description provided for @folderNotExist.
  ///
  /// In en, this message translates to:
  /// **'Folder does not exist'**
  String get folderNotExist;

  /// No description provided for @diagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Network Diagnostics'**
  String get diagnosticsTitle;

  /// No description provided for @diagnosticsRunning.
  ///
  /// In en, this message translates to:
  /// **'Running diagnostics...'**
  String get diagnosticsRunning;

  /// No description provided for @diagnosticsComplete.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics complete'**
  String get diagnosticsComplete;

  /// No description provided for @diagnosticsFailed.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics failed'**
  String get diagnosticsFailed;

  /// No description provided for @networkStatus.
  ///
  /// In en, this message translates to:
  /// **'Network Status'**
  String get networkStatus;

  /// No description provided for @wifiConnected.
  ///
  /// In en, this message translates to:
  /// **'WiFi Connected'**
  String get wifiConnected;

  /// No description provided for @wifiDisconnected.
  ///
  /// In en, this message translates to:
  /// **'WiFi Disconnected'**
  String get wifiDisconnected;

  /// No description provided for @mobileData.
  ///
  /// In en, this message translates to:
  /// **'Mobile Data'**
  String get mobileData;

  /// No description provided for @noConnection.
  ///
  /// In en, this message translates to:
  /// **'No Connection'**
  String get noConnection;

  /// No description provided for @ipAddress.
  ///
  /// In en, this message translates to:
  /// **'IP Address'**
  String get ipAddress;

  /// No description provided for @noIpAddress.
  ///
  /// In en, this message translates to:
  /// **'No IP Address'**
  String get noIpAddress;

  /// No description provided for @serverStatusCheck.
  ///
  /// In en, this message translates to:
  /// **'Server Status Check'**
  String get serverStatusCheck;

  /// No description provided for @portCheck.
  ///
  /// In en, this message translates to:
  /// **'Port Check'**
  String get portCheck;

  /// No description provided for @portAvailable.
  ///
  /// In en, this message translates to:
  /// **'Port Available'**
  String get portAvailable;

  /// No description provided for @portUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Port Unavailable'**
  String get portUnavailable;

  /// No description provided for @suggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestions;

  /// No description provided for @syncClipboard.
  ///
  /// In en, this message translates to:
  /// **'Sync Remote Clipboard'**
  String get syncClipboard;

  /// No description provided for @filesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Send {count} file} other{Send {count} files}}'**
  String filesCount(int count);

  /// No description provided for @sendFile.
  ///
  /// In en, this message translates to:
  /// **'Send File'**
  String get sendFile;

  /// No description provided for @shareViaQr.
  ///
  /// In en, this message translates to:
  /// **'Share via QR'**
  String get shareViaQr;

  /// No description provided for @webShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan to receive files'**
  String get webShareTitle;

  /// No description provided for @webShareHint.
  ///
  /// In en, this message translates to:
  /// **'The receiver can scan with the system camera and download in a browser—no app install needed. Stay on the same Wi‑Fi / LAN. Some third-party scanners (e.g. WeChat) may block LAN links; use Copy Link as a fallback.'**
  String get webShareHint;

  /// No description provided for @webShareCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get webShareCopyLink;

  /// No description provided for @webShareLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get webShareLinkCopied;

  /// No description provided for @webShareStopSharing.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing'**
  String get webShareStopSharing;

  /// No description provided for @webShareStopped.
  ///
  /// In en, this message translates to:
  /// **'Web share stopped'**
  String get webShareStopped;

  /// No description provided for @webShareServerRequired.
  ///
  /// In en, this message translates to:
  /// **'Start the local server before sharing via QR'**
  String get webShareServerRequired;

  /// No description provided for @webShareCreated.
  ///
  /// In en, this message translates to:
  /// **'Web share created. The receiver can scan to download.'**
  String get webShareCreated;

  /// No description provided for @webShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create web share'**
  String get webShareFailed;

  /// No description provided for @webSharePeerName.
  ///
  /// In en, this message translates to:
  /// **'Web Share'**
  String get webSharePeerName;

  /// No description provided for @webShareFilesSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} file(s) · {size}'**
  String webShareFilesSummary(int count, String size);

  /// No description provided for @webShareExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Expires in {time}'**
  String webShareExpiresIn(String time);

  /// No description provided for @releaseToAdd.
  ///
  /// In en, this message translates to:
  /// **'Release to add files'**
  String get releaseToAdd;

  /// No description provided for @serverNotRunning.
  ///
  /// In en, this message translates to:
  /// **'Server not running, cannot receive shared files'**
  String get serverNotRunning;

  /// No description provided for @cannotReceiveFiles.
  ///
  /// In en, this message translates to:
  /// **'Cannot receive files'**
  String get cannotReceiveFiles;

  /// No description provided for @sendingInProgress.
  ///
  /// In en, this message translates to:
  /// **'File transfer in progress, please try later'**
  String get sendingInProgress;

  /// No description provided for @pleaseTryLater.
  ///
  /// In en, this message translates to:
  /// **'Please try later'**
  String get pleaseTryLater;

  /// No description provided for @filesAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Added {count} shared file} other{Added {count} shared files}}'**
  String filesAdded(int count);

  /// No description provided for @preparingSend.
  ///
  /// In en, this message translates to:
  /// **'Preparing to send...'**
  String get preparingSend;

  /// No description provided for @transferring.
  ///
  /// In en, this message translates to:
  /// **'Transferring'**
  String get transferring;

  /// No description provided for @transferProgress.
  ///
  /// In en, this message translates to:
  /// **'[{current}/{total}] {fileName}: Transferring...'**
  String transferProgress(int current, int total, String fileName);

  /// No description provided for @networkChanged.
  ///
  /// In en, this message translates to:
  /// **'Network changed, server address updated'**
  String get networkChanged;

  /// No description provided for @serverAddressUpdated.
  ///
  /// In en, this message translates to:
  /// **'Server address updated'**
  String get serverAddressUpdated;

  /// No description provided for @portCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Port cannot be empty'**
  String get portCannotBeEmpty;

  /// No description provided for @portMustBeNumber.
  ///
  /// In en, this message translates to:
  /// **'Port must be a number'**
  String get portMustBeNumber;

  /// No description provided for @portRange.
  ///
  /// In en, this message translates to:
  /// **'Port range: 1-65535'**
  String get portRange;

  /// No description provided for @ipDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted IP: {ip}'**
  String ipDeleted(String ip);

  /// No description provided for @runningDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Running network diagnostics...'**
  String get runningDiagnostics;

  /// No description provided for @targetDeviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Target Device Info'**
  String get targetDeviceInfo;

  /// No description provided for @fullAddress.
  ///
  /// In en, this message translates to:
  /// **'Full Address'**
  String get fullAddress;

  /// No description provided for @targetNotSet.
  ///
  /// In en, this message translates to:
  /// **'Target device not set'**
  String get targetNotSet;

  /// No description provided for @diagnosticsReport.
  ///
  /// In en, this message translates to:
  /// **'Network Diagnostics Report'**
  String get diagnosticsReport;

  /// No description provided for @reportCopied.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics report copied to clipboard'**
  String get reportCopied;

  /// No description provided for @deviceNameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Device name cannot be empty'**
  String get deviceNameCannotBeEmpty;

  /// No description provided for @deviceNameSaved.
  ///
  /// In en, this message translates to:
  /// **'Device name saved'**
  String get deviceNameSaved;

  /// No description provided for @resetDeviceName.
  ///
  /// In en, this message translates to:
  /// **'Reset Device Name'**
  String get resetDeviceName;

  /// No description provided for @resetDeviceNameConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset device name to \"{model}\"?'**
  String resetDeviceNameConfirm(String model);

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @confirmChange.
  ///
  /// In en, this message translates to:
  /// **'Confirm Change'**
  String get confirmChange;

  /// No description provided for @concurrentTransfersIncrease.
  ///
  /// In en, this message translates to:
  /// **'Change concurrent transfers from {from} to {to}?\n\nNote: Increasing may improve transfer speed but will increase device load'**
  String concurrentTransfersIncrease(int from, int to);

  /// No description provided for @concurrentTransfersDecrease.
  ///
  /// In en, this message translates to:
  /// **'Change concurrent transfers from {from} to {to}?\n\nNote: Decreasing will reduce device load but may lower transfer speed'**
  String concurrentTransfersDecrease(int from, int to);

  /// No description provided for @concurrentTransfersHint.
  ///
  /// In en, this message translates to:
  /// **'Concurrent transfers hint'**
  String get concurrentTransfersHint;

  /// No description provided for @concurrentTransfersSaved.
  ///
  /// In en, this message translates to:
  /// **'Concurrent transfers saved'**
  String get concurrentTransfersSaved;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get enterValidNumber;

  /// No description provided for @historyCountRange.
  ///
  /// In en, this message translates to:
  /// **'History count range: {min}-{max}'**
  String historyCountRange(int min, int max);

  /// No description provided for @maxHistoryChange.
  ///
  /// In en, this message translates to:
  /// **'Change max history items from {from} to {to}?\n\n'**
  String maxHistoryChange(int from, int to);

  /// No description provided for @currentHistoryCount.
  ///
  /// In en, this message translates to:
  /// **'Current history count: {count} items\n\n'**
  String currentHistoryCount(int count);

  /// No description provided for @historyWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Warning: Current history count exceeds the new limit.\n\n'**
  String get historyWarning;

  /// No description provided for @historyDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'Only the latest {max} items will be kept, {toDelete} old items will be deleted.'**
  String historyDeleteWarning(int current, int max, int toDelete);

  /// No description provided for @historyHint.
  ///
  /// In en, this message translates to:
  /// **'Note: New setting will take effect on next save.'**
  String get historyHint;

  /// No description provided for @historyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Settings saved, deleted {count} old items'**
  String historyDeleted(int count);

  /// No description provided for @maxHistorySaved.
  ///
  /// In en, this message translates to:
  /// **'Max history items saved'**
  String get maxHistorySaved;

  /// No description provided for @clipboardSizeRange.
  ///
  /// In en, this message translates to:
  /// **'Clipboard size range: {min}-{max} MB'**
  String clipboardSizeRange(int min, int max);

  /// No description provided for @maxClipboardSizeChange.
  ///
  /// In en, this message translates to:
  /// **'Change max clipboard size from {from} MB to {to} MB?\n\n'**
  String maxClipboardSizeChange(int from, int to);

  /// No description provided for @clipboardSizeDecreaseHint.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Note: After decreasing the limit, clipboard content exceeding the new size cannot be synced. Please use file transfer instead.'**
  String get clipboardSizeDecreaseHint;

  /// No description provided for @clipboardSizeIncreaseHint.
  ///
  /// In en, this message translates to:
  /// **'Note: After increasing the limit, larger clipboard content can be synced, but this may affect transfer speed.'**
  String get clipboardSizeIncreaseHint;

  /// No description provided for @maxClipboardSizeSaved.
  ///
  /// In en, this message translates to:
  /// **'Max clipboard size saved'**
  String get maxClipboardSizeSaved;

  /// No description provided for @ipValidationEnabled.
  ///
  /// In en, this message translates to:
  /// **'IP validation enabled'**
  String get ipValidationEnabled;

  /// No description provided for @ipValidationDisabled.
  ///
  /// In en, this message translates to:
  /// **'IP validation disabled'**
  String get ipValidationDisabled;

  /// No description provided for @deviceSecretKeyCleared.
  ///
  /// In en, this message translates to:
  /// **'Device secret key cleared'**
  String get deviceSecretKeyCleared;

  /// No description provided for @deviceSecretKeySaved.
  ///
  /// In en, this message translates to:
  /// **'Device secret key saved'**
  String get deviceSecretKeySaved;

  /// No description provided for @loadingDevInfo.
  ///
  /// In en, this message translates to:
  /// **'Loading developer info...'**
  String get loadingDevInfo;

  /// No description provided for @copyLog.
  ///
  /// In en, this message translates to:
  /// **'Copy Log'**
  String get copyLog;

  /// No description provided for @logCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied last {lines} lines of log to clipboard'**
  String logCopied(int lines);

  /// No description provided for @logFileEmpty.
  ///
  /// In en, this message translates to:
  /// **'Log file is empty'**
  String get logFileEmpty;

  /// No description provided for @devInfo.
  ///
  /// In en, this message translates to:
  /// **'Developer Info'**
  String get devInfo;

  /// No description provided for @labelCopied.
  ///
  /// In en, this message translates to:
  /// **'{label} copied: {value}'**
  String labelCopied(String label, String value);

  /// No description provided for @transferSettings.
  ///
  /// In en, this message translates to:
  /// **'Transfer Settings'**
  String get transferSettings;

  /// No description provided for @concurrentTransfers.
  ///
  /// In en, this message translates to:
  /// **'Concurrent Transfers'**
  String get concurrentTransfers;

  /// No description provided for @concurrentTransfersDesc.
  ///
  /// In en, this message translates to:
  /// **'Number of files to transfer simultaneously (1-{max})'**
  String concurrentTransfersDesc(int max);

  /// No description provided for @concurrentTransfersHintText.
  ///
  /// In en, this message translates to:
  /// **'Higher concurrency can better utilize bandwidth, but may increase device load'**
  String get concurrentTransfersHintText;

  /// No description provided for @maxHistory.
  ///
  /// In en, this message translates to:
  /// **'Max History Items'**
  String get maxHistory;

  /// No description provided for @maxHistoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Maximum number of transfer records to save ({min}-{max})'**
  String maxHistoryDesc(int min, int max);

  /// No description provided for @maxHistoryHintText.
  ///
  /// In en, this message translates to:
  /// **'Enter count ({min}-{max})'**
  String maxHistoryHintText(int min, int max);

  /// No description provided for @oldRecordsAutoDelete.
  ///
  /// In en, this message translates to:
  /// **'Records exceeding the limit will be automatically deleted, keeping only the most recent ones'**
  String get oldRecordsAutoDelete;

  /// No description provided for @maxClipboard.
  ///
  /// In en, this message translates to:
  /// **'Max Clipboard Size'**
  String get maxClipboard;

  /// No description provided for @maxClipboardDesc.
  ///
  /// In en, this message translates to:
  /// **'Maximum clipboard size allowed for sync ({min}-{max} MB)'**
  String maxClipboardDesc(int min, int max);

  /// No description provided for @maxClipboardHintText.
  ///
  /// In en, this message translates to:
  /// **'Enter size ({min}-{max} MB)'**
  String maxClipboardHintText(int min, int max);

  /// No description provided for @clipboardSyncLimit.
  ///
  /// In en, this message translates to:
  /// **'Clipboard content exceeding this size cannot be synced. Use file transfer instead'**
  String get clipboardSyncLimit;

  /// No description provided for @ipValidation.
  ///
  /// In en, this message translates to:
  /// **'IP Validation'**
  String get ipValidation;

  /// No description provided for @ipValidationDesc.
  ///
  /// In en, this message translates to:
  /// **'Validate if target device IP is in the same subnet'**
  String get ipValidationDesc;

  /// No description provided for @ipValidationEnabledHint.
  ///
  /// In en, this message translates to:
  /// **'When enabled, verifies that the target IP is in the same subnet to prevent connecting to incorrect devices'**
  String get ipValidationEnabledHint;

  /// No description provided for @ipValidationDisabledHint.
  ///
  /// In en, this message translates to:
  /// **'When disabled, IP subnet validation is skipped. Suitable for complex network environments (hotspot, VPN, etc.)'**
  String get ipValidationDisabledHint;

  /// No description provided for @deviceSecretKey.
  ///
  /// In en, this message translates to:
  /// **'Device Secret Key'**
  String get deviceSecretKey;

  /// No description provided for @deviceSecretKeyDesc.
  ///
  /// In en, this message translates to:
  /// **'When set, other devices need to provide the correct key to skip confirmation'**
  String get deviceSecretKeyDesc;

  /// No description provided for @deviceSecretKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Enter secret key (leave empty to disable)'**
  String get deviceSecretKeyHint;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not Set'**
  String get notSet;

  /// No description provided for @author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'A simple and easy-to-use LAN file transfer tool'**
  String get appDescription;

  /// No description provided for @targetDeviceIP.
  ///
  /// In en, this message translates to:
  /// **'Target Device IP Address'**
  String get targetDeviceIP;

  /// No description provided for @ipHint.
  ///
  /// In en, this message translates to:
  /// **'e.g.: 192.168.1.100'**
  String get ipHint;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @targetDevicePort.
  ///
  /// In en, this message translates to:
  /// **'Target Device Port'**
  String get targetDevicePort;

  /// No description provided for @resetToDefaultPort.
  ///
  /// In en, this message translates to:
  /// **'Reset to default port ({port})'**
  String resetToDefaultPort(int port);

  /// No description provided for @targetDeviceSecretKey.
  ///
  /// In en, this message translates to:
  /// **'Target Device Secret Key (Optional)'**
  String get targetDeviceSecretKey;

  /// No description provided for @secretKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Correct key can skip confirmation'**
  String get secretKeyHint;

  /// No description provided for @aboutSecretKey.
  ///
  /// In en, this message translates to:
  /// **'About Secret Key'**
  String get aboutSecretKey;

  /// No description provided for @secretKeyFeatureTitle.
  ///
  /// In en, this message translates to:
  /// **'Secret Key Feature'**
  String get secretKeyFeatureTitle;

  /// No description provided for @secretKeyFeatureDesc.
  ///
  /// In en, this message translates to:
  /// **'If the target device has set a secret key, entering the correct key allows you to skip the confirmation dialog and directly transfer files or sync clipboard.'**
  String get secretKeyFeatureDesc;

  /// No description provided for @secretKeyUsageSteps.
  ///
  /// In en, this message translates to:
  /// **'Usage Steps:'**
  String get secretKeyUsageSteps;

  /// No description provided for @secretKeyUsageStep1.
  ///
  /// In en, this message translates to:
  /// **'1. Target device sets its secret key in Settings'**
  String get secretKeyUsageStep1;

  /// No description provided for @secretKeyUsageStep2.
  ///
  /// In en, this message translates to:
  /// **'2. Enter the target device\'s secret key in this field'**
  String get secretKeyUsageStep2;

  /// No description provided for @secretKeyUsageStep3.
  ///
  /// In en, this message translates to:
  /// **'3. When sending files or requesting clipboard, if the key is correct, the other party will automatically accept'**
  String get secretKeyUsageStep3;

  /// No description provided for @secretKeyTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: Leave empty to use traditional manual confirmation'**
  String get secretKeyTip;

  /// No description provided for @secretKeyDescription.
  ///
  /// In en, this message translates to:
  /// **'Secret Key Description'**
  String get secretKeyDescription;

  /// No description provided for @clearSecretKey.
  ///
  /// In en, this message translates to:
  /// **'Clear Secret Key'**
  String get clearSecretKey;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got It'**
  String get gotIt;

  /// No description provided for @localIP.
  ///
  /// In en, this message translates to:
  /// **'Local IP'**
  String get localIP;

  /// No description provided for @ipCopied.
  ///
  /// In en, this message translates to:
  /// **'IP address copied: {ip}'**
  String ipCopied(String ip);

  /// No description provided for @transferred.
  ///
  /// In en, this message translates to:
  /// **'Transferred'**
  String get transferred;

  /// No description provided for @transferSpeed.
  ///
  /// In en, this message translates to:
  /// **'Transfer Speed'**
  String get transferSpeed;

  /// No description provided for @remainingTime.
  ///
  /// In en, this message translates to:
  /// **'Remaining Time'**
  String get remainingTime;

  /// No description provided for @transferringProgress.
  ///
  /// In en, this message translates to:
  /// **'Transferring {progress}%'**
  String transferringProgress(double progress);

  /// No description provided for @storagePermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is required to select files. Please enable it manually in Settings.'**
  String get storagePermissionMessage;

  /// No description provided for @checkingTargetDevice.
  ///
  /// In en, this message translates to:
  /// **'Checking target device...'**
  String get checkingTargetDevice;

  /// No description provided for @targetDeviceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Target device unavailable'**
  String get targetDeviceUnavailable;

  /// No description provided for @targetDeviceError.
  ///
  /// In en, this message translates to:
  /// **'Target device unavailable\nError: {error}'**
  String targetDeviceError(String error);

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection Failed'**
  String get connectionFailed;

  /// No description provided for @transferHistory.
  ///
  /// In en, this message translates to:
  /// **'Transfer History'**
  String get transferHistory;

  /// No description provided for @clearHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get clearHistoryTitle;

  /// No description provided for @clearHistoryMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all transfer history? This action cannot be undone.'**
  String get clearHistoryMessage;

  /// No description provided for @noFilteredRecords.
  ///
  /// In en, this message translates to:
  /// **'No matching records'**
  String get noFilteredRecords;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get filterSent;

  /// No description provided for @filterReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get filterReceived;

  /// No description provided for @statisticsInfo.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statisticsInfo;

  /// No description provided for @transfersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} transfer} other{{count} transfers}}'**
  String transfersCount(int count);

  /// No description provided for @totalTransfers.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalTransfers;

  /// No description provided for @successfulTransfers.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get successfulTransfers;

  /// No description provided for @failedTransfers.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failedTransfers;

  /// No description provided for @sentFiles.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sentFiles;

  /// No description provided for @receivedFiles.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get receivedFiles;

  /// No description provided for @totalSize.
  ///
  /// In en, this message translates to:
  /// **'Total Size'**
  String get totalSize;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More Actions'**
  String get moreActions;

  /// No description provided for @deleteRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete Record'**
  String get deleteRecord;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @deleteRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Record'**
  String get deleteRecordTitle;

  /// No description provided for @deleteRecordMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the transfer record for \"{fileName}\"?\n\nNote: This will only delete the record, not the file itself.'**
  String deleteRecordMessage(String fileName);

  /// No description provided for @deleteRecordNote.
  ///
  /// In en, this message translates to:
  /// **'Note: This will only delete the record, not the file itself.'**
  String get deleteRecordNote;

  /// No description provided for @recordDeleted.
  ///
  /// In en, this message translates to:
  /// **'Record deleted'**
  String get recordDeleted;

  /// No description provided for @filePathNotExist.
  ///
  /// In en, this message translates to:
  /// **'File path does not exist'**
  String get filePathNotExist;

  /// No description provided for @cannotOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Cannot open file'**
  String get cannotOpenFile;

  /// No description provided for @cannotOpenFileWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Cannot open file: {message}'**
  String cannotOpenFileWithMessage(String message);

  /// No description provided for @iosNoFolderSupport.
  ///
  /// In en, this message translates to:
  /// **'iOS does not support opening folders directly'**
  String get iosNoFolderSupport;

  /// No description provided for @cannotOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Cannot open folder'**
  String get cannotOpenFolder;

  /// No description provided for @recentFilesOpened.
  ///
  /// In en, this message translates to:
  /// **'Recent files opened, please search manually'**
  String get recentFilesOpened;

  /// No description provided for @receiveRecord.
  ///
  /// In en, this message translates to:
  /// **'Receive Record'**
  String get receiveRecord;

  /// No description provided for @sendRecord.
  ///
  /// In en, this message translates to:
  /// **'Send Record'**
  String get sendRecord;

  /// No description provided for @fileName.
  ///
  /// In en, this message translates to:
  /// **'File Name'**
  String get fileName;

  /// No description provided for @fromDevice.
  ///
  /// In en, this message translates to:
  /// **'From Device'**
  String get fromDevice;

  /// No description provided for @toDevice.
  ///
  /// In en, this message translates to:
  /// **'To Device'**
  String get toDevice;

  /// No description provided for @deviceIP.
  ///
  /// In en, this message translates to:
  /// **'Device IP'**
  String get deviceIP;

  /// No description provided for @transferTime.
  ///
  /// In en, this message translates to:
  /// **'Transfer Time'**
  String get transferTime;

  /// No description provided for @transferStatus.
  ///
  /// In en, this message translates to:
  /// **'Transfer Status'**
  String get transferStatus;

  /// No description provided for @statusSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get statusSuccess;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @savedLocation.
  ///
  /// In en, this message translates to:
  /// **'Saved Location'**
  String get savedLocation;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @pathCopied.
  ///
  /// In en, this message translates to:
  /// **'Path copied to clipboard'**
  String get pathCopied;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @sentTo.
  ///
  /// In en, this message translates to:
  /// **'Sent to'**
  String get sentTo;

  /// No description provided for @clipboardRequest.
  ///
  /// In en, this message translates to:
  /// **'Clipboard Request'**
  String get clipboardRequest;

  /// No description provided for @clipboardRequestFrom.
  ///
  /// In en, this message translates to:
  /// **'Device \"{deviceName}\" is requesting access to your clipboard content'**
  String clipboardRequestFrom(String deviceName);

  /// No description provided for @allowClipboardRequest.
  ///
  /// In en, this message translates to:
  /// **'Allow this request?'**
  String get allowClipboardRequest;

  /// No description provided for @clipboardRequestMessage.
  ///
  /// In en, this message translates to:
  /// **'Clipboard Request'**
  String get clipboardRequestMessage;

  /// No description provided for @autoRejectIn.
  ///
  /// In en, this message translates to:
  /// **'Auto-reject in {seconds} seconds'**
  String autoRejectIn(int seconds);

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @clipboardSharedWithSecretKey.
  ///
  /// In en, this message translates to:
  /// **'{deviceName} verified with secret key, clipboard shared automatically'**
  String clipboardSharedWithSecretKey(String deviceName);

  /// No description provided for @clipboardRequestRejected.
  ///
  /// In en, this message translates to:
  /// **'User rejected clipboard request'**
  String get clipboardRequestRejected;

  /// No description provided for @clipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Clipboard is empty'**
  String get clipboardEmpty;

  /// No description provided for @clipboardContentTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Clipboard content too large ({actualSizeMB} MB), exceeds recipient device limit ({maxSizeMB} MB). Please use file transfer instead.'**
  String clipboardContentTooLarge(double actualSizeMB, int maxSizeMB);

  /// No description provided for @clipboardContentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully retrieved clipboard content'**
  String get clipboardContentSuccess;

  /// No description provided for @invalidJsonFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid JSON format'**
  String get invalidJsonFormat;

  /// No description provided for @serverInternalError.
  ///
  /// In en, this message translates to:
  /// **'Server internal error'**
  String get serverInternalError;

  /// No description provided for @backgroundRejectNeedsSecretKey.
  ///
  /// In en, this message translates to:
  /// **'Device is in the background. Only secret-key auto sync/receive is supported. Open the app or configure a matching device secret key.'**
  String get backgroundRejectNeedsSecretKey;

  /// No description provided for @foregroundServiceNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'IcyEasySend'**
  String get foregroundServiceNotificationTitle;

  /// No description provided for @foregroundServiceNotificationText.
  ///
  /// In en, this message translates to:
  /// **'Waiting for file transfers and clipboard sync in the background'**
  String get foregroundServiceNotificationText;

  /// No description provided for @androidBackgroundReceiveHint.
  ///
  /// In en, this message translates to:
  /// **'While backgrounded, only peers with a matching secret key can auto-sync clipboard or send files. Keep the persistent notification running.'**
  String get androidBackgroundReceiveHint;

  /// No description provided for @clipboardOverlay.
  ///
  /// In en, this message translates to:
  /// **'Clipboard floating button'**
  String get clipboardOverlay;

  /// No description provided for @clipboardOverlayDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap the floating button to refresh cached text/images for background sync'**
  String get clipboardOverlayDesc;

  /// No description provided for @clipboardOverlayHint.
  ///
  /// In en, this message translates to:
  /// **'While backgrounded, only the last refreshed content can be synced. Turning this off clears the cache and hides the button.'**
  String get clipboardOverlayHint;

  /// No description provided for @clipboardOverlayPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Allow \"Display over other apps\" in system settings. The floating button will appear after you return.'**
  String get clipboardOverlayPermissionNeeded;

  /// No description provided for @clipboardOverlayEnabledToast.
  ///
  /// In en, this message translates to:
  /// **'Clipboard floating button enabled'**
  String get clipboardOverlayEnabledToast;

  /// No description provided for @clipboardBackgroundCacheMiss.
  ///
  /// In en, this message translates to:
  /// **'Cannot read the system clipboard in the background and no cache is available. Open the app or tap the floating button to refresh, then sync again.'**
  String get clipboardBackgroundCacheMiss;

  /// No description provided for @requestingClipboard.
  ///
  /// In en, this message translates to:
  /// **'Requesting clipboard...'**
  String get requestingClipboard;

  /// No description provided for @clipboardSyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Clipboard synced successfully'**
  String get clipboardSyncSuccess;

  /// No description provided for @textClipboardSyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Text clipboard synced successfully'**
  String get textClipboardSyncSuccess;

  /// No description provided for @fileClipboardSyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'File clipboard synced successfully\nYou can paste in app or file manager'**
  String get fileClipboardSyncSuccess;

  /// No description provided for @clipboardSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Clipboard sync failed'**
  String get clipboardSyncFailed;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync Failed'**
  String get syncFailed;

  /// No description provided for @clipboardRequestError.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while requesting clipboard: {error}'**
  String clipboardRequestError(String error);

  /// No description provided for @invalidFilesMessage.
  ///
  /// In en, this message translates to:
  /// **'The following files are invalid or inaccessible:\n{fileNames}'**
  String invalidFilesMessage(String fileNames);

  /// No description provided for @waitingForReceiverConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for receiver confirmation...'**
  String get waitingForReceiverConfirmation;

  /// No description provided for @fileSendSuccess.
  ///
  /// In en, this message translates to:
  /// **'File sent successfully!'**
  String get fileSendSuccess;

  /// No description provided for @filesSendSuccess.
  ///
  /// In en, this message translates to:
  /// **'{count} files sent successfully!'**
  String filesSendSuccess(int count);

  /// No description provided for @allFilesSendFailed.
  ///
  /// In en, this message translates to:
  /// **'All files failed to send'**
  String get allFilesSendFailed;

  /// No description provided for @failedFiles.
  ///
  /// In en, this message translates to:
  /// **'Failed files'**
  String get failedFiles;

  /// No description provided for @transferComplete.
  ///
  /// In en, this message translates to:
  /// **'Transfer Complete'**
  String get transferComplete;

  /// No description provided for @successCount.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get successCount;

  /// No description provided for @failureCount.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failureCount;

  /// No description provided for @transferSummary.
  ///
  /// In en, this message translates to:
  /// **'Success: {successCount} files\nFailed: {failureCount} files\n\nFailed files:\n{failedFiles}'**
  String transferSummary(
    int successCount,
    int failureCount,
    String failedFiles,
  );

  /// No description provided for @preparingTransferInfo.
  ///
  /// In en, this message translates to:
  /// **'Preparing transfer info...'**
  String get preparingTransferInfo;

  /// No description provided for @waitingForReceiverConfirmFiles.
  ///
  /// In en, this message translates to:
  /// **'Waiting for receiver to confirm {count} files...'**
  String waitingForReceiverConfirmFiles(int count);

  /// No description provided for @transferringFile.
  ///
  /// In en, this message translates to:
  /// **'Transferring file {current}/{total}: {fileName}'**
  String transferringFile(int current, int total, String fileName);

  /// No description provided for @receiverRejected.
  ///
  /// In en, this message translates to:
  /// **'Receiver rejected'**
  String get receiverRejected;

  /// No description provided for @receiverRejectedWithStatus.
  ///
  /// In en, this message translates to:
  /// **'Receiver rejected\nStatus code: {statusCode}'**
  String receiverRejectedWithStatus(int statusCode);

  /// No description provided for @transferIdNotFound.
  ///
  /// In en, this message translates to:
  /// **'Transfer ID not found'**
  String get transferIdNotFound;

  /// No description provided for @waitingForConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for confirmation...'**
  String get waitingForConfirmation;

  /// No description provided for @preparingToReceive.
  ///
  /// In en, this message translates to:
  /// **'Preparing to receive...'**
  String get preparingToReceive;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @receiveComplete.
  ///
  /// In en, this message translates to:
  /// **'Receive complete'**
  String get receiveComplete;

  /// No description provided for @receivingProgress.
  ///
  /// In en, this message translates to:
  /// **'Receiving... {progress}%'**
  String receivingProgress(double progress);

  /// No description provided for @receivingFiles.
  ///
  /// In en, this message translates to:
  /// **'Receiving {count} files'**
  String receivingFiles(int count);

  /// No description provided for @receiveFilesCount.
  ///
  /// In en, this message translates to:
  /// **'Receive {count} files'**
  String receiveFilesCount(int count);

  /// No description provided for @sender.
  ///
  /// In en, this message translates to:
  /// **'Sender'**
  String get sender;

  /// No description provided for @totalSizeBatch.
  ///
  /// In en, this message translates to:
  /// **'Total Size'**
  String get totalSizeBatch;

  /// No description provided for @fileList.
  ///
  /// In en, this message translates to:
  /// **'File List'**
  String get fileList;

  /// No description provided for @allFilesReceiveComplete.
  ///
  /// In en, this message translates to:
  /// **'All files received successfully!'**
  String get allFilesReceiveComplete;

  /// No description provided for @receivingFiles2.
  ///
  /// In en, this message translates to:
  /// **'Receiving files...'**
  String get receivingFiles2;

  /// No description provided for @autoRejectCountdown.
  ///
  /// In en, this message translates to:
  /// **'Accept these files? (Auto-reject in {seconds} seconds)'**
  String autoRejectCountdown(int seconds);

  /// No description provided for @rejectAll.
  ///
  /// In en, this message translates to:
  /// **'Reject All'**
  String get rejectAll;

  /// No description provided for @acceptAll.
  ///
  /// In en, this message translates to:
  /// **'Accept All'**
  String get acceptAll;

  /// No description provided for @networkDiagnosticsReport.
  ///
  /// In en, this message translates to:
  /// **'Network Diagnostics Report'**
  String get networkDiagnosticsReport;

  /// No description provided for @localNetworkInterfaces.
  ///
  /// In en, this message translates to:
  /// **'Local Network Interfaces'**
  String get localNetworkInterfaces;

  /// No description provided for @noValidNetworkInterface.
  ///
  /// In en, this message translates to:
  /// **'No valid network interface found'**
  String get noValidNetworkInterface;

  /// No description provided for @privateNetworkAddress.
  ///
  /// In en, this message translates to:
  /// **'Private Network Address'**
  String get privateNetworkAddress;

  /// No description provided for @targetDeviceReachability.
  ///
  /// In en, this message translates to:
  /// **'Target Device Reachability'**
  String get targetDeviceReachability;

  /// No description provided for @canConnectToTarget.
  ///
  /// In en, this message translates to:
  /// **'Can connect to target device'**
  String get canConnectToTarget;

  /// No description provided for @cannotConnectToTarget.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to target device'**
  String get cannotConnectToTarget;

  /// No description provided for @healthCheckTest.
  ///
  /// In en, this message translates to:
  /// **'Health Check Test'**
  String get healthCheckTest;

  /// No description provided for @healthCheckSuccess.
  ///
  /// In en, this message translates to:
  /// **'Health Check Successful'**
  String get healthCheckSuccess;

  /// No description provided for @healthCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Health Check Failed'**
  String get healthCheckFailed;

  /// No description provided for @statusCode.
  ///
  /// In en, this message translates to:
  /// **'Status Code'**
  String get statusCode;

  /// No description provided for @response.
  ///
  /// In en, this message translates to:
  /// **'Response'**
  String get response;

  /// No description provided for @internetConnection.
  ///
  /// In en, this message translates to:
  /// **'Internet Connection'**
  String get internetConnection;

  /// No description provided for @hasInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'Internet connection available'**
  String get hasInternetConnection;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternetConnection;

  /// No description provided for @networkConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to target device, please check network connection and IP address'**
  String get networkConnectionFailed;

  /// No description provided for @networkTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timeout, target device may be offline or network is unstable'**
  String get networkTimeout;

  /// No description provided for @networkRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Network request failed, please check network connection'**
  String get networkRequestFailed;

  /// No description provided for @transferTimeout.
  ///
  /// In en, this message translates to:
  /// **'Transfer timeout, please check network connection'**
  String get transferTimeout;

  /// No description provided for @transferInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Transfer interrupted, please retry'**
  String get transferInterrupted;

  /// No description provided for @fileNotFound.
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get fileNotFound;

  /// No description provided for @fileNotReadable.
  ///
  /// In en, this message translates to:
  /// **'Unable to read file, please ensure file exists and has access permission'**
  String get fileNotReadable;

  /// No description provided for @fileAccessError.
  ///
  /// In en, this message translates to:
  /// **'File access error, please check file permissions'**
  String get fileAccessError;

  /// No description provided for @fileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'File save failed'**
  String get fileSaveFailed;

  /// No description provided for @fileSizeMismatch.
  ///
  /// In en, this message translates to:
  /// **'File save failed: file size mismatch'**
  String get fileSizeMismatch;

  /// No description provided for @invalidFileName.
  ///
  /// In en, this message translates to:
  /// **'File name contains invalid characters'**
  String get invalidFileName;

  /// No description provided for @downloadsDirectoryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to access downloads directory'**
  String get downloadsDirectoryUnavailable;

  /// No description provided for @storageInsufficient.
  ///
  /// In en, this message translates to:
  /// **'Insufficient storage space, cannot receive file'**
  String get storageInsufficient;

  /// No description provided for @diskFullTitle.
  ///
  /// In en, this message translates to:
  /// **'Disk full'**
  String get diskFullTitle;

  /// No description provided for @storageCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to check storage space'**
  String get storageCheckFailed;

  /// No description provided for @networkPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Network access permission required to transfer files'**
  String get networkPermissionDenied;

  /// No description provided for @storagePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Storage access permission required to save files'**
  String get storagePermissionDenied;

  /// No description provided for @serverStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to start server: {reason}'**
  String serverStartFailed(String reason);

  /// No description provided for @serverPortsOccupied.
  ///
  /// In en, this message translates to:
  /// **'Unable to start server: all ports are occupied'**
  String get serverPortsOccupied;

  /// No description provided for @serverPortsOccupiedRange.
  ///
  /// In en, this message translates to:
  /// **'Unable to start server: ports {defaultPort}-{maxPort} are all occupied'**
  String serverPortsOccupiedRange(int defaultPort, int maxPort);

  /// No description provided for @serverUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unable to start server: unknown error'**
  String get serverUnknownError;

  /// No description provided for @transferRejected.
  ///
  /// In en, this message translates to:
  /// **'Transfer rejected by recipient'**
  String get transferRejected;

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File too large, maximum 2GB supported'**
  String get fileTooLarge;

  /// No description provided for @fileOrStorageFull.
  ///
  /// In en, this message translates to:
  /// **'File too large or recipient storage space insufficient'**
  String get fileOrStorageFull;

  /// No description provided for @receiveTimeout.
  ///
  /// In en, this message translates to:
  /// **'Receive timeout, automatically rejected'**
  String get receiveTimeout;

  /// No description provided for @userRejected.
  ///
  /// In en, this message translates to:
  /// **'User rejected file transfer'**
  String get userRejected;

  /// No description provided for @ipAddressEmpty.
  ///
  /// In en, this message translates to:
  /// **'IP address cannot be empty'**
  String get ipAddressEmpty;

  /// No description provided for @ipAddressInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid IP address format, please use xxx.xxx.xxx.xxx format'**
  String get ipAddressInvalidFormat;

  /// No description provided for @ipAddressInvalidRange.
  ///
  /// In en, this message translates to:
  /// **'Invalid IP address format, each number must be between 0-255'**
  String get ipAddressInvalidRange;

  /// No description provided for @ipAddressSpecial1.
  ///
  /// In en, this message translates to:
  /// **'Cannot use 0.0.0.0 as target address'**
  String get ipAddressSpecial1;

  /// No description provided for @ipAddressSpecial2.
  ///
  /// In en, this message translates to:
  /// **'Cannot use broadcast address 255.255.255.255'**
  String get ipAddressSpecial2;

  /// No description provided for @ipAddressNotInSameSubnet.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Subnet Mismatch\nLocal IP: {localIP} (Subnet: {localNetwork}.x)\nTarget IP: {targetIP} (Subnet: {targetNetwork}.x)\n\nNote: Both devices must be on the same LAN (same subnet) to transfer files.\nFor Class C IPv4 addresses, the first three numbers should be identical (e.g., 192.168.2), with only the last number differing.\nThe simplest solution is to connect both devices to the same WiFi network or router.\n'**
  String ipAddressNotInSameSubnet(
    String localIP,
    String targetIP,
    String localNetwork,
    String targetNetwork,
  );

  /// No description provided for @responseParseError.
  ///
  /// In en, this message translates to:
  /// **'Unable to parse server response'**
  String get responseParseError;

  /// No description provided for @responseInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Target device response format is incorrect'**
  String get responseInvalidFormat;

  /// No description provided for @responseStatusCodeError.
  ///
  /// In en, this message translates to:
  /// **'Server returned error status code: {statusCode}'**
  String responseStatusCodeError(int statusCode);

  /// No description provided for @fileSelectionError.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while selecting file'**
  String get fileSelectionError;

  /// No description provided for @fileSelectionCancelled.
  ///
  /// In en, this message translates to:
  /// **'File selection cancelled'**
  String get fileSelectionCancelled;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'{operation} failed'**
  String genericError(String operation);

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error occurred: {details}'**
  String unexpectedError(String details);

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error: {context}'**
  String networkError(String context);

  /// No description provided for @fileError.
  ///
  /// In en, this message translates to:
  /// **'File error: {context}'**
  String fileError(String context);

  /// No description provided for @permissionError.
  ///
  /// In en, this message translates to:
  /// **'{permissionType} permission required to continue'**
  String permissionError(String permissionType);

  /// No description provided for @foregroundServiceChannelName.
  ///
  /// In en, this message translates to:
  /// **'Background transfer service'**
  String get foregroundServiceChannelName;

  /// No description provided for @foregroundServiceChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Keeps the app able to receive LAN files and clipboard requests in the background'**
  String get foregroundServiceChannelDescription;

  /// No description provided for @peerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the target device'**
  String get peerUnreachable;

  /// No description provided for @peerUnreachableBoth.
  ///
  /// In en, this message translates to:
  /// **'Device is unreachable over both LAN and relay'**
  String get peerUnreachableBoth;

  /// No description provided for @peerUnsupported.
  ///
  /// In en, this message translates to:
  /// **'The other device runs a version without pairing support'**
  String get peerUnsupported;

  /// No description provided for @identityMismatch.
  ///
  /// In en, this message translates to:
  /// **'Device code does not match its public key, pairing aborted'**
  String get identityMismatch;

  /// No description provided for @cannotPairSelf.
  ///
  /// In en, this message translates to:
  /// **'Cannot pair a device with itself'**
  String get cannotPairSelf;

  /// No description provided for @pairingTitle.
  ///
  /// In en, this message translates to:
  /// **'Device Pairing'**
  String get pairingTitle;

  /// No description provided for @compareHint.
  ///
  /// In en, this message translates to:
  /// **'Check that both devices show exactly the same number before confirming. A mismatch means the connection may have been tampered with.'**
  String get compareHint;

  /// No description provided for @compareHintRelay.
  ///
  /// In en, this message translates to:
  /// **'This device is not on your network. Read the six digits to the other person by phone or voice and confirm only if they match exactly. Confirming without checking gives you no protection at all.'**
  String get compareHintRelay;

  /// No description provided for @pairOverRelay.
  ///
  /// In en, this message translates to:
  /// **'Pair through the relay'**
  String get pairOverRelay;

  /// No description provided for @enterDeviceCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the other device\'s 32-character code'**
  String get enterDeviceCode;

  /// No description provided for @invalidDeviceCode.
  ///
  /// In en, this message translates to:
  /// **'A device code is 32 hexadecimal characters'**
  String get invalidDeviceCode;

  /// No description provided for @alreadyPaired.
  ///
  /// In en, this message translates to:
  /// **'That device is already trusted'**
  String get alreadyPaired;

  /// No description provided for @peerAlreadyPaired.
  ///
  /// In en, this message translates to:
  /// **'The other device still trusts this one; unpair on that device first'**
  String get peerAlreadyPaired;

  /// No description provided for @relayUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Connect to the relay server first'**
  String get relayUnavailable;

  /// No description provided for @peerBusy.
  ///
  /// In en, this message translates to:
  /// **'The other device is handling another pairing request'**
  String get peerBusy;

  /// No description provided for @peerPairingBlocked.
  ///
  /// In en, this message translates to:
  /// **'The other device has blocked this one; ask them to unblock it first'**
  String get peerPairingBlocked;

  /// No description provided for @peerRelayPairingOff.
  ///
  /// In en, this message translates to:
  /// **'The other device is not accepting pairing requests over the relay'**
  String get peerRelayPairingOff;

  /// No description provided for @incomingRequest.
  ///
  /// In en, this message translates to:
  /// **'\"{deviceName}\" wants to pair with this device'**
  String incomingRequest(String deviceName);

  /// No description provided for @outgoingRequest.
  ///
  /// In en, this message translates to:
  /// **'Pairing with \"{deviceName}\"'**
  String outgoingRequest(String deviceName);

  /// No description provided for @waitingPeer.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the other device…'**
  String get waitingPeer;

  /// No description provided for @peerAccepted.
  ///
  /// In en, this message translates to:
  /// **'The other device confirmed'**
  String get peerAccepted;

  /// No description provided for @peerRejected.
  ///
  /// In en, this message translates to:
  /// **'The other device rejected the pairing'**
  String get peerRejected;

  /// No description provided for @peerTimeout.
  ///
  /// In en, this message translates to:
  /// **'The other device did not confirm in time'**
  String get peerTimeout;

  /// No description provided for @pairingFailed.
  ///
  /// In en, this message translates to:
  /// **'Pairing failed'**
  String get pairingFailed;

  /// No description provided for @pairingSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Paired with \"{deviceName}\"'**
  String pairingSucceeded(String deviceName);

  /// No description provided for @codesMatch.
  ///
  /// In en, this message translates to:
  /// **'Numbers match, pair'**
  String get codesMatch;

  /// No description provided for @codesDiffer.
  ///
  /// In en, this message translates to:
  /// **'They differ, cancel'**
  String get codesDiffer;

  /// No description provided for @blockPeer.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get blockPeer;

  /// No description provided for @pairingBlocklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Pairing blocklist'**
  String get pairingBlocklistTitle;

  /// No description provided for @pairingBlocklistEmpty.
  ///
  /// In en, this message translates to:
  /// **'No blocked devices'**
  String get pairingBlocklistEmpty;

  /// No description provided for @pairingBlocklistManage.
  ///
  /// In en, this message translates to:
  /// **'Blocklist'**
  String get pairingBlocklistManage;

  /// No description provided for @unblockPeer.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblockPeer;

  /// No description provided for @unblockPeerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Unblock \"{name}\"? They will be able to request pairing again.'**
  String unblockPeerConfirm(String name);

  /// No description provided for @pairedDevicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Paired Devices'**
  String get pairedDevicesTitle;

  /// No description provided for @pairedDevicesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No paired devices yet'**
  String get pairedDevicesEmpty;

  /// No description provided for @addPairedDevice.
  ///
  /// In en, this message translates to:
  /// **'Pair a new device'**
  String get addPairedDevice;

  /// No description provided for @unpair.
  ///
  /// In en, this message translates to:
  /// **'Unpair'**
  String get unpair;

  /// No description provided for @unpairConfirm.
  ///
  /// In en, this message translates to:
  /// **'Removing \"{deviceName}\" means comparing the numbers again to restore trust. Continue?'**
  String unpairConfirm(String deviceName);

  /// No description provided for @deviceCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'This device\'s code'**
  String get deviceCodeLabel;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Relay server'**
  String get title;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Forwards files through your own server when devices are not on the same network. A direct connection is always preferred.'**
  String get description;

  /// No description provided for @encryptionNotice.
  ///
  /// In en, this message translates to:
  /// **'Files are end-to-end encrypted between the two paired devices, and only they can decrypt them. The server sees only when a transfer happened and how many bytes it carried.'**
  String get encryptionNotice;

  /// No description provided for @acceptPairingLabel.
  ///
  /// In en, this message translates to:
  /// **'Accept pairing requests over the relay'**
  String get acceptPairingLabel;

  /// No description provided for @acceptPairingHint.
  ///
  /// In en, this message translates to:
  /// **'Any device holding the server token can send a request to your device code. A device you turn down will not ask again.'**
  String get acceptPairingHint;

  /// No description provided for @iosForegroundNotice.
  ///
  /// In en, this message translates to:
  /// **'On iOS, receiving through the relay only works while the app is open.'**
  String get iosForegroundNotice;

  /// No description provided for @enableLabel.
  ///
  /// In en, this message translates to:
  /// **'Enable relay'**
  String get enableLabel;

  /// No description provided for @serverUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get serverUrlLabel;

  /// No description provided for @tokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Access token'**
  String get tokenLabel;

  /// No description provided for @invalidUrl.
  ///
  /// In en, this message translates to:
  /// **'The address must start with http:// or https://'**
  String get invalidUrl;

  /// No description provided for @insecureUrlWarning.
  ///
  /// In en, this message translates to:
  /// **'Traffic is unencrypted over http://, use it only for local testing'**
  String get insecureUrlWarning;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get testConnection;

  /// No description provided for @testSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Connected successfully'**
  String get testSucceeded;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @statusDisabled.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get statusDisabled;

  /// No description provided for @statusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get statusConnecting;

  /// No description provided for @statusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get statusConnected;

  /// No description provided for @statusReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting'**
  String get statusReconnecting;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected by the server'**
  String get statusRejected;

  /// No description provided for @clipboardNeedsPairing.
  ///
  /// In en, this message translates to:
  /// **'Pair with the device first'**
  String get clipboardNeedsPairing;

  /// No description provided for @clipboardRelayUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not connected to the relay server'**
  String get clipboardRelayUnavailable;

  /// No description provided for @clipboardPeerOffline.
  ///
  /// In en, this message translates to:
  /// **'The peer is not online on the relay'**
  String get clipboardPeerOffline;

  /// No description provided for @clipboardFailed.
  ///
  /// In en, this message translates to:
  /// **'Clipboard sync over the relay failed'**
  String get clipboardFailed;

  /// No description provided for @clipboardPeerNoUi.
  ///
  /// In en, this message translates to:
  /// **'The peer cannot confirm the request right now'**
  String get clipboardPeerNoUi;

  /// No description provided for @clipboardPeerBusy.
  ///
  /// In en, this message translates to:
  /// **'The peer is busy, try again later'**
  String get clipboardPeerBusy;

  /// No description provided for @clipboardTooLargeForRelay.
  ///
  /// In en, this message translates to:
  /// **'Clipboard content exceeds the configured size limit'**
  String get clipboardTooLargeForRelay;

  /// No description provided for @clipboardStreamFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch clipboard data over the relay stream'**
  String get clipboardStreamFailed;

  /// No description provided for @clipboardPeerTimeout.
  ///
  /// In en, this message translates to:
  /// **'The peer did not answer the clipboard request'**
  String get clipboardPeerTimeout;

  /// No description provided for @clipboardDeclined.
  ///
  /// In en, this message translates to:
  /// **'The peer declined the clipboard request'**
  String get clipboardDeclined;

  /// No description provided for @selectedRelayPeer.
  ///
  /// In en, this message translates to:
  /// **'Selected relay peer: {name}'**
  String selectedRelayPeer(String name);

  /// No description provided for @clearSelectedPeer.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get clearSelectedPeer;

  /// No description provided for @lanRouteUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Device is not reachable over the local network'**
  String get lanRouteUnavailable;

  /// No description provided for @relayRouteUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Device is not reachable through the relay server'**
  String get relayRouteUnavailable;

  /// No description provided for @relayNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected to the relay server'**
  String get relayNotConnected;

  /// No description provided for @relayPeerOffline.
  ///
  /// In en, this message translates to:
  /// **'The other device must have the app open to receive through the relay'**
  String get relayPeerOffline;

  /// No description provided for @relayPeerNotPaired.
  ///
  /// In en, this message translates to:
  /// **'The other device has not added this one to its trusted list'**
  String get relayPeerNotPaired;

  /// No description provided for @relayPeerBusy.
  ///
  /// In en, this message translates to:
  /// **'The other device is busy with another batch'**
  String get relayPeerBusy;

  /// No description provided for @relayNeedsPairedDevice.
  ///
  /// In en, this message translates to:
  /// **'Relay transfer requires pairing with the device first'**
  String get relayNeedsPairedDevice;

  /// No description provided for @relayNegotiatingSession.
  ///
  /// In en, this message translates to:
  /// **'Establishing an encrypted session…'**
  String get relayNegotiatingSession;

  /// No description provided for @relayIdentityMismatch.
  ///
  /// In en, this message translates to:
  /// **'The peer\'s signature is invalid; it may not be the paired device'**
  String get relayIdentityMismatch;

  /// No description provided for @relayTransferNotice.
  ///
  /// In en, this message translates to:
  /// **'Transferring through the relay server; speed is limited by its bandwidth'**
  String get relayTransferNotice;

  /// No description provided for @retryingAfterInterruption.
  ///
  /// In en, this message translates to:
  /// **'Connection interrupted, retrying ({attempt}/{maxAttempts})…'**
  String retryingAfterInterruption(int attempt, int maxAttempts);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'ja',
    'ko',
    'nl',
    'pt',
    'ru',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'HK':
            return AppLocalizationsZhHk();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'nl':
      return AppLocalizationsNl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
