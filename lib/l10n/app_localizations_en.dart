import 'app_localizations.dart';

/// English localization
class AppLocalizationsEn extends AppLocalizations {
  @override
  String get appName => 'Icy Easy Send';

  @override
  String get appVersion => 'Version';

  @override
  String get navHome => 'Home';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get homeTitle => 'Home';

  @override
  String get serverStatus => 'Server Status';

  @override
  String get serverRunning => 'Running';

  @override
  String get serverStopped => 'Stopped';

  @override
  String get serverAddress => 'Server Address';

  @override
  String get deviceName => 'Device Name';

  @override
  String get storageSpace => 'Storage Space';

  @override
  String get availableSpace => 'Available';

  @override
  String get sendFiles => 'Send Files';

  @override
  String get receiveFiles => 'Receive Files';

  @override
  String get selectFiles => 'Select Files';

  @override
  String get selectFolder => 'Select Folder';

  @override
  String get dragDropHint => 'Drag and drop files here';

  @override
  String get noFilesSelected => 'No files selected';

  @override
  String filesSelected(int count) =>
      '$count file${count > 1 ? 's' : ''} selected';

  @override
  String get clearSelection => 'Clear';

  @override
  String get startSending => 'Send';

  @override
  String get sending => 'Sending';

  @override
  String get sendSuccess => 'Sent successfully';

  @override
  String get sendFailed => 'Send failed';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get historyTitle => 'Transfer History';

  @override
  String get noHistory => 'No history';

  @override
  String get clearHistory => 'Clear History';

  @override
  String get sent => 'Sent';

  @override
  String get received => 'Received';

  @override
  String get failed => 'Failed';

  @override
  String get fileSize => 'Size';

  @override
  String get time => 'Time';

  @override
  String get deleteItem => 'Delete';

  @override
  String get deleteItemConfirm => 'Are you sure you want to delete this item?';

  @override
  String get openFile => 'Open File';

  @override
  String get openFolder => 'Open Folder';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get general => 'General';

  @override
  String get language => 'Language';

  @override
  String get deviceNameSetting => 'Device Name';

  @override
  String get editDeviceName => 'Edit Device Name';

  @override
  String get deviceNameHint => 'Enter device name';

  @override
  String get deviceNameEmpty => 'Device name cannot be empty';

  @override
  String get port => 'Port';

  @override
  String get portHint => 'Enter port number';

  @override
  String get portInvalid => 'Invalid port number';

  @override
  String get portInUse => 'Port is already in use';

  @override
  String get savePath => 'Save Path';

  @override
  String get selectSavePath => 'Select Save Path';

  @override
  String get savePathDesc =>
      'Received files are saved here. The system downloads folder is used by default.';

  @override
  String get savePathDefaultBadge => 'Default';

  @override
  String get savePathUnavailable => 'Unable to resolve save path';

  @override
  String get savePathSavedSuccess => 'Save path updated successfully';

  @override
  String get savePathNotWritable =>
      'Cannot write to this folder. Please choose another location or check permissions.';

  @override
  String get resetSavePathToDefault => 'Use default folder';

  @override
  String get savePathResetSuccess => 'Restored to system downloads folder';

  @override
  String get autoStart => 'Auto Start';

  @override
  String get autoStartDesc => 'Start server automatically when app launches';

  @override
  String get network => 'Network';

  @override
  String get networkDiagnostics => 'Network Diagnostics';

  @override
  String get scanDevices => 'Scan Devices';

  @override
  String get scanDevicesTitle => 'Scan LAN Devices';

  @override
  String get scanningDevices => 'Scanning local network...';

  @override
  String scanProgress(int scanned, int total, int found) =>
      'Scanned $scanned/$total, found $found device${found == 1 ? '' : 's'}';

  @override
  String get noDevicesFound => 'No devices found';

  @override
  String get noDevicesFoundHint =>
      'Make sure the target device has started the server and is on the same network. Check router AP isolation and firewall settings.';

  @override
  String scanDevicesFound(int count) =>
      'Found $count device${count == 1 ? '' : 's'}';

  @override
  String get rescan => 'Rescan';

  @override
  String get runDiagnostics => 'Run Diagnostics';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get checkUpdate => 'Check for Updates';

  @override
  String get feedback => 'Feedback';

  @override
  String get openSource => 'Open Source Licenses';

  @override
  String get license => 'License';

