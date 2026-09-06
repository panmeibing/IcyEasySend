// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'Icy Easy Send';

  @override
  String get appVersion => '버전';

  @override
  String get navHome => '홈';

  @override
  String get navHistory => '기록';

  @override
  String get navSettings => '설정';

  @override
  String get homeTitle => '홈';

  @override
  String get serverStatus => '서버 상태';

  @override
  String get serverRunning => '실행 중';

  @override
  String get serverStopped => '중지됨';

  @override
  String get serverAddress => '서버 주소';

  @override
  String get deviceName => '기기 이름';

  @override
  String get storageSpace => '저장 공간';

  @override
  String get availableSpace => '사용 가능한 공간';

  @override
  String get sendFiles => '파일 전송';

  @override
  String get receiveFiles => '파일 수신';

  @override
  String get selectFiles => '파일 선택';

  @override
  String get selectFolder => '폴더 선택';

  @override
  String get dragDropHint => '여기에 파일을 드래그하세요';

  @override
  String get noFilesSelected => '선택된 파일 없음';

  @override
  String filesSelected(int count) {
    return '$count개 파일 선택됨';
  }

  @override
  String get clearSelection => '선택 취소';

  @override
  String get startSending => '전송 시작';

  @override
  String get sending => '전송 중';

  @override
  String get sendSuccess => '전송 성공';

  @override
  String get sendFailed => '전송 실패';

  @override
  String get cancel => '취소';

  @override
  String get confirm => '확인';

  @override
  String get historyTitle => '전송 기록';

  @override
  String get noHistory => '기록이 없습니다';

  @override
  String get clearHistory => '기록 지우기';

  @override
  String get sent => '전송됨';

  @override
  String get received => '수신됨';

  @override
  String get failed => '실패';

  @override
  String get fileSize => '파일 크기';

  @override
  String get time => '시간';

  @override
  String get deleteItem => '기록 삭제';

  @override
  String get deleteItemConfirm => '이 기록을 삭제하시겠습니까?';

  @override
  String get openFile => '파일 열기';

  @override
  String get openFolder => '폴더 열기';

  @override
  String get settingsTitle => '설정';

  @override
  String get general => '일반';

  @override
  String get language => '언어';

  @override
  String get deviceNameSetting => '기기 이름';

  @override
  String get editDeviceName => '기기 이름 수정';

  @override
  String get deviceNameHint => '기기 이름을 입력하세요';

  @override
  String get deviceNameEmpty => '기기 이름은 비워둘 수 없습니다';

  @override
  String get port => '포트';

  @override
  String get portHint => '포트 번호를 입력하세요';

  @override
  String get portInvalid => '유효하지 않은 포트 번호';

  @override
  String get portInUse => '포트가 이미 사용 중입니다';

  @override
  String get savePath => '저장 경로';

  @override
  String get selectSavePath => '저장 경로 선택';

  @override
  String get savePathDesc => '수신한 파일이 이 위치에 저장됩니다. 기본값은 시스템 다운로드 폴더입니다.';

  @override
  String get savePathDefaultBadge => '기본';

  @override
  String get savePathUnavailable => '저장 경로를 가져올 수 없습니다';

  @override
  String get savePathSavedSuccess => '저장 경로가 성공적으로 설정되었습니다';

  @override
  String get savePathNotWritable => '이 폴더에 쓸 수 없습니다. 다른 위치를 선택하거나 권한을 확인하세요.';

  @override
  String get resetSavePathToDefault => '기본 폴더 사용';

  @override
  String get savePathResetSuccess => '시스템 다운로드 폴더로 복원되었습니다';

  @override
  String get autoStart => '자동 시작';

  @override
  String get autoStartDesc => '앱 시작 시 서버 자동 실행';

  @override
  String get network => '네트워크';

  @override
  String get networkDiagnostics => '네트워크 진단';

  @override
  String get scanDevices => '기기 검색';

  @override
  String get scanDevicesTitle => 'LAN 기기 검색';

  @override
  String get scanningDevices => '로컬 네트워크를 검색하는 중...';

  @override
  String scanProgress(int scanned, int total, int found) {
    return '검색 $scanned/$total, $found대 발견';
  }

  @override
  String get noDevicesFound => '기기를 찾을 수 없습니다';

  @override
  String get noDevicesFoundHint =>
      '대상 기기에서 서버가 실행 중이고 같은 네트워크에 연결되어 있는지 확인하세요. AP 격리 및 방화벽 설정도 확인하세요.';

  @override
  String scanDevicesFound(int count) {
    return '$count대 기기 발견';
  }

  @override
  String get rescan => '다시 검색';

  @override
  String get runDiagnostics => '진단 실행';

  @override
  String get about => '정보';

  @override
  String get version => '버전';

  @override
  String get checkUpdate => '업데이트 확인';

  @override
  String get feedback => '피드백';

  @override
  String get openSource => '오픈소스 라이선스';

  @override
  String get license => '라이선스';

  @override
  String get permissionRequired => '권한 필요';

  @override
  String get permissionDenied => '권한이 거부되었습니다';

  @override
  String get permissionPermanentlyDenied => '권한이 영구적으로 거부되었습니다';

  @override
  String get permissionStorage => '저장소 권한';

  @override
  String get permissionStorageDesc => '파일을 저장하고 읽으려면 저장소 권한이 필요합니다';

  @override
  String get permissionNotification => '알림 권한';

  @override
  String get permissionNotificationDesc => '전송 진행 상황을 표시하려면 알림 권한이 필요합니다';

  @override
  String get openSettings => '설정 열기';

  @override
  String get permissionWarning => '일부 권한이 부여되지 않아 일부 기능이 제한될 수 있습니다';

  @override
  String get error => '오류';

  @override
  String get errorUnknown => '알 수 없는 오류';

  @override
  String get errorNetwork => '네트워크 오류';

  @override
  String get errorFileNotFound => '파일을 찾을 수 없음';

  @override
  String get errorPermission => '권한 오류';

  @override
  String get errorStorage => '저장소 오류';

  @override
  String get errorServer => '서버 오류';

  @override
  String get errorServerStart => '서버 시작 실패';

  @override
  String get errorServerStop => '서버 중지 실패';

  @override
  String get errorConnection => '연결 오류';

  @override
  String get errorTimeout => '연결 시간 초과';

  @override
  String get retry => '재시도';

  @override
  String get copied => '복사됨';

  @override
  String get copyFailed => '복사 실패';

  @override
  String get saved => '저장됨';

  @override
  String get saveFailed => '저장 실패';

  @override
  String get deleted => '삭제됨';

  @override
  String get deleteFailed => '삭제 실패';

  @override
  String get loading => '로딩 중';

  @override
  String get success => '성공';

  @override
  String get warning => '경고';

  @override
  String get info => '정보';

  @override
  String get yes => '예';

  @override
  String get no => '아니오';

  @override
  String get ok => '확인';

  @override
  String get close => '닫기';

  @override
  String get selectFilesFailed => '파일 선택 실패';

  @override
  String get selectFolderFailed => '폴더 선택 실패';

  @override
  String folderFilesAdded(int count) {
    return '폴더에서 $count개 파일을 추가했습니다';
  }

  @override
  String get folderContainsNoFiles => '선택한 폴더에 전송할 파일이 없습니다';

  @override
  String get openFileFailed => '파일 열기 실패';

  @override
  String get openFolderFailed => '폴더 열기 실패';

  @override
  String get fileNotExist => '파일이 존재하지 않습니다';

  @override
  String get folderNotExist => '폴더가 존재하지 않습니다';

  @override
  String get diagnosticsTitle => '네트워크 진단';

  @override
  String get diagnosticsRunning => '진단 실행 중...';

  @override
  String get diagnosticsComplete => '진단 완료';

  @override
  String get diagnosticsFailed => '진단 실패';

  @override
  String get networkStatus => '네트워크 상태';

  @override
  String get wifiConnected => 'WiFi 연결됨';

  @override
  String get wifiDisconnected => 'WiFi 연결 안 됨';

  @override
  String get mobileData => '모바일 데이터';

  @override
  String get noConnection => '네트워크 연결 없음';

  @override
  String get ipAddress => 'IP 주소';

  @override
  String get noIpAddress => 'IP 주소 없음';

  @override
  String get serverStatusCheck => '서버 상태 확인';

  @override
  String get portCheck => '포트 확인';

  @override
  String get portAvailable => '포트 사용 가능';

  @override
  String get portUnavailable => '포트 사용 불가';

  @override
  String get suggestions => '제안';

  @override
  String get syncClipboard => '상대방 클립보드 동기화';

  @override
  String filesCount(int count) {
    return '$count개 파일 전송';
  }

  @override
  String get sendFile => '파일 전송';

  @override
  String get shareViaQr => 'QR로 공유';

  @override
  String get webShareTitle => '스캔하여 받기';

  @override
  String get webShareHint =>
      '상대방은 시스템 카메라로 스캔해 브라우저에서 다운로드할 수 있습니다(앱 설치 불필요). 같은 Wi‑Fi / LAN에 있어야 합니다. 일부 서드파티 스캐너는 LAN 링크를 열지 못할 수 있으니 링크 복사를 사용하세요.';

  @override
  String get webShareCopyLink => '링크 복사';

  @override
  String get webShareLinkCopied => '링크가 복사되었습니다';

  @override
  String get webShareStopSharing => '공유 중지';

  @override
  String get webShareStopped => '웹 공유가 중지되었습니다';

  @override
  String get webShareServerRequired => 'QR 공유 전에 로컬 서버를 시작하세요';

  @override
  String get webShareCreated => '웹 공유가 생성되었습니다. 상대방이 스캔하여 다운로드할 수 있습니다.';

  @override
  String get webShareFailed => '웹 공유 생성 실패';

  @override
  String get webSharePeerName => '웹 공유';

  @override
  String webShareFilesSummary(int count, String size) {
    return '$count개 파일 · $size';
  }

  @override
  String webShareExpiresIn(String time) {
    return '남은 시간 $time';
  }

  @override
  String get releaseToAdd => '마우스를 놓아 파일 추가';

  @override
  String get serverNotRunning => '서버가 실행되지 않아 공유 파일을 받을 수 없습니다';

  @override
  String get cannotReceiveFiles => '파일을 받을 수 없습니다';

  @override
  String get sendingInProgress => '파일 전송 중입니다. 나중에 다시 시도하세요';

  @override
  String get pleaseTryLater => '나중에 다시 시도하세요';

  @override
  String filesAdded(int count) {
    return '$count개의 공유 파일이 추가되었습니다';
  }

  @override
  String get preparingSend => '전송 준비 중...';

  @override
  String get transferring => '전송 중';

  @override
  String transferProgress(int current, int total, String fileName) {
    return '[$current/$total] $fileName: 전송 중...';
  }

  @override
  String get networkChanged => '네트워크가 변경되어 서버 주소가 업데이트되었습니다';

  @override
  String get serverAddressUpdated => '서버 주소가 업데이트되었습니다';

  @override
  String get portCannotBeEmpty => '포트는 비워둘 수 없습니다';

  @override
  String get portMustBeNumber => '포트는 숫자여야 합니다';

  @override
  String get portRange => '포트 범위: 1-65535';

  @override
  String ipDeleted(String ip) {
    return 'IP 삭제됨: $ip';
  }

  @override
  String get runningDiagnostics => '네트워크 진단 실행 중...';

  @override
  String get targetDeviceInfo => '대상 기기 정보';

  @override
  String get fullAddress => '전체 주소';

  @override
  String get targetNotSet => '대상 기기가 설정되지 않았습니다';

  @override
  String get diagnosticsReport => '네트워크 진단 보고서';

  @override
  String get reportCopied => '진단 보고서가 클립보드에 복사되었습니다';

  @override
  String get deviceNameCannotBeEmpty => '기기 이름은 비워둘 수 없습니다';

  @override
  String get deviceNameSaved => '기기 이름이 저장되었습니다';

  @override
  String get resetDeviceName => '기기 이름 재설정';

  @override
  String resetDeviceNameConfirm(String model) {
    return '기기 이름을 \"$model\"(으)로 재설정하시겠습니까?';
  }

  @override
  String get reset => '재설정';

  @override
  String get confirmChange => '변경 확인';

  @override
  String concurrentTransfersIncrease(int from, int to) {
    return '동시 전송 수를 $from에서 $to(으)로 변경하시겠습니까?\n\n팁: 동시 전송 수를 늘리면 전송 속도가 향상될 수 있지만 기기 부하가 증가합니다';
  }

  @override
  String concurrentTransfersDecrease(int from, int to) {
    return '동시 전송 수를 $from에서 $to(으)로 변경하시겠습니까?\n\n팁: 동시 전송 수를 줄이면 기기 부하가 감소하지만 전송 속도가 느려질 수 있습니다';
  }

  @override
  String get concurrentTransfersHint => '동시 전송 팁';

  @override
  String get concurrentTransfersSaved => '동시 전송 수가 저장되었습니다';

  @override
  String get enterValidNumber => '유효한 숫자를 입력하세요';

  @override
  String historyCountRange(int min, int max) {
    return '기록 수 범위: $min-$max';
  }

  @override
  String maxHistoryChange(int from, int to) {
    return '최대 기록 수를 $from에서 $to(으)로 변경하시겠습니까?\n\n';
  }

  @override
  String currentHistoryCount(int count) {
    return '현재 기록 수: $count개\n\n';
  }

  @override
  String get historyWarning => '⚠️ 경고: 현재 저장된 기록 수가 설정된 수보다 많습니다.\n\n';

  @override
  String historyDeleteWarning(int current, int max, int toDelete) {
    return '최신 $max개의 기록만 유지되며, 초과된 $toDelete개의 오래된 기록은 삭제됩니다.';
  }

  @override
  String get historyHint => '팁: 새 설정은 다음에 기록을 저장할 때 적용됩니다.';

  @override
  String historyDeleted(int count) {
    return '설정이 저장되었으며 $count개의 오래된 기록이 삭제되었습니다';
  }

  @override
  String get maxHistorySaved => '최대 기록 수가 저장되었습니다';

  @override
  String clipboardSizeRange(int min, int max) {
    return '클립보드 크기 범위: $min-$max MB';
  }

  @override
  String maxClipboardSizeChange(int from, int to) {
    return '최대 클립보드 크기를 $from MB에서 $to MB로 변경하시겠습니까?\n\n';
  }

  @override
  String get clipboardSizeDecreaseHint =>
      '⚠️ 팁: 제한을 낮추면 제한을 초과하는 클립보드 내용은 동기화할 수 없습니다. 파일 전송 기능을 사용하는 것이 좋습니다.';

  @override
  String get clipboardSizeIncreaseHint =>
      '팁: 제한을 늘리면 더 큰 클립보드 내용을 동기화할 수 있지만 전송 속도에 영향을 줄 수 있습니다.';

  @override
  String get maxClipboardSizeSaved => '최대 클립보드 크기가 저장되었습니다';

  @override
  String get ipValidationEnabled => 'IP 주소 검증이 활성화되었습니다';

  @override
  String get ipValidationDisabled => 'IP 주소 검증이 비활성화되었습니다';

  @override
  String get deviceSecretKeyCleared => '기기 비밀 키가 지워졌습니다';

  @override
  String get deviceSecretKeySaved => '기기 비밀 키가 저장되었습니다';

  @override
  String get loadingDevInfo => '개발 정보 로딩 중...';

  @override
  String get copyLog => '로그 복사';

  @override
  String logCopied(int lines) {
    return '마지막 $lines줄의 로그가 클립보드에 복사되었습니다';
  }

  @override
  String get logFileEmpty => '로그 파일이 비어 있습니다';

  @override
  String get devInfo => '개발 정보';

  @override
  String labelCopied(String label, String value) {
    return '$label 복사됨: $value';
  }

  @override
  String get transferSettings => '전송 설정';

  @override
  String get concurrentTransfers => '동시 전송 수';

  @override
  String concurrentTransfersDesc(int max) {
    return '동시에 전송할 파일 수 (1-$max)';
  }

  @override
  String get concurrentTransfersHintText =>
      '높은 동시 전송 수는 대역폭을 더 잘 활용할 수 있지만 기기 부하가 증가할 수 있습니다';

  @override
  String get maxHistory => '최대 기록 수';

  @override
  String maxHistoryDesc(int min, int max) {
    return '저장할 최대 전송 기록 수 ($min-$max)';
  }

  @override
  String maxHistoryHintText(int min, int max) {
    return '수량 입력 ($min-$max)';
  }

  @override
  String get oldRecordsAutoDelete =>
      '설정된 수를 초과하는 오래된 기록은 자동으로 삭제되며 최신 기록만 유지됩니다';

  @override
  String get maxClipboard => '최대 클립보드 크기';

  @override
  String maxClipboardDesc(int min, int max) {
    return '동기화할 수 있는 최대 클립보드 크기 ($min-$max MB)';
  }

  @override
  String maxClipboardHintText(int min, int max) {
    return '크기 입력 ($min-$max MB)';
  }

  @override
  String get clipboardSyncLimit =>
      '이 크기를 초과하는 클립보드 내용은 동기화할 수 없습니다. 파일 전송 기능을 사용하는 것이 좋습니다';

  @override
  String get ipValidation => 'IP 주소 검증';

  @override
  String get ipValidationDesc => '대상 기기 IP가 같은 서브넷에 있는지 확인';

  @override
  String get ipValidationEnabledHint =>
      '활성화하면 대상 IP가 같은 서브넷에 있는지 확인하여 잘못된 기기에 연결하는 것을 방지할 수 있습니다';

  @override
  String get ipValidationDisabledHint =>
      '비활성화하면 IP 서브넷을 확인하지 않으며 복잡한 네트워크 환경(핫스팟, VPN 등)에 적합합니다';

  @override
  String get deviceSecretKey => '이 기기 비밀 키';

  @override
  String get deviceSecretKeyDesc => '설정하면 다른 기기가 올바른 비밀 키를 제공해야 확인을 건너뛸 수 있습니다';

  @override
  String get deviceSecretKeyHint => '비밀 키 입력 (비워두면 비밀 키를 사용하지 않음)';

  @override
  String get notSet => '설정되지 않음';

  @override
  String get author => '작성자';

  @override
  String get appDescription => '간단하고 사용하기 쉬운 로컬 네트워크 파일 전송 도구';

  @override
  String get targetDeviceIP => '대상 기기 IP 주소';

  @override
  String get ipHint => '예: 192.168.1.100';

  @override
  String get clear => '지우기';

  @override
  String get history => '기록';

  @override
  String get targetDevicePort => '대상 기기 포트';

  @override
  String resetToDefaultPort(int port) {
    return '기본 포트로 재설정 ($port)';
  }

  @override
  String get targetDeviceSecretKey => '대상 기기 비밀 키 (선택 사항)';

  @override
  String get secretKeyHint => '올바른 비밀 키로 상대방 확인 건너뛰기';

  @override
  String get aboutSecretKey => '비밀 키 정보';

  @override
  String get secretKeyFeatureTitle => '비밀 키 기능 설명';

  @override
  String get secretKeyFeatureDesc =>
      '대상 기기가 비밀 키를 설정한 경우 올바른 비밀 키를 입력하면 확인 대화 상자를 건너뛰고 파일을 직접 전송하거나 클립보드를 동기화할 수 있습니다.';

  @override
  String get secretKeyUsageSteps => '사용 단계:';

  @override
  String get secretKeyUsageStep1 => '1. 대상 기기가 설정 페이지에서 이 기기 비밀 키를 설정합니다';

  @override
  String get secretKeyUsageStep2 => '2. 이 입력란에 대상 기기의 비밀 키를 입력합니다';

  @override
  String get secretKeyUsageStep3 =>
      '3. 파일을 전송하거나 클립보드를 요청할 때 비밀 키가 올바르면 상대방이 자동으로 수락합니다';

  @override
  String get secretKeyTip => '팁: 비워두면 기존의 수동 확인 방식을 사용합니다';

  @override
  String get secretKeyDescription => '비밀 키 설명';

  @override
  String get clearSecretKey => '비밀 키 지우기';

  @override
  String get gotIt => '알겠습니다';

  @override
  String get localIP => '이 기기 IP';

  @override
  String ipCopied(String ip) {
    return 'IP 주소 복사됨: $ip';
  }

  @override
  String get transferred => '전송됨';

  @override
  String get transferSpeed => '전송 속도';

  @override
  String get remainingTime => '남은 시간';

  @override
  String transferringProgress(double progress) {
    final intl.NumberFormat progressNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String progressString = progressNumberFormat.format(progress);

    return '전송 중 $progressString%';
  }

  @override
  String get storagePermissionMessage =>
      '파일을 선택하려면 저장소 권한이 필요합니다. 설정에서 수동으로 권한을 활성화하세요.';

  @override
  String get checkingTargetDevice => '대상 기기 확인 중...';

  @override
  String get targetDeviceUnavailable => '대상 기기를 사용할 수 없습니다';

  @override
  String targetDeviceError(String error) {
    return '대상 기기를 사용할 수 없습니다\n오류: $error';
  }

  @override
  String get connectionFailed => '연결 실패';

  @override
  String get transferHistory => '전송 기록';

  @override
  String get clearHistoryTitle => '기록 지우기';

  @override
  String get clearHistoryMessage => '모든 전송 기록을 지우시겠습니까? 이 작업은 취소할 수 없습니다.';

  @override
  String get noFilteredRecords => '조건에 맞는 기록이 없습니다';

  @override
  String get filterAll => '전체';

  @override
  String get filterSent => '전송됨';

  @override
  String get filterReceived => '수신됨';

  @override
  String get statisticsInfo => '통계 정보';

  @override
  String transfersCount(int count) {
    return '$count회 전송';
  }

  @override
  String get totalTransfers => '총 전송';

  @override
  String get successfulTransfers => '성공';

  @override
  String get failedTransfers => '실패';

  @override
  String get sentFiles => '전송됨';

  @override
  String get receivedFiles => '수신됨';

  @override
  String get totalSize => '총 크기';

  @override
  String get moreActions => '더 많은 작업';

  @override
  String get deleteRecord => '기록 삭제';

  @override
  String get viewDetails => '세부 정보 보기';

  @override
  String get deleteRecordTitle => '기록 삭제';

  @override
  String deleteRecordMessage(String fileName) {
    return '\"$fileName\"의 전송 기록을 삭제하시겠습니까?\n\n참고: 기록만 삭제되며 파일 자체는 삭제되지 않습니다.';
  }

  @override
  String get deleteRecordNote => '참고: 기록만 삭제되며 파일 자체는 삭제되지 않습니다.';

  @override
  String get recordDeleted => '기록이 삭제되었습니다';

  @override
  String get filePathNotExist => '파일 경로가 존재하지 않습니다';

  @override
  String get cannotOpenFile => '파일을 열 수 없습니다';

  @override
  String cannotOpenFileWithMessage(String message) {
    return '파일을 열 수 없습니다: $message';
  }

  @override
  String get iosNoFolderSupport => 'iOS는 폴더를 직접 열 수 없습니다';

  @override
  String get cannotOpenFolder => '폴더를 열 수 없습니다';

  @override
  String get recentFilesOpened => '최근 파일이 열렸습니다. 수동으로 찾아보세요';

  @override
  String get receiveRecord => '수신 기록';

  @override
  String get sendRecord => '전송 기록';

  @override
  String get fileName => '파일 이름';

  @override
  String get fromDevice => '보낸 기기';

  @override
  String get toDevice => '받는 기기';

  @override
  String get deviceIP => '기기 IP';

  @override
  String get transferTime => '전송 시간';

  @override
  String get transferStatus => '전송 상태';

  @override
  String get statusSuccess => '성공';

  @override
  String get statusFailed => '실패';

  @override
  String get savedLocation => '저장 위치';

  @override
  String get copy => '복사';

  @override
  String get pathCopied => '경로가 클립보드에 복사되었습니다';

  @override
  String get from => '보낸 곳';

  @override
  String get sentTo => '받는 곳';

  @override
  String get clipboardRequest => '클립보드 요청';

  @override
  String clipboardRequestFrom(String deviceName) {
    return '기기 \"$deviceName\"이(가) 클립보드 내용을 요청합니다';
  }

  @override
  String get allowClipboardRequest => '허용하시겠습니까?';

  @override
  String get clipboardRequestMessage => '클립보드 요청';

  @override
  String autoRejectIn(int seconds) {
    return '$seconds초 후 자동 거부';
  }

  @override
  String get reject => '거부';

  @override
  String get allow => '허용';

  @override
  String clipboardSharedWithSecretKey(String deviceName) {
    return '$deviceName이(가) 비밀 키 인증을 통과하여 클립보드를 자동으로 공유합니다';
  }

  @override
  String get clipboardRequestRejected => '사용자가 클립보드 요청을 거부했습니다';

  @override
  String get clipboardEmpty => '클립보드가 비어 있습니다';

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

    return '클립보드 내용이 너무 큽니다 ($actualSizeMBString MB). 상대방 기기의 제한 ($maxSizeMB MB)을 초과합니다. 파일 전송 기능을 사용하는 것이 좋습니다.';
  }

  @override
  String get clipboardContentSuccess => '클립보드 내용을 성공적으로 가져왔습니다';

  @override
  String get invalidJsonFormat => '유효하지 않은 JSON 형식';

  @override
  String get serverInternalError => '서버 내부 오류';

  @override
  String get backgroundRejectNeedsSecretKey =>
      '기기가 백그라운드에 있습니다. 일치하는 비밀 키가 있을 때만 자동 동기화/수신이 가능합니다.';

  @override
  String get foregroundServiceNotificationTitle => 'IcyEasySend';

  @override
  String get foregroundServiceNotificationText =>
      '백그라운드에서 파일 전송 및 클립보드 동기화를 대기 중';

  @override
  String get androidBackgroundReceiveHint =>
      '백그라운드에서는 일치하는 비밀 키가 있는 기기만 자동 동기화/전송할 수 있습니다. 상시 알림을 유지하세요.';

  @override
  String get clipboardOverlay => '클립보드 플로팅 버튼';

  @override
  String get clipboardOverlayDesc =>
      '플로팅 버튼을 눌러 백그라운드 동기화용 텍스트/이미지 캐시를 새로고침합니다';

  @override
  String get clipboardOverlayHint =>
      '백그라운드에서는 마지막 새로고침 내용만 동기화됩니다. 끄면 캐시가 비워지고 버튼이 숨겨집니다.';

  @override
  String get clipboardOverlayPermissionNeeded =>
      '시스템 설정에서 \"다른 앱 위에 표시\"를 허용하세요. 돌아오면 플로팅 버튼이 표시됩니다.';

  @override
  String get clipboardOverlayEnabledToast => '클립보드 플로팅 버튼이 켜졌습니다';

  @override
  String get clipboardBackgroundCacheMiss =>
      '백그라운드에서는 시스템 클립보드를 읽을 수 없고 사용 가능한 캐시도 없습니다. 앱을 열거나 플로팅 버튼을 눌러 새로고침한 뒤 동기화하세요.';

  @override
  String get requestingClipboard => '클립보드 요청 중...';

  @override
  String get clipboardSyncSuccess => '클립보드 동기화 성공';

  @override
  String get textClipboardSyncSuccess => '텍스트 클립보드 동기화 성공';

  @override
  String get fileClipboardSyncSuccess =>
      '파일 클립보드 동기화 성공\n앱 또는 파일 관리자에서 붙여넣을 수 있습니다';

  @override
  String get clipboardSyncFailed => '클립보드 동기화 실패';

  @override
  String get syncFailed => '동기화 실패';

  @override
  String clipboardRequestError(String error) {
    return '클립보드 요청 중 오류 발생: $error';
  }

  @override
  String invalidFilesMessage(String fileNames) {
    return '다음 파일이 유효하지 않거나 액세스할 수 없습니다:\n$fileNames';
  }

  @override
  String get waitingForReceiverConfirmation => '수신자 확인 대기 중...';

  @override
  String get fileSendSuccess => '파일 전송 성공!';

  @override
  String filesSendSuccess(int count) {
    return '$count개 파일 전송 성공!';
  }

  @override
  String get allFilesSendFailed => '모든 파일 전송 실패';

  @override
  String get failedFiles => '실패한 파일';

  @override
  String get transferComplete => '전송 완료';

  @override
  String get successCount => '성공';

  @override
  String get failureCount => '실패';

  @override
  String transferSummary(
    int successCount,
    int failureCount,
    String failedFiles,
  ) {
    return '성공: $successCount개 파일\n실패: $failureCount개 파일\n\n실패한 파일:\n$failedFiles';
  }

  @override
  String get preparingTransferInfo => '전송 정보 준비 중...';

  @override
  String waitingForReceiverConfirmFiles(int count) {
    return '수신자가 $count개 파일을 확인하기를 기다리는 중...';
  }

  @override
  String transferringFile(int current, int total, String fileName) {
    return '파일 전송 중 $current/$total: $fileName';
  }

  @override
  String get receiverRejected => '수신자가 거부했습니다';

  @override
  String receiverRejectedWithStatus(int statusCode) {
    return '수신자가 거부했습니다\n상태 코드: $statusCode';
  }

  @override
  String get transferIdNotFound => '전송 ID를 찾을 수 없습니다';

  @override
  String get waitingForConfirmation => '확인 대기 중...';

  @override
  String get preparingToReceive => '수신 준비 중...';

  @override
  String get rejected => '거부됨';

  @override
  String get receiveComplete => '수신 완료';

  @override
  String receivingProgress(double progress) {
    final intl.NumberFormat progressNumberFormat =
        intl.NumberFormat.decimalPatternDigits(
          locale: localeName,
          decimalDigits: 1,
        );
    final String progressString = progressNumberFormat.format(progress);

    return '수신 중... $progressString%';
  }

  @override
  String receivingFiles(int count) {
    return '$count개 파일 수신 중';
  }

  @override
  String receiveFilesCount(int count) {
    return '$count개 파일 수신';
  }

  @override
  String get sender => '보낸 사람';

  @override
  String get totalSizeBatch => '총 크기';

  @override
  String get fileList => '파일 목록';

  @override
  String get allFilesReceiveComplete => '모든 파일 수신 완료!';

  @override
  String get receivingFiles2 => '파일 수신 중...';

  @override
  String autoRejectCountdown(int seconds) {
    return '이 파일들을 받으시겠습니까? ($seconds초 후 자동 거부)';
  }

  @override
  String get rejectAll => '모두 거부';

  @override
  String get acceptAll => '모두 수락';

  @override
  String get networkDiagnosticsReport => '네트워크 진단 보고서';

  @override
  String get localNetworkInterfaces => '로컬 네트워크 인터페이스';

  @override
  String get noValidNetworkInterface => '유효한 네트워크 인터페이스를 찾을 수 없습니다';

  @override
  String get privateNetworkAddress => '사설 네트워크 주소';

  @override
  String get targetDeviceReachability => '대상 기기 연결 가능성';

  @override
  String get canConnectToTarget => '대상 기기에 연결할 수 있습니다';

  @override
  String get cannotConnectToTarget => '대상 기기에 연결할 수 없습니다';

  @override
  String get healthCheckTest => '상태 확인 테스트';

  @override
  String get healthCheckSuccess => '상태 확인 성공';

  @override
  String get healthCheckFailed => '상태 확인 실패';

  @override
  String get statusCode => '상태 코드';

  @override
  String get response => '응답';

  @override
  String get internetConnection => '인터넷 연결';

  @override
  String get hasInternetConnection => '인터넷 연결 있음';

  @override
  String get noInternetConnection => '인터넷 연결 없음';

  @override
  String get networkConnectionFailed =>
      '대상 기기에 연결할 수 없습니다. 네트워크 연결과 IP 주소를 확인하세요';

  @override
  String get networkTimeout => '연결 시간 초과. 대상 기기가 오프라인이거나 네트워크가 불안정할 수 있습니다';

  @override
  String get networkRequestFailed => '네트워크 요청 실패. 네트워크 연결을 확인하세요';

  @override
  String get transferTimeout => '전송 시간 초과. 네트워크 연결을 확인하세요';

  @override
  String get transferInterrupted => '전송이 중단되었습니다. 다시 시도하세요';

  @override
  String get fileNotFound => '파일이 존재하지 않습니다';

  @override
  String get fileNotReadable => '파일을 읽을 수 없습니다. 파일이 존재하고 액세스 권한이 있는지 확인하세요';

  @override
  String get fileAccessError => '파일 액세스 오류. 파일 권한을 확인하세요';

  @override
  String get fileSaveFailed => '파일 저장 실패';

  @override
  String get fileSizeMismatch => '파일 저장 실패: 파일 크기가 일치하지 않습니다';

  @override
  String get invalidFileName => '파일 이름에 잘못된 문자가 포함되어 있습니다';

  @override
  String get downloadsDirectoryUnavailable => '다운로드 디렉토리에 액세스할 수 없습니다';

  @override
  String get storageInsufficient => '저장 공간이 부족하여 파일을 받을 수 없습니다';

  @override
  String get diskFullTitle => '디스크 공간 부족';

  @override
  String get storageCheckFailed => '저장 공간을 확인할 수 없습니다';

  @override
  String get networkPermissionDenied => '파일을 전송하려면 네트워크 액세스 권한이 필요합니다';

  @override
  String get storagePermissionDenied => '파일을 저장하려면 저장소 액세스 권한이 필요합니다';

  @override
  String serverStartFailed(String reason) {
    return '서버를 시작할 수 없습니다: $reason';
  }

  @override
  String get serverPortsOccupied => '서버를 시작할 수 없습니다: 모든 포트가 이미 사용 중입니다';

  @override
  String serverPortsOccupiedRange(int defaultPort, int maxPort) {
    return '서버를 시작할 수 없습니다: 포트 $defaultPort-$maxPort가 모두 사용 중입니다';
  }

  @override
  String get serverUnknownError => '서버를 시작할 수 없습니다: 알 수 없는 오류';

  @override
  String get transferRejected => '상대방이 파일 수신을 거부했습니다';

  @override
  String get fileTooLarge => '파일이 너무 큽니다. 최대 2GB까지 지원됩니다';

  @override
  String get fileOrStorageFull => '파일이 너무 크거나 상대방의 저장 공간이 부족합니다';

  @override
  String get receiveTimeout => '수신 시간 초과. 자동으로 거부되었습니다';

  @override
  String get userRejected => '사용자가 파일 수신을 거부했습니다';

  @override
  String get ipAddressEmpty => 'IP 주소는 비워둘 수 없습니다';

  @override
  String get ipAddressInvalidFormat =>
      'IP 주소 형식이 유효하지 않습니다. xxx.xxx.xxx.xxx 형식을 사용하세요';

  @override
  String get ipAddressInvalidRange =>
      'IP 주소 형식이 유효하지 않습니다. 각 숫자는 0-255 사이여야 합니다';

  @override
  String get ipAddressSpecial1 => '0.0.0.0을 대상 주소로 사용할 수 없습니다';

  @override
  String get ipAddressSpecial2 => '브로드캐스트 주소 255.255.255.255를 사용할 수 없습니다';

  @override
  String ipAddressNotInSameSubnet(
    String localIP,
    String targetIP,
    String localNetwork,
    String targetNetwork,
  ) {
    return '⚠️ 서브넷 불일치\n로컬 IP: $localIP (서브넷: $localNetwork.x)\n대상 IP: $targetIP (서브넷: $targetNetwork.x)\n\n팁: 두 기기가 파일을 전송하려면 같은 로컬 네트워크(같은 서브넷)에 있어야 합니다.\nC 클래스 IPv4 주소의 경우 두 IP 주소의 처음 세 숫자가 같아야 합니다. 예를 들어 둘 다 192.169.2이고 마지막 숫자만 다릅니다\n가장 간단한 방법은 두 기기를 같은 WiFi 또는 라우터에 연결하는 것입니다.\n';
  }

  @override
  String get responseParseError => '서버 응답을 구문 분석할 수 없습니다';

  @override
  String get responseInvalidFormat => '대상 기기 응답 형식이 올바르지 않습니다';

  @override
  String responseStatusCodeError(int statusCode) {
    return '서버가 오류 상태 코드를 반환했습니다: $statusCode';
  }

  @override
  String get fileSelectionError => '파일 선택 중 오류 발생';

  @override
  String get fileSelectionCancelled => '파일 선택이 취소되었습니다';

  @override
  String genericError(String operation) {
    return '$operation 실패';
  }

  @override
  String unexpectedError(String details) {
    return '예기치 않은 오류 발생: $details';
  }

  @override
  String networkError(String context) {
    return '네트워크 오류: $context';
  }

  @override
  String fileError(String context) {
    return '파일 오류: $context';
  }

  @override
  String permissionError(String permissionType) {
    return '계속하려면 $permissionType 권한이 필요합니다';
  }

  @override
  String get foregroundServiceChannelName => '백그라운드 전송 서비스';

  @override
  String get foregroundServiceChannelDescription =>
      '앱이 백그라운드에서도 LAN 파일 및 클립보드 요청을 받을 수 있도록 유지';

  @override
  String get peerUnreachable => '대상 기기에 연결할 수 없습니다';

  @override
  String get peerUnreachableBoth => '장치에 연결할 수 없습니다(로컬 네트워크와 중계 모두 불가)';

  @override
  String get peerUnsupported => '상대 기기의 버전이 오래되어 페어링을 지원하지 않습니다';

  @override
  String get identityMismatch => '상대 기기 코드가 공개 키와 일치하지 않아 페어링을 중단했습니다';

  @override
  String get cannotPairSelf => '자기 자신과는 페어링할 수 없습니다';

  @override
  String get pairingTitle => '기기 페어링';

  @override
  String get compareHint =>
      '두 기기에 표시된 숫자가 완전히 같은지 확인한 뒤 확인을 누르세요. 다르면 연결이 변조되었을 수 있습니다.';

  @override
  String get compareHintRelay =>
      '같은 네트워크에 있지 않은 기기입니다. 전화나 음성으로 상대방과 6자리 숫자를 확인하고 완전히 같을 때만 확인하세요. 확인하지 않으면 아무런 보호가 없습니다.';

  @override
  String get pairOverRelay => '중계로 페어링';

  @override
  String get enterDeviceCode => '상대방의 32자리 기기 코드를 입력하세요';

  @override
  String get invalidDeviceCode => '기기 코드는 32자리 16진수여야 합니다';

  @override
  String get alreadyPaired => '이미 신뢰 목록에 있는 기기입니다';

  @override
  String get peerAlreadyPaired =>
      'The other device still trusts this one; unpair on that device first';

  @override
  String get relayUnavailable => '먼저 중계 서버에 연결해야 합니다';

  @override
  String get peerBusy => '상대방이 다른 페어링 요청을 처리하고 있습니다';

  @override
  String get peerPairingBlocked =>
      'The other device has blocked this one; ask them to unblock it first';

  @override
  String get peerRelayPairingOff => '상대방이 중계 페어링 요청 수신을 껐습니다';

  @override
  String incomingRequest(String deviceName) {
    return '\"$deviceName\"이(가) 이 기기와 페어링을 요청했습니다';
  }

  @override
  String outgoingRequest(String deviceName) {
    return '\"$deviceName\"과(와) 페어링하는 중';
  }

  @override
  String get waitingPeer => '상대방의 확인을 기다리는 중…';

  @override
  String get peerAccepted => '상대방이 확인했습니다';

  @override
  String get peerRejected => '상대방이 페어링을 거부했습니다';

  @override
  String get peerTimeout => '상대방이 제한 시간 내에 확인하지 않았습니다';

  @override
  String get pairingFailed => '페어링 실패';

  @override
  String pairingSucceeded(String deviceName) {
    return '\"$deviceName\"과(와) 페어링을 완료했습니다';
  }

  @override
  String get codesMatch => '숫자가 같음, 페어링 확인';

  @override
  String get codesDiffer => '다름, 취소';

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
  String get pairedDevicesTitle => '페어링된 기기';

  @override
  String get pairedDevicesEmpty => '페어링된 기기가 없습니다';

  @override
  String get addPairedDevice => '새 기기 페어링';

  @override
  String get unpair => '페어링 해제';

  @override
  String unpairConfirm(String deviceName) {
    return '\"$deviceName\"을(를) 제거하면 다시 숫자를 확인해야 신뢰를 복구할 수 있습니다. 제거할까요?';
  }

  @override
  String get deviceCodeLabel => '이 기기의 코드';

  @override
  String get title => '중계 서버';

  @override
  String get description =>
      '같은 네트워크에 없을 때 직접 구축한 서버를 통해 파일을 전달합니다. 로컬 연결이 가능하면 항상 직접 연결합니다.';

  @override
  String get encryptionNotice =>
      '파일은 두 기기 사이에서 종단 간 암호화되며 페어링된 기기만 복호화할 수 있습니다. 서버는 전송 시각과 바이트 수만 볼 수 있습니다.';

  @override
  String get acceptPairingLabel => '중계를 통한 페어링 요청 수신 허용';

  @override
  String get acceptPairingHint =>
      '서버 토큰을 가진 기기는 누구나 이 기기 코드로 페어링을 요청할 수 있습니다. 한 번 거부한 기기는 다시 표시되지 않습니다.';

  @override
  String get iosForegroundNotice => 'iOS에서는 앱이 열려 있을 때만 중계로 파일을 받을 수 있습니다.';

  @override
  String get enableLabel => '중계 사용';

  @override
  String get serverUrlLabel => '서버 주소';

  @override
  String get tokenLabel => '접속 토큰';

  @override
  String get invalidUrl => '주소는 http:// 또는 https:// 로 시작해야 합니다';

  @override
  String get insecureUrlWarning =>
      'http:// 를 사용하면 트래픽이 암호화되지 않습니다. 로컬 테스트에만 사용하세요';

  @override
  String get testConnection => '연결 테스트';

  @override
  String get testSucceeded => '연결 성공';

  @override
  String get save => '저장';

  @override
  String get statusDisabled => '사용 안 함';

  @override
  String get statusConnecting => '연결 중';

  @override
  String get statusConnected => '연결됨';

  @override
  String get statusReconnecting => '다시 연결 중';

  @override
  String get statusRejected => '서버에서 거부됨';

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
  String get lanRouteUnavailable => '로컬 네트워크로 이 장치에 연결할 수 없습니다';

  @override
  String get relayRouteUnavailable => '중계 서버로 이 장치에 연결할 수 없습니다';

  @override
  String get relayNotConnected => '중계 서버에 연결되지 않음';

  @override
  String get relayPeerOffline => '상대방이 앱을 열어야 중계로 받을 수 있습니다';

  @override
  String get relayPeerNotPaired => '상대방이 이 장치를 신뢰 목록에 추가하지 않았습니다';

  @override
  String get relayPeerBusy => '상대방이 다른 파일 묶음을 처리하고 있습니다';

  @override
  String get relayNeedsPairedDevice => '중계 전송을 하려면 먼저 장치를 페어링해야 합니다';

  @override
  String get relayNegotiatingSession => '상대방과 암호화 세션을 설정하는 중…';

  @override
  String get relayIdentityMismatch =>
      '상대 장치의 서명이 유효하지 않습니다. 페어링한 장치가 아닐 수 있습니다';

  @override
  String get relayTransferNotice => '중계 서버를 통해 전송 중입니다. 속도는 서버 대역폭에 따라 제한됩니다';

  @override
  String retryingAfterInterruption(int attempt, int maxAttempts) {
    return '연결이 끊겨 다시 시도하는 중입니다 ($attempt/$maxAttempts)…';
  }
}
