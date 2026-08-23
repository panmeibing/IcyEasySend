/// Device pairing strings.
///
/// Pairing text lives here rather than in `AppLocalizations` because half of
/// it is needed without a `BuildContext`: the receiver's confirmation dialog
/// is triggered by an inbound HTTP request handled in the service layer, and
/// the failure reasons are produced by [PairingService] before any widget is
/// involved. Keeping both halves of one feature in a single place beats
/// splitting it across two mechanisms.
library;

import 'base_i18n_provider.dart';

class PairingMessages extends BaseI18nProvider {
  static final PairingMessages instance = PairingMessages._internal();

  factory PairingMessages() => instance;

  PairingMessages._internal();

  // Failure reasons

  String get peerUnreachable => getMessage({
    'zh': '无法连接到目标设备',
    'zh_HK': '無法連線到目標裝置',
    'ko': '대상 기기에 연결할 수 없습니다',
    'ja': '対象デバイスに接続できません',
    'fr': 'Impossible de joindre l\'appareil cible',
    'de': 'Zielgerät nicht erreichbar',
    'es': 'No se puede conectar con el dispositivo de destino',
    'pt': 'Não foi possível conectar ao dispositivo de destino',
    'ru': 'Не удалось подключиться к целевому устройству',
    'it': 'Impossibile raggiungere il dispositivo di destinazione',
    'nl': 'Kan geen verbinding maken met het doelapparaat',
    'en': 'Cannot reach the target device',
  });

  String get peerUnsupported => getMessage({
    'zh': '对方版本过旧，不支持设备配对',
    'zh_HK': '對方版本過舊，不支援裝置配對',
    'ko': '상대 기기의 버전이 오래되어 페어링을 지원하지 않습니다',
    'ja': '相手のバージョンが古く、ペアリングに対応していません',
    'fr': 'La version de l\'autre appareil est trop ancienne pour l\'appairage',
    'de': 'Die Version des anderen Geräts unterstützt keine Kopplung',
    'es': 'La versión del otro dispositivo no admite el emparejamiento',
    'pt': 'A versão do outro dispositivo não suporta emparelhamento',
    'ru': 'Версия другого устройства не поддерживает сопряжение',
    'it': 'La versione dell\'altro dispositivo non supporta l\'accoppiamento',
    'nl': 'De versie van het andere apparaat ondersteunt koppelen niet',
    'en': 'The other device runs a version without pairing support',
  });

  String get identityMismatch => getMessage({
    'zh': '对方设备码与公钥不匹配，已中止配对',
    'zh_HK': '對方裝置碼與公鑰不相符，已中止配對',
    'ko': '상대 기기 코드가 공개 키와 일치하지 않아 페어링을 중단했습니다',
    'ja': '相手のデバイスコードと公開鍵が一致しないため中止しました',
    'fr': 'Le code de l\'appareil ne correspond pas à sa clé publique, appairage annulé',
    'de': 'Gerätecode passt nicht zum öffentlichen Schlüssel, Kopplung abgebrochen',
    'es': 'El código del dispositivo no coincide con su clave pública; emparejamiento cancelado',
    'pt': 'O código do dispositivo não corresponde à sua chave pública; emparelhamento cancelado',
    'ru': 'Код устройства не соответствует его открытому ключу, сопряжение прервано',
    'it': 'Il codice del dispositivo non corrisponde alla chiave pubblica, accoppiamento annullato',
    'nl': 'De apparaatcode komt niet overeen met de publieke sleutel; koppelen afgebroken',
    'en': 'Device code does not match its public key, pairing aborted',
  });

  String get cannotPairSelf => getMessage({
    'zh': '不能与本机配对',
    'zh_HK': '不能與本機配對',
    'ko': '자기 자신과는 페어링할 수 없습니다',
    'ja': '自分自身とはペアリングできません',
    'fr': 'Impossible d\'appairer l\'appareil avec lui-même',
    'de': 'Ein Gerät kann sich nicht mit sich selbst koppeln',
    'es': 'No se puede emparejar el dispositivo consigo mismo',
    'pt': 'Não é possível emparelhar o dispositivo consigo mesmo',
    'ru': 'Нельзя выполнить сопряжение с самим собой',
    'it': 'Non è possibile accoppiare il dispositivo con se stesso',
    'nl': 'Een apparaat kan niet met zichzelf worden gekoppeld',
    'en': 'Cannot pair a device with itself',
  });

