import 'app_localizations.dart';

/// Traditional Chinese (Hong Kong) localization
class AppLocalizationsZhHk extends AppLocalizations {
  @override
  String get appName => 'Icy Easy Send';

  @override
  String get appVersion => '版本';

  @override
  String get navHome => '首頁';

  @override
  String get navHistory => '歷史';

  @override
  String get navSettings => '設定';

  @override
  String get homeTitle => '首頁';

  @override
  String get serverStatus => '服務狀態';

  @override
  String get serverRunning => '運行中';

  @override
  String get serverStopped => '已停止';

  @override
  String get serverAddress => '服務地址';

  @override
  String get deviceName => '裝置名稱';

  @override
  String get storageSpace => '儲存空間';

  @override
  String get availableSpace => '可用空間';

  @override
  String get sendFiles => '傳送檔案';

  @override
  String get receiveFiles => '接收檔案';

  @override
  String get selectFiles => '選擇檔案';

  @override
  String get selectFolder => '選擇資料夾';

  @override
  String get dragDropHint => '拖曳檔案到此處';

  @override
  String get noFilesSelected => '未選擇檔案';

  @override
  String filesSelected(int count) => '已選擇 $count 個檔案';

  @override
  String get clearSelection => '清除選擇';

  @override
  String get startSending => '開始傳送';

  @override
  String get sending => '傳送中';

  @override
  String get sendSuccess => '傳送成功';

  @override
  String get sendFailed => '傳送失敗';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '確認';

  @override
  String get historyTitle => '傳輸歷史';

  @override
  String get noHistory => '暫無歷史記錄';

  @override
  String get clearHistory => '清空歷史';

  @override
  String get sent => '已傳送';

  @override
  String get received => '已接收';

  @override
  String get failed => '失敗';

  @override
  String get fileSize => '檔案大小';

  @override
  String get time => '時間';

  @override
  String get deleteItem => '刪除記錄';

  @override
  String get deleteItemConfirm => '確定要刪除這條記錄嗎？';

  @override
  String get openFile => '開啟檔案';

  @override
  String get openFolder => '開啟資料夾';

  @override
  String get settingsTitle => '設定';

  @override
  String get general => '通用';

  @override
  String get language => '語言';

  @override
  String get deviceNameSetting => '裝置名稱';

  @override
  String get editDeviceName => '修改裝置名稱';

  @override
  String get deviceNameHint => '請輸入裝置名稱';

  @override
  String get deviceNameEmpty => '裝置名稱不能為空';

  @override
  String get port => '連接埠';

  @override
  String get portHint => '請輸入連接埠號';

  @override
  String get portInvalid => '連接埠號無效';

  @override
  String get portInUse => '連接埠已被佔用';

  @override
  String get savePath => '儲存路徑';

  @override
  String get selectSavePath => '選擇儲存路徑';

  @override
  String get savePathDesc => '接收到的檔案將儲存到此目錄。預設使用系統下載資料夾。';

  @override
  String get savePathDefaultBadge => '預設';

  @override
  String get savePathUnavailable => '無法取得儲存路徑';

  @override
  String get savePathSavedSuccess => '儲存路徑設定成功';

  @override
  String get savePathNotWritable => '此路徑無法寫入檔案，請選擇其他目錄或檢查權限';

  @override
  String get resetSavePathToDefault => '恢復預設路徑';

  @override
  String get savePathResetSuccess => '已恢復為系統下載資料夾';

  @override
  String get autoStart => '自動啟動';

  @override
  String get autoStartDesc => '應用程式啟動時自動開啟服務';

  @override
  String get network => '網路';

  @override
  String get networkDiagnostics => '網路診斷';

  @override
  String get scanDevices => '掃描裝置';

  @override
  String get scanDevicesTitle => '掃描區域網路裝置';

  @override
  String get scanningDevices => '正在掃描區域網路...';

  @override
  String scanProgress(int scanned, int total, int found) =>
      '已掃描 $scanned/$total，發現 $found 台裝置';

  @override
  String get noDevicesFound => '未發現裝置';

