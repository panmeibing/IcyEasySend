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

  // Receive save path
  final String receiveSavePathDisplay;
  final bool isCustomReceiveSavePath;

  // Secret key
  final String deviceSecretKey;
  final bool isEditingSecretKey;

  // Android clipboard floating overlay
  final bool clipboardOverlayEnabled;

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
    this.receiveSavePathDisplay = '',
    this.isCustomReceiveSavePath = false,
    this.deviceSecretKey = '',
    this.isEditingSecretKey = false,
    this.clipboardOverlayEnabled = false,
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
    String? receiveSavePathDisplay,
    bool? isCustomReceiveSavePath,
    String? deviceSecretKey,
    bool? isEditingSecretKey,
    bool? clipboardOverlayEnabled,
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
      receiveSavePathDisplay:
          receiveSavePathDisplay ?? this.receiveSavePathDisplay,
      isCustomReceiveSavePath:
          isCustomReceiveSavePath ?? this.isCustomReceiveSavePath,
      deviceSecretKey: deviceSecretKey ?? this.deviceSecretKey,
      isEditingSecretKey: isEditingSecretKey ?? this.isEditingSecretKey,
      clipboardOverlayEnabled:
          clipboardOverlayEnabled ?? this.clipboardOverlayEnabled,
      versionTapCount: versionTapCount ?? this.versionTapCount,
      lastVersionTapTime: lastVersionTapTime ?? this.lastVersionTapTime,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
