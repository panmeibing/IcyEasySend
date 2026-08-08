import 'app_localizations.dart';

/// Chinese localization
class AppLocalizationsZh extends AppLocalizations {
  @override
  String get appName => 'Icy Easy Send';

  @override
  String get appVersion => '版本';

  @override
  String get navHome => '首页';

  @override
  String get navHistory => '历史';

  @override
  String get navSettings => '设置';

  @override
  String get homeTitle => '首页';

  @override
  String get serverStatus => '服务状态';

  @override
  String get serverRunning => '运行中';

  @override
  String get serverStopped => '已停止';

  @override
  String get serverAddress => '服务地址';

  @override
  String get deviceName => '设备名称';

  @override
  String get storageSpace => '存储空间';

  @override
  String get availableSpace => '可用空间';

  @override
  String get sendFiles => '发送文件';

  @override
  String get receiveFiles => '接收文件';

  @override
  String get selectFiles => '选择文件';

  @override
  String get selectFolder => '选择文件夹';

  @override
  String get dragDropHint => '拖拽文件到此处';

  @override
  String get noFilesSelected => '未选择文件';

  @override
  String filesSelected(int count) => '已选择 $count 个文件';

  @override
  String get clearSelection => '清除选择';

  @override
  String get startSending => '开始发送';

  @override
  String get sending => '发送中';

  @override
  String get sendSuccess => '发送成功';

  @override
  String get sendFailed => '发送失败';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get historyTitle => '传输历史';

  @override
  String get noHistory => '暂无历史记录';

  @override
  String get clearHistory => '清空历史';

  @override
  String get sent => '已发送';

  @override
  String get received => '已接收';

  @override
  String get failed => '失败';

  @override
  String get fileSize => '文件大小';

  @override
  String get time => '时间';

  @override
  String get deleteItem => '删除记录';

  @override
  String get deleteItemConfirm => '确定要删除这条记录吗？';

  @override
  String get openFile => '打开文件';

  @override
  String get openFolder => '打开文件夹';

  @override
  String get settingsTitle => '设置';

  @override
  String get general => '通用';

  @override
  String get language => '语言';

  @override
  String get deviceNameSetting => '设备名称';

  @override
  String get editDeviceName => '修改设备名称';

  @override
  String get deviceNameHint => '请输入设备名称';

  @override
  String get deviceNameEmpty => '设备名称不能为空';

  @override
  String get port => '端口';

  @override
  String get portHint => '请输入端口号';

  @override
  String get portInvalid => '端口号无效';

  @override
  String get portInUse => '端口已被占用';

  @override
  String get savePath => '保存路径';

  @override
  String get selectSavePath => '选择保存路径';

  @override
  String get savePathDesc => '接收到的文件将保存到此目录。默认使用系统下载文件夹。';

  @override
  String get savePathDefaultBadge => '默认';

  @override
  String get savePathUnavailable => '无法获取保存路径';

  @override
  String get savePathSavedSuccess => '保存路径设置成功';

  @override
  String get savePathNotWritable => '该路径无法写入文件，请选择其他目录或检查权限';

  @override
  String get resetSavePathToDefault => '恢复默认路径';

  @override
  String get savePathResetSuccess => '已恢复为系统下载文件夹';

  @override
  String get autoStart => '自动启动';

  @override
  String get autoStartDesc => '应用启动时自动开启服务';

  @override
  String get network => '网络';

  @override
  String get networkDiagnostics => '网络诊断';

  @override
  String get scanDevices => '扫描设备';

  @override
  String get scanDevicesTitle => '扫描局域网设备';

  @override
  String get scanningDevices => '正在扫描局域网...';

  @override
  String scanProgress(int scanned, int total, int found) =>
      '已扫描 $scanned/$total，发现 $found 台设备';

  @override
  String get noDevicesFound => '未发现设备';

  @override
  String get noDevicesFoundHint =>
      '请确认目标设备已启动服务且在同一局域网内，并检查路由器的 AP 隔离和防火墙设置。';

  @override
  String scanDevicesFound(int count) => '发现 $count 台设备';

  @override
  String get rescan => '重新扫描';

  @override
  String get runDiagnostics => '运行诊断';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get checkUpdate => '检查更新';

  @override
  String get feedback => '反馈';

