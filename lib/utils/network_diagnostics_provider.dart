/// Global network diagnostics message provider that supports internationalization
/// without requiring BuildContext.
///
/// This provider uses the current language setting from LanguageService
/// to return appropriate diagnostic messages.
library;

import 'base_i18n_provider.dart';

class NetworkDiagnosticsProvider extends BaseI18nProvider {
  static final NetworkDiagnosticsProvider _instance =
      NetworkDiagnosticsProvider._internal();

  factory NetworkDiagnosticsProvider() => _instance;

  NetworkDiagnosticsProvider._internal();

  // Diagnostics messages
  String get networkDiagnosticsReport => getMessage({
    'zh': '网络诊断报告',
    'zh_HK': '網路診斷報告',
    'ko': '네트워크 진단 보고서',
    'ja': 'ネットワーク診断レポート',
    'fr': 'Rapport de diagnostic réseau',
    'de': 'Netzwerkdiagnosebericht',
    'es': 'Informe de diagnóstico de red',
    'pt': 'Relatório de Diagnóstico de Rede',
    'ru': 'Отчет диагностики сети',
    'it': 'Rapporto Diagnostica di Rete',
    'nl': 'Netwerkdiagnose Rapport',
    'en': 'Network Diagnostics Report',
  });

  String get localNetworkInterfaces => getMessage({
    'zh': '本地网络接口',
    'zh_HK': '本機網路介面',
    'ko': '로컬 네트워크 인터페이스',
    'ja': 'ローカルネットワークインターフェース',
    'fr': 'Interfaces réseau locales',
    'de': 'Lokale Netzwerkschnittstellen',
    'es': 'Interfaces de red locales',
    'pt': 'Interfaces de Rede Locais',
    'ru': 'Локальные сетевые интерфейсы',
    'it': 'Interfacce di Rete Locali',
    'nl': 'Lokale Netwerkinterfaces',
    'en': 'Local Network Interfaces',
  });

  String get noValidNetworkInterface => getMessage({
    'zh': '未找到有效的网络接口',
    'zh_HK': '未找到有效的網路介面',
    'ko': '유효한 네트워크 인터페이스를 찾을 수 없습니다',
    'ja': '有効なネットワークインターフェースが見つかりません',
    'fr': 'Aucune interface réseau valide trouvée',
    'de': 'Keine gültige Netzwerkschnittstelle gefunden',
    'es': 'No se encontró una interfaz de red válida',
    'pt': 'Nenhuma interface de rede válida encontrada',
    'ru': 'Не найден действительный сетевой интерфейс',
    'it': 'Nessuna interfaccia di rete valida trovata',
    'nl': 'Geen geldige netwerkinterface gevonden',
    'en': 'No valid network interface found',
  });

  String get privateNetworkAddress => getMessage({
    'zh': '私有网络地址',
    'zh_HK': '私有網路位址',
    'ko': '사설 네트워크 주소',
    'ja': 'プライベートネットワークアドレス',
    'fr': 'Adresse réseau privée',
    'de': 'Private Netzwerkadresse',
    'es': 'Dirección de red privada',
    'pt': 'Endereço de Rede Privada',
    'ru': 'Адрес частной сети',
    'it': 'Indirizzo di Rete Privata',
    'nl': 'Privé Netwerkadres',
    'en': 'Private network address',
  });

  String get targetDeviceReachability => getMessage({
    'zh': '目标设备可达性',
    'zh_HK': '目標裝置可達性',
    'ko': '대상 장치 연결 가능성',
    'ja': 'ターゲットデバイスの到達可能性',
    'fr': 'Accessibilité de l\'appareil cible',
    'de': 'Erreichbarkeit des Zielgeräts',
    'es': 'Accesibilidad del dispositivo de destino',
    'pt': 'Acessibilidade do Dispositivo de Destino',
    'ru': 'Доступность целевого устройства',
    'it': 'Raggiungibilità Dispositivo di Destinazione',
    'nl': 'Bereikbaarheid Doelapparaat',
    'en': 'Target Device Reachability',
  });

  String get canConnectToTarget => getMessage({
    'zh': '可以连接到目标设备',
    'zh_HK': '可以連線到目標裝置',
    'ko': '대상 장치에 연결할 수 있습니다',
    'ja': 'ターゲットデバイスに接続できます',
    'fr': 'Peut se connecter à l\'appareil cible',
    'de': 'Kann sich mit dem Zielgerät verbinden',
    'es': 'Se puede conectar al dispositivo de destino',
    'pt': 'Pode conectar ao dispositivo de destino',
    'ru': 'Можно подключиться к целевому устройству',
    'it': 'Può connettersi al dispositivo di destinazione',
    'nl': 'Kan verbinden met doelapparaat',
    'en': 'Can connect to target device',
  });

  String get cannotConnectToTarget => getMessage({
    'zh': '无法连接到目标设备',
    'zh_HK': '無法連線到目標裝置',
    'ko': '대상 장치에 연결할 수 없습니다',
    'ja': 'ターゲットデバイスに接続できません',
    'fr': 'Impossible de se connecter à l\'appareil cible',
    'de': 'Kann keine Verbindung zum Zielgerät herstellen',
    'es': 'No se puede conectar al dispositivo de destino',
    'pt': 'Não é possível conectar ao dispositivo de destino',
    'ru': 'Невозможно подключиться к целевому устройству',
    'it': 'Impossibile connettersi al dispositivo di destinazione',
    'nl': 'Kan niet verbinden met doelapparaat',
    'en': 'Cannot connect to target device',
  });

