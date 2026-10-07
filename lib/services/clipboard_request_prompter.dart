import 'package:flutter/widgets.dart';

/// How the service layer asks the user whether a peer may read the clipboard.
///
/// Requests arrive over the LAN server and over the relay; both need the same
/// answer from the same dialog, and neither should reach into `lib/pages` for
/// it. The UI layer installs the real implementation at startup; see
/// `DialogClipboardRequestPrompter` in
/// `lib/pages/clipboard/clipboard_request_dialog.dart`.
abstract class ClipboardRequestPrompter {
  const ClipboardRequestPrompter();

  static ClipboardRequestPrompter instance =
      const _NoUiClipboardRequestPrompter();

  /// True only when the user explicitly allowed it. Rejecting, dismissing and
  /// running out the countdown are all false, and the prompt is gone from the
  /// screen by the time this completes.
  Future<bool> confirm(
    BuildContext context, {
    required String requesterDeviceName,
  });
}

/// Stands in until the UI layer installs itself, and in tests that never do.
class _NoUiClipboardRequestPrompter extends ClipboardRequestPrompter {
  const _NoUiClipboardRequestPrompter();

  @override
  Future<bool> confirm(
    BuildContext context, {
    required String requesterDeviceName,
  }) async => false;
}
