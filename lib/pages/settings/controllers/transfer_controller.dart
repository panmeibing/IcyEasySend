import '../../../services/preferences_service.dart';
import '../../../services/transfer_history_service.dart';

/// Controller for transfer settings
class TransferController {
  final PreferencesService _preferencesService;
  final TransferHistoryService _historyService;

  TransferController(this._preferencesService, this._historyService);

  /// Load concurrent transfers setting
  Future<int> loadConcurrentTransfers() async {
    return await _preferencesService.getConcurrentTransfers();
  }

  /// Save concurrent transfers setting
  Future<bool> saveConcurrentTransfers(int count) async {
    return await _preferencesService.saveConcurrentTransfers(count);
  }

  /// Load max history items setting
  Future<int> loadMaxHistoryItems() async {
    return await _preferencesService.getMaxHistoryItems();
  }

  /// Save max history items setting and trim history if needed
  Future<Map<String, dynamic>> saveMaxHistoryItems(
    int newCount,
    int currentCount,
  ) async {
    final success = await _preferencesService.saveMaxHistoryItems(newCount);
    if (!success) {
      return {'success': false, 'deletedCount': 0};
    }

    // If current count exceeds new limit, trim the history
    int deletedCount = 0;
    if (currentCount > newCount) {
      deletedCount = await _historyService.trimHistory(newCount);
    }

    return {'success': true, 'deletedCount': deletedCount};
  }

  /// Get current history count
  Future<int> getCurrentHistoryCount() async {
    final history = await _historyService.loadHistory();
    return history.length;
  }

  /// Load max clipboard size setting
  Future<int> loadMaxClipboardSize() async {
    return await _preferencesService.getMaxClipboardSize();
  }

  /// Save max clipboard size setting
  Future<bool> saveMaxClipboardSize(int sizeMB) async {
    return await _preferencesService.saveMaxClipboardSize(sizeMB);
  }

  /// Load IP validation enabled state
  Future<bool> loadIPValidationEnabled() async {
    return await _preferencesService.getIPValidationEnabled();
  }

  /// Save IP validation enabled state
  Future<bool> saveIPValidationEnabled(bool enabled) async {
    return await _preferencesService.saveIPValidationEnabled(enabled);
  }
}
