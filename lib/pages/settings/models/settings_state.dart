/// Settings state model
class SettingsState {
  // Device info
  final String deviceName;
  final String deviceModel;
  final bool isEditingName;

  // Server info
  final String? serverIP;
  final String? serverPort;

  // Transfer settings
  final int concurrentTransfers;
  final int tempConcurrentTransfers;
  final int maxHistoryItems;
  final bool isEditingMaxHistory;
  final int maxClipboardSizeMB;
  final bool isEditingMaxClipboardSize;
  final bool enableIPValidation;

  // Developer mode
  final int versionTapCount;
  final DateTime? lastVersionTapTime;

  // Loading state
  final bool isLoading;

  const SettingsState({
    required this.deviceName,
    required this.deviceModel,
    this.isEditingName = false,
    this.serverIP,
    this.serverPort,
    required this.concurrentTransfers,
    required this.tempConcurrentTransfers,
    required this.maxHistoryItems,
    this.isEditingMaxHistory = false,
    required this.maxClipboardSizeMB,
    this.isEditingMaxClipboardSize = false,
    required this.enableIPValidation,
    this.versionTapCount = 0,
    this.lastVersionTapTime,
    this.isLoading = true,
  });

  SettingsState copyWith({
    String? deviceName,
    String? deviceModel,
    bool? isEditingName,
    String? serverIP,
    String? serverPort,
    int? concurrentTransfers,
    int? tempConcurrentTransfers,
    int? maxHistoryItems,
    bool? isEditingMaxHistory,
    int? maxClipboardSizeMB,
    bool? isEditingMaxClipboardSize,
    bool? enableIPValidation,
    int? versionTapCount,
    DateTime? lastVersionTapTime,
    bool? isLoading,
  }) {
    return SettingsState(
      deviceName: deviceName ?? this.deviceName,
      deviceModel: deviceModel ?? this.deviceModel,
      isEditingName: isEditingName ?? this.isEditingName,
      serverIP: serverIP ?? this.serverIP,
      serverPort: serverPort ?? this.serverPort,
      concurrentTransfers: concurrentTransfers ?? this.concurrentTransfers,
      tempConcurrentTransfers:
          tempConcurrentTransfers ?? this.tempConcurrentTransfers,
      maxHistoryItems: maxHistoryItems ?? this.maxHistoryItems,
      isEditingMaxHistory: isEditingMaxHistory ?? this.isEditingMaxHistory,
      maxClipboardSizeMB: maxClipboardSizeMB ?? this.maxClipboardSizeMB,
      isEditingMaxClipboardSize:
          isEditingMaxClipboardSize ?? this.isEditingMaxClipboardSize,
      enableIPValidation: enableIPValidation ?? this.enableIPValidation,
      versionTapCount: versionTapCount ?? this.versionTapCount,
      lastVersionTapTime: lastVersionTapTime ?? this.lastVersionTapTime,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
