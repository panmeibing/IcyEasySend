import 'package:flutter/widgets.dart';

import '../models/incoming_batch.dart';

/// How the service layer shows the user an incoming batch of files.
///
/// Files arrive over the LAN server and over the relay, and both need the same
/// accept/reject prompt followed by a progress view. The UI layer installs the
/// real implementation at startup; see `DialogBatchReceivePrompter` in
/// `lib/pages/receive/batch_receive_dialog.dart`.
abstract class BatchReceivePrompter {
  const BatchReceivePrompter();

  static BatchReceivePrompter instance = const _NoUiBatchReceivePrompter();

  /// Shows [batch], letting the user [IncomingBatch.accept] or
  /// [IncomingBatch.reject] it, and keeps showing it while an accepted batch
  /// is received. Completes once the prompt is gone.
  Future<void> present(BuildContext context, IncomingBatch batch);
}

/// Stands in until the UI layer installs itself, and in tests that never do.
class _NoUiBatchReceivePrompter extends BatchReceivePrompter {
  const _NoUiBatchReceivePrompter();

  @override
  Future<void> present(BuildContext context, IncomingBatch batch) async {
    if (batch.autoAccept) {
      batch.accept();
    } else {
      batch.reject();
    }
  }
}