  // Confirmation dialog

  String get pairingTitle => getMessage({
    'zh': '设备配对',
    'zh_HK': '裝置配對',
    'ko': '기기 페어링',
    'ja': 'デバイスのペアリング',
    'fr': 'Appairage d\'appareils',
    'de': 'Gerätekopplung',
    'es': 'Emparejamiento de dispositivos',
    'pt': 'Emparelhamento de dispositivos',
    'ru': 'Сопряжение устройств',
    'it': 'Accoppiamento dispositivi',
    'nl': 'Apparaten koppelen',
    'en': 'Device Pairing',
  });

  String get compareHint => getMessage({
    'zh': '请确认两台设备显示的数字完全相同，再点击确认。数字不同说明连接可能被篡改。',
    'zh_HK': '請確認兩台裝置顯示的數字完全相同再確認。數字不同代表連線可能遭到竄改。',
    'ko': '두 기기에 표시된 숫자가 완전히 같은지 확인한 뒤 확인을 누르세요. 다르면 연결이 변조되었을 수 있습니다.',
    'ja': '両方のデバイスに表示された数字が完全に一致することを確認してください。異なる場合、接続が改ざんされている可能性があります。',
    'fr': 'Vérifiez que les deux appareils affichent exactement le même nombre. Sinon, la connexion a peut-être été altérée.',
    'de': 'Prüfen Sie, ob beide Geräte genau dieselbe Zahl anzeigen. Andernfalls wurde die Verbindung möglicherweise manipuliert.',
    'es': 'Comprueba que ambos dispositivos muestren exactamente el mismo número. Si no, la conexión puede haber sido manipulada.',
    'pt': 'Verifique se os dois dispositivos mostram exatamente o mesmo número. Caso contrário, a conexão pode ter sido adulterada.',
    'ru': 'Убедитесь, что на обоих устройствах отображается одно и то же число. Иначе соединение могло быть подменено.',
    'it': 'Verifica che entrambi i dispositivi mostrino esattamente lo stesso numero. In caso contrario la connessione potrebbe essere stata manomessa.',
    'nl': 'Controleer of beide apparaten exact hetzelfde getal tonen. Zo niet, dan is de verbinding mogelijk gemanipuleerd.',
    'en': 'Check that both devices show exactly the same number before confirming. A mismatch means the connection may have been tampered with.',
  });