  @override
  String get openSource => '开源许可';

  @override
  String get license => '许可证';

  @override
  String get permissionRequired => '需要权限';

  @override
  String get permissionDenied => '权限被拒绝';

  @override
  String get permissionPermanentlyDenied => '权限被永久拒绝';

  @override
  String get permissionStorage => '存储权限';

  @override
  String get permissionStorageDesc => '需要存储权限以保存和读取文件';

  @override
  String get permissionNotification => '通知权限';

  @override
  String get permissionNotificationDesc => '需要通知权限以显示传输进度';

  @override
  String get openSettings => '打开设置';

  @override
  String get permissionWarning => '某些权限未授予，部分功能可能受限';

  @override
  String get error => '错误';

  @override
  String get errorUnknown => '未知错误';

  @override
  String get errorNetwork => '网络错误';

  @override
  String get errorFileNotFound => '文件未找到';

  @override
  String get errorPermission => '权限错误';

  @override
  String get errorStorage => '存储错误';

  @override
  String get errorServer => '服务器错误';

  @override
  String get errorServerStart => '服务器启动失败';

  @override
  String get errorServerStop => '服务器停止失败';

  @override
  String get errorConnection => '连接错误';

  @override
  String get errorTimeout => '连接超时';

  @override
  String get retry => '重试';

  @override
  String get copied => '已复制';

  @override
  String get copyFailed => '复制失败';

  @override
  String get saved => '已保存';

  @override
  String get saveFailed => '保存失败';

  @override
  String get deleted => '已删除';

  @override
  String get deleteFailed => '删除失败';

  @override
  String get loading => '加载中';

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
  String get ok => '确定';

  @override
  String get close => '关闭';

  @override
  String get selectFilesFailed => '选择文件失败';

  @override
  String get selectFolderFailed => '选择文件夹失败';

  @override
  String folderFilesAdded(int count) => '已从文件夹添加 $count 个文件';

  @override
  String get folderContainsNoFiles => '所选文件夹中没有可发送的文件';

  @override
  String get openFileFailed => '打开文件失败';

  @override
  String get openFolderFailed => '打开文件夹失败';

  @override
  String get fileNotExist => '文件不存在';

  @override
  String get folderNotExist => '文件夹不存在';

  @override
  String get diagnosticsTitle => '网络诊断';

  @override
  String get diagnosticsRunning => '诊断运行中...';

  @override
  String get diagnosticsComplete => '诊断完成';

  @override
  String get diagnosticsFailed => '诊断失败';

  @override
  String get networkStatus => '网络状态';

  @override
  String get wifiConnected => 'WiFi已连接';

  @override
  String get wifiDisconnected => 'WiFi未连接';

  @override
  String get mobileData => '移动数据';

  @override
  String get noConnection => '无网络连接';

  @override
  String get ipAddress => 'IP地址';

  @override
  String get noIpAddress => '无IP地址';

  @override
  String get serverStatusCheck => '服务器状态检查';

  @override
  String get portCheck => '端口检查';

  @override
  String get portAvailable => '端口可用';

  @override
  String get portUnavailable => '端口不可用';

  @override
  String get suggestions => '建议';

  @override
  String get syncClipboard => '同步对方剪切板';

  @override
  String filesCount(int count) => '发送 $count 个文件';

  @override
  String get sendFile => '发送文件';

  @override
  String get releaseToAdd => '松开鼠标以添加文件';

  @override
  String get serverNotRunning => '服务器未运行，无法接收分享的文件';

  @override
  String get cannotReceiveFiles => '无法接收文件';

  @override
  String get sendingInProgress => '正在发送文件，请稍后再试';

  @override
  String get pleaseTryLater => '请稍后再试';

  @override
  String filesAdded(int count) => '已添加 $count 个分享的文件';

  @override
  String get preparingSend => '准备发送...';

  @override
  String get transferring => '传输中';

  @override
  String transferProgress(int current, int total, String fileName) =>
      '[$current/$total] $fileName: 传输中...';

  @override
  String get networkChanged => '网络已变化，服务器地址已更新';

  @override
  String get serverAddressUpdated => '服务器地址已更新';

  @override
  String get portCannotBeEmpty => '端口不能为空';

  @override
  String get portMustBeNumber => '端口必须是数字';

