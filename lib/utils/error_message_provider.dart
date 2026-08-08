/// Global error message provider that supports internationalization
/// without requiring BuildContext.
///
/// This provider uses the current language setting from LanguageService
/// to return appropriate error messages.
library;

import 'base_i18n_provider.dart';
import 'constants.dart';

class ErrorMessageProvider extends BaseI18nProvider {
  static final ErrorMessageProvider _instance =
      ErrorMessageProvider._internal();

  factory ErrorMessageProvider() => _instance;

  ErrorMessageProvider._internal();

  // Network errors
  String get networkConnectionFailed => getMessage({
    'zh': '无法连接到目标设备，请检查网络连接和 IP 地址',
    'zh_HK': '無法連線到目標裝置，請檢查網路連線和 IP 位址',
    'ko': '대상 기기에 연결할 수 없습니다. 네트워크 연결과 IP 주소를 확인하세요',
    'ja': 'ターゲットデバイスに接続できません。ネットワーク接続とIPアドレスを確認してください',
    'fr':
        'Impossible de se connecter à l\'appareil cible, veuillez vérifier la connexion réseau et l\'adresse IP',
    'de':
        'Verbindung zum Zielgerät nicht möglich, bitte überprüfen Sie die Netzwerkverbindung und die IP-Adresse',
    'es':
        'No se puede conectar al dispositivo de destino, por favor verifique la conexión de red y la dirección IP',
    'pt':
        'Não é possível conectar ao dispositivo de destino, verifique a conexão de rede e o endereço IP',
    'ru':
        'Невозможно подключиться к целевому устройству, проверьте сетевое подключение и IP-адрес',
    'it':
        'Impossibile connettersi al dispositivo di destinazione, verificare la connessione di rete e l\'indirizzo IP',
    'nl':
        'Kan geen verbinding maken met doelapparaat, controleer netwerkverbinding en IP-adres',
    'en':
        'Unable to connect to target device, please check network connection and IP address',
  });

  String get networkTimeout => getMessage({
    'zh': '连接超时，目标设备可能不在线或网络不稳定',
    'zh_HK': '連線逾時，目標裝置可能不在線上或網路不穩定',
    'ko': '연결 시간 초과. 대상 기기가 오프라인이거나 네트워크가 불안정할 수 있습니다',
    'ja': '接続タイムアウト、ターゲットデバイスがオフラインまたはネットワークが不安定な可能性があります',
    'fr':
        'Délai de connexion dépassé, l\'appareil cible peut être hors ligne ou le réseau est instable',
    'de':
        'Verbindungszeitüberschreitung, Zielgerät ist möglicherweise offline oder Netzwerk ist instabil',
    'es':
        'Tiempo de espera de conexión agotado, el dispositivo de destino puede estar fuera de línea o la red es inestable',
    'pt':
        'Tempo de conexão esgotado, o dispositivo de destino pode estar offline ou a rede está instável',
    'ru':
        'Время подключения истекло, целевое устройство может быть не в сети или сеть нестабильна',
    'it':
        'Timeout di connessione, il dispositivo di destinazione potrebbe essere offline o la rete è instabile',
    'nl':
        'Verbindingstime-out, doelapparaat is mogelijk offline of netwerk is instabiel',
    'en':
        'Connection timeout, target device may be offline or network is unstable',
  });

  String get networkRequestFailed => getMessage({
    'zh': '网络请求失败，请检查网络连接',
    'zh_HK': '網路請求失敗，請檢查網路連線',
    'ko': '네트워크 요청 실패. 네트워크 연결을 확인하세요',
    'ja': 'ネットワークリクエストが失敗しました。ネットワーク接続を確認してください',
    'fr': 'Échec de la requête réseau, veuillez vérifier la connexion réseau',
    'de':
        'Netzwerkanfrage fehlgeschlagen, bitte überprüfen Sie die Netzwerkverbindung',
    'es': 'Solicitud de red fallida, por favor verifique la conexión de red',
    'pt': 'Falha na solicitação de rede, verifique a conexão de rede',
    'ru': 'Сбой сетевого запроса, проверьте сетевое подключение',
    'it': 'Richiesta di rete fallita, verificare la connessione di rete',
    'nl': 'Netwerkverzoek mislukt, controleer netwerkverbinding',
    'en': 'Network request failed, please check network connection',
  });

  String get targetDeviceUnavailable => getMessage({
    'zh': '目标设备不可用，请确认设备在线且 IP 地址正确',
    'zh_HK': '目標裝置不可用，請確認裝置在線上且 IP 位址正確',
    'ko': '대상 기기를 사용할 수 없습니다. 기기가 온라인 상태이고 IP 주소가 올바른지 확인하세요',
    'ja': 'ターゲットデバイスが利用できません。デバイスがオンラインでIPアドレスが正しいことを確認してください',
    'fr':
        'Appareil cible indisponible, veuillez confirmer que l\'appareil est en ligne et que l\'adresse IP est correcte',
    'de':
        'Zielgerät nicht verfügbar, bitte bestätigen Sie, dass das Gerät online ist und die IP-Adresse korrekt ist',
    'es':
        'Dispositivo de destino no disponible, por favor confirme que el dispositivo está en línea y la dirección IP es correcta',
    'pt':
        'Dispositivo de destino indisponível, confirme que o dispositivo está online e o endereço IP está correto',
    'ru':
        'Целевое устройство недоступно, подтвердите, что устройство в сети и IP-адрес правильный',
    'it':
        'Dispositivo di destinazione non disponibile, confermare che il dispositivo è online e l\'indirizzo IP è corretto',
    'nl':
        'Doelapparaat niet beschikbaar, bevestig dat apparaat online is en IP-adres correct is',
    'en':
        'Target device unavailable, please confirm device is online and IP address is correct',
  });

  String get transferTimeout => getMessage({
    'zh': '传输超时，请检查网络连接',
    'zh_HK': '傳輸逾時，請檢查網路連線',
    'ko': '전송 시간 초과. 네트워크 연결을 확인하세요',
    'ja': '転送タイムアウト、ネットワーク接続を確認してください',
    'fr': 'Délai de transfert dépassé, veuillez vérifier la connexion réseau',
    'de':
        'Übertragungszeitüberschreitung, bitte überprüfen Sie die Netzwerkverbindung',
    'es':
        'Tiempo de espera de transferencia agotado, por favor verifique la conexión de red',
    'pt': 'Tempo de transferência esgotado, verifique a conexão de rede',
    'ru': 'Время передачи истекло, проверьте сетевое подключение',
    'it': 'Timeout di trasferimento, verificare la connessione di rete',
    'nl': 'Overdracht time-out, controleer netwerkverbinding',
    'en': 'Transfer timeout, please check network connection',
  });