  @override
  String get permissionRequired => 'Permission Required';

  @override
  String get permissionDenied => 'Permission Denied';

  @override
  String get permissionPermanentlyDenied => 'Permission Permanently Denied';

  @override
  String get permissionStorage => 'Storage Permission';

  @override
  String get permissionStorageDesc =>
      'Storage permission is required to save and read files';

  @override
  String get permissionNotification => 'Notification Permission';

  @override
  String get permissionNotificationDesc =>
      'Notification permission is required to show transfer progress';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get permissionWarning =>
      'Some permissions are not granted, some features may be limited';

  @override
  String get error => 'Error';

  @override
  String get errorUnknown => 'Unknown error';

  @override
  String get errorNetwork => 'Network error';

  @override
  String get errorFileNotFound => 'File not found';

  @override
  String get errorPermission => 'Permission error';

  @override
  String get errorStorage => 'Storage error';

  @override
  String get errorServer => 'Server error';

  @override
  String get errorServerStart => 'Failed to start server';

  @override
  String get errorServerStop => 'Failed to stop server';

  @override
  String get errorConnection => 'Connection error';

  @override
  String get errorTimeout => 'Connection timeout';

  @override
  String get retry => 'Retry';

  @override
  String get copied => 'Copied';

  @override
  String get copyFailed => 'Copy failed';

  @override
  String get saved => 'Saved';

  @override
  String get saveFailed => 'Save failed';

  @override
  String get deleted => 'Deleted';

  @override
  String get deleteFailed => 'Delete failed';

  @override
  String get loading => 'Loading';

  @override
  String get success => 'Success';

  @override
  String get warning => 'Warning';

  @override
  String get info => 'Info';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Close';

  @override
  String get selectFilesFailed => 'Failed to select files';

  @override
  String get selectFolderFailed => 'Failed to select folder';

  @override
  String folderFilesAdded(int count) => 'Added $count files from folder';

  @override
  String get folderContainsNoFiles =>
      'The selected folder contains no files to send';

  @override
  String get openFileFailed => 'Failed to open file';

  @override
  String get openFolderFailed => 'Failed to open folder';

  @override
  String get fileNotExist => 'File does not exist';

  @override
  String get folderNotExist => 'Folder does not exist';

  @override
  String get diagnosticsTitle => 'Network Diagnostics';

  @override
  String get diagnosticsRunning => 'Running diagnostics...';

  @override
  String get diagnosticsComplete => 'Diagnostics complete';

  @override
  String get diagnosticsFailed => 'Diagnostics failed';

  @override
  String get networkStatus => 'Network Status';

  @override
  String get wifiConnected => 'WiFi Connected';

  @override
  String get wifiDisconnected => 'WiFi Disconnected';

  @override
  String get mobileData => 'Mobile Data';

  @override
  String get noConnection => 'No Connection';

  @override
  String get ipAddress => 'IP Address';

  @override
  String get noIpAddress => 'No IP Address';

  @override
  String get serverStatusCheck => 'Server Status Check';

  @override
  String get portCheck => 'Port Check';

  @override
  String get portAvailable => 'Port Available';

  @override
  String get portUnavailable => 'Port Unavailable';

  @override
  String get suggestions => 'Suggestions';

  @override
  String get syncClipboard => 'Sync Remote Clipboard';

  @override
  String filesCount(int count) => 'Send $count file${count > 1 ? 's' : ''}';

  @override
  String get sendFile => 'Send File';

  @override
  String get releaseToAdd => 'Release to add files';

  @override
  String get serverNotRunning =>
      'Server not running, cannot receive shared files';

  @override
  String get cannotReceiveFiles => 'Cannot receive files';

  @override
  String get sendingInProgress => 'File transfer in progress, please try later';

  @override
  String get pleaseTryLater => 'Please try later';

  @override
  String filesAdded(int count) =>
      'Added $count shared file${count > 1 ? 's' : ''}';

  @override
  String get preparingSend => 'Preparing to send...';

  @override
  String get transferring => 'Transferring';

  @override
  String transferProgress(int current, int total, String fileName) =>
      '[$current/$total] $fileName: Transferring...';

  @override
  String get networkChanged => 'Network changed, server address updated';

  @override
  String get serverAddressUpdated => 'Server address updated';

  @override
  String get portCannotBeEmpty => 'Port cannot be empty';

