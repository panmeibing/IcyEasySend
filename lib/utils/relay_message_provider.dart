/// Relay server strings.
///
/// Kept out of `AppLocalizations` for the same reason as the pairing strings:
/// part of this text is produced in the service layer, where there is no
/// `BuildContext` to look a localization up from.
library;

import 'base_i18n_provider.dart';

class RelayMessages extends BaseI18nProvider {
  static final RelayMessages instance = RelayMessages._internal();

  factory RelayMessages() => instance;

  RelayMessages._internal();

  String get title => getMessage({
    'zh': '中转服务器',
    'zh_HK': '中轉伺服器',
    'ko': '중계 서버',
    'ja': '中継サーバー',
    'fr': 'Serveur relais',
    'de': 'Relay-Server',
    'es': 'Servidor de retransmisión',
    'pt': 'Servidor de retransmissão',
    'ru': 'Сервер ретрансляции',
    'it': 'Server relay',
    'nl': 'Relayserver',
    'en': 'Relay server',
  });

  String get description => getMessage({
    'zh': '不在同一局域网时，通过你自建的服务器转发文件。局域网可用时始终优先直连。',
    'zh_HK': '不在同一區域網路時，透過你自建的伺服器轉發檔案。區域網路可用時一律優先直連。',
    'ko': '같은 네트워크에 없을 때 직접 구축한 서버를 통해 파일을 전달합니다. 로컬 연결이 가능하면 항상 직접 연결합니다.',
    'ja': '同じネットワークにないとき、自分で立てたサーバー経由でファイルを転送します。ローカル接続が可能な場合は常に直接接続します。',
    'fr':
        'Transfère les fichiers via votre propre serveur quand les appareils ne sont pas sur le même réseau. La connexion directe reste prioritaire.',
    'de':
        'Leitet Dateien über Ihren eigenen Server weiter, wenn die Geräte nicht im selben Netzwerk sind. Direkte Verbindungen haben immer Vorrang.',
    'es':
        'Reenvía archivos a través de tu propio servidor cuando los dispositivos no están en la misma red. La conexión directa siempre tiene prioridad.',
    'pt':
        'Encaminha arquivos pelo seu próprio servidor quando os dispositivos não estão na mesma rede. A conexão direta sempre tem prioridade.',
    'ru':
        'Передаёт файлы через ваш собственный сервер, когда устройства не в одной сети. Прямое соединение всегда в приоритете.',
    'it':
        'Inoltra i file tramite il tuo server quando i dispositivi non sono sulla stessa rete. La connessione diretta ha sempre la precedenza.',
    'nl':
        'Stuurt bestanden door via je eigen server wanneer apparaten niet op hetzelfde netwerk zitten. Directe verbindingen krijgen altijd voorrang.',
    'en':
        'Forwards files through your own server when devices are not on the same network. A direct connection is always preferred.',
  });