  String get transferInterrupted => getMessage({
    'zh': '传输中断，请重试',
    'zh_HK': '傳輸中斷，請重試',
    'ko': '전송이 중단되었습니다. 다시 시도하세요',
    'ja': '転送が中断されました。再試行してください',
    'fr': 'Transfert interrompu, veuillez réessayer',
    'de': 'Übertragung unterbrochen, bitte erneut versuchen',
    'es': 'Transferencia interrumpida, por favor reintente',
    'pt': 'Transferência interrompida, tente novamente',
    'ru': 'Передача прервана, повторите попытку',
    'it': 'Trasferimento interrotto, riprovare',
    'nl': 'Overdracht onderbroken, probeer opnieuw',
    'en': 'Transfer interrupted, please retry',
  });

  // File system errors
  String get fileNotFound => getMessage({
    'zh': '文件不存在',
    'zh_HK': '檔案不存在',
    'ko': '파일을 찾을 수 없습니다',
    'ja': 'ファイルが見つかりません',
    'fr': 'Fichier introuvable',
    'de': 'Datei nicht gefunden',
    'es': 'Archivo no encontrado',
    'pt': 'Arquivo não existe',
    'ru': 'Файл не найден',
    'it': 'File non trovato',
    'nl': 'Bestand niet gevonden',
    'en': 'File not found',
  });

  String get fileNotReadable => getMessage({
    'zh': '无法读取文件，请确保文件存在且有访问权限',
    'zh_HK': '無法讀取檔案，請確保檔案存在且有存取權限',
    'ko': '파일을 읽을 수 없습니다. 파일이 존재하고 액세스 권한이 있는지 확인하세요',
    'ja': 'ファイルを読み取れません。ファイルが存在し、アクセス権限があることを確認してください',
    'fr':
        'Impossible de lire le fichier, veuillez vous assurer que le fichier existe et dispose des autorisations d\'accès',
    'de':
        'Datei kann nicht gelesen werden, bitte stellen Sie sicher, dass die Datei existiert und Zugriffsrechte hat',
    'es':
        'No se puede leer el archivo, por favor asegúrese de que el archivo existe y tiene permisos de acceso',
    'pt':
        'Não é possível ler o arquivo, certifique-se de que o arquivo existe e tem permissão de acesso',
    'ru':
        'Невозможно прочитать файл, убедитесь, что файл существует и имеет права доступа',
    'it':
        'Impossibile leggere il file, assicurarsi che il file esista e abbia i permessi di accesso',
    'nl':
        'Kan bestand niet lezen, zorg ervoor dat bestand bestaat en toegangsrechten heeft',
    'en':
        'Unable to read file, please ensure file exists and has access permission',
  });

  String get fileAccessError => getMessage({
    'zh': '文件访问错误，请检查文件权限',
    'zh_HK': '檔案存取錯誤，請檢查檔案權限',
    'ko': '파일 액세스 오류, 파일 권한을 확인하세요',
    'ja': 'ファイルアクセスエラー、ファイル権限を確認してください',
    'fr':
        'Erreur d\'accès au fichier, veuillez vérifier les autorisations du fichier',
    'de': 'Dateizugriffsfehler, bitte überprüfen Sie die Dateiberechtigungen',
    'es':
        'Error de acceso al archivo, por favor verifique los permisos del archivo',
    'pt': 'Erro de acesso ao arquivo, verifique as permissões do arquivo',
    'ru': 'Ошибка доступа к файлу, проверьте права доступа к файлу',
    'it': 'Errore di accesso al file, verificare i permessi del file',
    'nl': 'Bestandstoegang fout, controleer bestandsrechten',
    'en': 'File access error, please check file permissions',
  });

  String get fileSaveFailed => getMessage({
    'zh': '文件保存失败',
    'zh_HK': '檔案儲存失敗',
    'ko': '파일 저장 실패',
    'ja': 'ファイルの保存に失敗しました',
    'fr': 'Échec de l\'enregistrement du fichier',
    'de': 'Speichern der Datei fehlgeschlagen',
    'es': 'Error al guardar el archivo',
    'pt': 'Falha ao salvar arquivo',
    'ru': 'Не удалось сохранить файл',
    'it': 'Salvataggio file fallito',
    'nl': 'Bestand opslaan mislukt',
    'en': 'File save failed',
  });

  String get fileSizeMismatch => getMessage({
    'zh': '文件保存失败：文件大小不匹配',
    'zh_HK': '檔案儲存失敗：檔案大小不符',
    'ko': '파일 저장 실패: 파일 크기 불일치',
    'ja': 'ファイルの保存に失敗しました：ファイルサイズが一致しません',
    'fr':
        'Échec de l\'enregistrement du fichier : taille de fichier incompatible',
    'de': 'Speichern der Datei fehlgeschlagen: Dateigrößenkonflikt',
    'es': 'Error al guardar el archivo: tamaño de archivo no coincide',
    'pt': 'Falha ao salvar arquivo: tamanho do arquivo não corresponde',
    'ru': 'Не удалось сохранить файл: несоответствие размера файла',
    'it': 'Salvataggio file fallito: dimensione del file non corrisponde',
    'nl': 'Bestand opslaan mislukt: bestandsgrootte komt niet overeen',
    'en': 'File save failed: file size mismatch',
  });

  String get invalidFileName => getMessage({
    'zh': '文件名包含非法字符',
    'zh_HK': '檔案名稱包含非法字元',
    'ko': '파일 이름에 잘못된 문자가 포함되어 있습니다',
    'ja': 'ファイル名に無効な文字が含まれています',
    'fr': 'Le nom de fichier contient des caractères non valides',
    'de': 'Dateiname enthält ungültige Zeichen',
    'es': 'El nombre del archivo contiene caracteres no válidos',
    'pt': 'Nome do arquivo contém caracteres ilegais',
    'ru': 'Имя файла содержит недопустимые символы',
    'it': 'Il nome del file contiene caratteri non validi',
    'nl': 'Bestandsnaam bevat ongeldige tekens',
    'en': 'File name contains invalid characters',
  });

  String get downloadsDirectoryUnavailable => getMessage({
    'zh': '无法访问下载目录',
    'zh_HK': '無法存取下載目錄',
    'ko': '다운로드 디렉토리에 액세스할 수 없습니다',
    'ja': 'ダウンロードディレクトリにアクセスできません',
    'fr': 'Impossible d\'accéder au répertoire de téléchargements',
    'de': 'Zugriff auf Download-Verzeichnis nicht möglich',
    'es': 'No se puede acceder al directorio de descargas',
    'pt': 'Não é possível acessar o diretório de downloads',
    'ru': 'Невозможно получить доступ к каталогу загрузок',
    'it': 'Impossibile accedere alla directory dei download',
    'nl': 'Kan geen toegang krijgen tot downloadmap',
    'en': 'Unable to access downloads directory',
  });