  @override
  String get portMustBeNumber => 'Port must be a number';

  @override
  String get portRange => 'Port range: 1-65535';

  @override
  String ipDeleted(String ip) => 'Deleted IP: $ip';

  @override
  String get runningDiagnostics => 'Running network diagnostics...';

  @override
  String get targetDeviceInfo => 'Target Device Info';

  @override
  String get fullAddress => 'Full Address';

  @override
  String get targetNotSet => 'Target device not set';

  @override
  String get diagnosticsReport => 'Network Diagnostics Report';

  @override
  String get reportCopied => 'Diagnostics report copied to clipboard';

  @override
  String get deviceNameCannotBeEmpty => 'Device name cannot be empty';

  @override
  String get deviceNameSaved => 'Device name saved';

  @override
  String get resetDeviceName => 'Reset Device Name';

  @override
  String resetDeviceNameConfirm(String model) =>
      'Are you sure you want to reset device name to "$model"?';

  @override
  String get reset => 'Reset';

  @override
  String get confirmChange => 'Confirm Change';

  @override
  String concurrentTransfersChange(int from, int to) =>
      'Change concurrent transfers from $from to $to?\n\nNote: ${to > from ? "Increasing may improve transfer speed but will increase device load" : "Decreasing will reduce device load but may lower transfer speed"}';

  @override
  String get concurrentTransfersHint => 'Concurrent transfers hint';

  @override
  String get concurrentTransfersSaved => 'Concurrent transfers saved';

  @override
  String get enterValidNumber => 'Please enter a valid number';

  @override
  String historyCountRange(int min, int max) =>
      'History count range: $min-$max';

  @override
  String maxHistoryChange(int from, int to) =>
      'Change max history items from $from to $to?\n\n';

  @override
  String currentHistoryCount(int count) =>
      'Current history count: $count items\n\n';

  @override
  String get historyWarning =>
      '⚠️ Warning: Current history count exceeds the new limit.\n\n';

  @override
  String historyDeleteWarning(int current, int max, int toDelete) =>
      'Only the latest $max items will be kept, $toDelete old items will be deleted.';

  @override
  String get historyHint => 'Note: New setting will take effect on next save.';

  @override
  String historyDeleted(int count) =>
      'Settings saved, deleted $count old items';

  @override
  String get maxHistorySaved => 'Max history items saved';

  @override
  String clipboardSizeRange(int min, int max) =>
      'Clipboard size range: $min-$max MB';

  @override
  String maxClipboardSizeChange(int from, int to) =>
      'Change max clipboard size from $from MB to $to MB?\n\n';

  @override
  String get clipboardSizeDecreaseHint =>
      '⚠️ Note: After decreasing the limit, clipboard content exceeding the new size cannot be synced. Please use file transfer instead.';

  @override
  String get clipboardSizeIncreaseHint =>
      'Note: After increasing the limit, larger clipboard content can be synced, but this may affect transfer speed.';

  @override
  String get maxClipboardSizeSaved => 'Max clipboard size saved';

  @override
  String get ipValidationEnabled => 'IP validation enabled';

  @override
  String get ipValidationDisabled => 'IP validation disabled';

  @override
  String get deviceSecretKeyCleared => 'Device secret key cleared';

  @override
  String get deviceSecretKeySaved => 'Device secret key saved';

  @override
  String get loadingDevInfo => 'Loading developer info...';

  @override
  String get copyLog => 'Copy Log';

  @override
  String logCopied(int lines) => 'Copied last $lines lines of log to clipboard';

  @override
  String get logFileEmpty => 'Log file is empty';

  @override
  String get devInfo => 'Developer Info';

  @override
  String labelCopied(String label, String value) => '$label copied: $value';

  @override
  String get transferSettings => 'Transfer Settings';

  @override
  String get concurrentTransfers => 'Concurrent Transfers';

  @override
  String concurrentTransfersDesc(int max) =>
      'Number of files to transfer simultaneously (1-$max)';

  @override
  String get concurrentTransfersHintText =>
      'Higher concurrency can better utilize bandwidth, but may increase device load';

  @override
  String get maxHistory => 'Max History Items';

  @override
  String maxHistoryDesc(int min, int max) =>
      'Maximum number of transfer records to save ($min-$max)';

  @override
  String maxHistoryHintText(int min, int max) => 'Enter count ($min-$max)';

