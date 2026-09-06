// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

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
  String filesSelected(int count) {
    return '已选择 $count 个文件';
  }

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
  String scanProgress(int scanned, int total, int found) {
    return '已扫描 $scanned/$total，发现 $found 台设备';
  }

  @override
  String get noDevicesFound => '未发现设备';

  @override
  String get noDevicesFoundHint => '请确认目标设备已启动服务且在同一局域网内，并检查路由器的 AP 隔离和防火墙设置。';

  @override
  String scanDevicesFound(int count) {
    return '发现 $count 台设备';
  }

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
  String folderFilesAdded(int count) {
    return '已从文件夹添加 $count 个文件';
  }

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
  String filesCount(int count) {
    return '发送 $count 个文件';
  }

  @override
  String get sendFile => '发送文件';

  @override
  String get shareViaQr => '二维码分享';

  @override
  String get webShareTitle => '扫码接收文件';

  @override
  String get webShareHint =>
      '对方使用系统相机扫码即可在浏览器中下载，无需安装本应用。请保持同一 Wi‑Fi / 局域网；微信等第三方扫码器可能无法打开，可复制链接发送。';

  @override
  String get webShareCopyLink => '复制链接';

  @override
  String get webShareLinkCopied => '链接已复制';

  @override
  String get webShareStopSharing => '停止分享';

  @override
  String get webShareStopped => '已停止网页分享';

  @override
  String get webShareServerRequired => '请先启动本机服务后再使用二维码分享';

  @override
  String get webShareCreated => '网页分享已创建，对方扫码即可下载';

  @override
  String get webShareFailed => '创建网页分享失败';

  @override
  String get webSharePeerName => '网页分享';

  @override
  String webShareFilesSummary(int count, String size) {
    return '$count 个文件 · $size';
  }

  @override
  String webShareExpiresIn(String time) {
    return '剩余有效时间 $time';
  }

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
  String filesAdded(int count) {
    return '已添加 $count 个分享的文件';
  }

  @override
  String get preparingSend => '准备发送...';

  @override
  String get transferring => '传输中';

  @override
  String transferProgress(int current, int total, String fileName) {
    return '[$current/$total] $fileName: 传输中...';
  }

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
  String ipDeleted(String ip) {
    return '已删除 IP: $ip';
  }

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
  String resetDeviceNameConfirm(String model) {
    return '确定要将设备名重置为 \"$model\" 吗？';
  }

  @override
  String get reset => '重置';

  @override
  String get confirmChange => '确认修改';

  @override
  String concurrentTransfersIncrease(int from, int to) {
    return '确定要将并发传输数量从 $from 修改为 $to 吗？\n\n提示：增加并发数可能会提高传输速度，但也会增加设备负载';
  }

  @override
  String concurrentTransfersDecrease(int from, int to) {
    return '确定要将并发传输数量从 $from 修改为 $to 吗？\n\n提示：降低并发数可以减少设备负载，但可能会降低传输速度';
  }

  @override
  String get concurrentTransfersHint => '并发传输提示';

  @override
  String get concurrentTransfersSaved => '并发传输数量已保存';

  @override
  String get enterValidNumber => '请输入有效的数字';

  @override
  String historyCountRange(int min, int max) {
    return '历史记录数量范围: $min-$max';
  }

  @override
  String maxHistoryChange(int from, int to) {
    return '确定要将最大历史记录数从 $from 修改为 $to 吗？\n\n';
  }

  @override
  String currentHistoryCount(int count) {
    return '当前历史记录数: $count 条\n\n';
  }

  @override
  String get historyWarning => '⚠️ 警告：当前保存的历史记录数大于设置的数量。\n\n';

  @override
  String historyDeleteWarning(int current, int max, int toDelete) {
    return '只会保留最新的 $max 条记录，超过的 $toDelete 条旧记录将被删除。';
  }

  @override
  String get historyHint => '提示：新的设置将在下次保存历史记录时生效。';

  @override
  String historyDeleted(int count) {
    return '设置已保存，已删除 $count 条旧记录';
  }

  @override
  String get maxHistorySaved => '最大历史记录数已保存';

  @override
  String clipboardSizeRange(int min, int max) {
    return '剪切板大小范围: $min-$max MB';
  }

  @override
  String maxClipboardSizeChange(int from, int to) {
    return '确定要将最大剪切板大小从 $from MB 修改为 $to MB 吗？\n\n';
  }

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
  String logCopied(int lines) {
    return '已复制最后$lines行日志到剪贴板';
  }

  @override
  String get logFileEmpty => '日志文件为空';

  @override
  String get devInfo => '开发信息';

  @override
  String labelCopied(String label, String value) {
    return '$label已复制: $value';
  }

  @override
  String get transferSettings => '传输设置';

  @override
  String get concurrentTransfers => '并发传输数量';

  @override
  String concurrentTransfersDesc(int max) {
    return '同时传输的文件数量（1-$max）';
  }

  @override
  String get concurrentTransfersHintText => '较高的并发数可以更好地利用带宽，但可能增加设备负载';

  @override
  String get maxHistory => '最大历史记录数';

  @override
  String maxHistoryDesc(int min, int max) {
    return '保存的最大传输记录数量（$min-$max）';
  }

  @override
  String maxHistoryHintText(int min, int max) {
    return '输入数量 ($min-$max)';
  }

  @override
  String get oldRecordsAutoDelete => '超过设置数量的旧记录将被自动删除，只保留最新的记录';

  @override
  String get maxClipboard => '最大剪切板大小';

  @override
  String maxClipboardDesc(int min, int max) {
    return '允许同步的最大剪切板大小（$min-$max MB）';
  }

  @override
  String maxClipboardHintText(int min, int max) {
    return '输入大小 ($min-$max MB)';
  }

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
  String get targetDevicePort => '目标设备端口';

  @override
  String resetToDefaultPort(int port) {
    return '重置为默认端口 ($port)';
  }

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
  String get localIP => '本机IP';

  @override
  String ipCopied(String ip) {
    return 'IP地址已复制: $ip';
  }

  @override
  String get transferred => '已传输';

  @override
  String get transferSpeed => '传输速度';

  @override
  String get remainingTime => '剩余时间';

  @override
  String transferringProgress(double progress) {
    final intl.NumberFormat progressNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String progressString = progressNumberFormat.format(progress);

    return '传输中 $progressString%';
  }

  @override
  String get storagePermissionMessage => '需要存储权限才能选择文件。请在设置中手动开启权限。';

  @override
  String get checkingTargetDevice => '正在检查目标设备...';

  @override
  String get targetDeviceUnavailable => '目标设备不可用';

  @override
  String targetDeviceError(String error) {
    return '目标设备不可用\n错误: $error';
  }

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
  String transfersCount(int count) {
    return '$count 次传输';
  }

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
  String deleteRecordMessage(String fileName) {
    return '确定要删除 \"$fileName\" 的传输记录吗？\n\n注意：这只会删除记录，不会删除文件本身。';
  }

  @override
  String get deleteRecordNote => '注意：这只会删除记录，不会删除文件本身。';

  @override
  String get recordDeleted => '记录已删除';

  @override
  String get filePathNotExist => '文件路径不存在';

  @override
  String get cannotOpenFile => '无法打开文件';

  @override
  String cannotOpenFileWithMessage(String message) {
    return '无法打开文件: $message';
  }

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

  @override
  String get clipboardRequest => '剪切板请求';

  @override
  String clipboardRequestFrom(String deviceName) {
    return '设备 \"$deviceName\" 请求获取您的剪切板内容';
  }

  @override
  String get allowClipboardRequest => '是否允许？';

  @override
  String get clipboardRequestMessage => '剪切板请求';

  @override
  String autoRejectIn(int seconds) {
    return '$seconds 秒后自动拒绝';
  }

  @override
  String get reject => '拒绝';

  @override
  String get allow => '允许';

  @override
  String clipboardSharedWithSecretKey(String deviceName) {
    return '$deviceName 使用秘钥验证通过，自动分享剪切板';
  }

  @override
  String get clipboardRequestRejected => '用户拒绝了剪切板请求';

  @override
  String get clipboardEmpty => '剪切板为空';

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

    return '剪切板内容过大 ($actualSizeMBString MB)，超过对方设备的限制 ($maxSizeMB MB)。建议使用文件传输功能。';
  }

  @override
  String get clipboardContentSuccess => '成功获取剪切板内容';

  @override
  String get invalidJsonFormat => '无效的JSON格式';

  @override
  String get serverInternalError => '服务器内部错误';

  @override
  String get backgroundRejectNeedsSecretKey =>
      '设备处于后台，仅支持密钥自动同步/接收。请打开应用或配置匹配的设备密钥。';

  @override
  String get foregroundServiceNotificationTitle => 'IcyEasySend';

  @override
  String get foregroundServiceNotificationText => '正在后台等待文件传输与剪切板同步';

  @override
  String get androidBackgroundReceiveHint =>
      '后台时仅密钥匹配的设备可自动同步剪切板或发送文件，请保留通知栏常驻服务。';

  @override
  String get clipboardOverlay => '剪切板悬浮窗';

  @override
  String get clipboardOverlayDesc => '点击悬浮窗可刷新可同步的文本/图片缓存，便于后台同步';

  @override
  String get clipboardOverlayHint => '后台只能同步上次刷新的内容。关闭开关会清空缓存并隐藏悬浮窗。';

  @override
  String get clipboardOverlayPermissionNeeded =>
      '请在系统设置中允许「显示在其他应用上层」，返回后悬浮窗将自动显示';

  @override
  String get clipboardOverlayEnabledToast => '剪切板悬浮窗已开启';

  @override
  String get clipboardBackgroundCacheMiss =>
      '后台无法读取系统剪切板，且无可用缓存。请打开应用或点击悬浮窗刷新后再同步。';

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
  String clipboardRequestError(String error) {
    return '请求剪切板时发生错误: $error';
  }

  @override
  String invalidFilesMessage(String fileNames) {
    return '以下文件无效或无法访问:\n$fileNames';
  }

  @override
  String get waitingForReceiverConfirmation => '等待接收方确认...';

  @override
  String get fileSendSuccess => '文件发送成功！';

  @override
  String filesSendSuccess(int count) {
    return '发送 $count 个文件发送成功！';
  }

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
  ) {
    return '成功: $successCount 个文件\n失败: $failureCount 个文件\n\n失败的文件:\n$failedFiles';
  }

  @override
  String get preparingTransferInfo => '准备传输信息...';

  @override
  String waitingForReceiverConfirmFiles(int count) {
    return '等待接收方确认 $count 个文件...';
  }

  @override
  String transferringFile(int current, int total, String fileName) {
    return '正在传输文件 $current/$total: $fileName';
  }

  @override
  String get receiverRejected => '接收方拒绝接收';

  @override
  String receiverRejectedWithStatus(int statusCode) {
    return '接收方拒绝接收\n状态码: $statusCode';
  }

  @override
  String get transferIdNotFound => '未找到传输ID';

  @override
  String get waitingForConfirmation => '等待确认...';

  @override
  String get preparingToReceive => '准备接收...';

  @override
  String get rejected => '已拒绝';

  @override
  String get receiveComplete => '接收完成';

  @override
  String receivingProgress(double progress) {
    final intl.NumberFormat progressNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String progressString = progressNumberFormat.format(progress);

    return '接收中... $progressString%';
  }

  @override
  String receivingFiles(int count) {
    return '正在接收 $count 个文件';
  }

  @override
  String receiveFilesCount(int count) {
    return '接收 $count 个文件';
  }

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
  String autoRejectCountdown(int seconds) {
    return '是否接收这些文件？($seconds 秒后自动拒绝)';
  }

  @override
  String get rejectAll => '全部拒绝';

  @override
  String get acceptAll => '全部接受';

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
  String get diskFullTitle => '磁盘空间不足';

  @override
  String get storageCheckFailed => '无法检查存储空间';

  @override
  String get networkPermissionDenied => '需要网络访问权限才能传输文件';

  @override
  String get storagePermissionDenied => '需要存储访问权限才能保存文件';

  @override
  String serverStartFailed(String reason) {
    return '无法启动服务器：$reason';
  }

  @override
  String get serverPortsOccupied => '无法启动服务器：所有端口都已被占用';

  @override
  String serverPortsOccupiedRange(int defaultPort, int maxPort) {
    return '无法启动服务器：端口 $defaultPort-$maxPort 都已被占用';
  }

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
  ) {
    return '⚠️ 网段不匹配\n本机IP: $localIP (网段: $localNetwork.x)\n目标IP: $targetIP (网段: $targetNetwork.x)\n\n提示：两台设备需要在同一个局域网（相同网段）才能传输文件。\nC类IPv4地址应该保证两个IP地址的前三个数字相同，例如都是192.169.2，只是最后一个数字不同\n最简单的方法就是让两个设备都连接同一个WiFi或路由器。\n';
  }

  @override
  String get responseParseError => '无法解析服务器响应';

  @override
  String get responseInvalidFormat => '目标设备响应格式不正确';

  @override
  String responseStatusCodeError(int statusCode) {
    return '服务器返回错误状态码: $statusCode';
  }

  @override
  String get fileSelectionError => '选择文件时出错';

  @override
  String get fileSelectionCancelled => '已取消选择文件';

  @override
  String genericError(String operation) {
    return '$operation失败';
  }

  @override
  String unexpectedError(String details) {
    return '发生意外错误: $details';
  }

  @override
  String networkError(String context) {
    return '网络错误: $context';
  }

  @override
  String fileError(String context) {
    return '文件错误: $context';
  }

  @override
  String permissionError(String permissionType) {
    return '需要$permissionType权限才能继续操作';
  }

  @override
  String get foregroundServiceChannelName => '后台传输服务';

  @override
  String get foregroundServiceChannelDescription => '保持应用在后台可接收局域网文件与剪切板请求';

  @override
  String get peerUnreachable => '无法连接到目标设备';

  @override
  String get peerUnreachableBoth => '无法访问该设备（局域网与中转均不可达）';

  @override
  String get peerUnsupported => '对方版本过旧，不支持设备配对';

  @override
  String get identityMismatch => '对方设备码与公钥不匹配，已中止配对';

  @override
  String get cannotPairSelf => '不能与本机配对';

  @override
  String get pairingTitle => '设备配对';

  @override
  String get compareHint => '请确认两台设备显示的数字完全相同，再点击确认。数字不同说明连接可能被篡改。';

  @override
  String get compareHintRelay =>
      '这台设备不在同一局域网。请通过电话或语音与对方核对这 6 位数字，完全一致才能确认。不核对就确认等于没有任何保护。';

  @override
  String get pairOverRelay => '通过中转配对';

  @override
  String get enterDeviceCode => '输入对方的 32 位设备码';

  @override
  String get invalidDeviceCode => '设备码应为 32 位十六进制字符';

  @override
  String get alreadyPaired => '该设备已在信任列表中';

  @override
  String get peerAlreadyPaired => '对方已信任过本机，请先在对方设备上取消配对';

  @override
  String get relayUnavailable => '需要先连接中转服务器';

  @override
  String get peerBusy => '对方正在处理另一个配对请求';

  @override
  String get peerPairingBlocked => '对方已将本机加入黑名单，请联系对方移出后再试';

  @override
  String get peerRelayPairingOff => '对方已关闭通过中转接收配对请求';

  @override
  String incomingRequest(String deviceName) {
    return '「$deviceName」请求与本机配对';
  }

  @override
  String outgoingRequest(String deviceName) {
    return '正在与「$deviceName」配对';
  }

  @override
  String get waitingPeer => '等待对方确认…';

  @override
  String get peerAccepted => '对方已确认';

  @override
  String get peerRejected => '对方拒绝了本次配对';

  @override
  String get peerTimeout => '对方未在规定时间内确认';

  @override
  String get pairingFailed => '配对失败';

  @override
  String pairingSucceeded(String deviceName) {
    return '已与「$deviceName」完成配对';
  }

  @override
  String get codesMatch => '数字一致，确认配对';

  @override
  String get codesDiffer => '不一致，取消';

  @override
  String get blockPeer => '拉黑';

  @override
  String get pairingBlocklistTitle => '配对黑名单';

  @override
  String get pairingBlocklistEmpty => '黑名单为空';

  @override
  String get pairingBlocklistManage => '黑名单';

  @override
  String get unblockPeer => '移出黑名单';

  @override
  String unblockPeerConfirm(String name) {
    return '确定将「$name」移出黑名单？移出后对方可再次发起配对。';
  }

  @override
  String get pairedDevicesTitle => '已配对设备';

  @override
  String get pairedDevicesEmpty => '还没有已配对的设备';

  @override
  String get addPairedDevice => '配对新设备';

  @override
  String get unpair => '取消配对';

  @override
  String unpairConfirm(String deviceName) {
    return '移除「$deviceName」后，需要重新核对数字才能恢复信任。确定要移除吗？';
  }

  @override
  String get deviceCodeLabel => '本机设备码';

  @override
  String get title => '中转服务器';

  @override
  String get description => '不在同一局域网时，通过你自建的服务器转发文件。局域网可用时始终优先直连。';

  @override
  String get encryptionNotice => '文件在两台设备之间端到端加密，只有已配对的设备能解密。服务器只能看到传输时间和字节数。';

  @override
  String get acceptPairingLabel => '允许通过中转接收配对请求';

  @override
  String get acceptPairingHint => '任何持有服务器令牌的设备都能向你的设备码发起配对请求。被你拒绝过的设备不会再次弹窗。';

  @override
  String get iosForegroundNotice => '在 iOS 上仅在应用打开时可以通过中转接收文件。';

  @override
  String get enableLabel => '启用中转';

  @override
  String get serverUrlLabel => '服务器地址';

  @override
  String get tokenLabel => '接入令牌';

  @override
  String get invalidUrl => '地址需要以 http:// 或 https:// 开头';

  @override
  String get insecureUrlWarning => '使用 http:// 时流量不加密，仅适合本机调试';

  @override
  String get testConnection => '测试连接';

  @override
  String get testSucceeded => '连接成功';

  @override
  String get save => '保存';

  @override
  String get statusDisabled => '未启用';

  @override
  String get statusConnecting => '连接中';

  @override
  String get statusConnected => '已连接';

  @override
  String get statusReconnecting => '正在重连';

  @override
  String get statusRejected => '被服务器拒绝';

  @override
  String get clipboardNeedsPairing => '需要先与对方设备配对';

  @override
  String get clipboardRelayUnavailable => '未连接到中转服务器';

  @override
  String get clipboardPeerOffline => '对方设备当前不在中转服务器上';

  @override
  String get clipboardFailed => '通过中转同步剪切板失败';

  @override
  String get clipboardPeerNoUi => '对方设备当前无法确认请求';

  @override
  String get clipboardPeerBusy => '对方设备正忙，请稍后再试';

  @override
  String get clipboardTooLargeForRelay => '剪切板内容超过设置的大小上限';

  @override
  String get clipboardStreamFailed => '通过中转拉取剪切板数据失败';

  @override
  String get clipboardPeerTimeout => '对方没有响应剪切板请求';

  @override
  String get clipboardDeclined => '对方拒绝了剪切板请求';

  @override
  String selectedRelayPeer(String name) {
    return '已选择中转设备：$name';
  }

  @override
  String get clearSelectedPeer => '清除选择';

  @override
  String get lanRouteUnavailable => '无法通过局域网访问该设备';

  @override
  String get relayRouteUnavailable => '无法通过中转服务器访问该设备';

  @override
  String get relayNotConnected => '未连接到中转服务器';

  @override
  String get relayPeerOffline => '对方设备需要打开应用才能通过中转接收';

  @override
  String get relayPeerNotPaired => '对方设备没有把本设备加入信任列表';

  @override
  String get relayPeerBusy => '对方正在处理另一批文件';

  @override
  String get relayNeedsPairedDevice => '中转传输需要先与该设备配对';

  @override
  String get relayNegotiatingSession => '正在与对方建立加密会话…';

  @override
  String get relayIdentityMismatch => '对方设备的身份签名无效，可能不是已配对的设备';

  @override
  String get relayTransferNotice => '正在通过中转服务器传输，速度受服务器带宽限制';

  @override
  String retryingAfterInterruption(int attempt, int maxAttempts) {
    return '连接中断，正在重试（$attempt/$maxAttempts）…';
  }
}