  @override
  String get noDevicesFoundHint =>
      '請確認目標裝置已啟動服務且在同一區域網路內，並檢查路由器的 AP 隔離和防火牆設定。';

  @override
  String scanDevicesFound(int count) => '發現 $count 台裝置';

  @override
  String get rescan => '重新掃描';

  @override
  String get runDiagnostics => '執行診斷';

  @override
  String get about => '關於';

  @override
  String get version => '版本';

  @override
  String get checkUpdate => '檢查更新';

  @override
  String get feedback => '意見回饋';

  @override
  String get openSource => '開源授權';

  @override
  String get license => '授權條款';

  @override
  String get permissionRequired => '需要權限';

  @override
  String get permissionDenied => '權限被拒絕';

  @override
  String get permissionPermanentlyDenied => '權限被永久拒絕';

  @override
  String get permissionStorage => '儲存權限';

  @override
  String get permissionStorageDesc => '需要儲存權限以儲存和讀取檔案';

  @override
  String get permissionNotification => '通知權限';

  @override
  String get permissionNotificationDesc => '需要通知權限以顯示傳輸進度';

  @override
  String get openSettings => '開啟設定';

  @override
  String get permissionWarning => '某些權限未授予，部分功能可能受限';

  @override
  String get error => '錯誤';

  @override
  String get errorUnknown => '未知錯誤';

  @override
  String get errorNetwork => '網路錯誤';

  @override
  String get errorFileNotFound => '檔案未找到';

  @override
  String get errorPermission => '權限錯誤';

  @override
  String get errorStorage => '儲存錯誤';

  @override
  String get errorServer => '伺服器錯誤';

  @override
  String get errorServerStart => '伺服器啟動失敗';

  @override
  String get errorServerStop => '伺服器停止失敗';

  @override
  String get errorConnection => '連線錯誤';

  @override
  String get errorTimeout => '連線逾時';

  @override
  String get retry => '重試';

  @override
  String get copied => '已複製';

  @override
  String get copyFailed => '複製失敗';

  @override
  String get saved => '已儲存';

  @override
  String get saveFailed => '儲存失敗';

  @override
  String get deleted => '已刪除';

  @override
  String get deleteFailed => '刪除失敗';

  @override
  String get loading => '載入中';

  @override
  String get success => '成功';

  @override
  String get warning => '警告';

  @override
  String get info => '提示';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get ok => '確定';

  @override
  String get close => '關閉';

  @override
  String get selectFilesFailed => '選擇檔案失敗';

  @override
  String get selectFolderFailed => '選擇資料夾失敗';

  @override
  String folderFilesAdded(int count) => '已從資料夾添加 $count 個檔案';

  @override
  String get folderContainsNoFiles => '所選資料夾中沒有可傳送的檔案';

  @override
  String get openFileFailed => '開啟檔案失敗';

  @override
  String get openFolderFailed => '開啟資料夾失敗';

  @override
  String get fileNotExist => '檔案不存在';

  @override
  String get folderNotExist => '資料夾不存在';

  @override
  String get diagnosticsTitle => '網路診斷';

  @override
  String get diagnosticsRunning => '診斷執行中...';

  @override
  String get diagnosticsComplete => '診斷完成';

  @override
  String get diagnosticsFailed => '診斷失敗';

  @override
  String get networkStatus => '網路狀態';

  @override
  String get wifiConnected => 'WiFi已連線';

  @override
  String get wifiDisconnected => 'WiFi未連線';

  @override
  String get mobileData => '行動數據';

  @override
  String get noConnection => '無網路連線';

  @override
  String get ipAddress => 'IP位址';

  @override
  String get noIpAddress => '無IP位址';

  @override
  String get serverStatusCheck => '伺服器狀態檢查';

  @override
  String get portCheck => '連接埠檢查';

  @override
  String get portAvailable => '連接埠可用';

  @override
  String get portUnavailable => '連接埠不可用';

  @override
  String get suggestions => '建議';

  @override
  String get syncClipboard => '同步對方剪貼簿';

  @override
  String filesCount(int count) => '傳送 $count 個檔案';

  @override
  String get sendFile => '傳送檔案';