  @override
  String get portRange => '端口范围: 1-65535';

  @override
  String ipDeleted(String ip) => '已删除 IP: $ip';

  @override
  String get runningDiagnostics => '正在运行网络诊断...';

  @override
  String get targetDeviceInfo => '目标设备信息';

  @override
  String get fullAddress => '完整地址';

  @override
  String get targetNotSet => '未设置目标设备';

  @override
  String get diagnosticsReport => '网络诊断报告';

  @override
  String get reportCopied => '诊断报告已复制到剪贴板';

  @override
  String get deviceNameCannotBeEmpty => '设备名不能为空';

  @override
  String get deviceNameSaved => '设备名已保存';

  @override
  String get resetDeviceName => '重置设备名';

  @override
  String resetDeviceNameConfirm(String model) => '确定要将设备名重置为 "$model" 吗？';

  @override
  String get reset => '重置';

  @override
  String get confirmChange => '确认修改';

  @override
  String concurrentTransfersChange(int from, int to) =>
      '确定要将并发传输数量从 $from 修改为 $to 吗？\n\n提示：${to > from ? "增加并发数可能会提高传输速度，但也会增加设备负载" : "降低并发数可以减少设备负载，但可能会降低传输速度"}';

  @override
  String get concurrentTransfersHint => '并发传输提示';

  @override
  String get concurrentTransfersSaved => '并发传输数量已保存';

  @override
  String get enterValidNumber => '请输入有效的数字';

  @override
  String historyCountRange(int min, int max) => '历史记录数量范围: $min-$max';

  @override
  String maxHistoryChange(int from, int to) =>
      '确定要将最大历史记录数从 $from 修改为 $to 吗？\n\n';

  @override
  String currentHistoryCount(int count) => '当前历史记录数: $count 条\n\n';

  @override
  String get historyWarning => '⚠️ 警告：当前保存的历史记录数大于设置的数量。\n\n';

  @override
  String historyDeleteWarning(int current, int max, int toDelete) =>
      '只会保留最新的 $max 条记录，超过的 $toDelete 条旧记录将被删除。';

  @override
  String get historyHint => '提示：新的设置将在下次保存历史记录时生效。';

  @override
  String historyDeleted(int count) => '设置已保存，已删除 $count 条旧记录';

  @override
  String get maxHistorySaved => '最大历史记录数已保存';

  @override
  String clipboardSizeRange(int min, int max) => '剪切板大小范围: $min-$max MB';

  @override
  String maxClipboardSizeChange(int from, int to) =>
      '确定要将最大剪切板大小从 $from MB 修改为 $to MB 吗？\n\n';

  @override
  String get clipboardSizeDecreaseHint =>
      '⚠️ 提示：降低限制后，超过限制的剪切板内容将无法同步，建议使用文件传输功能。';

  @override
  String get clipboardSizeIncreaseHint => '提示：增加限制后，可以同步更大的剪切板内容，但可能会影响传输速度。';

  @override
  String get maxClipboardSizeSaved => '最大剪切板大小已保存';

  @override
  String get ipValidationEnabled => 'IP地址校验已启用';

  @override
  String get ipValidationDisabled => 'IP地址校验已禁用';

  @override
  String get deviceSecretKeyCleared => '设备秘钥已清空';

  @override
  String get deviceSecretKeySaved => '设备秘钥已保存';

  @override
  String get loadingDevInfo => '正在加载开发信息...';

  @override
  String get copyLog => '复制日志';

  @override
  String logCopied(int lines) => '已复制最后$lines行日志到剪贴板';

  @override
  String get logFileEmpty => '日志文件为空';

  @override
  String get devInfo => '开发信息';

  @override
  String labelCopied(String label, String value) => '$label已复制: $value';

  @override
  String get transferSettings => '传输设置';

  @override
  String get concurrentTransfers => '并发传输数量';

  @override
  String concurrentTransfersDesc(int max) => '同时传输的文件数量（1-$max）';

  @override
  String get concurrentTransfersHintText => '较高的并发数可以更好地利用带宽，但可能增加设备负载';

  @override
  String get maxHistory => '最大历史记录数';

  @override
  String maxHistoryDesc(int min, int max) => '保存的最大传输记录数量（$min-$max）';

