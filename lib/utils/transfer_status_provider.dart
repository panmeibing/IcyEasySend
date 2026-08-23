/// Global transfer status message provider that supports internationalization
/// without requiring BuildContext.
///
/// This provider uses the current language setting from LanguageService
/// to return appropriate status messages for batch transfers.
library;

import 'base_i18n_provider.dart';

class TransferStatusProvider extends BaseI18nProvider {
  static final TransferStatusProvider _instance =
      TransferStatusProvider._internal();

  factory TransferStatusProvider() => _instance;

  TransferStatusProvider._internal();

  // Status messages
  String get checkingTargetDevice => getMessage({
    'zh': '正在检查目标设备...',
    'zh_HK': '正在檢查目標裝置...',
    'ko': '대상 장치 확인 중...',
    'ja': 'ターゲットデバイスを確認中...',
    'fr': 'Vérification de l\'appareil cible...',
    'de': 'Zielgerät wird überprüft...',
    'es': 'Comprobando dispositivo de destino...',
    'pt': 'Verificando dispositivo de destino...',
    'ru': 'Проверка целевого устройства...',
    'it': 'Verifica dispositivo di destinazione...',
    'nl': 'Doelapparaat controleren...',
    'en': 'Checking target device...',
  });

  String get preparingTransferInfo => getMessage({
    'zh': '准备传输信息...',
    'zh_HK': '準備傳輸資訊...',
    'ko': '전송 정보 준비 중...',
    'ja': '転送情報を準備中...',
    'fr': 'Préparation des informations de transfert...',
    'de': 'Übertragungsinformationen werden vorbereitet...',
    'es': 'Preparando información de transferencia...',
    'pt': 'Preparando informações de transferência...',
    'ru': 'Подготовка информации о передаче...',
    'it': 'Preparazione informazioni trasferimento...',
    'nl': 'Overdracht informatie voorbereiden...',
    'en': 'Preparing transfer info...',
  });

  String waitingForReceiverConfirmFiles(
    int count,
  ) => getMessageWith1Param<int>({
    'zh': (count) => '等待接收方确认 $count 个文件...',
    'zh_HK': (count) => '等待接收方確認 $count 個檔案...',
    'ko': (count) => '수신자가 $count개의 파일을 확인하기를 기다리는 중...',
    'ja': (count) => '受信者が$count個のファイルを確認するのを待っています...',
    'fr': (count) =>
        'En attente de confirmation de $count fichiers par le destinataire...',
    'de': (count) =>
        'Warte auf Bestätigung von $count Dateien durch Empfänger...',
    'es': (count) => 'Esperando que el receptor confirme $count archivos...',
    'pt': (count) =>
        'Aguardando confirmação de $count arquivos pelo destinatário...',
    'ru': (count) => 'Ожидание подтверждения $count файлов получателем...',
    'it': (count) => 'In attesa che il destinatario confermi $count file...',
    'nl': (count) => 'Wachten tot ontvanger $count bestanden bevestigt...',
    'en': (count) => 'Waiting for receiver to confirm $count files...',
  }, count);

  String transferringFile(int current, int total, String fileName) =>
      getMessageWith3Params<int, int, String>(
        {
          'zh': (current, total, fileName) =>
              '正在传输文件 $current/$total: $fileName',
          'zh_HK': (current, total, fileName) =>
              '正在傳輸檔案 $current/$total: $fileName',
          'ko': (current, total, fileName) =>
              '파일 전송 중 $current/$total: $fileName',
          'ja': (current, total, fileName) =>
              'ファイル転送中 $current/$total: $fileName',
          'fr': (current, total, fileName) =>
              'Transfert du fichier $current/$total: $fileName',
          'de': (current, total, fileName) =>
              'Datei wird übertragen $current/$total: $fileName',
          'es': (current, total, fileName) =>
              'Transfiriendo archivo $current/$total: $fileName',
          'pt': (current, total, fileName) =>
              'Transferindo arquivo $current/$total: $fileName',
          'ru': (current, total, fileName) =>
              'Передача файла $current/$total: $fileName',
          'it': (current, total, fileName) =>
              'Trasferimento file $current/$total: $fileName',
          'nl': (current, total, fileName) =>
              'Bestand overdragen $current/$total: $fileName',
          'en': (current, total, fileName) =>
              'Transferring file $current/$total: $fileName',
        },
        current,
        total,
        fileName,
      );