  /// Replaces [compareHint] when the two devices are not on the same network.
  ///
  /// The instruction has to be different: there is no second screen to glance
  /// at, and a user who does not actually make the call has no protection at
  /// all against the relay substituting a key.
  String get compareHintRelay => getMessage({
    'zh': '这台设备不在同一局域网。请通过电话或语音与对方核对这 6 位数字，完全一致才能确认。不核对就确认等于没有任何保护。',
    'zh_HK': '這台裝置不在同一區域網路。請透過電話或語音與對方核對這 6 位數字，完全一致才可確認。不核對就確認等於沒有任何保護。',
    'ko': '같은 네트워크에 있지 않은 기기입니다. 전화나 음성으로 상대방과 6자리 숫자를 확인하고 완전히 같을 때만 확인하세요. 확인하지 않으면 아무런 보호가 없습니다.',
    'ja': '同じネットワークにないデバイスです。電話や音声通話で 6 桁の数字を相手と読み合わせ、完全に一致する場合のみ確認してください。確認しなければ保護は一切ありません。',
    'fr':
        'Cet appareil n\'est pas sur le même réseau. Comparez les 6 chiffres de vive voix avec l\'autre personne et ne confirmez qu\'en cas d\'identité parfaite. Sans cette vérification, il n\'y a aucune protection.',
    'de':
        'Dieses Gerät ist nicht im selben Netzwerk. Vergleichen Sie die 6 Ziffern per Telefon oder Sprachanruf und bestätigen Sie nur bei exakter Übereinstimmung. Ohne diesen Abgleich gibt es keinerlei Schutz.',
    'es':
        'Este dispositivo no está en la misma red. Compara los 6 dígitos por teléfono o voz y confirma solo si coinciden exactamente. Sin esa comprobación no hay ninguna protección.',
    'pt':
        'Este dispositivo não está na mesma rede. Compare os 6 dígitos por telefone ou voz e confirme apenas se forem idênticos. Sem essa conferência não há proteção alguma.',
    'ru':
        'Это устройство не в вашей сети. Сверьте 6 цифр с собеседником по телефону и подтверждайте только при полном совпадении. Без сверки защиты нет вообще.',
    'it':
        'Questo dispositivo non è sulla stessa rete. Confronta le 6 cifre a voce con l\'altra persona e conferma solo se coincidono esattamente. Senza questo confronto non c\'è alcuna protezione.',
    'nl':
        'Dit apparaat zit niet op hetzelfde netwerk. Vergelijk de 6 cijfers telefonisch met de ander en bevestig alleen bij een exacte match. Zonder die controle is er geen enkele bescherming.',
    'en':
        'This device is not on your network. Read the six digits to the other person by phone or voice and confirm only if they match exactly. Confirming without checking gives you no protection at all.',
  });

  String get pairOverRelay => getMessage({
    'zh': '通过中转配对',
    'zh_HK': '透過中轉配對',
    'ko': '중계로 페어링',
    'ja': '中継でペアリング',
    'fr': 'Appairer via le relais',
    'de': 'Über das Relay koppeln',
    'es': 'Emparejar por retransmisión',
    'pt': 'Emparelhar pela retransmissão',
    'ru': 'Сопряжение через ретранслятор',
    'it': 'Associa tramite relay',
    'nl': 'Koppelen via de relay',
    'en': 'Pair through the relay',
  });

  String get enterDeviceCode => getMessage({
    'zh': '输入对方的 32 位设备码',
    'zh_HK': '輸入對方的 32 位裝置碼',
    'ko': '상대방의 32자리 기기 코드를 입력하세요',
    'ja': '相手の 32 桁のデバイスコードを入力してください',
    'fr': 'Saisissez le code à 32 caractères de l\'autre appareil',
    'de': 'Geben Sie den 32-stelligen Gerätecode der Gegenstelle ein',
    'es': 'Introduce el código de 32 caracteres del otro dispositivo',
    'pt': 'Digite o código de 32 caracteres do outro dispositivo',
    'ru': 'Введите 32-значный код другого устройства',
    'it': 'Inserisci il codice a 32 caratteri dell\'altro dispositivo',
    'nl': 'Voer de 32-tekens apparaatcode van het andere apparaat in',
    'en': 'Enter the other device\'s 32-character code',
  });

  String get invalidDeviceCode => getMessage({
    'zh': '设备码应为 32 位十六进制字符',
    'zh_HK': '裝置碼應為 32 位十六進位字元',
    'ko': '기기 코드는 32자리 16진수여야 합니다',
    'ja': 'デバイスコードは 32 桁の 16 進数である必要があります',
    'fr': 'Le code doit comporter 32 caractères hexadécimaux',
    'de': 'Der Gerätecode muss aus 32 Hexadezimalzeichen bestehen',
    'es': 'El código debe tener 32 caracteres hexadecimales',
    'pt': 'O código deve ter 32 caracteres hexadecimais',
    'ru': 'Код устройства должен состоять из 32 шестнадцатеричных символов',
    'it': 'Il codice deve avere 32 caratteri esadecimali',
    'nl': 'De apparaatcode moet 32 hexadecimale tekens bevatten',
    'en': 'A device code is 32 hexadecimal characters',
  });