  @override
  String maxHistoryHintText(int min, int max) => '输入数量 ($min-$max)';

  @override
  String get oldRecordsAutoDelete => '超过设置数量的旧记录将被自动删除，只保留最新的记录';

  @override
  String get maxClipboard => '最大剪切板大小';

  @override
  String maxClipboardDesc(int min, int max) => '允许同步的最大剪切板大小（$min-$max MB）';

  @override
  String maxClipboardHintText(int min, int max) => '输入大小 ($min-$max MB)';

  @override
  String get clipboardSyncLimit => '超过此大小的剪切板内容将无法同步，建议使用文件传输功能';

  @override
  String get ipValidation => 'IP地址校验';

  @override
  String get ipValidationDesc => '校验目标设备IP是否在同一网段';

  @override
  String get ipValidationEnabledHint => '启用后会检查目标IP是否在同一网段，可以避免连接错误的设备';

  @override
  String get ipValidationDisabledHint => '禁用后不会检查IP网段，适用于复杂网络环境（如热点、VPN等）';

  @override
  String get deviceSecretKey => '本机秘钥';

  @override
  String get deviceSecretKeyDesc => '设置后，其他设备需要提供正确的秘钥才能跳过确认';

  @override
  String get deviceSecretKeyHint => '输入秘钥（留空表示不使用秘钥）';

  @override
  String get notSet => '未设置';

  @override
  String get author => '作者';

  @override
  String get appDescription => '一个简单易用的局域网文件传输工具';

  @override
  String get targetDeviceIP => '目标设备 IP 地址';

  @override
  String get ipHint => '例如: 192.168.1.100';

  @override
  String get clear => '清空';

  @override
  String get history => '历史记录';

  @override
  String resetToDefaultPort(int port) => '重置为默认端口 ($port)';

  @override
  String get targetDeviceSecretKey => '目标设备秘钥（可选）';

  @override
  String get secretKeyHint => '正确的秘钥可跳过对方确认';

  @override
  String get aboutSecretKey => '关于秘钥';

  @override
  String get secretKeyFeatureTitle => '秘钥功能说明';

  @override
  String get secretKeyFeatureDesc =>
      '如果目标设备设置了秘钥，输入正确的秘钥后可以跳过确认框，直接传输文件或同步剪切板。';

  @override
  String get secretKeyUsageSteps => '使用步骤：';

  @override
  String get secretKeyUsageStep1 => '1. 目标设备在设置页面中设置本机秘钥';

  @override
  String get secretKeyUsageStep2 => '2. 在此输入框中输入目标设备的秘钥';

  @override
  String get secretKeyUsageStep3 => '3. 发送文件或请求剪切板时，如果秘钥正确，对方会自动接受';

  @override
  String get secretKeyTip => '提示：留空则使用传统的手动确认方式';

  @override
  String get secretKeyDescription => '秘钥说明';

  @override
  String get clearSecretKey => '清空秘钥';

  @override
  String get gotIt => '知道了';

  @override
  String get targetDevicePort => '目标设备端口';

  @override
  String get localIP => '本机IP';

  @override
  String ipCopied(String ip) => 'IP地址已复制: $ip';

  @override
  String get transferred => '已传输';

  @override
  String get transferSpeed => '传输速度';

  @override
  String get remainingTime => '剩余时间';

  @override
  String transferringProgress(double progress) =>
      '传输中 ${progress.toStringAsFixed(1)}%';

  @override
  String get storagePermissionMessage => '需要存储权限才能选择文件。请在设置中手动开启权限。';

  @override
  String get checkingTargetDevice => '正在检查目标设备...';

  @override
  String get targetDeviceUnavailable => '目标设备不可用';

  @override
  String targetDeviceError(String error) => '目标设备不可用\n错误: $error';

  @override
  String get connectionFailed => '连接失败';

  @override
  String get transferHistory => '传输历史';

  @override
  String get clearHistoryTitle => '清除历史记录';

  @override
  String get clearHistoryMessage => '确定要清除所有传输历史记录吗？此操作无法撤销。';

  @override
  String get noFilteredRecords => '没有符合条件的记录';

  @override
  String get filterAll => '全部';

  @override
  String get filterSent => '已发送';

  @override
  String get filterReceived => '已接收';