  String get healthCheckTest => getMessage({
    'zh': '健康检查测试',
    'zh_HK': '健康檢查測試',
    'ko': '상태 확인 테스트',
    'ja': 'ヘルスチェックテスト',
    'fr': 'Test de vérification de santé',
    'de': 'Gesundheitsprüfungstest',
    'es': 'Prueba de verificación de salud',
    'pt': 'Teste de Verificação de Saúde',
    'ru': 'Тест проверки работоспособности',
    'it': 'Test di Verifica Salute',
    'nl': 'Gezondheidscontrole Test',
    'en': 'Health Check Test',
  });

  String get healthCheckSuccess => getMessage({
    'zh': '健康检查成功',
    'zh_HK': '健康檢查成功',
    'ko': '상태 확인 성공',
    'ja': 'ヘルスチェック成功',
    'fr': 'Vérification de santé réussie',
    'de': 'Gesundheitsprüfung erfolgreich',
    'es': 'Verificación de salud exitosa',
    'pt': 'Verificação de saúde bem-sucedida',
    'ru': 'Проверка работоспособности успешна',
    'it': 'Verifica salute riuscita',
    'nl': 'Gezondheidscontrole geslaagd',
    'en': 'Health check successful',
  });

  String get healthCheckFailed => getMessage({
    'zh': '健康检查失败',
    'zh_HK': '健康檢查失敗',
    'ko': '상태 확인 실패',
    'ja': 'ヘルスチェック失敗',
    'fr': 'Vérification de santé échouée',
    'de': 'Gesundheitsprüfung fehlgeschlagen',
    'es': 'Verificación de salud fallida',
    'pt': 'Verificação de saúde falhou',
    'ru': 'Проверка работоспособности не удалась',
    'it': 'Verifica salute fallita',
    'nl': 'Gezondheidscontrole mislukt',
    'en': 'Health check failed',
  });

  String get statusCode => getMessage({
    'zh': '状态码',
    'zh_HK': '狀態碼',
    'ko': '상태 코드',
    'ja': 'ステータスコード',
    'fr': 'Code de statut',
    'de': 'Statuscode',
    'es': 'Código de estado',
    'pt': 'Código de Status',
    'ru': 'Код состояния',
    'it': 'Codice di Stato',
    'nl': 'Statuscode',
    'en': 'Status code',
  });

  String get response => getMessage({
    'zh': '响应',
    'zh_HK': '回應',
    'ko': '응답',
    'ja': 'レスポンス',
    'fr': 'Réponse',
    'de': 'Antwort',
    'es': 'Respuesta',
    'ru': 'Ответ',
    'pt': 'Resposta',
    'it': 'Risposta',
    'nl': 'Reactie',
    'en': 'Response',
  });

  String get error => getMessage({
    'zh': '错误',
    'zh_HK': '錯誤',
    'ko': '오류',
    'ja': 'エラー',
    'fr': 'Erreur',
    'de': 'Fehler',
    'es': 'Error',
    'ru': 'Ошибка',
    'pt': 'Erro',
    'it': 'Errore',
    'nl': 'Fout',
    'en': 'Error',
  });

  String get internetConnection => getMessage({
    'zh': '互联网连接',
    'zh_HK': '網際網路連線',
    'ko': '인터넷 연결',
    'ja': 'インターネット接続',
    'fr': 'Connexion Internet',
    'de': 'Internetverbindung',
    'es': 'Conexión a Internet',
    'pt': 'Conexão com a Internet',
    'ru': 'Подключение к Интернету',
    'it': 'Connessione Internet',
    'nl': 'Internetverbinding',
    'en': 'Internet Connection',
  });

  String get hasInternetConnection => getMessage({
    'zh': '有互联网连接',
    'zh_HK': '有網際網路連線',
    'ko': '인터넷 연결됨',
    'ja': 'インターネット接続あり',
    'fr': 'Connexion Internet disponible',
    'de': 'Internetverbindung vorhanden',
    'es': 'Tiene conexión a Internet',
    'pt': 'Tem conexão com a internet',
    'ru': 'Есть подключение к Интернету',
    'it': 'Ha connessione internet',
    'nl': 'Heeft internetverbinding',
    'en': 'Has internet connection',
  });

  String get noInternetConnection => getMessage({
    'zh': '无互联网连接',
    'zh_HK': '無網際網路連線',
    'ko': '인터넷 연결 없음',
    'ja': 'インターネット接続なし',
    'fr': 'Pas de connexion Internet',
    'de': 'Keine Internetverbindung',
    'es': 'Sin conexión a Internet',
    'pt': 'Sem conexão com a internet',
    'ru': 'Нет подключения к Интернету',
    'it': 'Nessuna connessione internet',
    'nl': 'Geen internetverbinding',
    'en': 'No internet connection',
  });
}