  String get alreadyPaired => getMessage({
    'zh': '该设备已在信任列表中',
    'zh_HK': '該裝置已在信任清單中',
    'ko': '이미 신뢰 목록에 있는 기기입니다',
    'ja': 'このデバイスはすでに信頼リストにあります',
    'fr': 'Cet appareil est déjà dans la liste de confiance',
    'de': 'Dieses Gerät ist bereits vertrauenswürdig',
    'es': 'Ese dispositivo ya está en la lista de confianza',
    'pt': 'Esse dispositivo já está na lista de confiança',
    'ru': 'Это устройство уже в списке доверенных',
    'it': 'Questo dispositivo è già tra quelli attendibili',
    'nl': 'Dit apparaat staat al in de vertrouwenslijst',
    'en': 'That device is already trusted',
  });

  /// Peer still has this device in their trust list (asymmetric unpair).
  String get peerAlreadyPaired => getMessage({
    'zh': '对方已信任过本机，请先在对方设备上取消配对',
    'en': 'The other device still trusts this one; unpair on that device first',
  });

  String get relayUnavailable => getMessage({
    'zh': '需要先连接中转服务器',
    'zh_HK': '需要先連線中轉伺服器',
    'ko': '먼저 중계 서버에 연결해야 합니다',
    'ja': '先に中継サーバーへ接続してください',
    'fr': 'Connectez d\'abord le serveur relais',
    'de': 'Zuerst mit dem Relay-Server verbinden',
    'es': 'Primero hay que conectar con el servidor de retransmisión',
    'pt': 'Conecte-se primeiro ao servidor de retransmissão',
    'ru': 'Сначала подключитесь к серверу ретрансляции',
    'it': 'Collegati prima al server relay',
    'nl': 'Maak eerst verbinding met de relayserver',
    'en': 'Connect to the relay server first',
  });

  String get peerBusy => getMessage({
    'zh': '对方正在处理另一个配对请求',
    'zh_HK': '對方正在處理另一個配對要求',
    'ko': '상대방이 다른 페어링 요청을 처리하고 있습니다',
    'ja': '相手は別のペアリング要求を処理中です',
    'fr': 'L\'autre appareil traite déjà une autre demande',
    'de': 'Die Gegenstelle bearbeitet bereits eine andere Anfrage',
    'es': 'El otro dispositivo está atendiendo otra solicitud',
    'pt': 'O outro dispositivo está tratando de outra solicitação',
    'ru': 'Устройство обрабатывает другой запрос сопряжения',
    'it': 'L\'altro dispositivo sta gestendo un\'altra richiesta',
    'nl': 'Het andere apparaat behandelt al een ander verzoek',
    'en': 'The other device is handling another pairing request',
  });

  String get peerPairingBlocked => getMessage({
    'zh': '对方已将本机加入黑名单，请联系对方移出后再试',
    'en': 'The other device has blocked this one; ask them to unblock it first',
  });

  String get peerRelayPairingOff => getMessage({
    'zh': '对方已关闭通过中转接收配对请求',
    'zh_HK': '對方已關閉透過中轉接收配對要求',
    'ko': '상대방이 중계 페어링 요청 수신을 껐습니다',
    'ja': '相手は中継経由のペアリング要求を無効にしています',
    'fr': 'L\'autre appareil n\'accepte pas les demandes via le relais',
    'de': 'Die Gegenstelle nimmt keine Kopplungsanfragen über das Relay an',
    'es': 'El otro dispositivo no acepta solicitudes por retransmisión',
    'pt': 'O outro dispositivo não aceita solicitações pela retransmissão',
    'ru': 'Устройство не принимает запросы сопряжения через ретранслятор',
    'it': 'L\'altro dispositivo non accetta richieste tramite relay',
    'nl': 'Het andere apparaat accepteert geen verzoeken via de relay',
    'en': 'The other device is not accepting pairing requests over the relay',
  });