  @override
  String get statisticsInfo => '统计信息';

  @override
  String transfersCount(int count) => '$count 次传输';

  @override
  String get totalTransfers => '总传输';

  @override
  String get successfulTransfers => '成功';

  @override
  String get failedTransfers => '失败';

  @override
  String get sentFiles => '已发送';

  @override
  String get receivedFiles => '已接收';

  @override
  String get totalSize => '总大小';

  @override
  String get moreActions => '更多操作';

  @override
  String get deleteRecord => '删除记录';

  @override
  String get viewDetails => '查看详情';

  @override
  String get deleteRecordTitle => '删除记录';

  @override
  String deleteRecordMessage(String fileName) =>
      '确定要删除 "$fileName" 的传输记录吗？\n\n注意：这只会删除记录，不会删除文件本身。';

  @override
  String get deleteRecordNote => '注意：这只会删除记录，不会删除文件本身。';

  @override
  String get recordDeleted => '记录已删除';

  @override
  String get filePathNotExist => '文件路径不存在';

  @override
  String get cannotOpenFile => '无法打开文件';

  @override
  String cannotOpenFileWithMessage(String message) => '无法打开文件: $message';

  @override
  String get iosNoFolderSupport => 'iOS 不支持直接打开文件夹';

  @override
  String get cannotOpenFolder => '无法打开文件夹';

  @override
  String get recentFilesOpened => '已打开最近文件，请手动查找';

  @override
  String get receiveRecord => '接收记录';

  @override
  String get sendRecord => '发送记录';

  @override
  String get fileName => '文件名';

  @override
  String get fromDevice => '来自设备';

  @override
  String get toDevice => '发送至设备';

  @override
  String get deviceIP => '设备 IP';

  @override
  String get transferTime => '传输时间';

  @override
  String get transferStatus => '传输状态';

  @override
  String get statusSuccess => '成功';

  @override
  String get statusFailed => '失败';

  @override
  String get savedLocation => '保存位置';

  @override
  String get copy => '复制';

  @override
  String get pathCopied => '路径已复制到剪贴板';

  @override
  String get from => '来自';

  @override
  String get sentTo => '发送至';

  // Clipboard related
  @override
  String get clipboardRequest => '剪切板请求';

  @override
  String clipboardRequestFrom(String deviceName) =>
      '设备 "$deviceName" 请求获取您的剪切板内容';

  @override
  String get allowClipboardRequest => '是否允许？';

  @override
  String get clipboardRequestMessage => '剪切板请求';

  @override
  String autoRejectIn(int seconds) => '$seconds 秒后自动拒绝';

  @override
  String get reject => '拒绝';

  @override
  String get allow => '允许';

  @override
  String clipboardSharedWithSecretKey(String deviceName) =>
      '$deviceName 使用秘钥验证通过，自动分享剪切板';

  @override
  String get clipboardRequestRejected => '用户拒绝了剪切板请求';

  @override
  String get clipboardEmpty => '剪切板为空';

  @override
  String clipboardContentTooLarge(double actualSizeMB, int maxSizeMB) =>
      '剪切板内容过大 (${actualSizeMB.toStringAsFixed(2)} MB)，超过对方设备的限制 ($maxSizeMB MB)。建议使用文件传输功能。';

  @override
  String get clipboardContentSuccess => '成功获取剪切板内容';

  @override
  String get invalidJsonFormat => '无效的JSON格式';

  @override
  String get serverInternalError => '服务器内部错误';


  @override
  String get backgroundRejectNeedsSecretKey => '设备处于后台，仅支持密钥自动同步/接收。请打开应用或配置匹配的设备密钥。';

  @override
  String get foregroundServiceNotificationTitle => 'IcyEasySend';

  @override
  String get foregroundServiceNotificationText => '正在后台等待文件传输与剪切板同步';

  @override
  String get androidBackgroundReceiveHint => '后台时仅密钥匹配的设备可自动同步剪切板或发送文件，请保留通知栏常驻服务。';

  @override
  String get clipboardOverlay => '剪切板悬浮窗';

  @override
  String get clipboardOverlayDesc => '点击悬浮窗可刷新可同步的文本/图片缓存，便于后台同步';

  @override
  String get clipboardOverlayHint => '后台只能同步上次刷新的内容。关闭开关会清空缓存并隐藏悬浮窗。';

