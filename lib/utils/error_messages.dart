/// ErrorMessages provides user-friendly error messages
/// for all error scenarios in the application.
///
/// All messages follow these principles:
/// - Clarity: Use simple, clear descriptions
/// - Actionability: Provide next steps the user can take
/// - Friendliness: Avoid technical jargon, use user-understandable language
/// - Consistency: All messages follow the same format and style
///
/// This class now uses ErrorMessageProvider for internationalization support.
library;

import 'error_message_provider.dart';

class ErrorMessages {
  static final _provider = ErrorMessageProvider();

  // Network errors (Requirement 10.1)
  static String get networkConnectionFailed =>
      _provider.networkConnectionFailed;

  static String get networkTimeout => _provider.networkTimeout;

  static String get networkRequestFailed => _provider.networkRequestFailed;

  static String get targetDeviceUnavailable =>
      _provider.targetDeviceUnavailable;

  static String get transferTimeout => _provider.transferTimeout;

  static String get transferInterrupted => _provider.transferInterrupted;

  // File system errors (Requirement 10.2)
  static String get fileNotFound => _provider.fileNotFound;

  static String get fileNotReadable => _provider.fileNotReadable;

  static String get fileAccessError => _provider.fileAccessError;

  static String get fileSaveFailed => _provider.fileSaveFailed;

  static String get fileSizeMismatch => _provider.fileSizeMismatch;

  static String get invalidFileName => _provider.invalidFileName;

  static String get downloadsDirectoryUnavailable =>
      _provider.downloadsDirectoryUnavailable;

  // Storage errors (Requirement 10.3)
  static String get storageInsufficient => _provider.storageInsufficient;

  static String get storageCheckFailed => _provider.storageCheckFailed;

  // Permission errors (Requirement 10.4)
  static String get permissionDenied => _provider.permissionDenied;

  static String get networkPermissionDenied =>
      _provider.networkPermissionDenied;

  static String get storagePermissionDenied =>
      _provider.storagePermissionDenied;

  // Server errors
  static String serverStartFailed(String reason) =>
      _provider.serverStartFailed(reason);

  static String get serverPortsOccupied => _provider.serverPortsOccupied;

  static String get serverUnknownError => _provider.serverUnknownError;

  // Transfer errors
  static String get transferRejected => _provider.transferRejected;

  static String get fileTooLarge => _provider.fileTooLarge;

  static String get fileOrStorageFull => _provider.fileOrStorageFull;

  static String get receiveTimeout => _provider.receiveTimeout;

  static String get userRejected => _provider.userRejected;

  static String get backgroundRejectNeedsSecretKey =>
      _provider.backgroundRejectNeedsSecretKey;

  static String get clipboardBackgroundCacheMiss =>
      _provider.clipboardBackgroundCacheMiss;

  static String get foregroundServiceNotificationTitle =>
      _provider.foregroundServiceNotificationTitle;

  static String get foregroundServiceNotificationText =>
      _provider.foregroundServiceNotificationText;

  static String get foregroundServiceChannelName =>
      _provider.foregroundServiceChannelName;

  static String get foregroundServiceChannelDescription =>
      _provider.foregroundServiceChannelDescription;

  // Validation errors
  static String get ipAddressEmpty => _provider.ipAddressEmpty;

  static String get ipAddressInvalidFormat => _provider.ipAddressInvalidFormat;

  static String get ipAddressInvalidRange => _provider.ipAddressInvalidRange;

  static String get ipAddressSpecial1 => _provider.ipAddressSpecial1;

  static String get ipAddressSpecial2 => _provider.ipAddressSpecial2;

  /// Warning message when target IP is not in the same subnet as local IP
  static String ipAddressNotInSameSubnet(String localIP, String targetIP) =>
      _provider.ipAddressNotInSameSubnet(localIP, targetIP);

  // Response parsing errors
  static String get responseParseError => _provider.responseParseError;

  static String get responseInvalidFormat => _provider.responseInvalidFormat;

  static String responseStatusCodeError(int statusCode) =>
      _provider.responseStatusCodeError(statusCode);

  // File selection errors
  static String get fileSelectionError => _provider.fileSelectionError;

  static String get fileSelectionCancelled => _provider.fileSelectionCancelled;

  // Generic errors
  static String genericError(String operation) =>
      _provider.genericError(operation);

  static String unexpectedError(String details) =>
      _provider.unexpectedError(details);

  /// Format a network error message with additional context
  static String networkError(String context) => _provider.networkError(context);

  /// Format a file error message with additional context
  static String fileError(String context) => _provider.fileError(context);

  /// Format a permission error message with specific permission type
  static String permissionError(String permissionType) =>
      _provider.permissionError(permissionType);

  /// Get a user-friendly error message from an exception
  static String fromException(Exception e, {String? context}) {
    final message = e.toString();

    // Try to extract meaningful error message
    if (message.contains('SocketException')) {
      return networkConnectionFailed;
    } else if (message.contains('TimeoutException')) {
      return networkTimeout;
    } else if (message.contains('FileSystemException')) {
      return fileAccessError;
    } else if (message.contains('PermissionDeniedException')) {
      return permissionDenied;
    }

    // Return generic error with context if available
    if (context != null) {
      return '$context: $message';
    }

    return unexpectedError(message);
  }
}
