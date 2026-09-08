// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'Icy Easy Send';

  @override
  String get appVersion => 'バージョン';

  @override
  String get navHome => 'ホーム';

  @override
  String get navHistory => '履歴';

  @override
  String get navSettings => '設定';

  @override
  String get homeTitle => 'ホーム';

  @override
  String get serverStatus => 'サーバーステータス';

  @override
  String get serverRunning => '実行中';

  @override
  String get serverStopped => '停止';

  @override
  String get serverAddress => 'サーバーアドレス';

  @override
  String get deviceName => 'デバイス名';

  @override
  String get storageSpace => 'ストレージ容量';

  @override
  String get availableSpace => '利用可能な容量';

  @override
  String get sendFiles => 'ファイルを送信';

  @override
  String get receiveFiles => 'ファイルを受信';

  @override
  String get selectFiles => 'ファイルを選択';

  @override
  String get selectFolder => 'フォルダを選択';

  @override
  String get dragDropHint => 'ここにファイルをドラッグ';

  @override
  String get noFilesSelected => 'ファイルが選択されていません';

  @override
  String filesSelected(int count) {
    return '$count個のファイルが選択されました';
  }

  @override
  String get clearSelection => '選択をクリア';

  @override
  String get startSending => '送信開始';

  @override
  String get sending => '送信中';

  @override
  String get sendSuccess => '送信成功';

  @override
  String get sendFailed => '送信失敗';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirm => '確認';

  @override
  String get historyTitle => '転送履歴';

  @override
  String get noHistory => '履歴がありません';

  @override
  String get clearHistory => '履歴をクリア';

  @override
  String get sent => '送信済み';

  @override
  String get received => '受信済み';

  @override
  String get failed => '失敗';

  @override
  String get fileSize => 'ファイルサイズ';

  @override
  String get time => '時間';

  @override
  String get deleteItem => '記録を削除';

  @override
  String get deleteItemConfirm => 'この記録を削除しますか？';

  @override
  String get openFile => 'ファイルを開く';

  @override
  String get openFolder => 'フォルダを開く';

  @override
  String get settingsTitle => '設定';

  @override
  String get general => '一般';

  @override
  String get language => '言語';

  @override
  String get deviceNameSetting => 'デバイス名';

  @override
  String get editDeviceName => 'デバイス名を変更';

  @override
  String get deviceNameHint => 'デバイス名を入力してください';

  @override
  String get deviceNameEmpty => 'デバイス名を空にすることはできません';

  @override
  String get port => 'ポート';

  @override
  String get portHint => 'ポート番号を入力してください';

  @override
  String get portInvalid => '無効なポート番号';

  @override
  String get portInUse => 'ポートは既に使用されています';

  @override
  String get savePath => '保存パス';

  @override
  String get selectSavePath => '保存パスを選択';

  @override
  String get savePathDesc => '受信したファイルはここに保存されます。既定ではシステムのダウンロードフォルダを使用します。';

  @override
  String get savePathDefaultBadge => '既定';

  @override
  String get savePathUnavailable => '保存パスを取得できません';

  @override
  String get savePathSavedSuccess => '保存パスの設定に成功しました';

  @override
  String get savePathNotWritable => 'このフォルダに書き込めません。別の場所を選ぶか、権限を確認してください。';

  @override
  String get resetSavePathToDefault => '既定のフォルダに戻す';

  @override
  String get savePathResetSuccess => 'システムのダウンロードフォルダに戻しました';

  @override
  String get autoStart => '自動起動';

  @override
  String get autoStartDesc => 'アプリ起動時にサーバーを自動実行';

  @override
  String get network => 'ネットワーク';

  @override
  String get networkDiagnostics => 'ネットワーク診断';

  @override
  String get scanDevices => 'デバイスをスキャン';

  @override
  String get scanDevicesTitle => 'LAN デバイスをスキャン';

  @override
  String get scanningDevices => 'ローカルネットワークをスキャン中...';

  @override
  String scanProgress(int scanned, int total, int found) {
    return 'スキャン $scanned/$total、$found 台を発見';
  }

  @override
  String get noDevicesFound => 'デバイスが見つかりません';

  @override
  String get noDevicesFoundHint =>
      '相手デバイスでサーバーが起動していること、同じネットワークに接続していることを確認してください。AP 分離やファイアウォール設定も確認してください。';

  @override
  String scanDevicesFound(int count) {
    return '$count 台のデバイスを発見';
  }

  @override
  String get rescan => '再スキャン';

  @override
  String get runDiagnostics => '診断を実行';

  @override
  String get about => '情報';

  @override
  String get version => 'バージョン';

  @override
  String get checkUpdate => 'アップデートを確認';

  @override
  String get feedback => 'フィードバック';

  @override
  String get openSource => 'オープンソースライセンス';

  @override
  String get license => 'ライセンス';

  @override
  String get permissionRequired => '権限が必要';

  @override
  String get permissionDenied => '権限が拒否されました';

  @override
  String get permissionPermanentlyDenied => '権限が永久に拒否されました';

  @override
  String get permissionStorage => 'ストレージ権限';

  @override
  String get permissionStorageDesc => 'ファイルを保存して読み取るにはストレージ権限が必要です';

  @override
  String get permissionNotification => '通知権限';

  @override
  String get permissionNotificationDesc => '転送の進行状況を表示するには通知権限が必要です';

  @override
  String get openSettings => '設定を開く';

  @override
  String get permissionWarning => '一部の権限が付与されていないため、一部の機能が制限される可能性があります';

  @override
  String get error => 'エラー';

  @override
  String get errorUnknown => '不明なエラー';

  @override
  String get errorNetwork => 'ネットワークエラー';

  @override
  String get errorFileNotFound => 'ファイルが見つかりません';

  @override
  String get errorPermission => '権限エラー';

  @override
  String get errorStorage => 'ストレージエラー';

  @override
  String get errorServer => 'サーバーエラー';

  @override
  String get errorServerStart => 'サーバーの起動に失敗';

  @override
  String get errorServerStop => 'サーバーの停止に失敗';

  @override
  String get errorConnection => '接続エラー';

  @override
  String get errorTimeout => '接続タイムアウト';

  @override
  String get retry => '再試行';

  @override
  String get copied => 'コピーしました';

  @override
  String get copyFailed => 'コピー失敗';

  @override
  String get saved => '保存しました';

  @override
  String get saveFailed => '保存失敗';

  @override
  String get deleted => '削除しました';

  @override
  String get deleteFailed => '削除失敗';

  @override
  String get loading => '読み込み中';

  @override
  String get success => '成功';

  @override
  String get warning => '警告';

  @override
  String get info => '情報';

  @override
  String get yes => 'はい';

  @override
  String get no => 'いいえ';

  @override
  String get ok => '確認';

  @override
  String get close => '閉じる';

  @override
  String get selectFilesFailed => 'ファイル選択に失敗';

  @override
  String get selectFolderFailed => 'フォルダ選択に失敗';

  @override
  String folderFilesAdded(int count) {
    return 'フォルダから $count 個のファイルを追加しました';
  }

  @override
  String get folderContainsNoFiles => '選択したフォルダに送信できるファイルがありません';

  @override
  String get openFileFailed => 'ファイルを開けません';

  @override
  String get openFolderFailed => 'フォルダを開けません';

  @override
  String get fileNotExist => 'ファイルが存在しません';

  @override
  String get folderNotExist => 'フォルダが存在しません';

  @override
  String get diagnosticsTitle => 'ネットワーク診断';

  @override
  String get diagnosticsRunning => '診断実行中...';

  @override
  String get diagnosticsComplete => '診断完了';

  @override
  String get diagnosticsFailed => '診断失敗';

  @override
  String get networkStatus => 'ネットワーク状態';

  @override
  String get wifiConnected => 'WiFi接続済み';

  @override
  String get wifiDisconnected => 'WiFi未接続';

  @override
  String get mobileData => 'モバイルデータ';

  @override
  String get noConnection => 'ネットワーク接続なし';

  @override
  String get ipAddress => 'IPアドレス';

  @override
  String get noIpAddress => 'IPアドレスなし';

  @override
  String get serverStatusCheck => 'サーバー状態確認';

  @override
  String get portCheck => 'ポート確認';

  @override
  String get portAvailable => 'ポート使用可能';

  @override
  String get portUnavailable => 'ポート使用不可';

  @override
  String get suggestions => '提案';

  @override
  String get syncClipboard => '相手のクリップボードを同期';

  @override
  String filesCount(int count) {
    return '$count個のファイルを送信';
  }

  @override
  String get sendFile => 'ファイルを送信';

  @override
  String get shareViaQr => 'QRコードで共有';

  @override
  String get webShareTitle => 'スキャンして受信';

  @override
  String get webShareHint =>
      '相手はシステムカメラでスキャンし、ブラウザからダウンロードできます（アプリ不要）。同じ Wi‑Fi / LAN に接続してください。一部のサードパーティスキャナーは LAN リンクを開けない場合があります。リンクをコピーして共有できます。';

  @override
  String get webShareCopyLink => 'リンクをコピー';

  @override
  String get webShareLinkCopied => 'リンクをコピーしました';

  @override
  String get webShareStopSharing => '共有を停止';

  @override
  String get webShareStopped => 'Web共有を停止しました';

  @override
  String get webShareServerRequired => 'QR共有の前にローカルサーバーを起動してください';

  @override
  String get webShareCreated => 'Web共有を作成しました。相手はスキャンしてダウンロードできます。';

  @override
  String get webShareFailed => 'Web共有の作成に失敗しました';

  @override
  String get webSharePeerName => 'Web共有';

  @override
  String webShareFilesSummary(int count, String size) {
    return '$count ファイル · $size';
  }

  @override
  String webShareExpiresIn(String time) {
    return '有効期限まで $time';
  }

  @override
  String get releaseToAdd => 'マウスを離してファイルを追加';

  @override
  String get serverNotRunning => 'サーバーが実行されていないため、共有ファイルを受信できません';

  @override
  String get cannotReceiveFiles => 'ファイルを受信できません';

  @override
  String get sendingInProgress => 'ファイル転送中です。後でもう一度お試しください';

  @override
  String get pleaseTryLater => '後でもう一度お試しください';

  @override
  String filesAdded(int count) {
    return '$count個の共有ファイルが追加されました';
  }

  @override
  String get preparingSend => '転送準備中...';

  @override
  String get transferring => '送信中';

  @override
  String transferProgress(int current, int total, String fileName) {
    return '[$current/$total] $fileName: 転送中...';
  }

  @override
  String get networkChanged => 'ネットワークが変更され、サーバーアドレスが更新されました';

  @override
  String get serverAddressUpdated => 'サーバーアドレスが更新されました';

  @override
  String get portCannotBeEmpty => 'ポートを空にすることはできません';

  @override
  String get portMustBeNumber => 'ポートは数字である必要があります';

  @override
  String get portRange => 'ポート範囲: 1-65535';

  @override
  String ipDeleted(String ip) {
    return 'IPを削除しました: $ip';
  }

  @override
  String get runningDiagnostics => 'ネットワーク診断実行中...';

  @override
  String get targetDeviceInfo => 'ターゲットデバイス情報';

  @override
  String get fullAddress => '完全なアドレス';

  @override
  String get targetNotSet => 'ターゲットデバイスが設定されていません';

  @override
  String get diagnosticsReport => 'ネットワーク診断レポート';

  @override
  String get reportCopied => '診断レポートがクリップボードにコピーされました';

  @override
  String get deviceNameCannotBeEmpty => 'デバイス名を空にすることはできません';

  @override
  String get deviceNameSaved => 'デバイス名が保存されました';

  @override
  String get resetDeviceName => 'デバイス名をリセット';

  @override
  String resetDeviceNameConfirm(String model) {
    return 'デバイス名を「$model」にリセットしますか？';
  }

  @override
  String get reset => 'リセット';

  @override
  String get confirmChange => '変更を確認';

  @override
  String concurrentTransfersIncrease(int from, int to) {
    return '同時転送数を$fromから$toに変更しますか？\n\nヒント: 同時転送数を増やすと転送速度が向上する可能性がありますが、デバイスの負荷が増加します';
  }

  @override
  String concurrentTransfersDecrease(int from, int to) {
    return '同時転送数を$fromから$toに変更しますか？\n\nヒント: 同時転送数を減らすとデバイスの負荷が減少しますが、転送速度が低下する可能性があります';
  }

  @override
  String get concurrentTransfersHint => '同時転送のヒント';

  @override
  String get concurrentTransfersSaved => '同時転送数が保存されました';

  @override
  String get enterValidNumber => '有効な数字を入力してください';

  @override
  String historyCountRange(int min, int max) {
    return '履歴数の範囲: $min-$max';
  }

  @override
  String maxHistoryChange(int from, int to) {
    return '最大履歴数を$fromから$toに変更しますか？\n\n';
  }

  @override
  String currentHistoryCount(int count) {
    return '現在の履歴数: $count件\n\n';
  }

  @override
  String get historyWarning => '⚠️ 警告: 現在保存されている履歴数が設定数を超えています。\n\n';

  @override
  String historyDeleteWarning(int current, int max, int toDelete) {
    return '最新の$max件の履歴のみが保持され、超過した$toDelete件の古い履歴は削除されます。';
  }

  @override
  String get historyHint => 'ヒント: 新しい設定は次回履歴を保存する際に適用されます。';

  @override
  String historyDeleted(int count) {
    return '設定が保存され、$count件の古い履歴が削除されました';
  }

  @override
  String get maxHistorySaved => '最大履歴数が保存されました';

  @override
  String clipboardSizeRange(int min, int max) {
    return 'クリップボードサイズの範囲: $min-$max MB';
  }

  @override
  String maxClipboardSizeChange(int from, int to) {
    return '最大クリップボードサイズを$from MBから$to MBに変更しますか？\n\n';
  }

  @override
  String get clipboardSizeDecreaseHint =>
      '⚠️ ヒント: 制限を下げると、制限を超えるクリップボードの内容は同期できません。ファイル転送機能の使用をお勧めします。';

  @override
  String get clipboardSizeIncreaseHint =>
      'ヒント: 制限を上げると、より大きなクリップボードの内容を同期できますが、転送速度に影響する可能性があります。';

  @override
  String get maxClipboardSizeSaved => '最大クリップボードサイズが保存されました';

  @override
  String get ipValidationEnabled => 'IPアドレス検証が有効になりました';

  @override
  String get ipValidationDisabled => 'IPアドレス検証が無効になりました';

  @override
  String get deviceSecretKeyCleared => 'デバイス秘密鍵がクリアされました';

  @override
  String get deviceSecretKeySaved => 'デバイス秘密鍵が保存されました';

  @override
  String get loadingDevInfo => '開発情報読み込み中...';

  @override
  String get copyLog => 'ログをコピー';

  @override
  String logCopied(int lines) {
    return '最後の$lines行のログがクリップボードにコピーされました';
  }

  @override
  String get logFileEmpty => 'ログファイルが空です';

  @override
  String get devInfo => '開発情報';

  @override
  String labelCopied(String label, String value) {
    return '$labelをコピーしました: $value';
  }

  @override
  String get transferSettings => '転送設定';

  @override
  String get concurrentTransfers => '同時転送数';

  @override
  String concurrentTransfersDesc(int max) {
    return '同時に転送するファイル数（1-$max）';
  }

  @override
  String get concurrentTransfersHintText =>
      '同時転送数を増やすと帯域幅をより有効活用できますが、デバイスの負荷が増加する可能性があります';

  @override
  String get maxHistory => '最大履歴数';

  @override
  String maxHistoryDesc(int min, int max) {
    return '保存する最大転送履歴数（$min-$max）';
  }

  @override
  String maxHistoryHintText(int min, int max) {
    return '数量を入力（$min-$max）';
  }

  @override
  String get oldRecordsAutoDelete => '設定数を超える古い履歴は自動的に削除され、最新の履歴のみが保持されます';

  @override
  String get maxClipboard => '最大クリップボードサイズ';

  @override
  String maxClipboardDesc(int min, int max) {
    return '同期可能な最大クリップボードサイズ（$min-$max MB）';
  }

  @override
  String maxClipboardHintText(int min, int max) {
    return 'サイズを入力（$min-$max MB）';
  }

  @override
  String get clipboardSyncLimit =>
      'このサイズを超えるクリップボードの内容は同期できません。ファイル転送機能の使用をお勧めします';

  @override
  String get ipValidation => 'IPアドレス検証';

  @override
  String get ipValidationDesc => 'ターゲットデバイスのIPが同じサブネットにあるか確認';

  @override
  String get ipValidationEnabledHint =>
      '有効にすると、ターゲットIPが同じサブネットにあるか確認し、誤ったデバイスへの接続を防ぎます';

  @override
  String get ipValidationDisabledHint =>
      '無効にすると、IPサブネットを確認せず、複雑なネットワーク環境（ホットスポット、VPNなど）に適しています';

  @override
  String get deviceSecretKey => 'このデバイスの秘密鍵';

  @override
  String get deviceSecretKeyDesc => '設定すると、他のデバイスが正しい秘密鍵を提供した場合に確認をスキップできます';

  @override
  String get deviceSecretKeyHint => '秘密鍵を入力（空欄の場合は秘密鍵を使用しません）';

  @override
  String get notSet => '設定されていません';

  @override
  String get author => '作成者';

  @override
  String get update => '更新';

  @override
  String get github => 'GitHub';

  @override
  String get githubLinkCopied => 'GitHubリンクをコピーしました';

  @override
  String get openGitHubFailed => 'ブラウザを開けませんでした。代わりにリンクをコピーしました';

  @override
  String get appDescription => 'シンプルで使いやすいローカルネットワークファイル転送ツール';

  @override
  String get targetDeviceIP => 'ターゲットデバイスのIPアドレス';

  @override
  String get ipHint => '例: 192.168.1.100';

  @override
  String get clear => 'クリア';

  @override
  String get history => '履歴';

  @override
  String get targetDevicePort => 'ターゲットデバイスのポート';

  @override
  String resetToDefaultPort(int port) {
    return 'デフォルトポートにリセット（$port）';
  }

  @override
  String get targetDeviceSecretKey => 'ターゲットデバイスの秘密鍵（オプション）';

  @override
  String get secretKeyHint => '正しい秘密鍵で相手の確認をスキップ';

  @override
  String get aboutSecretKey => '秘密鍵について';

  @override
  String get secretKeyFeatureTitle => '秘密鍵機能の説明';

  @override
  String get secretKeyFeatureDesc =>
      'ターゲットデバイスが秘密鍵を設定している場合、正しい秘密鍵を入力すると確認ダイアログをスキップして、ファイルを直接転送したりクリップボードを同期したりできます。';

  @override
  String get secretKeyUsageSteps => '使用手順:';

  @override
  String get secretKeyUsageStep1 => '1. ターゲットデバイスが設定ページでこのデバイスの秘密鍵を設定します';

  @override
  String get secretKeyUsageStep2 => '2. この入力欄にターゲットデバイスの秘密鍵を入力します';

  @override
  String get secretKeyUsageStep3 =>
      '3. ファイルを送信またはクリップボードをリクエストする際、秘密鍵が正しければ相手が自動的に承認します';

  @override
  String get secretKeyTip => 'ヒント: 空欄の場合は従来の手動確認方式を使用します';

  @override
  String get secretKeyDescription => '秘密鍵の説明';

  @override
  String get clearSecretKey => '秘密鍵をクリア';

  @override
  String get gotIt => '了解しました';

  @override
  String get localIP => 'このデバイスのIP';

  @override
  String ipCopied(String ip) {
    return 'IPアドレスをコピーしました: $ip';
  }

  @override
  String get transferred => '送信済み';

  @override
  String get transferSpeed => '転送速度';

  @override
  String get remainingTime => '残り時間';

  @override
  String transferringProgress(double progress) {
    final intl.NumberFormat progressNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String progressString = progressNumberFormat.format(progress);

    return '転送中 $progressString%';
  }

  @override
  String get storagePermissionMessage =>
      'ファイルを選択するにはストレージ権限が必要です。設定で手動で権限を有効にしてください。';

  @override
  String get checkingTargetDevice => 'ターゲットデバイス確認中...';

  @override
  String get targetDeviceUnavailable => 'ターゲットデバイスを使用できません';

  @override
  String targetDeviceError(String error) {
    return 'ターゲットデバイスを使用できません\nエラー: $error';
  }

  @override
  String get connectionFailed => '接続失敗';

  @override
  String get transferHistory => '転送履歴';

  @override
  String get clearHistoryTitle => '履歴をクリア';

  @override
  String get clearHistoryMessage => 'すべての転送履歴を削除しますか？この操作は取り消せません。';

  @override
  String get noFilteredRecords => '条件に一致する記録がありません';

  @override
  String get filterAll => 'すべて';

  @override
  String get filterSent => '送信済み';

  @override
  String get filterReceived => '受信済み';

  @override
  String get statisticsInfo => '統計情報';

  @override
  String transfersCount(int count) {
    return '$count回の転送';
  }

  @override
  String get totalTransfers => '総転送';

  @override
  String get successfulTransfers => '成功';

  @override
  String get failedTransfers => '失敗';

  @override
  String get sentFiles => '送信済み';

  @override
  String get receivedFiles => '受信済み';

  @override
  String get totalSize => '合計サイズ';

  @override
  String get moreActions => 'その他の操作';

  @override
  String get deleteRecord => '記録を削除';

  @override
  String get viewDetails => '詳細を表示';

  @override
  String get deleteRecordTitle => '記録を削除';

  @override
  String deleteRecordMessage(String fileName) {
    return '「$fileName」の転送履歴を削除しますか？\n\n注意: 履歴のみが削除され、ファイル自体は削除されません。';
  }

  @override
  String get deleteRecordNote => '注意: 履歴のみが削除され、ファイル自体は削除されません。';

  @override
  String get recordDeleted => '履歴が削除されました';

  @override
  String get filePathNotExist => 'ファイルパスが存在しません';

  @override
  String get cannotOpenFile => 'ファイルを開けません';

  @override
  String cannotOpenFileWithMessage(String message) {
    return 'ファイルを開けません: $message';
  }

  @override
  String get iosNoFolderSupport => 'iOSはフォルダを直接開くことができません';

  @override
  String get cannotOpenFolder => 'フォルダを開けません';

  @override
  String get recentFilesOpened => '最近のファイルが開かれました。手動で検索してください';

  @override
  String get receiveRecord => '受信記録';

  @override
  String get sendRecord => '転送履歴';

  @override
  String get fileName => 'ファイル名';

  @override
  String get fromDevice => '送信元デバイス';

  @override
  String get toDevice => '受信先デバイス';

  @override
  String get deviceIP => 'デバイスIP';

  @override
  String get transferTime => '転送時間';

  @override
  String get transferStatus => '転送状態';

  @override
  String get statusSuccess => '成功';

  @override
  String get statusFailed => '失敗';

  @override
  String get savedLocation => '保存場所';

  @override
  String get copy => 'コピー';

  @override
  String get pathCopied => 'パスがクリップボードにコピーされました';

  @override
  String get from => '送信者';

  @override
  String get sentTo => '受信者';

  @override
  String get clipboardRequest => 'クリップボードリクエスト';

  @override
  String clipboardRequestFrom(String deviceName) {
    return 'デバイス「$deviceName」がクリップボードの内容をリクエストしています';
  }

  @override
  String get allowClipboardRequest => '許可しますか？';

  @override
  String get clipboardRequestMessage => 'クリップボードリクエスト';

  @override
  String autoRejectIn(int seconds) {
    return '$seconds秒後に自動拒否';
  }

  @override
  String get reject => '拒否';

  @override
  String get allow => '許可';

  @override
  String clipboardSharedWithSecretKey(String deviceName) {
    return '$deviceNameが秘密鍵認証を通過し、クリップボードを自動的に共有します';
  }

  @override
  String get clipboardRequestRejected => 'ユーザーがクリップボードリクエストを拒否しました';

  @override
  String get clipboardEmpty => 'クリップボードが空です';

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

    return 'クリップボードの内容が大きすぎます（$actualSizeMBString MB）。相手デバイスの制限（$maxSizeMB MB）を超えています。ファイル転送機能の使用をお勧めします。';
  }

  @override
  String get clipboardContentSuccess => 'クリップボードの内容を正常に取得しました';

  @override
  String get invalidJsonFormat => '無効なJSON形式';

  @override
  String get serverInternalError => 'サーバー内部エラー';

  @override
  String get backgroundRejectNeedsSecretKey =>
      'デバイスはバックグラウンドです。一致する秘密鍵がある場合のみ自動同期/受信できます。';

  @override
  String get foregroundServiceNotificationTitle => 'IcyEasySend';

  @override
  String get foregroundServiceNotificationText =>
      'バックグラウンドでファイル転送とクリップボード同期を待機中';

  @override
  String get androidBackgroundReceiveHint =>
      'バックグラウンドでは一致する秘密鍵の端末のみ自動同期/送信できます。常駐通知を維持してください。';

  @override
  String get clipboardOverlay => 'クリップボードフローティングボタン';

  @override
  String get clipboardOverlayDesc =>
      'フローティングボタンをタップして、バックグラウンド同期用のテキスト/画像キャッシュを更新します';

  @override
  String get clipboardOverlayHint =>
      'バックグラウンドでは最後に更新した内容のみ同期できます。オフにするとキャッシュを消去しボタンを非表示にします。';

  @override
  String get clipboardOverlayPermissionNeeded =>
      'システム設定で「他のアプリの上に表示」を許可してください。戻るとフローティングボタンが表示されます。';

  @override
  String get clipboardOverlayEnabledToast => 'クリップボードフローティングボタンを有効にしました';

  @override
  String get clipboardBackgroundCacheMiss =>
      'バックグラウンドではシステムクリップボードを読めず、有効なキャッシュもありません。アプリを開くかフローティングボタンで更新してから同期してください。';

  @override
  String get requestingClipboard => 'クリップボードをリクエスト中...';

  @override
  String get clipboardSyncSuccess => 'クリップボード同期成功';

  @override
  String get textClipboardSyncSuccess => 'テキストクリップボード同期成功';

  @override
  String get fileClipboardSyncSuccess =>
      'ファイルクリップボード同期成功\nアプリまたはファイルマネージャーで貼り付けできます';

  @override
  String get clipboardSyncFailed => 'クリップボード同期失敗';

  @override
  String get syncFailed => '同期失敗';

  @override
  String clipboardRequestError(String error) {
    return 'クリップボードリクエスト中にエラーが発生しました: $error';
  }

  @override
  String invalidFilesMessage(String fileNames) {
    return '以下のファイルが無効またはアクセスできません:\n$fileNames';
  }

  @override
  String get waitingForReceiverConfirmation => '受信者の確認待ち...';

  @override
  String get fileSendSuccess => 'ファイル送信成功！';

  @override
  String filesSendSuccess(int count) {
    return '$count個のファイル送信成功！';
  }

  @override
  String get allFilesSendFailed => 'すべてのファイル送信に失敗';

  @override
  String get failedFiles => '失敗したファイル';

  @override
  String get transferComplete => '転送完了';

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
    return '成功: $successCount個のファイル\n失敗: $failureCount個のファイル\n\n失敗したファイル:\n$failedFiles';
  }

  @override
  String get preparingTransferInfo => '転送情報準備中...';

  @override
  String waitingForReceiverConfirmFiles(int count) {
    return '受信者が$count個のファイルを確認するのを待っています...';
  }

  @override
  String transferringFile(int current, int total, String fileName) {
    return 'ファイル転送中 $current/$total: $fileName';
  }

  @override
  String get receiverRejected => '受信者が拒否しました';

  @override
  String receiverRejectedWithStatus(int statusCode) {
    return '受信者が拒否しました\nステータスコード: $statusCode';
  }

  @override
  String get transferIdNotFound => '転送IDが見つかりません';

  @override
  String get waitingForConfirmation => '確認待ち...';

  @override
  String get preparingToReceive => '受信準備中...';

  @override
  String get rejected => '拒否されました';

  @override
  String get receiveComplete => '受信完了';

  @override
  String receivingProgress(double progress) {
    final intl.NumberFormat progressNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String progressString = progressNumberFormat.format(progress);

    return '受信中... $progressString%';
  }

  @override
  String receivingFiles(int count) {
    return '$count個のファイルを受信中';
  }

  @override
  String receiveFilesCount(int count) {
    return '$count個のファイルを受信';
  }

  @override
  String get sender => '送信者';

  @override
  String get totalSizeBatch => '合計サイズ';

  @override
  String get fileList => 'ファイルリスト';

  @override
  String get allFilesReceiveComplete => 'すべてのファイルの受信が完了しました！';

  @override
  String get receivingFiles2 => 'ファイルを受信中...';

  @override
  String autoRejectCountdown(int seconds) {
    return 'これらのファイルを受信しますか？（$seconds秒後に自動拒否）';
  }

  @override
  String get rejectAll => 'すべて拒否';

  @override
  String get acceptAll => 'すべて受け入れ';

  @override
  String get networkDiagnosticsReport => 'ネットワーク診断レポート';

  @override
  String get localNetworkInterfaces => 'ローカルネットワークインターフェース';

  @override
  String get noValidNetworkInterface => '有効なネットワークインターフェースが見つかりません';

  @override
  String get privateNetworkAddress => 'プライベートネットワークアドレス';

  @override
  String get targetDeviceReachability => 'ターゲットデバイスの到達可能性';

  @override
  String get canConnectToTarget => 'ターゲットデバイスに接続できます';

  @override
  String get cannotConnectToTarget => 'ターゲットデバイスに接続できません';

  @override
  String get healthCheckTest => 'ヘルスチェックテスト';

  @override
  String get healthCheckSuccess => 'ヘルスチェック成功';

  @override
  String get healthCheckFailed => 'ヘルスチェック失敗';

  @override
  String get statusCode => 'ステータスコード';

  @override
  String get response => '応答';

  @override
  String get internetConnection => 'インターネット接続';

  @override
  String get hasInternetConnection => 'インターネット接続あり';

  @override
  String get noInternetConnection => 'インターネット接続なし';

  @override
  String get networkConnectionFailed =>
      'ターゲットデバイスに接続できません。ネットワーク接続とIPアドレスを確認してください';

  @override
  String get networkTimeout => '接続タイムアウト。ターゲットデバイスがオフラインまたはネットワークが不安定な可能性があります';

  @override
  String get networkRequestFailed => 'ネットワークリクエスト失敗。ネットワーク接続を確認してください';

  @override
  String get transferTimeout => '転送タイムアウト。ネットワーク接続を確認してください';

  @override
  String get transferInterrupted => '転送が中断されました。再試行してください';

  @override
  String get fileNotFound => 'ファイルが存在しません';

  @override
  String get fileNotReadable => 'ファイルを読み取れません。ファイルが存在し、アクセス権限があることを確認してください';

  @override
  String get fileAccessError => 'ファイルアクセスエラー。ファイル権限を確認してください';

  @override
  String get fileSaveFailed => 'ファイル保存失敗';

  @override
  String get fileSizeMismatch => 'ファイル保存失敗: ファイルサイズが一致しません';

  @override
  String get invalidFileName => 'ファイル名に無効な文字が含まれています';

  @override
  String get downloadsDirectoryUnavailable => 'ダウンロードディレクトリにアクセスできません';

  @override
  String get storageInsufficient => 'ストレージ容量が不足しているため、ファイルを受信できません';

  @override
  String get diskFullTitle => 'ディスク容量不足';

  @override
  String get storageCheckFailed => 'ストレージ容量を確認できません';

  @override
  String get networkPermissionDenied => 'ファイルを転送するにはネットワークアクセス権限が必要です';

  @override
  String get storagePermissionDenied => 'ファイルを保存するにはストレージアクセス権限が必要です';

  @override
  String serverStartFailed(String reason) {
    return 'サーバーを起動できません: $reason';
  }

  @override
  String get serverPortsOccupied => 'サーバーを起動できません: すべてのポートが使用中です';

  @override
  String serverPortsOccupiedRange(int defaultPort, int maxPort) {
    return 'サーバーを起動できません: ポート$defaultPort-$maxPortがすべて使用中です';
  }

  @override
  String get serverUnknownError => 'サーバーを起動できません: 不明なエラー';

  @override
  String get transferRejected => '相手がファイルの受信を拒否しました';

  @override
  String get fileTooLarge => 'ファイルが大きすぎます。最大2GBまでサポートされています';

  @override
  String get fileOrStorageFull => 'ファイルが大きすぎるか、相手のストレージ容量が不足しています';

  @override
  String get receiveTimeout => '受信タイムアウト。自動的に拒否されました';

  @override
  String get userRejected => 'ユーザーがファイルの受信を拒否しました';

  @override
  String get ipAddressEmpty => 'IPアドレスを空にすることはできません';

  @override
  String get ipAddressInvalidFormat =>
      'IPアドレスの形式が無効です。xxx.xxx.xxx.xxx形式を使用してください';

  @override
  String get ipAddressInvalidRange => 'IPアドレスの形式が無効です。各数字は0-255の範囲内である必要があります';

  @override
  String get ipAddressSpecial1 => '0.0.0.0をターゲットアドレスとして使用できません';

  @override
  String get ipAddressSpecial2 => 'ブロードキャストアドレス255.255.255.255を使用できません';

  @override
  String ipAddressNotInSameSubnet(
    String localIP,
    String targetIP,
    String localNetwork,
    String targetNetwork,
  ) {
    return '⚠️ サブネットの不一致\nローカルIP: $localIP（サブネット: $localNetwork.x）\nターゲットIP: $targetIP（サブネット: $targetNetwork.x）\n\nヒント: 2台のデバイスがファイルを転送するには、同じローカルネットワーク（同じサブネット）にある必要があります。\nクラスC IPv4アドレスの場合、2つのIPアドレスの最初の3つの数字が同じである必要があります。例えば、両方とも192.169.2で、最後の数字のみが異なります\n最も簡単な方法は、2台のデバイスを同じWiFiまたはルーターに接続することです。\n';
  }

  @override
  String get responseParseError => 'サーバーの応答を解析できません';

  @override
  String get responseInvalidFormat => 'ターゲットデバイスの応答形式が正しくありません';

  @override
  String responseStatusCodeError(int statusCode) {
    return 'サーバーがエラーステータスコードを返しました: $statusCode';
  }

  @override
  String get fileSelectionError => 'ファイル選択中にエラーが発生しました';

  @override
  String get fileSelectionCancelled => 'ファイル選択がキャンセルされました';

  @override
  String genericError(String operation) {
    return '$operation失敗';
  }

  @override
  String unexpectedError(String details) {
    return '予期しないエラーが発生しました: $details';
  }

  @override
  String networkError(String context) {
    return 'ネットワークエラー: $context';
  }

  @override
  String fileError(String context) {
    return 'ファイルエラー: $context';
  }

  @override
  String permissionError(String permissionType) {
    return '続行するには$permissionType権限が必要です';
  }

  @override
  String get foregroundServiceChannelName => 'バックグラウンド転送サービス';

  @override
  String get foregroundServiceChannelDescription =>
      'バックグラウンドでもLANファイルとクリップボード要求を受信できるようにします';

  @override
  String get peerUnreachable => '対象デバイスに接続できません';

  @override
  String get peerUnreachableBoth => 'このデバイスに接続できません（ローカルも中継も不可）';

  @override
  String get peerUnsupported => '相手のバージョンが古く、ペアリングに対応していません';

  @override
  String get identityMismatch => '相手のデバイスコードと公開鍵が一致しないため中止しました';

  @override
  String get cannotPairSelf => '自分自身とはペアリングできません';

  @override
  String get pairingTitle => 'デバイスのペアリング';

  @override
  String get compareHint =>
      '両方のデバイスに表示された数字が完全に一致することを確認してください。異なる場合、接続が改ざんされている可能性があります。';

  @override
  String get compareHintRelay =>
      '同じネットワークにないデバイスです。電話や音声通話で 6 桁の数字を相手と読み合わせ、完全に一致する場合のみ確認してください。確認しなければ保護は一切ありません。';

  @override
  String get pairOverRelay => '中継でペアリング';

  @override
  String get enterDeviceCode => '相手の 32 桁のデバイスコードを入力してください';

  @override
  String get invalidDeviceCode => 'デバイスコードは 32 桁の 16 進数である必要があります';

  @override
  String get alreadyPaired => 'このデバイスはすでに信頼リストにあります';

  @override
  String get peerAlreadyPaired =>
      'The other device still trusts this one; unpair on that device first';

  @override
  String get relayUnavailable => '先に中継サーバーへ接続してください';

  @override
  String get peerBusy => '相手は別のペアリング要求を処理中です';

  @override
  String get peerPairingBlocked =>
      'The other device has blocked this one; ask them to unblock it first';

  @override
  String get peerRelayPairingOff => '相手は中継経由のペアリング要求を無効にしています';

  @override
  String incomingRequest(String deviceName) {
    return '「$deviceName」がこのデバイスとのペアリングを要求しています';
  }

  @override
  String outgoingRequest(String deviceName) {
    return '「$deviceName」とペアリングしています';
  }

  @override
  String get waitingPeer => '相手の確認を待っています…';

  @override
  String get peerAccepted => '相手が確認しました';

  @override
  String get peerRejected => '相手がペアリングを拒否しました';

  @override
  String get peerTimeout => '相手が時間内に確認しませんでした';

  @override
  String get pairingFailed => 'ペアリングに失敗しました';

  @override
  String pairingSucceeded(String deviceName) {
    return '「$deviceName」とのペアリングが完了しました';
  }

  @override
  String get codesMatch => '数字が一致、ペアリングする';

  @override
  String get codesDiffer => '一致しない、中止';

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
  String get pairedDevicesTitle => 'ペアリング済みデバイス';

  @override
  String get pairedDevicesEmpty => 'ペアリング済みのデバイスはありません';

  @override
  String get addPairedDevice => '新しいデバイスをペアリング';

  @override
  String get unpair => 'ペアリング解除';

  @override
  String unpairConfirm(String deviceName) {
    return '「$deviceName」を削除すると、再度数字を照合するまで信頼は復元されません。削除しますか？';
  }

  @override
  String get deviceCodeLabel => 'このデバイスのコード';

  @override
  String get title => '中継サーバー';

  @override
  String get description =>
      '同じネットワークにないとき、自分で立てたサーバー経由でファイルを転送します。ローカル接続が可能な場合は常に直接接続します。';

  @override
  String get encryptionNotice =>
      'ファイルは 2 台のデバイス間でエンドツーエンド暗号化され、ペアリング済みのデバイスだけが復号できます。サーバーが分かるのは転送時刻とバイト数だけです。';

  @override
  String get acceptPairingLabel => '中継経由のペアリング要求を受け取る';

  @override
  String get acceptPairingHint =>
      'サーバートークンを持つデバイスなら誰でもあなたのデバイスコード宛にペアリングを要求できます。一度拒否した相手は再表示されません。';

  @override
  String get iosForegroundNotice => 'iOS ではアプリを開いているときのみ中継で受信できます。';

  @override
  String get enableLabel => '中継を有効にする';

  @override
  String get serverUrlLabel => 'サーバーアドレス';

  @override
  String get tokenLabel => 'アクセストークン';

  @override
  String get invalidUrl => 'アドレスは http:// または https:// で始まる必要があります';

  @override
  String get insecureUrlWarning => 'http:// では通信が暗号化されません。ローカル検証のみに使用してください';

  @override
  String get testConnection => '接続をテスト';

  @override
  String get testSucceeded => '接続に成功しました';

  @override
  String get save => '保存';

  @override
  String get statusDisabled => '無効';

  @override
  String get statusConnecting => '接続中';

  @override
  String get statusConnected => '接続済み';

  @override
  String get statusReconnecting => '再接続中';

  @override
  String get statusRejected => 'サーバーに拒否されました';

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
  String get lanRouteUnavailable => 'ローカルネットワークでこのデバイスに接続できません';

  @override
  String get relayRouteUnavailable => '中継サーバー経由でこのデバイスに接続できません';

  @override
  String get relayNotConnected => '中継サーバーに接続していません';

  @override
  String get relayPeerOffline => '相手がアプリを開かないと中継で受信できません';

  @override
  String get relayPeerNotPaired => '相手がこのデバイスを信頼リストに追加していません';

  @override
  String get relayPeerBusy => '相手は別のファイルを処理中です';

  @override
  String get relayNeedsPairedDevice => '中継転送には事前のペアリングが必要です';

  @override
  String get relayNegotiatingSession => '相手と暗号化セッションを確立しています…';

  @override
  String get relayIdentityMismatch => '相手の署名が無効です。ペアリング済みのデバイスではない可能性があります';

  @override
  String get relayTransferNotice => '中継サーバー経由で転送中です。速度はサーバーの帯域に依存します';

  @override
  String retryingAfterInterruption(int attempt, int maxAttempts) {
    return '接続が切断されました。再試行中 ($attempt/$maxAttempts)…';
  }
}