  // Storage errors
  String get storageInsufficient => getMessage({
    'zh': '存储空间不足，无法接收文件',
    'zh_HK': '儲存空間不足，無法接收檔案',
    'ko': '저장 공간이 부족하여 파일을 받을 수 없습니다',
    'ja': 'ストレージ容量が不足しているため、ファイルを受信できません',
    'fr': 'Espace de stockage insuffisant, impossible de recevoir le fichier',
    'de': 'Unzureichender Speicherplatz, Datei kann nicht empfangen werden',
    'es':
        'Espacio de almacenamiento insuficiente, no se puede recibir el archivo',
    'pt':
        'Espaço de armazenamento insuficiente, não é possível receber arquivo',
    'ru': 'Недостаточно места для хранения, невозможно получить файл',
    'it': 'Spazio di archiviazione insufficiente, impossibile ricevere il file',
    'nl': 'Onvoldoende opslagruimte, kan bestand niet ontvangen',
    'en': 'Insufficient storage space, cannot receive file',
  });

  String get storageCheckFailed => getMessage({
    'zh': '无法检查存储空间',
    'zh_HK': '無法檢查儲存空間',
    'ko': '저장 공간을 확인할 수 없습니다',
    'ja': 'ストレージ容量を確認できません',
    'fr': 'Impossible de vérifier l\'espace de stockage',
    'de': 'Speicherplatz kann nicht überprüft werden',
    'es': 'No se puede verificar el espacio de almacenamiento',
    'pt': 'Não é possível verificar o espaço de armazenamento',
    'ru': 'Невозможно проверить место для хранения',
    'it': 'Impossibile verificare lo spazio di archiviazione',
    'nl': 'Kan opslagruimte niet controleren',
    'en': 'Unable to check storage space',
  });

  // Permission errors
  String get permissionDenied => getMessage({
    'zh': '需要文件访问权限才能继续操作',
    'zh_HK': '需要檔案存取權限才能繼續操作',
    'ko': '계속하려면 파일 액세스 권한이 필요합니다',
    'ja': '続行するにはファイルアクセス権限が必要です',
    'fr': 'Autorisation d\'accès aux fichiers requise pour continuer',
    'de': 'Dateizugriffsberechtigung erforderlich, um fortzufahren',
    'es': 'Se requiere permiso de acceso a archivos para continuar',
    'pt': 'Permissão de acesso ao arquivo necessária para continuar',
    'ru': 'Для продолжения требуется разрешение на доступ к файлам',
    'it': 'Permesso di accesso ai file necessario per continuare',
    'nl': 'Bestandstoegang toestemming vereist om door te gaan',
    'en': 'File access permission required to continue',
  });

  String get networkPermissionDenied => getMessage({
    'zh': '需要网络访问权限才能传输文件',
    'zh_HK': '需要網路存取權限才能傳輸檔案',
    'ko': '파일을 전송하려면 네트워크 액세스 권한이 필요합니다',
    'ja': 'ファイルを転送するにはネットワークアクセス権限が必要です',
    'fr':
        'Autorisation d\'accès au réseau requise pour transférer des fichiers',
    'de': 'Netzwerkzugriffsberechtigung erforderlich, um Dateien zu übertragen',
    'es': 'Se requiere permiso de acceso a la red para transferir archivos',
    'pt': 'Permissão de acesso à rede necessária para transferir arquivos',
    'ru': 'Для передачи файлов требуется разрешение на доступ к сети',
    'it': 'Permesso di accesso alla rete necessario per trasferire file',
    'nl': 'Netwerktoegang toestemming vereist om bestanden over te dragen',
    'en': 'Network access permission required to transfer files',
  });

  String get storagePermissionDenied => getMessage({
    'zh': '需要存储访问权限才能保存文件',
    'zh_HK': '需要儲存存取權限才能儲存檔案',
    'ko': '파일을 저장하려면 저장소 액세스 권한이 필요합니다',
    'ja': 'ファイルを保存するにはストレージアクセス権限が必要です',
    'fr':
        'Autorisation d\'accès au stockage requise pour enregistrer des fichiers',
    'de': 'Speicherzugriffsberechtigung erforderlich, um Dateien zu speichern',
    'es':
        'Se requiere permiso de acceso al almacenamiento para guardar archivos',
    'pt':
        'Permissão de acesso ao armazenamento necessária para salvar arquivos',
    'ru': 'Для сохранения файлов требуется разрешение на доступ к хранилищу',
    'it': 'Permesso di accesso all\'archiviazione necessario per salvare file',
    'nl': 'Opslagtoegang toestemming vereist om bestanden op te slaan',
    'en': 'Storage access permission required to save files',
  });

  // Server errors
  String serverStartFailed(String reason) {
    final messages = <String, String Function(String)>{
      'zh': (reason) => '无法启动服务器：$reason',
      'zh_HK': (reason) => '無法啟動伺服器：$reason',
      'ko': (reason) => '서버를 시작할 수 없습니다: $reason',
      'ja': (reason) => 'サーバーを起動できません：$reason',
      'fr': (reason) => 'Impossible de démarrer le serveur : $reason',
      'de': (reason) => 'Server kann nicht gestartet werden: $reason',
      'es': (reason) => 'No se puede iniciar el servidor: $reason',
      'pt': (reason) => 'Não é possível iniciar o servidor: $reason',
      'ru': (reason) => 'Невозможно запустить сервер: $reason',
      'it': (reason) => 'Impossibile avviare il server: $reason',
      'nl': (reason) => 'Kan server niet starten: $reason',
      'en': (reason) => 'Unable to start server: $reason',
    };
    return getMessageWith1Param(messages, reason);
  }

  String get serverPortsOccupied {
    final messages = <String, String>{
      'zh':
          '无法启动服务器：端口 ${AppConstants.defaultPort}-${AppConstants.maxServerPort} 都已被占用',
      'zh_HK':
          '無法啟動伺服器：連接埠 ${AppConstants.defaultPort}-${AppConstants.maxServerPort} 都已被佔用',
      'ko':
          '서버를 시작할 수 없습니다: 포트 ${AppConstants.defaultPort}-${AppConstants.maxServerPort}가 모두 사용 중입니다',
      'ja':
          'サーバーを起動できません：ポート${AppConstants.defaultPort}-${AppConstants.maxServerPort}がすべて使用中です',
      'fr':
          'Impossible de démarrer le serveur : les ports ${AppConstants.defaultPort}-${AppConstants.maxServerPort} sont tous occupés',
      'de':
          'Server kann nicht gestartet werden: Ports ${AppConstants.defaultPort}-${AppConstants.maxServerPort} sind alle belegt',
      'es':
          'No se puede iniciar el servidor: los puertos ${AppConstants.defaultPort}-${AppConstants.maxServerPort} están todos ocupados',
      'pt':
          'Não é possível iniciar o servidor: as portas ${AppConstants.defaultPort}-${AppConstants.maxServerPort} estão todas ocupadas',
      'ru':
          'Невозможно запустить сервер: порты ${AppConstants.defaultPort}-${AppConstants.maxServerPort} все заняты',
      'it':
          'Impossibile avviare il server: le porte ${AppConstants.defaultPort}-${AppConstants.maxServerPort} sono tutte occupate',
      'nl':
          'Kan server niet starten: poorten ${AppConstants.defaultPort}-${AppConstants.maxServerPort} zijn allemaal bezet',
      'en':
          'Unable to start server: ports ${AppConstants.defaultPort}-${AppConstants.maxServerPort} are all occupied',
    };
    return getMessage(messages);
  }