  /// What the relay operator can and cannot see.
  ///
  /// Stated in terms of what is protected rather than "your files are safe":
  /// the operator does learn that two devices exchanged a certain number of
  /// bytes at a certain time, and pretending otherwise would be a lie.
  String get encryptionNotice => getMessage({
    'zh': '文件在两台设备之间端到端加密，只有已配对的设备能解密。服务器只能看到传输时间和字节数。',
    'zh_HK': '檔案在兩台裝置之間端對端加密，只有已配對的裝置能解密。伺服器只能看到傳輸時間與位元組數。',
    'ko': '파일은 두 기기 사이에서 종단 간 암호화되며 페어링된 기기만 복호화할 수 있습니다. 서버는 전송 시각과 바이트 수만 볼 수 있습니다.',
    'ja': 'ファイルは 2 台のデバイス間でエンドツーエンド暗号化され、ペアリング済みのデバイスだけが復号できます。サーバーが分かるのは転送時刻とバイト数だけです。',
    'fr':
        'Les fichiers sont chiffrés de bout en bout entre les deux appareils appairés, seuls eux peuvent les déchiffrer. Le serveur ne voit que l\'horodatage et le nombre d\'octets.',
    'de':
        'Dateien sind zwischen den beiden gekoppelten Geräten Ende-zu-Ende verschlüsselt; nur sie können entschlüsseln. Der Server sieht lediglich Zeitpunkt und Byteanzahl.',
    'es':
        'Los archivos van cifrados de extremo a extremo entre los dos dispositivos emparejados; solo ellos pueden descifrarlos. El servidor solo ve la hora y el número de bytes.',
    'pt':
        'Os arquivos são criptografados de ponta a ponta entre os dois dispositivos emparelhados; só eles conseguem descriptografar. O servidor vê apenas o horário e a quantidade de bytes.',
    'ru':
        'Файлы шифруются сквозным образом между двумя сопряжёнными устройствами, расшифровать их может только получатель. Сервер видит лишь время передачи и объём.',
    'it':
        'I file sono cifrati end-to-end tra i due dispositivi associati e solo loro possono decifrarli. Il server vede soltanto l\'orario e il numero di byte.',
    'nl':
        'Bestanden zijn end-to-end versleuteld tussen de twee gekoppelde apparaten; alleen zij kunnen ontsleutelen. De server ziet alleen het tijdstip en het aantal bytes.',
    'en':
        'Files are end-to-end encrypted between the two paired devices, and only they can decrypt them. The server sees only when a transfer happened and how many bytes it carried.',
  });

  String get acceptPairingLabel => getMessage({
    'zh': '允许通过中转接收配对请求',
    'zh_HK': '允許透過中轉接收配對要求',
    'ko': '중계를 통한 페어링 요청 수신 허용',
    'ja': '中継経由のペアリング要求を受け取る',
    'fr': 'Accepter les demandes d\'appairage via le relais',
    'de': 'Kopplungsanfragen über das Relay annehmen',
    'es': 'Aceptar solicitudes de emparejamiento por retransmisión',
    'pt': 'Aceitar solicitações de emparelhamento pela retransmissão',
    'ru': 'Принимать запросы сопряжения через ретранслятор',
    'it': 'Accetta richieste di associazione tramite relay',
    'nl': 'Koppelverzoeken via de relay accepteren',
    'en': 'Accept pairing requests over the relay',
  });

  String get acceptPairingHint => getMessage({
    'zh': '任何持有服务器令牌的设备都能向你的设备码发起配对请求。被你拒绝过的设备不会再次弹窗。',
    'zh_HK': '任何持有伺服器權杖的裝置都能向你的裝置碼發起配對要求。被你拒絕過的裝置不會再次彈出視窗。',
    'ko': '서버 토큰을 가진 기기는 누구나 이 기기 코드로 페어링을 요청할 수 있습니다. 한 번 거부한 기기는 다시 표시되지 않습니다.',
    'ja': 'サーバートークンを持つデバイスなら誰でもあなたのデバイスコード宛にペアリングを要求できます。一度拒否した相手は再表示されません。',
    'fr':
        'Tout appareil disposant du jeton du serveur peut solliciter votre code d\'appareil. Un appareil refusé ne réapparaît plus.',
    'de':
        'Jedes Gerät mit dem Servertoken kann eine Anfrage an Ihren Gerätecode senden. Einmal abgelehnte Geräte fragen nicht erneut.',
    'es':
        'Cualquier dispositivo con el token del servidor puede solicitar emparejarse con tu código. Un dispositivo rechazado no vuelve a aparecer.',
    'pt':
        'Qualquer dispositivo com o token do servidor pode solicitar emparelhamento com o seu código. Um dispositivo recusado não aparece de novo.',
    'ru':
        'Любое устройство с токеном сервера может запросить сопряжение с вашим кодом. Отклонённое устройство больше не появится.',
    'it':
        'Qualsiasi dispositivo con il token del server può richiedere l\'associazione al tuo codice. Un dispositivo rifiutato non si ripresenta.',
    'nl':
        'Elk apparaat met het servertoken kan een verzoek naar jouw apparaatcode sturen. Een geweigerd apparaat verschijnt niet opnieuw.',
    'en':
        'Any device holding the server token can send a request to your device code. A device you turn down will not ask again.',
  });