/// The translations for Chinese, as used in Hong Kong (`zh_HK`).
class AppLocalizationsZhHk extends AppLocalizationsZh {
  AppLocalizationsZhHk() : super('zh_HK');

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
  String filesSelected(int count) {
    return '已選擇 $count 個檔案';
  }

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
  String scanProgress(int scanned, int total, int found) {
    return '已掃描 $scanned/$total，發現 $found 台裝置';
  }

  @override
  String get noDevicesFound => '未發現裝置';

  @override
  String get noDevicesFoundHint => '請確認目標裝置已啟動服務且在同一區域網路內，並檢查路由器的 AP 隔離和防火牆設定。';

  @override
  String scanDevicesFound(int count) {
    return '發現 $count 台裝置';
  }

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
  String folderFilesAdded(int count) {
    return '已從資料夾添加 $count 個檔案';
  }

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
  String filesCount(int count) {
    return '傳送 $count 個檔案';
  }

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
  String webShareFilesSummary(int count, String size) {
    return '$count 個檔案 · $size';
  }

  @override
  String webShareExpiresIn(String time) {
    return '剩餘有效時間 $time';
  }

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
  String filesAdded(int count) {
    return '已新增 $count 個分享的檔案';
  }

  @override
  String get preparingSend => '準備傳送...';