  String get serverUnknownError => getMessage({
    'zh': '无法启动服务器：未知错误',
    'zh_HK': '無法啟動伺服器：未知錯誤',
    'ko': '서버를 시작할 수 없습니다: 알 수 없는 오류',
    'ja': 'サーバーを起動できません：不明なエラー',
    'fr': 'Impossible de démarrer le serveur : erreur inconnue',
    'de': 'Server kann nicht gestartet werden: unbekannter Fehler',
    'es': 'No se puede iniciar el servidor: error desconocido',
    'pt': 'Não é possível iniciar o servidor: erro desconhecido',
    'ru': 'Невозможно запустить сервер: неизвестная ошибка',
    'it': 'Impossibile avviare il server: errore sconosciuto',
    'nl': 'Kan server niet starten: onbekende fout',
    'en': 'Unable to start server: unknown error',
  });

  // Transfer errors
  String get transferRejected => getMessage({
    'zh': '对方拒绝接收文件',
    'zh_HK': '對方拒絕接收檔案',
    'ko': '수신자가 전송을 거부했습니다',
    'ja': '受信者が転送を拒否しました',
    'fr': 'Transfert rejeté par le destinataire',
    'de': 'Übertragung vom Empfänger abgelehnt',
    'es': 'Transferencia rechazada por el destinatario',
    'pt': 'Destinatário rejeitou o recebimento do arquivo',
    'ru': 'Получатель отклонил передачу',
    'it': 'Trasferimento rifiutato dal destinatario',
    'nl': 'Overdracht geweigerd door ontvanger',
    'en': 'Transfer rejected by recipient',
  });

  String get fileTooLarge => getMessage({
    'zh': '文件过大，最大支持 2GB',
    'zh_HK': '檔案過大，最大支援 2GB',
    'ko': '파일이 너무 큽니다. 최대 2GB 지원',
    'ja': 'ファイルが大きすぎます。最大2GBまでサポート',
    'fr': 'Fichier trop volumineux, maximum 2 Go pris en charge',
    'de': 'Datei zu groß, maximal 2 GB unterstützt',
    'es': 'Archivo demasiado grande, máximo 2GB soportado',
    'pt': 'Arquivo muito grande, máximo suportado 2GB',
    'ru': 'Файл слишком большой, максимум поддерживается 2 ГБ',
    'it': 'File troppo grande, massimo 2GB supportato',
    'nl': 'Bestand te groot, maximaal 2GB ondersteund',
    'en': 'File too large, maximum 2GB supported',
  });

  String get fileOrStorageFull => getMessage({
    'zh': '文件过大或对方存储空间不足',
    'zh_HK': '檔案過大或對方儲存空間不足',
    'ko': '파일이 너무 크거나 수신자의 저장 공간이 부족합니다',
    'ja': 'ファイルが大きすぎるか、受信者のストレージ容量が不足しています',
    'fr':
        'Fichier trop volumineux ou espace de stockage du destinataire insuffisant',
    'de': 'Datei zu groß oder Speicherplatz des Empfängers unzureichend',
    'es':
        'Archivo demasiado grande o espacio de almacenamiento del destinatario insuficiente',
    'pt':
        'Arquivo muito grande ou espaço de armazenamento do destinatário insuficiente',
    'ru':
        'Файл слишком большой или недостаточно места для хранения у получателя',
    'it':
        'File troppo grande o spazio di archiviazione del destinatario insufficiente',
    'nl': 'Bestand te groot of opslagruimte ontvanger onvoldoende',
    'en': 'File too large or recipient storage space insufficient',
  });

  String get receiveTimeout => getMessage({
    'zh': '接收超时，已自动拒绝',
    'zh_HK': '接收逾時，已自動拒絕',
    'ko': '수신 시간 초과, 자동으로 거부되었습니다',
    'ja': '受信タイムアウト、自動的に拒否されました',
    'fr': 'Délai de réception dépassé, automatiquement rejeté',
    'de': 'Empfangszeitüberschreitung, automatisch abgelehnt',
    'es': 'Tiempo de espera de recepción agotado, rechazado automáticamente',
    'pt': 'Tempo de recebimento esgotado, rejeitado automaticamente',
    'ru': 'Время приема истекло, автоматически отклонено',
    'it': 'Timeout di ricezione, rifiutato automaticamente',
    'nl': 'Ontvangst time-out, automatisch geweigerd',
    'en': 'Receive timeout, automatically rejected',
  });

  String get userRejected => getMessage({
    'zh': '用户拒绝接收文件',
    'zh_HK': '使用者拒絕接收檔案',
    'ko': '사용자가 파일 전송을 거부했습니다',
    'ja': 'ユーザーがファイル転送を拒否しました',
    'fr': 'L\'utilisateur a rejeté le transfert de fichier',
    'de': 'Benutzer hat Dateiübertragung abgelehnt',
    'es': 'El usuario rechazó la transferencia de archivos',
    'pt': 'Usuário rejeitou o recebimento do arquivo',
    'ru': 'Пользователь отклонил передачу файла',
    'it': 'Utente ha rifiutato il trasferimento del file',
    'nl': 'Gebruiker heeft bestandsoverdracht geweigerd',
    'en': 'User rejected file transfer',
  });

  String get backgroundRejectNeedsSecretKey => getMessage({
    'zh': '设备处于后台，仅支持密钥自动同步/接收。请打开应用或配置匹配的设备密钥。',
    'zh_HK': '裝置處於背景，僅支援密鑰自動同步/接收。請打開應用程式或設定相符的裝置密鑰。',
    'ko': '기기가 백그라운드에 있습니다. 일치하는 비밀 키가 있을 때만 자동 동기화/수신이 가능합니다.',
    'ja': 'デバイスはバックグラウンドです。一致する秘密鍵がある場合のみ自動同期/受信できます。',
    'fr':
        'L\'appareil est en arrière-plan. Seule la synchronisation/réception automatique avec clé secrète correspondante est prise en charge.',
    'de':
        'Gerät ist im Hintergrund. Nur automatische Sync/Empfang mit passendem Geheimschlüssel wird unterstützt.',
    'es':
        'El dispositivo está en segundo plano. Solo se admite sincronización/recepción automática con clave secreta coincidente.',
    'pt':
        'O dispositivo está em segundo plano. Somente sincronização/recebimento automático com chave secreta correspondente é suportado.',
    'ru':
        'Устройство в фоне. Поддерживается только автосинхронизация/приём при совпадении секретного ключа.',
    'it':
        'Il dispositivo è in background. È supportata solo la sincronizzazione/ricezione automatica con chiave segreta corrispondente.',
    'nl':
        'Apparaat is op de achtergrond. Alleen automatische sync/ontvangst met overeenkomende geheime sleutel wordt ondersteund.',
    'en':
        'Device is in the background. Only secret-key auto sync/receive is supported. Open the app or configure a matching device secret key.',
  });