  @override
  String get oldRecordsAutoDelete =>
      'Records exceeding the limit will be automatically deleted, keeping only the most recent ones';

  @override
  String get maxClipboard => 'Max Clipboard Size';

  @override
  String maxClipboardDesc(int min, int max) =>
      'Maximum clipboard size allowed for sync ($min-$max MB)';

  @override
  String maxClipboardHintText(int min, int max) => 'Enter size ($min-$max MB)';

  @override
  String get clipboardSyncLimit =>
      'Clipboard content exceeding this size cannot be synced. Use file transfer instead';

  @override
  String get ipValidation => 'IP Validation';

  @override
  String get ipValidationDesc =>
      'Validate if target device IP is in the same subnet';

  @override
  String get ipValidationEnabledHint =>
      'When enabled, verifies that the target IP is in the same subnet to prevent connecting to incorrect devices';

  @override
  String get ipValidationDisabledHint =>
      'When disabled, IP subnet validation is skipped. Suitable for complex network environments (hotspot, VPN, etc.)';

  @override
  String get deviceSecretKey => 'Device Secret Key';

  @override
  String get deviceSecretKeyDesc =>
      'When set, other devices need to provide the correct key to skip confirmation';

  @override
  String get deviceSecretKeyHint => 'Enter secret key (leave empty to disable)';

  @override
  String get notSet => 'Not Set';

  @override
  String get author => 'Author';

  @override
  String get appDescription =>
      'A simple and easy-to-use LAN file transfer tool';

  @override
  String get targetDeviceIP => 'Target Device IP Address';

  @override
  String get ipHint => 'e.g.: 192.168.1.100';

  @override
  String get clear => 'Clear';

  @override
  String get history => 'History';

  @override
  String get targetDevicePort => 'Target Device Port';

  @override
  String resetToDefaultPort(int port) => 'Reset to default port ($port)';

  @override
  String get targetDeviceSecretKey => 'Target Device Secret Key (Optional)';

  @override
  String get secretKeyHint => 'Correct key can skip confirmation';

  @override
  String get aboutSecretKey => 'About Secret Key';

  @override
  String get secretKeyFeatureTitle => 'Secret Key Feature';

  @override
  String get secretKeyFeatureDesc =>
      'If the target device has set a secret key, entering the correct key allows you to skip the confirmation dialog and directly transfer files or sync clipboard.';

  @override
  String get secretKeyUsageSteps => 'Usage Steps:';

  @override
  String get secretKeyUsageStep1 =>
      '1. Target device sets its secret key in Settings';

  @override
  String get secretKeyUsageStep2 =>
      '2. Enter the target device\'s secret key in this field';

  @override
  String get secretKeyUsageStep3 =>
      '3. When sending files or requesting clipboard, if the key is correct, the other party will automatically accept';

  @override
  String get secretKeyTip =>
      'Tip: Leave empty to use traditional manual confirmation';

  @override
  String get secretKeyDescription => 'Secret Key Description';

  @override
  String get clearSecretKey => 'Clear Secret Key';

  @override
  String get gotIt => 'Got It';

  @override
  String get localIP => 'Local IP';

  @override
  String ipCopied(String ip) => 'IP address copied: $ip';

  @override
  String get transferred => 'Transferred';

  @override
  String get transferSpeed => 'Transfer Speed';

  @override
  String get remainingTime => 'Remaining Time';

  @override
  String transferringProgress(double progress) =>
      'Transferring ${progress.toStringAsFixed(1)}%';

  @override
  String get storagePermissionMessage =>
      'Storage permission is required to select files. Please enable it manually in Settings.';

  @override
  String get checkingTargetDevice => 'Checking target device...';

  @override
  String get targetDeviceUnavailable => 'Target device unavailable';

  @override
  String targetDeviceError(String error) =>
      'Target device unavailable\nError: $error';

  @override
  String get connectionFailed => 'Connection Failed';

  @override
  String get transferHistory => 'Transfer History';

  @override
  String get clearHistoryTitle => 'Clear History';

  @override
  String get clearHistoryMessage =>
      'Are you sure you want to clear all transfer history? This action cannot be undone.';

  @override
  String get noFilteredRecords => 'No matching records';

  @override
  String get filterAll => 'All';

  @override
  String get filterSent => 'Sent';

  @override
  String get filterReceived => 'Received';

  @override
  String get statisticsInfo => 'Statistics';