  @override
  String get clipboardOverlayPermissionNeeded => '请在系统设置中允许「显示在其他应用上层」，返回后悬浮窗将自动显示';

  @override
  String get clipboardOverlayEnabledToast => '剪切板悬浮窗已开启';

  @override
  String get clipboardBackgroundCacheMiss => '后台无法读取系统剪切板，且无可用缓存。请打开应用或点击悬浮窗刷新后再同步。';
  // Clipboard sync
  @override
  String get requestingClipboard => '正在请求剪切板...';

  @override
  String get clipboardSyncSuccess => '剪切板同步成功';

  @override
  String get textClipboardSyncSuccess => '文本剪切板同步成功';

  @override
  String get fileClipboardSyncSuccess => '文件剪切板同步成功\n可在应用或文件管理器中粘贴';

  @override
  String get clipboardSyncFailed => '剪切板同步失败';

  @override
  String get syncFailed => '同步失败';

  @override
  String clipboardRequestError(String error) => '请求剪切板时发生错误: $error';

  // File transfer
  @override
  String invalidFilesMessage(String fileNames) => '以下文件无效或无法访问:\n$fileNames';

  @override
  String get waitingForReceiverConfirmation => '等待接收方确认...';

  @override
  String get fileSendSuccess => '文件发送成功！';

  @override
  String filesSendSuccess(int count) => '发送 $count 个文件发送成功！';

  @override
  String get allFilesSendFailed => '所有文件发送失败';

  @override
  String get failedFiles => '失败的文件';

  @override
  String get transferComplete => '传输完成';

  @override
  String get successCount => '成功';

  @override
  String get failureCount => '失败';

  @override
  String transferSummary(
    int successCount,
    int failureCount,
    String failedFiles,
  ) => '成功: $successCount 个文件\n失败: $failureCount 个文件\n\n失败的文件:\n$failedFiles';

  // Batch transfer status
  @override
  String get preparingTransferInfo => '准备传输信息...';

  @override
  String waitingForReceiverConfirmFiles(int count) => '等待接收方确认 $count 个文件...';

  @override
  String transferringFile(int current, int total, String fileName) =>
      '正在传输文件 $current/$total: $fileName';

  @override
  String get receiverRejected => '接收方拒绝接收';

  @override
  String receiverRejectedWithStatus(int statusCode) =>
      '接收方拒绝接收\n状态码: $statusCode';

  @override
  String get transferIdNotFound => '未找到传输ID';

  // Batch receive
  @override
  String get waitingForConfirmation => '等待确认...';

  @override
  String get preparingToReceive => '准备接收...';

  @override
  String get rejected => '已拒绝';

  @override
  String get receiveComplete => '接收完成';

  @override
  String receivingProgress(double progress) =>
      '接收中... ${progress.toStringAsFixed(1)}%';

  @override
  String receivingFiles(int count) => '正在接收 $count 个文件';

  @override
  String receiveFilesCount(int count) => '接收 $count 个文件';

  @override
  String get sender => '发送者';

  @override
  String get totalSizeBatch => '总大小';

  @override
  String get fileList => '文件列表';

  @override
  String get allFilesReceiveComplete => '所有文件接收完成！';

  @override
  String get receivingFiles2 => '正在接收文件...';

  @override
  String autoRejectCountdown(int seconds) => '是否接收这些文件？($seconds 秒后自动拒绝)';

  @override
  String get rejectAll => '全部拒绝';

  @override
  String get acceptAll => '全部接受';

  // Network diagnostics
  @override
  String get networkDiagnosticsReport => '网络诊断报告';

  @override
  String get localNetworkInterfaces => '本地网络接口';

  @override
  String get noValidNetworkInterface => '未找到有效的网络接口';

  @override
  String get privateNetworkAddress => '私有网络地址';

  @override
  String get targetDeviceReachability => '目标设备可达性';

  @override
  String get canConnectToTarget => '可以连接到目标设备';

  @override
  String get cannotConnectToTarget => '无法连接到目标设备';

  @override
  String get healthCheckTest => '健康检查测试';

  @override
  String get healthCheckSuccess => '健康检查成功';

  @override
  String get healthCheckFailed => '健康检查失败';