  String incomingRequest(String deviceName) => getMessage({
    'zh': '「$deviceName」请求与本机配对',
    'zh_HK': '「$deviceName」要求與本機配對',
    'ko': '"$deviceName"이(가) 이 기기와 페어링을 요청했습니다',
    'ja': '「$deviceName」がこのデバイスとのペアリングを要求しています',
    'fr': '« $deviceName » demande à s\'appairer avec cet appareil',
    'de': '„$deviceName“ möchte sich mit diesem Gerät koppeln',
    'es': '«$deviceName» solicita emparejarse con este dispositivo',
    'pt': '"$deviceName" solicita emparelhamento com este dispositivo',
    'ru': '«$deviceName» запрашивает сопряжение с этим устройством',
    'it': '«$deviceName» chiede di accoppiarsi con questo dispositivo',
    'nl': '"$deviceName" wil koppelen met dit apparaat',
    'en': '"$deviceName" wants to pair with this device',
  });

  String outgoingRequest(String deviceName) => getMessage({
    'zh': '正在与「$deviceName」配对',
    'zh_HK': '正在與「$deviceName」配對',
    'ko': '"$deviceName"과(와) 페어링하는 중',
    'ja': '「$deviceName」とペアリングしています',
    'fr': 'Appairage avec « $deviceName »',
    'de': 'Kopplung mit „$deviceName“',
    'es': 'Emparejando con «$deviceName»',
    'pt': 'Emparelhando com "$deviceName"',
    'ru': 'Сопряжение с «$deviceName»',
    'it': 'Accoppiamento con «$deviceName»',
    'nl': 'Koppelen met "$deviceName"',
    'en': 'Pairing with "$deviceName"',
  });

  String get waitingPeer => getMessage({
    'zh': '等待对方确认…',
    'zh_HK': '等待對方確認…',
    'ko': '상대방의 확인을 기다리는 중…',
    'ja': '相手の確認を待っています…',
    'fr': 'En attente de confirmation…',
    'de': 'Warten auf Bestätigung…',
    'es': 'Esperando confirmación…',
    'pt': 'Aguardando confirmação…',
    'ru': 'Ожидание подтверждения…',
    'it': 'In attesa di conferma…',
    'nl': 'Wachten op bevestiging…',
    'en': 'Waiting for the other device…',
  });

  String get peerAccepted => getMessage({
    'zh': '对方已确认',
    'zh_HK': '對方已確認',
    'ko': '상대방이 확인했습니다',
    'ja': '相手が確認しました',
    'fr': 'L\'autre appareil a confirmé',
    'de': 'Das andere Gerät hat bestätigt',
    'es': 'El otro dispositivo ha confirmado',
    'pt': 'O outro dispositivo confirmou',
    'ru': 'Другое устройство подтвердило',
    'it': 'L\'altro dispositivo ha confermato',
    'nl': 'Het andere apparaat heeft bevestigd',
    'en': 'The other device confirmed',
  });

  String get peerRejected => getMessage({
    'zh': '对方拒绝了本次配对',
    'zh_HK': '對方拒絕了這次配對',
    'ko': '상대방이 페어링을 거부했습니다',
    'ja': '相手がペアリングを拒否しました',
    'fr': 'L\'autre appareil a refusé l\'appairage',
    'de': 'Das andere Gerät hat die Kopplung abgelehnt',
    'es': 'El otro dispositivo rechazó el emparejamiento',
    'pt': 'O outro dispositivo recusou o emparelhamento',
    'ru': 'Другое устройство отклонило сопряжение',
    'it': 'L\'altro dispositivo ha rifiutato l\'accoppiamento',
    'nl': 'Het andere apparaat heeft het koppelen geweigerd',
    'en': 'The other device rejected the pairing',
  });

  String get peerTimeout => getMessage({
    'zh': '对方未在规定时间内确认',
    'zh_HK': '對方未在時限內確認',
    'ko': '상대방이 제한 시간 내에 확인하지 않았습니다',
    'ja': '相手が時間内に確認しませんでした',
    'fr': 'L\'autre appareil n\'a pas confirmé à temps',
    'de': 'Das andere Gerät hat nicht rechtzeitig bestätigt',
    'es': 'El otro dispositivo no confirmó a tiempo',
    'pt': 'O outro dispositivo não confirmou a tempo',
    'ru': 'Другое устройство не подтвердило вовремя',
    'it': 'L\'altro dispositivo non ha confermato in tempo',
    'nl': 'Het andere apparaat heeft niet op tijd bevestigd',
    'en': 'The other device did not confirm in time',
  });