  @override
  String transfersCount(int count) => '$count transfer${count > 1 ? 's' : ''}';

  @override
  String get totalTransfers => 'Total';

  @override
  String get successfulTransfers => 'Success';

  @override
  String get failedTransfers => 'Failed';

  @override
  String get sentFiles => 'Sent';

  @override
  String get receivedFiles => 'Received';

  @override
  String get totalSize => 'Total Size';

  @override
  String get moreActions => 'More Actions';

  @override
  String get viewDetails => 'View Details';

  @override
  String get deleteRecord => 'Delete Record';

  @override
  String get deleteRecordTitle => 'Delete Record';

  @override
  String deleteRecordMessage(String fileName) =>
      'Are you sure you want to delete the transfer record for "$fileName"?\n\nNote: This will only delete the record, not the file itself.';

  @override
  String get deleteRecordNote =>
      'Note: This will only delete the record, not the file itself.';

  @override
  String get recordDeleted => 'Record deleted';

  @override
  String get filePathNotExist => 'File path does not exist';

  @override
  String get cannotOpenFile => 'Cannot open file';

  @override
  String cannotOpenFileWithMessage(String message) =>
      'Cannot open file: $message';

  @override
  String get iosNoFolderSupport =>
      'iOS does not support opening folders directly';

  @override
  String get cannotOpenFolder => 'Cannot open folder';

  @override
  String get recentFilesOpened => 'Recent files opened, please search manually';

  @override
  String get receiveRecord => 'Receive Record';

  @override
  String get sendRecord => 'Send Record';

  @override
  String get fileName => 'File Name';

  @override
  String get fromDevice => 'From Device';

  @override
  String get toDevice => 'To Device';

  @override
  String get deviceIP => 'Device IP';

  @override
  String get transferTime => 'Transfer Time';

  @override
  String get transferStatus => 'Transfer Status';

  @override
  String get statusSuccess => 'Success';

  @override
  String get statusFailed => 'Failed';

  @override
  String get savedLocation => 'Saved Location';

  @override
  String get copy => 'Copy';

  @override
  String get pathCopied => 'Path copied to clipboard';

  @override
  String get from => 'From';

  @override
  String get sentTo => 'Sent to';

  // Clipboard related
  @override
  String get clipboardRequest => 'Clipboard Request';

  @override
  String clipboardRequestFrom(String deviceName) =>
      'Device "$deviceName" is requesting access to your clipboard content';

  @override
  String get allowClipboardRequest => 'Allow this request?';

  @override
  String get clipboardRequestMessage => 'Clipboard Request';

  @override
  String autoRejectIn(int seconds) => 'Auto-reject in $seconds seconds';

  @override
  String get reject => 'Reject';

  @override
  String get allow => 'Allow';

  @override
  String clipboardSharedWithSecretKey(String deviceName) =>
      '$deviceName verified with secret key, clipboard shared automatically';

  @override
  String get clipboardRequestRejected => 'User rejected clipboard request';

  @override
  String get clipboardEmpty => 'Clipboard is empty';

  @override
  String clipboardContentTooLarge(double actualSizeMB, int maxSizeMB) =>
      'Clipboard content too large (${actualSizeMB.toStringAsFixed(2)} MB), exceeds recipient device limit ($maxSizeMB MB). Please use file transfer instead.';

  @override
  String get clipboardContentSuccess =>
      'Successfully retrieved clipboard content';

  @override
  String get invalidJsonFormat => 'Invalid JSON format';

  @override
  String get serverInternalError => 'Server internal error';


  @override
  String get backgroundRejectNeedsSecretKey => 'Device is in the background. Only secret-key auto sync/receive is supported. Open the app or configure a matching device secret key.';

  @override
  String get foregroundServiceNotificationTitle => 'IcyEasySend';

  @override
  String get foregroundServiceNotificationText => 'Waiting for file transfers and clipboard sync in the background';

  @override
  String get androidBackgroundReceiveHint => 'While backgrounded, only peers with a matching secret key can auto-sync clipboard or send files. Keep the persistent notification running.';

  @override
  String get clipboardOverlay => 'Clipboard floating button';

  @override
  String get clipboardOverlayDesc => 'Tap the floating button to refresh cached text/images for background sync';

  @override
  String get clipboardOverlayHint => 'While backgrounded, only the last refreshed content can be synced. Turning this off clears the cache and hides the button.';