  // Error messages
  String targetDeviceError(String error) => getMessageWith1Param<String>({
    'zh': (error) => '目标设备不可用\n错误: $error',
    'zh_HK': (error) => '目標裝置不可用\n錯誤: $error',
    'ko': (error) => '대상 장치를 사용할 수 없음\n오류: $error',
    'ja': (error) => 'ターゲットデバイスが利用できません\nエラー: $error',
    'fr': (error) => 'Appareil cible indisponible\nErreur: $error',
    'de': (error) => 'Zielgerät nicht verfügbar\nFehler: $error',
    'es': (error) => 'Dispositivo de destino no disponible\nError: $error',
    'pt': (error) => 'Dispositivo de destino indisponível\nErro: $error',
    'ru': (error) => 'Целевое устройство недоступно\nОшибка: $error',
    'it': (error) =>
        'Dispositivo di destinazione non disponibile\nErrore: $error',
    'nl': (error) => 'Doelapparaat niet beschikbaar\nFout: $error',
    'en': (error) => 'Target device unavailable\nError: $error',
  }, error);

  String get lanRouteUnavailable => getMessage({
    'zh': '无法通过局域网访问该设备',
    'zh_HK': '無法透過區域網路存取該裝置',
    'ko': '로컬 네트워크로 이 장치에 연결할 수 없습니다',
    'ja': 'ローカルネットワークでこのデバイスに接続できません',
    'fr': 'Appareil inaccessible via le réseau local',
    'de': 'Gerät über das lokale Netzwerk nicht erreichbar',
    'es': 'No se puede acceder al dispositivo por la red local',
    'pt': 'Não é possível acessar o dispositivo pela rede local',
    'ru': 'Устройство недоступно по локальной сети',
    'it': 'Dispositivo non raggiungibile tramite la rete locale',
    'nl': 'Apparaat niet bereikbaar via het lokale netwerk',
    'en': 'Device is not reachable over the local network',
  });

  // Relay transfer status

  String get relayRouteUnavailable => getMessage({
    'zh': '无法通过中转服务器访问该设备',
    'zh_HK': '無法透過中轉伺服器存取該裝置',
    'ko': '중계 서버로 이 장치에 연결할 수 없습니다',
    'ja': '中継サーバー経由でこのデバイスに接続できません',
    'fr': 'Appareil inaccessible via le serveur relais',
    'de': 'Gerät über den Relay-Server nicht erreichbar',
    'es': 'No se puede acceder al dispositivo por el servidor de retransmisión',
    'pt': 'Não é possível acessar o dispositivo pelo servidor de retransmissão',
    'ru': 'Устройство недоступно через сервер ретрансляции',
    'it': 'Dispositivo non raggiungibile tramite il server relay',
    'nl': 'Apparaat niet bereikbaar via de relayserver',
    'en': 'Device is not reachable through the relay server',
  });

  /// Both the LAN and the relay were tried and neither could reach the peer.
  String get peerUnreachable => getMessage({
    'zh': '无法访问该设备（局域网与中转均不可达）',
    'zh_HK': '無法存取該裝置（區域網路與中轉均不可達）',
    'ko': '장치에 연결할 수 없습니다(로컬 네트워크와 중계 모두 불가)',
    'ja': 'このデバイスに接続できません（ローカルも中継も不可）',
    'fr': 'Appareil inaccessible (réseau local et relais)',
    'de': 'Gerät nicht erreichbar (weder lokal noch per Relay)',
    'es': 'Dispositivo inaccesible (red local y retransmisión)',
    'pt': 'Dispositivo inacessível (rede local e retransmissão)',
    'ru': 'Устройство недоступно (ни локально, ни через ретранслятор)',
    'it': 'Dispositivo non raggiungibile (né LAN né relay)',
    'nl': 'Apparaat niet bereikbaar (noch LAN noch relay)',
    'en': 'Device is unreachable over both LAN and relay',
  });

  String get relayNotConnected => getMessage({
    'zh': '未连接到中转服务器',
    'zh_HK': '未連線到中轉伺服器',
    'ko': '중계 서버에 연결되지 않음',
    'ja': '中継サーバーに接続していません',
    'fr': 'Non connecté au serveur relais',
    'de': 'Nicht mit dem Relay-Server verbunden',
    'es': 'No conectado al servidor de retransmisión',
    'pt': 'Não conectado ao servidor de retransmissão',
    'ru': 'Нет подключения к серверу ретрансляции',
    'it': 'Non connesso al server relay',
    'nl': 'Niet verbonden met de relayserver',
    'en': 'Not connected to the relay server',
  });