  String get pairingFailed => getMessage({
    'zh': '配对失败',
    'zh_HK': '配對失敗',
    'ko': '페어링 실패',
    'ja': 'ペアリングに失敗しました',
    'fr': 'Échec de l\'appairage',
    'de': 'Kopplung fehlgeschlagen',
    'es': 'Error de emparejamiento',
    'pt': 'Falha no emparelhamento',
    'ru': 'Сбой сопряжения',
    'it': 'Accoppiamento non riuscito',
    'nl': 'Koppelen mislukt',
    'en': 'Pairing failed',
  });

  String pairingSucceeded(String deviceName) => getMessage({
    'zh': '已与「$deviceName」完成配对',
    'zh_HK': '已與「$deviceName」完成配對',
    'ko': '"$deviceName"과(와) 페어링을 완료했습니다',
    'ja': '「$deviceName」とのペアリングが完了しました',
    'fr': 'Appairage avec « $deviceName » terminé',
    'de': 'Kopplung mit „$deviceName“ abgeschlossen',
    'es': 'Emparejamiento con «$deviceName» completado',
    'pt': 'Emparelhamento com "$deviceName" concluído',
    'ru': 'Сопряжение с «$deviceName» завершено',
    'it': 'Accoppiamento con «$deviceName» completato',
    'nl': 'Koppeling met "$deviceName" voltooid',
    'en': 'Paired with "$deviceName"',
  });

  String get codesMatch => getMessage({
    'zh': '数字一致，确认配对',
    'zh_HK': '數字相同，確認配對',
    'ko': '숫자가 같음, 페어링 확인',
    'ja': '数字が一致、ペアリングする',
    'fr': 'Les nombres correspondent, appairer',
    'de': 'Zahlen stimmen überein, koppeln',
    'es': 'Los números coinciden, emparejar',
    'pt': 'Os números coincidem, emparelhar',
    'ru': 'Числа совпадают, выполнить сопряжение',
    'it': 'I numeri coincidono, accoppia',
    'nl': 'Getallen komen overeen, koppelen',
    'en': 'Numbers match, pair',
  });

  String get codesDiffer => getMessage({
    'zh': '不一致，取消',
    'zh_HK': '不相同，取消',
    'ko': '다름, 취소',
    'ja': '一致しない、中止',
    'fr': 'Différents, annuler',
    'de': 'Unterschiedlich, abbrechen',
    'es': 'No coinciden, cancelar',
    'pt': 'Diferentes, cancelar',
    'ru': 'Не совпадают, отменить',
    'it': 'Diversi, annulla',
    'nl': 'Verschillend, annuleren',
    'en': 'They differ, cancel',
  });

  String get blockPeer => getMessage({
    'zh': '拉黑',
    'en': 'Block',
  });

  String get pairingBlocklistTitle => getMessage({
    'zh': '配对黑名单',
    'en': 'Pairing blocklist',
  });

  String get pairingBlocklistEmpty => getMessage({
    'zh': '黑名单为空',
    'en': 'No blocked devices',
  });

  String get pairingBlocklistManage => getMessage({
    'zh': '黑名单',
    'en': 'Blocklist',
  });

  String get unblockPeer => getMessage({
    'zh': '移出黑名单',
    'en': 'Unblock',
  });

  String unblockPeerConfirm(String name) => getMessage({
    'zh': '确定将「$name」移出黑名单？移出后对方可再次发起配对。',
    'en': 'Unblock "$name"? They will be able to request pairing again.',
  });

  // Trusted device list

  String get pairedDevicesTitle => getMessage({
    'zh': '已配对设备',
    'zh_HK': '已配對裝置',
    'ko': '페어링된 기기',
    'ja': 'ペアリング済みデバイス',
    'fr': 'Appareils appairés',
    'de': 'Gekoppelte Geräte',
    'es': 'Dispositivos emparejados',
    'pt': 'Dispositivos emparelhados',
    'ru': 'Сопряжённые устройства',
    'it': 'Dispositivi accoppiati',
    'nl': 'Gekoppelde apparaten',
    'en': 'Paired Devices',
  });