  @override
  String get clipboardOverlayPermissionNeeded => 'Allow "Display over other apps" in system settings. The floating button will appear after you return.';

  @override
  String get clipboardOverlayEnabledToast => 'Clipboard floating button enabled';

  @override
  String get clipboardBackgroundCacheMiss => 'Cannot read the system clipboard in the background and no cache is available. Open the app or tap the floating button to refresh, then sync again.';
  // Clipboard sync
  @override
  String get requestingClipboard => 'Requesting clipboard...';

  @override
  String get clipboardSyncSuccess => 'Clipboard synced successfully';

  @override
  String get textClipboardSyncSuccess => 'Text clipboard synced successfully';

  @override
  String get fileClipboardSyncSuccess =>
      'File clipboard synced successfully\nYou can paste in app or file manager';

  @override
  String get clipboardSyncFailed => 'Clipboard sync failed';

  @override
  String get syncFailed => 'Sync Failed';

  @override
  String clipboardRequestError(String error) =>
      'Error occurred while requesting clipboard: $error';

  // File transfer
  @override
  String invalidFilesMessage(String fileNames) =>
      'The following files are invalid or inaccessible:\n$fileNames';

  @override
  String get waitingForReceiverConfirmation =>
      'Waiting for receiver confirmation...';

  @override
  String get fileSendSuccess => 'File sent successfully!';

  @override
  String filesSendSuccess(int count) => '$count files sent successfully!';

  @override
  String get allFilesSendFailed => 'All files failed to send';

  @override
  String get failedFiles => 'Failed files';

  @override
  String get transferComplete => 'Transfer Complete';

  @override
  String get successCount => 'Success';

  @override
  String get failureCount => 'Failed';

  @override
  String transferSummary(
    int successCount,
    int failureCount,
    String failedFiles,
  ) =>
      'Success: $successCount files\nFailed: $failureCount files\n\nFailed files:\n$failedFiles';

  // Batch transfer status
  @override
  String get preparingTransferInfo => 'Preparing transfer info...';

  @override
  String waitingForReceiverConfirmFiles(int count) =>
      'Waiting for receiver to confirm $count files...';

  @override
  String transferringFile(int current, int total, String fileName) =>
      'Transferring file $current/$total: $fileName';

  @override
  String get receiverRejected => 'Receiver rejected';

  @override
  String receiverRejectedWithStatus(int statusCode) =>
      'Receiver rejected\nStatus code: $statusCode';

  @override
  String get transferIdNotFound => 'Transfer ID not found';

  // Batch receive
  @override
  String get waitingForConfirmation => 'Waiting for confirmation...';

  @override
  String get preparingToReceive => 'Preparing to receive...';

  @override
  String get rejected => 'Rejected';

  @override
  String get receiveComplete => 'Receive complete';

  @override
  String receivingProgress(double progress) =>
      'Receiving... ${progress.toStringAsFixed(1)}%';

  @override
  String receivingFiles(int count) => 'Receiving $count files';

  @override
  String receiveFilesCount(int count) => 'Receive $count files';

  @override
  String get sender => 'Sender';

  @override
  String get totalSizeBatch => 'Total Size';

  @override
  String get fileList => 'File List';

  @override
  String get allFilesReceiveComplete => 'All files received successfully!';

  @override
  String get receivingFiles2 => 'Receiving files...';

  @override
  String autoRejectCountdown(int seconds) =>
      'Accept these files? (Auto-reject in $seconds seconds)';

  @override
  String get rejectAll => 'Reject All';

  @override
  String get acceptAll => 'Accept All';

  // Network diagnostics
  @override
  String get networkDiagnosticsReport => 'Network Diagnostics Report';

  @override
  String get localNetworkInterfaces => 'Local Network Interfaces';

  @override
  String get noValidNetworkInterface => 'No valid network interface found';

  @override
  String get privateNetworkAddress => 'Private Network Address';

  @override
  String get targetDeviceReachability => 'Target Device Reachability';

  @override
  String get canConnectToTarget => 'Can connect to target device';

  @override
  String get cannotConnectToTarget => 'Cannot connect to target device';

  @override
  String get healthCheckTest => 'Health Check Test';

  @override
  String get healthCheckSuccess => 'Health Check Successful';

  @override
  String get healthCheckFailed => 'Health Check Failed';