  String get clipboardBackgroundCacheMiss => getMessage({
    'zh': '后台无法读取系统剪切板，且无可用缓存。请打开应用或点击悬浮窗刷新后再同步。',
    'zh_HK': '背景無法讀取系統剪貼簿，且無可用快取。請打開應用程式或點擊懸浮窗重新整理後再同步。',
    'ko': '백그라운드에서는 시스템 클립보드를 읽을 수 없고 사용 가능한 캐시도 없습니다. 앱을 열거나 플로팅 버튼을 눌러 새로고침한 뒤 동기화하세요.',
    'ja': 'バックグラウンドではシステムクリップボードを読めず、有効なキャッシュもありません。アプリを開くかフローティングボタンで更新してから同期してください。',
    'fr':
        'Impossible de lire le presse-papiers système en arrière-plan et aucun cache disponible. Ouvrez l\'app ou appuyez sur le bouton flottant pour actualiser.',
    'de':
        'Zwischenablage im Hintergrund nicht lesbar und kein Cache verfügbar. App öffnen oder Floating-Button tippen zum Aktualisieren.',
    'es':
        'No se puede leer el portapapeles del sistema en segundo plano y no hay caché. Abra la app o toque el botón flotante para actualizar.',
    'pt':
        'Não é possível ler a área de transferência do sistema em segundo plano e não há cache. Abra o app ou toque no botão flutuante para atualizar.',
    'ru':
        'В фоне системный буфер недоступен и нет кэша. Откройте приложение или нажмите плавающую кнопку для обновления.',
    'it':
        'Impossibile leggere gli appunti di sistema in background e nessuna cache disponibile. Apri l\'app o tocca il pulsante flottante per aggiornare.',
    'nl':
        'Systeemklembord is op de achtergrond niet leesbaar en er is geen cache. Open de app of tik op de zwevende knop om te vernieuwen.',
    'en':
        'Cannot read the system clipboard in the background and no cache is available. Open the app or tap the floating button to refresh, then sync again.',
  });

  String get foregroundServiceNotificationTitle => getMessage({
    'zh': 'IcyEasySend',
    'zh_HK': 'IcyEasySend',
    'ko': 'IcyEasySend',
    'ja': 'IcyEasySend',
    'fr': 'IcyEasySend',
    'de': 'IcyEasySend',
    'es': 'IcyEasySend',
    'pt': 'IcyEasySend',
    'ru': 'IcyEasySend',
    'it': 'IcyEasySend',
    'nl': 'IcyEasySend',
    'en': 'IcyEasySend',
  });

  String get foregroundServiceNotificationText => getMessage({
    'zh': '正在后台等待文件传输与剪切板同步',
    'zh_HK': '正在背景等待檔案傳輸與剪貼簿同步',
    'ko': '백그라운드에서 파일 전송 및 클립보드 동기화를 대기 중',
    'ja': 'バックグラウンドでファイル転送とクリップボード同期を待機中',
    'fr': 'En attente des transferts et de la synchro presse-papiers en arrière-plan',
    'de': 'Wartet im Hintergrund auf Dateiübertragung und Zwischenablage-Sync',
    'es': 'Esperando transferencias y sincronización del portapapeles en segundo plano',
    'pt': 'Aguardando transferências e sincronização da área de transferência em segundo plano',
    'ru': 'Ожидание передачи файлов и синхронизации буфера в фоне',
    'it': 'In attesa di trasferimenti e sync appunti in background',
    'nl': 'Wacht op bestandoverdracht en klembordsync op de achtergrond',
    'en': 'Waiting for file transfers and clipboard sync in the background',
  });

  String get foregroundServiceChannelName => getMessage({
    'zh': '后台传输服务',
    'zh_HK': '背景傳輸服務',
    'ko': '백그라운드 전송 서비스',
    'ja': 'バックグラウンド転送サービス',
    'fr': 'Service de transfert en arrière-plan',
    'de': 'Hintergrund-Übertragungdienst',
    'es': 'Servicio de transferencia en segundo plano',
    'pt': 'Serviço de transferência em segundo plano',
    'ru': 'Фоновая служба передачи',
    'it': 'Servizio trasferimento in background',
    'nl': 'Achtergrond-overdrachtservice',
    'en': 'Background transfer service',
  });

  String get foregroundServiceChannelDescription => getMessage({
    'zh': '保持应用在后台可接收局域网文件与剪切板请求',
    'zh_HK': '保持應用程式在背景可接收區域網路檔案與剪貼簿請求',
    'ko': '앱이 백그라운드에서도 LAN 파일 및 클립보드 요청을 받을 수 있도록 유지',
    'ja': 'バックグラウンドでもLANファイルとクリップボード要求を受信できるようにします',
    'fr':
        'Maintient l\'app capable de recevoir fichiers LAN et requêtes presse-papiers en arrière-plan',
    'de':
        'Hält die App bereit, LAN-Dateien und Zwischenablage-Anfragen im Hintergrund zu empfangen',
    'es':
        'Mantiene la app lista para recibir archivos LAN y solicitudes del portapapeles en segundo plano',
    'pt':
        'Mantém o app pronto para receber arquivos LAN e pedidos da área de transferência em segundo plano',
    'ru':
        'Позволяет приложению принимать LAN-файлы и запросы буфера обмена в фоне',
    'it':
        'Mantiene l\'app in grado di ricevere file LAN e richieste appunti in background',
    'nl':
        'Houdt de app klaar om LAN-bestanden en klembordverzoeken op de achtergrond te ontvangen',
    'en':
        'Keeps the app able to receive LAN files and clipboard requests in the background',
  });

  // Validation errors
  String get ipAddressEmpty => getMessage({
    'zh': 'IP 地址不能为空',
    'zh_HK': 'IP 位址不能為空',
    'ko': 'IP 주소는 비워둘 수 없습니다',
    'ja': 'IPアドレスは空にできません',
    'fr': 'L\'adresse IP ne peut pas être vide',
    'de': 'IP-Adresse darf nicht leer sein',
    'es': 'La dirección IP no puede estar vacía',
    'pt': 'Endereço IP não pode estar vazio',
    'ru': 'IP-адрес не может быть пустым',
    'it': 'L\'indirizzo IP non può essere vuoto',
    'nl': 'IP-adres mag niet leeg zijn',
    'en': 'IP address cannot be empty',
  });

  String get ipAddressInvalidFormat => getMessage({
    'zh': 'IP 地址格式无效，请使用 xxx.xxx.xxx.xxx 格式',
    'zh_HK': 'IP 位址格式無效，請使用 xxx.xxx.xxx.xxx 格式',
    'ko': '잘못된 IP 주소 형식입니다. xxx.xxx.xxx.xxx 형식을 사용하세요',
    'ja': '無効なIPアドレス形式です。xxx.xxx.xxx.xxx形式を使用してください',
    'fr':
        'Format d\'adresse IP invalide, veuillez utiliser le format xxx.xxx.xxx.xxx',
    'de':
        'Ungültiges IP-Adressformat, bitte verwenden Sie das Format xxx.xxx.xxx.xxx',
    'es': 'Formato de dirección IP no válido, use el formato xxx.xxx.xxx.xxx',
    'pt': 'Formato de endereço IP inválido, use o formato xxx.xxx.xxx.xxx',
    'ru': 'Неверный формат IP-адреса, используйте формат xxx.xxx.xxx.xxx',
    'it':
        'Formato indirizzo IP non valido, utilizzare il formato xxx.xxx.xxx.xxx',
    'nl': 'Ongeldig IP-adres formaat, gebruik xxx.xxx.xxx.xxx formaat',
    'en': 'Invalid IP address format, please use xxx.xxx.xxx.xxx format',
  });