  /// Shown when the peer is a device that must have the app open to receive
  /// (decision D1 makes this the normal state of affairs on iOS).
  String get relayPeerOffline => getMessage({
    'zh': '对方设备需要打开应用才能通过中转接收',
    'zh_HK': '對方裝置需要開啟應用程式才能透過中轉接收',
    'ko': '상대방이 앱을 열어야 중계로 받을 수 있습니다',
    'ja': '相手がアプリを開かないと中継で受信できません',
    'fr': 'Le destinataire doit ouvrir l\'application pour recevoir via le relais',
    'de': 'Die Gegenstelle muss die App öffnen, um über das Relay zu empfangen',
    'es': 'El destinatario debe abrir la aplicación para recibir por retransmisión',
    'pt': 'O destinatário precisa abrir o aplicativo para receber pela retransmissão',
    'ru': 'Получатель должен открыть приложение, чтобы принять через ретрансляцию',
    'it': 'Il destinatario deve aprire l\'app per ricevere tramite relay',
    'nl': 'De ontvanger moet de app openen om via de relay te ontvangen',
    'en': 'The other device must have the app open to receive through the relay',
  });

  String get relayPeerNotPaired => getMessage({
    'zh': '对方设备没有把本设备加入信任列表',
    'zh_HK': '對方裝置沒有把本裝置加入信任清單',
    'ko': '상대방이 이 장치를 신뢰 목록에 추가하지 않았습니다',
    'ja': '相手がこのデバイスを信頼リストに追加していません',
    'fr': 'Le destinataire n\'a pas ajouté cet appareil à sa liste de confiance',
    'de': 'Die Gegenstelle hat dieses Gerät nicht als vertrauenswürdig eingetragen',
    'es': 'El destinatario no tiene este dispositivo en su lista de confianza',
    'pt': 'O destinatário não tem este dispositivo na lista de confiança',
    'ru': 'Получатель не добавил это устройство в список доверенных',
    'it': 'Il destinatario non ha questo dispositivo tra quelli attendibili',
    'nl': 'De ontvanger heeft dit apparaat niet in de vertrouwenslijst',
    'en': 'The other device has not added this one to its trusted list',
  });

  String get relayPeerBusy => getMessage({
    'zh': '对方正在处理另一批文件',
    'zh_HK': '對方正在處理另一批檔案',
    'ko': '상대방이 다른 파일 묶음을 처리하고 있습니다',
    'ja': '相手は別のファイルを処理中です',
    'fr': 'Le destinataire traite déjà un autre lot de fichiers',
    'de': 'Die Gegenstelle bearbeitet gerade einen anderen Stapel',
    'es': 'El destinatario está procesando otro lote de archivos',
    'pt': 'O destinatário está processando outro lote de arquivos',
    'ru': 'Получатель обрабатывает другую партию файлов',
    'it': 'Il destinatario sta elaborando un altro gruppo di file',
    'nl': 'De ontvanger verwerkt al een andere reeks bestanden',
    'en': 'The other device is busy with another batch',
  });

  String get relayNeedsPairedDevice => getMessage({
    'zh': '中转传输需要先与该设备配对',
    'zh_HK': '中轉傳輸需要先與該裝置配對',
    'ko': '중계 전송을 하려면 먼저 장치를 페어링해야 합니다',
    'ja': '中継転送には事前のペアリングが必要です',
    'fr': 'Le transfert par relais nécessite un appairage préalable',
    'de': 'Übertragung über das Relay erfordert eine vorherige Kopplung',
    'es': 'La transferencia por retransmisión requiere emparejar primero',
    'pt': 'A transferência por retransmissão exige emparelhamento prévio',
    'ru': 'Для передачи через ретрансляцию нужно сначала выполнить сопряжение',
    'it': 'Il trasferimento tramite relay richiede prima l\'associazione',
    'nl': 'Overdracht via de relay vereist eerst koppelen',
    'en': 'Relay transfer requires pairing with the device first',
  });