  @override
  String get statusCode => '状态码';

  @override
  String get response => '响应';

  @override
  String get internetConnection => '互联网连接';

  @override
  String get hasInternetConnection => '有互联网连接';

  @override
  String get noInternetConnection => '无互联网连接';

  // Error messages
  @override
  String get networkConnectionFailed => '无法连接到目标设备，请检查网络连接和 IP 地址';

  @override
  String get networkTimeout => '连接超时，目标设备可能不在线或网络不稳定';

  @override
  String get networkRequestFailed => '网络请求失败，请检查网络连接';

  @override
  String get transferTimeout => '传输超时，请检查网络连接';

  @override
  String get transferInterrupted => '传输中断，请重试';

  @override
  String get fileNotFound => '文件不存在';

  @override
  String get fileNotReadable => '无法读取文件，请确保文件存在且有访问权限';

  @override
  String get fileAccessError => '文件访问错误，请检查文件权限';

  @override
  String get fileSaveFailed => '文件保存失败';

  @override
  String get fileSizeMismatch => '文件保存失败：文件大小不匹配';

  @override
  String get invalidFileName => '文件名包含非法字符';

  @override
  String get downloadsDirectoryUnavailable => '无法访问下载目录';

  @override
  String get storageInsufficient => '存储空间不足，无法接收文件';

  @override
  String get storageCheckFailed => '无法检查存储空间';

  @override
  String get networkPermissionDenied => '需要网络访问权限才能传输文件';

  @override
  String get storagePermissionDenied => '需要存储访问权限才能保存文件';

  @override
  String serverStartFailed(String reason) => '无法启动服务器：$reason';

  @override
  String get serverPortsOccupied => '无法启动服务器：所有端口都已被占用';

  @override
  String serverPortsOccupiedRange(int defaultPort, int maxPort) =>
      '无法启动服务器：端口 $defaultPort-$maxPort 都已被占用';

  @override
  String get serverUnknownError => '无法启动服务器：未知错误';

  @override
  String get transferRejected => '对方拒绝接收文件';

  @override
  String get fileTooLarge => '文件过大，最大支持 2GB';

  @override
  String get fileOrStorageFull => '文件过大或对方存储空间不足';

  @override
  String get receiveTimeout => '接收超时，已自动拒绝';

  @override
  String get userRejected => '用户拒绝接收文件';

  @override
  String get ipAddressEmpty => 'IP 地址不能为空';

  @override
  String get ipAddressInvalidFormat => 'IP 地址格式无效，请使用 xxx.xxx.xxx.xxx 格式';

  @override
  String get ipAddressInvalidRange => 'IP 地址格式无效，每个数字必须在 0-255 之间';

  @override
  String get ipAddressSpecial1 => '不能使用 0.0.0.0 作为目标地址';

  @override
  String get ipAddressSpecial2 => '不能使用广播地址 255.255.255.255';

  @override
  String ipAddressNotInSameSubnet(
    String localIP,
    String targetIP,
    String localNetwork,
    String targetNetwork,
  ) =>
      '⚠️ 网段不匹配\n'
      '本机IP: $localIP (网段: $localNetwork.x)\n'
      '目标IP: $targetIP (网段: $targetNetwork.x)\n'
      '\n'
      '提示：两台设备需要在同一个局域网（相同网段）才能传输文件。\n'
      'C类IPv4地址应该保证两个IP地址的前三个数字相同，例如都是192.169.2，只是最后一个数字不同\n'
      '最简单的方法就是让两个设备都连接同一个WiFi或路由器。\n';

  @override
  String get responseParseError => '无法解析服务器响应';

  @override
  String get responseInvalidFormat => '目标设备响应格式不正确';

  @override
  String responseStatusCodeError(int statusCode) => '服务器返回错误状态码: $statusCode';

  @override
  String get fileSelectionError => '选择文件时出错';

  @override
  String get fileSelectionCancelled => '已取消选择文件';

  @override
  String genericError(String operation) => '$operation失败';

  @override
  String unexpectedError(String details) => '发生意外错误: $details';

  @override
  String networkError(String context) => '网络错误: $context';

  @override
  String fileError(String context) => '文件错误: $context';

  @override
  String permissionError(String permissionType) => '需要$permissionType权限才能继续操作';
}