  @override
  String get transferring => '傳輸中';

  @override
  String transferProgress(int current, int total, String fileName) {
    return '[$current/$total] $fileName: 傳輸中...';
  }

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
  String ipDeleted(String ip) {
    return '已刪除 IP: $ip';
  }

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
  String resetDeviceNameConfirm(String model) {
    return '確定要將裝置名稱重設為 \"$model\" 嗎？';
  }

  @override
  String get reset => '重設';

  @override
  String get confirmChange => '確認修改';

  @override
  String concurrentTransfersIncrease(int from, int to) {
    return '確定要將並行傳輸數量從 $from 修改為 $to 嗎？\n\n提示：增加並行數可能會提高傳輸速度，但也會增加裝置負載';
  }

  @override
  String concurrentTransfersDecrease(int from, int to) {
    return '確定要將並行傳輸數量從 $from 修改為 $to 嗎？\n\n提示：降低並行數可以減少裝置負載，但可能會降低傳輸速度';
  }

  @override
  String get concurrentTransfersHint => '並行傳輸提示';

  @override
  String get concurrentTransfersSaved => '並行傳輸數量已儲存';

  @override
  String get enterValidNumber => '請輸入有效的數字';

  @override
  String historyCountRange(int min, int max) {
    return '歷史記錄數量範圍: $min-$max';
  }

