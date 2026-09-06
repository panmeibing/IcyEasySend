/// Thin facades over [appText].
///
/// These used to carry their own 12-locale translation tables in parallel with
/// `AppLocalizations`. The tables are gone; the class names remain so service
/// and UI call sites keep compiling while everything resolves through one
/// source of truth.
library;

import '../l10n/current_localizations.dart';

class ErrorMessages {
  ErrorMessages._();

  static String get networkConnectionFailed => appText.networkConnectionFailed;
  static String get networkTimeout => appText.networkTimeout;
  static String get networkRequestFailed => appText.networkRequestFailed;
  static String get targetDeviceUnavailable => appText.targetDeviceUnavailable;
  static String get transferTimeout => appText.transferTimeout;
  static String get transferInterrupted => appText.transferInterrupted;

  static String get fileNotFound => appText.fileNotFound;
  static String get fileNotReadable => appText.fileNotReadable;
  static String get fileAccessError => appText.fileAccessError;
  static String get fileSaveFailed => appText.fileSaveFailed;
  static String get fileSizeMismatch => appText.fileSizeMismatch;
  static String get invalidFileName => appText.invalidFileName;
  static String get downloadsDirectoryUnavailable =>
      appText.downloadsDirectoryUnavailable;

  static String get storageInsufficient => appText.storageInsufficient;
  static String get storageCheckFailed => appText.storageCheckFailed;

  static String get permissionDenied => appText.permissionDenied;
  static String get networkPermissionDenied => appText.networkPermissionDenied;
  static String get storagePermissionDenied => appText.storagePermissionDenied;

  static String serverStartFailed(String reason) =>
      appText.serverStartFailed(reason);
  static String get serverPortsOccupied => appText.serverPortsOccupied;
  static String get serverUnknownError => appText.serverUnknownError;

  static String get transferRejected => appText.transferRejected;
  static String get fileTooLarge => appText.fileTooLarge;
  static String get fileOrStorageFull => appText.fileOrStorageFull;
  static String get receiveTimeout => appText.receiveTimeout;
  static String get userRejected => appText.userRejected;
  static String get backgroundRejectNeedsSecretKey =>
      appText.backgroundRejectNeedsSecretKey;
  static String get clipboardBackgroundCacheMiss =>
      appText.clipboardBackgroundCacheMiss;

  static String get foregroundServiceNotificationTitle =>
      appText.foregroundServiceNotificationTitle;
  static String get foregroundServiceNotificationText =>
      appText.foregroundServiceNotificationText;
  static String get foregroundServiceChannelName =>
      appText.foregroundServiceChannelName;
  static String get foregroundServiceChannelDescription =>
      appText.foregroundServiceChannelDescription;

  static String get ipAddressEmpty => appText.ipAddressEmpty;
  static String get ipAddressInvalidFormat => appText.ipAddressInvalidFormat;
  static String get ipAddressInvalidRange => appText.ipAddressInvalidRange;
  static String get ipAddressSpecial1 => appText.ipAddressSpecial1;
  static String get ipAddressSpecial2 => appText.ipAddressSpecial2;
  static String ipAddressNotInSameSubnet(String localIP, String targetIP) {
    final localNetwork = localIP.split('.').take(3).join('.');
    final targetNetwork = targetIP.split('.').take(3).join('.');
    return appText.ipAddressNotInSameSubnet(
      localIP,
      targetIP,
      localNetwork,
      targetNetwork,
    );
  }

  static String get responseParseError => appText.responseParseError;
  static String get responseInvalidFormat => appText.responseInvalidFormat;
  static String responseStatusCodeError(int statusCode) =>
      appText.responseStatusCodeError(statusCode);

  static String get fileSelectionError => appText.fileSelectionError;
  static String get fileSelectionCancelled => appText.fileSelectionCancelled;

  static String genericError(String operation) =>
      appText.genericError(operation);
  static String unexpectedError(String details) =>
      appText.unexpectedError(details);
  static String networkError(String context) => appText.networkError(context);
  static String fileError(String context) => appText.fileError(context);
  static String permissionError(String permissionType) =>
      appText.permissionError(permissionType);

  static String fromException(Exception e, {String? context}) {
    final message = e.toString();
    if (message.contains('SocketException')) {
      return networkConnectionFailed;
    }
    if (message.contains('TimeoutException')) {
      return networkTimeout;
    }
    if (message.contains('FileSystemException')) {
      return fileAccessError;
    }
    if (message.contains('PermissionDeniedException')) {
      return permissionDenied;
    }
    if (context != null) {
      return '$context: $message';
    }
    return unexpectedError(message);
  }
}
