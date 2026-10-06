import '../l10n/current_localizations.dart';

/// Why a receiving device turned a request down, as sent back to the sender.
///
/// Travels as a stable [code] (the `code` field of an HTTP error body, or of a
/// relay `file.done`) so the sender can describe it in its own language: the
/// receiver has no idea which language the person on the other end reads.
/// [englishMessage] goes along as `message` for versions that predate codes
/// and show that field as-is.
enum PeerError {
  badRequest(
    'bad_request',
    'The request was not understood. Update both devices to the same version.',
  ),
  noValidFiles('no_valid_files', 'None of the files can be received.'),
  declined('declined', 'The receiver declined the files.'),
  backgroundNeedsSecretKey(
    'background_needs_secret_key',
    'The receiver is in the background and only accepts requests carrying a '
        'matching secret key.',
  ),
  busy('busy', 'The receiver is busy. Try again shortly.'),
  noUi('no_ui', 'The receiver cannot show a confirmation right now.'),
  fileTooLarge('file_too_large', 'The file exceeds the size limit.'),
  notConfirmed(
    'not_confirmed',
    'The receiver has no confirmation for this transfer.',
  ),
  sourceMismatch(
    'source_mismatch',
    'The transfer came from a different address than its confirmation.',
  ),
  contentMismatch(
    'content_mismatch',
    'The file does not match what the receiver agreed to.',
  ),
  diskFull('disk_full', 'The receiver is out of storage space.'),
  saveFailed('save_failed', 'The receiver could not save the file.'),
  internalError('internal_error', 'The receiver hit an unexpected error.'),
  clipboardDeclined(
    'clipboard_declined',
    'The clipboard request was declined.',
  ),
  clipboardEmpty('clipboard_empty', 'The clipboard is empty.'),
  clipboardUnavailableInBackground(
    'clipboard_unavailable_in_background',
    'The clipboard cannot be read while the receiver is in the background.',
  ),
  clipboardTooLarge(
    'clipboard_too_large',
    'The clipboard content exceeds the size limit.',
  );

  const PeerError(this.code, this.englishMessage);

  final String code;
  final String englishMessage;

  static PeerError? fromCode(Object? code) {
    for (final error in values) {
      if (error.code == code) return error;
    }
    return null;
  }

  /// Body fields for an error response.
  Map<String, Object> toJson() => {'code': code, 'message': englishMessage};

  /// This error in the current app language.
  ///
  /// [details] is the rest of the error body, for errors that carry figures.
  String describe([Map<String, dynamic>? details]) {
    final text = appText;
    return switch (this) {
      badRequest => text.peerErrorBadRequest,
      noValidFiles => text.peerErrorNoValidFiles,
      declined => text.transferRejected,
      backgroundNeedsSecretKey => text.backgroundRejectNeedsSecretKey,
      busy => text.peerErrorBusy,
      noUi => text.peerErrorNoUi,
      fileTooLarge => text.fileTooLarge,
      notConfirmed => text.peerErrorNotConfirmed,
      sourceMismatch => text.peerErrorSourceMismatch,
      contentMismatch => text.peerErrorContentMismatch,
      diskFull => text.peerErrorDiskFull,
      saveFailed => text.peerErrorSaveFailed,
      internalError => text.peerErrorInternal,
      clipboardDeclined => text.clipboardDeclined,
      clipboardEmpty => text.clipboardEmpty,
      clipboardUnavailableInBackground => text.clipboardBackgroundCacheMiss,
      clipboardTooLarge => _describeClipboardTooLarge(details),
    };
  }

  static String _describeClipboardTooLarge(Map<String, dynamic>? details) {
    final actual = details?['actualSizeMB'];
    final max = details?['maxSizeMB'];
    if (actual is num && max is num) {
      return appText.clipboardContentTooLarge(actual.toDouble(), max.toInt());
    }
    return appText.peerErrorClipboardTooLarge;
  }

  /// What to tell the user about an error body from a peer: the localized
  /// code when there is one, else whatever text an older peer sent, else
  /// [fallback].
  static String describeBody(Object? body, String fallback) {
    if (body is! Map<String, dynamic>) return fallback;
    final error = fromCode(body['code']);
    if (error != null) return error.describe(body);
    final message = body['message'];
    return message is String && message.isNotEmpty ? message : fallback;
  }
}