  /// Decision D1 made visible, so users do not report it as a bug.
  String get iosForegroundNotice => getMessage({
    'zh': '在 iOS 上仅在应用打开时可以通过中转接收文件。',
    'zh_HK': '在 iOS 上僅在應用程式開啟時可以透過中轉接收檔案。',
    'ko': 'iOS에서는 앱이 열려 있을 때만 중계로 파일을 받을 수 있습니다.',
    'ja': 'iOS ではアプリを開いているときのみ中継で受信できます。',
    'fr':
        'Sur iOS, la réception via le relais ne fonctionne que lorsque l\'application est ouverte.',
    'de':
        'Unter iOS ist der Empfang über das Relay nur bei geöffneter App möglich.',
    'es':
        'En iOS solo se pueden recibir archivos por retransmisión con la aplicación abierta.',
    'pt':
        'No iOS só é possível receber pela retransmissão com o aplicativo aberto.',
    'ru':
        'На iOS приём через ретрансляцию работает только при открытом приложении.',
    'it':
        'Su iOS la ricezione tramite relay funziona solo con l\'app aperta.',
    'nl':
        'Op iOS kun je alleen ontvangen via de relay wanneer de app geopend is.',
    'en':
        'On iOS, receiving through the relay only works while the app is open.',
  });

  String get enableLabel => getMessage({
    'zh': '启用中转',
    'zh_HK': '啟用中轉',
    'ko': '중계 사용',
    'ja': '中継を有効にする',
    'fr': 'Activer le relais',
    'de': 'Relay aktivieren',
    'es': 'Activar retransmisión',
    'pt': 'Ativar retransmissão',
    'ru': 'Включить ретрансляцию',
    'it': 'Attiva il relay',
    'nl': 'Relay inschakelen',
    'en': 'Enable relay',
  });

  String get serverUrlLabel => getMessage({
    'zh': '服务器地址',
    'zh_HK': '伺服器位址',
    'ko': '서버 주소',
    'ja': 'サーバーアドレス',
    'fr': 'Adresse du serveur',
    'de': 'Serveradresse',
    'es': 'Dirección del servidor',
    'pt': 'Endereço do servidor',
    'ru': 'Адрес сервера',
    'it': 'Indirizzo del server',
    'nl': 'Serveradres',
    'en': 'Server address',
  });

  String get tokenLabel => getMessage({
    'zh': '接入令牌',
    'zh_HK': '接入權杖',
    'ko': '접속 토큰',
    'ja': 'アクセストークン',
    'fr': 'Jeton d\'accès',
    'de': 'Zugangstoken',
    'es': 'Token de acceso',
    'pt': 'Token de acesso',
    'ru': 'Токен доступа',
    'it': 'Token di accesso',
    'nl': 'Toegangstoken',
    'en': 'Access token',
  });

  String get invalidUrl => getMessage({
    'zh': '地址需要以 http:// 或 https:// 开头',
    'zh_HK': '位址需要以 http:// 或 https:// 開頭',
    'ko': '주소는 http:// 또는 https:// 로 시작해야 합니다',
    'ja': 'アドレスは http:// または https:// で始まる必要があります',
    'fr': 'L\'adresse doit commencer par http:// ou https://',
    'de': 'Die Adresse muss mit http:// oder https:// beginnen',
    'es': 'La dirección debe empezar por http:// o https://',
    'pt': 'O endereço deve começar com http:// ou https://',
    'ru': 'Адрес должен начинаться с http:// или https://',
    'it': 'L\'indirizzo deve iniziare con http:// o https://',
    'nl': 'Het adres moet beginnen met http:// of https://',
    'en': 'The address must start with http:// or https://',
  });