  /// Shown while the two devices agree on session keys, before anything about
  /// the files has left this device.
  String get relayNegotiatingSession => getMessage({
    'zh': '正在与对方建立加密会话…',
    'zh_HK': '正在與對方建立加密工作階段…',
    'ko': '상대방과 암호화 세션을 설정하는 중…',
    'ja': '相手と暗号化セッションを確立しています…',
    'fr': 'Établissement d\'une session chiffrée…',
    'de': 'Verschlüsselte Sitzung wird aufgebaut…',
    'es': 'Estableciendo una sesión cifrada…',
    'pt': 'Estabelecendo uma sessão criptografada…',
    'ru': 'Установка зашифрованного сеанса…',
    'it': 'Creazione di una sessione cifrata…',
    'nl': 'Versleutelde sessie opzetten…',
    'en': 'Establishing an encrypted session…',
  });

  /// Shown when the peer answers the handshake with a key that is not the one
  /// this device paired with.
  String get relayIdentityMismatch => getMessage({
    'zh': '对方设备的身份签名无效，可能不是已配对的设备',
    'zh_HK': '對方裝置的身分簽章無效，可能不是已配對的裝置',
    'ko': '상대 장치의 서명이 유효하지 않습니다. 페어링한 장치가 아닐 수 있습니다',
    'ja': '相手の署名が無効です。ペアリング済みのデバイスではない可能性があります',
    'fr': 'Signature invalide : ce n\'est peut-être pas l\'appareil appairé',
    'de': 'Ungültige Signatur; möglicherweise nicht das gekoppelte Gerät',
    'es': 'Firma no válida; puede no ser el dispositivo emparejado',
    'pt': 'Assinatura inválida; pode não ser o dispositivo emparelhado',
    'ru': 'Недействительная подпись: возможно, это не сопряжённое устройство',
    'it': 'Firma non valida: potrebbe non essere il dispositivo associato',
    'nl': 'Ongeldige handtekening; mogelijk niet het gekoppelde apparaat',
    'en': 'The peer\'s signature is invalid; it may not be the paired device',
  });

  /// Shown during the transfer so a slow relay is not mistaken for a freeze.
  String get relayTransferNotice => getMessage({
    'zh': '正在通过中转服务器传输，速度受服务器带宽限制',
    'zh_HK': '正在透過中轉伺服器傳輸，速度受伺服器頻寬限制',
    'ko': '중계 서버를 통해 전송 중입니다. 속도는 서버 대역폭에 따라 제한됩니다',
    'ja': '中継サーバー経由で転送中です。速度はサーバーの帯域に依存します',
    'fr': 'Transfert via le serveur relais, la vitesse dépend de sa bande passante',
    'de': 'Übertragung über den Relay-Server; die Geschwindigkeit hängt von dessen Bandbreite ab',
    'es': 'Transfiriendo por el servidor de retransmisión; la velocidad depende de su ancho de banda',
    'pt': 'Transferindo pelo servidor de retransmissão; a velocidade depende da banda dele',
    'ru': 'Передача через сервер ретрансляции, скорость ограничена его каналом',
    'it': 'Trasferimento tramite server relay, la velocità dipende dalla sua banda',
    'nl': 'Overdracht via de relayserver; de snelheid hangt af van de bandbreedte',
    'en': 'Transferring through the relay server; speed is limited by its bandwidth',
  });

  /// Shown between attempts, so a stalled progress bar has an explanation.
  String retryingAfterInterruption(int attempt, int maxAttempts) =>
      getMessageWith2Params<int, int>({
        'zh': (attempt, max) => '连接中断，正在重试（$attempt/$max）…',
        'zh_HK': (attempt, max) => '連線中斷，正在重試（$attempt/$max）…',
        'ko': (attempt, max) => '연결이 끊겨 다시 시도하는 중입니다 ($attempt/$max)…',
        'ja': (attempt, max) => '接続が切断されました。再試行中 ($attempt/$max)…',
        'fr': (attempt, max) =>
            'Connexion interrompue, nouvelle tentative ($attempt/$max)…',
        'de': (attempt, max) =>
            'Verbindung unterbrochen, neuer Versuch ($attempt/$max)…',
        'es': (attempt, max) =>
            'Conexión interrumpida, reintentando ($attempt/$max)…',
        'pt': (attempt, max) =>
            'Conexão interrompida, tentando novamente ($attempt/$max)…',
        'ru': (attempt, max) =>
            'Соединение прервано, повтор ($attempt/$max)…',
        'it': (attempt, max) =>
            'Connessione interrotta, nuovo tentativo ($attempt/$max)…',
        'nl': (attempt, max) =>
            'Verbinding verbroken, opnieuw proberen ($attempt/$max)…',
        'en': (attempt, max) =>
            'Connection interrupted, retrying ($attempt/$max)…',
      }, attempt, maxAttempts);