  @override
  String maxHistoryChange(int from, int to) {
    return '確定要將最大歷史記錄數從 $from 修改為 $to 嗎？\n\n';
  }

  @override
  String currentHistoryCount(int count) {
    return '目前歷史記錄數: $count 條\n\n';
  }

  @override
  String get historyWarning => '⚠️ 警告：目前儲存的歷史記錄數大於設定的數量。\n\n';

  @override
  String historyDeleteWarning(int current, int max, int toDelete) {
    return '只會保留最新的 $max 條記錄，超過的 $toDelete 條舊記錄將被刪除。';
  }

  @override
  String get historyHint => '提示：新的設定將在下次儲存歷史記錄時生效。';

  @override
  String historyDeleted(int count) {
    return '設定已儲存，已刪除 $count 條舊記錄';
  }

  @override
  String get maxHistorySaved => '最大歷史記錄數已儲存';

  @override
  String clipboardSizeRange(int min, int max) {
    return '剪貼簿大小範圍: $min-$max MB';
  }

  @override
  String maxClipboardSizeChange(int from, int to) {
    return '確定要將最大剪貼簿大小從 $from MB 修改為 $to MB 嗎？\n\n';
  }

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
  String logCopied(int lines) {
    return '已複製最後$lines行日誌到剪貼簿';
  }