  /// Shown when the user points the app at a plain-HTTP relay.
  String get insecureUrlWarning => getMessage({
    'zh': '使用 http:// 时流量不加密，仅适合本机调试',
    'zh_HK': '使用 http:// 時流量不加密，僅適合本機除錯',
    'ko': 'http:// 를 사용하면 트래픽이 암호화되지 않습니다. 로컬 테스트에만 사용하세요',
    'ja': 'http:// では通信が暗号化されません。ローカル検証のみに使用してください',
    'fr':
        'Le trafic n\'est pas chiffré avec http://, à réserver aux tests locaux',
    'de':
        'Mit http:// ist der Verkehr unverschlüsselt, nur für lokale Tests geeignet',
    'es':
        'Con http:// el tráfico no va cifrado, úsalo solo para pruebas locales',
    'pt': 'Com http:// o tráfego não é criptografado, use só em testes locais',
    'ru': 'С http:// трафик не шифруется, только для локальной отладки',
    'it': 'Con http:// il traffico non è cifrato, usalo solo in locale',
    'nl': 'Met http:// is het verkeer onversleuteld, alleen voor lokale tests',
    'en': 'Traffic is unencrypted over http://, use it only for local testing',
  });

  String get testConnection => getMessage({
    'zh': '测试连接',
    'zh_HK': '測試連線',
    'ko': '연결 테스트',
    'ja': '接続をテスト',
    'fr': 'Tester la connexion',
    'de': 'Verbindung testen',
    'es': 'Probar conexión',
    'pt': 'Testar conexão',
    'ru': 'Проверить подключение',
    'it': 'Prova connessione',
    'nl': 'Verbinding testen',
    'en': 'Test connection',
  });

  String get testSucceeded => getMessage({
    'zh': '连接成功',
    'zh_HK': '連線成功',
    'ko': '연결 성공',
    'ja': '接続に成功しました',
    'fr': 'Connexion réussie',
    'de': 'Verbindung erfolgreich',
    'es': 'Conexión correcta',
    'pt': 'Conexão bem-sucedida',
    'ru': 'Подключение выполнено',
    'it': 'Connessione riuscita',
    'nl': 'Verbinding geslaagd',
    'en': 'Connected successfully',
  });

  String get save => getMessage({
    'zh': '保存',
    'zh_HK': '儲存',
    'ko': '저장',
    'ja': '保存',
    'fr': 'Enregistrer',
    'de': 'Speichern',
    'es': 'Guardar',
    'pt': 'Salvar',
    'ru': 'Сохранить',
    'it': 'Salva',
    'nl': 'Opslaan',
    'en': 'Save',
  });

  String get saved => getMessage({
    'zh': '中转设置已保存',
    'zh_HK': '中轉設定已儲存',
    'ko': '중계 설정이 저장되었습니다',
    'ja': '中継設定を保存しました',
    'fr': 'Paramètres du relais enregistrés',
    'de': 'Relay-Einstellungen gespeichert',
    'es': 'Ajustes de retransmisión guardados',
    'pt': 'Configurações de retransmissão salvas',
    'ru': 'Настройки ретрансляции сохранены',
    'it': 'Impostazioni del relay salvate',
    'nl': 'Relayinstellingen opgeslagen',
    'en': 'Relay settings saved',
  });

  String get saveFailed => getMessage({
    'zh': '保存失败',
    'zh_HK': '儲存失敗',
    'ko': '저장 실패',
    'ja': '保存失敗',
    'fr': 'Échec de l\'enregistrement',
    'de': 'Speichern fehlgeschlagen',
    'es': 'Error al guardar',
    'pt': 'Falha ao salvar',
    'ru': 'Не удалось сохранить',
    'it': 'Salvataggio fallito',
    'nl': 'Opslaan mislukt',
    'en': 'Save failed',
  });

  String get statusDisabled => getMessage({
    'zh': '未启用',
    'zh_HK': '未啟用',
    'ko': '사용 안 함',
    'ja': '無効',
    'fr': 'Désactivé',
    'de': 'Deaktiviert',
    'es': 'Desactivado',
    'pt': 'Desativado',
    'ru': 'Выключено',
    'it': 'Disattivato',
    'nl': 'Uitgeschakeld',
    'en': 'Off',
  });