  @override
  String get shareViaQr => '二維碼分享';

  @override
  String get webShareTitle => '掃碼接收檔案';

  @override
  String get webShareHint =>
      '對方使用系統相機掃碼即可在瀏覽器中下載，無需安裝本應用。請保持同一 Wi‑Fi / 局域網；微信等第三方掃碼器可能無法開啟，可複製連結傳送。';

  @override
  String get webShareCopyLink => '複製連結';

  @override
  String get webShareLinkCopied => '連結已複製';

  @override
  String get webShareStopSharing => '停止分享';

  @override
  String get webShareStopped => '已停止網頁分享';

  @override
  String get webShareServerRequired => '請先啟動本機服務後再使用二維碼分享';

  @override
  String get webShareCreated => '網頁分享已建立，對方掃碼即可下載';

  @override
  String get webShareFailed => '建立網頁分享失敗';

  @override
  String get webSharePeerName => '網頁分享';

  @override
  String webShareFilesSummary(int count, String size) => '$count 個檔案 · $size';

  @override
  String webShareExpiresIn(String time) => '剩餘有效時間 $time';

  @override
  String get releaseToAdd => '放開滑鼠以新增檔案';

  @override
  String get serverNotRunning => '伺服器未執行，無法接收分享的檔案';

  @override
  String get cannotReceiveFiles => '無法接收檔案';

  @override
  String get sendingInProgress => '正在傳送檔案，請稍後再試';

  @override
  String get pleaseTryLater => '請稍後再試';

  @override
  String filesAdded(int count) => '已新增 $count 個分享的檔案';

  @override
  String get preparingSend => '準備傳送...';

  @override
  String get transferring => '傳輸中';

  @override
  String transferProgress(int current, int total, String fileName) =>
      '[$current/$total] $fileName: 傳輸中...';

  @override
  String get networkChanged => '網路已變化，伺服器位址已更新';

  @override
  String get serverAddressUpdated => '伺服器位址已更新';

  @override
  String get portCannotBeEmpty => '連接埠不能為空';

  @override
  String get portMustBeNumber => '連接埠必須是數字';

  @override
  String get portRange => '連接埠範圍: 1-65535';

  @override
  String ipDeleted(String ip) => '已刪除 IP: $ip';

  @override
  String get runningDiagnostics => '正在執行網路診斷...';

  @override
  String get targetDeviceInfo => '目標裝置資訊';

  @override
  String get fullAddress => '完整位址';

  @override
  String get targetNotSet => '未設定目標裝置';

  @override
  String get diagnosticsReport => '網路診斷報告';

  @override
  String get reportCopied => '診斷報告已複製到剪貼簿';

  @override
  String get deviceNameCannotBeEmpty => '裝置名稱不能為空';

  @override
  String get deviceNameSaved => '裝置名稱已儲存';

  @override
  String get resetDeviceName => '重設裝置名稱';

  @override
  String resetDeviceNameConfirm(String model) => '確定要將裝置名稱重設為 "$model" 嗎？';

  @override
  String get reset => '重設';

  @override
  String get confirmChange => '確認修改';

  @override
  String concurrentTransfersChange(int from, int to) =>
      '確定要將並行傳輸數量從 $from 修改為 $to 嗎？\n\n提示：${to > from ? "增加並行數可能會提高傳輸速度，但也會增加裝置負載" : "降低並行數可以減少裝置負載，但可能會降低傳輸速度"}';

  @override
  String get concurrentTransfersHint => '並行傳輸提示';

  @override
  String get concurrentTransfersSaved => '並行傳輸數量已儲存';

  @override
  String get enterValidNumber => '請輸入有效的數字';

  @override
  String historyCountRange(int min, int max) => '歷史記錄數量範圍: $min-$max';

  @override
  String maxHistoryChange(int from, int to) =>
      '確定要將最大歷史記錄數從 $from 修改為 $to 嗎？\n\n';

  @override
  String currentHistoryCount(int count) => '目前歷史記錄數: $count 條\n\n';

  @override
  String get historyWarning => '⚠️ 警告：目前儲存的歷史記錄數大於設定的數量。\n\n';