  String get pairedDevicesEmpty => getMessage({
    'zh': '还没有已配对的设备',
    'zh_HK': '尚未配對任何裝置',
    'ko': '페어링된 기기가 없습니다',
    'ja': 'ペアリング済みのデバイスはありません',
    'fr': 'Aucun appareil appairé',
    'de': 'Noch keine gekoppelten Geräte',
    'es': 'Aún no hay dispositivos emparejados',
    'pt': 'Ainda não há dispositivos emparelhados',
    'ru': 'Сопряжённых устройств пока нет',
    'it': 'Nessun dispositivo accoppiato',
    'nl': 'Nog geen gekoppelde apparaten',
    'en': 'No paired devices yet',
  });

  String get addPairedDevice => getMessage({
    'zh': '配对新设备',
    'zh_HK': '配對新裝置',
    'ko': '새 기기 페어링',
    'ja': '新しいデバイスをペアリング',
    'fr': 'Appairer un appareil',
    'de': 'Neues Gerät koppeln',
    'es': 'Emparejar un dispositivo',
    'pt': 'Emparelhar novo dispositivo',
    'ru': 'Сопрячь новое устройство',
    'it': 'Accoppia un dispositivo',
    'nl': 'Nieuw apparaat koppelen',
    'en': 'Pair a new device',
  });

  String get unpair => getMessage({
    'zh': '取消配对',
    'zh_HK': '取消配對',
    'ko': '페어링 해제',
    'ja': 'ペアリング解除',
    'fr': 'Dissocier',
    'de': 'Entkoppeln',
    'es': 'Desemparejar',
    'pt': 'Desemparelhar',
    'ru': 'Разорвать сопряжение',
    'it': 'Disaccoppia',
    'nl': 'Ontkoppelen',
    'en': 'Unpair',
  });

  String unpairConfirm(String deviceName) => getMessage({
    'zh': '移除「$deviceName」后，需要重新核对数字才能恢复信任。确定要移除吗？',
    'zh_HK': '移除「$deviceName」後，需要重新核對數字才能恢復信任。確定要移除嗎？',
    'ko': '"$deviceName"을(를) 제거하면 다시 숫자를 확인해야 신뢰를 복구할 수 있습니다. 제거할까요?',
    'ja': '「$deviceName」を削除すると、再度数字を照合するまで信頼は復元されません。削除しますか？',
    'fr': 'Après la suppression de « $deviceName », il faudra à nouveau comparer les nombres. Confirmer ?',
    'de': 'Nach dem Entfernen von „$deviceName“ müssen die Zahlen erneut verglichen werden. Fortfahren?',
    'es': 'Tras eliminar «$deviceName» habrá que volver a comparar los números. ¿Continuar?',
    'pt': 'Após remover "$deviceName" será preciso comparar os números novamente. Continuar?',
    'ru': 'После удаления «$deviceName» потребуется снова сверить числа. Продолжить?',
    'it': 'Dopo aver rimosso «$deviceName» sarà necessario confrontare di nuovo i numeri. Continuare?',
    'nl': 'Na het verwijderen van "$deviceName" moeten de getallen opnieuw worden vergeleken. Doorgaan?',
    'en': 'Removing "$deviceName" means comparing the numbers again to restore trust. Continue?',
  });

  String get deviceCodeLabel => getMessage({
    'zh': '本机设备码',
    'zh_HK': '本機裝置碼',
    'ko': '이 기기의 코드',
    'ja': 'このデバイスのコード',
    'fr': 'Code de cet appareil',
    'de': 'Code dieses Geräts',
    'es': 'Código de este dispositivo',
    'pt': 'Código deste dispositivo',
    'ru': 'Код этого устройства',
    'it': 'Codice di questo dispositivo',
    'nl': 'Code van dit apparaat',
    'en': 'This device\'s code',
  });

}