  String get receiverRejected => getMessage({
    'zh': '接收方拒绝接收',
    'zh_HK': '接收方拒絕接收',
    'ko': '수신자가 거부함',
    'ja': '受信者が拒否しました',
    'fr': 'Destinataire a refusé',
    'de': 'Empfänger hat abgelehnt',
    'es': 'Receptor rechazó',
    'pt': 'Destinatário rejeitou',
    'ru': 'Получатель отклонил',
    'it': 'Destinatario ha rifiutato',
    'nl': 'Ontvanger heeft geweigerd',
    'en': 'Receiver rejected',
  });

  String receiverRejectedWithStatus(int statusCode) =>
      getMessageWith1Param<int>({
        'zh': (statusCode) => '接收方拒绝接收\n状态码: $statusCode',
        'zh_HK': (statusCode) => '接收方拒絕接收\n狀態碼: $statusCode',
        'ko': (statusCode) => '수신자가 거부함\n상태 코드: $statusCode',
        'ja': (statusCode) => '受信者が拒否しました\nステータスコード: $statusCode',
        'fr': (statusCode) =>
            'Destinataire a refusé\nCode d\'état: $statusCode',
        'de': (statusCode) =>
            'Empfänger hat abgelehnt\nStatuscode: $statusCode',
        'es': (statusCode) => 'Receptor rechazó\nCódigo de estado: $statusCode',
        'pt': (statusCode) =>
            'Destinatário rejeitou\nCódigo de status: $statusCode',
        'ru': (statusCode) => 'Получатель отклонил\nКод состояния: $statusCode',
        'it': (statusCode) =>
            'Destinatario ha rifiutato\nCodice di stato: $statusCode',
        'nl': (statusCode) =>
            'Ontvanger heeft geweigerd\nStatuscode: $statusCode',
        'en': (statusCode) => 'Receiver rejected\nStatus code: $statusCode',
      }, statusCode);

  String get transferIdNotFound => getMessage({
    'zh': '未找到传输ID',
    'zh_HK': '未找到傳輸ID',
    'ko': '전송 ID를 찾을 수 없음',
    'ja': '転送IDが見つかりません',
    'fr': 'ID de transfert introuvable',
    'de': 'Übertragungs-ID nicht gefunden',
    'es': 'ID de transferencia no encontrado',
    'pt': 'ID de transferência não encontrado',
    'ru': 'ID передачи не найден',
    'it': 'ID trasferimento non trovato',
    'nl': 'Overdracht-ID niet gevonden',
    'en': 'Transfer ID not found',
  });

  // Batch receive status
  String get receiveComplete => getMessage({
    'zh': '接收完成',
    'zh_HK': '接收完成',
    'ko': '수신 완료',
    'ja': '受信完了',
    'fr': 'Réception terminée',
    'de': 'Empfang abgeschlossen',
    'es': 'Recepción completa',
    'pt': 'Recebimento concluído',
    'ru': 'Получение завершено',
    'it': 'Ricezione completata',
    'nl': 'Ontvangst voltooid',
    'en': 'Receive complete',
  });

  String receivingProgress(double progress) => getMessageWith1Param<double>({
    'zh': (progress) => '接收中... ${(progress * 100).toStringAsFixed(1)}%',
    'zh_HK': (progress) => '接收中... ${(progress * 100).toStringAsFixed(1)}%',
    'ko': (progress) => '수신 중... ${(progress * 100).toStringAsFixed(1)}%',
    'ja': (progress) => '受信中... ${(progress * 100).toStringAsFixed(1)}%',
    'fr': (progress) =>
        'Réception en cours... ${(progress * 100).toStringAsFixed(1)}%',
    'de': (progress) =>
        'Empfang läuft... ${(progress * 100).toStringAsFixed(1)}%',
    'es': (progress) => 'Recibiendo... ${(progress * 100).toStringAsFixed(1)}%',
    'pt': (progress) => 'Recebendo... ${(progress * 100).toStringAsFixed(1)}%',
    'ru': (progress) => 'Получение... ${(progress * 100).toStringAsFixed(1)}%',
    'it': (progress) =>
        'Ricezione in corso... ${(progress * 100).toStringAsFixed(1)}%',
    'nl': (progress) => 'Ontvangen... ${(progress * 100).toStringAsFixed(1)}%',
    'en': (progress) => 'Receiving... ${(progress * 100).toStringAsFixed(1)}%',
  }, progress);
}