  @override
  String historyDeleteWarning(int current, int max, int toDelete) =>
      '只會保留最新的 $max 條記錄，超過的 $toDelete 條舊記錄將被刪除。';

  @override
  String get historyHint => '提示：新的設定將在下次儲存歷史記錄時生效。';

  @override
  String historyDeleted(int count) => '設定已儲存，已刪除 $count 條舊記錄';

  @override
  String get maxHistorySaved => '最大歷史記錄數已儲存';

  @override
  String clipboardSizeRange(int min, int max) => '剪貼簿大小範圍: $min-$max MB';

  @override
  String maxClipboardSizeChange(int from, int to) =>
      '確定要將最大剪貼簿大小從 $from MB 修改為 $to MB 嗎？\n\n';

  @override
  String get clipboardSizeDecreaseHint =>
      '⚠️ 提示：降低限制後，超過限制的剪貼簿內容將無法同步，建議使用檔案傳輸功能。';

  @override
  String get clipboardSizeIncreaseHint => '提示：增加限制後，可以同步更大的剪貼簿內容，但可能會影響傳輸速度。';

  @override
  String get maxClipboardSizeSaved => '最大剪貼簿大小已儲存';

  @override
  String get ipValidationEnabled => 'IP位址校驗已啟用';

  @override
  String get ipValidationDisabled => 'IP位址校驗已停用';

  @override
  String get deviceSecretKeyCleared => '裝置密鑰已清空';

  @override
  String get deviceSecretKeySaved => '裝置密鑰已儲存';

  @override
  String get loadingDevInfo => '正在載入開發資訊...';

  @override
  String get copyLog => '複製日誌';

  @override
  String logCopied(int lines) => '已複製最後$lines行日誌到剪貼簿';

  @override
  String get logFileEmpty => '日誌檔案為空';

  @override
  String get devInfo => '開發資訊';

  @override
  String labelCopied(String label, String value) => '$label已複製: $value';

  @override
  String get transferSettings => '傳輸設定';

  @override
  String get concurrentTransfers => '並行傳輸數量';

  @override
  String concurrentTransfersDesc(int max) => '同時傳輸的檔案數量（1-$max）';

  @override
  String get concurrentTransfersHintText => '較高的並行數可以更好地利用頻寬，但可能增加裝置負載';

  @override
  String get maxHistory => '最大歷史記錄數';

  @override
  String maxHistoryDesc(int min, int max) => '儲存的最大傳輸記錄數量（$min-$max）';

  @override
  String maxHistoryHintText(int min, int max) => '輸入數量 ($min-$max)';

  @override
  String get oldRecordsAutoDelete => '超過設定數量的舊記錄將被自動刪除，只保留最新的記錄';

  @override
  String get maxClipboard => '最大剪貼簿大小';

  @override
  String maxClipboardDesc(int min, int max) => '允許同步的最大剪貼簿大小（$min-$max MB）';

  @override
  String maxClipboardHintText(int min, int max) => '輸入大小 ($min-$max MB)';

  @override
  String get clipboardSyncLimit => '超過此大小的剪貼簿內容將無法同步，建議使用檔案傳輸功能';

  @override
  String get ipValidation => 'IP位址校驗';

  @override
  String get ipValidationDesc => '校驗目標裝置IP是否在同一網段';

  @override
  String get ipValidationEnabledHint => '啟用後會檢查目標IP是否在同一網段，可以避免連線錯誤的裝置';

  @override
  String get ipValidationDisabledHint => '停用後不會檢查IP網段，適用於複雜網路環境（如熱點、VPN等）';

  @override
  String get deviceSecretKey => '本機密鑰';

  @override
  String get deviceSecretKeyDesc => '設定後，其他裝置需要提供正確的密鑰才能跳過確認';

  @override
  String get deviceSecretKeyHint => '輸入密鑰（留空表示不使用密鑰）';

  @override
  String get notSet => '未設定';

  @override
  String get author => '作者';

  @override
  String get appDescription => '一個簡單易用的區域網路檔案傳輸工具';

