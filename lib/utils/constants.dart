/// Application-wide constants
class AppConstants {
  // Information about this project
  static const String projectName = "Icy Easy Send";
  static const String projectNameTight = "IcyEasySend";
  static const String version = "v1.1.0";
  static const String author = "冰冷的希望";

  // Network constants

  /// Default port for file transfer server
  ///
  /// This is the default port used by the HTTP server to listen for incoming
  /// file transfer requests. The server will try this port first, and if it's
  /// occupied, it will try subsequent ports up to [maxServerPort].
  static const int defaultPort = 9527;

  /// Maximum port number to try when starting the server
  ///
  /// If [defaultPort] is occupied, the server will try ports in the range
  /// [defaultPort] to [maxServerPort] until it finds an available one.
  static const int maxServerPort = 9537;

  // Timeout constants

  /// Timeout for network requests, seconds
  static const int requestTimeout = 30;

  /// Timeout for network requests (health check), seconds
  static const int checkHealthTimeout = 5;

  /// Timeout for confirmation requests (longer to allow user to respond)
  /// User has 30 seconds to confirm, so we add 5 seconds buffer
  static const Duration confirmTimeout = Duration(seconds: 35);

  /// Base timeout for file transfer
  /// Actual timeout is calculated as: baseTimeout + (fileSize / 1MB) seconds
  static const Duration fileTransferBaseTimeout = Duration(seconds: 60);

  // File size constants

  /// Maximum file size (20GB)
  static const int maxFileSize = 20 * 1024 * 1024 * 1024;

  // History constants

  /// Maximum number of history items to keep
  static const int defaultMaxHistoryItems = 100;

  /// Maximum number of history items user can set
  static const int allowMaxHistoryItems = 1000;

  /// Minimum number of history items user can set
  static const int allowMinHistoryItems = 10;

  // Concurrent transfer constants

  /// Default number of concurrent transfers
  static const int defaultConcurrentTransfers = 5;

  /// Maximum number of concurrent transfers
  static const int maxConcurrentTransfers = 10;

  /// The delimiter used to display diagnostic information
  static const String diagInfoSeparator = '==========';

  // UI and Dialog constants

  /// Timeout duration for receive confirmation dialog
  /// User has this amount of time to accept or reject incoming files
  static const Duration receiveConfirmationTimeout = Duration(seconds: 30);

  /// Initial countdown seconds for receive confirmation
  static const int receiveConfirmationCountdown = 30;

  /// Countdown update interval (1 second)
  static const Duration countdownInterval = Duration(seconds: 1);

  /// Batch window duration for grouping multiple file requests from same sender
  /// Files arriving within this window will be grouped together
  static const Duration batchRequestWindow = Duration(milliseconds: 500);

  /// Progress update interval for file transfer UI
  static const Duration progressUpdateInterval = Duration(milliseconds: 500);

  /// Auto-close delay after all files are received
  /// Dialog will automatically close after this duration when transfer completes
  static const Duration autoCloseDelay = Duration(seconds: 1);

  /// File size constant
  static const int bytesPerKB = 1024;
  static const int bytesPerMB = 1024 * 1024;
  static const int bytesPerGB = 1024 * 1024 * 1024;

  /// Dialog width percentage (relative to screen width)
  /// All dialogs will use this percentage of screen width for consistent sizing
  static const double dialogWidthPercent = 0.8;

  // Clipboard constants

  /// Default max clipboard size
  static const int defaultMaxClipboardSize = 2;

  /// Minimum clipboard size
  static const int minClipboardSizeMB = 1;

  /// Maximum clipboard size
  static const int maxClipboardSizeMB = 10;

  /// Keep the lastest temp file count from clipboard
  static const int maxClipboardKeepCount = 5;

  // File name constants
  static const String defaultLoggerFileName = "IcyEasySend.log";
  static const String historyFileName = "IcyEasySendTransferHistory.json";

  // Logger constants
  static const int maxReadLogLines = 50;
}