  @override
  String get logFileEmpty => '日誌檔案為空';

  @override
  String get devInfo => '開發資訊';

  @override
  String labelCopied(String label, String value) {
    return '$label已複製: $value';
  }

  @override
  String get transferSettings => '傳輸設定';

  @override
  String get concurrentTransfers => '並行傳輸數量';

  @override
  String concurrentTransfersDesc(int max) {
    return '同時傳輸的檔案數量（1-$max）';
  }

  @override
  String get concurrentTransfersHintText => '較高的並行數可以更好地利用頻寬，但可能增加裝置負載';

  @override
  String get maxHistory => '最大歷史記錄數';

  @override
  String maxHistoryDesc(int min, int max) {
    return '儲存的最大傳輸記錄數量（$min-$max）';
  }

  @override
  String maxHistoryHintText(int min, int max) {
    return '輸入數量 ($min-$max)';
  }

  @override
  String get oldRecordsAutoDelete => '超過設定數量的舊記錄將被自動刪除，只保留最新的記錄';

  @override
  String get maxClipboard => '最大剪貼簿大小';

  @override
  String maxClipboardDesc(int min, int max) {
    return '允許同步的最大剪貼簿大小（$min-$max MB）';
  }

  @override
  String maxClipboardHintText(int min, int max) {
    return '輸入大小 ($min-$max MB)';
  }

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
  String get targetDevicePort => '目標裝置連接埠';