  @override
  String get targetDeviceIP => '目標裝置 IP 位址';

  @override
  String get ipHint => '例如: 192.168.1.100';

  @override
  String get clear => '清空';

  @override
  String get history => '歷史記錄';

  @override
  String resetToDefaultPort(int port) => '重設為預設連接埠 ($port)';

  @override
  String get targetDeviceSecretKey => '目標裝置密鑰（選填）';

  @override
  String get secretKeyHint => '正確的密鑰可跳過對方確認';

  @override
  String get aboutSecretKey => '關於密鑰';

  @override
  String get secretKeyFeatureTitle => '密鑰功能說明';

  @override
  String get secretKeyFeatureDesc =>
      '如果目標裝置設定了密鑰，輸入正確的密鑰後可以跳過確認框，直接傳輸檔案或同步剪貼簿。';

  @override
  String get secretKeyUsageSteps => '使用步驟：';

  @override
  String get secretKeyUsageStep1 => '1. 目標裝置在設定頁面中設定本機密鑰';

  @override
  String get secretKeyUsageStep2 => '2. 在此輸入框中輸入目標裝置的密鑰';

  @override
  String get secretKeyUsageStep3 => '3. 傳送檔案或請求剪貼簿時，如果密鑰正確，對方會自動接受';

  @override
  String get secretKeyTip => '提示：留空則使用傳統的手動確認方式';

  @override
  String get secretKeyDescription => '密鑰說明';

  @override
  String get clearSecretKey => '清空密鑰';

  @override
  String get gotIt => '知道了';

  @override
  String get targetDevicePort => '目標裝置連接埠';

  @override
  String get localIP => '本機IP';

  @override
  String ipCopied(String ip) => 'IP位址已複製: $ip';

  @override
  String get transferred => '已傳輸';

  @override
  String get transferSpeed => '傳輸速度';

  @override
  String get remainingTime => '剩餘時間';

  @override
  String transferringProgress(double progress) =>
      '傳輸中 ${progress.toStringAsFixed(1)}%';

  @override
  String get storagePermissionMessage => '需要儲存權限才能選擇檔案。請在設定中手動開啟權限。';

  @override
  String get checkingTargetDevice => '正在檢查目標裝置...';

  @override
  String get targetDeviceUnavailable => '目標裝置不可用';

  @override
  String targetDeviceError(String error) => '目標裝置不可用\n錯誤: $error';

  @override
  String get connectionFailed => '連線失敗';

  @override
  String get transferHistory => '傳輸歷史';

  @override
  String get clearHistoryTitle => '清除歷史記錄';

  @override
  String get clearHistoryMessage => '確定要清除所有傳輸歷史記錄嗎？此操作無法復原。';

  @override
  String get noFilteredRecords => '沒有符合條件的記錄';

  @override
  String get filterAll => '全部';

  @override
  String get filterSent => '已傳送';

  @override
  String get filterReceived => '已接收';

  @override
  String get statisticsInfo => '統計資訊';

  @override
  String transfersCount(int count) => '$count 次傳輸';

  @override
  String get totalTransfers => '總傳輸';

  @override
  String get successfulTransfers => '成功';

  @override
  String get failedTransfers => '失敗';

  @override
  String get sentFiles => '已傳送';

  @override
  String get receivedFiles => '已接收';

  @override
  String get totalSize => '總大小';

  @override
  String get moreActions => '更多操作';

  @override
  String get deleteRecord => '刪除記錄';

  @override
  String get viewDetails => '檢視詳情';

  @override
  String get deleteRecordTitle => '刪除記錄';

  @override
  String deleteRecordMessage(String fileName) =>
      '確定要刪除 "$fileName" 的傳輸記錄嗎？\n\n注意：這只會刪除記錄，不會刪除檔案本身。';

  @override
  String get deleteRecordNote => '注意：這只會刪除記錄，不會刪除檔案本身。';

  @override
  String get recordDeleted => '記錄已刪除';

  @override
  String get filePathNotExist => '檔案路徑不存在';

  @override
  String get cannotOpenFile => '無法開啟檔案';