  String get ipAddressInvalidRange => getMessage({
    'zh': 'IP 地址格式无效，每个数字必须在 0-255 之间',
    'zh_HK': 'IP 位址格式無效，每個數字必須在 0-255 之間',
    'ko': '잘못된 IP 주소 형식입니다. 각 숫자는 0-255 사이여야 합니다',
    'ja': '無効なIPアドレス形式です。各数字は0〜255の間でなければなりません',
    'fr':
        'Format d\'adresse IP invalide, chaque nombre doit être entre 0 et 255',
    'de':
        'Ungültiges IP-Adressformat, jede Zahl muss zwischen 0 und 255 liegen',
    'es':
        'Formato de dirección IP no válido, cada número debe estar entre 0 y 255',
    'pt': 'Formato de endereço IP inválido, cada número deve estar entre 0-255',
    'ru': 'Неверный формат IP-адреса, каждое число должно быть от 0 до 255',
    'it':
        'Formato indirizzo IP non valido, ogni numero deve essere compreso tra 0-255',
    'nl': 'Ongeldig IP-adres formaat, elk nummer moet tussen 0-255 zijn',
    'en': 'Invalid IP address format, each number must be between 0-255',
  });

  String get ipAddressSpecial1 => getMessage({
    'zh': '不能使用 0.0.0.0 作为目标地址',
    'zh_HK': '不能使用 0.0.0.0 作為目標位址',
    'ko': '0.0.0.0을 대상 주소로 사용할 수 없습니다',
    'ja': '0.0.0.0をターゲットアドレスとして使用できません',
    'fr': 'Impossible d\'utiliser 0.0.0.0 comme adresse cible',
    'de': '0.0.0.0 kann nicht als Zieladresse verwendet werden',
    'es': 'No se puede usar 0.0.0.0 como dirección de destino',
    'pt': 'Não é possível usar 0.0.0.0 como endereço de destino',
    'ru': 'Невозможно использовать 0.0.0.0 в качестве целевого адреса',
    'it': 'Impossibile utilizzare 0.0.0.0 come indirizzo di destinazione',
    'nl': 'Kan 0.0.0.0 niet gebruiken als doeladres',
    'en': 'Cannot use 0.0.0.0 as target address',
  });

  String get ipAddressSpecial2 => getMessage({
    'zh': '不能使用广播地址 255.255.255.255',
    'zh_HK': '不能使用廣播位址 255.255.255.255',
    'ko': '브로드캐스트 주소 255.255.255.255를 사용할 수 없습니다',
    'ja': 'ブロードキャストアドレス255.255.255.255は使用できません',
    'fr': 'Impossible d\'utiliser l\'adresse de diffusion 255.255.255.255',
    'de': 'Broadcast-Adresse 255.255.255.255 kann nicht verwendet werden',
    'es': 'No se puede usar la dirección de difusión 255.255.255.255',
    'pt': 'Não é possível usar o endereço de broadcast 255.255.255.255',
    'ru': 'Невозможно использовать широковещательный адрес 255.255.255.255',
    'it': 'Impossibile utilizzare l\'indirizzo broadcast 255.255.255.255',
    'nl': 'Kan broadcast-adres 255.255.255.255 niet gebruiken',
    'en': 'Cannot use broadcast address 255.255.255.255',
  });

