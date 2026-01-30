import '../../models/transfer_history.dart';
import '../../utils/log_util.dart';
import '../transfer_history_service.dart';

/// Manager for saving transfer history
class TransferHistoryManager {
  final TransferHistoryService _historyService;

  TransferHistoryManager({TransferHistoryService? historyService})
      : _historyService = historyService ?? TransferHistoryService();

  /// Save transfer history (both successful and failed)
  Future<void> saveTransferHistory({
    required String fileName,
    required int fileSize,
    required String targetIP,
    required bool success,
    required bool isReceived,
    String? deviceName,
    String? savedPath,
  }) async {
    try {
      await _historyService.saveTransfer(
        TransferHistory(
          fileName: fileName,
          fileSize: fileSize,
          peerIP: targetIP.split(':').first,
          peerDeviceName: deviceName,
          timestamp: DateTime.now(),
          isReceived: isReceived,
          success: success,
          savedPath: savedPath,
        ),
      );
      LogUtil.d('传输历史已保存: $fileName (成功: $success)');
    } catch (e) {
      LogUtil.e('保存传输历史失败: $e');
    }
  }
}
