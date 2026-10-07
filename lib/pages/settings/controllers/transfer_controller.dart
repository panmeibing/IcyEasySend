import '../../../services/preferences_service.dart';
import '../../../services/transfer_history_service.dart';
import '../../../services/validation_service.dart';
import '../../../utils/platform_util.dart';

/// Outcome of [TransferController.setCustomReceiveSavePath].
enum ReceivePathChange { saved, notWritable, saveFailed }

/// Transfer settings shared by the phone and TV settings pages, so the two
/// cannot drift apart in what saving a value actually does.
class TransferController {
  final PreferencesService _preferencesService;
  final TransferHistoryService _historyService;
  final ValidationService _validationService;

  TransferController(
    this._preferencesService,
    this._historyService, {
    ValidationService? validationService,
  }) : _validationService = validationService ?? ValidationService();

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

  /// Saves the history limit and immediately drops entries beyond it.
  Future<({bool success, int deletedCount})> saveMaxHistoryItems(
    int newCount,
  ) async {
    final success = await _preferencesService.saveMaxHistoryItems(newCount);
    if (!success) {
      return (success: false, deletedCount: 0);
    }
    final deletedCount = await _historyService.trimHistory(newCount);
    return (success: true, deletedCount: deletedCount);
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

  /// Custom receive save path, or null when the system downloads folder is used.
  Future<String?> loadCustomReceiveSavePath() async {
    final path = await _preferencesService.getCustomReceiveSavePath();
    return path == null || path.isEmpty ? null : path;
  }

  /// Whether a custom receive save path is configured
  Future<bool> hasCustomReceiveSavePath() async {
    return await loadCustomReceiveSavePath() != null;
  }

  /// Path shown in settings (custom path or system downloads folder)
  Future<String> getReceiveSavePathDisplay() async {
    final custom = await loadCustomReceiveSavePath();
    if (custom != null) {
      return custom;
    }
    final downloadsDir = await PlatformUtil.getDownloadsDirectory();
    return downloadsDir?.path ?? '';
  }

  /// Makes [path] the receive directory, provided files can be written there.
  Future<ReceivePathChange> setCustomReceiveSavePath(String path) async {
    final writable = await _validationService.validateDirectoryWritable(path);
    if (!writable.isSuccess) {
      return ReceivePathChange.notWritable;
    }
    final saved = await _preferencesService.saveCustomReceiveSavePath(path);
    return saved ? ReceivePathChange.saved : ReceivePathChange.saveFailed;
  }

  /// Clear custom receive save path (use system downloads folder)
  Future<bool> clearCustomReceiveSavePath() async {
    return _preferencesService.clearCustomReceiveSavePath();
  }
}
