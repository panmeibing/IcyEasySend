import '../../models/transfer_history.dart';
import '../../utils/log_util.dart';
import '../transfer_history_service.dart';

/// Manager for saving transfer history
class TransferHistoryManager {
  final TransferHistoryService _historyService;
  final String logTag = LogTags.history;

  TransferHistoryManager({TransferHistoryService? historyService})
    : _historyService = historyService ?? TransferHistoryService();

  /// Save multiple transfer histories in batch
  /// This is more efficient and safer for concurrent transfers
  Future<void> saveTransferHistoryBatch(List<TransferHistory> histories) async {
    if (histories.isEmpty) return;

    try {
      await _historyService.saveTransferBatch(histories);
      LogUtil.dTag(logTag, '批量保存传输历史: ${histories.length} 条记录');
    } catch (e) {
      LogUtil.eTag(logTag, '批量保存传输历史失败: $e');
    }
  }

  /// Create a transfer history record without saving it
  /// Useful for collecting records to save in batch later
  TransferHistory createTransferHistory({
    required String fileName,
    required int fileSize,
    required String targetIP,
    required bool success,
    required bool isReceived,
    String? deviceName,
    String? savedPath,
  }) {
    return TransferHistory(
      fileName: fileName,
      fileSize: fileSize,
      peerIP: targetIP.split(':').first,
      peerDeviceName: deviceName,
      timestamp: DateTime.now(),
      isReceived: isReceived,
      success: success,
      savedPath: savedPath,
    );
  }
}