  @override
  String get statusCode => 'Status Code';

  @override
  String get response => 'Response';

  @override
  String get internetConnection => 'Internet Connection';

  @override
  String get hasInternetConnection => 'Internet connection available';

  @override
  String get noInternetConnection => 'No Internet Connection';

  // Error messages
  @override
  String get networkConnectionFailed =>
      'Unable to connect to target device, please check network connection and IP address';

  @override
  String get networkTimeout =>
      'Connection timeout, target device may be offline or network is unstable';

  @override
  String get networkRequestFailed =>
      'Network request failed, please check network connection';

  @override
  String get transferTimeout =>
      'Transfer timeout, please check network connection';

  @override
  String get transferInterrupted => 'Transfer interrupted, please retry';

  @override
  String get fileNotFound => 'File not found';

  @override
  String get fileNotReadable =>
      'Unable to read file, please ensure file exists and has access permission';

  @override
  String get fileAccessError =>
      'File access error, please check file permissions';

  @override
  String get fileSaveFailed => 'File save failed';

  @override
  String get fileSizeMismatch => 'File save failed: file size mismatch';

  @override
  String get invalidFileName => 'File name contains invalid characters';

  @override
  String get downloadsDirectoryUnavailable =>
      'Unable to access downloads directory';

  @override
  String get storageInsufficient =>
      'Insufficient storage space, cannot receive file';

  @override
  String get storageCheckFailed => 'Unable to check storage space';

  @override
  String get networkPermissionDenied =>
      'Network access permission required to transfer files';

  @override
  String get storagePermissionDenied =>
      'Storage access permission required to save files';

  @override
  String serverStartFailed(String reason) => 'Unable to start server: $reason';

  @override
  String get serverPortsOccupied =>
      'Unable to start server: all ports are occupied';

  @override
  String serverPortsOccupiedRange(int defaultPort, int maxPort) =>
      'Unable to start server: ports $defaultPort-$maxPort are all occupied';

  @override
  String get serverUnknownError => 'Unable to start server: unknown error';

  @override
  String get transferRejected => 'Transfer rejected by recipient';

  @override
  String get fileTooLarge => 'File too large, maximum 2GB supported';

  @override
  String get fileOrStorageFull =>
      'File too large or recipient storage space insufficient';

  @override
  String get receiveTimeout => 'Receive timeout, automatically rejected';

  @override
  String get userRejected => 'User rejected file transfer';

  @override
  String get ipAddressEmpty => 'IP address cannot be empty';

  @override
  String get ipAddressInvalidFormat =>
      'Invalid IP address format, please use xxx.xxx.xxx.xxx format';

  @override
  String get ipAddressInvalidRange =>
      'Invalid IP address format, each number must be between 0-255';

  @override
  String get ipAddressSpecial1 => 'Cannot use 0.0.0.0 as target address';

  @override
  String get ipAddressSpecial2 =>
      'Cannot use broadcast address 255.255.255.255';

  @override
  String ipAddressNotInSameSubnet(
    String localIP,
    String targetIP,
    String localNetwork,
    String targetNetwork,
  ) =>
      '⚠️ Subnet Mismatch\n'
      'Local IP: $localIP (Subnet: $localNetwork.x)\n'
      'Target IP: $targetIP (Subnet: $targetNetwork.x)\n'
      '\n'
      'Note: Both devices must be on the same LAN (same subnet) to transfer files.\n'
      'For Class C IPv4 addresses, the first three numbers should be identical (e.g., 192.168.2), with only the last number differing.\n'
      'The simplest solution is to connect both devices to the same WiFi network or router.\n';

  @override
  String get responseParseError => 'Unable to parse server response';

  @override
  String get responseInvalidFormat =>
      'Target device response format is incorrect';

  @override
  String responseStatusCodeError(int statusCode) =>
      'Server returned error status code: $statusCode';

  @override
  String get fileSelectionError => 'Error occurred while selecting file';

  @override
  String get fileSelectionCancelled => 'File selection cancelled';

  @override
  String genericError(String operation) => '$operation failed';

  @override
  String unexpectedError(String details) =>
      'Unexpected error occurred: $details';

  @override
  String networkError(String context) => 'Network error: $context';

  @override
  String fileError(String context) => 'File error: $context';

  @override
  String permissionError(String permissionType) =>
      '$permissionType permission required to continue';
}