  String ipAddressNotInSameSubnet(String localIP, String targetIP) {
    final localNetwork = localIP.split('.').take(3).join('.');
    final targetNetwork = targetIP.split('.').take(3).join('.');

    final messages = <String, String Function(Map<String, String>)>{
      'zh': (params) =>
          '⚠️ 网段不匹配\n'
          '本机IP: ${params['localIP']} (网段: ${params['localNetwork']}.x)\n'
          '目标IP: ${params['targetIP']} (网段: ${params['targetNetwork']}.x)\n'
          '\n'
          '提示：两台设备需要在同一个局域网（相同网段）才能传输文件。\n'
          'C类IPv4地址应该保证两个IP地址的前三个数字相同，例如都是192.169.2，只是最后一个数字不同\n'
          '最简单的方法就是让两个设备都连接同一个WiFi或路由器。\n',
      'zh_HK': (params) =>
          '⚠️ 網段不符\n'
          '本機IP: ${params['localIP']} (網段: ${params['localNetwork']}.x)\n'
          '目標IP: ${params['targetIP']} (網段: ${params['targetNetwork']}.x)\n'
          '\n'
          '提示：兩台裝置需要在同一個區域網路（相同網段）才能傳輸檔案。\n'
          'C類IPv4位址應該保證兩個IP位址的前三個數字相同，例如都是192.169.2，只是最後一個數字不同\n'
          '最簡單的方法就是讓兩個裝置都連線同一個WiFi或路由器。\n',
      'ko': (params) =>
          '⚠️ 서브넷 불일치\n'
          '로컬 IP: ${params['localIP']} (서브넷: ${params['localNetwork']}.x)\n'
          '대상 IP: ${params['targetIP']} (서브넷: ${params['targetNetwork']}.x)\n'
          '\n'
          '참고: 두 기기가 파일을 전송하려면 동일한 LAN(동일한 서브넷)에 있어야 합니다.\n'
          'C 클래스 IPv4 주소의 경우 두 IP 주소의 처음 세 숫자가 같아야 합니다. 예: 둘 다 192.168.2이고 마지막 숫자만 다름\n'
          '가장 간단한 방법은 두 기기를 동일한 WiFi 또는 라우터에 연결하는 것입니다.\n',
      'ja': (params) =>
          '⚠️ サブネットの不一致\n'
          'ローカルIP: ${params['localIP']} (サブネット: ${params['localNetwork']}.x)\n'
          'ターゲットIP: ${params['targetIP']} (サブネット: ${params['targetNetwork']}.x)\n'
          '\n'
          '注意：ファイルを転送するには、両方のデバイスが同じLAN（同じサブネット）にある必要があります。\n'
          'クラスC IPv4アドレスの場合、2つのIPアドレスの最初の3つの数字が同じである必要があります。例：両方とも192.168.2で、最後の数字のみが異なる\n'
          '最も簡単な方法は、両方のデバイスを同じWiFiまたはルーターに接続することです。\n',
      'fr': (params) =>
          '⚠️ Incompatibilité de sous-réseau\n'
          'IP locale : ${params['localIP']} (sous-réseau : ${params['localNetwork']}.x)\n'
          'IP cible : ${params['targetIP']} (sous-réseau : ${params['targetNetwork']}.x)\n'
          '\n'
          'Remarque : Les deux appareils doivent être sur le même LAN (même sous-réseau) pour transférer des fichiers.\n'
          'Pour les adresses IPv4 de classe C, les trois premiers chiffres des deux adresses IP doivent être identiques, par exemple les deux sont 192.168.2, seul le dernier chiffre diffère\n'
          'Le moyen le plus simple est de connecter les deux appareils au même WiFi ou routeur.\n',
      'de': (params) =>
          '⚠️ Subnetz-Konflikt\n'
          'Lokale IP: ${params['localIP']} (Subnetz: ${params['localNetwork']}.x)\n'
          'Ziel-IP: ${params['targetIP']} (Subnetz: ${params['targetNetwork']}.x)\n'
          '\n'
          'Hinweis: Beide Geräte müssen sich im selben LAN (gleiches Subnetz) befinden, um Dateien zu übertragen.\n'
          'Bei Klasse-C-IPv4-Adressen sollten die ersten drei Zahlen beider IP-Adressen gleich sein, z. B. beide sind 192.168.2, nur die letzte Zahl unterscheidet sich\n'
          'Der einfachste Weg ist, beide Geräte mit demselben WLAN oder Router zu verbinden.\n',
      'es': (params) =>
          '⚠️ Incompatibilidad de subred\n'
          'IP local: ${params['localIP']} (subred: ${params['localNetwork']}.x)\n'
          'IP de destino: ${params['targetIP']} (subred: ${params['targetNetwork']}.x)\n'
          '\n'
          'Nota: Ambos dispositivos deben estar en la misma LAN (misma subred) para transferir archivos.\n'
          'Para direcciones IPv4 de clase C, los tres primeros números de ambas direcciones IP deben ser iguales, por ejemplo, ambos son 192.168.2, solo el último número difiere\n'
          'La forma más sencilla es conectar ambos dispositivos al mismo WiFi o enrutador.\n',
      'pt': (params) =>
          '⚠️ Incompatibilidade de segmento de rede\n'
          'IP local: ${params['localIP']} (segmento: ${params['localNetwork']}.x)\n'
          'IP de destino: ${params['targetIP']} (segmento: ${params['targetNetwork']}.x)\n'
          '\n'
          'Dica: Os dois dispositivos precisam estar na mesma rede local (mesmo segmento) para transferir arquivos.\n'
          'Para endereços IPv4 Classe C, os três primeiros números dos dois endereços IP devem ser iguais, por exemplo, ambos são 192.168.2, apenas o último número é diferente\n'
          'A maneira mais simples é conectar ambos os dispositivos ao mesmo WiFi ou roteador.\n',
      'ru': (params) =>
          '⚠️ Несоответствие подсети\n'
          'Локальный IP: ${params['localIP']} (подсеть: ${params['localNetwork']}.x)\n'
          'Целевой IP: ${params['targetIP']} (подсеть: ${params['targetNetwork']}.x)\n'
          '\n'
          'Примечание: Оба устройства должны находиться в одной локальной сети (одной подсети) для передачи файлов.\n'
          'Для IPv4-адресов класса C первые три числа обоих IP-адресов должны быть одинаковыми, например, оба 192.168.2, отличается только последнее число\n'
          'Самый простой способ - подключить оба устройства к одному WiFi или маршрутизатору.\n',
      'it': (params) =>
          '⚠️ Incompatibilità di sottorete\n'
          'IP locale: ${params['localIP']} (sottorete: ${params['localNetwork']}.x)\n'
          'IP di destinazione: ${params['targetIP']} (sottorete: ${params['targetNetwork']}.x)\n'
          '\n'
          'Nota: Entrambi i dispositivi devono essere sulla stessa LAN (stessa sottorete) per trasferire file.\n'
          'Per gli indirizzi IPv4 di classe C, i primi tre numeri di entrambi gli indirizzi IP devono essere uguali, ad esempio entrambi sono 192.168.2, solo l\'ultimo numero differisce\n'
          'Il modo più semplice è connettere entrambi i dispositivi allo stesso WiFi o router.\n',
      'nl': (params) =>
          '⚠️ Subnet komt niet overeen\n'
          'Lokaal IP: ${params['localIP']} (subnet: ${params['localNetwork']}.x)\n'
          'Doel IP: ${params['targetIP']} (subnet: ${params['targetNetwork']}.x)\n'
          '\n'
          'Opmerking: Beide apparaten moeten op hetzelfde LAN (hetzelfde subnet) zijn om bestanden over te dragen.\n'
          'Voor klasse C IPv4-adressen moeten de eerste drie cijfers van beide IP-adressen hetzelfde zijn, bijvoorbeeld beide zijn 192.168.2, alleen het laatste cijfer verschilt\n'
          'De eenvoudigste manier is om beide apparaten met dezelfde WiFi of router te verbinden.\n',
      'en': (params) =>
          '⚠️ Subnet Mismatch\n'
          'Local IP: ${params['localIP']} (subnet: ${params['localNetwork']}.x)\n'
          'Target IP: ${params['targetIP']} (subnet: ${params['targetNetwork']}.x)\n'
          '\n'
          'Note: Both devices need to be on the same LAN (same subnet) to transfer files.\n'
          'For Class C IPv4 addresses, the first three numbers should be the same, e.g., both are 192.168.2, only the last number differs\n'
          'The easiest way is to connect both devices to the same WiFi or router.\n',
    };

    return getMessageWithMapParam(messages, {
      'localIP': localIP,
      'targetIP': targetIP,
      'localNetwork': localNetwork,
      'targetNetwork': targetNetwork,
    });
  }

  // Response parsing errors
  String get responseParseError => getMessage({
    'zh': '无法解析服务器响应',
    'zh_HK': '無法解析伺服器回應',
    'ko': '서버 응답을 구문 분석할 수 없습니다',
    'ja': 'サーバーの応答を解析できません',
    'fr': 'Impossible d\'analyser la réponse du serveur',
    'de': 'Serverantwort kann nicht analysiert werden',
    'es': 'No se puede analizar la respuesta del servidor',
    'pt': 'Não é possível analisar a resposta do servidor',
    'ru': 'Невозможно разобрать ответ сервера',
    'it': 'Impossibile analizzare la risposta del server',
    'nl': 'Kan serverreactie niet parseren',
    'en': 'Unable to parse server response',
  });

  String get responseInvalidFormat => getMessage({
    'zh': '目标设备响应格式不正确',
    'zh_HK': '目標裝置回應格式不正確',
    'ko': '대상 기기 응답 형식이 올바르지 않습니다',
    'ja': 'ターゲットデバイスの応答形式が正しくありません',
    'fr': 'Le format de réponse de l\'appareil cible est incorrect',
    'de': 'Antwortformat des Zielgeräts ist falsch',
    'es': 'El formato de respuesta del dispositivo de destino es incorrecto',
    'pt': 'Formato de resposta do dispositivo de destino incorreto',
    'ru': 'Неверный формат ответа целевого устройства',
    'it':
        'Il formato della risposta del dispositivo di destinazione non è corretto',
    'nl': 'Reactieformaat doelapparaat is onjuist',
    'en': 'Target device response format is incorrect',
  });