  @override
  String resetToDefaultPort(int port) {
    return '重設為預設連接埠 ($port)';
  }

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
  String get localIP => '本機IP';

  @override
  String ipCopied(String ip) {
    return 'IP位址已複製: $ip';
  }

  @override
  String get transferred => '已傳輸';

  @override
  String get transferSpeed => '傳輸速度';

  @override
  String get remainingTime => '剩餘時間';

  @override
  String transferringProgress(double progress) {
    final intl.NumberFormat progressNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String progressString = progressNumberFormat.format(progress);

    return '傳輸中 $progressString%';
  }

  @override
  String get storagePermissionMessage => '需要儲存權限才能選擇檔案。請在設定中手動開啟權限。';

  @override
  String get checkingTargetDevice => '正在檢查目標裝置...';

  @override
  String get targetDeviceUnavailable => '目標裝置不可用';

  @override
  String targetDeviceError(String error) {
    return '目標裝置不可用\n錯誤: $error';
  }

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
  String transfersCount(int count) {
    return '$count 次傳輸';
  }

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
  String deleteRecordMessage(String fileName) {
    return '確定要刪除 \"$fileName\" 的傳輸記錄嗎？\n\n注意：這只會刪除記錄，不會刪除檔案本身。';
  }

  @override
  String get deleteRecordNote => '注意：這只會刪除記錄，不會刪除檔案本身。';

  @override
  String get recordDeleted => '記錄已刪除';

  @override
  String get filePathNotExist => '檔案路徑不存在';

  @override
  String get cannotOpenFile => '無法開啟檔案';

  @override
  String cannotOpenFileWithMessage(String message) {
    return '無法開啟檔案: $message';
  }

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

  @override
  String get clipboardRequest => '剪貼簿請求';

  @override
  String clipboardRequestFrom(String deviceName) {
    return '裝置 \"$deviceName\" 請求取得您的剪貼簿內容';
  }

  @override
  String get allowClipboardRequest => '是否允許？';

  @override
  String get clipboardRequestMessage => '剪貼簿請求';

  @override
  String autoRejectIn(int seconds) {
    return '$seconds 秒後自動拒絕';
  }

  @override
  String get reject => '拒絕';

  @override
  String get allow => '允許';

  @override
  String clipboardSharedWithSecretKey(String deviceName) {
    return '$deviceName 使用密鑰驗證通過，自動分享剪貼簿';
  }

  @override
  String get clipboardRequestRejected => '使用者拒絕了剪貼簿請求';

  @override
  String get clipboardEmpty => '剪貼簿為空';

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