  @override
  String cannotOpenFileWithMessage(String message) => '無法開啟檔案: $message';

  @override
  String get iosNoFolderSupport => 'iOS 不支援直接開啟資料夾';

  @override
  String get cannotOpenFolder => '無法開啟資料夾';

  @override
  String get recentFilesOpened => '已開啟最近檔案，請手動尋找';

  @override
  String get receiveRecord => '接收記錄';

  @override
  String get sendRecord => '傳送記錄';

  @override
  String get fileName => '檔案名稱';

  @override
  String get fromDevice => '來自裝置';

  @override
  String get toDevice => '傳送至裝置';

  @override
  String get deviceIP => '裝置 IP';

  @override
  String get transferTime => '傳輸時間';

  @override
  String get transferStatus => '傳輸狀態';

  @override
  String get statusSuccess => '成功';

  @override
  String get statusFailed => '失敗';

  @override
  String get savedLocation => '儲存位置';

  @override
  String get copy => '複製';

  @override
  String get pathCopied => '路徑已複製到剪貼簿';

  @override
  String get from => '來自';

  @override
  String get sentTo => '傳送至';

  // Clipboard related
  @override
  String get clipboardRequest => '剪貼簿請求';

  @override
  String clipboardRequestFrom(String deviceName) =>
      '裝置 "$deviceName" 請求取得您的剪貼簿內容';

  @override
  String get allowClipboardRequest => '是否允許？';

  @override
  String get clipboardRequestMessage => '剪貼簿請求';

  @override
  String autoRejectIn(int seconds) => '$seconds 秒後自動拒絕';

  @override
  String get reject => '拒絕';

  @override
  String get allow => '允許';

  @override
  String clipboardSharedWithSecretKey(String deviceName) =>
      '$deviceName 使用密鑰驗證通過，自動分享剪貼簿';

  @override
  String get clipboardRequestRejected => '使用者拒絕了剪貼簿請求';

  @override
  String get clipboardEmpty => '剪貼簿為空';

  @override
  String clipboardContentTooLarge(double actualSizeMB, int maxSizeMB) =>
      '剪貼簿內容過大 (${actualSizeMB.toStringAsFixed(2)} MB)，超過對方裝置的限制 ($maxSizeMB MB)。建議使用檔案傳輸功能。';

  @override
  String get clipboardContentSuccess => '成功取得剪貼簿內容';

  @override
  String get invalidJsonFormat => '無效的JSON格式';

  @override
  String get serverInternalError => '伺服器內部錯誤';


  @override
  String get backgroundRejectNeedsSecretKey => '裝置處於背景，僅支援密鑰自動同步/接收。請打開應用程式或設定相符的裝置密鑰。';

  @override
  String get foregroundServiceNotificationTitle => 'IcyEasySend';

  @override
  String get foregroundServiceNotificationText => '正在背景等待檔案傳輸與剪貼簿同步';

  @override
  String get androidBackgroundReceiveHint => '背景時僅密鑰相符的裝置可自動同步剪貼簿或傳送檔案，請保留通知列常駐服務。';

  @override
  String get clipboardOverlay => '剪貼簿懸浮窗';

  @override
  String get clipboardOverlayDesc => '點擊懸浮窗可重新整理可同步的文字/圖片快取，方便背景同步';

  @override
  String get clipboardOverlayHint => '背景只能同步上次重新整理的內容。關閉開關會清空快取並隱藏懸浮窗。';

  @override
  String get clipboardOverlayPermissionNeeded => '請在系統設定中允許「顯示在其他應用程式上層」，返回後懸浮窗將自動顯示';

  @override
  String get clipboardOverlayEnabledToast => '剪貼簿懸浮窗已開啟';

  @override
  String get clipboardBackgroundCacheMiss => '背景無法讀取系統剪貼簿，且無可用快取。請打開應用程式或點擊懸浮窗重新整理後再同步。';
  // Clipboard sync
  @override
  String get requestingClipboard => '正在請求剪貼簿...';

  @override
  String get clipboardSyncSuccess => '剪貼簿同步成功';

  @override
  String get textClipboardSyncSuccess => '文字剪貼簿同步成功';

