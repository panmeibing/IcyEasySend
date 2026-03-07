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