  String get statusConnecting => getMessage({
    'zh': '连接中',
    'zh_HK': '連線中',
    'ko': '연결 중',
    'ja': '接続中',
    'fr': 'Connexion…',
    'de': 'Verbinden…',
    'es': 'Conectando…',
    'pt': 'Conectando…',
    'ru': 'Подключение…',
    'it': 'Connessione…',
    'nl': 'Verbinden…',
    'en': 'Connecting',
  });

  String get statusConnected => getMessage({
    'zh': '已连接',
    'zh_HK': '已連線',
    'ko': '연결됨',
    'ja': '接続済み',
    'fr': 'Connecté',
    'de': 'Verbunden',
    'es': 'Conectado',
    'pt': 'Conectado',
    'ru': 'Подключено',
    'it': 'Connesso',
    'nl': 'Verbonden',
    'en': 'Connected',
  });

  String get statusReconnecting => getMessage({
    'zh': '正在重连',
    'zh_HK': '正在重新連線',
    'ko': '다시 연결 중',
    'ja': '再接続中',
    'fr': 'Reconnexion…',
    'de': 'Erneut verbinden…',
    'es': 'Reconectando…',
    'pt': 'Reconectando…',
    'ru': 'Переподключение…',
    'it': 'Riconnessione…',
    'nl': 'Opnieuw verbinden…',
    'en': 'Reconnecting',
  });

  String get statusRejected => getMessage({
    'zh': '被服务器拒绝',
    'zh_HK': '被伺服器拒絕',
    'ko': '서버에서 거부됨',
    'ja': 'サーバーに拒否されました',
    'fr': 'Refusé par le serveur',
    'de': 'Vom Server abgelehnt',
    'es': 'Rechazado por el servidor',
    'pt': 'Rejeitado pelo servidor',
    'ru': 'Отклонено сервером',
    'it': 'Rifiutato dal server',
    'nl': 'Geweigerd door de server',
    'en': 'Rejected by the server',
  });

  String get clipboardNeedsPairing => getMessage({
    'zh': '需要先与对方设备配对',
    'en': 'Pair with the device first',
  });

  String get clipboardRelayUnavailable => getMessage({
    'zh': '未连接到中转服务器',
    'en': 'Not connected to the relay server',
  });

  String get clipboardPeerOffline => getMessage({
    'zh': '对方设备当前不在中转服务器上',
    'en': 'The peer is not online on the relay',
  });

  String get clipboardFailed => getMessage({
    'zh': '通过中转同步剪切板失败',
    'en': 'Clipboard sync over the relay failed',
  });

  String get clipboardPeerNoUi => getMessage({
    'zh': '对方设备当前无法确认请求',
    'en': 'The peer cannot confirm the request right now',
  });

  String get clipboardPeerBusy => getMessage({
    'zh': '对方设备正忙，请稍后再试',
    'en': 'The peer is busy, try again later',
  });

  String get clipboardEmpty => getMessage({
    'zh': '对方剪切板为空',
    'en': 'The peer\'s clipboard is empty',
  });

  String get clipboardTooLargeForRelay => getMessage({
    'zh': '剪切板内容超过设置的大小上限',
    'en': 'Clipboard content exceeds the configured size limit',
  });

  String get clipboardStreamFailed => getMessage({
    'zh': '通过中转拉取剪切板数据失败',
    'en': 'Failed to fetch clipboard data over the relay stream',
  });

  String get clipboardPeerTimeout => getMessage({
    'zh': '对方没有响应剪切板请求',
    'en': 'The peer did not answer the clipboard request',
  });

  String get clipboardDeclined => getMessage({
    'zh': '对方拒绝了剪切板请求',
    'en': 'The peer declined the clipboard request',
  });

  String selectedRelayPeer(String name) => getMessage({
    'zh': '已选择中转设备：$name',
    'en': 'Selected relay peer: $name',
  });

  String get clearSelectedPeer => getMessage({
    'zh': '清除选择',
    'en': 'Clear selection',
  });
}