  @override
  String get fileClipboardSyncSuccess => '檔案剪貼簿同步成功\n可在應用程式或檔案管理器中貼上';

  @override
  String get clipboardSyncFailed => '剪貼簿同步失敗';

  @override
  String get syncFailed => '同步失敗';

  @override
  String clipboardRequestError(String error) => '請求剪貼簿時發生錯誤: $error';

  // File transfer
  @override
  String invalidFilesMessage(String fileNames) => '以下檔案無效或無法存取:\n$fileNames';

  @override
  String get waitingForReceiverConfirmation => '等待接收方確認...';

  @override
  String get fileSendSuccess => '檔案傳送成功！';

  @override
  String filesSendSuccess(int count) => '傳送 $count 個檔案傳送成功！';

  @override
  String get allFilesSendFailed => '所有檔案傳送失敗';

  @override
  String get failedFiles => '失敗的檔案';

  @override
  String get transferComplete => '傳輸完成';

  @override
  String get successCount => '成功';

  @override
  String get failureCount => '失敗';

  @override
  String transferSummary(
    int successCount,
    int failureCount,
    String failedFiles,
  ) => '成功: $successCount 個檔案\n失敗: $failureCount 個檔案\n\n失敗的檔案:\n$failedFiles';

  // Batch transfer status
  @override
  String get preparingTransferInfo => '準備傳輸資訊...';

  @override
  String waitingForReceiverConfirmFiles(int count) => '等待接收方確認 $count 個檔案...';

  @override
  String transferringFile(int current, int total, String fileName) =>
      '正在傳輸檔案 $current/$total: $fileName';

  @override
  String get receiverRejected => '接收方拒絕接收';

  @override
  String receiverRejectedWithStatus(int statusCode) =>
      '接收方拒絕接收\n狀態碼: $statusCode';

  @override
  String get transferIdNotFound => '未找到傳輸ID';

  // Batch receive
  @override
  String get waitingForConfirmation => '等待確認...';

  @override
  String get preparingToReceive => '準備接收...';

  @override
  String get rejected => '已拒絕';

  @override
  String get receiveComplete => '接收完成';

  @override
  String receivingProgress(double progress) =>
      '接收中... ${progress.toStringAsFixed(1)}%';

  @override
  String receivingFiles(int count) => '正在接收 $count 個檔案';

  @override
  String receiveFilesCount(int count) => '接收 $count 個檔案';

  @override
  String get sender => '傳送者';

  @override
  String get totalSizeBatch => '總大小';

  @override
  String get fileList => '檔案清單';

  @override
  String get allFilesReceiveComplete => '所有檔案接收完成！';

  @override
  String get receivingFiles2 => '正在接收檔案...';

  @override
  String autoRejectCountdown(int seconds) => '是否接收這些檔案？($seconds 秒後自動拒絕)';

  @override
  String get rejectAll => '全部拒絕';

  @override
  String get acceptAll => '全部接受';

  // Network diagnostics
  @override
  String get networkDiagnosticsReport => '網路診斷報告';

  @override
  String get localNetworkInterfaces => '本機網路介面';

  @override
  String get noValidNetworkInterface => '未找到有效的網路介面';

  @override
  String get privateNetworkAddress => '私有網路位址';

  @override
  String get targetDeviceReachability => '目標裝置可達性';

  @override
  String get canConnectToTarget => '可以連線到目標裝置';

  @override
  String get cannotConnectToTarget => '無法連線到目標裝置';

  @override
  String get healthCheckTest => '健康檢查測試';

  @override
  String get healthCheckSuccess => '健康檢查成功';

  @override
  String get healthCheckFailed => '健康檢查失敗';

  @override
  String get statusCode => '狀態碼';

  @override
  String get response => '回應';

  @override
  String get internetConnection => '網際網路連線';

  @override
  String get hasInternetConnection => '有網際網路連線';

  @override
  String get noInternetConnection => '無網際網路連線';

  // Error messages
  @override
  String get networkConnectionFailed => '無法連線到目標裝置，請檢查網路連線和 IP 位址';