  String responseStatusCodeError(int statusCode) {
    final messages = <String, String Function(int)>{
      'zh': (code) => '服务器返回错误状态码: $code',
      'zh_HK': (code) => '伺服器傳回錯誤狀態碼: $code',
      'ko': (code) => '서버가 오류 상태 코드를 반환했습니다: $code',
      'ja': (code) => 'サーバーがエラーステータスコードを返しました: $code',
      'fr': (code) => 'Le serveur a renvoyé un code d\'état d\'erreur : $code',
      'de': (code) => 'Server hat Fehlerstatuscode zurückgegeben: $code',
      'es': (code) =>
          'El servidor devolvió un código de estado de error: $code',
      'pt': (code) => 'Servidor retornou código de status de erro: $code',
      'ru': (code) => 'Сервер вернул код ошибки: $code',
      'it': (code) =>
          'Il server ha restituito un codice di stato di errore: $code',
      'nl': (code) => 'Server heeft foutstatuscode geretourneerd: $code',
      'en': (code) => 'Server returned error status code: $code',
    };
    return getMessageWith1Param(messages, statusCode);
  }

  // File selection errors
  String get fileSelectionError => getMessage({
    'zh': '选择文件时出错',
    'zh_HK': '選擇檔案時出錯',
    'ko': '파일 선택 중 오류가 발생했습니다',
    'ja': 'ファイル選択中にエラーが発生しました',
    'fr': 'Erreur lors de la sélection du fichier',
    'de': 'Fehler beim Auswählen der Datei',
    'es': 'Error al seleccionar el archivo',
    'pt': 'Erro ao selecionar arquivo',
    'ru': 'Ошибка при выборе файла',
    'it': 'Errore durante la selezione del file',
    'nl': 'Fout opgetreden bij selecteren bestand',
    'en': 'Error occurred while selecting file',
  });

  String get fileSelectionCancelled => getMessage({
    'zh': '已取消选择文件',
    'zh_HK': '已取消選擇檔案',
    'ko': '파일 선택이 취소되었습니다',
    'ja': 'ファイル選択がキャンセルされました',
    'fr': 'Sélection de fichier annulée',
    'de': 'Dateiauswahl abgebrochen',
    'es': 'Selección de archivos cancelada',
    'pt': 'Seleção de arquivo cancelada',
    'ru': 'Выбор файла отменен',
    'it': 'Selezione file annullata',
    'nl': 'Bestandsselectie geannuleerd',
    'en': 'File selection cancelled',
  });

  // Generic errors
  String genericError(String operation) {
    final messages = <String, String Function(String)>{
      'zh': (op) => '$op失败',
      'zh_HK': (op) => '$op失敗',
      'ko': (op) => '$op 실패',
      'ja': (op) => '$opに失敗しました',
      'fr': (op) => '$op a échoué',
      'de': (op) => '$op fehlgeschlagen',
      'es': (op) => '$op falló',
      'pt': (op) => '$op falhou',
      'ru': (op) => '$op не удалось',
      'it': (op) => '$op fallito',
      'nl': (op) => '$op mislukt',
      'en': (op) => '$op failed',
    };
    return getMessageWith1Param(messages, operation);
  }

  String unexpectedError(String details) {
    final messages = <String, String Function(String)>{
      'zh': (d) => '发生意外错误: $d',
      'zh_HK': (d) => '發生意外錯誤: $d',
      'ko': (d) => '예기치 않은 오류가 발생했습니다: $d',
      'ja': (d) => '予期しないエラーが発生しました: $d',
      'fr': (d) => 'Une erreur inattendue s\'est produite : $d',
      'de': (d) => 'Unerwarteter Fehler aufgetreten: $d',
      'es': (d) => 'Ocurrió un error inesperado: $d',
      'pt': (d) => 'Ocorreu um erro inesperado: $d',
      'ru': (d) => 'Произошла непредвиденная ошибка: $d',
      'it': (d) => 'Si è verificato un errore imprevisto: $d',
      'nl': (d) => 'Onverwachte fout opgetreden: $d',
      'en': (d) => 'Unexpected error occurred: $d',
    };
    return getMessageWith1Param(messages, details);
  }

  String networkError(String context) {
    final messages = <String, String Function(String)>{
      'zh': (ctx) => '网络错误: $ctx',
      'zh_HK': (ctx) => '網路錯誤: $ctx',
      'ko': (ctx) => '네트워크 오류: $ctx',
      'ja': (ctx) => 'ネットワークエラー: $ctx',
      'fr': (ctx) => 'Erreur réseau : $ctx',
      'de': (ctx) => 'Netzwerkfehler: $ctx',
      'es': (ctx) => 'Error de red: $ctx',
      'pt': (ctx) => 'Erro de rede: $ctx',
      'ru': (ctx) => 'Ошибка сети: $ctx',
      'it': (ctx) => 'Errore di rete: $ctx',
      'nl': (ctx) => 'Netwerkfout: $ctx',
      'en': (ctx) => 'Network error: $ctx',
    };
    return getMessageWith1Param(messages, context);
  }

  String fileError(String context) {
    final messages = <String, String Function(String)>{
      'zh': (ctx) => '文件错误: $ctx',
      'zh_HK': (ctx) => '檔案錯誤: $ctx',
      'ko': (ctx) => '파일 오류: $ctx',
      'ja': (ctx) => 'ファイルエラー: $ctx',
      'fr': (ctx) => 'Erreur de fichier : $ctx',
      'de': (ctx) => 'Dateifehler: $ctx',
      'es': (ctx) => 'Error de archivo: $ctx',
      'pt': (ctx) => 'Erro de arquivo: $ctx',
      'ru': (ctx) => 'Ошибка файла: $ctx',
      'it': (ctx) => 'Errore file: $ctx',
      'nl': (ctx) => 'Bestandsfout: $ctx',
      'en': (ctx) => 'File error: $ctx',
    };
    return getMessageWith1Param(messages, context);
  }

  String permissionError(String permissionType) {
    final messages = <String, String Function(String)>{
      'zh': (type) => '需要$type权限才能继续操作',
      'zh_HK': (type) => '需要$type權限才能繼續操作',
      'ko': (type) => '계속하려면 $type 권한이 필요합니다',
      'ja': (type) => '続行するには$type権限が必要です',
      'fr': (type) => 'Autorisation $type requise pour continuer',
      'de': (type) => '$type-Berechtigung erforderlich, um fortzufahren',
      'es': (type) => 'Se requiere permiso de $type para continuar',
      'pt': (type) => 'Permissão de $type necessária para continuar',
      'ru': (type) => 'Для продолжения требуется разрешение $type',
      'it': (type) => 'Permesso $type necessario per continuare',
      'nl': (type) => '$type toestemming vereist om door te gaan',
      'en': (type) => '$type permission required to continue',
    };
    return getMessageWith1Param(messages, permissionType);
  }
}