    return '剪貼簿內容過大 ($actualSizeMBString MB)，超過對方裝置的限制 ($maxSizeMB MB)。建議使用檔案傳輸功能。';
  }

  @override
  String get clipboardContentSuccess => '成功取得剪貼簿內容';

  @override
  String get invalidJsonFormat => '無效的JSON格式';

  @override
  String get serverInternalError => '伺服器內部錯誤';

  @override
  String get backgroundRejectNeedsSecretKey =>
      '裝置處於背景，僅支援密鑰自動同步/接收。請打開應用程式或設定相符的裝置密鑰。';

  @override
  String get foregroundServiceNotificationTitle => 'IcyEasySend';

  @override
  String get foregroundServiceNotificationText => '正在背景等待檔案傳輸與剪貼簿同步';

  @override
  String get androidBackgroundReceiveHint =>
      '背景時僅密鑰相符的裝置可自動同步剪貼簿或傳送檔案，請保留通知列常駐服務。';

  @override
  String get clipboardOverlay => '剪貼簿懸浮窗';

  @override
  String get clipboardOverlayDesc => '點擊懸浮窗可重新整理可同步的文字/圖片快取，方便背景同步';

  @override
  String get clipboardOverlayHint => '背景只能同步上次重新整理的內容。關閉開關會清空快取並隱藏懸浮窗。';

  @override
  String get clipboardOverlayPermissionNeeded =>
      '請在系統設定中允許「顯示在其他應用程式上層」，返回後懸浮窗將自動顯示';

  @override
  String get clipboardOverlayEnabledToast => '剪貼簿懸浮窗已開啟';

  @override
  String get clipboardBackgroundCacheMiss =>
      '背景無法讀取系統剪貼簿，且無可用快取。請打開應用程式或點擊懸浮窗重新整理後再同步。';

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
  String clipboardRequestError(String error) {
    return '請求剪貼簿時發生錯誤: $error';
  }

  @override
  String invalidFilesMessage(String fileNames) {
    return '以下檔案無效或無法存取:\n$fileNames';
  }

  @override
  String get waitingForReceiverConfirmation => '等待接收方確認...';

  @override
  String get fileSendSuccess => '檔案傳送成功！';

  @override
  String filesSendSuccess(int count) {
    return '傳送 $count 個檔案傳送成功！';
  }

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
  ) {
    return '成功: $successCount 個檔案\n失敗: $failureCount 個檔案\n\n失敗的檔案:\n$failedFiles';
  }

  @override
  String get preparingTransferInfo => '準備傳輸資訊...';

  @override
  String waitingForReceiverConfirmFiles(int count) {
    return '等待接收方確認 $count 個檔案...';
  }

  @override
  String transferringFile(int current, int total, String fileName) {
    return '正在傳輸檔案 $current/$total: $fileName';
  }

  @override
  String get receiverRejected => '接收方拒絕接收';

  @override
  String receiverRejectedWithStatus(int statusCode) {
    return '接收方拒絕接收\n狀態碼: $statusCode';
  }

  @override
  String get transferIdNotFound => '未找到傳輸ID';

  @override
  String get waitingForConfirmation => '等待確認...';

  @override
  String get preparingToReceive => '準備接收...';

  @override
  String get rejected => '已拒絕';

  @override
  String get receiveComplete => '接收完成';

  @override
  String receivingProgress(double progress) {
    final intl.NumberFormat progressNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String progressString = progressNumberFormat.format(progress);

    return '接收中... $progressString%';
  }

  @override
  String receivingFiles(int count) {
    return '正在接收 $count 個檔案';
  }

  @override
  String receiveFilesCount(int count) {
    return '接收 $count 個檔案';
  }

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
  String autoRejectCountdown(int seconds) {
    return '是否接收這些檔案？($seconds 秒後自動拒絕)';
  }

  @override
  String get rejectAll => '全部拒絕';

  @override
  String get acceptAll => '全部接受';

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
  String get diskFullTitle => '磁碟空間不足';

  @override
  String get storageCheckFailed => '無法檢查儲存空間';

  @override
  String get networkPermissionDenied => '需要網路存取權限才能傳輸檔案';

  @override
  String get storagePermissionDenied => '需要儲存存取權限才能儲存檔案';

  @override
  String serverStartFailed(String reason) {
    return '無法啟動伺服器：$reason';
  }

  @override
  String get serverPortsOccupied => '無法啟動伺服器：所有連接埠都已被佔用';

  @override
  String serverPortsOccupiedRange(int defaultPort, int maxPort) {
    return '無法啟動伺服器：連接埠 $defaultPort-$maxPort 都已被佔用';
  }

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
  ) {
    return '⚠️ 網段不符\n本機IP: $localIP (網段: $localNetwork.x)\n目標IP: $targetIP (網段: $targetNetwork.x)\n\n提示：兩台裝置需要在同一個區域網路（相同網段）才能傳輸檔案。\nC類IPv4位址應該保證兩個IP位址的前三個數字相同，例如都是192.169.2，只是最後一個數字不同\n最簡單的方法就是讓兩個裝置都連線同一個WiFi或路由器。\n';
  }

  @override
  String get responseParseError => '無法解析伺服器回應';

  @override
  String get responseInvalidFormat => '目標裝置回應格式不正確';

  @override
  String responseStatusCodeError(int statusCode) {
    return '伺服器傳回錯誤狀態碼: $statusCode';
  }

  @override
  String get fileSelectionError => '選擇檔案時出錯';

  @override
  String get fileSelectionCancelled => '已取消選擇檔案';

  @override
  String genericError(String operation) {
    return '$operation失敗';
  }

  @override
  String unexpectedError(String details) {
    return '發生意外錯誤: $details';
  }

  @override
  String networkError(String context) {
    return '網路錯誤: $context';
  }

  @override
  String fileError(String context) {
    return '檔案錯誤: $context';
  }

  @override
  String permissionError(String permissionType) {
    return '需要$permissionType權限才能繼續操作';
  }

  @override
  String get foregroundServiceChannelName => '背景傳輸服務';

  @override
  String get foregroundServiceChannelDescription => '保持應用程式在背景可接收區域網路檔案與剪貼簿請求';

  @override
  String get peerUnreachable => '無法連線到目標裝置';

  @override
  String get peerUnreachableBoth => '無法存取該裝置（區域網路與中轉均不可達）';

  @override
  String get peerUnsupported => '對方版本過舊，不支援裝置配對';

  @override
  String get identityMismatch => '對方裝置碼與公鑰不相符，已中止配對';

  @override
  String get cannotPairSelf => '不能與本機配對';

  @override
  String get pairingTitle => '裝置配對';

  @override
  String get compareHint => '請確認兩台裝置顯示的數字完全相同再確認。數字不同代表連線可能遭到竄改。';

  @override
  String get compareHintRelay =>
      '這台裝置不在同一區域網路。請透過電話或語音與對方核對這 6 位數字，完全一致才可確認。不核對就確認等於沒有任何保護。';

  @override
  String get pairOverRelay => '透過中轉配對';

  @override
  String get enterDeviceCode => '輸入對方的 32 位裝置碼';

  @override
  String get invalidDeviceCode => '裝置碼應為 32 位十六進位字元';

  @override
  String get alreadyPaired => '該裝置已在信任清單中';

  @override
  String get peerAlreadyPaired =>
      'The other device still trusts this one; unpair on that device first';

  @override
  String get relayUnavailable => '需要先連線中轉伺服器';

  @override
  String get peerBusy => '對方正在處理另一個配對要求';

  @override
  String get peerPairingBlocked =>
      'The other device has blocked this one; ask them to unblock it first';

  @override
  String get peerRelayPairingOff => '對方已關閉透過中轉接收配對要求';

  @override
  String incomingRequest(String deviceName) {
    return '「$deviceName」要求與本機配對';
  }

  @override
  String outgoingRequest(String deviceName) {
    return '正在與「$deviceName」配對';
  }

  @override
  String get waitingPeer => '等待對方確認…';

  @override
  String get peerAccepted => '對方已確認';

  @override
  String get peerRejected => '對方拒絕了這次配對';

  @override
  String get peerTimeout => '對方未在時限內確認';

  @override
  String get pairingFailed => '配對失敗';

  @override
  String pairingSucceeded(String deviceName) {
    return '已與「$deviceName」完成配對';
  }

  @override
  String get codesMatch => '數字相同，確認配對';

  @override
  String get codesDiffer => '不相同，取消';

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
  String get pairedDevicesTitle => '已配對裝置';

  @override
  String get pairedDevicesEmpty => '尚未配對任何裝置';

  @override
  String get addPairedDevice => '配對新裝置';

  @override
  String get unpair => '取消配對';

  @override
  String unpairConfirm(String deviceName) {
    return '移除「$deviceName」後，需要重新核對數字才能恢復信任。確定要移除嗎？';
  }

  @override
  String get deviceCodeLabel => '本機裝置碼';

  @override
  String get title => '中轉伺服器';

  @override
  String get description => '不在同一區域網路時，透過你自建的伺服器轉發檔案。區域網路可用時一律優先直連。';

  @override
  String get encryptionNotice => '檔案在兩台裝置之間端對端加密，只有已配對的裝置能解密。伺服器只能看到傳輸時間與位元組數。';

  @override
  String get acceptPairingLabel => '允許透過中轉接收配對要求';

  @override
  String get acceptPairingHint =>
      '任何持有伺服器權杖的裝置都能向你的裝置碼發起配對要求。被你拒絕過的裝置不會再次彈出視窗。';

  @override
  String get iosForegroundNotice => '在 iOS 上僅在應用程式開啟時可以透過中轉接收檔案。';

  @override
  String get enableLabel => '啟用中轉';

  @override
  String get serverUrlLabel => '伺服器位址';

  @override
  String get tokenLabel => '接入權杖';

  @override
  String get invalidUrl => '位址需要以 http:// 或 https:// 開頭';

  @override
  String get insecureUrlWarning => '使用 http:// 時流量不加密，僅適合本機除錯';

  @override
  String get testConnection => '測試連線';

  @override
  String get testSucceeded => '連線成功';

  @override
  String get save => '儲存';

  @override
  String get statusDisabled => '未啟用';

  @override
  String get statusConnecting => '連線中';

  @override
  String get statusConnected => '已連線';

  @override
  String get statusReconnecting => '正在重新連線';

  @override
  String get statusRejected => '被伺服器拒絕';

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
  String get lanRouteUnavailable => '無法透過區域網路存取該裝置';

  @override
  String get relayRouteUnavailable => '無法透過中轉伺服器存取該裝置';

  @override
  String get relayNotConnected => '未連線到中轉伺服器';

  @override
  String get relayPeerOffline => '對方裝置需要開啟應用程式才能透過中轉接收';

  @override
  String get relayPeerNotPaired => '對方裝置沒有把本裝置加入信任清單';

  @override
  String get relayPeerBusy => '對方正在處理另一批檔案';

  @override
  String get relayNeedsPairedDevice => '中轉傳輸需要先與該裝置配對';

  @override
  String get relayNegotiatingSession => '正在與對方建立加密工作階段…';

  @override
  String get relayIdentityMismatch => '對方裝置的身分簽章無效，可能不是已配對的裝置';

  @override
  String get relayTransferNotice => '正在透過中轉伺服器傳輸，速度受伺服器頻寬限制';

  @override
  String retryingAfterInterruption(int attempt, int maxAttempts) {
    return '連線中斷，正在重試（$attempt/$maxAttempts）…';
  }
}