  @override
  String get networkTimeout => '連線逾時，目標裝置可能不在線上或網路不穩定';

  @override
  String get networkRequestFailed => '網路請求失敗，請檢查網路連線';

  @override
  String get transferTimeout => '傳輸逾時，請檢查網路連線';

  @override
  String get transferInterrupted => '傳輸中斷，請重試';

  @override
  String get fileNotFound => '檔案不存在';

  @override
  String get fileNotReadable => '無法讀取檔案，請確保檔案存在且有存取權限';

  @override
  String get fileAccessError => '檔案存取錯誤，請檢查檔案權限';

  @override
  String get fileSaveFailed => '檔案儲存失敗';

  @override
  String get fileSizeMismatch => '檔案儲存失敗：檔案大小不符';

  @override
  String get invalidFileName => '檔案名稱包含非法字元';

  @override
  String get downloadsDirectoryUnavailable => '無法存取下載目錄';

  @override
  String get storageInsufficient => '儲存空間不足，無法接收檔案';

  @override
  String get storageCheckFailed => '無法檢查儲存空間';

  @override
  String get networkPermissionDenied => '需要網路存取權限才能傳輸檔案';

  @override
  String get storagePermissionDenied => '需要儲存存取權限才能儲存檔案';

  @override
  String serverStartFailed(String reason) => '無法啟動伺服器：$reason';

  @override
  String get serverPortsOccupied => '無法啟動伺服器：所有連接埠都已被佔用';

  @override
  String serverPortsOccupiedRange(int defaultPort, int maxPort) =>
      '無法啟動伺服器：連接埠 $defaultPort-$maxPort 都已被佔用';

  @override
  String get serverUnknownError => '無法啟動伺服器：未知錯誤';

  @override
  String get transferRejected => '對方拒絕接收檔案';

  @override
  String get fileTooLarge => '檔案過大，最大支援 2GB';

  @override
  String get fileOrStorageFull => '檔案過大或對方儲存空間不足';

  @override
  String get receiveTimeout => '接收逾時，已自動拒絕';

  @override
  String get userRejected => '使用者拒絕接收檔案';

  @override
  String get ipAddressEmpty => 'IP 位址不能為空';

  @override
  String get ipAddressInvalidFormat => 'IP 位址格式無效，請使用 xxx.xxx.xxx.xxx 格式';

  @override
  String get ipAddressInvalidRange => 'IP 位址格式無效，每個數字必須在 0-255 之間';

  @override
  String get ipAddressSpecial1 => '不能使用 0.0.0.0 作為目標位址';

  @override
  String get ipAddressSpecial2 => '不能使用廣播位址 255.255.255.255';

  @override
  String ipAddressNotInSameSubnet(
    String localIP,
    String targetIP,
    String localNetwork,
    String targetNetwork,
  ) =>
      '⚠️ 網段不符\n'
      '本機IP: $localIP (網段: $localNetwork.x)\n'
      '目標IP: $targetIP (網段: $targetNetwork.x)\n'
      '\n'
      '提示：兩台裝置需要在同一個區域網路（相同網段）才能傳輸檔案。\n'
      'C類IPv4位址應該保證兩個IP位址的前三個數字相同，例如都是192.169.2，只是最後一個數字不同\n'
      '最簡單的方法就是讓兩個裝置都連線同一個WiFi或路由器。\n';

  @override
  String get responseParseError => '無法解析伺服器回應';

  @override
  String get responseInvalidFormat => '目標裝置回應格式不正確';

  @override
  String responseStatusCodeError(int statusCode) => '伺服器傳回錯誤狀態碼: $statusCode';

  @override
  String get fileSelectionError => '選擇檔案時出錯';

  @override
  String get fileSelectionCancelled => '已取消選擇檔案';

  @override
  String genericError(String operation) => '$operation失敗';

  @override
  String unexpectedError(String details) => '發生意外錯誤: $details';

  @override
  String networkError(String context) => '網路錯誤: $context';

  @override
  String fileError(String context) => '檔案錯誤: $context';

  @override
  String permissionError(String permissionType) => '需要$permissionType權限才能繼續操作';
}
